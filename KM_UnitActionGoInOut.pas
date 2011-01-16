unit KM_UnitActionGoInOut;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, SysUtils, KM_CommonTypes, KM_Defaults, KM_Houses, KM_Units, KM_Utils;


{This is a [fairly :P] simple action making unit go inside/outside of house}
type
  TUnitActionGoInOut = class(TUnitAction)
    private
      fStep:single;
      fHouse:TKMHouse;
      fDirection:TGoInDirection;
      fDoor:TKMPointF;
      fStreet:TKMPoint;
      fHasStarted, fWaitingForPush, fUsingDoorway, fUsedDoorway:boolean;
      procedure IncDoorway;
      procedure DecDoorway;
    public
      constructor Create(aAction: TUnitActionType; aDirection:TGoInDirection; aHouse:TKMHouse);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad; override;
      destructor Destroy; override;
      function ValidTileToGo(LocX, LocY:word; WalkUnit:TKMUnit):boolean; //using X,Y looks more clear
      property GetHasStarted: boolean read fHasStarted;
      function Execute(KMUnit: TKMUnit):TActionResult; override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;


implementation
uses KM_PlayersCollection, KM_Terrain, KM_UnitActionStay;


constructor TUnitActionGoInOut.Create(aAction: TUnitActionType; aDirection:TGoInDirection; aHouse:TKMHouse);
begin
  Inherited Create(aAction);
  fActionName     := uan_GoInOut;
  Locked          := true;
  //We might stuck trying to exit when house gets destroyed (1)
  //and we might be dying in destroyed house (2)
  if aHouse<>nil then fHouse := aHouse.GetHousePointer
                 else fHouse := nil;
  fDirection      := aDirection;
  fHasStarted     := false;
  fWaitingForPush := false;
  fUsingDoorway   := true;

  if fDirection = gd_GoInside then
    fStep := 1  //go Inside (one cell up)
  else
    fStep := 0; //go Outside (one cell down)
end;


constructor TUnitActionGoInOut.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fStep);
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fDirection, SizeOf(fDirection));
  LoadStream.Read(fDoor);
  LoadStream.Read(fStreet);
  LoadStream.Read(fHasStarted);
  LoadStream.Read(fWaitingForPush);
  LoadStream.Read(fUsingDoorway);
  LoadStream.Read(fUsedDoorway);
end;


procedure TUnitActionGoInOut.SyncLoad();
begin
  Inherited;
  fHouse := fPlayers.GetHouseByID(cardinal(fHouse));
end;


destructor TUnitActionGoInOut.Destroy;
begin
  if fUsedDoorway then DecDoorway;
  fPlayers.CleanUpHousePointer(fHouse);
  Inherited;
end;


procedure TUnitActionGoInOut.IncDoorway;
begin
  if fUsedDoorway then
  begin
    fLog.AssertToLog(false,'Inc doorway when already in use?');
    exit;
  end;
  if fHouse<>nil then inc(fHouse.DoorwayUse);
  fUsedDoorway := true;
end;


procedure TUnitActionGoInOut.DecDoorway;
begin
  if not fUsedDoorway then
  begin
    fLog.AssertToLog(false,'Dec doorway when not in use?');
    exit;
  end;
  if fHouse<>nil then dec(fHouse.DoorwayUse);
  fUsedDoorway := false;
end;


//Check that tile is walkable and there's no unit blocking it or that unit can be pushed away
function TUnitActionGoInOut.ValidTileToGo(LocX, LocY:word; WalkUnit:TKMUnit):boolean; //using X,Y looks more clear
var aUnit:TKMUnit;
begin
  Result := fTerrain.TileInMapCoords(LocX, LocY)
        and (fTerrain.CheckPassability(KMPoint(LocX, LocY), WalkUnit.GetDesiredPassability));

  if not Result then exit;

  if not (fTerrain.Land[LocY,LocX].IsUnit = nil) then begin
    aUnit := fTerrain.UnitsHitTest(LocX, LocY); //Let's see who is standing there
    Result := (aUnit <> nil) and (aUnit.GetUnitAction is TUnitActionStay)
                             and (not TUnitActionStay(aUnit.GetUnitAction).Locked);
    if Result then
      aUnit.SetActionWalkPushed( fTerrain.GetOutOfTheWay(aUnit.GetPosition,KMPoint(0,0),CanWalk) );
  end;
end;


