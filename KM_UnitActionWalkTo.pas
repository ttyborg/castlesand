unit KM_UnitActionWalkTo;
interface
uses Classes, KM_Defaults, KromUtils, KM_Utils, KM_CommonTypes, KM_Player, KM_Units, SysUtils, Math;

{Walk to somewhere}
type
  //@All: Most of these are not being used for anything, should be cleaned up later once main processes are working.
  TInteractionStatus = (kis_None,       //We are not involved in any interaction to our knowledge (we are just walking)
                        kis_Exchanging, //We are about to exchange positions with the other unit
                        kis_Pushing,    //We are pushing an idle unit out of the way
                        kis_Pushed,     //We were pushed (idle then asked to move)
                        kis_Trying,     //We are currently stuck and trying to find a solution
                        kis_Waiting     //We are waiting for the give up timeout. During this time other units may tell us to swap with them
  );

const
  TInteractionStatusNames: array[TInteractionStatus] of string = ('None', 'Exchanging', 'Pushing', 'Pushed', 'Trying', 'Waiting');

type
  TCanWalk = (cnw_Yes,
              cnw_Exit,
              cnw_ExitNoTask);

//INTERACTION CONSTANTS:
//Times after which various things will happen. Will need to be tweaked later for optimal performance.
const
  EXCHANGE_TIMEOUT = 0;  //Pass with unit
  PUSH_TIMEOUT = 1;      //Push unit out of the way
  PUSHED_TIMEOUT = 10;   //Try a different way when pushed
  DODGE_TIMEOUT = 5;     //Pass with a unit on a tile next to our target if they want to
  AVOID_TIMEOUT = 10;    //Go around busy units
  SIDESTEP_TIMEOUT = 15; //Step to empty tile next to target
  WAITING_TIMEOUT = 40;  //After this time we can be forced to exchange
  TOTAL_GIVEUP_TIMEOUT = 200; //?????Re-route entire route avoiding other units?????


