unit KM_Scripting;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils,
  uPSCompiler, uPSRuntime, uPSUtils, uPSDisassembly,
  KM_CommonClasses, KM_Defaults, KM_ScriptingESA, KM_Houses, KM_Units, KM_UnitGroups;

  //Dynamic scripts allow mapmakers to control the mission flow

  //In TSK, there are no enemies and you win when you build the tannery.
  //In TPR, you must defeat the enemies AND build the tannery.

type
  TKMScripting = class
  private
    fScriptCode: AnsiString;
    fByteCode: AnsiString;
    fExec: TPSExec;
    fErrorString: string; //Info about found mistakes

    fStates: TKMScriptStates;
    fActions: TKMScriptActions;
    fIDCache: TKMIDCache;

    function ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
    procedure ScriptOnUseVariable(Sender: TPSPascalCompiler; VarType: TPSVariableType; VarNo: Longint; ProcNo, Position: Cardinal; const PropData: tbtString);
    function ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
    procedure CompileScript;
    procedure LinkRuntime;
  public
    constructor Create;
    destructor Destroy; override;

    property ErrorString: string read fErrorString;
    procedure LoadFromFile(aFileName: string);
    procedure ExportDataToText;

    procedure ProcTick;
    procedure ProcMissionStart;
    procedure ProcHouseBuilt(aHouse: TKMHouse);
    procedure ProcHouseLost(aHouseID: Integer; aFullyBuilt: Boolean);
    procedure ProcHouseDestroyed(aHouseID: Integer; aDestroyerOwner: TPlayerIndex; aFullyBuilt:Boolean);
    procedure ProcUnitTrained(aUnit: TKMUnit);
    procedure ProcUnitLost(aUnitType: TUnitType; aOwner: TPlayerIndex);
    procedure ProcUnitKilled(aUnitType: TUnitType; aOwner, aKillerOwner: TPlayerIndex);
    procedure ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
    procedure ProcPlayerDefeated(aPlayer: TPlayerIndex);
    procedure ProcPlayerVictory(aPlayer: TPlayerIndex);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateState;
  end;


  TKMEvent = procedure of object;
  TKMEvent1I = procedure (aIndex: Integer) of object;
  TKMEvent2I = procedure (aIndex, aParam: Integer) of object;
  TKMEvent3I = procedure (aIndex, aParam, aParam2: Integer) of object;
  TKMEvent2I1B = procedure (aIndex, aParam: Integer; aParam2: Boolean) of object;
  TKMEvent1I1B = procedure (aIndex: Integer; aParam2: Boolean) of object;

var
  fScripting: TKMScripting;


implementation
uses KM_Log, KM_ResourceHouse, KM_ResourceUnit;


{ TKMScripting }
constructor TKMScripting.Create;
begin
  inherited;
  fExec := TPSExec.Create;  // Create an instance of the executer.
  fIDCache := TKMIDCache.Create;
  fStates := TKMScriptStates.Create(fIDCache);
  fActions := TKMScriptActions.Create(fIDCache);
end;


destructor TKMScripting.Destroy;
begin
  FreeAndNil(fStates);
  FreeAndNil(fActions);
  FreeAndNil(fIDCache);
  FreeAndNil(fExec);
  inherited;
end;


procedure TKMScripting.LoadFromFile(aFileName: string);
var
  SL: TStringList;
begin
  fErrorString := '';

  if not FileExists(aFileName) then
  begin
    fLog.AddNoTime(aFileName + ' was not found. It is okay for mission to have no dynamic scripts.');
    Exit;
  end;

  //Read the file line by line and try to add valid events
  SL := TStringList.Create;
  try
    SL.LoadFromFile(aFileName);
    fScriptCode := SL.Text;
    CompileScript;
  finally
    SL.Free;
  end;
end;


