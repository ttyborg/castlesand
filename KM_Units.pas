unit KM_Units;
interface
uses
  Classes, Math, MMSystem, SysUtils, KromUtils, Windows,
  KM_CommonTypes, KM_Defaults, KM_Utils, KM_Houses, KM_Terrain, KM_Units_WorkPlan;

type
  TKMUnit = class;
  TKMUnitSerf = class;
  TKMUnitWorker = class;

  TDeliverKind = (dk_House, dk_Unit);

  TUnitAction = class(TObject)
  protected
    fActionName: TUnitActionName;
    fActionType: TUnitActionType;
    IsStepDone: boolean; //True when single action element is done (unit walked to new tile, single attack loop done)
  public
    constructor Create(aActionType: TUnitActionType);
    constructor Load(LoadStream:TKMemoryStream);
    procedure Execute(KMUnit: TKMUnit; TimeDelta: single; out DoEnd: Boolean); virtual; abstract;
    property GetActionType: TUnitActionType read fActionType;
    property GetIsStepDone:boolean read IsStepDone write IsStepDone;
    procedure Save(SaveStream:TKMemoryStream); virtual;
  end;

      {Abandon the current walk, move onto next tile}
      TUnitActionAbandonWalk = class(TUnitAction)
      private
        fWalkTo:TKMPoint;
      public
        constructor Create(LocB:TKMPoint; const aActionType:TUnitActionType=ua_Walk);
        constructor Load(LoadStream: TKMemoryStream);
        procedure Execute(KMUnit: TKMUnit; TimeDelta: single; out DoEnd: Boolean); override;
        procedure Save(SaveStream:TKMemoryStream); override;
      end;

  TUnitTask = class(TObject)
  private
    fTaskName:TUnitTaskName;
    fUnit:TKMUnit; //Unit who's performing the Task
    fPhase:byte;
    fPhase2:byte;
  public
    constructor Create(aUnit:TKMUnit);
    destructor Destroy; override;
    procedure Abandon; virtual;
    procedure Execute(out TaskDone:boolean); virtual; abstract;
    procedure Save(SaveStream:TKMemoryStream); virtual;
    procedure Load(LoadStream:TKMemoryStream); virtual;
  end;

    TTaskSelfTrain = class(TUnitTask)
    private
      fSchool:TKMHouseSchool;
    public
      constructor Create(aUnit:TKMUnit; aSchool:TKMHouseSchool);
      destructor Destroy; override;
      procedure Abandon(); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskDeliver = class(TUnitTask)
    private
      fFrom:TKMHouse;
      fToHouse:TKMHouse;
      fToUnit:TKMUnit;
      fResourceType:TResourceType;
      fDeliverID:integer;
    public
      DeliverKind:TDeliverKind;
      constructor Create(aSerf:TKMUnitSerf; aFrom:TKMHouse; toHouse:TKMHouse; toUnit:TKMUnit; Res:TResourceType; aID:integer);
      destructor Destroy; override;
      procedure Abandon; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildRoad = class(TUnitTask)
    private
      fLoc:TKMPoint;
      ID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildWine = class(TUnitTask)
    private
      fLoc:TKMPoint;
      ID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildField = class(TUnitTask)
    private
      fLoc:TKMPoint;
      ID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildWall = class(TUnitTask)
    private
      fLoc:TKMPoint;
      ID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouseArea = class(TUnitTask)
    private
      fHouse:TKMHouse;
      TaskID:integer;
      Step:byte;
      ListOfCells:array[1..4*4]of TKMPoint;
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      destructor Destroy; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouse = class(TUnitTask)
    private
      fHouse:TKMHouse;
      TaskID:integer;
      LocCount:byte; //Count for locations around the house from where worker can build
      CurLoc:byte; //Current WIP location
      Cells:array[1..4*4]of TKMPointDir; //List of surrounding cells and directions
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      destructor Destroy; override;
      procedure Abandon(); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouseRepair = class(TUnitTask)
    private
      fHouse:TKMHouse;
      TaskID:integer;
      LocCount:byte; //Count for locations around the house from where worker can build
      CurLoc:byte; //Current WIP location
      Cells:array[1..4*4]of TKMPointDir; //List of surrounding cells and directions
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      destructor Destroy; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskGoHome = class(TUnitTask)
    private
    public
      constructor Create(aUnit:TKMUnit);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskGoEat = class(TUnitTask)
    private
      fInn:TKMHouseInn;
      PlaceID:byte; //Units place in Inn
    public
      constructor Create(aInn:TKMHouseInn; aUnit:TKMUnit);
      destructor Destroy; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskMining = class(TUnitTask)
    private
      WorkPlan:TUnitWorkPlan;
      BeastID:byte;
      function ResourceExists():boolean;
    public
      constructor Create(aWorkPlan:TUnitWorkPlan; aUnit:TKMUnit; aHouse:TKMHouse);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    {Yep, this is a Task}
    TTaskDie = class(TUnitTask)
    private
      SequenceLength:integer;
    public
      constructor Create(aUnit:TKMUnit);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskGoOutShowHungry = class(TUnitTask)
    public
      constructor Create(aUnit:TKMUnit);
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

  TKMUnit = class(TObject) //todo: actions should return enum result
  private
    fUnitType: TUnitType;
    fUnitTask: TUnitTask;
    fCurrentAction: TUnitAction;
    fThought:TUnitThought;
    fCondition:integer; //Unit condition, when it reaches zero unit should die
    fOwner:TPlayerID;
    fHome:TKMHouse;
    fPosition: TKMPointF;
    fLastUpdateTime: Cardinal;
    fVisible:boolean;
    fIsDead:boolean;
    fPointerCount:integer;
    procedure CloseUnit;
    procedure SetAction(aAction: TUnitAction; aStep:integer);
  public
    ID:integer; //unique unit ID, used for save/load to sync to
    AnimStep: integer;
    Direction: TKMDirection;
    PrevPosition: TKMPoint;
    NextPosition: TKMPoint; //Thats where unit is going to. Next tile in route or same tile if stay on place
  public
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
    constructor Load(LoadStream:TKMemoryStream);
    destructor Destroy; override;
    function GetSelf:TKMUnit; //Returns self and adds one to the pointer counter
    procedure RemovePointer;  //Decreases the pointer counter
    property GetPointerCount:integer read fPointerCount;
    procedure KillUnit;
    function GetSupportedActions: TUnitActionTypeSet; virtual;
    function HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): Boolean;
    procedure SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouseType:THouseType=ht_None);
    procedure SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
    procedure SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
    procedure SetActionWalk(aKMUnit: TKMUnit; aLocB,aAvoid:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true); overload;
    procedure SetActionWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true); overload;
    procedure SetActionAbandonWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
    procedure Feed(Amount:single);
    procedure AbandonWalk;
    procedure PlaceUnitAfterHouseDestroyed();
    function GetDesiredPassability():TPassability;
    property GetOwner:TPlayerID read fOwner;
    function GetSpeed():single;
    property GetHome:TKMHouse read fHome;
    property GetUnitAction: TUnitAction read fCurrentAction;
    function GetUnitActionType():TUnitActionType;
    property GetUnitTask: TUnitTask read fUnitTask;
    property SetUnitTask: TUnitTask write fUnitTask;
    property GetUnitType: TUnitType read fUnitType;
    function GetUnitTaskText():string;
    function GetUnitActText():string;
    property GetCondition: integer read fCondition;
    procedure CancelUnitTask;
    property IsVisible: boolean read fVisible;
    property SetVisibility:boolean write fVisible;
    property IsDead:boolean read fIsDead;
    function IsArmyUnit():boolean;
    procedure RemoveUntrainedFromSchool();
    function CanGoEat:boolean;
    //property IsAtHome: boolean read UnitAtHome;
    function GetPosition():TKMPoint;
    property PositionF:TKMPointF read fPosition write fPosition;
    property Thought:TUnitThought read fThought write fThought;
  private
    procedure UpdateHunger;
    procedure UpdateFOW();
    procedure UpdateThoughts();
    procedure UpdateVisibility();
  public
    procedure Save(SaveStream:TKMemoryStream); virtual;
    //procedure Load(LoadStream:TKMemoryStream); virtual;
    function UpdateState():boolean; virtual;
    procedure Paint; virtual;
  end;

  //This is a common class for units going out of their homes for resources
  TKMUnitCitizen = class(TKMUnit)
  public
    WorkPlan:TUnitWorkPlan;
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
    destructor Destroy; override;
    function FindHome():boolean;
    function InitiateMining():TUnitTask;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Serf class - transports all goods ingame between houses
  TKMUnitSerf = class(TKMUnit)
    Carry: TResourceType;
  public
    function GiveResource(Res:TResourceType):boolean;
    function TakeResource(Res:TResourceType):boolean;
    function GetActionFromQueue():TUnitTask;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Worker class - builds everything ingame
  TKMUnitWorker = class(TKMUnit)
  public
    function GetActionFromQueue():TUnitTask;
    procedure AbandonWork;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Possibly melee warrior class? with Archer class separate?
  TKMUnitWarrior = class(TKMUnit)
    fIsCommander:boolean; //Wherever the unit is a leader of a group and has a shtandart
    fCommander:TKMUnit; //ID of commander unit
    fFlagAnim:cardinal;
    fOrder:TWarriorOrder;
    fOrderLoc:TKMPoint;
  public
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
    function GetSupportedActions: TUnitActionTypeSet; override;
    procedure PlaceOrder(aWarriorOrder:TWarriorOrder; aLoc:TKMPoint);
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Animals
  TKMUnitAnimal = class(TKMUnit)
    fFishCount:byte; //1-5
  public
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType); overload;
    constructor Load(LoadStream:TKMemoryStream); overload;
    function ReduceFish:boolean;
    function GetSupportedActions: TUnitActionTypeSet; override;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;


  TKMUnitsCollection = class(TKMList) //List of TKMUnits
  private
    //Groups:array of integer;
  public
    function Add(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; AutoPlace:boolean=true):TKMUnit;
    function AddGroup(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; aDir:TKMDirection; aUnitPerRow, aUnitCount:word):TKMUnit;
    procedure Rem(aUnit:TKMUnit);
    function HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): TKMUnit;
    procedure GetLocations(aOwner:TPlayerID; out Loc:TKMPointList);
    function GetTotalPointers: integer;
    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
    procedure UpdateState;
    procedure Paint();
  end;

implementation
uses KM_Unit1, KM_Render, KM_DeliverQueue, KM_LoadLib, KM_PlayersCollection, KM_SoundFX, KM_Viewport, KM_Game,
KM_ResourceGFX, KM_UnitActionGoInOut, KM_UnitActionStay, KM_UnitActionWalkTo;


{ TKMUnitCitizen }
constructor TKMUnitCitizen.Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited;
  WorkPlan := TUnitWorkPlan.Create;
end;


destructor TKMUnitCitizen.Destroy;
begin
  FreeAndNil(WorkPlan);
  Inherited;
end;


function TKMUnitCitizen.FindHome():boolean;
var KMHouse:TKMHouse;
begin
  Result:=false;
  KMHouse:=fPlayers.Player[byte(fOwner)].FindEmptyHouse(fUnitType,GetPosition);
  if KMHouse<>nil then begin
    fHome:=KMHouse.GetSelf;
    Result:=true;
  end;
end;


procedure TKMUnitCitizen.Paint();
var UnitType:integer; AnimAct,AnimDir:integer;
begin
inherited;
if not fVisible then exit;
UnitType:=byte(fUnitType);
AnimAct:=byte(fCurrentAction.fActionType);
AnimDir:=byte(Direction);

  if MakeShowUnitRoutes then
  if fCurrentAction is TUnitActionWalkTo then
    fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,
                            TUnitActionWalkTo(fCurrentAction).NodePos,
                            $FF00FFFF);

case fCurrentAction.fActionType of
ua_Walk:
  begin
    fRender.RenderUnit(UnitType,       1, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);
    if ua_WalkArm in UnitSupportedActions[byte(UnitType)] then
    fRender.RenderUnit(UnitType,       9, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,false);
  end;
ua_Work..ua_Eat:
    fRender.RenderUnit(UnitType, AnimAct, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);
ua_WalkArm .. ua_WalkBooty2:
  begin
    fRender.RenderUnit(UnitType,       1, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);
    fRender.RenderUnit(UnitType, AnimAct, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,false);
  end;
end;

  if fThought<>th_None then
  fRender.RenderUnitThought(fThought, AnimStep, fPosition.X+0.5, fPosition.Y+1);
end;


procedure TKMUnitCitizen.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  WorkPlan.Save(SaveStream);
end;


function TKMUnitCitizen.UpdateState():boolean;
var H:TKMHouseInn; RestTime: integer;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;
  if Self.IsDead then exit; //Caused by SelfTrain.Abandoned

  fThought:=th_None;

