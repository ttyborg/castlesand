unit KM_Units;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, KromUtils,
  KM_CommonClasses, KM_Defaults, KM_Utils, KM_Terrain, KM_Houses, KM_Points;

//Memo on directives:
//Dynamic - declared and used (overriden) occasionally
//Virtual - declared and used (overriden) always
//Abstract - declared but must be overriden in child classes

type
  TKMUnit = class;
  TKMUnitWorker = class;

  TActionResult = (ActContinues, ActDone, ActAborted); //

  TUnitAction = class
  protected
    fActionType: TUnitActionType;
    fUnit: TKMUnit;
  public
    Locked: boolean; //Means that unit can't take part in interaction, must stay on its tile
    StepDone: boolean; //True when single action element is done (unit walked to new tile, single attack loop done)
    constructor Create(aUnit: TKMUnit; aActionType: TUnitActionType; aLocked: Boolean);
    constructor Load(LoadStream:TKMemoryStream); virtual;
    procedure SyncLoad; virtual;

    function ActName: TUnitActionName; virtual; abstract;
    property ActionType: TUnitActionType read fActionType;
    function GetExplanation:string; virtual; abstract;
    function Execute: TActionResult; virtual; abstract;
    procedure Save(SaveStream:TKMemoryStream); virtual;
    procedure Paint; virtual;
  end;

  TTaskResult = (TaskContinues, TaskDone); //There's no difference between Done and Aborted

  TUnitTask = class
  protected
    fTaskName: TUnitTaskName;
    fUnit: TKMUnit; //Unit who's performing the Task
    fPhase: Byte;
    fPhase2: Byte;
  public
    constructor Create(aUnit: TKMUnit);
    constructor Load(LoadStream: TKMemoryStream); virtual;
    procedure SyncLoad; virtual;
    destructor Destroy; override;

    property Phase: Byte read fPhase write fPhase;
    property TaskName: TUnitTaskName read fTaskName;
    function WalkShouldAbandon: Boolean; dynamic;

    function Execute: TTaskResult; virtual; abstract;
    procedure Save(SaveStream: TKMemoryStream); virtual;
  end;


  TKMUnit = class
  protected //Accessible for child classes
    fID:integer; //unique unit ID, used for save/load to sync to
    fUnitType: TUnitType;
    fUnitTask: TUnitTask;
    fCurrentAction: TUnitAction;
    fThought:TUnitThought;
    fHitPoints:byte;
    fHitPointCounter: cardinal;
    fCondition:integer; //Unit condition, when it reaches zero unit should die
    fOwner:TPlayerIndex;
    fHome:TKMHouse;
    fPosition: TKMPointF;
    fVisible:boolean;
    fIsDead:boolean;
    fKillASAP:boolean;
    fPointerCount:integer;
    fInHouse: TKMHouse; //House we are currently in
    fCurrPosition: TKMPoint; //Where we are now
    fPrevPosition: TKMPoint; //Where we were
    fNextPosition: TKMPoint; //Where we will be. Next tile in route or same tile if stay on place
    fDirection: TKMDirection; //

    procedure SetDirection(aValue:TKMDirection);
    procedure SetAction(aAction: TUnitAction; aStep:integer=0);
    function GetSlide(aCheck:TCheckAxis): single;
    function CanAccessHome: Boolean;

    procedure UpdateHunger;
    procedure UpdateFOW;
    procedure UpdateThoughts;
    function UpdateVisibility:boolean;
    procedure UpdateHitPoints;
  public
    AnimStep: integer;
    IsExchanging:boolean; //Current walk is an exchange, used for sliding

    constructor Create(aOwner: shortint; PosX, PosY:integer; aUnitType:TUnitType);
    constructor Load(LoadStream:TKMemoryStream); dynamic;
    procedure SyncLoad; virtual;
    destructor Destroy; override;

    function GetUnitPointer:TKMUnit; //Returns self and adds one to the pointer counter
    procedure ReleaseUnitPointer;  //Decreases the pointer counter
    property GetPointerCount:integer read fPointerCount;

    procedure KillUnit; virtual; //Creates TTaskDie which then will Close the unit from further access
    procedure CloseUnit(aRemoveTileUsage:boolean=true); dynamic;

    property ID:integer read fID;
    property PrevPosition: TKMPoint read fPrevPosition;
    property NextPosition: TKMPoint read fNextPosition;
    property Direction:TKMDirection read fDirection write SetDirection;

    function HitTest(X,Y:integer; const UT:TUnitType = ut_Any): Boolean;
    procedure UpdateNextPosition(aLoc:TKMPoint);

    procedure SetActionAbandonWalk(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
    procedure SetActionFight(aAction: TUnitActionType; aOpponent:TKMUnit);
    procedure SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouse: TKMHouse); virtual;
    procedure SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
    procedure SetActionStorm(aRow:integer);
    procedure SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);

    procedure SetActionWalk(aLocB:TKMPoint; aActionType:TUnitActionType; aDistance:single; aTargetUnit:TKMUnit; aTargetHouse:TKMHouse);
    procedure SetActionWalkToHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TUnitActionType = ua_Walk);
    procedure SetActionWalkToUnit(aUnit:TKMUnit; aDistance:single; aActionType:TUnitActionType=ua_Walk);
    procedure SetActionWalkToSpot(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aUseExactTarget:boolean=true);
    procedure SetActionWalkPushed(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);

    procedure Feed(Amount:single);
    procedure AbandonWalk;
    function GetDesiredPassability: TPassability;
    property GetOwner:TPlayerIndex read fOwner;
    property GetHome:TKMHouse read fHome;
    property GetUnitAction: TUnitAction read fCurrentAction;
    property GetUnitTask: TUnitTask read fUnitTask;
    property SetUnitTask: TUnitTask read fUnitTask write fUnitTask;
    property UnitType: TUnitType read fUnitType;
    function GetUnitTaskText:string;
    function GetUnitActText:string;
    property Condition: integer read fCondition write fCondition;
    procedure SetFullCondition;
    function  HitPointsDecrease(aAmount:integer):boolean;
    procedure HitPointsIncrease(aAmount:integer);
    property GetHitPoints:byte read fHitPoints;
    function GetMaxHitPoints:byte;
    procedure CancelUnitTask;
    property Visible: boolean read fVisible write fVisible;
    procedure SetInHouse(aInHouse:TKMHouse);
    property GetInHouse: TKMHouse read fInHouse;
    property IsDead:boolean read fIsDead;
    function IsDeadOrDying:boolean;
    function IsArmyUnit:boolean;
    function CanGoEat:boolean;
    property GetPosition:TKMPoint read fCurrPosition;
    procedure SetPosition(aPos:TKMPoint);
    property PositionF:TKMPointF read fPosition write fPosition;
    property Thought:TUnitThought read fThought write fThought;
    function GetMovementVector: TKMPointF;
    function IsIdle: Boolean;

    function PickRandomSpot(aList: TKMPointDirList; out Loc: TKMPointDir): Boolean;

    function CanStepTo(X,Y: Integer): Boolean;
    function CanWalkTo(aTo: TKMPoint; aDistance: Single): Boolean; overload;
    function CanWalkTo(aTo: TKMPoint; aPass: TPassability; aDistance: Single): Boolean; overload;
    function CanWalkTo(aFrom, aTo: TKMPoint; aDistance: Single): Boolean; overload;
    function CanWalkTo(aFrom, aTo: TKMPoint; aPass: TPassability; aDistance: Single): Boolean; overload;
    function CanWalkTo(aFrom: TKMPoint; aHouse: TKMHouse; aPass: TPassability; aDistance: Single): Boolean; overload;
    function CanWalkDiagonaly(aFrom, aTo: TKMPoint): Boolean;
    procedure VertexRem(aLoc: TKMPoint);
    function VertexUsageCompatible(aFrom, aTo: TKMPoint): Boolean;
    procedure VertexAdd(aFrom, aTo: TKMPoint);
    procedure Walk(aFrom, aTo: TKMPoint);


    procedure Save(SaveStream:TKMemoryStream); virtual;
    function UpdateState:boolean; virtual;
    procedure Paint; virtual;
  end;

  //This is a common class for units going out of their homes for resources
  TKMUnitCitizen = class(TKMUnit)
  private
    function FindHome:boolean;
    function InitiateMining:TUnitTask;
    procedure IssueResourceDepletedMessage;
  public
    function UpdateState:boolean; override;
    procedure Paint; override;
  end;


  TKMUnitRecruit = class(TKMUnit)
  private
    function FindHome: Boolean;
    function InitiateActivity: TUnitTask;
  public
    function UpdateState: Boolean; override;
    procedure Paint; override;
    procedure DestroyInBarracks;
  end;

  //Serf class - transports all goods in game between houses
  TKMUnitSerf = class(TKMUnit)
  private
    fCarry: TResourceType;
  public
    constructor Create(aOwner: TPlayerIndex; PosX, PosY:integer; aUnitType:TUnitType);
    constructor Load(LoadStream:TKMemoryStream); override;
    procedure Save(SaveStream:TKMemoryStream); override;

    procedure Deliver(aFrom: TKMHouse; toHouse: TKMHouse; Res: TResourceType; aID: integer); overload;
    procedure Deliver(aFrom: TKMHouse; toUnit: TKMUnit; Res: TResourceType; aID: integer); overload;
    function TryDeliverFrom(aFrom: TKMHouse): Boolean;

    property Carry: TResourceType read fCarry;
    procedure CarryGive(Res:TResourceType);
    procedure CarryTake;
    procedure SetNewDelivery(aDelivery:TUnitTask);

    function UpdateState:boolean; override;
    procedure Paint; override;
  end;

  //Worker class - builds everything in game
  TKMUnitWorker = class(TKMUnit)
  public
    procedure BuildHouse(aHouse: TKMHouse; aIndex: Integer);
    procedure BuildHouseRepair(aHouse: TKMHouse; aIndex: Integer);
    procedure BuildField(aField: TFieldType; aLoc: TKMPoint; aIndex: Integer);
    procedure BuildHouseArea(aHouseType: THouseType; aLoc: TKMPoint; aIndex: Integer);

    function UpdateState:boolean; override;
    procedure Paint; override;
  end;


  //Animals
  TKMUnitAnimal = class(TKMUnit)
  private
    fFishCount:byte; //1-5
  public
    constructor Create(aOwner: TPlayerIndex; PosX, PosY:integer; aUnitType:TUnitType); overload;
    constructor Load(LoadStream:TKMemoryStream); override;
    property FishCount: byte read fFishCount;
    function ReduceFish:boolean;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState:boolean; override;
    procedure Paint; override;
  end;


  TKMUnitsCollection = class(TKMList)
  private
    function GetUnit(aIndex: Integer): TKMUnit;
    procedure SetUnit(aIndex: Integer; aItem: TKMUnit);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(aOwner: TPlayerIndex; aUnitType: TUnitType; PosX, PosY: Integer; AutoPlace: boolean = true; RequiredWalkConnect: Byte = 0): TKMUnit;
    function AddGroup(aOwner: TPlayerIndex; aUnitType: TUnitType; PosX, PosY: Integer; aDir: TKMDirection; aUnitPerRow, aUnitCount: word; aMapEditor: boolean = false): TKMUnit;
    property Units[aIndex: Integer]: TKMUnit read GetUnit write SetUnit; default; //Use instead of Items[.]
    procedure RemoveUnit(aUnit: TKMUnit);
    procedure OwnerUpdate(aOwner: TPlayerIndex);
    function HitTest(X, Y: Integer; const UT: TUnitType = ut_Any): TKMUnit;
    function GetUnitByID(aID: Integer): TKMUnit;
    function GetClosestUnit(aPoint: TKMPoint): TKMUnit;
    function GetTotalPointers: Integer;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;
    procedure Paint;
  end;