//The OnUses callback function is called for each "uses" in the script.
//It's always called with the parameter 'SYSTEM' at the top of the script.
//For example: uses ii1, ii2;
//This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'
function TKMScripting.ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;
begin
  if Name = 'SYSTEM' then
  begin

    //Sender.AddTypeS('THouseType', '(utSerf, utAxeman)');

    //Register classes and methods to the script engine.
    //After that they can be used from within the script.
    with Sender.AddClassN(nil, fStates.ClassName) do
    begin
      RegisterMethod('function ArmyCount(aPlayer: Byte): Integer');
      RegisterMethod('function CitizenCount(aPlayer: Byte): Integer');
      RegisterMethod('function GameTime: Cardinal');
      RegisterMethod('function PeaceTime: Cardinal');
      RegisterMethod('function CheckAlliance(aPlayer1, aPlayer2: Byte): Boolean');
      RegisterMethod('function HouseTypeCount(aPlayer, aHouseType: Byte): Integer');
      RegisterMethod('function PlayerCount: Integer');
      RegisterMethod('function PlayerDefeated(aPlayer: Byte): Boolean');
      RegisterMethod('function PlayerVictorious(aPlayer: Byte): Boolean');
      RegisterMethod('function UnitCount(aPlayer: Byte): Integer');
      RegisterMethod('function UnitTypeCount(aPlayer, aUnitType: Byte): Integer');
      RegisterMethod('function PlayerName(aPlayer: Byte): AnsiString');
      RegisterMethod('function PlayerEnabled(aPlayer: Byte): Boolean');
      RegisterMethod('function HouseAt(aX, aY: Word): Integer');
      RegisterMethod('function HouseDestroyed(aHouseID: Integer): Boolean');
      RegisterMethod('function HouseOwner(aHouseID: Integer): Integer');
      RegisterMethod('function HouseType(aHouseID: Integer): Integer');
      RegisterMethod('function HouseDamage(aHouseID: Integer): Integer');
      RegisterMethod('function KaMRandom: Single');
      RegisterMethod('function KaMRandomI(aMax:Integer): Integer');
      RegisterMethod('function UnitAt(aX, aY: Word): Integer');
      RegisterMethod('function UnitDead(aUnitID: Integer): Boolean');
      RegisterMethod('function UnitOwner(aUnitID: Integer): Integer');
      RegisterMethod('function UnitType(aUnitID: Integer): Integer');
      RegisterMethod('function UnitHunger(aUnitID: Integer): Integer');
      RegisterMethod('function UnitMaxHunger: Integer');
      RegisterMethod('function UnitLowHunger: Integer');
      RegisterMethod('function UnitsGroup(aUnitID: Integer): Integer');
      RegisterMethod('function GroupAt(aX, aY: Word): Integer');
      RegisterMethod('function GroupDead(aGroupID: Integer): Boolean');
      RegisterMethod('function GroupOwner(aGroupID: Integer): Integer');
      RegisterMethod('function GroupMemberCount(aGroupID: Integer): Integer');
      RegisterMethod('function GroupMember(aGroupID, aMemberIndex: Integer): Integer');
      RegisterMethod('function UnitKilledCount(aPlayer, aUnitType: Byte): Integer');
      RegisterMethod('function UnitLostCount(aPlayer, aUnitType: Byte): Integer');
      RegisterMethod('function ResourceProducedCount(aPlayer, aResType: Byte): Integer');
      RegisterMethod('function HouseRepair(aHouseID: Integer): Boolean');
      RegisterMethod('function HouseDeliveryBlocked(aHouseID: Integer): Boolean');
      RegisterMethod('function HouseResourceAmount(aHouseID, aResource: Integer): Integer');
      RegisterMethod('function HouseHasOccupant(aHouseID: Integer): Boolean');
      RegisterMethod('function HousePositionX(aHouseID: Integer): Integer');
      RegisterMethod('function HousePositionY(aHouseID: Integer): Integer');
      RegisterMethod('function UnitPositionX(aHouseID: Integer): Integer');
      RegisterMethod('function UnitPositionY(aHouseID: Integer): Integer');
    end;

    with Sender.AddClassN(nil, fActions.ClassName) do
    begin
      RegisterMethod('procedure Defeat(aPlayer: Word)');
      RegisterMethod('procedure Victory(const aVictors: array of Integer; aTeamVictory: Boolean)');
      RegisterMethod('function GiveGroup(aPlayer, aType, X, Y, aDir, aCount, aColumns: Word): Integer');
      RegisterMethod('function GiveUnit(aPlayer, aType, X,Y, aDir: Word): Integer');
      RegisterMethod('function GiveAnimal(aType, X,Y: Word): Integer');
      RegisterMethod('procedure GiveWares(aPlayer, aType, aCount: Word)');
      RegisterMethod('procedure RevealCircle(aPlayer, X, Y, aRadius: Word)');
      RegisterMethod('procedure ShowMsg(aPlayer, aIndex: Word)');
      RegisterMethod('procedure ShowMsgFormatted(aPlayer, aIndex: Word; const Args: array of const)');
      RegisterMethod('procedure UnlockHouse(aPlayer, aHouseType: Word)');
      RegisterMethod('procedure AddHouseDamage(aHouseID: Integer; aDamage: Word)');
      RegisterMethod('procedure DestroyHouse(aHouseID: Integer)');
      RegisterMethod('procedure GiveWaresToHouse(aHouseID: Integer; aType, aCount: Word)');
      RegisterMethod('procedure SetHouseRepair(aHouseID: Integer; aRepairEnabled: Boolean)');
      RegisterMethod('procedure SetOverlayText(aPlayer, aIndex: Word)');
      RegisterMethod('procedure SetOverlayTextFormatted(aPlayer, aIndex: Word; const Args: array of const)');
      RegisterMethod('procedure SetUnitHunger(aUnitID, aHungerLevel: Integer)');
      RegisterMethod('function SetUnitDirection(aUnitID, aDirection: Integer): Boolean');
      RegisterMethod('procedure KillUnit(aUnitID: Integer)');
      RegisterMethod('procedure GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word)');
      RegisterMethod('procedure GroupOrderAttackHouse(aGroupID, aHouseID: Integer)');
      RegisterMethod('procedure GroupOrderAttackUnit(aGroupID, aUnitID: Integer)');
      RegisterMethod('function AddRoadPlan(aPlayer, X, Y: Word): Boolean');
      RegisterMethod('function AddFieldPlan(aPlayer, X, Y: Word): Boolean');
      RegisterMethod('function AddWinefieldPlan(aPlayer, X, Y: Word): Boolean');
      RegisterMethod('function AddHousePlan(aPlayer, aHouseType, X, Y: Word): Boolean');
      RegisterMethod('procedure SetHouseDeliveryBlocked(aHouseID: Integer; aDeliveryBlocked: Boolean)');
      RegisterMethod('function SchoolAddToQueue(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer');
      RegisterMethod('function BarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer');
      RegisterMethod('procedure GroupOrderFood(aGroupID: Integer)');
      RegisterMethod('procedure GroupOrderStorm(aGroupID: Integer)');
      RegisterMethod('procedure GroupOrderHalt(aGroupID: Integer)');
      RegisterMethod('procedure GroupOrderLink(aGroupID, aDestGroupID: Integer)');
      RegisterMethod('procedure GroupSetFormation(aGroupID: Integer; aNumColumns: Byte)');
      RegisterMethod('procedure SetHouseAllowed(aPlayer, aHouseType: Word; aAllowed: Boolean)');
      RegisterMethod('procedure SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean)');
      RegisterMethod('function GroupOrderSplit(aGroupID: Integer): Integer');
      RegisterMethod('function UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean');
    end;

    //Register objects
    AddImportedClassVariable(Sender, 'States', fStates.ClassName);
    AddImportedClassVariable(Sender, 'Actions', fActions.ClassName);

    Result := True;
  end else
    Result := False;