{  if fUnitTask=nil then //Which is always nil if 'Inherited UpdateState' works properly
  if not TestHunger then
  if not TestHasHome then
  if not TestAtHome then
  if not TestMining then
    Idle..}

  //Reset unit activity if home was destroyed, except when unit is dying or eating (finish eating/dying first)
  if (fHome<>nil)and(fHome.IsDestroyed)and(not(fUnitTask is TTaskDie))and(not(fUnitTask is TTaskGoEat)) then
  begin
    if fCurrentAction is TUnitActionWalkTo then AbandonWalk;
    FreeAndNil(fUnitTask);
    if KMSamePoint(GetPosition,fHome.GetEntrance) then PlaceUnitAfterHouseDestroyed;
    fHome.RemovePointer;
    fHome := nil;
  end;
    

  if fCondition<UNIT_MIN_CONDITION then
  begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition,not fVisible);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self)
    else
      if fHome <> nil then
        if not fVisible then
          fUnitTask:=TTaskGoOutShowHungry.Create(Self)
        else
          fUnitTask:=TTaskGoHome.Create(Self);
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    if (fHome=nil) then
      if FindHome then
        fUnitTask:=TTaskGoHome.Create(Self) //Home found - go there
      else begin
        fThought:=th_Quest; //Always show quest when idle, unlike serfs who randomly show it
        SetActionStay(120, ua_Walk) //There's no home
      end
    else
      if fVisible then//Unit is not at home, still it has one
        fUnitTask:=TTaskGoHome.Create(Self)
      else
        fUnitTask:=InitiateMining; //Unit is at home, so go get a job

  if fHome <> nil then
       RestTime := HouseDAT[integer(fHome.GetHouseType)].WorkerRest*10
  else RestTime := 120; //Unit may not have a home; if so, load a default value

  if fUnitTask=nil then begin
    if random(2) = 0 then fThought := th_Quest;
    SetActionStay(RestTime, ua_Walk); //Absolutely nothing to do ...
  end;

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitCitizen.InitiateMining():TUnitTask;
var i,Tmp,Res:integer;
begin
  Result:=nil;

  Res:=1;
  //Check if House has production orders
  //Random pick from whole amount
  if HousePlaceOrders[byte(fHome.GetHouseType)] then
  begin
    Tmp := fHome.CheckResOrder(1)+fHome.CheckResOrder(2)+fHome.CheckResOrder(3)+fHome.CheckResOrder(4);
    if Tmp=0 then exit; //No orders
    Tmp:=Random(Tmp)+1; //Pick random from overall count
    for i:=1 to 4 do begin
      if InRange(Tmp,1,fHome.CheckResOrder(i)) then Res:=i;
      dec(Tmp,fHome.CheckResOrder(i));
    end;
  end;

  //if not KMSamePoint(GetPosition,fHome.GetEntrance) then begin
  //  fLog.AssertToLog(KMSamePoint(GetPosition,fHome.GetEntrance),'Asking for work from wrong spot');
  //  fViewport.SetCenter(GetPosition.X,GetPosition.Y);
  //end;

  WorkPlan.FindPlan(fUnitType,fHome.GetHouseType,HouseOutput[byte(fHome.GetHouseType),Res],KMPointY1(fHome.GetEntrance));

  //Now issue a message if we failed because the resource is depleted
  if WorkPlan.ResourceDepleted and not fHome.ResourceDepletedMsgIssued then
  begin
    case fHome.GetHouseType of
      ht_Quary:    Tmp := 290;
      ht_CoalMine: Tmp := 291;
      ht_IronMine: Tmp := 292;
      ht_GoldMine: Tmp := 293;
      ht_FisherHut:Tmp := 294;
      else Tmp := 0;
    end;
    if Tmp <> 0 then
      fGame.fGamePlayInterface.IssueMessage(msgHouse,fTextLibrary.GetTextString(Tmp), fHome.GetEntrance);
    fHome.ResourceDepletedMsgIssued := true;
  end;

  if (not WorkPlan.IsIssued) or
     ((WorkPlan.Resource1<>rt_None)and(fHome.CheckResIn(WorkPlan.Resource1)<WorkPlan.Count1)) or
     ((WorkPlan.Resource2<>rt_None)and(fHome.CheckResIn(WorkPlan.Resource2)<WorkPlan.Count2)) or
     (fHome.CheckResOut(WorkPlan.Product1)>=MAX_RES_IN_HOUSE) or
     (fHome.CheckResOut(WorkPlan.Product2)>=MAX_RES_IN_HOUSE) then
  else
  begin
    if HousePlaceOrders[byte(fHome.GetHouseType)] then
      fHome.ResRemOrder(Res);
    Result := TTaskMining.Create(WorkPlan,Self,fHome);
  end;
end;


{ TKMSerf }
procedure TKMUnitSerf.Paint();
var AnimAct,AnimDir:integer;
begin
  inherited;
  if not fVisible then exit;
  AnimAct:=integer(fCurrentAction.fActionType); //should correspond with UnitAction
  AnimDir:=integer(Direction);

  if MakeShowUnitRoutes then
  if fCurrentAction is TUnitActionWalkTo then
    fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,TUnitActionWalkTo(fCurrentAction).NodePos,$FFFF00FF);

  fRender.RenderUnit(byte(GetUnitType), AnimAct, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);

  if fUnitTask is TTaskDie then exit; //Do not show unnecessary arms

  if Carry<>rt_None then
    fRender.RenderUnitCarry(integer(Carry), AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1)
  else
    fRender.RenderUnit(byte(GetUnitType), 9, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,false);

  if fThought<>th_None then
  fRender.RenderUnitThought(fThought, AnimStep, fPosition.X+0.5, fPosition.Y+1);
end;


procedure TKMUnitSerf.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(Carry, 4);
end;


function TKMUnitSerf.UpdateState():boolean;
var
  H:TKMHouseInn;
  OldThought:TUnitThought;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;

  OldThought:=fThought;
  fThought:=th_None;

  if fCondition<UNIT_MIN_CONDITION then begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self);
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    fUnitTask:=GetActionFromQueue;

  //Only show quest thought if we are idle and not thinking anything else (e.g. death)
  if fUnitTask=nil then begin
    if (random(2)=0)and(OldThought=th_None) then fThought:=th_Quest; //
    SetActionStay(60,ua_Walk); //Stay idle
  end;

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitSerf.GiveResource(Res:TResourceType):boolean;
begin
  Result:=false;
  if Carry<>rt_None then exit;
  Carry:=Res;
  Result:=true;
end;


function TKMUnitSerf.TakeResource(Res:TResourceType):boolean;
begin
  Result:=true;
  if Carry=rt_None then
    Result:=false
  else
    Carry:=rt_None;
end;


function TKMUnitSerf.GetActionFromQueue():TUnitTask;
begin
  Result:=fPlayers.Player[byte(fOwner)].DeliverList.AskForDelivery(Self);
end;


{ TKMWorker }
procedure TKMUnitWorker.Paint();
var AnimAct,AnimDir:integer;
begin
  inherited;
  if not fVisible then exit;

  if MakeShowUnitRoutes then
  if fCurrentAction is TUnitActionWalkTo then
    fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,TUnitActionWalkTo(fCurrentAction).NodePos,$FFFFFFFF);

  AnimAct:=integer(fCurrentAction.fActionType); //should correspond with UnitAction
  AnimDir:=integer(Direction);

  fRender.RenderUnit(byte(GetUnitType), AnimAct, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);

  if fThought<>th_None then
  fRender.RenderUnitThought(fThought, AnimStep, fPosition.X+0.5, fPosition.Y+1);
end;


procedure TKMUnitWorker.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  //Nothing to save yet
end;


function TKMUnitWorker.UpdateState():boolean;
var
  H:TKMHouseInn;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;

  if fCondition<UNIT_MIN_CONDITION then begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self);
  end;

  if (fThought = th_Build)and(fUnitTask = nil) then
    fThought := th_None; //Remove build thought if we are no longer doing anything

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    fUnitTask:=GetActionFromQueue;

  if fUnitTask=nil then SetActionStay(20,ua_Walk);

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitWorker.GetActionFromQueue():TUnitTask;
begin
                   Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHouseRepair(Self,Self.GetPosition);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHousePlan(Self,Self.GetPosition);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForRoad(Self,Self.GetPosition);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHouse(Self,Self.GetPosition);
end;


procedure TKMUnitWorker.AbandonWork;
begin
  //This will be called when we die, and we should abandom our task (if any) and clean up stuff like temporary passability
  if fUnitTask <> nil then
  begin
    //Road, wine and field: remove the markup that disallows all other building (mu_UnderConstruction) only if we have started digging
    if (fUnitTask is TTaskBuildRoad)
    or (fUnitTask is TTaskBuildWine)
    or (fUnitTask is TTaskBuildField)
    or (fUnitTask is TTaskBuildWall) then
      if fUnitTask.fPhase > 1 then fTerrain.RemMarkup(TTaskBuildRoad(fUnitTask).fLoc)
      else fPlayers.Player[byte(fOwner)].BuildList.ReOpenRoad(TTaskBuildRoad(fUnitTask).ID); //Allow other workers to take this task

    //House area: remove house, restoring terrain to normal
    if fUnitTask is TTaskBuildHouseArea then
    begin
      if fUnitTask.fPhase <= 1 then
        fPlayers.Player[byte(fOwner)].BuildList.ReOpenHousePlan(TTaskBuildHouseArea(fUnitTask).TaskID) //Allow other workers to take this task
      else //Otherwise we must destroy the house
        if TTaskBuildHouseArea(fUnitTask).fHouse <> nil then
          fPlayers.Player[Integer(fOwner)].RemHouse(TTaskBuildHouseArea(fUnitTask).fHouse.GetPosition,true);
    end;
    //Build House and Repair: No action necessary, another worker will finish it automatically
  end;
end;


{ TKMwarrior }
constructor TKMUnitWarrior.Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited;
  fFlagAnim:=0;
  fIsCommander:=false;
  fCommander:=nil;
  fOrder:=wo_Stop;
  fOrderLoc:=KMPoint(0,0);
end;


function TKMUnitWarrior.GetSupportedActions: TUnitActionTypeSet;
begin
  Result:= [ua_Walk, ua_Work1, ua_Die];
end;


procedure TKMUnitWarrior.PlaceOrder(aWarriorOrder:TWarriorOrder; aLoc:TKMPoint);
begin
  fOrder:=aWarriorOrder;
  fOrderLoc:=aLoc;
end;


procedure TKMUnitWarrior.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fIsCommander, 4);
  if fCommander <> nil then
    SaveStream.Write(fCommander.ID, 4) //Store ID
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(fFlagAnim, 4);
  SaveStream.Write(fUnitType, 4);
  SaveStream.Write(fOrder, 4);
  SaveStream.Write(fOrderLoc, 4);
end;


function TKMUnitWarrior.UpdateState():boolean;
begin
  inc(fFlagAnim);

  //Override current action if there's an Order in queue paying attention
  //to unit WalkTo current position (let the unit arrive on next tile first!)
  //As well let the unit finish it's curent Attack action before taking a new order
  //This should make units response a bit delayed.

  if fCondition <= (UNIT_MIN_CONDITION div 3) then
    fThought:=th_Death
  else
    if fCondition < UNIT_MIN_CONDITION then
      fThought:=th_Eat
    else
      fThought:=th_None;

  //Dispatch new order when warrior finished previous action part
  if (fOrder=wo_Walk) and (GetUnitAction is TUnitActionWalkTo) then
    AbandonWalk; //If we are already walking then cancel it to make way for new command
  if (fOrder=wo_Walk) and GetUnitAction.IsStepDone then
  begin
    SetActionWalk(Self,fOrderLoc);
    fOrder:=wo_Stop;
  end;

  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;

  SetActionStay(50,ua_Walk);

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


procedure TKMUnitWarrior.Paint();
var UnitType,AnimAct,AnimDir:byte;
begin
inherited;
  UnitType:=byte(fUnitType);
  AnimAct:=byte(fCurrentAction.fActionType); //should correspond with UnitAction
  AnimDir:=byte(Direction);
  
  fRender.RenderUnit(UnitType, AnimAct, AnimDir, AnimStep, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,true);
  if fIsCommander then
  fRender.RenderUnitFlag(UnitType,       9, AnimDir, fFlagAnim, byte(fOwner), fPosition.X+0.5, fPosition.Y+1,false);

  if fThought<>th_None then
  fRender.RenderUnitThought(fThought, AnimStep, fPosition.X+0.5, fPosition.Y+1);
end;


{ TKMUnitAnimal }
constructor TKMUnitAnimal.Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited;
  if aUnitType = ut_Fish then fFishCount := 5;  //Always start with 5 fish in the group
end;


constructor TKMUnitAnimal.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fFishCount,1)
end;


function TKMUnitAnimal.ReduceFish:boolean;
begin
  Result := false;
  if fUnitType <> ut_Fish then exit;
  if fFishCount > 1 then
  begin
    fFishCount := fFishCount-1;
    Result := true;
  end
  else if fFishCount = 1 then
  begin
    KillUnit;
    Result := true;
  end;