implementation
uses
  KM_Game, KM_RenderPool, KM_RenderAux, KM_TextLibrary, KM_PlayersCollection,
  KM_Units_Warrior, KM_Resource, KM_Log, KM_MessageStack,

  KM_UnitActionAbandonWalk,
  KM_UnitActionFight,
  KM_UnitActionGoInOut,
  KM_UnitActionStay,
  KM_UnitActionStormAttack,
  KM_UnitActionWalkTo,

  KM_UnitTaskAttackHouse,
  KM_UnitTaskBuild,
  KM_UnitTaskDelivery,
  KM_UnitTaskDie,
  KM_UnitTaskGoEat,
  KM_UnitTaskGoHome,
  KM_UnitTaskGoOutShowHungry,
  KM_UnitTaskMining,
  KM_UnitTaskSelfTrain,
  KM_UnitTaskThrowRock;


{ TKMUnitCitizen }
//Find home for unit
function TKMUnitCitizen.FindHome:boolean;
var H:TKMHouse;
begin
  Result:=false;
  H := fPlayers.Player[fOwner].Houses.FindEmptyHouse(fUnitType,fCurrPosition);
  if H<>nil then begin
    fHome  := H.GetHousePointer;
    Result := true;
  end;
end;


procedure TKMUnitCitizen.Paint;
var
  Act: TUnitActionType;
  XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  if fCurrentAction = nil then exit;
  Act := fCurrentAction.fActionType;

  XPaintPos := fPosition.X + UNIT_OFF_X + GetSlide(ax_X);
  YPaintPos := fPosition.Y + UNIT_OFF_Y + GetSlide(ax_Y);

  case fCurrentAction.fActionType of
    ua_Walk:
      begin
        fRenderPool.AddUnit(fUnitType, ua_Walk, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
        if fResource.UnitDat[fUnitType].SupportsAction(ua_WalkArm) then
          fRenderPool.AddUnit(fUnitType, ua_WalkArm, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, false);
      end;
    ua_Work..ua_Eat:
        fRenderPool.AddUnit(fUnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
    ua_WalkArm .. ua_WalkBooty2:
      begin
        fRenderPool.AddUnit(fUnitType, ua_Walk, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
        fRenderPool.AddUnit(fUnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, false);
      end;
  end;

  if fThought <> th_None then
    fRenderPool.AddUnitThought(fThought, XPaintPos, YPaintPos);
end;


function TKMUnitCitizen.UpdateState:boolean;
var H:TKMHouseInn;
begin
  Result:=true; //Required for override compatibility
  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at start of TKMUnitCitizen.UpdateState',fCurrPosition);

  //Reset unit activity if home was destroyed, except when unit is dying or eating (finish eating/dying first)
  if (fHome <> nil)
  and fHome.IsDestroyed
  and not(fUnitTask is TTaskDie)
  and not(fUnitTask is TTaskGoEat) then
  begin
    if (fCurrentAction is TUnitActionWalkTo)
    and not TUnitActionWalkTo(GetUnitAction).DoingExchange then
      AbandonWalk;
    FreeAndNil(fUnitTask);
    fPlayers.CleanUpHousePointer(fHome);
  end;

  if inherited UpdateState then exit;
  if IsDead then exit; //Caused by SelfTrain.Abandoned

  fThought := th_None;

{  if fUnitTask=nil then //Which is always nil if 'inherited UpdateState' works properly
  if not TestHunger then
  if not TestHasHome then
  if not TestAtHome then
  if not TestMining then
    Idle..}


  if fCondition<UNIT_MIN_CONDITION then
  begin
    H := fPlayers.Player[fOwner].FindInn(fCurrPosition,Self,not fVisible);
    if H<>nil then
      fUnitTask := TTaskGoEat.Create(H,Self)
    else
      if (fHome <> nil) and not fVisible then
        fUnitTask:=TTaskGoOutShowHungry.Create(Self)
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    if fHome=nil then
      if FindHome then
        fUnitTask := TTaskGoHome.Create(Self) //Home found - go there
      else begin
        fThought := th_Quest; //Always show quest when idle, unlike serfs who randomly show it
        SetActionStay(60, ua_Walk) //There's no home
      end
    else
      if fVisible then //Unit is not at home, but it has one
      begin
        if CanAccessHome then
          fUnitTask := TTaskGoHome.Create(Self)
        else
          SetActionStay(60, ua_Walk) //Home can't be reached
      end else begin
        fUnitTask := InitiateMining; //Unit is at home, so go get a job
        if fUnitTask=nil then //We didn't find any job to do - rest at home
          SetActionStay(fResource.HouseDat[fHome.HouseType].WorkerRest*10, ua_Walk);
      end;

  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at end of TKMUnitCitizen.UpdateState',fCurrPosition);
end;


procedure TKMUnitCitizen.IssueResourceDepletedMessage;
var
  Msg: Word;
begin
  case fHome.HouseType of
    ht_Quary:     Msg := TX_MSG_STONE_DEPLETED;
    ht_CoalMine:  Msg := TX_MSG_COAL_DEPLETED;
    ht_IronMine:  Msg := TX_MSG_IRON_DEPLETED;
    ht_GoldMine:  Msg := TX_MSG_GOLD_DEPLETED;
    ht_FisherHut: if not fTerrain.CanFindFishingWater(KMPointBelow(fHome.GetEntrance), fResource.UnitDat[fUnitType].MiningRange) then
                    Msg := TX_MSG_FISHERMAN_TOO_FAR
                  else
                    Msg := TX_MSG_FISHERMAN_CANNOT_CATCH;
    else         Msg := 0;
  end;

  Assert(Msg <> 0, fResource.HouseDat[fHome.HouseType].HouseName+' resource cant possibly deplet');

  if fOwner = MyPlayer.PlayerIndex then //Don't show message for other players
    fGame.fGamePlayInterface.MessageIssue(mkHouse, fTextLibrary[Msg], fHome.GetEntrance);

  fHome.ResourceDepletedMsgIssued := True;
end;


function TKMUnitCitizen.InitiateMining:TUnitTask;
var Res:integer; TM: TTaskMining;
begin
  Result := nil;

  if not KMSamePoint(fCurrPosition, fHome.GetEntrance) then
    raise ELocError.Create('Mining from wrong spot',fCurrPosition);

  Res := 1;
  //Check if House has production orders
  //Ask the house what order we should make
  if fResource.HouseDat[fHome.HouseType].DoesOrders then
  begin
    Res := fHome.PickOrder;
    if Res = 0 then Exit;
  end;

  TM := TTaskMining.Create(Self, fResource.HouseDat[fHome.HouseType].ResOutput[Res]);

  if TM.WorkPlan.ResourceDepleted and not fHome.ResourceDepletedMsgIssued then
    IssueResourceDepletedMessage;

  if TM.WorkPlan.IsIssued
  and ((TM.WorkPlan.Resource1 = rt_None) or (fHome.CheckResIn(TM.WorkPlan.Resource1) >= TM.WorkPlan.Count1))
  and ((TM.WorkPlan.Resource2 = rt_None) or (fHome.CheckResIn(TM.WorkPlan.Resource2) >= TM.WorkPlan.Count2))
  and (fHome.CheckResOut(TM.WorkPlan.Product1) < MAX_RES_IN_HOUSE)
  and (fHome.CheckResOut(TM.WorkPlan.Product2) < MAX_RES_IN_HOUSE) then
  begin
    if fResource.HouseDat[fHome.HouseType].DoesOrders then
      fHome.ResEditOrder(Res, -1); //Take order
    Result := TM;
  end else
  begin
    TM.Free;
    Result := nil;
  end;
end;


{ TKMUnitRecruit }
function TKMUnitRecruit.FindHome:boolean;
var H:TKMHouse;
begin
  Result  := false;
  H := fPlayers.Player[fOwner].Houses.FindEmptyHouse(fUnitType,fCurrPosition);
  if H<>nil then begin
    fHome  := H.GetHousePointer;
    Result := true;
  end;
end;


procedure TKMUnitRecruit.Paint;
var Act:TUnitActionType; XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  if fCurrentAction = nil then exit;
  Act := fCurrentAction.fActionType;

  XPaintPos := fPosition.X + UNIT_OFF_X + GetSlide(ax_X);
  YPaintPos := fPosition.Y + UNIT_OFF_Y + GetSlide(ax_Y);

  case fCurrentAction.fActionType of
    ua_Walk:
      begin
        fRenderPool.AddUnit(fUnitType, ua_Walk, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
        if fResource.UnitDat[fUnitType].SupportsAction(ua_WalkArm) then
          fRenderPool.AddUnit(fUnitType, ua_WalkArm, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, false);
      end;
    ua_Work..ua_Eat:
        fRenderPool.AddUnit(fUnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
    ua_WalkArm .. ua_WalkBooty2:
      begin
        fRenderPool.AddUnit(fUnitType, ua_Walk, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);
        fRenderPool.AddUnit(fUnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, false);
      end;
  end;

  if fThought<>th_None then
    fRenderPool.AddUnitThought(fThought, XPaintPos, YPaintPos);
end;


procedure TKMUnitRecruit.DestroyInBarracks;
begin
  if fPlayers.Selected = Self then fPlayers.Selected := nil;
  if fGame.fGamePlayInterface.ShownUnit = Self then fGame.fGamePlayInterface.ShowUnitInfo(nil);

  //Dispose of current action/task BEFORE we close the unit (action might need to check fPosition if recruit was about to walk out to eat)
  //Normally this isn't required because TTaskDie takes care of it all, but recruits in barracks don't use TaskDie.
  SetAction(nil);
  FreeAndNil(fUnitTask);

  CloseUnit(False); //Don't remove tile usage, we are inside the barracks
end;


function TKMUnitRecruit.UpdateState:boolean;
var H: TKMHouseInn;
begin
  Result := True; //Required for override compatibility
  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at start of TKMUnitRecruit.UpdateState',fCurrPosition);

  //Reset unit activity if home was destroyed, except when unit is dying or eating (finish eating/dying first)
  if (fHome <> nil)
  and fHome.IsDestroyed
  and not(fUnitTask is TTaskDie)
  and not(fUnitTask is TTaskGoEat) then
  begin
    if (fCurrentAction is TUnitActionWalkTo)
    and not TUnitActionWalkTo(GetUnitAction).DoingExchange then
      AbandonWalk;
    FreeAndNil(fUnitTask);
    fPlayers.CleanUpHousePointer(fHome);
  end;

  if inherited UpdateState then exit;
  if IsDead then exit; //Caused by SelfTrain.Abandoned

  fThought := th_None;

  if fCondition<UNIT_MIN_CONDITION then
  begin
    H:=fPlayers.Player[fOwner].FindInn(fCurrPosition,Self,not fVisible);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self)
    else
      if (fHome <> nil) and not fVisible then
        fUnitTask:=TTaskGoOutShowHungry.Create(Self)
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    if fHome=nil then
      if FindHome then
        fUnitTask := TTaskGoHome.Create(Self) //Home found - go there
      else begin
        fThought := th_Quest; //Always show quest when idle, unlike serfs who randomly show it
        SetActionStay(120, ua_Walk) //There's no home
      end
    else
      if fVisible then //Unit is not at home, but it has one
      begin
        if CanAccessHome then
          fUnitTask := TTaskGoHome.Create(Self)
        else
          SetActionStay(60, ua_Walk) //Home can't be reached
      end else begin
        fUnitTask := InitiateActivity; //Unit is at home, so go get a job
        if fUnitTask=nil then //We didn't find any job to do - rest at home
          SetActionStay(Max(fResource.HouseDat[fHome.HouseType].WorkerRest,1)*10, ua_Walk); //By default it's 0, don't scan that often
      end;

  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at end of TKMUnitRecruit.UpdateState',fCurrPosition);
end;


function TKMUnitRecruit.InitiateActivity:TUnitTask;
var
  Enemy:TKMUnit;
begin
  Result := nil;

  //See if we are in a tower and have something to throw
  if (not (fHome is TKMHouseTower)) or ((not FREE_ROCK_THROWING) and (fHome.CheckResIn(rt_Stone) <= 0)) then
    Exit;

  Enemy := fTerrain.UnitsHitTestWithinRad(fCurrPosition, RANGE_WATCHTOWER_MIN, RANGE_WATCHTOWER_MAX, fOwner, at_Enemy, dir_NA);

  //Note: In actual game there might be two Towers nearby,
  //both throwing a stone into the same enemy. We should not
  //negate that fact, thats real-life situation.

  if Enemy <> nil then
    Result := TTaskThrowRock.Create(Self, Enemy);
end;


{ TKMSerf }
constructor TKMUnitSerf.Create(aOwner: TPlayerIndex; PosX, PosY: integer; aUnitType: TUnitType);
begin
  inherited;
  fCarry := rt_None;
end;


procedure TKMUnitSerf.Deliver(aFrom, toHouse: TKMHouse; Res: TResourceType; aID: integer);
begin
  fThought := th_None; //Clear ? thought
  fUnitTask := TTaskDeliver.Create(Self, aFrom, toHouse, Res, aID);
end;


procedure TKMUnitSerf.Deliver(aFrom: TKMHouse; toUnit: TKMUnit; Res: TResourceType; aID: integer);
begin
  fThought := th_None; //Clear ? thought
  fUnitTask := TTaskDeliver.Create(Self, aFrom, toUnit, Res, aID);
end;


function TKMUnitSerf.TryDeliverFrom(aFrom: TKMHouse): Boolean;
var T: TUnitTask;
begin
  //Remember current task
  T := fUnitTask;
  //Try to get a new one
  fPlayers.Player[GetOwner].Deliveries.Queue.AskForDelivery(Self, aFrom);

  //Return True if we've got a new deliery
  Result := fUnitTask <> T;

  //If we got ourselves a new task then skip to resource-taking part, as we are already in this house
  if Result and (aFrom <> nil) then
    fUnitTask.Phase := 2; //Skip  of the new task
end;


constructor TKMUnitSerf.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fCarry, SizeOf(fCarry));
end;


procedure TKMUnitSerf.Paint;
var Act:TUnitActionType; XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  if fCurrentAction = nil then exit;
  Act := fCurrentAction.fActionType;

  XPaintPos := fPosition.X + UNIT_OFF_X + GetSlide(ax_X);
  YPaintPos := fPosition.Y + UNIT_OFF_Y + GetSlide(ax_Y);

  fRenderPool.AddUnit(UnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);

  if fUnitTask is TTaskDie then exit; //Do not show unnecessary arms

  if Carry <> rt_None then
    fRenderPool.AddUnitCarry(Carry, Direction, AnimStep, XPaintPos, YPaintPos)
  else
    fRenderPool.AddUnit(UnitType, ua_WalkArm, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, false);

  if fThought <> th_None then
    fRenderPool.AddUnitThought(fThought, XPaintPos, YPaintPos);
end;


procedure TKMUnitSerf.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fCarry, SizeOf(fCarry));
end;


function TKMUnitSerf.UpdateState:boolean;
var
  H:TKMHouseInn;
  OldThought:TUnitThought;
  WasIdle:Boolean;
begin
  Result:=true; //Required for override compatibility
  WasIdle := IsIdle;
  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at start of TKMUnitSerf.UpdateState',fCurrPosition);
  if inherited UpdateState then exit;

  OldThought:=fThought;
  fThought:=th_None;

  if fCondition<UNIT_MIN_CONDITION then begin
    H:=fPlayers.Player[fOwner].FindInn(fCurrPosition,Self);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self);
  end;

  //Only show quest thought if we have been idle since the last update (not HadTask)
  //and not thinking anything else (e.g. death)
  if fUnitTask=nil then begin
    if WasIdle and (OldThought=th_None) and (KaMRandom(2)=0) then
      fThought:=th_Quest;
    SetActionStay(60,ua_Walk); //Stay idle
  end;

  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at end of TKMUnitSerf.UpdateState',fCurrPosition);
end;


procedure TKMUnitSerf.CarryGive(Res:TResourceType);
begin
  Assert(fCarry=rt_None, 'Giving Serf another Carry');
  fCarry := Res;
end;


procedure TKMUnitSerf.CarryTake;
begin
  Assert(Carry <> rt_None, 'Taking wrong resource from Serf');
  fCarry := rt_None;
end;


procedure TKMUnitSerf.SetNewDelivery(aDelivery:TUnitTask);
begin
  fUnitTask := aDelivery;
end;


{ TKMWorker }
procedure TKMUnitWorker.BuildHouse(aHouse: TKMHouse; aIndex: Integer);
begin
  SetUnitTask := TTaskBuildHouse.Create(Self, aHouse, aIndex);
end;


procedure TKMUnitWorker.BuildField(aField: TFieldType; aLoc: TKMPoint; aIndex: Integer);
begin
  case aField of
    ft_Road: SetUnitTask := TTaskBuildRoad.Create(Self, aLoc, aIndex);
    ft_Corn: SetUnitTask := TTaskBuildField.Create(Self, aLoc, aIndex);
    ft_Wine: SetUnitTask := TTaskBuildWine.Create(Self, aLoc, aIndex);
    ft_Wall: SetUnitTask := TTaskBuildWall.Create(Self, aLoc, aIndex);
    else     begin
              Assert(false, 'Unexpected Field Type');
              SetUnitTask := nil;
              Exit;
             end;
  end;
end;


procedure TKMUnitWorker.BuildHouseArea(aHouseType: THouseType; aLoc: TKMPoint; aIndex: Integer);
begin
  SetUnitTask := TTaskBuildHouseArea.Create(Self, aHouseType, aLoc, aIndex);
end;


procedure TKMUnitWorker.BuildHouseRepair(aHouse: TKMHouse; aIndex: Integer);
begin
  SetUnitTask := TTaskBuildHouseRepair.Create(Self, aHouse, aIndex);
end;


procedure TKMUnitWorker.Paint;
var XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  if fCurrentAction = nil then exit;

  XPaintPos := fPosition.X + UNIT_OFF_X + GetSlide(ax_X);
  YPaintPos := fPosition.Y + UNIT_OFF_Y + GetSlide(ax_Y);

  fRenderPool.AddUnit(UnitType, fCurrentAction.fActionType, Direction, AnimStep, XPaintPos, YPaintPos, fPlayers.Player[fOwner].FlagColor, true);

  if fThought <> th_None then
    fRenderPool.AddUnitThought(fThought, XPaintPos, YPaintPos);
end;


function TKMUnitWorker.UpdateState: Boolean;
var
  H: TKMHouseInn;
begin
  Result:=true; //Required for override compatibility
  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at start of TKMUnitWorker.UpdateState',fCurrPosition);
  if inherited UpdateState then exit;

  if fCondition < UNIT_MIN_CONDITION then
  begin
    H := fPlayers.Player[fOwner].FindInn(fCurrPosition, Self);
    if H <> nil then
      fUnitTask := TTaskGoEat.Create(H, Self);
  end;

  if (fThought = th_Build)and(fUnitTask = nil) then
    fThought := th_None; //Remove build thought if we are no longer doing anything

  //If we are still stuck on a house for some reason, get off it ASAP
  Assert(fTerrain.Land[fCurrPosition.Y, fCurrPosition.X].TileLock <> tlHouse);

  if (fUnitTask = nil) and (fCurrentAction = nil) then SetActionStay(20, ua_Walk);

  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at end of TKMUnitWorker.UpdateState',fCurrPosition);
end;


{ TKMUnitAnimal }
constructor TKMUnitAnimal.Create(aOwner: TPlayerIndex; PosX, PosY:integer; aUnitType:TUnitType);
begin
  inherited;

  //Always start with 5 fish in the group
  if aUnitType = ut_Fish then
    fFishCount := 5;
end;


constructor TKMUnitAnimal.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fFishCount);
end;