end;


procedure TKMScripting.ScriptOnUseVariable(Sender: TPSPascalCompiler; VarType: TPSVariableType; VarNo: Integer; ProcNo, Position: Cardinal; const PropData: tbtString);
begin
  //There's no variable type info here
  //GetVarCount is not including this current variable yet either
end;


{ The OnExportCheck callback function is called for each function in the script
  (Also for the main proc, with '!MAIN' as a Proc^.Name). ProcDecl contains the
  result type and parameter types of a function using this format:
  ProcDecl: ResultType + ' ' + Parameter1 + ' ' + Parameter2 + ' '+Parameter3 + .....
  Parameter: ParameterType+TypeName
  ParameterType is @ for a normal parameter and ! for a var parameter.
  A result type of 0 means no result}
function TKMScripting.ScriptOnExportCheck(Sender: TPSPascalCompiler; Proc: TPSInternalProcedure; const ProcDecl: AnsiString): Boolean;
begin
  Result := True;

  //todo: Sender.MakeError reports the wrong line number so the user has no idea what the error is
  //todo: Refactor this so it isn't so long and ugly xD

  //Check if the proc is the proc we want
  if (Proc.Name = 'ONHOUSEDESTROYED') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0, btS32, btS32, btEnum], [pmIn, pmIn, pmIn]) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
  //Check if the proc is the proc we want
  if (Proc.Name = 'ONHOUSELOST') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0, btS32, btEnum], [pmIn, pmIn]) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
  //Check if the proc is the proc we want
  if (Proc.Name = 'ONUNITKILLED') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0, btS32, btS32, btS32], [pmIn, pmIn, pmIn]) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
  if (Proc.Name = 'ONWARRIOREQUIPPED') or (Proc.Name = 'ONUNITLOST') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0, btS32, btS32], [pmIn, pmIn]) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
  if (Proc.Name = 'ONUNITTRAINED') or (Proc.Name = 'ONHOUSEBUILT')
  or (Proc.Name = 'ONPLAYERDEFEATED') or (Proc.Name = 'ONPLAYERVICTORY') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0, btS32], [pmIn]) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
  if (Proc.Name = 'ONMISSIONSTART') or (Proc.Name = 'ONTICK') then
    //Check if the proc has the correct params
    if not ExportCheck(Sender, Proc, [0], []) then
    begin
      //Something is wrong, so cause an error
      Sender.MakeError('', ecTypeMismatch, '');
      Result := False;
      Exit;
    end;