end;


function TKMUnitAnimal.GetSupportedActions: TUnitActionTypeSet;
begin
  Result:= [ua_Walk];
end;


procedure TKMUnitAnimal.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fFishCount,1);
end;


function TKMUnitAnimal.UpdateState():boolean;
var
  TimeDelta: Cardinal;
  ActDone,TaskDone: Boolean;
  Spot:TKMPoint; //Target spot where unit will go
  SpotJit:byte; 
begin
  Result:=true; //Required for override compatibility

  ActDone:=true;
  TaskDone:=true;
  TimeDelta:= TimeGetTime - fLastUpdateTime;
  fLastUpdateTime:= TimeGetTime;

  if fCurrentAction <> nil then
    fCurrentAction.Execute(Self, TimeDelta/1000, ActDone);

  if ActDone then FreeAndNil(fCurrentAction) else exit;

  if fUnitTask <> nil then
    fUnitTask.Execute(TaskDone);

  if TaskDone then FreeAndNil(fUnitTask) else exit;

  //First make sure the animal isn't stuck (check passibility of our position)
  if not fTerrain.CheckPassability(GetPosition,AnimalTerrain[byte(GetUnitType)]) then
  begin
    //Animal is stuck so it dies
    KillUnit;
    exit;
  end;

  SpotJit:=8; //Initial Spot jitter, it limits number of Spot guessing attempts reducing the range to 0

  repeat //Where unit should go, keep picking until target is walkable for the unit
    dec(SpotJit,1);
    Spot:=fTerrain.EnsureTileInMapCoords(GetPosition.X+RandomS(SpotJit),GetPosition.Y+RandomS(SpotJit));
  until((SpotJit=0)or(fTerrain.Route_CanBeMade(GetPosition,Spot,AnimalTerrain[byte(GetUnitType)],true)));

  if KMSamePoint(GetPosition,Spot) then begin
    SetActionStay(20, ua_Walk);
    exit;
  end;

  SetActionWalk(Self, Spot, KMPoint(0,0));
  if not TUnitActionWalkTo(fCurrentAction).fRouteBuilt then SetActionStay(5, ua_Walk);

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


procedure TKMUnitAnimal.Paint();
var AnimAct,AnimDir:integer;
begin
inherited;
  if fUnitType = ut_Fish then
       AnimAct:=byte(fFishCount) //For fish the action is the number of fish in the group
  else AnimAct:=byte(fCurrentAction.fActionType); //should correspond with UnitAction

  AnimDir:=byte(Direction);
  fRender.RenderUnit(byte(Self.GetUnitType), AnimAct, AnimDir, AnimStep, 0, fPosition.X+0.5, fPosition.Y+1,true);
end;


{ TKMUnit }
constructor TKMUnit.Create(const aOwner:TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited Create;
  fPointerCount := 0;
  fIsDead := false;
  fThought := th_None;
  fHome := nil;
  fPosition.X := PosX;
  fPosition.Y := PosY;
  PrevPosition := GetPosition;
  NextPosition := GetPosition;
  fOwner := aOwner;
  fUnitType := aUnitType;
  Direction := dir_S;
  fVisible := true;
  SetActionStay(10, ua_Walk);
  ID := fGame.GetNewID;
  AnimStep := UnitStillFrames[Direction]; //Use still frame at begining, so units don't all change frame on first tick
  //Units start with a random amount of condition ranging from 3/4 to full.
  //This means that they won't all go eat at the same time and cause crowding, blockages, food shortages and other problems.
  //Note: Warriors of the same group will need to be set the same if they are created at the begining of the mission
  fCondition := UNIT_MAX_CONDITION - Random(UNIT_MAX_CONDITION div 4);
  fTerrain.UnitAdd(NextPosition);
end;


constructor TKMUnit.Load(LoadStream:TKMemoryStream);
var HasTask,HasAct:boolean; TaskType:TUnitTaskName; ActName: TUnitActionName; i:array[1..4]of char; k:integer;
begin
  Inherited Create;
  LoadStream.Read(fUnitType, SizeOf(fUnitType));
  LoadStream.Read(HasTask);
  if HasTask then
  begin
    //LoadStream.Read(TaskType, 4); //Save task type before anything else for it will be used on loading to create specific task type
    //case TaskType of
    //utn_Unknown: fUnitTask := TTaskGoHome.Create(Self) fUnitTask.Load(LoadStream);
    //todo: load task
  end
  else
    fUnitTask := nil;

  LoadStream.Read(HasAct);
  if HasAct then
  begin
    LoadStream.Read(ActName, SizeOf(ActName)); //Save task type before anything else for it will be used on loading to create specific task type
    LoadStream.Seek(-SizeOf(ActName), soFromCurrent); //rewind
    case ActName of
      uan_Unknown: fCurrentAction := nil;
      uan_Stay:    fCurrentAction := TUnitActionStay.Load(LoadStream);
      uan_WalkTo:  fCurrentAction := TUnitActionWalkTo.Load(LoadStream);
      uan_AbandonWalk: fCurrentAction := TUnitActionAbandonWalk.Load(LoadStream);
      //todo: add GoInOut
      else fCurrentAction := nil;
    end;
  end
  else
    fCurrentAction := nil;

  LoadStream.Read(fThought, SizeOf(fThought));
  LoadStream.Read(fCondition);
  LoadStream.Read(fOwner, SizeOf(fOwner));
  LoadStream.Read(fHome, 4); //Substitute it with reference on SyncLoad

  k:= integer(fHome);

  LoadStream.Read(fPosition, 8); //2floats
  LoadStream.Read(fLastUpdateTime, 4);
  LoadStream.Read(fVisible);
  LoadStream.Read(fIsDead);
  LoadStream.Read(fPointerCount);
  LoadStream.Read(ID);
  LoadStream.Read(AnimStep);
  LoadStream.Read(Direction, SizeOf(Direction));
  LoadStream.Read(PrevPosition, 4);
  LoadStream.Read(NextPosition, 4);
end;


destructor TKMUnit.Destroy;
begin
  Inherited;
end;


{Returns self and adds on to the pointer counter}
function TKMUnit.GetSelf:TKMUnit;
begin
  inc(fPointerCount);
  Result := Self;
end;


{Decreases the pointer counter}
procedure TKMUnit.RemovePointer;
begin
  dec(fPointerCount);
end;


{Erase everything related to unit status to exclude it from being accessed by anything but the old pointers}
procedure TKMUnit.CloseUnit;
begin
  if fHome<>nil then
  begin
    fHome.GetHasOwner := false;
    fHome.RemovePointer;
  end;

  fTerrain.UnitRem(NextPosition); //Must happen before we nil NextPosition

  fIsDead       := true;
  fThought      := th_None;
  fHome         := nil;
  fPosition     := KMPointF(0,0);
  PrevPosition  := KMPoint(0,0);
  NextPosition  := KMPoint(0,0);
  fOwner        := play_none;
  fUnitType     := ut_None;
  Direction     := dir_NA;
  fVisible      := false;
  fCondition    := 0;
  AnimStep      := 0;
  FreeAndNil(fCurrentAction);
  FreeAndNil(fUnitTask);

  if Self = fGame.fGamePlayInterface.GetShownUnit then
    fGame.fGamePlayInterface.ClearShownUnit; //If this unit is being shown then we must clear it otherwise it sometimes crashes
end;


{Call this procedure to properly kill unit}
//killing a unit is done in 3 steps
// Kill - release all unit-specific tasks
// TTaskDie - perform dying animation
// CloseUnit - erase all unit data and hide it from further access
procedure TKMUnit.KillUnit;
begin
  if (fUnitTask is TTaskDie) then exit; //Don't kill unit if it's already dying

  if Self is TKMUnitWarrior then begin
    TKMUnitWarrior(Self).fIsCommander:=false; //Remove commanders flag
    //Reassign commanders flag to another unit
  end;

  //Abandon delivery if any
  if (Self is TKMUnitSerf) and (Self.fUnitTask is TTaskDeliver) then
    TTaskDeliver(Self.fUnitTask).Abandon;

  //Abandon work if any
  if Self is TKMUnitWorker then
    TKMUnitWorker(Self).AbandonWork;

  //Update statistics
  if Assigned(fPlayers) and (fOwner <> play_animals) and Assigned(fPlayers.Player[byte(fOwner)]) then
    fPlayers.Player[byte(fOwner)].DestroyedUnit(fUnitType);

  fThought := th_None; //Reset thought
  SetAction(nil,0); //Dispose of current action
  FreeAndNil(fUnitTask); //Should be overriden to dispose of Task-specific items
  fUnitTask:=TTaskDie.Create(Self);
end;


function TKMUnit.GetSupportedActions: TUnitActionTypeSet;
begin
  Result:= UnitSupportedActions[integer(fUnitType)];
end;

function TKMUnit.GetPosition():TKMPoint;
begin
  Result := KMPointRound(fPosition);
end;

function TKMUnit.GetSpeed():single;
begin
  Result := UnitStat[byte(fUnitType)].Speed/24;
end;


function TKMUnit.GetUnitActionType():TUnitActionType;
begin
  Result := GetUnitAction.fActionType;
end;


function TKMUnit.GetUnitTaskText():string;
begin
  Result:='Idle';                                      {----------} //Thats allowed width
  if fUnitTask is TTaskSelfTrain        then Result := 'Self-training';
  if fUnitTask is TTaskDeliver          then Result := 'Delivering';
  if fUnitTask is TTaskBuildRoad        then Result := 'Building road';
  if fUnitTask is TTaskBuildWine        then Result := 'Building wine field';
  if fUnitTask is TTaskBuildField       then Result := 'Building corn field';
  if fUnitTask is TTaskBuildWall        then Result := 'Building a wall';
  if fUnitTask is TTaskBuildHouseArea   then Result := 'Preparing house area';
  if fUnitTask is TTaskBuildHouse       then Result := 'Building house';
  if fUnitTask is TTaskBuildHouseRepair then Result := 'Repairing house';
  if fUnitTask is TTaskGoHome           then Result := 'Going home';
  if fUnitTask is TTaskGoEat            then Result := 'Going to eat';
  if fUnitTask is TTaskMining           then Result := 'Mining resources';
  if fUnitTask is TTaskDie              then Result := 'Dying';
  if fUnitTask is TTaskGoOutShowHungry  then Result := 'Showing hunger';
end;


function TKMUnit.GetUnitActText():string;
begin
  Result:=' - ';
  if fCurrentAction is TUnitActionWalkTo then
    Result:=TInteractionStatusNames[TUnitActionWalkTo(fCurrentAction).GetInteractionStatus]+': '
           +TUnitActionWalkTo(fCurrentAction).Explanation;
end;


procedure TKMUnit.CancelUnitTask;
begin
  if (fUnitTask <> nil)and(fCurrentAction is TUnitActionWalkTo) then
    AbandonWalk;
  FreeAndNil(fUnitTask);
end;


function TKMUnit.HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): Boolean;
begin
  Result := (X = GetPosition.X) and //Keep comparing X,Y to GetPosition incase input is negative numbers
            (Y = GetPosition.Y) and
            ((fUnitType=UT)or(UT=ut_Any)) and
            not (fUnitType in [ut_Wolf..ut_Duck]);
end;


procedure TKMUnit.SetAction(aAction: TUnitAction; aStep:integer);
begin
  AnimStep := aStep;
  if aAction = nil then
  begin
    FreeAndNil(fCurrentAction);
    Exit;
  end;
  if not (aAction.GetActionType in GetSupportedActions) then
  begin
    FreeAndNil(aAction);
    exit;
  end;
  if fCurrentAction <> aAction then
  begin
    fCurrentAction.Free;
    fCurrentAction := aAction;
  end;
end;


procedure TKMUnit.SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouseType:THouseType=ht_None);
begin
  SetAction(TUnitActionGoInOut.Create(aAction, aGoDir, aHouseType),0);
end;


procedure TKMUnit.SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //When standing still in walk, use default frame
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(aTimeToStay, aAction, aStayStill, aStillFrame),aStep);
end;


procedure TKMUnit.SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //Same as above but we will ignore get-out-of-the-way (push) requests from interaction system
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(aTimeToStay, aAction, aStayStill, aStillFrame, true),aStep);
end;


procedure TKMUnit.SetActionWalk(aKMUnit: TKMUnit; aLocB,aAvoid:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true);
begin
  SetAction(TUnitActionWalkTo.Create(aKMUnit, aLocB, aAvoid, aActionType, aWalkToSpot),0);
end;


procedure TKMUnit.SetActionWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true);
begin
  SetAction(TUnitActionWalkTo.Create(aKMUnit, aLocB, KMPoint(0,0), aActionType, aWalkToSpot),0);
end;


procedure TKMUnit.SetActionAbandonWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
begin
  SetAction(TUnitActionAbandonWalk.Create(aLocB, aActionType),aKMUnit.AnimStep); //Use the current animation step, to ensure smooth transition
