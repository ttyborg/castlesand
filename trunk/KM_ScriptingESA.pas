unit KM_ScriptingESA;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils,
  KM_CommonClasses, KM_Defaults, KM_Points;


type
  //Two classes exposed to scripting States and Actions

  //All functions can be split into these three categories:
  // - Event, when something has happened (e.g. House was built)
  // - State, describing the state of something (e.g. Houses.Count >= 1)
  // - Action, when we need to perform something (e.g. show a message)

  //How to add new a method exposed to the scripting? Three steps:
  //1. Add method to published section here below
  //2. Add method declaration to Compiler (TKMScripting.ScriptOnUses)
  //3. Add method name to Runtime (TKMScripting.LinkRuntime)
  TKMScriptStates = class
  private
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    function ArmyCount(aPlayer: Byte): Integer;
    function CitizenCount(aPlayer: Byte): Integer;
    function GameTime: Cardinal;
    function PlayerCount: Integer;
    function PlayerDefeated(aPlayer: Byte): Boolean;
    function UnitCount(aPlayer: Byte): Integer;
    function UnitTypeCount(aPlayer, aUnitType: Byte): Integer;
  end;

  TKMScriptActions = class
  private
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    procedure Defeat(aPlayer: Word);
    procedure GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word);
    procedure GiveUnit(aPlayer, aType, X,Y, aDir: Word);
    procedure ShowMsg(aPlayer, aIndex: Word);
    procedure UnlockHouse(aPlayer, aHouseType: Word);
  end;


implementation
uses KM_AI, KM_Houses, KM_Terrain, KM_Game, KM_CommonTypes, KM_PlayersCollection,
  KM_TextLibrary, KM_ResourceUnit, KM_ResourceHouse, KM_Log;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player

{ TKMScriptStates }
procedure TKMScriptStates.LogError(aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  for I := Low(aValues) to High(aValues) do
    Values := Values + IntToStr(aValues[I]) + IfThen(I<>High(aValues), ', ');
  fLog.AddTime('Mistake in script usage' + aFuncName + ': ' + Values);
end;


function TKMScriptStates.ArmyCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetArmyCount
  else
    LogError('States.ArmyCount', [aPlayer]);
end;


function TKMScriptStates.CitizenCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetCitizensCount
  else
    LogError('States.ArmyCount', [aPlayer]);
end;


function TKMScriptStates.GameTime: Cardinal;
begin
  Result := fGame.GameTickCount;
end;


function TKMScriptStates.PlayerCount: Integer;
begin
  Result := fPlayers.Count;
end;


function TKMScriptStates.PlayerDefeated(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := (fPlayers[aPlayer].AI.WonOrLost = wol_Lost)
  else
    LogError('States.PlayerDefeated', [aPlayer]);
end;


function TKMScriptStates.UnitCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetUnitQty(ut_Any)
  else
    LogError('States.UnitCount', [aPlayer]);
end;


function TKMScriptStates.UnitTypeCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetUnitQty(UnitIndexToType[aUnitType])
  else
    LogError('States.UnitTypeCount', [aPlayer]);
end;


{ TKMScriptActions }
procedure TKMScriptActions.LogError(aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  for I := Low(aValues) to High(aValues) do
    Values := Values + IntToStr(aValues[I]) + IfThen(I<>High(aValues), ', ');
  fLog.AddTime('Mistake in script usage' + aFuncName + ': ' + Values);
end;


procedure TKMScriptActions.Defeat(aPlayer: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    fPlayers[aPlayer].AI.Defeat
  else
    LogError('Actions.Defeat', [aPlayer]);
end;


procedure TKMScriptActions.GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  and fTerrain.TileInMapCoords(X,Y)
  and (TKMDirection(aDir+1) in [dir_N..dir_NW]) then
    fPlayers[aPlayer].AddUnitGroup(UnitIndexToType[aType],
                                   KMPoint(X,Y),
                                   TKMDirection(aDir+1),
                                   aColumns,
                                   aCount)
  else
    LogError('Actions.GiveGroup', [aPlayer, aType, X, Y, aDir, aCount, aColumns]);
end;


procedure TKMScriptActions.GiveUnit(aPlayer, aType, X, Y, aDir: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  and fTerrain.TileInMapCoords(X,Y)
  and (TKMDirection(aDir+1) in [dir_N..dir_NW]) then
    fPlayers[aPlayer].AddUnit(UnitIndexToType[aType],
                              KMPoint(X,Y))
    //Direction is ignored for now
  else
    LogError('Actions.GiveUnit', [aPlayer, aType, X, Y, aDir]);
end;


procedure TKMScriptActions.ShowMsg(aPlayer, aIndex: Word);
begin
  //Verify all input parameters
  if aPlayer = MyPlayer.PlayerIndex then
    fGame.ShowMessage(mkText, fTextLibrary.GetMissionString(aIndex), KMPoint(0,0))
  else
    LogError('Actions.ShowMsg', [aPlayer, aIndex]);
end;


procedure TKMScriptActions.UnlockHouse(aPlayer, aHouseType: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    fPlayers[aPlayer].Stats.HouseGranted[HouseIndexToType[aHouseType]] := True
  else
    LogError('Actions.UnlockHouse', [aPlayer, aHouseType]);
end;


end.
