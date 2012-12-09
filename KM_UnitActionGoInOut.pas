unit KM_UnitActionGoInOut;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Units, KM_UnitGroups;


type
  TBestExit = (be_None, be_Left, be_Center, be_Right);

  {This is a [fairly :P] simple action making unit go inside/outside of house}
  TUnitActionGoInOut = class(TUnitAction)
  private
    fStep:single;
    fHouse:TKMHouse;
    fDirection:TGoInDirection;
    fDoor:TKMPoint;
    fStreet:TKMPoint;
    fHasStarted:boolean;
    fPushedUnit: TKMUnit;
    fWaitingForPush:boolean;
    fUsedDoorway:boolean;
    procedure IncDoorway;
    procedure DecDoorway;
    function FindBestExit(aLoc: TKMPoint): TBestExit;
    function TileHasIdleUnit(X,Y: Word): TKMUnit;
    procedure WalkIn;
    procedure WalkOut;
  public
    constructor Create(aUnit: TKMUnit; aAction: TUnitActionType; aDirection:TGoInDirection; aHouse:TKMHouse);
    constructor Load(LoadStream:TKMemoryStream); override;
    procedure SyncLoad; override;
    destructor Destroy; override;
    function ActName: TUnitActionName; override;
    function GetExplanation:string; override;
    property GetHasStarted: boolean read fHasStarted;
    property GetWaitingForPush: boolean read fWaitingForPush;
    function GetDoorwaySlide(aCheck: TCheckAxis): Single;
    function Execute: TActionResult; override;
    procedure Save(SaveStream: TKMemoryStream); override;
  end;


implementation
uses KM_Player, KM_PlayersCollection, KM_Resource, KM_Terrain, KM_UnitActionStay,
  KM_Units_Warrior, KM_UnitTaskMining;


{ TUnitActionGoInOut }
constructor TUnitActionGoInOut.Create(aUnit: TKMUnit; aAction: TUnitActionType; aDirection:TGoInDirection; aHouse:TKMHouse);
begin
  inherited Create(aUnit, aAction, True);

  //We might stuck trying to exit when house gets destroyed (1)
  //and we might be dying in destroyed house (2)
  fHouse          := aHouse.GetHousePointer;
  fDirection      := aDirection;
  fHasStarted     := False;
  fWaitingForPush := False;

  if fDirection = gd_GoInside then
    fStep := 1  //go Inside (one cell up)
  else
    fStep := 0; //go Outside (one cell down)
end;


constructor TUnitActionGoInOut.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fStep);
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fPushedUnit, 4);
  LoadStream.Read(fDirection, SizeOf(fDirection));
  LoadStream.Read(fDoor);
  LoadStream.Read(fStreet);
  LoadStream.Read(fHasStarted);
  LoadStream.Read(fWaitingForPush);
  LoadStream.Read(fUsedDoorway);
end;


procedure TUnitActionGoInOut.SyncLoad;
begin
  inherited;
  fHouse := fPlayers.GetHouseByID(cardinal(fHouse));
  fPushedUnit := fPlayers.GetUnitByID(cardinal(fPushedUnit));
end;


destructor TUnitActionGoInOut.Destroy;
begin
  if fUsedDoorway then
    DecDoorway;

  fPlayers.CleanUpHousePointer(fHouse);
  fPlayers.CleanUpUnitPointer(fPushedUnit);

  //A bug can occur because this action is destroyed early when a unit is told to die.
  //If we are still invisible then TTaskDie assumes we are inside and creates a new
  //GoOut action. Therefore if we are invisible we do not occupy a tile.
  if (fDirection = gd_GoOutside)
  and fHasStarted
  and not fUnit.Visible
  and (fTerrain.Land[fUnit.NextPosition.Y,fUnit.NextPosition.X].IsUnit = fUnit) then
  begin
    fTerrain.UnitRem(fUnit.NextPosition);
    if not KMSamePoint(fDoor, KMPoint(0,0)) then
      fUnit.PositionF := KMPointF(fDoor); //Put us back inside the house
  end;

  if (fDirection = gd_GoOutside) and fUnit.Visible then
    fUnit.SetInHouse(nil); //We are not in any house now

  inherited;
end;


function TUnitActionGoInOut.ActName: TUnitActionName;
begin
  Result := uan_GoInOut;
end;


function TUnitActionGoInOut.GetExplanation: string;
begin
  Result := 'Walking in/out';
end;


procedure TUnitActionGoInOut.IncDoorway;
begin
  Assert(not fUsedDoorway, 'Inc doorway when already in use?');

  if fHouse<>nil then inc(fHouse.DoorwayUse);
  fUsedDoorway := true;
end;


procedure TUnitActionGoInOut.DecDoorway;
begin
  Assert(fUsedDoorway, 'Dec doorway when not in use?');

  if fHouse<>nil then dec(fHouse.DoorwayUse);
  fUsedDoorway := false;
end;