end;


procedure TKMUnit.AbandonWalk;
begin
  if GetUnitAction is TUnitActionWalkTo then
    SetActionAbandonWalk(Self, NextPosition, ua_Walk)
  else
    SetActionStay(0, ua_Walk); //Error
end;


procedure TKMUnit.PlaceUnitAfterHouseDestroyed();
begin
  //Assume: 1. We are currently in a house
  //        2. That house was just destroyed and so now we must sort ourselves out and reappear for the user
  fTerrain.UnitRem(GetPosition);
  fPosition := KMPointF(fPlayers.FindPlaceForUnit(GetPosition.X,GetPosition.Y,GetUnitType)); //Reposition in case there are other units in the house
  fTerrain.UnitAdd(GetPosition);
  fVisible:=true; //Become visible
end;


function TKMUnit.GetDesiredPassability():TPassability;
begin
  case fUnitType of //Select desired passability depending on unit type
    ut_Serf..ut_Fisher,ut_StoneCutter..ut_Recruit: Result := canWalkRoad; //Citizens except Worker
    ut_Wolf..ut_Duck:                              Result := AnimalTerrain[byte(fUnitType)] //Animals
    else                                           Result := canWalk; //Worker, Warriors
  end;

  if (not DO_SERFS_WALK_ROADS) and (fUnitType in [ut_Serf..ut_Fisher,ut_StoneCutter..ut_Recruit]) then Result := canWalk; //Reset villagers to canWalk for debug (not animals!)

  //Delivery to unit
  if (fUnitType = ut_Serf)
  and(fUnitTask is TTaskDeliver)
  and(TTaskDeliver(fUnitTask).DeliverKind = dk_Unit)
  then
    Result := canWalk;

  //Preparing house area
  if (fUnitType = ut_Worker)
  and(fUnitTask is TTaskBuildHouseArea)
  and(TTaskBuildHouseArea(fUnitTask).fPhase > 1) //Worker has arrived on site
  then
    Result := canAll;

  //Thats for 'miners' at work
  if (fUnitType in [ut_Woodcutter, ut_Farmer, ut_Fisher, ut_StoneCutter])
  and(fUnitTask is TTaskMining)
  then
    Result := canWalk;
end;


procedure TKMUnit.Feed(Amount:single);
begin
  fCondition := min(fCondition + round(Amount), UNIT_MAX_CONDITION);
end;


{Check wherever this unit is armed}
function TKMUnit.IsArmyUnit():boolean;
begin
  Result:= fUnitType in [ut_Militia .. ut_Barbarian];
end;


procedure TKMUnit.RemoveUntrainedFromSchool();
begin
  CloseUnit; //Provide this procedure as a pointer to the private procedure CloseUnit so that CloseUnit is not run by mistake
end;

function TKMUnit.CanGoEat:boolean;
begin
  Result := fPlayers.Player[byte(fOwner)].FindInn(GetPosition) <> nil;
end;


procedure TKMUnit.UpdateHunger;
begin
  if fCondition>0 then //Make unit hungry as long as they are not currently eating in the inn
    if not((fUnitTask is TTaskGoEat) and (TTaskGoEat(fUnitTask).PlaceID<>0)) then
      dec(fCondition);

  //Feed the unit automatically. Don't align it with dec(fCondition) cos FOW uses it as a timer 
  if (not DO_UNIT_HUNGER)and(fCondition<UNIT_MIN_CONDITION+100) then fCondition := UNIT_MAX_CONDITION;

  if fCondition = 0 then
    KillUnit;
end;


procedure TKMUnit.UpdateFOW;
begin
  //Can use fCondition as a sort of counter to reveal terrain X times a sec
  if fCondition mod 10 = 0 then fTerrain.RevealCircle(GetPosition, UnitStat[byte(fUnitType)].Sight, 20, fOwner);
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


procedure TKMUnit.UpdateVisibility;
begin
  if fHome <> nil then //If unit is at home and home was destroyed then make it visible
    if fHome.IsDestroyed and KMSamePoint(GetPosition, fHome.GetEntrance) then
      SetVisibility := true;
end;


procedure TKMUnit.Save(SaveStream:TKMemoryStream);
var HasTask,HasAct:boolean;
begin
  SaveStream.Write(fUnitType, SizeOf(fUnitType));

  HasTask := fUnitTask <> nil; //Thats our switch to know if unit should write down his task.
  SaveStream.Write(HasTask);
  if HasTask then fUnitTask.Save(SaveStream); //TaskType gets written first in fUnitTask.Save

  HasAct := fCurrentAction <> nil;
  SaveStream.Write(HasAct);
  if HasAct then fCurrentAction.Save(SaveStream);

  SaveStream.Write(fThought, SizeOf(fThought));
  fCondition:=7777777;
  SaveStream.Write(fCondition);
  SaveStream.Write(fOwner, SizeOf(fOwner));

  if fHome <> nil then
    SaveStream.Write(fHome.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);

  SaveStream.Write(fPosition, 8); //2floats
  SaveStream.Write(fLastUpdateTime, 4);
  SaveStream.Write(fVisible);
  SaveStream.Write(fIsDead);
  SaveStream.Write(fPointerCount);

  SaveStream.Write(ID);
  SaveStream.Write(AnimStep);
  SaveStream.Write(Direction, SizeOf(Direction));
  SaveStream.Write(PrevPosition, 4);
  SaveStream.Write(NextPosition, 4);
end;


{Here are common Unit.UpdateState routines}
function TKMUnit.UpdateState():boolean;
var
  TimeDelta: Cardinal;
  ActDone,TaskDone: Boolean;
begin
  //There are layers of unit activity (bottom to top):
  // - Action (Atom creating layer (walk 1frame, etc..))
  // - Task (Action creating layer)
  // - specific UpdateState (Task creating layer)

  Result:=true;

  UpdateHunger();
  UpdateFOW();
  UpdateThoughts();
  UpdateVisibility(); //incase units home was destroyed

  //
  //Performing Tasks and Actions now
  //------------------------------------------------------------------------------------------------

  ActDone:=true;
  TaskDone:=true;
  TimeDelta:= TimeGetTime - fLastUpdateTime;
  fLastUpdateTime:= TimeGetTime;

  //Shortcut to freeze unit in place if it's on an unwalkable tile
  if fCurrentAction is TUnitActionWalkTo then
    if GetDesiredPassability = canWalkRoad then
    begin
      if not fTerrain.CheckPassability(GetPosition, canWalk) then
        exit;
    end else
    if not fTerrain.CheckPassability(GetPosition, GetDesiredPassability) then
      exit;

//@Lewin: I want to switch to this pattern, need your opinion on it:
//todo: new task handling pattern
{
  if fCurrentAction<>nil then
  case fCurrentAction.Execute(Self, TimeDelta/1000) of
    ActContinues: exit;
    ActAborted: fUnitTask.Abandon; //abandon the task properly, move along to unit task-specific UpdateState
    ActDone: ; move along to unit task
  end;

  if fUnitTask <> nil then
  case fUnitTask.Execute() of
    TaskContinues: exit;
    TaskAbandoned,
    TaskDone: ; //move along to unit-specific UpdateState
  end;
}
//@Krom: Looks fine to me. :)

  if fCurrentAction <> nil then
    fCurrentAction.Execute(Self, TimeDelta/1000, ActDone);

  if ActDone then FreeAndNil(fCurrentAction) else exit;

  if fUnitTask <> nil then
    fUnitTask.Execute(TaskDone);

  if TaskDone then FreeAndNil(fUnitTask) else exit;

  //If we get to this point then it means that common part is done and now
  //we can perform unit-specific activities (ask for job, etc..)
  Result:=false;
end;


procedure TKMUnit.Paint();
begin
  //fLog.AssertToLog(fUnitTask<>nil,'Unit '+TypeToString(fUnitType)+' has no task!');
  if fCurrentAction=nil then
  begin
    fLog.AssertToLog(fCurrentAction<>nil,'Unit '+TypeToString(fUnitType)+' has no action!');
    SetActionStay(10, ua_Walk);
  end;
  //Here should be catched any cases where unit has no current action - this is a flaw in TTasks somewhere
  //Unit always meant to have some Action performed.
end;


constructor TUnitTask.Create(aUnit:TKMUnit);
begin
  Inherited Create;
  if aUnit <> nil then fUnit := aUnit.GetSelf;
  fTaskName := utn_Unknown;
  fPhase:=0;
  fPhase2:=0;
end;

destructor TUnitTask.Destroy;
begin
  if fUnit <> nil then fUnit.RemovePointer;
  Inherited Destroy;
end;


procedure TUnitTask.Abandon;
begin
  //Shortcut to abandon and declare task done
  fUnit.Thought:=th_None; //Stop any thoughts
  if fUnit <> nil then fUnit.RemovePointer;
  fUnit:=nil;
  fPhase:=MAXBYTE-1; //-1 so that if it is increased on the next run it won't overrun before exiting
  fPhase2:=MAXBYTE-1;
end;