end;


procedure TKMScripting.CompileScript;
var
  I: Integer;
  Compiler: TPSPascalCompiler;
begin
  Compiler := TPSPascalCompiler.Create; // create an instance of the compiler
  try
    Compiler.OnUses := ScriptOnUses; // assign the OnUses event
    Compiler.OnUseVariable := ScriptOnUseVariable;
    Compiler.OnExportCheck := ScriptOnExportCheck; // Assign the onExportCheck event

    Compiler.AllowNoEnd := True; //Scripts only use event handlers now, main section is unused

    if not Compiler.Compile(fScriptCode) then  // Compile the Pascal script into bytecode
    begin
      for I := 0 to Compiler.MsgCount - 1 do
        fErrorString := fErrorString + Compiler.Msg[I].MessageToString + '|';
      Exit;
    end;

    Compiler.GetOutput(fByteCode); // Save the output of the compiler in the string Data.
  finally
    Compiler.Free;
  end;

  LinkRuntime;
end;


//Link the ByteCode with used functions and load it into Executioner
procedure TKMScripting.LinkRuntime;
var
  ClassImp: TPSRuntimeClassImporter;
  I: Integer;
  Allowed: Boolean;
  V: PIFVariant;
begin
  //Create an instance of the runtime class importer
  ClassImp := TPSRuntimeClassImporter.Create;
  try
    //Register classes and their exposed methods to Runtime (must be uppercase)
    with ClassImp.Add(TKMScriptStates) do
    begin
      RegisterMethod(@TKMScriptStates.ArmyCount, 'ARMYCOUNT');
      RegisterMethod(@TKMScriptStates.CitizenCount, 'CITIZENCOUNT');
      RegisterMethod(@TKMScriptStates.GameTime, 'GAMETIME');
      RegisterMethod(@TKMScriptStates.PeaceTime, 'PEACETIME');
      RegisterMethod(@TKMScriptStates.CheckAlliance, 'CHECKALLIANCE');
      RegisterMethod(@TKMScriptStates.HouseTypeCount, 'HOUSETYPECOUNT');
      RegisterMethod(@TKMScriptStates.PlayerCount, 'PLAYERCOUNT');
      RegisterMethod(@TKMScriptStates.PlayerDefeated, 'PLAYERDEFEATED');
      RegisterMethod(@TKMScriptStates.PlayerVictorious, 'PLAYERVICTORIOUS');
      RegisterMethod(@TKMScriptStates.UnitCount, 'UNITCOUNT');
      RegisterMethod(@TKMScriptStates.UnitTypeCount, 'UNITTYPECOUNT');
      RegisterMethod(@TKMScriptStates.PlayerName, 'PLAYERNAME');
      RegisterMethod(@TKMScriptStates.PlayerEnabled, 'PLAYERENABLED');
      RegisterMethod(@TKMScriptStates.HouseAt, 'HOUSEAT');
      RegisterMethod(@TKMScriptStates.HouseOwner, 'HOUSEOWNER');
      RegisterMethod(@TKMScriptStates.HouseDestroyed, 'HOUSEDESTROYED');
      RegisterMethod(@TKMScriptStates.HouseType, 'HOUSETYPE');
      RegisterMethod(@TKMScriptStates.HouseDamage, 'HOUSEDAMAGE');
      RegisterMethod(@TKMScriptStates.KaMRandom, 'KAMRANDOM');
      RegisterMethod(@TKMScriptStates.KaMRandomI, 'KAMRANDOMI');
      RegisterMethod(@TKMScriptStates.UnitAt, 'UNITAT');
      RegisterMethod(@TKMScriptStates.UnitDead, 'UNITDEAD');
      RegisterMethod(@TKMScriptStates.UnitOwner, 'UNITOWNER');
      RegisterMethod(@TKMScriptStates.UnitType, 'UNITTYPE');
      RegisterMethod(@TKMScriptStates.UnitHunger, 'UNITHUNGER');
      RegisterMethod(@TKMScriptStates.UnitMaxHunger, 'UNITMAXHUNGER');
      RegisterMethod(@TKMScriptStates.UnitLowHunger, 'UNITLOWHUNGER');
      RegisterMethod(@TKMScriptStates.UnitsGroup, 'UNITSGROUP');
      RegisterMethod(@TKMScriptStates.GroupAt, 'GROUPAT');
      RegisterMethod(@TKMScriptStates.GroupDead, 'GROUPDEAD');
      RegisterMethod(@TKMScriptStates.GroupOwner, 'GROUPOWNER');
      RegisterMethod(@TKMScriptStates.GroupMemberCount, 'GROUPMEMBERCOUNT');
      RegisterMethod(@TKMScriptStates.GroupMember, 'GROUPMEMBER');
      RegisterMethod(@TKMScriptStates.UnitKilledCount, 'UNITKILLEDCOUNT');
      RegisterMethod(@TKMScriptStates.UnitLostCount, 'UNITLOSTCOUNT');
      RegisterMethod(@TKMScriptStates.ResourceProducedCount, 'RESOURCEPRODUCEDCOUNT');
      RegisterMethod(@TKMScriptStates.HouseRepair, 'HOUSEREPAIR');
      RegisterMethod(@TKMScriptStates.HouseDeliveryBlocked, 'HOUSEDELIVERYBLOCKED');
      RegisterMethod(@TKMScriptStates.HouseResourceAmount, 'HOUSERESOURCEAMOUNT');
      RegisterMethod(@TKMScriptStates.HouseHasOccupant, 'HOUSEHASOCCUPANT');
      RegisterMethod(@TKMScriptStates.HousePositionX, 'HOUSEPOSITIONX');
      RegisterMethod(@TKMScriptStates.HousePositionY, 'HOUSEPOSITIONY');
      RegisterMethod(@TKMScriptStates.UnitPositionX, 'UNITPOSITIONX');
      RegisterMethod(@TKMScriptStates.UnitPositionY, 'UNITPOSITIONY');
    end;

    with ClassImp.Add(TKMScriptActions) do
    begin
      RegisterMethod(@TKMScriptActions.Defeat, 'DEFEAT');
      RegisterMethod(@TKMScriptActions.Victory, 'VICTORY');
      RegisterMethod(@TKMScriptActions.GiveGroup, 'GIVEGROUP');
      RegisterMethod(@TKMScriptActions.GiveUnit, 'GIVEUNIT');
      RegisterMethod(@TKMScriptActions.GiveAnimal, 'GIVEANIMAL');
      RegisterMethod(@TKMScriptActions.GiveWares, 'GIVEWARES');
      RegisterMethod(@TKMScriptActions.RevealCircle, 'REVEALCIRCLE');
      RegisterMethod(@TKMScriptActions.ShowMsg, 'SHOWMSG');
      RegisterMethod(@TKMScriptActions.ShowMsgFormatted, 'SHOWMSGFORMATTED');
      RegisterMethod(@TKMScriptActions.UnlockHouse, 'UNLOCKHOUSE');
      RegisterMethod(@TKMScriptActions.AddHouseDamage, 'ADDHOUSEDAMAGE');
      RegisterMethod(@TKMScriptActions.DestroyHouse, 'DESTROYHOUSE');
      RegisterMethod(@TKMScriptActions.GiveWaresToHouse, 'GIVEWARESTOHOUSE');
      RegisterMethod(@TKMScriptActions.SetHouseRepair, 'SETHOUSEREPAIR');
      RegisterMethod(@TKMScriptActions.SetOverlayText, 'SETOVERLAYTEXT');
      RegisterMethod(@TKMScriptActions.SetOverlayTextFormatted, 'SETOVERLAYTEXTFORMATTED');
      RegisterMethod(@TKMScriptActions.SetUnitHunger, 'SETUNITHUNGER');
      RegisterMethod(@TKMScriptActions.SetUnitDirection, 'SETUNITDIRECTION');
      RegisterMethod(@TKMScriptActions.KillUnit, 'KILLUNIT');
      RegisterMethod(@TKMScriptActions.GroupOrderWalk, 'GROUPORDERWALK');
      RegisterMethod(@TKMScriptActions.GroupOrderAttackHouse, 'GROUPORDERATTACKHOUSE');
      RegisterMethod(@TKMScriptActions.GroupOrderAttackUnit, 'GROUPORDERATTACKUNIT');
      RegisterMethod(@TKMScriptActions.AddRoadPlan, 'ADDROADPLAN');
      RegisterMethod(@TKMScriptActions.AddFieldPlan, 'ADDFIELDPLAN');
      RegisterMethod(@TKMScriptActions.AddWinefieldPlan, 'ADDWINEFIELDPLAN');
      RegisterMethod(@TKMScriptActions.AddHousePlan, 'ADDHOUSEPLAN');
      RegisterMethod(@TKMScriptActions.SetHouseDeliveryBlocked, 'SETHOUSEDELIVERYBLOCKED');
      RegisterMethod(@TKMScriptActions.SchoolAddToQueue, 'SCHOOLADDTOQUEUE');
      RegisterMethod(@TKMScriptActions.BarracksEquip, 'BARRACKSEQUIP');
      RegisterMethod(@TKMScriptActions.GroupOrderFood, 'GROUPORDERFOOD');
      RegisterMethod(@TKMScriptActions.GroupOrderStorm, 'GROUPORDERSTORM');
      RegisterMethod(@TKMScriptActions.GroupOrderHalt, 'GROUPORDERHALT');
      RegisterMethod(@TKMScriptActions.GroupOrderLink, 'GROUPORDERLINK');
      RegisterMethod(@TKMScriptActions.GroupSetFormation, 'GROUPSETFORMATION');
      RegisterMethod(@TKMScriptActions.SetHouseAllowed, 'SETHOUSEALLOWED');
      RegisterMethod(@TKMScriptActions.SetTradeAllowed, 'SETTRADEALLOWED');
      RegisterMethod(@TKMScriptActions.GroupOrderSplit, 'GROUPORDERSPLIT');
      RegisterMethod(@TKMScriptActions.UnitOrderWalk, 'UNITORDERWALK');
    end;

    //Append classes info to Exec
    RegisterClassLibraryRuntime(fExec, ClassImp);

    if not fExec.LoadData(fByteCode) then // Load the data from the Data string.
    begin
      { For some reason the script could not be loaded. This is usually the case when a
        library that has been used at compile time isn't registered at runtime. }
      fErrorString := fErrorString + 'Uknown error in loading bytecode to Exec|';
      Exit;
    end;

    for I := 0 to fExec.GetVarCount - 1 do
    begin
      V := fExec.GetVarNo(I);
      Allowed := (V.FType.BaseType in [btU8, btS32, btSingle])
                 or ((V.FType.BaseType = btStaticArray) and (TPSTypeRec_StaticArray(V.FType).ArrayType.BaseType in [btU8, btS32, btSingle]))
                 or SameText(V.FType.ExportName, 'TKMScriptStates')
                 or SameText(V.FType.ExportName, 'TKMScriptActions');
      if not Allowed then
        fErrorString := fErrorString + 'Unsupported global variable type ' + IntToStr(V.FType.BaseType) + '|';
    end;

    //Link script objects with objects
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('STATES')), fStates);
    SetVariantToClass(fExec.GetVarNo(fExec.GetVar('ACTIONS')), fActions);
  finally
    ClassImp.Free;
  end;