//Attempt to find a tile below the door (on the street) we can walk to
//We can push idle units away. Check center first
function TUnitActionGoInOut.FindBestExit(aLoc: TKMPoint): TBestExit;
var
  U: TKMUnit;
begin
  if fUnit.CanStepTo(aLoc.X, aLoc.Y) then
    Result := be_Center
  else
  if fUnit.CanStepTo(aLoc.X-1, aLoc.Y) then
    Result := be_Left
  else
  if fUnit.CanStepTo(aLoc.X+1, aLoc.Y) then
    Result := be_Right
  else
  begin
    //U could be nil if tile is unwalkable for some reason
    U := TileHasIdleUnit(aLoc.X, aLoc.Y);
    if U <> nil then
      Result := be_Center
    else
    begin
      U := TileHasIdleUnit(aLoc.X-1, aLoc.Y);
      if U <> nil then
        Result := be_Left
      else
      begin
        U := TileHasIdleUnit(aLoc.X+1, aLoc.Y);
        if U <> nil then
          Result := be_Right
        else
          Result := be_None;
      end;
    end;

    if U <> nil then
    begin
      fPushedUnit := U.GetUnitPointer;
      fPushedUnit.SetActionWalkPushed(fTerrain.GetOutOfTheWay(U.GetPosition, KMPoint(0,0), CanWalk));
    end;
  end;
end;


//Check that tile is walkable and there's no unit blocking it or that unit can be pushed away
function TUnitActionGoInOut.TileHasIdleUnit(X,Y: Word): TKMUnit;
var U: TKMUnit;
begin
  Result := nil;

  if fTerrain.TileInMapCoords(X,Y)
  and (fTerrain.CheckPassability(KMPoint(X,Y), fUnit.DesiredPassability))
  and (fTerrain.CanWalkDiagonaly(fUnit.GetPosition, KMPoint(X,Y)))
  and (fTerrain.Land[Y,X].IsUnit <> nil) then //If there's some unit we need to do a better check on him
  begin
    U := fTerrain.UnitsHitTest(X,Y); //Let's see who is standing there

    //Check that the unit is idling and not an enemy warrior, so that we can push it away
    if (U <> nil)
    and (U.GetUnitAction is TUnitActionStay)
    and not TUnitActionStay(U.GetUnitAction).Locked
    and (not (U is TKMUnitWarrior) or (fPlayers.CheckAlliance(U.Owner,fUnit.Owner) = at_Ally)) then
      Result := U;
  end;
end;


procedure TUnitActionGoInOut.WalkIn;
begin
  fUnit.Direction := dir_N;  //one cell up
  fUnit.NextPosition := KMPoint(fUnit.GetPosition.X, fUnit.GetPosition.Y-1);
  fTerrain.UnitRem(fUnit.GetPosition); //Unit does not occupy a tile while inside

  //We are walking straight
  if fStreet.X = fDoor.X then
   IncDoorway;
end;


//Start walking out of the house. unit is no longer in the house
procedure TUnitActionGoInOut.WalkOut;
begin
  fUnit.Direction := KMGetDirection(fDoor, fStreet);
  fUnit.NextPosition := fStreet;
  fTerrain.UnitAdd(fUnit.NextPosition, fUnit); //Unit was not occupying tile while inside

  if (fUnit.GetHome <> nil)
  and (fUnit.GetHome.HouseType = ht_Barracks) //Unit home is barracks
  and (fUnit.GetHome = fHouse) then //And is the house we are walking from
    TKMHouseBarracks(fHouse).RecruitsList.Remove(fUnit);

  //Woodcutter takes his axe with him when going to chop trees
  if (fUnit.UnitType = ut_Woodcutter)
  and (fUnit.UnitTask.TaskName = utn_Mining)
  and (TTaskMining(fUnit.UnitTask).WorkPlan.GatheringScript = gs_WoodCutterCut)
  and (fUnit.GetHome <> nil)
  and (fUnit.GetHome.HouseType = ht_Woodcutters)
  and (fUnit.GetHome = fHouse) then //And is the house we are walking from
    fHouse.fCurrentAction.SubActionRem([ha_Flagpole]);

  //We are walking straight
  if fStreet.X = fDoor.X then
   IncDoorway;
end;


function TUnitActionGoInOut.GetDoorwaySlide(aCheck: TCheckAxis): Single;
var Offset: Integer;
begin
  if aCheck = ax_X then
    Offset := fResource.HouseDat[fHouse.HouseType].EntranceOffsetXpx - CELL_SIZE_PX div 2
  else
    Offset := fResource.HouseDat[fHouse.HouseType].EntranceOffsetYpx;

  if (fHouse = nil) or not fHasStarted then
    Result := 0
  else
    Result := Mix(0, Offset/CELL_SIZE_PX, fStep);
end;