function TKMUnitAnimal.ReduceFish: Boolean;
begin
  Result := fUnitType = ut_Fish;
  if not Result then Exit;

  if fFishCount > 1 then
    Dec(fFishCount)
  else
    KillUnit;
end;


procedure TKMUnitAnimal.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fFishCount);
end;


function TKMUnitAnimal.UpdateState: Boolean;
var
  Spot:TKMPoint; //Target spot where unit will go
  SpotJit:byte;
begin
  Result:=true; //Required for override compatibility

  fCurrPosition := KMPointRound(fPosition);

  if fCurrentAction=nil then
    raise ELocError.Create(fResource.UnitDat[UnitType].UnitName + ' has no action at start of TKMUnitAnimal.UpdateState', fCurrPosition);

  case fCurrentAction.Execute of
    ActContinues: exit;
    ActDone:      FreeAndNil(fCurrentAction);
    ActAborted:   FreeAndNil(fCurrentAction);
  end;
  fCurrPosition := KMPointRound(fPosition);


  Assert((fUnitTask = nil) or (fUnitTask is TTaskDie));
  if fUnitTask is TTaskDie then
  case fUnitTask.Execute of
    TaskContinues:  exit;
    TaskDone:       Assert(false); //TTaskDie never returns TaskDone yet
  end;


  //First make sure the animal isn't stuck (check passibility of our position)
  if (not fTerrain.CheckPassability(fCurrPosition,GetDesiredPassability))
  or fTerrain.CheckAnimalIsStuck(fCurrPosition,GetDesiredPassability) then begin
    KillUnit; //Animal is stuck so it dies
    exit;
  end;

  SpotJit := 16; //Initial Spot jitter, it limits number of Spot guessing attempts reducing the range to 0
  repeat //Where unit should go, keep picking until target is walkable for the unit
    Dec(SpotJit);
    Spot := fTerrain.EnsureTileInMapCoords(fCurrPosition.X + KaMRandomS(SpotJit), fCurrPosition.Y + KaMRandomS(SpotJit));
  until (SpotJit = 0) or (CanWalkTo(Spot, 0));

  if KMSamePoint(fCurrPosition, Spot) then
    SetActionStay(20, ua_Walk)
  else
    SetActionWalkToSpot(Spot);

  if fCurrentAction = nil then
    raise ELocError.Create(fResource.UnitDat[UnitType].UnitName + ' has no action at end of TKMUnitAnimal.UpdateState', fCurrPosition);