end;


procedure TKMScripting.ProcMissionStart;
var
  TestFunc: TKMEvent;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent(fExec.GetProcAsMethodN('ONMISSIONSTART'));
  if @TestFunc <> nil then
    TestFunc;
end;


procedure TKMScripting.ProcTick;
var
  TestFunc: TKMEvent;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent(fExec.GetProcAsMethodN('ONTICK'));
  if @TestFunc <> nil then
    TestFunc;
end;


procedure TKMScripting.ProcHouseBuilt(aHouse: TKMHouse);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONHOUSEBUILT'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.ID); //Improves cache efficiency since aHouse will probably be accessed soon
    TestFunc(aHouse.ID);
  end;
end;


procedure TKMScripting.ProcHouseLost(aHouseID: Integer; aFullyBuilt: Boolean);
var
  TestFunc: TKMEvent1I1B;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent1I1B(fExec.GetProcAsMethodN('ONHOUSELOST'));
  if @TestFunc <> nil then
    TestFunc(aHouseID, aFullyBuilt);
end;


procedure TKMScripting.ProcHouseDestroyed(aHouseID: Integer; aDestroyerOwner: TPlayerIndex; aFullyBuilt:Boolean);
var
  TestFunc: TKMEvent2I1B;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I1B(fExec.GetProcAsMethodN('ONHOUSEDESTROYED'));
  if @TestFunc <> nil then
    TestFunc(aHouseID, aDestroyerOwner, aFullyBuilt);
