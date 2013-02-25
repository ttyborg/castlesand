unit KM_AISetup;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, Math, SysUtils,
    KM_CommonClasses, KM_Points, KM_Defaults;


type
  TKMPlayerAISetup = class
  public
    Aggressiveness: Integer; //-1 means not used or default
    AutoBuild: Boolean;
    AutoRepair: Boolean;
    AutoDefend: Boolean;
    EquipRateLeather, EquipRateIron: Word; //Number of ticks between soldiers being equipped. Seperated into Leather/Iron to keep KaM compatibility.
    MaxSoldiers: Integer; //-1 means not used or default
    RecruitDelay: Cardinal; //Recruits (for barracks) can only be trained after this many ticks
    RecruitFactor: Byte;
    SerfFactor: Byte;
    StartPosition: TKMPoint; //Defines roughly where to defend and build around
    TownDefence: Integer; //-1 means not used or default
    WorkerFactor: Byte;

    constructor Create;
    function GetEquipRate(aUnit: TUnitType): Word;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;


implementation


{ TKMPlayerAISetup }
constructor TKMPlayerAISetup.Create;
begin
  inherited;

  //TSK/TPR properties
  Aggressiveness := 100; //No idea what the default for this is, it's barely used
  AutoBuild := True; //In KaM it is On by default, and most missions turn it off
  AutoRepair := False; //In KaM it is Off by default
  AutoDefend := False; //It did not exist in KaM, we add it, Off by default

  EquipRateIron := 500; //Measured in KaM: AI equips 1 iron soldier every ~50 seconds
  EquipRateLeather := 1000; //Measured in KaM: AI equips 1 leather soldier every ~100 seconds (if no iron one was already equipped)
  MaxSoldiers := -1; //No limit by default
  WorkerFactor := 6;
  RecruitFactor := 5; //This means the number in the barracks, watchtowers are counted seperately
  RecruitDelay := 0; //Can train at start
  SerfFactor := 10; //Means 1 serf per building
  StartPosition := KMPoint(1,1);
  TownDefence := 100; //In KaM 100 is standard, although we don't completely understand this command
end;


function TKMPlayerAISetup.GetEquipRate(aUnit: TUnitType): Word;
begin
  if aUnit in WARRIORS_IRON then
    Result := EquipRateIron
  else
    Result := EquipRateLeather;
end;


procedure TKMPlayerAISetup.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(Aggressiveness);
  SaveStream.Write(AutoBuild);
  SaveStream.Write(AutoRepair);
  SaveStream.Write(AutoDefend);
  SaveStream.Write(EquipRateLeather);
  SaveStream.Write(EquipRateIron);
  SaveStream.Write(MaxSoldiers);
  SaveStream.Write(RecruitDelay);
  SaveStream.Write(RecruitFactor);
  SaveStream.Write(SerfFactor);
  SaveStream.Write(StartPosition);
  SaveStream.Write(TownDefence);
  SaveStream.Write(WorkerFactor);
end;


procedure TKMPlayerAISetup.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.Read(Aggressiveness);
  LoadStream.Read(AutoBuild);
  LoadStream.Read(AutoRepair);
  LoadStream.Read(AutoDefend);
  LoadStream.Read(EquipRateLeather);
  LoadStream.Read(EquipRateIron);
  LoadStream.Read(MaxSoldiers);
  LoadStream.Read(RecruitDelay);
  LoadStream.Read(RecruitFactor);
  LoadStream.Read(SerfFactor);
  LoadStream.Read(StartPosition);
  LoadStream.Read(TownDefence);
  LoadStream.Read(WorkerFactor);
end;


end.