end;


//For fish the action is the number of fish in the group
procedure TKMUnitAnimal.Paint;
var
  Act: TUnitActionType;
  XPaintPos, YPaintPos: single;
begin
  inherited;
  if fCurrentAction = nil then exit;
  if fUnitType = ut_Fish then
    Act := FishCountAct[fFishCount]
  else
    Act := fCurrentAction.fActionType;

  XPaintPos := fPosition.X + UNIT_OFF_X + GetSlide(ax_X);
  YPaintPos := fPosition.Y + UNIT_OFF_Y + GetSlide(ax_Y);

  //Make fish/watersnakes to be more visible in the MapEd
  if (fGame.GameState = gsEditor) and (fUnitType in [ut_Fish, ut_Watersnake, ut_Seastar]) then
    fRenderAux.Circle(fPosition.X - 0.5,
                      fPosition.Y - fTerrain.HeightAt(fPosition.X - 0.5, fPosition.Y - 0.5) / CELL_HEIGHT_DIV - 0.5,
                      0.5, $30FF8000, $60FF8000);

  //Animals share the same WalkTo logic as other units and they exchange places if necessary
  fRenderPool.AddUnit(fUnitType, Act, Direction, AnimStep, XPaintPos, YPaintPos, $FFFFFFFF, True);
end;


{ TKMUnit }
constructor TKMUnit.Create(aOwner:TPlayerIndex; PosX, PosY:integer; aUnitType:TUnitType);
begin
  inherited Create;
  fID           := fGame.GetNewID;
  fPointerCount := 0;
  fIsDead       := false;
  fKillASAP     := false;
  fThought      := th_None;
  fHome         := nil;
  fInHouse      := nil;
  fPosition.X   := PosX;
  fPosition.Y   := PosY;
  fCurrPosition := KMPoint(PosX,PosY);
  fPrevPosition := fCurrPosition; //Init values
  fNextPosition := fCurrPosition; //Init values
  fOwner        := aOwner;
  fUnitType     := aUnitType;
  Direction     := dir_S;
  fVisible      := true;
  IsExchanging  := false;
  AnimStep      := UnitStillFrames[Direction]; //Use still frame at begining, so units don't all change frame on first tick
  //Units start with a random amount of condition ranging from 3/4 to full.
  //This means that they won't all go eat at the same time and cause crowding, blockages, food shortages and other problems.
  if fGame.GameState <> gsEditor then
    fCondition    := UNIT_MAX_CONDITION - KaMRandom(UNIT_MAX_CONDITION div 4)
  else
    fCondition    := UNIT_MAX_CONDITION div 2;
  fHitPoints    := GetMaxHitPoints;
  fHitPointCounter := 1;

  SetActionStay(10, ua_Walk);
  fTerrain.UnitAdd(NextPosition,Self);
end;


destructor TKMUnit.Destroy;
begin
  if not IsDead then fTerrain.UnitRem(NextPosition); //Happens only when removing player from map on GameStart (network)
  FreeAndNil(fCurrentAction);
  FreeAndNil(fUnitTask);
  SetInHouse(nil); //Free pointer
  inherited;
end;


constructor TKMUnit.Load(LoadStream:TKMemoryStream);
var HasTask,HasAct:boolean; TaskName:TUnitTaskName; ActName: TUnitActionName;
begin
  inherited Create;
  LoadStream.Read(fUnitType, SizeOf(fUnitType));
  LoadStream.Read(HasTask);
  if HasTask then
  begin
    LoadStream.Read(TaskName, SizeOf(TaskName));
    case TaskName of
      utn_Unknown:         Assert(false, 'TaskName can''t be handled');
      utn_SelfTrain:       fUnitTask := TTaskSelfTrain.Load(LoadStream);
      utn_Deliver:         fUnitTask := TTaskDeliver.Load(LoadStream);
      utn_BuildRoad:       fUnitTask := TTaskBuildRoad.Load(LoadStream);
      utn_BuildWine:       fUnitTask := TTaskBuildWine.Load(LoadStream);
      utn_BuildField:      fUnitTask := TTaskBuildField.Load(LoadStream);
      utn_BuildWall:       fUnitTask := TTaskBuildWall.Load(LoadStream);
      utn_BuildHouseArea:  fUnitTask := TTaskBuildHouseArea.Load(LoadStream);
      utn_BuildHouse:      fUnitTask := TTaskBuildHouse.Load(LoadStream);
      utn_BuildHouseRepair:fUnitTask := TTaskBuildHouseRepair.Load(LoadStream);
      utn_GoHome:          fUnitTask := TTaskGoHome.Load(LoadStream);
      utn_AttackHouse:     fUnitTask := TTaskAttackHouse.Load(LoadStream);
      utn_ThrowRock:       fUnitTask := TTaskThrowRock.Load(LoadStream);
      utn_GoEat:           fUnitTask := TTaskGoEat.Load(LoadStream);
      utn_Mining:          fUnitTask := TTaskMining.Load(LoadStream);
      utn_Die:             fUnitTask := TTaskDie.Load(LoadStream);
      utn_GoOutShowHungry: fUnitTask := TTaskGoOutShowHungry.Load(LoadStream);
      else                 Assert(false, 'TaskName can''t be handled');
    end;
  end
  else
    fUnitTask := nil;

  LoadStream.Read(HasAct);
  if HasAct then
  begin
    LoadStream.Read(ActName, SizeOf(ActName));
    case ActName of
      uan_Stay:        fCurrentAction := TUnitActionStay.Load(LoadStream);
      uan_WalkTo:      fCurrentAction := TUnitActionWalkTo.Load(LoadStream);
      uan_AbandonWalk: fCurrentAction := TUnitActionAbandonWalk.Load(LoadStream);
      uan_GoInOut:     fCurrentAction := TUnitActionGoInOut.Load(LoadStream);
      uan_Fight:       fCurrentAction := TUnitActionFight.Load(LoadStream);
      uan_StormAttack: fCurrentAction := TUnitActionStormAttack.Load(LoadStream);
      else             Assert(false, 'ActName can''t be handled');
  end;
  end
  else
    fCurrentAction := nil;

  LoadStream.Read(fThought, SizeOf(fThought));
  LoadStream.Read(fCondition);
  LoadStream.Read(fHitPoints);
  LoadStream.Read(fHitPointCounter);
  LoadStream.Read(fInHouse, 4);
  LoadStream.Read(fOwner, SizeOf(fOwner));
  LoadStream.Read(fHome, 4); //Substitute it with reference on SyncLoad
  LoadStream.Read(fPosition);
  LoadStream.Read(fVisible);
  LoadStream.Read(fIsDead);
  LoadStream.Read(fKillASAP);
  LoadStream.Read(IsExchanging);
  LoadStream.Read(fPointerCount);
  LoadStream.Read(fID);
  LoadStream.Read(AnimStep);
  LoadStream.Read(fDirection);
  LoadStream.Read(fCurrPosition);
  LoadStream.Read(fPrevPosition);
  LoadStream.Read(fNextPosition);
end;


procedure TKMUnit.SyncLoad;
begin
  if fUnitTask<>nil then fUnitTask.SyncLoad;
  if fCurrentAction<>nil then fCurrentAction.SyncLoad;
  fHome := fPlayers.GetHouseByID(cardinal(fHome));
  fInHouse := fPlayers.GetHouseByID(cardinal(fInHouse));
end;


{Returns self and adds on to the pointer counter}
function TKMUnit.GetUnitPointer: TKMUnit;
begin
  inc(fPointerCount);
  Result := Self;
end;


{Decreases the pointer counter}
//Should be used only by fPlayers for clarity sake
procedure TKMUnit.ReleaseUnitPointer;
begin
  if fPointerCount < 1 then
    raise ELocError.Create('Unit remove pointer', PrevPosition);
  dec(fPointerCount);
end;


{Erase everything related to unit status to exclude it from being accessed by anything but the old pointers}
procedure TKMUnit.CloseUnit(aRemoveTileUsage:boolean=true);
begin
  //if not KMSamePoint(fCurrPosition,NextPosition) then
  //  Assert(false, 'Not sure where to die?');

  if fHome<>nil then
  begin
    fHome.GetHasOwner := false;
    fPlayers.CleanUpHousePointer(fHome);
  end;

  if aRemoveTileUsage then fTerrain.UnitRem(fNextPosition); //Must happen before we nil NextPosition

  fIsDead       := true;
  fThought      := th_None;
  fPosition     := KMPointF(0,0);
  fCurrPosition := KMPoint(0,0);
  fPrevPosition := fCurrPosition;
  fNextPosition := fCurrPosition;
  fOwner        := -1;
  //Do not reset the unit type when they die as we still need to know during Load
  //fUnitType     := ut_None;
  fDirection    := dir_NA;
  fVisible      := false;
  fCondition    := 0;
  AnimStep      := 0;
  FreeAndNil(fCurrentAction);
  FreeAndNil(fUnitTask);

  if (fGame.fGamePlayInterface <> nil) and (Self = fGame.fGamePlayInterface.ShownUnit) then
    fGame.fGamePlayInterface.ClearShownUnit; //If this unit is being shown then we must clear it otherwise it sometimes crashes
  //MapEd doesn't need this yet
end;


{Call this procedure to properly kill a unit}
//killing a unit is done in 3 steps
// Kill - release all unit-specific tasks
// TTaskDie - perform dying animation
// CloseUnit - erase all unit data and hide it from further access
procedure TKMUnit.KillUnit;
begin
  if fPlayers.Selected = Self then fPlayers.Selected := nil;
  if fGame.fGamePlayInterface.ShownUnit = Self then fGame.fGamePlayInterface.ShowUnitInfo(nil);
  if (fUnitTask is TTaskDie) then exit; //Don't kill unit if it's already dying

  //Wait till units exchange (1 tick) and then do the killing
  if (fCurrentAction is TUnitActionWalkTo)
  and TUnitActionWalkTo(fCurrentAction).DoingExchange then
  begin
    fKillASAP := true; //Unit will be killed ASAP
    exit;
  end;

  //Update statistics
  if (fPlayers<>nil) and (fOwner <> PLAYER_NONE) and (fOwner <> PLAYER_ANIMAL) then
    fPlayers.Player[fOwner].Stats.UnitLost(fUnitType);

  fThought := th_None; //Reset thought
  SetAction(nil); //Dispose of current action (TTaskDie will set it to LockedStay)
  FreeAndNil(fUnitTask); //Should be overriden to dispose of Task-specific items
  fUnitTask := TTaskDie.Create(Self);