function TUnitActionGoInOut.Execute: TActionResult;
var Distance:single; U:TKMUnit;
begin
  Result := ActContinues;

  if not fHasStarted then
  begin
    //Set Door and Street locations
    fDoor := KMPoint(fUnit.GetPosition.X, fUnit.GetPosition.Y - round(fStep));
    fStreet := KMPoint(fUnit.GetPosition.X, fUnit.GetPosition.Y + 1 - round(fStep));

    case fDirection of
      gd_GoInside:  WalkIn;
      gd_GoOutside: begin
                      case FindBestExit(fStreet) of
                        be_Left:    fStreet.X := fStreet.X - 1;
                        be_Center:  ;
                        be_Right:   fStreet.X := fStreet.X + 1;
                        be_None:    Exit; //All street tiles are blocked by busy units. Do not exit the house, just wait
                      end;

                      //If we have pushed an idling unit, wait till it goes away
                      //Wait until our push request is dealt with before we move out
                      if (fPushedUnit <> nil) then
                      begin
                        fWaitingForPush := True;
                        fHasStarted := True;
                        Exit;
                      end
                      else
                        WalkOut; //Otherwise we can walk out now
                    end;
    end;

    fHasStarted := True;
  end;


  if fWaitingForPush then
  begin
    U := fTerrain.Land[fStreet.Y,fStreet.X].IsUnit;
    if (U = nil) then //Unit has walked away
    begin
      fWaitingForPush := False;
      fPlayers.CleanUpUnitPointer(fPushedUnit);
      WalkOut;
    end
    else
    begin //There's still some unit - we can't go outside
      if (U <> fPushedUnit) then //The unit has switched places with another one, so we must start again
      begin
        fHasStarted := False;
        fWaitingForPush := False;
        fPlayers.CleanUpUnitPointer(fPushedUnit);
      end;
      Exit;
    end;
  end;

  //IsExchanging can be updated while we have completed less than 20% of the move. If it is changed after that
  //the unit makes a noticable "jump". This needs to be updated after starting because we don't know about an
  //exchanging unit until they have also started walking (otherwise only 1 of the units will have IsExchanging = true)
  if (
      ((fDirection = gd_GoOutside) and (fStep < 0.2)) or
      ((fDirection = gd_GoInside) and (fStep > 0.8))
      )
  and (fStreet.X = fDoor.X) //We are walking straight
  and (fHouse <> nil) then
    fUnit.IsExchanging := (fHouse.DoorwayUse > 1);

  Assert((fHouse = nil) or KMSamePoint(fDoor, fHouse.GetEntrance)); //Must always go in/out the entrance of the house
  Distance := fResource.UnitDat[fUnit.UnitType].Speed;

  //Actual speed is slower if we are moving diagonally, due to the fact we are moving in X and Y
  if (fStreet.X - fDoor.X <> 0) then
    Distance := Distance / 1.41; {sqrt (2) = 1.41421 }

  fStep := fStep - Distance * shortint(fDirection);
  fUnit.PositionF := KMLerp(fDoor, fStreet, fStep);
  fUnit.Visible := (fHouse = nil) or (fHouse.IsDestroyed) or (fStep > 0); //Make unit invisible when it's inside of House

  if (fStep <= 0) or (fStep >= 1) then
  begin
    Result := ActDone;
    fUnit.IsExchanging := False;
    if fUsedDoorway then DecDoorway;
    if fDirection = gd_GoInside then
    begin
      fUnit.PositionF := KMPointF(fDoor);
      if (fUnit.GetHome <> nil)
      and (fUnit.GetHome = fHouse)
      and (fUnit.GetHome.HouseType = ht_Barracks) //Unit home is barracks
      and not fUnit.GetHome.IsDestroyed then //And is the house we are walking into and it's not destroyed
        TKMHouseBarracks(fUnit.GetHome).RecruitsList.Add(fUnit); //Add the recruit once it is inside, otherwise it can be equipped while still walking in!
      //Set us as inside even if the house is destroyed. In that case UpdateVisibility will sort things out.

      //When any woodcutter returns home - add an Axe
      if (fUnit.UnitType = ut_Woodcutter)
      and (fUnit.GetHome <> nil)
      and (fUnit.GetHome.HouseType = ht_Woodcutters)
      and (fUnit.GetHome = fHouse) then //And is the house we are walking from
        fHouse.fCurrentAction.SubActionAdd([ha_Flagpole]);

      if fHouse <> nil then fUnit.SetInHouse(fHouse);
    end
    else
    begin
      fUnit.PositionF := KMPointF(fStreet);
      fUnit.SetInHouse(nil); //We are not in a house any longer
    end;
  end
  else
    inc(fUnit.AnimStep);
end;


procedure TUnitActionGoInOut.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fStep);
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  if fPushedUnit <> nil then
    SaveStream.Write(fPushedUnit.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fDirection, SizeOf(fDirection));
  SaveStream.Write(fDoor);
  SaveStream.Write(fStreet);
  SaveStream.Write(fHasStarted);
  SaveStream.Write(fWaitingForPush);
  SaveStream.Write(fUsedDoorway);
end;


end.
