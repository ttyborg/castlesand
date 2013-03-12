unit KM_PlayerStats;
{$I KaM_Remake.inc}
interface
uses Classes, KM_Defaults, KM_CommonTypes;

{These are mission specific settings and stats for each player}
type
  TKMPlayerStats = class
  private
    Houses:array[1..HOUSE_COUNT]of packed record
      Started,      //Construction started
      Ended,        //Construction ended (either done or destroyed/cancelled)
      Initial,      //created by script on mission start
      Built,        //constructed by player
      SelfDestruct, //deconstructed by player
      Lost,         //lost from attacks and self-demolished
      Destroyed:word; //damage to other players
    end;
    Units:array[ut_Serf..ut_Barbarian]of packed record
      Initial,
      Trained,
      Lost,
      Killed:word;
    end;
    Goods:array[rt_Trunk..rt_Fish]of packed record
      Produced:word;
    end;
    ResourceRatios:array[1..4,1..4]of byte;
  public
    AllowToBuild:array[1..HOUSE_COUNT]of boolean; //Allowance derived from mission script
    BuildReqDone:array[1..HOUSE_COUNT]of boolean; //If building requirements performed or assigned from script
    constructor Create;

    procedure HouseStarted(aType:THouseType);
    procedure HouseEnded(aType:THouseType);
    procedure HouseCreated(aType:THouseType; aWasBuilt:boolean);
    procedure HouseLost(aType:THouseType);
    procedure HouseSelfDestruct(aType:THouseType);
    procedure HouseDestroyed(aType:THouseType);

    procedure UnitCreated(aType:TUnitType; aWasTrained:boolean);
    procedure UnitLost(aType:TUnitType);
    procedure UnitKilled(aType:TUnitType);

    procedure GoodProduced(aRes:TResourceType; aCount:integer);

    procedure UpdateReqDone(aType:THouseType);

    function GetHouseQty(aType:THouseType):integer;
    function GetHouseWip(aType:THouseType):integer;
    function GetUnitQty(aType:TUnitType):integer;
    function GetArmyCount:integer;
    function GetCanBuild(aType:THouseType):boolean;

    function GetRatio(aRes:TResourceType; aHouse:THouseType):byte;
    procedure SetRatio(aRes:TResourceType; aHouse:THouseType; aValue:byte);

    function GetUnitsLost:cardinal;
    function GetUnitsKilled:cardinal;
    function GetHousesLost:cardinal;
    function GetHousesDestroyed:cardinal;
    function GetHousesBuilt:cardinal;
    function GetUnitsTrained:cardinal;
    function GetWeaponsProduced:cardinal;
    function GetSoldiersTrained:cardinal;

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
  end;


implementation


{ TKMPlayerStats }
constructor TKMPlayerStats.Create;
var i,k:integer;
begin
  Inherited;
  for i:=1 to length(AllowToBuild) do
    AllowToBuild[i] := true;

  BuildReqDone[byte(ht_Store)] := true;

  for i:=1 to 4 do for k:=1 to 4 do
    ResourceRatios[i,k] := DistributionDefaults[i,k];
end;


procedure TKMPlayerStats.UpdateReqDone(aType:THouseType);
var i:integer;
begin
  for i:=1 to length(BuildingAllowed[1]) do
    if BuildingAllowed[byte(aType),i]<>ht_None then
      BuildReqDone[byte(BuildingAllowed[byte(aType),i])] := true;
end;


//New house in progress
procedure TKMPlayerStats.HouseStarted(aType:THouseType);
begin
  inc(Houses[byte(aType)].Started);
end;


//Since we track only WIP houses, we don't care if it's done or canceled/destroyed, that could be separate stats
procedure TKMPlayerStats.HouseEnded(aType:THouseType);
begin
  inc(Houses[byte(aType)].Ended);
end;


//New house, either built by player or created by mission script
procedure TKMPlayerStats.HouseCreated(aType:THouseType; aWasBuilt:boolean);
begin
  if aWasBuilt then
    inc(Houses[byte(aType)].Built)
  else
    inc(Houses[byte(aType)].Initial);
  UpdateReqDone(aType);
end;


//Destroyed by enemy
procedure TKMPlayerStats.HouseLost(aType:THouseType);
begin
  inc(Houses[byte(aType)].Lost);
