unit KM_UnitTaskAttackHouse;
interface
uses Classes, KM_CommonTypes, KM_Defaults, KM_Utils, KM_Houses, KM_Units, KromUtils, SysUtils;


{Attack a house}
type
    TTaskAttackHouse = class(TUnitTask)
    private
      fHouse:TKMHouse;
      LocID:byte; //Current attack location
      Cells:TKMPointDirList; //List of surrounding cells and directions
      function PosUsed(aPos: TKMPoint):boolean;
    public
      constructor Create(aWarrior: TKMUnit; aHouse:TKMHouse);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      procedure Abandon; override;
      function WalkShouldAbandon:boolean; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

implementation
uses KM_PlayersCollection, KM_Units_Warrior, KM_UnitActionWalkTo, KM_Terrain;


{ TTaskAttackHouse }
constructor TTaskAttackHouse.Create(aWarrior: TKMUnit; aHouse:TKMHouse);
begin
  Inherited Create(aWarrior);
  if aHouse <> nil then fHouse := aHouse.GetSelf;

  LocID := 0;
  Cells := TKMPointDirList.Create;
  //Pass created list to make sure we Free it in the same unit
  fHouse.GetListOfCellsAround(Cells, aWarrior.GetDesiredPassability);

  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskAttackHouse.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(LocID, 4);
  Cells := TKMPointDirList.Create;
  Cells.Load(LoadStream);
end;


procedure TTaskAttackHouse.SyncLoad();
begin
  Inherited;
  fHouse := fPlayers.GetHouseByID(cardinal(fHouse));
end;


destructor TTaskAttackHouse.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer;
  FreeAndNil(Cells);
  Inherited Destroy;
end;


procedure TTaskAttackHouse.Abandon();
begin
  Inherited;
end;


{Position is [used] when there's another warrior attacking the same house from queried spot?}
function TTaskAttackHouse.PosUsed(aPos: TKMPoint):boolean;
var HitUnit: TKMUnit;
begin
  HitUnit := fPlayers.UnitsHitTest(aPos.X,aPos.Y);
  Result := (HitUnit <> nil) and (HitUnit.GetUnitTask is TTaskAttackHouse) and
    (KMSamePoint(TTaskAttackHouse(HitUnit.GetUnitTask).Cells.List[TTaskAttackHouse(HitUnit.GetUnitTask).LocID].Loc,aPos));
end;


function TTaskAttackHouse.WalkShouldAbandon:boolean;
begin
  Result := false;

  //Stop walking if the house has been destroyed already
  if fHouse.IsDestroyed then
  begin
    Result := true;
    exit;
  end;

  //See if someone beat us to this location
  if PosUsed(Cells.List[LocID].Loc) then
  begin
    Result := true;
    fPhase := 0; //Start again with a new spot
  end;
end;


procedure TTaskAttackHouse.Execute(out TaskDone:boolean);
  function PickRandomSpot(): byte;
  var i, MyCount: integer; Spots: array[1..16] of byte;
  begin
    MyCount := 0;
    for i:=1 to Cells.Count do
    if fTerrain.TileInMapCoords(Cells.List[i].Loc.X,Cells.List[i].Loc.Y) and (not PosUsed(Cells.List[i].Loc)) then //Is someone else is using it
    if fTerrain.Route_CanBeMade(fUnit.GetPosition, Cells.List[i].Loc ,fUnit.GetDesiredPassability, true) then
    begin
      inc(MyCount);
      Spots[MyCount] := i;
      //ALWAYS choose our current location if it is available to save walking
      if KMSamePoint(Cells.List[i].Loc,fUnit.GetPosition) then
      begin
        Result := i;
        exit;
      end;
    end;
    if MyCount > 0 then
      Result := Spots[Random(MyCount)+1]
    else Result := 0;
  end;
begin
  TaskDone:=false;
  //If the house is destroyed drop the task
  if fHouse.IsDestroyed then
  begin
    Abandon;
    TaskDone := true; //Drop the task
    exit;
  end;

  with fUnit do
  case fPhase of
  0: begin
       //Choose location and walk to it (will be different if we are a ranged unit)
       LocID := PickRandomSpot();
       if LocID = 0 then
       begin
         //All cells are taken/inaccessable
         Abandon;
         TaskDone:=true; //Drop the task
         exit;
       end;
       SetActionWalk(fUnit,Cells.List[LocID].Loc);
     end;
  1: begin
       //Hit/shoot the house (possibly using Fight action modified to be in house rather than unit mode? Should be pretty much the same otherwise...
       Direction:=TKMDirection(Cells.List[LocID].Dir); //Face target
       TaskDone := true;
     end;
     //...anything else?
  end;

  if TaskDone then exit;
  inc(fPhase);
  if fUnit.GetUnitAction=nil then
    fLog.AssertToLog(false,'fWarrior.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskAttackHouse.Save(SaveStream:TKMemoryStream);
begin
  Inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID
  else
    SaveStream.Write(Zero);
  SaveStream.Write(LocID);
  Cells.Save(SaveStream);
end;


end.