procedure TUnitTask.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(fTaskName, 4); //Save task type before anything else for it will be used on loading to create specific task type
  if fUnit <> nil then
    SaveStream.Write(fUnit.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(fPhase, 4);
  SaveStream.Write(fPhase2, 4);
end;


procedure TUnitTask.Load(LoadStream:TKMemoryStream);
begin
  LoadStream.Read(fUnit, 4);//Substitute it with reference on SyncLoad
  LoadStream.Read(fPhase, 4);
  LoadStream.Read(fPhase2, 4);
end;


{ TTaskSelfTrain }
{Train itself in school}
constructor TTaskSelfTrain.Create(aUnit:TKMUnit; aSchool:TKMHouseSchool);
begin
  Inherited Create(aUnit);
  fTaskName := utn_SelfTrain;
  if aSchool <> nil then fSchool:=TKMHouseSchool(aSchool.GetSelf);
  fUnit.fVisible:=false;
  fUnit.SetActionStay(0,ua_Walk);
end;


destructor TTaskSelfTrain.Destroy;
begin
  if fSchool <> nil then fSchool.RemovePointer;
  Inherited Destroy;
end;


procedure TTaskSelfTrain.Abandon();
var TempUnit: TKMUnit;
begin
  TempUnit := fUnit; //Make local copy of the pointer because Inherited will set the pointer to nil
  Inherited;
  TempUnit.RemoveUntrainedFromSchool; //Abort if someone has destroyed our school
end;


procedure TTaskSelfTrain.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
if fSchool.IsDestroyed then
begin
  Abandon;
  TaskDone:=true;
  exit;
end;
with fUnit do
case fPhase of
  0: begin
      fSchool.SetState(hst_Work,0);
      fSchool.fCurrentAction.SubActionWork(ha_Work1,30);
      SetActionStay(29,ua_Walk);
    end;
  1: begin
      fSchool.fCurrentAction.SubActionWork(ha_Work2,30);
      SetActionStay(29,ua_Walk);
    end;
  2: begin
      fSchool.fCurrentAction.SubActionWork(ha_Work3,30);
      SetActionStay(29,ua_Walk);
    end;
  3: begin
      fSchool.fCurrentAction.SubActionWork(ha_Work4,30);
      SetActionStay(29,ua_Walk);
    end;
  4: begin
      fSchool.fCurrentAction.SubActionWork(ha_Work5,30);
      SetActionStay(29,ua_Walk);
    end;
  5: begin
      fSchool.SetState(hst_Idle,10);
      SetActionStay(9,ua_Walk);
      fSoundLib.Play(sfx_SchoolDing,GetPosition); //Ding as the clock strikes 12
     end;
  6: begin
      SetActionGoIn(ua_Walk,gd_GoOutside,ht_School);
      fSchool.UnitTrainingComplete;
      fPlayers.Player[byte(fOwner)].CreatedUnit(fUnitType,true);
     end;
  else TaskDone:=true;
end;
inc(fPhase);
end;


procedure TTaskSelfTrain.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fSchool <> nil then
    SaveStream.Write(fSchool.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
end;


{ TTaskDeliver }
constructor TTaskDeliver.Create(aSerf:TKMUnitSerf; aFrom:TKMHouse; toHouse:TKMHouse; toUnit:TKMUnit; Res:TResourceType; aID:integer);
begin
  Inherited Create(aSerf);
  fTaskName := utn_Deliver;
  fLog.AssertToLog((toHouse=nil)or(toUnit=nil),'Deliver to House AND Unit?');
  if aFrom <> nil then fFrom:=aFrom.GetSelf;
  if toHouse <> nil then fToHouse:=toHouse.GetSelf;
  if toUnit <> nil then fToUnit:=toUnit.GetSelf;
  fResourceType:=Res;
  fDeliverID:=aID;

  if toHouse<>nil then
    DeliverKind:=dk_House;
  if toUnit<>nil then
    DeliverKind:=dk_Unit;

  fUnit.SetActionLockedStay(0,ua_Walk);
end;

destructor TTaskDeliver.Destroy;
begin
  if fFrom <> nil then fFrom.RemovePointer;
  if fToHouse <> nil then fToHouse.RemovePointer;
  if fToUnit <> nil then fToUnit.RemovePointer;
  Inherited Destroy;
end;

procedure TTaskDeliver.Abandon();
begin
  fPlayers.Player[byte(fUnit.fOwner)].DeliverList.AbandonDelivery(fDeliverID);
  Inherited;
end;


procedure TTaskDeliver.Execute(out TaskDone:boolean);
begin
TaskDone:=false;

with fUnit do
case fPhase of
0: if not fFrom.IsDestroyed then
      SetActionWalk(fUnit,KMPointY1(fFrom.GetEntrance))
   else begin
     Abandon;
     TaskDone:=true;
   end;
1: if not fFrom.IsDestroyed then
     SetActionGoIn(ua_Walk,gd_GoInside,fFrom.GetHouseType)
   else begin
     Abandon;
     TaskDone:=true;
   end;
2: if not fFrom.IsDestroyed then
   begin
     if fFrom.ResTakeFromOut(fResourceType) then begin
       TKMUnitSerf(fUnit).GiveResource(fResourceType);
       fPlayers.Player[byte(fOwner)].DeliverList.TakenOffer(fDeliverID);
     end else begin
       fPlayers.Player[byte(fOwner)].DeliverList.AbandonDelivery(fDeliverID);
       fLog.AssertToLog(false,'Resource''s gone..');
     end;
     SetActionStay(5,ua_Walk); //Wait a moment inside
   end else begin
     PlaceUnitAfterHouseDestroyed; //Unit was invisible while inside. Must show it
     Abandon;
     TaskDone:=true;
   end;
3: if not fFrom.IsDestroyed then
   begin
     SetActionGoIn(ua_Walk,gd_GoOutside,fFrom.GetHouseType);
   end else begin
     PlaceUnitAfterHouseDestroyed(); //Unit was invisible while inside. Must show it. Delivery may still continue even though house was just destroyed
     SetActionLockedStay(0,ua_Walk);
   end;
4: if TKMUnitSerf(fUnit).Carry=rt_None then TaskDone:=true else SetActionLockedStay(0,ua_Walk);
end;

//Deliver into complete house
if DeliverKind = dk_House then
  if fToHouse.IsComplete then
  with fUnit do
  case fPhase of
  0..4:;
  5: if not fToHouse.IsDestroyed then
       SetActionWalk(fUnit,KMPointY1(fToHouse.GetEntrance))
     else begin
       TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
       Abandon;
       TaskDone:=true;
     end;
  6: if not fToHouse.IsDestroyed then
       SetActionGoIn(ua_Walk,gd_GoInside,fToHouse.GetHouseType)
     else begin
       TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
       Abandon;
       TaskDone:=true;
     end;
  7: SetActionStay(5,ua_Walk);
  8: if not fToHouse.IsDestroyed then
     begin
       fToHouse.ResAddToIn(TKMUnitSerf(fUnit).Carry);
       TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
       SetActionGoIn(ua_walk,gd_GoOutside,fToHouse.GetHouseType);
       fPlayers.Player[byte(fOwner)].DeliverList.GaveDemand(fDeliverID);
       fPlayers.Player[byte(fOwner)].DeliverList.AbandonDelivery(fDeliverID);
     end else begin
       PlaceUnitAfterHouseDestroyed; //Unit was invisible while inside. Must show it
       TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
       Abandon;
       TaskDone:=true;
     end;
  else TaskDone:=true;
  end;

//Deliver into wip house
if DeliverKind = dk_House then
  if not fToHouse.IsComplete then
  if not fToHouse.IsDestroyed then
  begin
    with fUnit do
    case fPhase of
    0..4:;
    5: SetActionWalk(fUnit,KMPointY1(fToHouse.GetEntrance));
    6: begin
         fToHouse.ResAddToBuild(TKMUnitSerf(fUnit).Carry);
         TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
         fPlayers.Player[byte(fOwner)].DeliverList.GaveDemand(fDeliverID);
         fPlayers.Player[byte(fOwner)].DeliverList.AbandonDelivery(fDeliverID);
         SetActionStay(1,ua_Walk);
       end;
    else TaskDone:=true;
    end;
  end else begin
    TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
    Abandon;
    TaskDone:=true;
  end;

//Deliver to builder
if DeliverKind = dk_Unit then
with fUnit do
case fPhase of
0..4:;
5: if (fToUnit<>nil)and(fToUnit.fUnitTask<>nil)and(not fToUnit.IsDead) then
     SetActionWalk(fUnit, fToUnit.GetPosition, KMPoint(0,0), ua_Walk, false)
   else
   begin
     TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
     fPlayers.Player[byte(fOwner)].DeliverList.GaveDemand(fDeliverID);
     fPlayers.Player[byte(fOwner)].DeliverList.AbandonDelivery(fDeliverID);
     TaskDone:=true;
   end;
6: begin
      TKMUnitSerf(fUnit).TakeResource(TKMUnitSerf(fUnit).Carry);
      if (fToUnit<>nil)and(fToUnit.fUnitTask<>nil)and(not fToUnit.IsDead)and(not(fToUnit.fUnitTask is TTaskDie)) then begin
        inc(fToUnit.fUnitTask.fPhase);
        fToUnit.SetActionStay(0,ua_Work1);
      end;
      fPlayers.Player[byte(fOwner)].DeliverList.GaveDemand(fDeliverID);
      fPlayers.Player[byte(fOwner)].DeliverList.AbandonDelivery(fDeliverID);
      SetActionStay(1,ua_Walk);
   end;
else TaskDone:=true;
end;

if TaskDone then exit;
inc(fPhase);
if fUnit.fCurrentAction=nil then
  fLog.AssertToLog(false,'fSerf.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskDeliver.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fFrom <> nil then
    SaveStream.Write(fFrom.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  if fToHouse <> nil then
    SaveStream.Write(fToHouse.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  if fToUnit <> nil then
    SaveStream.Write(fToUnit.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(fResourceType,4);
  SaveStream.Write(fDeliverID,4);
end;


{ TTaskBuildRoad }
constructor TTaskBuildRoad.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildRoad;
  fLoc      := aLoc;
  ID        := aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskBuildRoad.Execute(out TaskDone:boolean);
const Cycle=11;
begin
TaskDone:=false;
with fUnit do
case fPhase of
0: begin
     SetActionWalk(fUnit,fLoc);
     fThought := th_Build;
   end;
1: begin
     fThought := th_None;
     fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
     fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
     fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(ID); //Close the job now because it can no longer be cancelled
     SetActionStay(11,ua_Work1,false);
   end;
2: begin
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work1,false);
   end;
3: begin
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work1,false);
     fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil, fUnit, rt_Stone, 1, dt_Once, di_High);
   end;

4: begin
     SetActionStay(30,ua_Work1);
     fThought:=th_Stone;
   end;

5: begin
     SetActionStay(11,ua_Work2,false);
     fThought:=th_None;
   end;
6: begin
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work2,false);
   end;
7: begin
     fTerrain.IncDigState(fLoc);
     fTerrain.FlattenTerrain(fLoc); //Flatten the terrain slightly on and around the road
     if MapElem[fTerrain.Land[fLoc.Y,fLoc.X].Obj+1].WineOrCorn then
       fTerrain.Land[fLoc.Y,fLoc.X].Obj:=255; //Remove fields and other quads as they won't fit with road
     SetActionStay(11,ua_Work2,false);
   end;
8: begin
     fTerrain.SetRoad(fLoc,fOwner);
     SetActionStay(5,ua_Work2);
     fTerrain.RemMarkup(fLoc);
   end;
else TaskDone:=true;
end;
if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rt_Stone
end;


procedure TTaskBuildRoad.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc,4);
  SaveStream.Write(ID,4);
end;


{ TTaskBuildWine }
constructor TTaskBuildWine.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildWine;
  fLoc:=aLoc;
  ID:=aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskBuildWine.Execute(out TaskDone:boolean);
const Cycle=11;
begin
TaskDone:=false;
with fUnit do
case fPhase of
 0: begin
      SetActionWalk(fUnit,fLoc);
      fThought := th_Build;
    end;
 1: begin
      fThought := th_None;
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(ID); //Close the job now because it can no longer be cancelled
      SetActionStay(11,ua_Work1,false);
    end;
 2: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(11,ua_Work1,false);
    end;
 3: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(11,ua_Work1,false);
      fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil,fUnit,rt_Wood, 1, dt_Once, di_High);
    end;
 4: begin
      SetActionStay(30,ua_Work1);
      fThought:=th_Wood;
    end;
 5: begin
      SetActionStay(11*4,ua_Work2,false);
      fThought:=th_None;
    end;  
 6: begin
      fTerrain.SetField(fLoc,fOwner,ft_Wine);
      SetActionStay(5,ua_Work2);
      fTerrain.RemMarkup(fLoc);
    end;
 else TaskDone:=true;
end;
if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rt_Stone
end;


procedure TTaskBuildWine.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc,4);
  SaveStream.Write(ID,4);
end;


{ TTaskBuildField }
constructor TTaskBuildField.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildField;
  fLoc:=aLoc;
  ID:=aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskBuildField.Execute(out TaskDone:boolean);
const Cycle=11;
begin
TaskDone:=false;
with fUnit do
case fPhase of
  0: begin
       SetActionWalk(fUnit,fLoc);
       fThought := th_Build;
     end;
  1: begin
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(ID); //Close the job now because it can no longer be cancelled
      SetActionLockedStay(0,ua_Walk);
     end;
  2: begin
      SetActionStay(11,ua_Work1,false);
      inc(fPhase2);
      if fPhase2 in [4,8,10] then fTerrain.IncDigState(fLoc);
     end;
  3: begin
      fThought := th_None; //Keep thinking build until it's done
      fTerrain.SetField(fLoc,fOwner,ft_Corn);
      SetActionStay(5,ua_Walk);
      fTerrain.RemMarkup(fLoc);
     end;
  else TaskDone:=true;
end;
if fPhase2 in [0,10] then inc(fPhase);
end;


procedure TTaskBuildField.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc,4);
  SaveStream.Write(ID,4);
end;


{ TTaskBuildWall }
constructor TTaskBuildWall.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildWall;
  fLoc:=aLoc;
  ID:=aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskBuildWall.Execute(out TaskDone:boolean);
const Cycle=11;
begin
TaskDone:=false;
with fUnit do
case fPhase of
  0: begin
       SetActionWalk(fUnit,fLoc);
       fThought := th_Build;
     end;
  1: begin
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(ID); //Close the job now because it can no longer be cancelled
      SetActionLockedStay(0,ua_Walk);
     end;
  2: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work1,false);
    end;
  3: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work1,false);
      fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil, fUnit, rt_Wood, 1, dt_Once, di_High);
    end;
  4: begin
      SetActionStay(30,ua_Work1);
      fThought:=th_Wood;
    end;
  5: begin
      fThought := th_None;
      SetActionStay(22,ua_Work2,false);
    end;
  6: begin
      fTerrain.ResetDigState(fLoc);
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work2,false);
    end;
    //Ask for 2 more wood now
    //@Lewin: It's yet incomplete
  7: begin
      //Walk away from tile and continue building from the side
      SetActionWalk(fUnit,fTerrain.GetOutOfTheWay(fUnit.GetPosition,KMPoint(0,0),canWalk));
    end;
  8: begin
      //fTerrain.IncWallState(fLoc);
      SetActionStay(11,ua_Work,false);
    end;
  9: begin
      fTerrain.SetWall(fLoc,fOwner);
      SetActionLockedStay(0,ua_Work);
      fTerrain.RemMarkup(fLoc);
     end;
  else TaskDone:=true;
end;
if (fPhase<>4)and(fPhase<>8) then inc(fPhase); //Phase=4 is when worker waits for rt_Wood
if fPhase=8 then inc(fPhase2);
if fPhase2=5 then inc(fPhase); //wait 5 cycles
end;


procedure TTaskBuildWall.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc,4);
  SaveStream.Write(ID,4);
end;


{ TTaskBuildHouseArea }
constructor TTaskBuildHouseArea.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
var i,k:integer;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouseArea;
  fHouse := aHouse.GetSelf;
  TaskID := aID;
  Step := 0;
  for i := 1 to 4 do for k := 1 to 4 do
  if HousePlanYX[byte(fHouse.GetHouseType),i,k] <> 0 then begin
    inc(Step);
    ListOfCells[Step] := KMPoint(fHouse.GetPosition.X + k - 3,fHouse.GetPosition.Y + i - 4);
  end;
  fUnit.SetActionLockedStay(0, ua_Walk);
end;

destructor TTaskBuildHouseArea.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer; 
  Inherited Destroy;
end;