end;


procedure TKMPlayerStats.HouseSelfDestruct(aType:THouseType);
begin
  inc(Houses[byte(aType)].SelfDestruct);
end;


//Player has destroyed an enemy house
procedure TKMPlayerStats.HouseDestroyed(aType:THouseType);
begin
  inc(Houses[byte(aType)].Destroyed);
end;


procedure TKMPlayerStats.UnitCreated(aType:TUnitType; aWasTrained:boolean);
begin
  if aWasTrained then
    inc(Units[aType].Trained)
  else
    inc(Units[aType].Initial);
end;


procedure TKMPlayerStats.UnitLost(aType:TUnitType);
begin
  inc(Units[aType].Lost);
end;


procedure TKMPlayerStats.UnitKilled(aType:TUnitType);
begin
  inc(Units[aType].Killed);
end;


procedure TKMPlayerStats.GoodProduced(aRes:TResourceType; aCount:integer);
begin
  if aRes<>rt_None then
    inc(Goods[aRes].Produced, aCount);
end;


function TKMPlayerStats.GetHouseQty(aType:THouseType):integer;
var i:integer;
begin
  Result := 0;
  case aType of
    ht_None:    ;
    ht_Any:     for i:=1 to HOUSE_COUNT do
                  inc(Result, Houses[i].Initial + Houses[i].Built - Houses[i].SelfDestruct - Houses[i].Lost);
    else        Result := Houses[byte(aType)].Initial + Houses[byte(aType)].Built - Houses[byte(aType)].SelfDestruct - Houses[byte(aType)].Lost;
  end;
end;


function TKMPlayerStats.GetHouseWip(aType:THouseType):integer;
var i:integer;
begin
  Result := 0;
  case aType of
    ht_None:    ;
    ht_Any:     for i:=1 to HOUSE_COUNT do
                  inc(Result, Houses[i].Started - Houses[i].Ended);
    else        Result := Houses[byte(aType)].Started - Houses[byte(aType)].Ended;
  end;
end;


function TKMPlayerStats.GetUnitQty(aType:TUnitType):integer;
var i:TUnitType;
begin
  Result := Units[aType].Initial + Units[aType].Trained - Units[aType].Lost;
  if aType = ut_Recruit then
    for i:= ut_Militia to ut_Barbarian do
      dec(Result,Units[i].Trained); //Trained soldiers use a recruit
end;


function TKMPlayerStats.GetArmyCount:integer;
var ut:TUnitType;
begin
  Result := 0;
  for ut:=ut_Militia to ut_Barbarian do
    Result := Result + GetUnitQty(ut);
end;


function TKMPlayerStats.GetCanBuild(aType:THouseType):boolean;
begin
  Result := BuildReqDone[byte(aType)] AND AllowToBuild[byte(aType)];
end;


function TKMPlayerStats.GetRatio(aRes:TResourceType; aHouse:THouseType):byte;
begin
  Result:=5; //Default should be 5, for house/resource combinations that don't have a setting (on a side note this should be the only place the resourse limit is defined)
  case aRes of
    rt_Steel: if aHouse=ht_WeaponSmithy   then Result:=ResourceRatios[1,1] else
              if aHouse=ht_ArmorSmithy    then Result:=ResourceRatios[1,2];
    rt_Coal:  if aHouse=ht_IronSmithy     then Result:=ResourceRatios[2,1] else
              if aHouse=ht_Metallurgists  then Result:=ResourceRatios[2,2] else
              if aHouse=ht_WeaponSmithy   then Result:=ResourceRatios[2,3] else
              if aHouse=ht_ArmorSmithy    then Result:=ResourceRatios[2,4];
    rt_Wood:  if aHouse=ht_ArmorWorkshop  then Result:=ResourceRatios[3,1] else
              if aHouse=ht_WeaponWorkshop then Result:=ResourceRatios[3,2];
    rt_Corn:  if aHouse=ht_Mill           then Result:=ResourceRatios[4,1] else
              if aHouse=ht_Swine          then Result:=ResourceRatios[4,2] else
              if aHouse=ht_Stables        then Result:=ResourceRatios[4,3];
  end;
end;