end;


procedure TKMScripting.ProcUnitTrained(aUnit: TKMUnit);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONUNITTRAINED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.ID); //Improves cache efficiency since aUnit will probably be accessed soon
    TestFunc(aUnit.ID);
  end;
end;


procedure TKMScripting.ProcUnitLost(aUnitType: TUnitType; aOwner: TPlayerIndex);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONUNITLOST'));
  if @TestFunc <> nil then
    TestFunc(aOwner, UnitTypeToIndex[aUnitType]);
end;


procedure TKMScripting.ProcUnitKilled(aUnitType: TUnitType; aOwner, aKillerOwner: TPlayerIndex);
var
  TestFunc: TKMEvent3I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent3I(fExec.GetProcAsMethodN('ONUNITKILLED'));
  if @TestFunc <> nil then
    TestFunc(aOwner, aKillerOwner, UnitTypeToIndex[aUnitType]);
end;


procedure TKMScripting.ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONWARRIOREQUIPPED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.ID); //Improves cache efficiency since aUnit will probably be accessed soon
    fIDCache.CacheGroup(aGroup, aGroup.ID);
    TestFunc(aUnit.ID, aGroup.ID);
  end;
end;


procedure TKMScripting.ProcPlayerDefeated(aPlayer: TPlayerIndex);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONPLAYERDEFEATED'));
  if @TestFunc <> nil then
    TestFunc(aPlayer);