{Prepare building site - flatten terrain}
procedure TTaskBuildHouseArea.Execute(out TaskDone:boolean);
begin
TaskDone:=false;

if fHouse.IsDestroyed then
begin
  Abandon;
  TaskDone := true;
  exit;
end;

with fUnit do
case fPhase of
0:  begin
      SetActionWalk(fUnit,fHouse.GetEntrance);
      fThought := th_Build;
    end;
1:  if not fHouse.IsDestroyed then begin //House plan was cancelled before worker has arrived on site
      fPlayers.Player[byte(fOwner)].BuildList.CloseHousePlan(TaskID);
      fTerrain.SetHouse(fHouse.GetPosition, fHouse.GetHouseType, hs_Fence, fOwner);
      fHouse.SetBuildingState(hbs_NoGlyph);
      SetActionStay(5,ua_Walk);
      fThought := th_None;
    end else begin
      TaskDone:=true;
      fThought := th_None;
    end;
2:  SetActionWalk(fUnit,ListOfCells[Step]);
3:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
    end;
4:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
    end;
5:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
    end;
6:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
      if not fHouse.IsDestroyed then
      if KMSamePoint(fHouse.GetEntrance,ListOfCells[Step]) then
        fTerrain.SetRoad(fHouse.GetEntrance, fOwner);
      fTerrain.Land[ListOfCells[Step].Y,ListOfCells[Step].X].Obj:=255; //All objects are removed
      fTerrain.SetMarkup(ListOfCells[Step],mu_HouseFenceNoWalk); //Block passability on tile
      fTerrain.RecalculatePassability(ListOfCells[Step]); //@Lewin: I didn't test if it worked yet..
      dec(Step);
    end;
7:  SetActionWalk(fUnit,KMPointY1(fHouse.GetEntrance));
8:  begin
      fHouse.SetBuildingState(hbs_Wood);
      fPlayers.Player[byte(fOwner)].BuildList.AddNewHouse(fHouse); //Add the house to JobList, so then all workers could take it
      with HouseDAT[byte(fHouse.GetHouseType)] do begin
        fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(fHouse, nil, rt_Wood, WoodCost, dt_Once, di_High);
        fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(fHouse, nil, rt_Stone, StoneCost, dt_Once, di_High);
      end;
      SetActionStay(1,ua_Walk);
    end;
else TaskDone:=true;
end;
inc(fPhase);
if (fPhase=7)and(Step>0) then fPhase:=2; //Repeat with next cell
end;


procedure TTaskBuildHouseArea.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(TaskID,4);
  SaveStream.Write(Step,4);
  for i:=1 to length(ListOfCells) do
  SaveStream.Write(ListOfCells[i],4);
end;


{ TTaskBuildHouse }
constructor TTaskBuildHouse.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
  var i,k:integer; ht:byte; Loc:TKMPoint;
  procedure AddLoc(X,Y:word; Dir:TKMDirection);
  begin
    //First check that the passabilty is correct, as the house may be placed against blocked terrain
    if not fTerrain.CheckPassability(KMPoint(X,Y),canWalk) then exit;
    inc(LocCount);
    Cells[LocCount].Loc:=KMPoint(X,Y);
    Cells[LocCount].Dir:=byte(Dir);
  end;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouse;
  fHouse:=aHouse.GetSelf;
  Loc:=fHouse.GetPosition;
  TaskID:=aID;
  LocCount:=0;
  CurLoc:=0;
  ht:=byte(fHouse.GetHouseType);
  //Create list of surrounding tiles and directions
  for i:=1 to 4 do for k:=1 to 4 do
  if HousePlanYX[ht,i,k]<>0 then
  begin
    if (i=1)or(HousePlanYX[ht,i-1,k]=0) then
      AddLoc(Loc.X + k - 3, Loc.Y + i - 4 - 1, dir_S); //Above
    if (i=4)or(HousePlanYX[ht,i+1,k]=0) then
      AddLoc(Loc.X + k - 3, Loc.Y + i - 4 + 1, dir_N); //Below
    if (k=4)or(HousePlanYX[ht,i,k+1]=0) then
      AddLoc(Loc.X + k - 3 + 1, Loc.Y + i - 4, dir_W); //FromRight
    if (k=1)or(HousePlanYX[ht,i,k-1]=0) then
      AddLoc(Loc.X + k - 3 - 1, Loc.Y + i - 4, dir_E);     //FromLeft
  end;
  
  fUnit.SetActionLockedStay(0,ua_Walk);
end;

destructor TTaskBuildHouse.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer;
  Inherited Destroy;
end;

procedure TTaskBuildHouse.Abandon();
begin
  fPlayers.Player[byte(fUnit.fOwner)].BuildList.CloseHouse(TaskID);
  Inherited;
end;

{Build the house}
procedure TTaskBuildHouse.Execute(out TaskDone:boolean);
  function PickRandomSpot(): byte;
  var i, MyCount: integer; Spots: array[1..16] of byte;
  begin
    MyCount := 0;
    for i:=1 to LocCount do
      if not KMSamePoint(Cells[i].Loc,fUnit.GetPosition) then
        if fTerrain.TileInMapCoords(Cells[i].Loc.X,Cells[i].Loc.Y) then
          if fTerrain.Route_CanBeMade(fUnit.GetPosition, Cells[i].Loc ,canWalk, true) then
          begin
            inc(MyCount);
            Spots[MyCount] := i;
          end;
    if MyCount > 0 then
      Result := Spots[Random(MyCount)+1]
    else Result := 0;
  end;
begin
  TaskDone:=false;
  //If the house has been destroyed during the building process then exit immediately
  if fHouse.IsDestroyed then
  begin
    Abandon;
    TaskDone:=true; //Drop the task
    exit;
  end;
  with fUnit do
    case fPhase of
      //Pick random location and go there
      0: begin
           //If house has not enough resource to be built, consider building task is done
           //and look for a new task that has enough resouces. Once this house has building resources
           //delivered it will be available from build queue again.
           if not fHouse.CheckResToBuild then begin
             TaskDone:=true; //Drop the task
             fThought := th_None;
             exit;
           end;
           fThought := th_Build;
           CurLoc := PickRandomSpot();
           SetActionWalk(fUnit,Cells[CurLoc].Loc);
         end;
      1: begin
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           SetActionLockedStay(0,ua_Walk);
         end;
      2: begin
           SetActionStay(5,ua_Work,false,0,0); //Start animation
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           if fHouse.IsStone then fTerrain.SetHouse(fHouse.GetPosition, fHouse.GetHouseType, hs_Built, fOwner); //Remove house plan when we start the stone phase (it is still required for wood)
         end;
      3: begin
           //Cancel building no matter progress if resource depleted or unit is hungry and is able to eat
           if ((fCondition<UNIT_MIN_CONDITION)and(CanGoEat))or(not fHouse.CheckResToBuild) then begin
             TaskDone:=true; //Drop the task
             fThought := th_None;
             exit;
           end;
           fHouse.IncBuildingProgress;
           SetActionStay(6,ua_Work,false,0,5); //Do building and end animation
           inc(fPhase2);
         end;
      4: begin
           fPlayers.Player[byte(fOwner)].BuildList.CloseHouse(TaskID);
           SetActionStay(1,ua_Walk);
           fThought := th_None;
         end;
      else TaskDone:=true;
    end;
  inc(fPhase);
  if (fPhase=4) and (not fHouse.IsComplete) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase:=0 //Then goto new spot
    else
      fPhase:=2; //else do more hits
end;


procedure TTaskBuildHouse.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(TaskID,4);
  SaveStream.Write(LocCount,4);
  SaveStream.Write(CurLoc,4);
  for i:=1 to length(Cells) do
  begin
    SaveStream.Write(Cells[i].Loc,4);
    SaveStream.Write(Cells[i].Dir,4);
  end;
end;


{ TTaskBuildHouseRepair }
constructor TTaskBuildHouseRepair.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
  var i,k:integer; ht:byte; Loc:TKMPoint;
  procedure AddLoc(X,Y:word; Dir:TKMDirection);
  begin
    inc(LocCount);
    Cells[LocCount].Loc:=KMPoint(X,Y);
    Cells[LocCount].Dir:=byte(Dir);
  end;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouseRepair;
  fHouse:=aHouse.GetSelf;
  Loc:=fHouse.GetPosition;
  TaskID:=aID;
  LocCount:=0;
  CurLoc:=0;
  ht:=byte(fHouse.GetHouseType);
  //Create list of surrounding tiles and directions
  for i:=1 to 4 do for k:=1 to 4 do
  if HousePlanYX[ht,i,k]<>0 then
    if (i=1)or(HousePlanYX[ht,i-1,k]=0) then AddLoc(Loc.X + k - 3, Loc.Y + i - 4 - 1, dir_S) else //Up
    if (i=4)or(HousePlanYX[ht,i+1,k]=0) then AddLoc(Loc.X + k - 3, Loc.Y + i - 4 + 1, dir_N) else //Down
    if (k=4)or(HousePlanYX[ht,i,k+1]=0) then AddLoc(Loc.X + k - 3 + 1, Loc.Y + i - 4, dir_W) else //Right
    if (k=1)or(HousePlanYX[ht,i,k-1]=0) then AddLoc(Loc.X + k - 3 - 1, Loc.Y + i - 4, dir_E);     //Left
  fUnit.SetActionLockedStay(0,ua_Walk);
end;

destructor TTaskBuildHouseRepair.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer;
  Inherited Destroy;
end;

{Repair the house}
procedure TTaskBuildHouseRepair.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if (fHouse.IsDestroyed)or(not fHouse.IsDamaged)or(not fHouse.BuildingRepair) then begin
    Abandon;
    TaskDone:=true; //Drop the task
    exit;
  end;

  with fUnit do
    case fPhase of
      //Pick random location and go there
      0: begin
           fThought := th_Build;
           CurLoc:=Random(LocCount)+1;
           SetActionWalk(fUnit,Cells[CurLoc].Loc);
         end;
      1: begin
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           SetActionLockedStay(0,ua_Walk);
         end;
      2: begin
           SetActionStay(5,ua_Work,false,0,0); //Start animation
           Direction:=TKMDirection(Cells[CurLoc].Dir);
         end;
      3: begin
           if (fCondition<UNIT_MIN_CONDITION) and CanGoEat then begin
             TaskDone:=true; //Drop the task
             exit;
           end;
           fHouse.AddRepair;
           SetActionStay(6,ua_Work,false,0,5); //Do building and end animation
           inc(fPhase2);
         end;
      4: begin
           fThought := th_None;
           fPlayers.Player[byte(fOwner)].BuildList.CloseHouse(TaskID);
           SetActionStay(1,ua_Walk);
         end;
      else TaskDone:=true;
    end;
  inc(fPhase);
  if (fPhase=4) and (fHouse.IsDamaged) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase:=0 //Then goto new spot
    else
      fPhase:=2; //else do more hits
end;


procedure TTaskBuildHouseRepair.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(TaskID,4);
  SaveStream.Write(LocCount,4);
  SaveStream.Write(CurLoc,4);
  for i:=1 to length(Cells) do
  begin
    SaveStream.Write(Cells[i].Loc,4);
    SaveStream.Write(Cells[i].Dir,4);
  end;
end;


{ TTaskMining }
constructor TTaskMining.Create(aWorkPlan:TUnitWorkPlan; aUnit:TKMUnit; aHouse:TKMHouse);
begin
  Inherited Create(aUnit);
  fTaskName := utn_Mining;
  WorkPlan  := aWorkPlan;
  BeastID   := 0;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


function TTaskMining.ResourceExists():boolean;
begin
  with fTerrain do
  case WorkPlan.GatheringScript of
    gs_StoneCutter:     Result := TileIsStone(KMPoint(WorkPlan.Loc.X, WorkPlan.Loc.Y - 1)) > 0; //Check stone deposit above Loc, which is walkable tile
    gs_FarmerSow:       Result := TileIsCornField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = 0);
    gs_FarmerCorn:      Result := TileIsCornField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = 65535);
    gs_FarmerWine:      Result := TileIsWineField(WorkPlan.Loc) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].FieldAge = 65535);
    gs_FisherCatch:     Result := CatchFish(KMPointDir(WorkPlan.Loc.X,WorkPlan.Loc.Y,WorkPlan.WorkDir),true);
    gs_WoodCutterPlant: Result := CheckPassability(WorkPlan.Loc, CanPlantTrees);
    gs_WoodCutterCut:   Result := ObjectIsChopableTree(WorkPlan.Loc, 4) and (Land[WorkPlan.Loc.Y, WorkPlan.Loc.X].TreeAge >= TreeAgeFull)
    else                Result := true;
  end;
end;


{This is execution of Resource mining}
procedure TTaskMining.Execute(out TaskDone:boolean);
const SkipWalk=8; SkipWork=30; //Skip to certain Phases
var Dir:integer; TimeToWork, StillFrame:integer;
begin
TaskDone:=false;
if fUnit.fHome <> nil then if fUnit.fHome.IsDestroyed then
begin
  //Make sure we always exit if our home is destroyed
  TaskDone := true;
  exit;