procedure TKMPlayerStats.SetRatio(aRes:TResourceType; aHouse:THouseType; aValue:byte);
begin
  case aRes of
    rt_Steel: if aHouse=ht_WeaponSmithy   then ResourceRatios[1,1]:=aValue else
              if aHouse=ht_ArmorSmithy    then ResourceRatios[1,2]:=aValue;
    rt_Coal:  if aHouse=ht_IronSmithy     then ResourceRatios[2,1]:=aValue else
              if aHouse=ht_Metallurgists  then ResourceRatios[2,2]:=aValue else
              if aHouse=ht_WeaponSmithy   then ResourceRatios[2,3]:=aValue else
              if aHouse=ht_ArmorSmithy    then ResourceRatios[2,4]:=aValue;
    rt_Wood:  if aHouse=ht_ArmorWorkshop  then ResourceRatios[3,1]:=aValue else
              if aHouse=ht_WeaponWorkshop then ResourceRatios[3,2]:=aValue;
    rt_Corn:  if aHouse=ht_Mill           then ResourceRatios[4,1]:=aValue else
              if aHouse=ht_Swine          then ResourceRatios[4,2]:=aValue else
              if aHouse=ht_Stables        then ResourceRatios[4,3]:=aValue;
    else fLog.AssertToLog(false,'Unexpected resource at SetRatio');
  end;
end;


function TKMPlayerStats.GetUnitsLost:cardinal;
var i:TUnitType;
begin
  Result:=0;
  for i:=low(Units) to high(Units) do
    inc(Result,Units[i].Lost);
end;


function TKMPlayerStats.GetUnitsKilled:cardinal;
var i:TUnitType;
begin
  Result:=0;
  for i:=low(Units) to high(Units) do
    inc(Result,Units[i].Killed);
end;


function TKMPlayerStats.GetHousesLost:cardinal;
var i:integer;
begin
  Result:=0;
  for i:=low(Houses) to high(Houses) do
    inc(Result,Houses[i].Lost);
end;


function TKMPlayerStats.GetHousesDestroyed:cardinal;
var i:integer;
begin
  Result:=0;
  for i:=low(Houses) to high(Houses) do
    inc(Result,Houses[i].Destroyed);
end;


function TKMPlayerStats.GetHousesBuilt:cardinal;
var i:integer;
begin
  Result:=0;
  for i:=low(Houses) to high(Houses) do
    inc(Result,Houses[i].Built);
end;


//The value includes all citizens, Warriors are counted separately
function TKMPlayerStats.GetUnitsTrained:cardinal;
var i:TUnitType;
begin
  Result:=0;
  for i:=ut_Serf to ut_Recruit do
    inc(Result,Units[i].Trained);
end;


//KaM includes all weapons and armor, but not horses
function TKMPlayerStats.GetWeaponsProduced:cardinal;
var i:TResourceType;
begin
  Result := 0;
  for i:=rt_Shield to rt_Arbalet do
    inc(Result, Goods[i].Produced);
end;


//The value includes all Warriors
function TKMPlayerStats.GetSoldiersTrained:cardinal;
var i:TUnitType;
begin
  Result:=0;
  for i:=ut_Militia to ut_Barbarian do
    inc(Result,Units[i].Trained);
end;


procedure TKMPlayerStats.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write('PlayerStats');
  SaveStream.Write(Houses, SizeOf(Houses));
  SaveStream.Write(Units, SizeOf(Units));
  SaveStream.Write(Goods, SizeOf(Goods));
  SaveStream.Write(ResourceRatios, SizeOf(ResourceRatios));
  SaveStream.Write(AllowToBuild, SizeOf(AllowToBuild));
  SaveStream.Write(BuildReqDone, SizeOf(BuildReqDone));
end;


procedure TKMPlayerStats.Load(LoadStream:TKMemoryStream);
var s:string;
begin
  LoadStream.Read(s);
  Assert(s = 'PlayerStats');
  LoadStream.Read(Houses, SizeOf(Houses));
  LoadStream.Read(Units, SizeOf(Units));
  LoadStream.Read(Goods, SizeOf(Goods));
  LoadStream.Read(ResourceRatios, SizeOf(ResourceRatios));
  LoadStream.Read(AllowToBuild, SizeOf(AllowToBuild));
  LoadStream.Read(BuildReqDone, SizeOf(BuildReqDone));
end;


end.