end;


procedure TKMUnit.SetPosition(aPos:TKMPoint);
begin
  Assert(fGame.GameState=gsEditor); //This is only used by the map editor, set all positions to aPos
  fTerrain.UnitRem(fCurrPosition);
  fCurrPosition := aPos;
  fNextPosition := aPos;
  fPrevPosition := aPos;
  fPosition := KMPointF(aPos);
  fTerrain.UnitAdd(fCurrPosition, Self);
end;


function TKMUnit.CanAccessHome: Boolean;
begin
  Result := (fHome = nil) or CanWalkTo(KMPointBelow(fHome.GetEntrance), CanWalk, 0);
end;


function TKMUnit.GetUnitTaskText:string;
begin
  Result:='Idle';                                      {----------} //Thats allowed width
  if fUnitTask is TTaskSelfTrain        then Result := 'Train';
  if fUnitTask is TTaskDeliver          then Result := 'Deliver';
  if fUnitTask is TTaskBuildRoad        then Result := 'Build road';
  if fUnitTask is TTaskBuildWine        then Result := 'Build wine field';
  if fUnitTask is TTaskBuildField       then Result := 'Build corn field';
  if fUnitTask is TTaskBuildWall        then Result := 'Build wall';
  if fUnitTask is TTaskBuildHouseArea   then Result := 'Prepare house area';
  if fUnitTask is TTaskBuildHouse       then Result := 'Build house';
  if fUnitTask is TTaskBuildHouseRepair then Result := 'Repair house';
  if fUnitTask is TTaskGoHome           then Result := 'Go home';
  if fUnitTask is TTaskGoEat            then Result := 'Go to eat';
  if fUnitTask is TTaskMining           then Result := 'Mine resources';
  if fUnitTask is TTaskDie              then Result := 'Die';
  if fUnitTask is TTaskAttackHouse      then Result := 'Attack House';
  if fUnitTask is TTaskGoOutShowHungry  then Result := 'Show hunger';
  if fUnitTask is TTaskThrowRock        then Result := 'Throwing rock';
end;


function TKMUnit.GetUnitActText:string;
begin
  Result := fCurrentAction.GetExplanation;
end;


procedure TKMUnit.SetFullCondition;
begin
  fCondition := UNIT_MAX_CONDITION;
end;


//Return TRUE if unit was killed
function TKMUnit.HitPointsDecrease(aAmount:integer):boolean;
begin
  Result := false;
  //When we are first hit reset the counter
  if (aAmount > 0) and (fHitPoints = GetMaxHitPoints) then fHitPointCounter := 1;
  // Sign of aAmount does not affect
  fHitPoints := EnsureRange(fHitPoints - abs(aAmount), 0, GetMaxHitPoints);
  if (fHitPoints = 0) and not IsDeadOrDying then begin //Kill only once
    KillUnit;
    Result := true;
  end;
end;


procedure TKMUnit.HitPointsIncrease(aAmount:integer);
begin
  // Sign of aAmount does not affect
  fHitPoints := EnsureRange(fHitPoints + abs(aAmount), 0, GetMaxHitPoints);
end;


function TKMUnit.GetMaxHitPoints:byte;
begin
  Result := fResource.UnitDat[fUnitType].HitPoints;
end;


procedure TKMUnit.CancelUnitTask;
begin
  if (fUnitTask <> nil)
  and (fCurrentAction is TUnitActionWalkTo)
  and not TUnitActionWalkTo(GetUnitAction).DoingExchange then
    AbandonWalk;
  FreeAndNil(fUnitTask);
end;


procedure TKMUnit.SetInHouse(aInHouse:TKMHouse);
begin
  fPlayers.CleanUpHousePointer(fInHouse);
  if aInHouse <> nil then
    fInHouse := aInHouse.GetHousePointer;
end;


function TKMUnit.HitTest(X,Y:Integer; const UT:TUnitType = ut_Any): Boolean;
begin
  Result := (X = fCurrPosition.X) and //Comparing X,Y to CurrentPosition separately, cos they can be negative numbers
            (Y = fCurrPosition.Y) and
            ((fUnitType = UT) or (UT = ut_Any));
end;


//As long as we only ever set PrevPos to NextPos and do so everytime before NextPos changes,
//there can be no problems (as were occurring in GetSlide)
//This procedure ensures that these values always get updated correctly so we don't get a problem
//where GetLength(PrevPosition,NextPosition) > sqrt(2)
procedure TKMUnit.UpdateNextPosition(aLoc:TKMPoint);
begin
  fPrevPosition := NextPosition;
  fNextPosition := aLoc;
end;


//Only ClearUnit can set fDirection to NA, no other circumstances it is allowed
procedure TKMUnit.SetDirection(aValue:TKMDirection);
begin
  Assert(aValue<>dir_NA);
  fDirection := aValue;
end;


//Assign the following Action to unit and set AnimStep
procedure TKMUnit.SetAction(aAction: TUnitAction; aStep:integer=0);
begin
  AnimStep := aStep;
  if aAction = nil then
  begin
    FreeAndNil(fCurrentAction);
    exit;
  end;
  if not fResource.UnitDat[fUnitType].SupportsAction(aAction.ActionType) then
  begin
    Assert(false, 'Unit '+fResource.UnitDat[UnitType].UnitName+' was asked to do unsupported action');
    FreeAndNil(aAction);
    exit;
  end;
  if fCurrentAction <> aAction then
  begin
    fCurrentAction.Free;
    fCurrentAction := aAction;
  end;
end;


procedure TKMUnit.SetActionFight(aAction: TUnitActionType; aOpponent: TKMUnit);
begin
  if (GetUnitAction is TUnitActionWalkTo) and not TUnitActionWalkTo(GetUnitAction).CanAbandonExternal then
    raise ELocError.Create('Unit fight overrides walk',fCurrPosition);
  SetAction(TUnitActionFight.Create(Self, aAction, aOpponent));
end;


procedure TKMUnit.SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouse: TKMHouse);
begin
  SetAction(TUnitActionGoInOut.Create(Self, aAction, aGoDir, aHouse));
end;


procedure TKMUnit.SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //When standing still in walk, use default frame
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(Self, aTimeToStay, aAction, aStayStill, aStillFrame, false), aStep);
end;


procedure TKMUnit.SetActionStorm(aRow:integer);
begin
  SetAction(TUnitActionStormAttack.Create(Self, ua_Walk, aRow), 0); //Action is ua_Walk for that is the inital one
end;


//Same as above but we will ignore get-out-of-the-way (push) requests from interaction system
procedure TKMUnit.SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //When standing still in walk, use default frame
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(Self, aTimeToStay, aAction, aStayStill, aStillFrame, true), aStep);
end;


//WalkTo action with exact options (retranslated from WalkTo if Obstcale met)
procedure TKMUnit.SetActionWalk(aLocB:TKMPoint; aActionType:TUnitActionType; aDistance:single; aTargetUnit:TKMUnit; aTargetHouse:TKMHouse);
begin
  if (GetUnitAction is TUnitActionWalkTo) and not TUnitActionWalkTo(GetUnitAction).CanAbandonExternal then Assert(false);
  SetAction(TUnitActionWalkTo.Create(Self, aLocB, aActionType, aDistance, false, aTargetUnit, aTargetHouse));
end;


//Approach house
procedure TKMUnit.SetActionWalkToHouse(aHouse: TKMHouse; aDistance: Single; aActionType: TUnitActionType = ua_Walk);
begin
  if (GetUnitAction is TUnitActionWalkTo) and not TUnitActionWalkTo(GetUnitAction).CanAbandonExternal then Assert(false);

  SetAction(TUnitActionWalkTo.Create( Self,               //Who's walking
                                      //Target position is the closest cell to our current position (only used for estimating in path finding)
                                      aHouse.GetClosestCell(Self.GetPosition),
                                      aActionType,        //
                                      aDistance,          //Proximity
                                      false,              //If we were pushed
                                      nil,                //Unit
                                      aHouse              //House
                                      ));
end;


//Approach unit
procedure TKMUnit.SetActionWalkToUnit(aUnit:TKMUnit; aDistance:single; aActionType:TUnitActionType=ua_Walk);
begin
  if (GetUnitAction is TUnitActionWalkTo) and not TUnitActionWalkTo(GetUnitAction).CanAbandonExternal then Assert(false);

  Assert(aDistance>=1,'Should not walk to units place');
  SetAction(TUnitActionWalkTo.Create( Self,               //Who's walking
                                      aUnit.fCurrPosition,//Target position
                                      aActionType,        //
                                      aDistance,          //Proximity
                                      false,              //If we were pushed
                                      aUnit,              //Unit
                                      nil                 //House
                                      ));
end;


//Walk to spot or its neighbourhood
procedure TKMUnit.SetActionWalkToSpot(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aUseExactTarget:boolean=true);
begin
  if (GetUnitAction is TUnitActionWalkTo) and not TUnitActionWalkTo(GetUnitAction).CanAbandonExternal then
    Assert(False, 'Interrupting unabandonable Walk action');

  if not aUseExactTarget and not (Self is TKMUnitWarrior) and not (Self.fUnitTask is TTaskMining) then
    Assert(False, 'Only true warriors don''t care ''bout exact location on reposition; Miners compete over resources, so they can handle is location is taken already');

  SetAction(TUnitActionWalkTo.Create(Self, aLocB, aActionType, 0, false, nil, nil, aUseExactTarget));
end;