end;
with fUnit do
  case fPhase of
    0: if WorkPlan.HasToWalk then begin
         fHome.SetState(hst_Empty,0);
         SetActionGoIn(WorkPlan.WalkTo,gd_GoOutside,fHome.GetHouseType); //Walk outside the house
       end else begin
         fPhase:=SkipWalk; //Skip walking part if there's no need in it, e.g. CoalMiner or Baker
         SetActionLockedStay(0,ua_Walk);
         exit;
       end;
    1: SetActionWalk(fUnit,WorkPlan.Loc, WorkPlan.WalkTo);
    2: begin //Before work tasks for specific mining jobs
         if WorkPlan.GatheringScript = gs_FisherCatch then
         begin
           Direction := TKMDirection(WorkPlan.WorkDir+1);
           SetActionStay(13, ua_Work1, false); //Throw the line out
         end
         else
           SetActionLockedStay(0, WorkPlan.WorkType);
       end;
    3: //IF resource still exists on location
       if ResourceExists then
       begin //Choose direction and time to work
         Dir:=integer(WorkPlan.WorkDir+1);
         if UnitSprite[integer(fUnitType)].Act[byte(WorkPlan.WorkType)].Dir[Dir].Count<=1 then
           for Dir:=1 to 8 do
             if UnitSprite[integer(fUnitType)].Act[byte(WorkPlan.WorkType)].Dir[Dir].Count>1 then break;
         Dir:=min(Dir,8);
         Direction:=TKMDirection(Dir);
         TimeToWork:=WorkPlan.WorkCyc*max(UnitSprite[integer(fUnitType)].Act[byte(WorkPlan.WorkType)].Dir[Dir].Count,1);
         SetActionStay(TimeToWork, WorkPlan.WorkType, false);
       end
       else
       begin
         TaskDone := true;
         exit;
       end;
    4: begin //After work tasks for specific mining jobs
             if WorkPlan.GatheringScript = gs_WoodCutterCut then
             begin
               SetActionStay(10, WorkPlan.WorkType, true, 5, 5); //Wait for the tree to start falling down
             end
             else
             if WorkPlan.GatheringScript = gs_FisherCatch then
             begin
               SetActionStay(15, ua_Work, false); //Pull the line in
             end
             else
               SetActionLockedStay(0, WorkPlan.WorkType);
       end;
    5: begin StillFrame := 0;
             case WorkPlan.GatheringScript of //Perform special tasks if required
               gs_StoneCutter:     fTerrain.DecStoneDeposit(KMPoint(WorkPlan.Loc.X,WorkPlan.Loc.Y-1));
               gs_FarmerSow:       fTerrain.SowCorn(WorkPlan.Loc);
               gs_FarmerCorn:      fTerrain.CutCorn(WorkPlan.Loc);
               gs_FarmerWine:      fTerrain.CutGrapes(WorkPlan.Loc);
               gs_FisherCatch:     begin fTerrain.CatchFish(KMPointDir(WorkPlan.Loc.X,WorkPlan.Loc.Y,WorkPlan.WorkDir)); WorkPlan.WorkType := ua_WalkTool; end;
               gs_WoodCutterPlant: fTerrain.SetTree(WorkPlan.Loc,fTerrain.ChooseTreeToPlant(WorkPlan.Loc));
               gs_WoodCutterCut:   begin fTerrain.FallTree(WorkPlan.Loc); StillFrame := 5; end;
             end;
         SetActionStay(WorkPlan.AfterWorkDelay, WorkPlan.WorkType, true, StillFrame, StillFrame);
       end;
    6: begin
         if WorkPlan.GatheringScript = gs_WoodCutterCut then
           fTerrain.ChopTree(WorkPlan.Loc); //Make the tree turn into a stump
         SetActionWalk(fUnit,KMPointY1(fHome.GetEntrance), WorkPlan.WalkFrom); //Go home
         fThought := th_Home;
       end;
    7: SetActionGoIn(WorkPlan.WalkFrom,gd_GoInside,fHome.GetHouseType); //Go inside

    {Unit back at home and can process its booty now}
    8: begin
        fThought := th_None;
        fPhase2:=1;
        fHome.SetState(hst_Work,0); //Set house to Work state
        fHome.ResTakeFromIn(WorkPlan.Resource1,WorkPlan.Count1);
        fHome.ResTakeFromIn(WorkPlan.Resource2,WorkPlan.Count2);
        fHome.fCurrentAction.SubActionAdd([ha_Smoke]);
        if WorkPlan.GatheringScript = gs_SwineBreeder then begin
          BeastID:=TKMHouseSwineStable(fHome).FeedBeasts;
          if BeastID<>0 then
            TKMHouseSwineStable(fHome).TakeBeast(BeastID);
        end;
        if WorkPlan.ActCount>=fPhase2 then begin
           fHome.fCurrentAction.SubActionWork(WorkPlan.HouseAct[fPhase2].Act,WorkPlan.HouseAct[fPhase2].TimeToWork);
           //Keep unit idling till next Phase, Idle time is -1 to compensate TaskExecution Phase
           SetActionStay(WorkPlan.HouseAct[fPhase2].TimeToWork-1,ua_Walk);
        end else begin
           fPhase:=SkipWork;
           SetActionLockedStay(0,ua_Walk);
           exit;
        end;
       end;
    9..29: begin //Allow for 20 different "house work" phases
           inc(fPhase2);
           if (fPhase2=2)and(WorkPlan.GatheringScript = gs_HorseBreeder) then BeastID:=TKMHouseSwineStable(fHome).FeedBeasts;
           if WorkPlan.ActCount>=fPhase2 then begin
             fHome.fCurrentAction.SubActionWork(WorkPlan.HouseAct[fPhase2].Act,WorkPlan.HouseAct[fPhase2].TimeToWork);
             SetActionStay(WorkPlan.HouseAct[fPhase2].TimeToWork-1,ua_Walk);
           end else begin
             fPhase:=SkipWork;
             SetActionLockedStay(0,ua_Walk);
             exit;
           end;
       end;
    30: begin
          case WorkPlan.GatheringScript of
            gs_CoalMiner: fTerrain.DecOreDeposit(WorkPlan.Loc,rt_Coal);
            gs_GoldMiner: fTerrain.DecOreDeposit(WorkPlan.Loc,rt_GoldOre);
            gs_IronMiner: fTerrain.DecOreDeposit(WorkPlan.Loc,rt_IronOre);
          end;
          if WorkPlan.GatheringScript = gs_HorseBreeder then begin
            if BeastID<>0 then begin
              TKMHouseSwineStable(fHome).TakeBeast(BeastID);
              fHome.ResAddToOut(WorkPlan.Product1,WorkPlan.ProdCount1);
            end;
          end else
          if WorkPlan.GatheringScript = gs_SwineBreeder then begin
            if BeastID<>0 then begin
              fHome.ResAddToOut(WorkPlan.Product1,WorkPlan.ProdCount1);
              fHome.ResAddToOut(WorkPlan.Product2,WorkPlan.ProdCount2);
            end;
          end else begin
            fHome.ResAddToOut(WorkPlan.Product1,WorkPlan.ProdCount1);
            fHome.ResAddToOut(WorkPlan.Product2,WorkPlan.ProdCount2); //This is unused tbh
          end;

          fHome.SetState(hst_Idle,WorkPlan.AfterWorkIdle);
          SetActionStay(WorkPlan.AfterWorkIdle-1,ua_Walk);
        end;
    else TaskDone:=true;
  end;
inc(fPhase);
if (fUnit.fCurrentAction=nil)and(not TaskDone) then
  fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskMining.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  {SaveStream.Write(WorkPlan,4);} //todo: save reference to workplan? Or just relink it to TKMUnitCitizen.WorkPlan
  SaveStream.Write(BeastID,4);
end;


{ TTaskGoHome }
constructor TTaskGoHome.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoHome;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskGoHome.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if fUnit.fHome.IsDestroyed then begin
    Abandon;
    TaskDone:=true;
    exit;
  end;
  with fUnit do
  case fPhase of
    0: begin
         fThought := th_Home;
         SetActionWalk(fUnit,KMPointY1(fHome.GetEntrance));
       end;
    1: SetActionGoIn(ua_Walk, gd_GoInside, fHome.GetHouseType);
    2: begin
        fThought := th_None; //Only stop thinking once we are right inside
        fHome.SetState(hst_Idle,0);
        SetActionStay(5,ua_Walk);
       end;
    else TaskDone:=true;
  end;
  inc(fPhase);
  if (fUnit.fCurrentAction=nil)and(not TaskDone) then
    fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskGoHome.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  //nothing more here yet
end;


{ TTaskDie }
constructor TTaskDie.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_Die;
  fUnit.SetActionLockedStay(0,ua_Walk);
  SequenceLength := fResource.GetUnitSequenceLength(fUnit.fUnitType,ua_Die,fUnit.Direction);
  if fUnit is TKMUnitAnimal then SequenceLength := 0; //Animals don't have a dying sequence. Can be changed later.
end;


procedure TTaskDie.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
with fUnit do
case fPhase of
  0: if not fVisible then begin
       if fHome<>nil then begin
         fHome.SetState(hst_Idle,0);
         fHome.SetState(hst_Empty,0);
         SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome.GetHouseType);
       end
       else
         SetActionGoIn(ua_Walk,gd_GoOutside); //Inn or Store or etc.. for units without home.
                                         //Which means that our current approach to deduce housetype from
                                         //fUnit.fHome is wrong
     end else
     SetActionLockedStay(0,ua_Walk);
  1: if SequenceLength > 0 then SetActionStay(SequenceLength,ua_Die,false)
     else SetActionLockedStay(0,ua_Walk);
  else begin
      fUnit.CloseUnit;
      exit;
     end;
end;
inc(fPhase);
end;


procedure TTaskDie.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(SequenceLength,4);
end;

{ TTaskGoOutShowHungry }
constructor TTaskGoOutShowHungry.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoOutShowHungry;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


procedure TTaskGoOutShowHungry.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if fUnit.fHome.IsDestroyed then begin
    Abandon;
    TaskDone:=true;
    exit;
  end;
  with fUnit do
  case fPhase of
    0: begin
         fThought := th_Eat;
         SetActionStay(20,ua_Walk);
       end;
    1: begin
         SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome.GetHouseType);
         fHome.SetState(hst_Empty,0);
       end;
    2: SetActionStay(4,ua_Walk);
    3: SetActionGoIn(ua_Walk,gd_GoInside,fUnit.fHome.GetHouseType);
    4: begin
         SetActionStay(20,ua_Walk);
         fHome.SetState(hst_Idle,0);
       end;
    else begin
         fThought := th_None;
         TaskDone := true;
       end;
  end;
  inc(fPhase);
  if (fUnit.fCurrentAction=nil)and(not TaskDone) then
    fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskGoOutShowHungry.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  //nothing more here yet
end;


{ TTaskGoEat }
constructor TTaskGoEat.Create(aInn:TKMHouseInn; aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoEat;
  fInn      := TKMHouseInn(aInn.GetSelf);
  PlaceID   := 0;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;

destructor TTaskGoEat.Destroy;
begin
  if fInn <> nil then fInn.RemovePointer;
  Inherited Destroy;
end;

procedure TTaskGoEat.Execute(out TaskDone:boolean);
begin
TaskDone:=false;

if fInn.IsDestroyed then
begin
  Abandon;
  TaskDone:=true;
  exit;
end;

with fUnit do
case fPhase of
 0: begin
      fThought := th_Eat;
      if fHome<>nil then fHome.SetState(hst_Empty,0);
      if not fVisible then SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome.GetHouseType) else
                           SetActionLockedStay(0,ua_Walk); //Walk outside the house
    end;
 1: begin
      SetActionWalk(fUnit,KMPointY1(fInn.GetEntrance));
    end;
 2: begin
      SetActionGoIn(ua_Walk,gd_GoInside,ht_Inn); //Enter Inn
      PlaceID := fInn.EaterGetsInside(fUnitType);
    end;
 3: //Units are fed acording to this: (from knightsandmerchants.de tips and tricks)
    //Bread    = +40%
    //Sausages = +60%
    //Wine     = +20%
    //Fish     = +50%
    if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Bread)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Bread);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.4);
      fInn.UpdateEater(PlaceID,2); //Order is Wine-Bread-Sausages-Fish
    end else
      SetActionLockedStay(0,ua_Walk);
 4: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Sausages)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Sausages);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.6);
      fInn.UpdateEater(PlaceID,3);
    end else
      SetActionLockedStay(0,ua_Walk);
 5: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Wine)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Wine);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.2);
      fInn.UpdateEater(PlaceID,1);
    end else
      SetActionLockedStay(0,ua_Walk);
 6: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Fish)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Fish);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.5);
      fInn.UpdateEater(PlaceID,4);
    end else
      SetActionLockedStay(0,ua_Walk);
 7: begin
      //Stop showing hungry if we no longer are, but if we are then walk out of the inn thinking hungry so that the player will know that we haven't been fed
      if fCondition<UNIT_MAX_CONDITION then
        fThought := th_Eat
      else fThought := th_None;
      SetActionGoIn(ua_Walk,gd_GoOutside,ht_Inn); //Exit Inn
      fInn.EatersGoesOut(PlaceID);
      PlaceID:=0;
    end;
 else TaskDone:=true;