function TUnitActionGoInOut.Execute(KMUnit: TKMUnit):TActionResult;
var Distance:single;
begin
  Result := ActContinues;

  if not fHasStarted then //Set Door and Street locations
  begin
    fUsingDoorway := true; //By default we will use the doorway rather than a diagonal entrance

    fDoor := KMPointF(KMUnit.GetPosition.X, KMUnit.GetPosition.Y - fStep);
    fStreet := KMPoint(KMUnit.GetPosition.X, KMUnit.GetPosition.Y + 1 - round(fStep));
    if (fHouse<>nil) and (byte(fHouse.GetHouseType) in [1..length(HouseDAT)]) then
      fDoor.X := fDoor.X + (HouseDAT[byte(fHouse.GetHouseType)].EntranceOffsetXpx/4)/CELL_SIZE_PX;


    if fDirection=gd_GoInside then
    begin
      KMUnit.Direction := dir_N;  //one cell up
      KMUnit.Thought := th_None;
      KMUnit.UpdateNextPosition(KMPoint(KMUnit.GetPosition.X,KMUnit.GetPosition.Y-1));
      fTerrain.UnitRem(KMUnit.GetPosition); //Unit does not occupy a tile while inside
    end;

    //Attempt to find a tile bellow the door we can walk to. Otherwise we can push idle units away.
    if fDirection=gd_GoOutside then begin

      if ValidTileToGo(fStreet.X, fStreet.Y, KMUnit) then begin
        fStreet.X := fStreet.X;
        fUsingDoorway := true;
      end else
      if ValidTileToGo(fStreet.X-1, fStreet.Y, KMUnit) then begin
        fStreet.X := fStreet.X - 1;
        fUsingDoorway := false;
      end else
      if ValidTileToGo(fStreet.X+1, fStreet.Y, KMUnit) then begin
        fStreet.X := fStreet.X + 1;
        fUsingDoorway := false;
      end else
        exit; //Do not exit the house if all street tiles are blocked by non-idle units, just wait

      if (fTerrain.Land[fStreet.Y,fStreet.X].IsUnit <> nil) then
      begin
        fWaitingForPush := true;
        fHasStarted:=true;
        exit; //Wait until my push request is dealt with before we move out
      end;

      //All checks done so unit can walk out now
      KMUnit.Direction := KMGetDirection(KMPointRound(fDoor) ,fStreet);
      KMUnit.UpdateNextPosition(fStreet);
      fTerrain.UnitAdd(KMUnit.NextPosition, KMUnit); //Unit was not occupying tile while inside
      if (KMUnit.GetHome<>nil)and(KMUnit.GetHome.GetHouseType=ht_Barracks) //Unit home is barracks
      and(KMUnit.GetHome = fHouse) then //And is the house we are walking from
        TKMHouseBarracks(KMUnit.GetHome).RecruitsList.Remove(KMUnit);
    end;

    if fUsingDoorway then
    begin
      IncDoorway;
      if fHouse<>nil then
        KMUnit.IsExchanging := (fHouse.DoorwayUse > 1);
    end;
    
    fHasStarted:=true;
  end;


  if fWaitingForPush then
  begin
    if (fTerrain.Land[fStreet.Y,fStreet.X].IsUnit = nil) then
    begin
      fWaitingForPush := false;
      KMUnit.Direction := KMGetDirection(KMPointRound(fDoor) ,fStreet);
      KMUnit.UpdateNextPosition(fStreet);
      fTerrain.UnitAdd(KMUnit.NextPosition, KMUnit); //Unit was not occupying tile while inside
      if (KMUnit.GetHome<>nil)and(KMUnit.GetHome.GetHouseType=ht_Barracks) //Unit home is barracks
      and(KMUnit.GetHome = fHouse) then //And is the house we are walking from
        TKMHouseBarracks(KMUnit.GetHome).RecruitsList.Remove(KMUnit);
    end
    else exit; //Wait until my push request is dealt with before we move out
  end;

  Assert((fHouse = nil) or KMSamePoint(KMPointRound(fDoor),fHouse.GetEntrance)); //Must always go in/out the entrance of the house
  Distance:= ACTION_TIME_DELTA * KMUnit.GetSpeed;
  //Actual speed is slower if we are moving diagonally, due to the fact we are moving in X and Y
  if (fStreet.X-fDoor.X <> 0) then
    Distance := Distance / 1.41; {sqrt (2) = 1.41421 }

  fStep := fStep - Distance * shortint(fDirection);
  KMUnit.PositionF := KMPointF(Mix(fStreet.X,fDoor.X,fStep),Mix(fStreet.Y,fDoor.Y,fStep));
  KMUnit.Visible := (fHouse=nil) or (fHouse.IsDestroyed) or (fStep >= 0.3); //Make unit invisible when it's inside of House

  if (fStep<=0)or(fStep>=1) then
  begin
    Result := ActDone;
    KMUnit.IsExchanging := false;
    if fUsedDoorway then DecDoorway;
    if fDirection = gd_GoInside then
    begin
      KMUnit.PositionF := fDoor;
      if (KMUnit.GetHome<>nil)and(KMUnit.GetHome.GetHouseType=ht_Barracks) //Unit home is barracks
      and(KMUnit.GetHome = fHouse) then //And is the house we are walking into
        TKMHouseBarracks(KMUnit.GetHome).RecruitsList.Add(KMUnit); //Add the recruit once it is inside, otherwise it can be equipped while still walking in!
      if (fHouse<>nil) and not fHouse.IsDestroyed then
        KMUnit.SetInHouse(fHouse);
      if (fHouse<>nil) and (fHouse.IsDestroyed) then
        fTerrain.UnitAdd(KMPointRound(KMUnit.PositionF), KMUnit); //Unit was not occupying a tile while walking in
    end
    else
    begin
      KMUnit.PositionF := KMPointF(fStreet.X,fStreet.Y);
      KMUnit.SetInHouse(nil); //We are not in a house any longer
    end;
  end
  else
    inc(KMUnit.AnimStep);
end;


procedure TUnitActionGoInOut.Save(SaveStream:TKMemoryStream);
begin
  Inherited;
  SaveStream.Write(fStep);
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(fDirection, SizeOf(fDirection));
  SaveStream.Write(fDoor);
  SaveStream.Write(fStreet);
  SaveStream.Write(fHasStarted);
  SaveStream.Write(fWaitingForPush);
  SaveStream.Write(fUsingDoorway);
  SaveStream.Write(fUsedDoorway);
end;


end.