end;


procedure TKMScripting.ProcPlayerVictory(aPlayer: TPlayerIndex);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONPLAYERVICTORY'));
  if @TestFunc <> nil then
    TestFunc(aPlayer);
end;


procedure TKMScripting.ExportDataToText;
var
  s: string;
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    IFPS3DataToText(fByteCode, s);
    SL.Text := s;
    ForceDirectories(ExeDir  + 'Export\');
    SL.SaveToFile(ExeDir  + 'Export\script_DataText.txt');
  finally
    SL.Free;
  end;
end;


procedure TKMScripting.Load(LoadStream: TKMemoryStream);
var
  I,K: Integer;
  V: PIFVariant;
  ArrayCount: Integer;
  ArrayType: TPSTypeRec;
  ArrayVar: TPSVariantIFC;
  TmpInt: Integer;
  TmpSingle: Single;
begin
  LoadStream.ReadAssert('Script');

  LoadStream.Read(fScriptCode);

  if fScriptCode <> '' then
    CompileScript;

  //Read script variables
  LoadStream.Read(I);
  Assert(I = fExec.GetVarCount, 'Script variable count mismatches saved variables count');
  for I := 0 to fExec.GetVarCount - 1 do
  begin
    //todo: So far we blindly assume that vars order is exactly the same
    V := fExec.GetVarNo(I);
    case V.FType.BaseType of
      btU8, btS32:  begin
                      LoadStream.Read(TmpInt);
                      VSetInt(V, TmpInt);
                    end;
      btSingle:     begin
                      LoadStream.Read(TmpSingle);
                      VSetReal(V, TmpSingle);
                    end;
      btStaticArray:begin
                      //See uPSRuntime line 1630 for algo idea
                      LoadStream.Read(ArrayCount);
                      Assert(ArrayCount = TPSTypeRec_StaticArray(V.FType).Size, 'Elements in array mismatch');

                      ArrayType := TPSTypeRec_StaticArray(V.FType).ArrayType; //Type of elements of array

                      case ArrayType.BaseType of
                        btU8, btS32:  for K := 0 to ArrayCount - 1 do
                                      begin
                                        ArrayVar := PSGetArrayField(NewTPSVariantIFC(V, False), K);
                                        LoadStream.Read(TmpInt);  //Byte, Boolean, Integer
                                        VNSetInt(ArrayVar, TmpInt);
                                      end;
                        btSingle:     for K := 0 to ArrayCount - 1 do
                                      begin
                                        ArrayVar := PSGetArrayField(NewTPSVariantIFC(V, False), K);
                                        LoadStream.Read(TmpSingle);  //Byte, Boolean, Integer
                                        VNSetReal(ArrayVar, TmpSingle);
                                      end;
                        else Assert(False);
                      end;
                    end;
    end;
  end;
end;


procedure TKMScripting.Save(SaveStream: TKMemoryStream);
var
  I,K: Integer;
  V: PIFVariant;
  ArrayCount: Integer;
  ArrayType: TPSTypeRec;
  ArrayVar: TPSVariantIFC;
  TmpInt: Integer;
  TmpSingle: Single;
begin
  SaveStream.Write('Script');

  //Write script code
  SaveStream.Write(fScriptCode);

  //Write script variables
  SaveStream.Write(fExec.GetVarCount);
  for I := 0 to fExec.GetVarCount - 1 do
  begin
    V := fExec.GetVarNo(I);
    case V.FType.BaseType of
      btU8, btS32:  SaveStream.Write(Integer(VGetInt(V)));   //Byte, Boolean, Integer
      btSingle:     begin                                    //Single
                      TmpSingle := VGetReal(V);
                      SaveStream.Write(TmpSingle);
                    end;
      btStaticArray:begin
                      //See uPSRuntime line 1630 for algo idea
                      ArrayCount := TPSTypeRec_StaticArray(V.FType).Size; //Elements in array
                      SaveStream.Write(ArrayCount);

                      ArrayType := TPSTypeRec_StaticArray(V.FType).ArrayType; //Type of elements of array

                      case ArrayType.BaseType of
                        btU8, btS32:  for K := 0 to ArrayCount - 1 do
                                      begin
                                        ArrayVar := PSGetArrayField(NewTPSVariantIFC(V, False), K);
                                        TmpInt := Integer(VNGetInt(ArrayVar));
                                        SaveStream.Write(TmpInt);  //Byte, Boolean, Integer
                                      end;
                        btSingle:     for K := 0 to ArrayCount - 1 do
                                      begin
                                        ArrayVar := PSGetArrayField(NewTPSVariantIFC(V, False), K);
                                        TmpSingle := VNGetReal(ArrayVar);
                                        SaveStream.Write(TmpSingle);  //Byte, Boolean, Integer
                                      end;
                        else Assert(False);
                      end;
                    end;
    end;
  end;
end;


procedure TKMScripting.UpdateState;
begin
  ProcTick;
  fIDCache.UpdateState;
end;


end.