type
  TUnitActionWalkTo = class(TUnitAction)
    private
      fWalker, fLastOpponent:TKMUnit;
      fWalkFrom, fWalkTo, fAvoid, fSideStepTesting:TKMPoint;
      fWalkToSpot:boolean;
      fPass:TPassability; //Desired passability set once on Create
      DoesWalking, WaitingOnStep, fDestBlocked:boolean;
      DoExchange:boolean; //Command to make exchange maneuver with other unit, should use MakeExchange when vertex use needs to be set
      fInteractionCount, fGiveUpCount, fLastSideStepNodePos: integer;
      fInteractionStatus: TInteractionStatus;
      function AssembleTheRoute():boolean;
      function CheckCanWalk():TCanWalk;
      function DoUnitInteraction():boolean;
        //Sub functions split out of DoUnitInteraction (these are the solutions)
        function IntCheckIfPushing(fOpponent:TKMUnit):boolean;
        function IntSolutionPush(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntSolutionExchange(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntCheckIfPushed(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntSolutionDodge(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntSolutionAvoid(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntSolutionSideStep(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
        function IntSolutionGiveUp(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;

      procedure ChangeStepTo(aPos: TKMPoint);
      procedure PerformExchange(ForcedExchangePos:TKMPoint);
      procedure IncVertex;
      procedure DecVertex;
      procedure SetInitValues;
    public
      NodeList:TKMPointList;
      fVertexOccupied: TKMPoint; //Public because it needs to be used by AbandonWalk
      NodePos:integer;
      fRouteBuilt:boolean;
      Explanation:string; //Debug only, explanation what unit is doing
      constructor Create(KMUnit: TKMUnit; LocB,Avoid:TKMPoint; const aActionType:TUnitActionType=ua_Walk; const aWalkToSpot:boolean=true);
      constructor Load(LoadStream: TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      function CanAbandon: boolean;
      procedure SetPushedValues;
      function GetNextPosition():TKMPoint;
      function GetNextNextPosition():TKMPoint;
      property GetInteractionStatus:TInteractionStatus read fInteractionStatus;
      procedure Execute(KMUnit: TKMUnit; out DoEnd: Boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;
            

implementation
uses KM_Houses, KM_Game, KM_PlayersCollection, KM_Terrain, KM_Viewport, KM_UnitActionGoInOut, KM_UnitActionStay;


{ TUnitActionWalkTo }
constructor TUnitActionWalkTo.Create(KMUnit: TKMUnit; LocB, Avoid:TKMPoint; const aActionType:TUnitActionType=ua_Walk; const aWalkToSpot:boolean=true);
begin
  fLog.AssertToLog(LocB.X*LocB.Y<>0,'Illegal WalkTo 0;0');

  Inherited Create(aActionType);
  fActionName   := uan_WalkTo;
  fWalker       := KMUnit;
  fWalkFrom     := fWalker.GetPosition;
  fWalkTo       := LocB;
  fAvoid        := Avoid;
  fWalkToSpot   := aWalkToSpot;
  fPass         := fWalker.GetDesiredPassability;

  NodeList      := TKMPointList.Create; //Freed on destroy
  SetInitValues;

  if KMSamePoint(fWalkFrom,fWalkTo) then //We don't care for this case, Execute will report action is done immediately
    exit; //so we don't need to perform any more processing

  fRouteBuilt   := AssembleTheRoute();
end;


procedure TUnitActionWalkTo.SetInitValues;
begin
  NodePos       := 1;
  fRouteBuilt   := false;
  DoExchange    := false;
  DoesWalking   := false;
  WaitingOnStep := false;
  fDestBlocked := false;
  fLastSideStepNodePos := -2; //Start negitive so it is at least 2 less than NodePos at the start
  fVertexOccupied  := KMPoint(0,0);
  fSideStepTesting := KMPoint(0,0);
  fInteractionCount := 0;
  fGiveUpCount  := 0;
  fInteractionStatus := kis_None;
  fLastOpponent := nil;
end;


constructor TUnitActionWalkTo.Load(LoadStream: TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fWalker, 4); //substitute it with reference on SyncLoad
  LoadStream.Read(fLastOpponent, 4); //substitute it with reference on SyncLoad
  LoadStream.Read(fWalkFrom);
  LoadStream.Read(fWalkTo);
  LoadStream.Read(fAvoid);
  LoadStream.Read(fVertexOccupied);
  LoadStream.Read(fWalkToSpot);
  LoadStream.Read(fSideStepTesting);
  LoadStream.Read(fDestBlocked);
  LoadStream.Read(fLastSideStepNodePos);
  LoadStream.Read(fPass, SizeOf(fPass));
  LoadStream.Read(DoesWalking);
  LoadStream.Read(DoExchange);
  LoadStream.Read(WaitingOnStep);
  LoadStream.Read(fInteractionCount);
  LoadStream.Read(fGiveUpCount);
  LoadStream.Read(fInteractionStatus, SizeOf(fInteractionStatus));

  NodeList := TKMPointList.Create; //Freed on destroy
  NodeList.Load(LoadStream);
  LoadStream.Read(NodePos);
  LoadStream.Read(fRouteBuilt);
//  LoadStream.Read(Explanation, length(Explanation));
end;


procedure TUnitActionWalkTo.SyncLoad();
begin
  Inherited;
  fLog.AppendLog('TUnitActionWalkTo.SyncLoad - ', integer(fWalker));
  fWalker       := fPlayers.GetUnitByID(integer(fWalker));
  fLastOpponent := fPlayers.GetUnitByID(integer(fLastOpponent));
  fLog.AppendLog('TUnitActionWalkTo.SyncLoad - fWalker<>nil ', integer(fWalker<>nil));
end;

destructor TUnitActionWalkTo.Destroy;
begin
  FreeAndNil(NodeList);
  if not KMSamePoint(fVertexOccupied,KMPoint(0,0)) then DecVertex;
  fWalker.IsExchanging := false;
  Inherited;
end;


function TUnitActionWalkTo.CanAbandon: boolean;
begin
  Result := (fInteractionStatus <> kis_Pushed) and (fInteractionStatus <> kis_Exchanging);
end;


//This is run after creation for units that were requested to get out of the way
procedure TUnitActionWalkTo.SetPushedValues;
begin
  fInteractionStatus:=kis_Pushed; //So that unit knows it was pushed not just walking somewhere
  Explanation:='We were asked to get out of the way';
  fPass:=canWalk; //Units are allowed to step off roads when they are pushed
  //Because the passability has changed we might need to reassemble the route if it failed in create
  if not fRouteBuilt then fRouteBuilt := AssembleTheRoute();
end;


procedure TUnitActionWalkTo.PerformExchange(ForcedExchangePos:TKMPoint);
begin
  Explanation:='We were asked to exchange places';
  fInteractionStatus := kis_Exchanging;
  DoExchange := true;

  //If we are being forced to exchange then modify our route to make the exchange, then return the tile we are currently on, then continue the route
  if not KMSamePoint(ForcedExchangePos,KMPoint(0,0)) then
  begin
    Explanation:='We were forced to exchange places';
    if KMLength(ForcedExchangePos,NodeList.List[NodePos+1]) >= 1.5 then
      NodeList.InjectEntry(NodePos+1,fWalker.GetPosition); //We must back-track if we cannot continue our route from the new tile
    NodeList.InjectEntry(NodePos+1,ForcedExchangePos);
    if KMSamePoint(fWalker.GetPosition,ForcedExchangePos) then fLog.AssertToLog(false,'Perform Exchange to same place?');
    fWalker.Direction := KMGetDirection(fWalker.GetPosition,ForcedExchangePos);
    DoesWalking:=true;
  end;
end;


//Used for dodging and side stepping
procedure TUnitActionWalkTo.ChangeStepTo(aPos: TKMPoint);
begin
  if (NodePos+2 <= NodeList.Count) and (KMLength(aPos,NodeList.List[NodePos+2]) < 1.5) then
  begin
    NodeList.List[NodePos+1] := aPos; //We can simply replace the entry because it is near the next tile
    //@Krom: This will be done better later on by running a procedure to "optimise" the route after we modify it, which will remove duplicate
    //       entries like this from anywhere after NodePos. Will probably do some other stuff too, (maybe taking shortcuts if it will work) I still need to think about it.
  end
  else //Otherwise we must inject it
    NodeList.InjectEntry(NodePos+1,aPos);
  fWalker.Direction := KMGetDirection(fWalker.GetPosition,aPos); //Face the new tile
end;


function TUnitActionWalkTo.AssembleTheRoute():boolean;
var i:integer; NodeList2:TKMPointList;
begin
  //Build a piece of route to return to nearest road piece connected to destination road network
  if (fPass = canWalkRoad) and (fWalkToSpot) then //That is Citizens walking to spot
    if fTerrain.GetRoadConnectID(fWalkFrom) <> fTerrain.GetRoadConnectID(fWalkTo) then //NoRoad returns 0
      fTerrain.Route_ReturnToRoad(fWalkFrom, fTerrain.GetRoadConnectID(fWalkTo), NodeList);

  //Build a route A*
  if NodeList.Count=0 then //Build a route from scratch
    fTerrain.Route_Make(fWalkFrom, fWalkTo, fAvoid, fPass, fWalkToSpot, NodeList) //Try to make the route with fPass
  else begin //Append route to existing part
    NodeList2 := TKMPointList.Create;
    fTerrain.Route_Make(NodeList.List[NodeList.Count], fWalkTo, fAvoid, fPass, fWalkToSpot, NodeList2); //Try to make the route with fPass
    for i:=2 to NodeList2.Count do
      NodeList.AddEntry(NodeList2.List[i]);
    FreeAndNil(NodeList2);
  end;
  
  Result := NodeList.Count > 0;

  if not Result then //If route still unbuilt..
    fLog.AddToLog('Unable to make a route '+TypeToString(fWalkFrom)+' > '+TypeToString(fWalkTo)+'with default fPass');

  {if not Result then begin //Build a route with canWalk
    fTerrain.Route_Make(fWalkFrom, fWalkTo, fAvoid, canWalk, fWalkToSpot, NodeList); //Try to make a route
    Result := NodeList.Count>0;
  end;

  if not Result then
    fLog.AddToLog('Unable to make a route '+TypeToString(fWalkFrom)+' > '+TypeToString(fWalkTo)+'with canWalk');}
end;


function TUnitActionWalkTo.CheckCanWalk():TCanWalk;
  function GetOurPassability:TPassability;
  begin //Needed mainly because of routes that start off-road but also some interaction solutions may force units off roads
    if fPass = canWalkRoad then Result := canWalk
    else Result := fPass;
  end;
begin
  Result := cnw_Yes;
  //If there's an unexpected obstacle (i.e. the terrain has changed since we calculated the route)
  //Use GetOurPassability so that canWalkRoad is changed to canWalk because walking off the road does not count as an obstacle
  if not fTerrain.CheckPassability(NodeList.List[NodePos+1],GetOurPassability) then
    //Try to find a walkaround
    if fTerrain.Route_CanBeMade(fWalker.GetPosition,fWalkTo,GetOurPassability,fWalkToSpot) then
    begin
      fWalker.SetActionWalk(fWalker,fWalkTo,KMPoint(0,0),GetActionType,fWalkToSpot);
      Result:=cnw_Exit;
    end
    else
    begin
      Result:=cnw_Exit;
      if fWalker.GetUnitTask <> nil then fWalker.GetUnitTask.Abandon //Else stop and abandon the task (if we have one)
      else Result:=cnw_ExitNoTask;
    end;
end;


procedure TUnitActionWalkTo.IncVertex;
begin
  //Tell fTerrain that this vertex is being used so no other unit walks over the top of us
  fLog.AssertToLog(KMSamePoint(fVertexOccupied,KMPoint(0,0)),'Inc new vertex when old is still used?');
  if not KMSamePoint(fVertexOccupied,KMPoint(0,0)) then exit;

  fTerrain.UnitVertexAdd(KMGetDiagVertex(fWalker.PrevPosition,fWalker.NextPosition));
  fVertexOccupied := KMGetDiagVertex(fWalker.PrevPosition,fWalker.NextPosition);
end;


procedure TUnitActionWalkTo.DecVertex;
begin
  //Tell fTerrain that this vertex is not being used anymore
  fLog.AssertToLog(not KMSamePoint(fVertexOccupied,KMPoint(0,0)),'Dec unoccupied vertex?');
  if KMSamePoint(fVertexOccupied,KMPoint(0,0)) then exit;

  fTerrain.UnitVertexRem(fVertexOccupied);
  fVertexOccupied := KMPoint(0,0);
end;


function TUnitActionWalkTo.IntCheckIfPushing(fOpponent:TKMUnit):boolean;
begin
  Result := false;
  //If we are asking someone to move away then just wait until they are gone
  if (fInteractionStatus <> kis_Pushing) then exit;
    if (fLastOpponent = fOpponent) and //Make sure they are still the same unit and are still moving out of the way
      (fOpponent.GetUnitAction is TUnitActionWalkTo) then
    begin
      Explanation := 'Unit is blocking the way and has been asked to move';
      Result := true; //Means exit DoUnitInteraction
    end
    else
    begin //We pushed a unit out of the way but someone else took it's place! Now we must start over to solve problem with this new opponent
      fInteractionCount := 0;
      fGiveUpCount := 0;
      fInteractionStatus := kis_Trying;
      Explanation := 'Someone took the pushed unit''s place or it get pushed';
    end;
end;


function TUnitActionWalkTo.IntSolutionPush(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
begin
  Result := false;
  if HighestInteractionCount < PUSH_TIMEOUT then exit;
  //Ask the other unit to step aside, only if they are idle!
  if (fOpponent.GetUnitAction is TUnitActionStay) and (fOpponent.GetUnitActionType = ua_Walk)
    and (not TUnitActionStay(fOpponent.GetUnitAction).Locked) then //Unit is idle, (not working or something) and not locked
  begin //Force Unit to go away
    fInteractionStatus := kis_Pushing;
    fOpponent.SetActionWalk(fOpponent, fTerrain.GetOutOfTheWay(fOpponent.GetPosition,canWalk));
    TUnitActionWalkTo(fOpponent.GetUnitAction).SetPushedValues;
    fLastOpponent := fOpponent; //So we know who we are pushing later in case something changes
    Explanation := 'Unit was blocking the way but it has been forced to go away now';
    //Next frame tile will be free and unit will walk there
    Result := true; //Means exit DoUnitInteraction
  end;
end;


function TUnitActionWalkTo.IntSolutionExchange(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
begin
  Result := false;
  //Do not initiate exchanges if we are in DestBlocked mode, as we are zero priority and other units will
  if not fDestBlocked and (((HighestInteractionCount >= EXCHANGE_TIMEOUT) and (fInteractionStatus <> kis_Pushed)) or //When pushed this timeout/counter is different
     (fInteractionStatus = kis_Pushed)) then //If we get pushed then always try exchanging (if we are here then there is no free tile)
  begin //Try to exchange with the other unit if they are willing
    //If Unit on the way is walking somewhere and not exchanging with someone else
    if (fOpponent.GetUnitAction is TUnitActionWalkTo) and (not TUnitActionWalkTo(fOpponent.GetUnitAction).DoExchange)
      //Unit not yet arrived on tile, wait till it does, otherwise there might be 2 units on one tile
      and (not TUnitActionWalkTo(fOpponent.GetUnitAction).DoesWalking) then
    begin
      //Check unit's future position is where we are now and exchange (use NodeList rather than direction as it's not always right)
      if KMSamePoint(TUnitActionWalkTo(fOpponent.GetUnitAction).GetNextNextPosition, fWalker.GetPosition) then
      begin
        //Graphically both units are walking side-by-side, but logically they simply walk through each-other.
        TUnitActionWalkTo(fOpponent.GetUnitAction).PerformExchange(KMPoint(0,0)); //Request unforced exchange
        fLastOpponent := fOpponent; //So we know who we are supposed to be exchanging with later

        Explanation:='Unit in the way is walking in the opposite direction. Performing an exchange';
        fInteractionStatus := kis_Exchanging; //Unnecessary?
        DoExchange := true;
        //They both will exchange next tick
        Result := true; //Means exit DoUnitInteraction
      end;
      //Now try to force the unit to exchange IF they are in the waiting phase
      if TUnitActionWalkTo(fOpponent.GetUnitAction).fInteractionStatus = kis_Waiting then
      begin
        //Because we are forcing this exchange we must inject into the other unit's nodelist by passing our current position
        TUnitActionWalkTo(fOpponent.GetUnitAction).PerformExchange(fWalker.GetPosition);
        fLastOpponent := fOpponent;

        Explanation:='Unit in the way is in waiting phase. Forcing an exchange';
        fInteractionStatus := kis_Exchanging; //Unnecessary?
        DoExchange := true;
        //They both will exchange next tick
        Result := true; //Means exit DoUnitInteraction
      end;
    end;
  end;
end;


function TUnitActionWalkTo.IntCheckIfPushed(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
var TempInt: integer;
begin
  Result := false;
  //If we were asked to move away then all we are allowed to do is push and exchanging, no re-routing, dodging etc. so we must exit here before any more tests
  if fInteractionStatus = kis_Pushed then
  begin
    //If we've been trying to get out of the way for a while but we haven't found a solution, (i.e. other unit is stuck) try a different direction
    if HighestInteractionCount >= PUSHED_TIMEOUT then
    begin
      TempInt := fGiveUpCount; //Carry over the give up counter
      Create(fWalker,fTerrain.GetOutOfTheWay(fWalker.GetPosition,canWalk),fAvoid,GetActionType,fWalkToSpot);
      SetPushedValues;
      fGiveUpCount := TempInt;
//      Result := true; //Means exit DoUnitInteraction
    end;
    inc(fInteractionCount);
    inc(fGiveUpCount);
    Explanation := 'We were pushed and are now waiting for a space to clear for us';
    Result := true; //Means exit DoUnitInteraction
  end;
end;


function TUnitActionWalkTo.IntSolutionDodge(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
var i:shortint;
    TempPos: TKMPoint;
    fAltOpponent:TKMUnit;
begin
  Result := false;
  if HighestInteractionCount >= DODGE_TIMEOUT then
  begin
    //If there is a unit on one of the tiles either side of target that wants to swap, do so
    fInteractionStatus := kis_Trying;

    //Tiles to the left (-1) and right (+1) (relative to unit) of the one we are walking to
    for i := -1 to 1 do
    if i <> 0 then
    begin
    TempPos := KMGetPointInDir(fWalker.GetPosition,KMLoopDirection(byte(KMGetDirection(fWalker.GetPosition,NodeList.List[NodePos+1]))+i));
    if fTerrain.TileInMapCoords(TempPos.X,TempPos.Y) and fTerrain.CanWalkDiagonaly(fWalker.GetPosition,TempPos)
      and (fPass in fTerrain.Land[TempPos.Y,TempPos.X].Passability) then //First make sure tile is on map and walkable!
    if fTerrain.HasUnit(TempPos) then //Now see if it has a unit
    begin
      //There is a unit here, first find our alternate opponent
      fAltOpponent := fPlayers.UnitsHitTest(TempPos.X, TempPos.Y);

      //Make sure unit really exists, is walking and has arrived on tile
      if (fAltOpponent <> nil) and (fAltOpponent.GetUnitAction is TUnitActionWalkTo) and
        (not TUnitActionWalkTo(fAltOpponent.GetUnitAction).DoExchange)
        and (not TUnitActionWalkTo(fAltOpponent.GetUnitAction).DoesWalking)
        and ((not KMStepIsDiag(fWalker.NextPosition,NodeList.List[NodePos+1])) //Isn't diagonal
        or ((KMStepIsDiag(fWalker.NextPosition,NodeList.List[NodePos+1])       //...or is diagonal and...
        and not fTerrain.HasVertexUnit(KMGetDiagVertex(fWalker.GetPosition,TempPos))))) then //...vertex is free
      if KMSamePoint(TUnitActionWalkTo(fAltOpponent.GetUnitAction).GetNextNextPosition, fWalker.GetPosition) then //Now see if they want to exchange with us
      begin
        //Perform exchange from our position to TempPos
        TUnitActionWalkTo(fAltOpponent.GetUnitAction).PerformExchange(KMPoint(0,0)); //Request unforced exchange
        fLastOpponent := fAltOpponent; //So we know who we are supposed to be exchanging with later

        Explanation:='Unit on tile next to target tile wants to swap. Performing an exchange';
        fInteractionStatus := kis_Exchanging; //Unnecessary?
        DoExchange := true;
        ChangeStepTo(TempPos);
        //They both will exchange next tick
        Result := true; //Means exit DoUnitInteraction
      end;
    end;
    end;
  end;
end;


function TUnitActionWalkTo.IntSolutionAvoid(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
begin
  Result := false;
  if (HighestInteractionCount >= AVOID_TIMEOUT) or fDestBlocked then
  begin
    //If the blockage won't go away because it's busy (not walking) then try going around it by re-routing our route and avoiding that tile
    if not KMSamePoint(fOpponent.GetPosition,fWalkTo) then // Not the target position (can't go around if it is)
    if fDestBlocked or (not (fOpponent.GetUnitAction is TUnitActionWalkTo)) or ((fOpponent.GetUnitAction is TUnitActionStay) and ((TUnitActionStay(fOpponent.GetUnitAction).Locked) or (not (TUnitActionStay(fOpponent.GetUnitAction).GetActionType = ua_Walk)))) then
      if fTerrain.Route_MakeAvoid(fWalker.GetPosition,fWalkTo,fOpponent.GetPosition,fPass,fWalkToSpot,NodeList) then //Make sure the route can be made, if not, we must simply wait
      begin
        //NodeList has now been re-routed, so we need to re-init everything else and start walk again
        SetInitValues;
        Explanation := 'Unit in the way is working so we will re-route around it';
        fRouteBuilt := true;
        fDestBlocked := false;
        //Exit, then on next tick new walk will start
        Result := true; //Means exit DoUnitInteraction
      end
      else
      begin
        if not fDestBlocked then fLastOpponent := fOpponent; //First time remember oponent
        fDestBlocked := true; //When in this mode we are zero priority as we cannot reach our destination. This allows serfs with stone to get through and clear our path.
        fInteractionStatus := kis_Waiting; //If route cannot be made it means our destination is currently not available (workers in the way) So allow us to be pushed.
        Explanation := 'Our destination is blocked by busy units';
      end;
  end;
end;


function TUnitActionWalkTo.IntSolutionSideStep(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
begin
  Result := false;
  if HighestInteractionCount >= SIDESTEP_TIMEOUT then
  begin
    //Try moving to a tile next to our target, if that tile is walkable and unoccupied. If we just did that then we cannot do it again
    if (not DoExchange) and (not KMSamePoint(fOpponent.GetPosition,fWalkTo)) then //Not the target position (no point if it is)
    begin
      if not KMSamePoint(fSideStepTesting,KMPoint(0,0)) then
      begin
        //We must check the tile that we chose last time to see if it is still free (side stepping is only for when no one is or wants to use tile)
        if fPlayers.UnitsHitTest(fSideStepTesting.X,fSideStepTesting.Y) <> nil then
          //Someone took it, so exit out and hope for better luck next time
          Result := true; //Means exit DoUnitInteraction
      end
      else
      begin
        //Ask Terrain to give us a side step position. Tell it about our next position if we can
        if NodePos+2 > NodeList.Count then
          fSideStepTesting := fTerrain.FindSideStepPosition(fWalker.GetPosition,fOpponent.GetPosition,KMPoint(0,0),(NodePos-fLastSideStepNodePos < 2))
        else
          fSideStepTesting := fTerrain.FindSideStepPosition(fWalker.GetPosition,fOpponent.GetPosition,NodeList.List[NodePos+2],(NodePos-fLastSideStepNodePos < 2));
      end;
      if not KMSamePoint(fSideStepTesting,KMPoint(0,0)) then //Only proceed if it is a valid tile
        begin
          //Modify our route to go via this tile
          Explanation := 'Sidestepping to a tile next to target';
          ChangeStepTo(fSideStepTesting);
          fLastSideStepNodePos := NodePos;
          Result := true; //Means exit DoUnitInteraction
        end;
    end;
  end;
end;


function TUnitActionWalkTo.IntSolutionGiveUp(fOpponent:TKMUnit; HighestInteractionCount:integer):boolean;
begin
  Result := false;
  //todo: Add give up solution
  if fGiveUpCount >= TOTAL_GIVEUP_TIMEOUT then
  begin
    //Give up and re-route without using tile that is currently blocking us (if possible)
  end;
end;


function TUnitActionWalkTo.DoUnitInteraction():boolean;
var
  fOpponent:TKMUnit;
  HighestInteractionCount: integer;
begin
  //todo: Don't run CPU intensive tests every time, just first time then once every say 10 ticks after that

  Result:=true; //false = interaction yet unsolved, stay and wait.
  if not DO_UNIT_INTERACTION then exit;

  //If there's a unit using this vertex to walk diagonally then we must wait, they will be finished after this step
  if KMStepIsDiag(fWalker.GetPosition,NodeList.List[NodePos+1]) and
    fTerrain.HasVertexUnit(KMGetDiagVertex(fWalker.GetPosition,NodeList.List[NodePos+1])) then
  begin
    Explanation := 'Diagonal vertex is being used, we must wait';
    Result := false;
    exit;
  end;

  //If there's no unit we can keep on walking, interaction does not need to be solved
  if not fTerrain.HasUnit(NodeList.List[NodePos+1]) then exit;
  //From now on there is a blockage, so don't allow to walk unless the problem is resolved
  Result := false;

  //Find the unit that is in our path
  fOpponent := fPlayers.UnitsHitTest(NodeList.List[NodePos+1].X, NodeList.List[NodePos+1].Y);
  //If there's currently no unit in the way but tile is pre-occupied
  if fOpponent = nil then begin
    //Do nothing and wait till unit is actually there so we can interact with it
    Explanation:='Can''t walk. No Unit in the way but tile is occupied';
    exit;
  end;
  //If we are in DestBlocked mode then only use our counter so we are always zero priority until our path clears
  if ((fOpponent.GetUnitAction is TUnitActionWalkTo) and not fDestBlocked) then
    HighestInteractionCount := max(fInteractionCount,TUnitActionWalkTo(fOpponent.GetUnitAction).fInteractionCount)
  else HighestInteractionCount := fInteractionCount;

  //Animals are low priority compared to other units
  if (fWalker.GetUnitType in [ut_Wolf..ut_Duck])and(not(fOpponent.GetUnitType in [ut_Wolf..ut_Duck])) then begin
    Explanation:='Unit is animal and therefore has no priority in movement';
    exit;
  end;

  if (fOpponent.GetUnitAction is TUnitActionGoInOut) then begin //Unit is walking into house, we can wait
    Explanation:='Unit is walking into house, we can wait';
    exit;
  end;

  //INTERACTION SOLUTIONS: Split into different sections or "solutions". If true returned it means exit.

  //If we are asking someone to move away then just wait until they are gone
  if IntCheckIfPushing(fOpponent) then exit;
  if IntSolutionPush(fOpponent,HighestInteractionCount) then exit;
  if IntSolutionExchange(fOpponent,HighestInteractionCount) then exit;
  if IntCheckIfPushed(fOpponent,HighestInteractionCount) then exit;
  if IntSolutionDodge(fOpponent,HighestInteractionCount) then exit;
  if IntSolutionAvoid(fOpponent,HighestInteractionCount) then exit;
  if IntSolutionSideStep(fOpponent,HighestInteractionCount) then exit;
  if IntSolutionGiveUp(fOpponent,HighestInteractionCount) then exit;

  //We will allow other units to force an exchange with us as we haven't found a solution
  if HighestInteractionCount >= WAITING_TIMEOUT then fInteractionStatus := kis_Waiting;

  //If we haven't exited yet we must increment the counters so we know how long we've been here
  inc(fInteractionCount);
  inc(fGiveUpCount);
end;


function TUnitActionWalkTo.GetNextPosition():TKMPoint;
begin
  if NodePos > NodeList.Count then
    Result:=KMPoint(0,0) //Error
  else Result:=NodeList.List[NodePos];
end;


function TUnitActionWalkTo.GetNextNextPosition():TKMPoint;
begin
  if NodePos+1 > NodeList.Count then
    Result:=KMPoint(0,0) //Error
  else Result:=NodeList.List[NodePos+1];
end;


procedure TUnitActionWalkTo.Execute(KMUnit: TKMUnit; out DoEnd: Boolean);
var
  DX,DY:shortint; WalkX,WalkY,Distance:single; AllowToWalk:boolean; CanWalk: TCanWalk;
begin
  DoEnd := false;
  GetIsStepDone := false;
  DoesWalking := false; //Set it to false at start of update

  //Happens whe e.g. Serf stays in front of Store and gets Deliver task
  if KMSamePoint(fWalkFrom,fWalkTo) then begin
    DoEnd := true;
    exit;
  end;

  //Somehow route was not built, this is an error
  if not fRouteBuilt then begin
    fLog.AddToLog('Unable to walk a route since it''s unbuilt');
    fViewport.SetCenter(fWalker.GetPosition.X,fWalker.GetPosition.Y);
    fGame.PauseGame(true);
    //todo: Pop-up some message
  end;

  //Walk complete - NodePos cannot be greater than NodeCount (this should not happen, cause is unknown but for now this check stops crashes)
  if NodePos > NodeList.Count then begin
    if KMStepIsDiag(fWalker.PrevPosition,fWalker.NextPosition) then DecVertex; //Unoccupy vertex
    fWalker.IsExchanging := false; //Disable sliding (in case it was set in previous step)
    DoEnd:=true;
    exit;
  end;

  //Execute the route in series of moves
  Distance := ACTION_TIME_DELTA * fWalker.GetSpeed;

  //Check if unit has arrived on tile
  if Equals(fWalker.PositionF.X,NodeList.List[NodePos].X,Distance/2) and
     Equals(fWalker.PositionF.Y,NodeList.List[NodePos].Y,Distance/2) then
  begin
    if (NodePos > 1) and (not WaitingOnStep) and KMStepIsDiag(NodeList.List[NodePos-1],NodeList.List[NodePos]) then DecVertex; //Unoccupy vertex
      WaitingOnStep := true;

    GetIsStepDone := true; //Unit stepped on a new tile
    fWalker.IsExchanging := false; //Disable sliding (in case it was set in previous step)

    //Set precise position to avoid rounding errors
    fWalker.PositionF := KMPointF(NodeList.List[NodePos].X,NodeList.List[NodePos].Y);

    //Walk complete
    if (NodePos=NodeList.Count) or ((not fWalkToSpot) and (KMLength(fWalker.GetPosition,fWalkTo) < 1.5)) then
    begin
      if not fWalkToSpot then
        fWalker.Direction := KMGetDirection(NodeList.List[NodePos],fWalkTo); //Face tile (e.g. worker)
      DoEnd:=true;
      exit;
    end;

    //This is sometimes caused by unit interaction changing the route so simply ignore it
    if KMSamePoint(NodeList.List[NodePos],NodeList.List[NodePos+1]) then
    begin
      inc(NodePos); //Inc the node pos and exit so this step is simply skipped
      exit; //Will take next step during next execute
    end;
    //Update unit direction according to next Node
    fWalker.Direction := KMGetDirection(NodeList.List[NodePos],NodeList.List[NodePos+1]);
      //fLog.AssertToLog(false,'Walk to same place?');

    //Check if we can walk to next tile in the route
    CanWalk := CheckCanWalk;
    if CanWalk <> cnw_Yes then
      if CanWalk = cnw_Exit then exit //Task has been abandoned, not our job to clean up
      else
      begin
        DoEnd := true; //If unit has no task and so we must abandon the walk
        exit;
      end;

    //Perform exchange
    //Both exchanging units have DoExchange:=true assigned by 1st unit, hence 2nd should not try doing UnitInteraction!
    if DoExchange then begin
      inc(NodePos);
      fWalker.PrevPosition:=fWalker.NextPosition;
      fWalker.NextPosition:=NodeList.List[NodePos];
      //fLog.AddToLog('DoExchange');
      //We don't need to perform UnitWalk since exchange means the same tiles will be occupied,
      //and without UnitWalk there's a guarantee no other unit will step on this tile!
      fInteractionStatus := kis_None;
      DoExchange := false;
      fWalker.IsExchanging := true; //So unit knows that it must slide
      fInteractionCount := 0;
      if KMStepIsDiag(fWalker.PrevPosition,fWalker.NextPosition) then IncVertex; //Occupy the vertex
    end else
    begin
      AllowToWalk := DoUnitInteraction();

      if not AllowToWalk then
      begin
        DoEnd := KMUnit.GetUnitType in [ut_Wolf..ut_Duck]; //Animals have no tasks hence they can choose new WalkTo spot no problem
        exit; //Do no further walking until unit interaction is solved
      end else fInteractionCount := 0; //Reset the counter when there is no blockage and we can walk
      if fInteractionStatus = kis_None then fGiveUpCount := 0; //Reset the give up counter if we are walking normally (not exchanging or dodging)

      inc(NodePos);
      fWalker.PrevPosition:=fWalker.NextPosition;
      fWalker.NextPosition:=NodeList.List[NodePos];
      fTerrain.UnitWalk(fWalker.PrevPosition,fWalker.NextPosition); //Pre-occupy next tile
      if KMStepIsDiag(fWalker.PrevPosition,fWalker.NextPosition) then IncVertex; //Occupy the vertex
    end;
    fSideStepTesting := KMPoint(0,0); //Reset it because now we are taking a new step (this interaction is solved)
  end;
  WaitingOnStep := false;

  if NodePos>NodeList.Count then
    fLog.AssertToLog(false,'TUnitAction is being overrun for some reason - error!');

  WalkX := NodeList.List[NodePos].X - fWalker.PositionF.X;
  WalkY := NodeList.List[NodePos].Y - fWalker.PositionF.Y;
  DX := sign(WalkX); //-1,0,1
  DY := sign(WalkY); //-1,0,1

  if (DX <> 0) and (DY <> 0) then
    Distance := Distance / 1.41; {sqrt (2) = 1.41421 }

  fWalker.PositionF:=KMPointF(fWalker.PositionF.X + DX*min(Distance,abs(WalkX)),
                              fWalker.PositionF.Y + DY*min(Distance,abs(WalkY)));

  inc(fWalker.AnimStep);
  DoesWalking:=true; //Now it's definitely true that unit did walked one step
end;


procedure TUnitActionWalkTo.Save(SaveStream:TKMemoryStream);
begin
  Inherited;
  if fWalker <> nil then
    SaveStream.Write(fWalker.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  if fLastOpponent <> nil then
    SaveStream.Write(fLastOpponent.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(fWalkFrom);
  SaveStream.Write(fWalkTo);
  SaveStream.Write(fAvoid);
  SaveStream.Write(fVertexOccupied);
  SaveStream.Write(fWalkToSpot);
  SaveStream.Write(fSideStepTesting);
  SaveStream.Write(fDestBlocked);
  SaveStream.Write(fLastSideStepNodePos);
  SaveStream.Write(fPass,SizeOf(fPass));
  SaveStream.Write(DoesWalking);
  SaveStream.Write(DoExchange);
  SaveStream.Write(WaitingOnStep);
  SaveStream.Write(fInteractionCount);
  SaveStream.Write(fGiveUpCount);
  SaveStream.Write(fInteractionStatus,SizeOf(fInteractionStatus));
  NodeList.Save(SaveStream);
  SaveStream.Write(NodePos);
  SaveStream.Write(fRouteBuilt);
//  SaveStream.Write(Explanation, length(Explanation));
end;


end.