//We were pushed (walk to spot with wider Passability)
procedure TKMUnit.SetActionWalkPushed(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
begin
  //1. Only idle units can be pushed, for they are low priority to busy units
  //2. If unit can't get away it will re-push itself once again
  Assert(((GetUnitAction is TUnitActionStay) and (not GetUnitAction.Locked)) or
         ((GetUnitAction is TUnitActionWalkTo) and TUnitActionWalkTo(GetUnitAction).CanAbandonExternal));

  SetAction(TUnitActionWalkTo.Create(Self, aLocB, aActionType, 0, true, nil, nil));
  //Once pushed, unit will try to walk away, if he bumps into more units he will
  //
end;


procedure TKMUnit.SetActionAbandonWalk(aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
var TempVertexOccupied: TKMPoint;
begin
  if GetUnitAction is TUnitActionWalkTo then
  begin
    TempVertexOccupied := TUnitActionWalkTo(GetUnitAction).fVertexOccupied;
    TUnitActionWalkTo(GetUnitAction).fVertexOccupied := KMPoint(0,0); //So it doesn't try to DecVertex on destroy (now it's AbandonWalk's responsibility)
  end
  else
    TempVertexOccupied := KMPoint(0,0);

  SetAction(TUnitActionAbandonWalk.Create(Self, aLocB, TempVertexOccupied, aActionType), AnimStep); //Use the current animation step, to ensure smooth transition
end;


procedure TKMUnit.AbandonWalk;
begin
  if GetUnitAction is TUnitActionWalkTo then
    SetActionAbandonWalk(NextPosition, ua_Walk)
  else
    SetActionLockedStay(0, ua_Walk); //Error
end;


//Specific unit desired passability may depend on several factors
function TKMUnit.GetDesiredPassability: TPassability;
begin
  Result := fResource.UnitDat[fUnitType].DesiredPassability;

  //Delivery to unit
  if (fUnitType = ut_Serf)
  and (fUnitTask is TTaskDeliver)
  and (TTaskDeliver(fUnitTask).DeliverKind = dk_ToUnit)
  then
    Result := CanWalk;

  //Preparing house area
  if (fUnitType = ut_Worker) and (fUnitTask is TTaskBuildHouseArea)
  and TTaskBuildHouseArea(fUnitTask).Digging
  then
    Result := CanWorker; //Special mode that allows us to walk on building sites

  //Miners at work need to go off roads
  if (fUnitType in [ut_Woodcutter, ut_Farmer, ut_Fisher, ut_StoneCutter])
  and (fUnitTask is TTaskMining)
  then
    Result := CanWalk;
end;


procedure TKMUnit.Feed(Amount:single);
begin
  fCondition := Math.min(fCondition + round(Amount), UNIT_MAX_CONDITION);
end;


//It's better not to start doing anything with dying units
function TKMUnit.IsDeadOrDying:boolean;
begin
  Result := fIsDead or (fUnitTask is TTaskDie) or fKillASAP;
end;


{Check wherever this unit is armed}
function TKMUnit.IsArmyUnit:boolean;
begin
  Result := fUnitType in [WARRIOR_MIN..WARRIOR_MAX];
end;


function TKMUnit.CanGoEat:boolean;
begin
  Result := fPlayers.Player[fOwner].FindInn(fCurrPosition,Self) <> nil;
end;


function TKMUnit.CanWalkDiagonaly(aFrom, aTo: TKMPoint): Boolean;
begin
  Result := fTerrain.CanWalkDiagonaly(aFrom, aTo);
end;


function TKMUnit.CanWalkTo(aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := fTerrain.Route_CanBeMade(GetPosition, aTo, GetDesiredPassability, aDistance);
end;


function TKMUnit.CanWalkTo(aTo: TKMPoint; aPass: TPassability; aDistance: Single): Boolean;
begin
  Result := fTerrain.Route_CanBeMade(GetPosition, aTo, aPass, aDistance);
end;


function TKMUnit.CanWalkTo(aFrom, aTo: TKMPoint; aDistance: Single): Boolean;
begin
  Result := fTerrain.Route_CanBeMade(aFrom, aTo, GetDesiredPassability, aDistance);
end;


function TKMUnit.CanWalkTo(aFrom, aTo: TKMPoint; aPass: TPassability; aDistance: Single): Boolean;
begin
  Result := fTerrain.Route_CanBeMade(aFrom, aTo, aPass, aDistance);
end;


//Check if a route can be made to any tile around this house
function TKMUnit.CanWalkTo(aFrom: TKMPoint; aHouse: TKMHouse; aPass: TPassability; aDistance: Single): Boolean;
var
  I: Integer;
  Cells: TKMPointList;
begin
  Result := False;
  Cells := TKMPointList.Create;
  try
    aHouse.GetListOfCellsWithin(Cells);
    for I := 0 to Cells.Count - 1 do
      Result := Result or fTerrain.Route_CanBeMade(aFrom, Cells[I], aPass, aDistance);
  finally
    Cells.Free;
  end;
end;


function TKMUnit.CanStepTo(X,Y: Integer): Boolean;
begin
  Result := fTerrain.TileInMapCoords(X,Y)
        and (fTerrain.CheckPassability(KMPoint(X,Y), GetDesiredPassability))
        and (not fTerrain.HasVertexUnit(KMGetDiagVertex(GetPosition, KMPoint(X,Y))))
        and (fTerrain.CanWalkDiagonaly(GetPosition, KMPoint(X,Y)))
        and (fTerrain.Land[Y,X].IsUnit = nil);
end;


procedure TKMUnit.UpdateHunger;
begin
  if fCondition>0 then //Make unit hungry as long as they are not currently eating in the inn
    if not((fUnitTask is TTaskGoEat) and (TTaskGoEat(fUnitTask).Eating)) then
      dec(fCondition);

  //Feed the unit automatically. Don't align it with dec(fCondition) cos FOW uses it as a timer
  if (not DO_UNIT_HUNGER)and(fCondition<UNIT_MIN_CONDITION+100) then fCondition := UNIT_MAX_CONDITION;

  //Unit killing could be postponed by few ticks, hence fCondition could be <0
  if fCondition <= 0 then
    KillUnit;
end;


//Can use fCondition as a sort of counter to reveal terrain X times a sec
procedure TKMUnit.UpdateFOW;
begin
  if fCondition mod 10 = 0 then
    fPlayers.RevealForTeam(fOwner, fCurrPosition, fResource.UnitDat[fUnitType].Sight, FOG_OF_WAR_INC);
end;


procedure TKMUnit.UpdateThoughts;
begin
  if (fThought <> th_Death) and (fCondition <= UNIT_MIN_CONDITION div 3) then
    fThought := th_Death;

  if (fThought in [th_Death, th_Eat]) and (fCondition > UNIT_MIN_CONDITION) then
    fThought := th_None;

  if (fUnitTask is TTaskDie) then //Clear thought if we are in the process of dying
    fThought := th_None;
end;

//Return true if the unit has to be killed due to lack of space
function TKMUnit.UpdateVisibility:boolean;
begin
  Result := false;
  if fInHouse = nil then exit; //There's nothing to update, we are always visible

  if fInHouse.IsDestroyed then //Someone has destroyed the house we were in
  begin
    fVisible := true;
    //If we are walking into/out of the house then don't set our position, ActionGoInOut will sort it out
    if (not (GetUnitAction is TUnitActionGoInOut)) or (not TUnitActionGoInOut(GetUnitAction).GetHasStarted) or
       (TUnitActionGoInOut(GetUnitAction).GetWaitingForPush) then
    begin
      //Position in a spiral nearest to entrance of house, updating IsUnit.
      if not fPlayers.FindPlaceForUnit(fInHouse.GetEntrance.X, fInHouse.GetEntrance.Y, UnitType, fCurrPosition, fTerrain.GetWalkConnectID(fInHouse.GetEntrance)) then
      begin
        //There is no space for this unit so it must be destroyed
        if (fPlayers<>nil) and (fOwner <> PLAYER_NONE) and (fOwner <> PLAYER_ANIMAL) then
          fPlayers.Player[fOwner].Stats.UnitLost(fUnitType);
        FreeAndNil(fCurrentAction);
        FreeAndNil(fUnitTask);
        CloseUnit(false); //Close the unit without removing tile usage (because this unit was in a house it has none)
        Result := true;
        exit;
      end;
      //Make sure these are reset properly
      assert(not fTerrain.HasUnit(fCurrPosition));
      IsExchanging := false;
      fPosition := KMPointF(fCurrPosition);
      fPrevPosition := fCurrPosition;
      fNextPosition := fCurrPosition;
      fTerrain.UnitAdd(fCurrPosition, Self); //Unit was not occupying tile while inside the house, hence just add do not remove
      if GetUnitAction is TUnitActionGoInOut then
      begin
        TUnitActionGoInOut(GetUnitAction).DoLinking; //Warriors will be linked as normal
        SetActionLockedStay(0,ua_Walk); //Abandon the walk out in this case
      end;
      if (GetUnitTask is TTaskGoEat) and (TTaskGoEat(GetUnitTask).Eating) then
      begin
        FreeAndNil(fUnitTask); //Stop the eating animation and makes the unit appear
        SetActionStay(0, ua_Walk); //Free the current action and give the unit a temporary one
      end;
    end;
    SetInHouse(nil); //Can't be in a destroyed house
  end;
end;


procedure TKMUnit.VertexAdd(aFrom, aTo: TKMPoint);
begin
  fTerrain.UnitVertexAdd(aFrom, aTo);
end;

procedure TKMUnit.VertexRem(aLoc: TKMPoint);
begin
  fTerrain.UnitVertexRem(aLoc); //Unoccupy vertex
end;


function TKMUnit.VertexUsageCompatible(aFrom, aTo: TKMPoint): Boolean;
begin
  Result := fTerrain.VertexUsageCompatible(aFrom, aTo);
end;


procedure TKMUnit.Walk(aFrom, aTo: TKMPoint);
begin
  fTerrain.UnitWalk(aFrom, aTo, Self)
end;

procedure TKMUnit.UpdateHitPoints;
begin
  //Use fHitPointCounter as a counter to restore hit points every X ticks (Humbelum says even when in fights)
  if fGame.GlobalSettings.fHitPointRestorePace = 0 then exit; //0 pace means don't restore
  if fHitPointCounter mod fGame.GlobalSettings.fHitPointRestorePace = 0 then
    HitPointsIncrease(1);
  inc(fHitPointCounter);
  if fHitPointCounter = high(Cardinal)-1 then fHitPointCounter := 1;
end;


function TKMUnit.GetSlide(aCheck:TCheckAxis): single;
//Pixel positions (waypoints) for sliding around other units. Uses a lookup to save on-the-fly calculations.
//Follows a sort of a bell curve (normal distribution) shape for realistic acceleration/deceleration.
//I tweaked it by hand to look similar to KaM.
//1st row for straight, 2nd for diagonal sliding
const
  SlideLookup: array[1..2, 0..Round(CELL_SIZE_PX * 1.42)] of byte = ( //1.42 instead of 1.41 because we want to round up just in case (it was causing a crash because Round(40*sqrt(2)) = 57 but Round(40*1.41) = 56)
    (0,0,0,0,0,0,1,1,2,2,3,3,4,5,6,7,7,8,8,9,9,9,9,8,8,7,7,6,5,4,3,3,2,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,3,3,4,4,4,5,5,5,6,6,6,7,7,7,7,6,6,6,5,5,5,4,4,4,3,3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0,0));
var DY,DX, PixelPos, LookupDiagonal: shortint;
begin
  Result := 0;

  //When going into a house, units "slide" towards the door when it is not on center
  if GetUnitAction is TUnitActionGoInOut then
    Result := Result+TUnitActionGoInOut(GetUnitAction).GetDoorwaySlide(aCheck);

  if (not IsExchanging) or not (GetUnitAction.ActName in [uan_WalkTo, uan_GoInOut]) then exit;

  //Uses Y because a walk in the Y means a slide in the X
  DX := sign(NextPosition.X - fPosition.X);
  DY := sign(NextPosition.Y - fPosition.Y);
  if (aCheck = ax_X) and (DY = 0) then exit; //Unit is not shifted
  if (aCheck = ax_Y) and (DX = 0) then exit;

  LookupDiagonal := abs(DX) + abs(DY); //which gives us swith: 1-straight, 2-diagonal.

  if aCheck = ax_X then begin
    PixelPos := Round(abs(fPosition.Y-PrevPosition.Y)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := Result+(DY*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
  if aCheck = ax_Y then begin
    PixelPos := Round(abs(fPosition.X-PrevPosition.X)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := Result-(DX*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
end;


function TKMUnit.GetMovementVector: TKMPointF;
var MovementSpeed:single;
begin
  if (GetUnitAction is TUnitActionWalkTo) and TUnitActionWalkTo(GetUnitAction).DoesWalking then
    MovementSpeed := fResource.UnitDat[fUnitType].Speed
  else
  if (GetUnitAction is TUnitActionStormAttack) then
    MovementSpeed := TUnitActionStormAttack(GetUnitAction).GetSpeed
  else
    MovementSpeed := 0;

  Result.X := KMGetVertex(fDirection).X * MovementSpeed;
  Result.Y := KMGetVertex(fDirection).Y * MovementSpeed;
end;


function TKMUnit.IsIdle: Boolean;
begin
  Result := (fUnitTask = nil) and ((fCurrentAction is TUnitActionStay) and not TUnitActionStay(fCurrentAction).Locked);
end;


procedure TKMUnit.Save(SaveStream:TKMemoryStream);
var
  HasTask, HasAct: Boolean;
  ActName: TUnitActionName;
begin
  SaveStream.Write(fUnitType, SizeOf(fUnitType));

  HasTask := fUnitTask <> nil; //Thats our switch to know if unit should write down his task.
  SaveStream.Write(HasTask);
  if HasTask then
  begin
    //We save TaskName to know which Task class to load
    SaveStream.Write(fUnitTask.TaskName, SizeOf(fUnitTask.TaskName));
    fUnitTask.Save(SaveStream);
  end;

  HasAct := fCurrentAction <> nil;
  SaveStream.Write(HasAct);
  if HasAct then
  begin
    ActName := fCurrentAction.ActName; //Can not pass function result to Write
    //We save ActName to know which Task class to load
    SaveStream.Write(ActName, SizeOf(ActName));
    fCurrentAction.Save(SaveStream);
  end;

  SaveStream.Write(fThought, SizeOf(fThought));
  SaveStream.Write(fCondition);
  SaveStream.Write(fHitPoints);
  SaveStream.Write(fHitPointCounter);

  if fInHouse <> nil then
    SaveStream.Write(fInHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));

  SaveStream.Write(fOwner, SizeOf(fOwner));

  if fHome <> nil then
    SaveStream.Write(fHome.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));

  SaveStream.Write(fPosition);
  SaveStream.Write(fVisible);
  SaveStream.Write(fIsDead);
  SaveStream.Write(fKillASAP);
  SaveStream.Write(IsExchanging);
  SaveStream.Write(fPointerCount);

  SaveStream.Write(fID);
  SaveStream.Write(AnimStep);
  SaveStream.Write(fDirection);
  SaveStream.Write(fCurrPosition);
  SaveStream.Write(fPrevPosition);
  SaveStream.Write(fNextPosition);
end;


{Here are common Unit.UpdateState routines}
function TKMUnit.UpdateState:boolean;
begin
  //There are layers of unit activity (bottom to top):
  // - Action (Atom creating layer (walk 1frame, etc..))
  // - Task (Action creating layer)
  // - specific UpdateState (Task creating layer)

  Result := true;

  if fCurrentAction=nil then raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action at start of TKMUnit.UpdateState',fCurrPosition);

  //UpdateState can happen right after unit gets killed (Exchange still in progress)
  if fKillASAP
  and not ((fCurrentAction is TUnitActionWalkTo) and TUnitActionWalkTo(fCurrentAction).DoingExchange) then
  begin
    KillUnit;
    fKillASAP := false;
    Assert(IsDeadOrDying); //Just in case KillUnit failed
  end;

  UpdateHunger;
  UpdateFOW;
  UpdateThoughts;
  UpdateHitPoints;
  if UpdateVisibility then exit; //incase units home was destroyed. Returns true if the unit was killed due to lack of space

  //Shortcut to freeze unit in place if it's on an unwalkable tile. We use fNextPosition rather than fCurrPosition
  //because once we have taken a step from a tile we no longer care about it. (fNextPosition matches up with IsUnit in terrain)
  if fCurrentAction is TUnitActionWalkTo then
    if GetDesiredPassability = CanWalkRoad then
    begin
      if not fTerrain.CheckPassability(fNextPosition, CanWalk) then
        raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' on unwalkable tile at '+KM_Points.TypeToString(fNextPosition)+' pass CanWalk',fNextPosition);
    end else
    if not fTerrain.CheckPassability(fNextPosition, GetDesiredPassability) then
      raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' on unwalkable tile at '+KM_Points.TypeToString(fNextPosition)+' pass '+PassabilityStr[GetDesiredPassability],fNextPosition);


  //
  //Performing Tasks and Actions now
  //------------------------------------------------------------------------------------------------
  if fCurrentAction=nil then
    raise ELocError.Create(fResource.UnitDat[UnitType].UnitName+' has no action in TKMUnit.UpdateState',fCurrPosition);

  fCurrPosition := KMPointRound(fPosition);
  case fCurrentAction.Execute of
    ActContinues: begin fCurrPosition := KMPointRound(fPosition); exit; end;
    ActAborted:   begin FreeAndNil(fCurrentAction); FreeAndNil(fUnitTask); end;
    ActDone:      FreeAndNil(fCurrentAction);
  end;
  fCurrPosition := KMPointRound(fPosition);


  if fUnitTask <> nil then
  case fUnitTask.Execute of
    TaskContinues:  exit;
    TaskDone:       FreeAndNil(fUnitTask);
  end;


  //If we get to this point then it means that common part is done and now
  //we can perform unit-specific activities (ask for job, etc..)
  Result := false;
end;


procedure TKMUnit.Paint;
begin
  //Here should be catched any cases where unit has no current action - this is a flaw in TTasks somewhere
  //Unit always meant to have some Action performed.
  //However, do not assert it here because then the player cannot close the message (paint happens repeatedly)
  //We check it at the start and end of UpdateState, that is the only place.
  if fCurrentAction <> nil then
    fCurrentAction.Paint;

  if SHOW_POINTER_DOTS and fGame.AllowDebugRendering then
    fRenderAux.UnitPointers(fPosition.X + 0.5 + GetSlide(ax_X), fPosition.Y + 1   + GetSlide(ax_Y), fPointerCount);
end;


//Select random point from list, excluding current location
function TKMUnit.PickRandomSpot(aList: TKMPointDirList; out Loc: TKMPointDir): Boolean;
var
  I, MyCount: Integer;
  Spots: array of Word;
begin
  SetLength(Spots, aList.Count);

  //Scan the list and pick suitable locations
  MyCount := 0;
  for I := 0 to aList.Count - 1 do
  if not KMSamePoint(aList[I].Loc, GetPosition)
  and CanWalkTo(aList[I].Loc, 0) then
  begin
    Spots[MyCount] := I;
    Inc(MyCount);
  end;

  Result := (MyCount > 0);
  if Result then
    Loc := aList[Spots[KaMRandom(MyCount)]];
end;


{ TUnitTask }
constructor TUnitTask.Create(aUnit: TKMUnit);
begin
  inherited Create;
  fTaskName := utn_Unknown;
  Assert(aUnit <> nil);
  fUnit := aUnit.GetUnitPointer;
  fUnit.SetActionLockedStay(0,ua_Walk);
  fPhase    := 0;
  fPhase2   := 0;
end;


constructor TUnitTask.Load(LoadStream:TKMemoryStream);
begin
  inherited Create;
  LoadStream.Read(fTaskName, SizeOf(fTaskName));
  LoadStream.Read(fUnit, 4);//Substitute it with reference on SyncLoad
  LoadStream.Read(fPhase);
  LoadStream.Read(fPhase2);
end;


procedure TUnitTask.SyncLoad;
begin
  fUnit := fPlayers.GetUnitByID(cardinal(fUnit));
end;


destructor TUnitTask.Destroy;
begin
  fUnit.Thought := th_None; //Stop any thoughts
  fPlayers.CleanUpUnitPointer(fUnit);
  fPhase        := high(byte)-1; //-1 so that if it is increased on the next run it won't overrun before exiting
  fPhase2       := high(byte)-1;
  inherited;
end;


function TUnitTask.WalkShouldAbandon:boolean;
begin
  Result := False; //Only used in some child classes
end;


procedure TUnitTask.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(fTaskName, SizeOf(fTaskName)); //Save task type before anything else for it will be used on loading to create specific task type
  if fUnit <> nil then
    SaveStream.Write(fUnit.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fPhase);
  SaveStream.Write(fPhase2);
end;


{ TUnitAction }
constructor TUnitAction.Create(aUnit: TKMUnit; aActionType: TUnitActionType; aLocked: Boolean);
begin
  inherited Create;

  //Unit who will be performing the action
  //Does not require pointer tracking because action should always be destroyed before the unit that owns it
  fUnit       := aUnit;
  fActionType := aActionType;
  Locked      := aLocked;
  StepDone    := False;
end;


constructor TUnitAction.Load(LoadStream:TKMemoryStream);
begin
  inherited Create;
  LoadStream.Read(fActionType, SizeOf(fActionType));
  LoadStream.Read(fUnit, 4);
  LoadStream.Read(Locked);
  LoadStream.Read(StepDone);
end;


procedure TUnitAction.SyncLoad;
begin
  fUnit := fPlayers.GetUnitByID(cardinal(fUnit));
end;


procedure TUnitAction.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(fActionType, SizeOf(fActionType));
  if fUnit <> nil then
    SaveStream.Write(fUnit.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(Locked);
  SaveStream.Write(StepDone);
end;


procedure TUnitAction.Paint;
begin
  //Used for debug, paint action properties here
end;


{ TKMUnitsCollection }
constructor TKMUnitsCollection.Create;
begin
  inherited Create;

end;


destructor TKMUnitsCollection.Destroy;
begin
  //No need to free units individually since they are Freed by TKMList.Clear command.
  inherited;
end;


function TKMUnitsCollection.GetUnit(aIndex: Integer): TKMUnit;
begin
  Result := Items[aIndex];
end;


procedure TKMUnitsCollection.SetUnit(aIndex: Integer; aItem: TKMUnit);
begin
  Items[aIndex] := aItem;
end;


{ AutoPlace means should we find a spot for this unit or just place it where we are told.
  Used for creating units still inside schools }
function TKMUnitsCollection.Add(aOwner: shortint; aUnitType: TUnitType; PosX, PosY:integer; AutoPlace:boolean=true; RequiredWalkConnect:byte=0):TKMUnit;
var U:Integer; P:TKMPoint;
begin
  P := KMPoint(0,0); // Will have 0:0 if no place found
  if AutoPlace then begin
    if RequiredWalkConnect = 0 then
      RequiredWalkConnect := fTerrain.GetWalkConnectID(KMPoint(PosX,PosY));
    fPlayers.FindPlaceForUnit(PosX,PosY,aUnitType, P, RequiredWalkConnect);
    PosX := P.X;
    PosY := P.Y;
  end;

  if fTerrain.HasUnit(KMPoint(PosX,PosY)) then
    raise ELocError.Create('No space for '+fResource.UnitDat[aUnitType].UnitName +
                           ', tile occupied by '{+fResource.UnitDat[fTerrain.Land[PosY,PosX].IsUnit.UnitType].UnitName},
                           KMPoint(PosX,PosY));

  if not fTerrain.TileInMapCoords(PosX, PosY) then begin
    fLog.AppendLog('Unable to add unit to '+KM_Points.TypeToString(KMPoint(PosX,PosY)));
    Result := nil;
    exit;
  end;

  case aUnitType of
    ut_Serf:    U := inherited Add(TKMUnitSerf.Create(aOwner,PosX,PosY,aUnitType));
    ut_Worker:  U := inherited Add(TKMUnitWorker.Create(aOwner,PosX,PosY,aUnitType));

    ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                U := inherited Add(TKMUnitCitizen.Create(aOwner,PosX,PosY,aUnitType));

    ut_Recruit: U := inherited Add(TKMUnitRecruit.Create(aOwner,PosX,PosY,aUnitType));

    WARRIOR_MIN..WARRIOR_MAX: U := inherited Add(TKMUnitWarrior.Create(aOwner,PosX,PosY,aUnitType));

    ANIMAL_MIN..ANIMAL_MAX:   U := inherited Add(TKMUnitAnimal.Create(aOwner,PosX,PosY,aUnitType));

    else                      raise ELocError.Create('Add '+fResource.UnitDat[aUnitType].UnitName,KMPoint(PosX, PosY));
  end;

  Result := Units[U];
end;


function TKMUnitsCollection.AddGroup(aOwner:TPlayerIndex;  aUnitType:TUnitType; PosX, PosY:integer; aDir:TKMDirection; aUnitPerRow, aUnitCount:word; aMapEditor:boolean=false):TKMUnit;
var U:TKMUnit; Commander,W:TKMUnitWarrior; i:integer; UnitPosition:TKMPoint; DoesFit: boolean;
begin
  Assert(aDir <> dir_NA);
  aUnitPerRow := Math.min(aUnitPerRow,aUnitCount); //Can have more rows than units
  if not (aUnitType in [WARRIOR_MIN..WARRIOR_MAX]) then
  begin
    for i:=1 to aUnitCount do
    begin
      UnitPosition := GetPositionInGroup2(PosX, PosY, aDir, i, aUnitPerRow, fTerrain.MapX, fTerrain.MapY, DoesFit);
      U := Add(aOwner, aUnitType, UnitPosition.X, UnitPosition.Y); //U will be _nil_ if unit didn't fit on map
      if U<>nil then
      begin
        fPlayers.Player[aOwner].Stats.UnitCreated(aUnitType, false);
        U.Direction := aDir;
        U.AnimStep  := UnitStillFrames[aDir];
      end;
    end;
    Result := nil; //Dunno what to return here
    exit; // Don't do anything else for citizens
  end;

  //Add commander first
  Commander := TKMUnitWarrior(Add(aOwner, aUnitType, PosX, PosY));
  Result := Commander;

  if Commander=nil then exit; //Don't add group without a commander
  fPlayers.Player[aOwner].Stats.UnitCreated(aUnitType, false);

  Commander.Direction := aDir;
  Commander.AnimStep  := UnitStillFrames[aDir];
  Commander.OrderLocDir := KMPointDir(Commander.OrderLocDir.Loc, aDir); //So when they click Halt for the first time it knows where to place them

  //In MapEditor we need only fMapEdMembersCount property, without actual members
  if aMapEditor then begin
    Commander.fMapEdMembersCount := aUnitCount-1; //Skip commander
    Commander.UnitsPerRow := aUnitPerRow; //Must be set at the end AFTER adding members
    exit;
  end;

  for i:=2 to aUnitCount do begin //Commander already placed
    UnitPosition := GetPositionInGroup2(PosX, PosY, aDir, i, aUnitPerRow, fTerrain.MapX, fTerrain.MapY, DoesFit);
    W := TKMUnitWarrior(Add(aOwner, aUnitType, UnitPosition.X, UnitPosition.Y, true, fTerrain.GetWalkConnectID(KMPoint(PosX,PosY)))); //W will be _nil_ if unit didn't fit on map
    if W<>nil then
    begin
      fPlayers.Player[aOwner].Stats.UnitCreated(aUnitType, false);
      W.Direction := aDir;
      W.AnimStep  := UnitStillFrames[aDir];
      Commander.AddMember(W);
      W.fCondition := Commander.fCondition; //Whole group will have same condition
    end;
  end;
  Commander.UnitsPerRow := aUnitPerRow; //Must be set at the end AFTER adding members
end;


procedure TKMUnitsCollection.RemoveUnit(aUnit:TKMUnit);
begin
  aUnit.CloseUnit; //Should free up the unit properly (freeing terrain usage and memory)
  aUnit.Free;
  Remove(aUnit);
end;


procedure TKMUnitsCollection.OwnerUpdate(aOwner:TPlayerIndex);
var i:integer;
begin
  for i:=0 to Count-1 do
    Units[i].fOwner := aOwner;
end;


function TKMUnitsCollection.HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): TKMUnit;
var i:integer;
begin
  Result:= nil;
  for i:=0 to Count-1 do
    if Units[i].HitTest(X,Y,UT) and (not Units[i].IsDead) then
    begin
      Result := Units[i];
      exit;
    end;
end;


function TKMUnitsCollection.GetUnitByID(aID: Integer): TKMUnit;
var i:integer;
begin
  Result := nil;
  for i := 0 to Count-1 do
    if aID = Units[i].ID then
    begin
      Result := Units[i];
      exit;
    end;
end;


function TKMUnitsCollection.GetClosestUnit(aPoint: TKMPoint):TKMUnit;
var
  i: integer;
  BestDist,Dist: single;
begin
  Result := nil;
  BestDist := MaxSingle; //Any distance will be closer than that
  for i:=0 to Count-1 do
    if (not Units[i].IsDeadOrDying) and (Units[i].fVisible) then
    begin
      Dist := GetLength(Units[i].GetPosition, aPoint);
      if Dist < BestDist then
      begin
        BestDist := Dist;
        Result := Units[i];
      end;
    end;
end;


function TKMUnitsCollection.GetTotalPointers: integer;
var i:integer;
begin
  Result := 0;
  for i:=0 to Count-1 do
    inc(Result, Units[i].GetPointerCount);
end;


procedure TKMUnitsCollection.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write('Units');
  SaveStream.Write(Count);
  for i := 0 to Count - 1 do
  begin
    //We save unit type to know which unit class to load
    SaveStream.Write(Units[i].UnitType, SizeOf(Units[i].UnitType));
    Units[i].Save(SaveStream);
  end;
end;


procedure TKMUnitsCollection.Load(LoadStream:TKMemoryStream);
var i,UnitCount:integer; UnitType:TUnitType;
begin
  LoadStream.ReadAssert('Units');
  LoadStream.Read(UnitCount);
  for i := 0 to UnitCount - 1 do
  begin
    LoadStream.Read(UnitType, SizeOf(UnitType));
    case UnitType of
      ut_Serf:                  inherited Add(TKMUnitSerf.Load(LoadStream));
      ut_Worker:                inherited Add(TKMUnitWorker.Load(LoadStream));
      ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                                inherited Add(TKMUnitCitizen.Load(LoadStream));
      ut_Recruit:               inherited Add(TKMUnitRecruit.Load(LoadStream));
      WARRIOR_MIN..WARRIOR_MAX: inherited Add(TKMUnitWarrior.Load(LoadStream));
      ANIMAL_MIN..ANIMAL_MAX:   inherited Add(TKMUnitAnimal.Load(LoadStream));
      else fLog.AssertToLog(false, 'Unknown unit type in Savegame')
    end;
  end;
end;


procedure TKMUnitsCollection.SyncLoad;
var i:integer;
begin
  for i:=0 to Count-1 do
  begin
    case Units[i].fUnitType of
      ut_Serf:                  TKMUnitSerf(Items[i]).SyncLoad;
      ut_Worker:                TKMUnitWorker(Items[i]).SyncLoad;
      ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                                TKMUnitCitizen(Items[i]).SyncLoad;
      ut_Recruit:               TKMUnitRecruit(Items[i]).SyncLoad;
      WARRIOR_MIN..WARRIOR_MAX: TKMUnitWarrior(Items[i]).SyncLoad;
      ANIMAL_MIN..ANIMAL_MAX:   TKMUnitAnimal(Items[i]).SyncLoad;
    end;
  end;
end;


procedure TKMUnitsCollection.UpdateState;
var
  I: integer;
begin
  for I:=Count-1 downto 0 do
  if not Units[I].IsDead then
    Units[I].UpdateState
  else //Else try to destroy the unit object if all pointers are freed
    if FREE_POINTERS and (Units[I].fPointerCount = 0) then
    begin
      Units[I].Free;
      Delete(I);
    end;

  //   --     POINTER FREEING SYSTEM - DESCRIPTION     --   //
  //  This system was implemented because unit and house objects cannot be freed until all pointers
  //  to them (in tasks, delivery queue, etc.) have been freed, otherwise we have pointer integrity
  //  issues.

  //   --     ROUGH OUTLINE     --   //
  // - Units and houses have fPointerCount, which is the number of pointers to them. (e.g. tasks,
  //   deliveries) This is kept up to date by the thing that is using the pointer. On create it uses
  //   GetUnitPointer to get the pointer and increase the pointer count and on destroy it decreases
  //   it with ReleaseUnitPointer.
  // - When a unit dies, the object is not destroyed. Instead a flag (boolean) is set to say that we
  //   want to destroy but can't because there still might be pointers to the unit. From then on
  //   every update state it checks to see if the pointer count is 0 yet. If it is then the unit is
  //   destroyed.
  // - For each place that contains a pointer, it should check everytime the pointer is used to see
  //   if it has been destroy. If it has then we free the pointer and reduce the count.
  //   (and do any other action nececary due to the unit/house dying)

end;


procedure TKMUnitsCollection.Paint;
const Margin = 2;
var
  I: Integer;
  Rect: TKMRect;
begin
  //Add additional margin to compensate for units height
  Rect := KMRectGrow(fGame.Viewport.GetClip, Margin);

  for I := 0 to Count - 1 do
  if (Items[I] <> nil) and not Units[I].IsDead and KMInRect(Units[I].fPosition, Rect) then
    Units[i].Paint;
end;


end.