end;
inc(fPhase);
if (fUnit.fCurrentAction=nil)and(not TaskDone) then
  fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskGoEat.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fInn <> nil then
    SaveStream.Write(fInn.ID, 4) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero, 4);
  SaveStream.Write(PlaceID,4);
end;


{ TUnitAction }
constructor TUnitAction.Create(aActionType: TUnitActionType);
begin
  Inherited Create;
  fActionName := uan_Unknown;
  fActionType := aActionType;
  IsStepDone  := false;
end;


constructor TUnitAction.Load(LoadStream:TKMemoryStream);
begin
  Create(ua_Walk);
  LoadStream.Read(fActionName, SizeOf(fActionName));
  LoadStream.Read(fActionType, SizeOf(fActionType));
  LoadStream.Read(IsStepDone);
end;

procedure TUnitAction.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fActionName, SizeOf(fActionName));
  SaveStream.Write(fActionType, SizeOf(fActionType));
  SaveStream.Write(IsStepDone);
end;


{ TUnitActionAbandonWalk }
constructor TUnitActionAbandonWalk.Create(LocB:TKMPoint; const aActionType:TUnitActionType=ua_Walk);
begin
  fLog.AssertToLog(LocB.X*LocB.Y<>0,'Illegal WalkTo 0;0');
  Inherited Create(aActionType);
  fActionName := uan_AbandonWalk;
  fWalkTo       := KMPoint(LocB.X,LocB.Y);
end;


constructor TUnitActionAbandonWalk.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fWalkTo, 4);
end;


procedure TUnitActionAbandonWalk.Execute(KMUnit: TKMUnit; TimeDelta: single; out DoEnd: Boolean);
const DirectionsBitfield:array[-1..1,-1..1]of TKMDirection = ((dir_NW,dir_W,dir_SW),(dir_N,dir_NA,dir_S),(dir_NE,dir_E,dir_SE));
var
  DX,DY:shortint; WalkX,WalkY,Distance:single;
begin
  DoEnd:= False;

  //Execute the route in series of moves
  TimeDelta:=0.1;
  Distance:= TimeDelta * KMUnit.GetSpeed;

  //Check if unit has arrived on tile
  if Equals(KMUnit.fPosition.X,fWalkTo.X,Distance/2) and Equals(KMUnit.fPosition.Y,fWalkTo.Y,Distance/2) then
  begin
    //Set precise position to avoid rounding errors
    KMUnit.fPosition.X:=fWalkTo.X;
    KMUnit.fPosition.Y:=fWalkTo.Y;
    //We are finished
    DoEnd:=true;
    GetIsStepDone := true;
    exit;
  end;

  WalkX := fWalkTo.X - KMUnit.fPosition.X;
  WalkY := fWalkTo.Y - KMUnit.fPosition.Y;
  DX := sign(WalkX); //-1,0,1
  DY := sign(WalkY); //-1,0,1

  if (DX <> 0) and (DY <> 0) then
    Distance:=Distance / 1.41; {sqrt (2) = 1.41421 }

  KMUnit.fPosition.X:= KMUnit.fPosition.X + DX*min(Distance,abs(WalkX));
  KMUnit.fPosition.Y:= KMUnit.fPosition.Y + DY*min(Distance,abs(WalkY));

  inc(KMUnit.AnimStep);
end;


procedure TUnitActionAbandonWalk.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fWalkTo,4);
end;


{ TKMUnitsCollection }
{ AutoPlace means should we find a spot for this unit or just place it where we are told.
  Used for creating units still inside schools }
function TKMUnitsCollection.Add(aOwner: TPlayerID; aUnitType: TUnitType; PosX, PosY:integer; AutoPlace:boolean=true):TKMUnit;
var U:Integer; P:TKMPoint;
begin
  if AutoPlace then begin
    P:=fPlayers.FindPlaceForUnit(PosX,PosY,aUnitType);
    PosX:=P.X;
    PosY:=P.Y;
  end;

  if not fTerrain.TileInMapCoords(PosX, PosY) then begin
    fLog.AppendLog('Unable to add unit to '+TypeToString(KMPoint(PosX,PosY)));
    Result:=nil;
    exit;
  end;

  U:=-1;
  case aUnitType of
    ut_Serf:    U:= Inherited Add(TKMUnitSerf.Create(aOwner,PosX,PosY,aUnitType));
    ut_Worker:  U:= Inherited Add(TKMUnitWorker.Create(aOwner,PosX,PosY,aUnitType));

    ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                U:= Inherited Add(TKMUnitCitizen.Create(aOwner,PosX,PosY,aUnitType));

    ut_Recruit: U:= Inherited Add(TKMUnitCitizen.Create(aOwner,PosX,PosY,aUnitType));

    ut_Militia..ut_Barbarian:   U:= Inherited Add(TKMUnitWarrior.Create(aOwner,PosX,PosY,aUnitType));
    //ut_Bowman:   Inherited Add(TKMUnitArcher.Create(aOwner,PosX,PosY,aUnitType)); //I guess it will be stand-alone

    ut_Wolf..ut_Duck:           U:= Inherited Add(TKMUnitAnimal.Create(aOwner,PosX,PosY,aUnitType));

    else
    fLog.AssertToLog(false,'Such unit doesn''t exist yet - '+TypeToString(aUnitType));
  end;

  if U=-1 then Result:=nil else Result:=TKMUnit(Items[U]);

end;


function TKMUnitsCollection.AddGroup(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; aDir:TKMDirection; aUnitPerRow, aUnitCount:word):TKMUnit;
const DirAngle:array[TKMDirection]of word =   (0,  0,   45,  90,   135, 180,   225, 270,   315);
const DirRatio:array[TKMDirection]of single = (0,  1, 1.41,   1,  1.41,   1,  1.41,   1,  1.41);
var U,Commander:TKMUnit; i,x,y,px,py:integer;
begin
  //Add commander
  Commander := Add(aOwner, aUnitType, PosX, PosY);
  Result := Commander;

  if Commander=nil then exit;
  fPlayers.Player[byte(aOwner)].CreatedUnit(aUnitType, false);

  Commander.Direction:=aDir;
  //@Krom: This doesn't seem to work all the time, e.g. tutorial the big group of scouts. Any idea why?
  Commander.AnimStep := UnitStillFrames[aDir]; //Use still frame at begining, so units don't all change frame on first tick
  if Commander is TKMUnitWarrior then
    TKMUnitWarrior(Commander).fIsCommander:=true;

  for i:=1 to aUnitCount do begin
    px:=(i-1) mod aUnitPerRow - aUnitPerRow div 2;
    py:=(i-1) div aUnitPerRow;

    x:=round( px*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) - py*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) );
    y:=round( px*DirRatio[aDir]*sin(DirAngle[aDir]/180*pi) + py*DirRatio[aDir]*cos(DirAngle[aDir]/180*pi) );

    if not ((x=0)and(y=0)) then begin//Skip commander
      U:=Add(aOwner, aUnitType, PosX + x, PosY + y);
      if U<>nil then begin
        fPlayers.Player[byte(aOwner)].CreatedUnit(aUnitType, false);
        U.Direction:=aDir; //U will be _nil_ if unit didn't fit on map
        U.AnimStep := UnitStillFrames[aDir]; //Use still frame at begining, so units don't all change frame on first tick
        if Commander is TKMUnitWarrior then
          TKMUnitWarrior(U).fCommander:=Commander;
      end;
    end;
  end;
end;


procedure TKMUnitsCollection.Rem(aUnit:TKMUnit);
begin
  Remove(aUnit);
end;


function TKMUnitsCollection.HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): TKMUnit;
var
  I: Integer;
begin
  Result:= nil;
  for I := 0 to Count - 1 do
    if (TKMUnit(Items[I]).HitTest(X, Y, UT)) and (not TKMUnit(Items[I]).IsDead) then
    begin
      Result:= TKMUnit(Items[I]);
      Break;
    end;
end;


procedure TKMUnitsCollection.GetLocations(aOwner:TPlayerID; out Loc:TKMPointList);
var i:integer;
begin
  Loc.Clearup;
  for I := 0 to Count - 1 do
    if (TKMUnit(Items[I]).fOwner=aOwner)and not(TKMUnit(Items[I]).fUnitType in [ut_Wolf..ut_Duck]) then
      Loc.AddEntry(TKMUnit(Items[I]).GetPosition);
end;


function TKMUnitsCollection.GetTotalPointers: integer;
var i:integer;
begin
  Result:=0;
  for I := 0 to Count - 1 do
    inc(Result, TKMUnit(Items[I]).GetPointerCount);
end;


procedure TKMUnitsCollection.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write('Units', 5);
  SaveStream.Write(Count,4);
  for i := 0 to Count - 1 do
    TKMUnit(Items[i]).Save(SaveStream);
end;


procedure TKMUnitsCollection.Load(LoadStream:TKMemoryStream);
var i,UnitCount:integer; c:array[1..64]of char; UnitType:TUnitType; U:Integer;
begin
  LoadStream.Read(c, 5); //if s <> 'Units' then exit;
  LoadStream.Read(UnitCount);
  for i := 0 to UnitCount - 1 do
  begin
    LoadStream.Read(UnitType, SizeOf(UnitType));
    LoadStream.Seek(-SizeOf(UnitType), soFromCurrent); //rewind
    case UnitType of //Create some placeholder unit
      //todo: ut-dependant unit creation without altering fTerrain!
      ut_Wolf..ut_Duck: inherited Add(TKMUnitAnimal.Load(LoadStream));
    else fLog.AssertToLog(false, 'Uknown unit type in Savegame')
    end;

  end;
end;


procedure TKMUnitsCollection.UpdateState;
var
  I, ID: Integer;
  IDsToDelete: array of integer;
begin
  //if Count>10 then fLog.AddToLog('Tick'); //@Lewin - thats debug string
  ID := 0;
  for I := 0 to Count - 1 do
  if not TKMUnit(Items[I]).IsDead then
    TKMUnit(Items[I]).UpdateState
  else //Else try to destroy the unit object if all pointers are freed
    if (Items[I] <> nil) and FREE_POINTERS and (TKMUnit(Items[I]).GetPointerCount = 0) then
    begin
      TKMUnit(Items[I]).Free; //Because no one needs this anymore it must DIE!!!!! :D
      SetLength(IDsToDelete,ID+1);
      IDsToDelete[ID] := I;
      inc(ID);
    end;
  //Must remove list entry after for loop is complete otherwise the indexes change
  if ID <> 0 then
    for I := ID-1 downto 0 do
    begin
      Delete(IDsToDelete[I]);
      //fLog.AppendLog('Unit sucessfully freed and removed');
    end;

  //   --     POINTER FREEING SYSTEM - DESCRIPTION     --   //
  //  This system was implemented because unit and house objects cannot be freed until all pointers to them
  //  (in tasks, delivery queue, etc.) have been freed, otherwise we have pointer integrity issues.

  //   --     ROUGH OUTLINE     --   //
  // - Units and houses have fPointerCount, which is the number of pointers to them. (e.g. tasks, deliveries)
  //   This is kept up to date by the thing that is using the pointer. On create it uses GetSelf to increase
  //   the pointer count and on destroy it decreases it. (this will be a source of errors and will need to be checked when changing pointers)
  // - When a unit dies, the object is not destroyed. Instead a flag (boolean) is set to say that we want to
  //   destroy but can't because there are still pointers to the unit. From then on every update state it checks
  //   to see if the pointer count is 0 yet. If it is then the unit is destroyed.
  // - For each place that contains a pointer, it should check everytime the pointer is used to see if it has been
  //   destroy. If it has then we free the pointer and reduce the count. (and do any other action nececary due to the unit/house dying)

end;


procedure TKMUnitsCollection.Paint();
var i:integer; x1,x2,y1,y2,Margin:integer;
begin
  if TestViewportClipInset then Margin:=-3 else Margin:=3;
  x1 := fViewport.GetClip.Left - Margin;
  x2 := fViewport.GetClip.Right + Margin;
  y1 := fViewport.GetClip.Top - Margin;
  y2 := fViewport.GetClip.Bottom + Margin;

  for I := 0 to Count - 1 do
  if not TKMUnit(Items[I]).IsDead then
  if (InRange(TKMUnit(Items[I]).fPosition.X,x1,x2) and InRange(TKMUnit(Items[I]).fPosition.Y,y1,y2)) then
    TKMUnit(Items[I]).Paint();
end;


end.
