unit KM_MissionScript_Standard;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, SysUtils, Math,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_MissionScript,
  KM_AIAttacks, KM_Houses, KM_Units, KM_Terrain, KM_UnitGroups, KM_Units_Warrior;


type
  TKMCommandParamType = (cpt_Unknown=0,cpt_Recruits,cpt_Constructors,cpt_WorkerFactor,cpt_RecruitCount,cpt_TownDefence,
                         cpt_MaxSoldier,cpt_EquipRate,cpt_EquipRateIron,cpt_EquipRateLeather,cpt_AttackFactor,cpt_TroopParam);

  TAIAttackParamType = (cpt_Type, cpt_TotalAmount, cpt_Counter, cpt_Range, cpt_TroopAmount, cpt_Target, cpt_Position, cpt_TakeAll);

  TKMAttackPosition = record
    Group: TKMUnitGroup;
    Target: TKMPoint;
  end;

  TMissionParserStandard = class(TMissionParserCommon)
  private
    fParsingMode: TMissionParsingMode; //Data gets sent to Game differently depending on Game/Editor mode
    fPlayerEnabled: TPlayerEnabledArray;
    fLastHouse: TKMHouse;
    fLastTroop: TKMUnitGroup;
    fAIAttack: TAIAttack;
    fAttackPositions: array of TKMAttackPosition;
    fAttackPositionsCount: Integer;
    procedure ProcessAttackPositions;
  protected
    function ProcessCommand(CommandType: TKMCommandType; P: array of Integer; TextParam: AnsiString = ''): Boolean; override;
  public
    constructor Create(aMode: TMissionParsingMode; aStrictParsing: Boolean); overload;
    constructor Create(aMode: TMissionParsingMode; aPlayersEnabled: TPlayerEnabledArray; aStrictParsing: Boolean); overload;
    function LoadMission(const aFileName: string): Boolean; overload; override;

    procedure SaveDATFile(const aFileName: string);
  end;


implementation
uses KM_PlayersCollection, KM_Player, KM_AI, KM_AIDefensePos, KM_TerrainPainter,
  KM_Resource, KM_ResourceHouse, KM_ResourceUnit, KM_ResourceResource, KM_Game;


const
  PARAMVALUES: array [TKMCommandParamType] of AnsiString = (
    '', 'RECRUTS', 'CONSTRUCTORS', 'WORKER_FACTOR', 'RECRUT_COUNT', 'TOWN_DEFENSE',
    'MAX_SOLDIER', 'EQUIP_RATE', 'EQUIP_RATE_IRON', 'EQUIP_RATE_LEATHER', 'ATTACK_FACTOR', 'TROUP_PARAM');

  AI_ATTACK_PARAMS: array [TAIAttackParamType] of AnsiString = (
    'TYPE', 'TOTAL_AMOUNT', 'COUNTER', 'RANGE', 'TROUP_AMOUNT', 'TARGET', 'POSITION', 'TAKEALL');


{ TMissionParserStandard }
//Mode affect how certain parameters are loaded a bit differently
constructor TMissionParserStandard.Create(aMode: TMissionParsingMode; aStrictParsing: boolean);
var I: Integer;
begin
  inherited Create(aStrictParsing);
  fParsingMode := aMode;

  for I := 0 to High(fPlayerEnabled) do
    fPlayerEnabled[I] := True;
end;


constructor TMissionParserStandard.Create(aMode: TMissionParsingMode; aPlayersEnabled: TPlayerEnabledArray; aStrictParsing: Boolean);
begin
  inherited Create(aStrictParsing);
  fParsingMode := aMode;

  //Tells us which player should be enabled and which ignored/skipped
  fPlayerEnabled := aPlayersEnabled;
end;


function TMissionParserStandard.LoadMission(const aFileName: string): Boolean;
var
  FileText: AnsiString;
begin
  inherited LoadMission(aFileName);

  Assert((fTerrain <> nil) and (fPlayers <> nil));

  Result := False;

  //Load the terrain since we know where it is beforehand
  if FileExists(ChangeFileExt(fMissionFileName, '.map')) then
  begin
    fTerrain.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'), fParsingMode = mpm_Editor);
    if fParsingMode = mpm_Editor then
      fTerrainPainter.LoadFromFile(ChangeFileExt(fMissionFileName, '.map'));
  end
  else
  begin
    //Else abort loading and fail
    AddError('Map file couldn''t be found', True);
    Exit;
  end;

  //Read the mission file into FileText
  FileText := ReadMissionFile(aFileName);
  if FileText = '' then
    Exit;

  if not TokenizeScript(FileText, 6, []) then
    Exit;

  //Post-processing of ct_Attack_Position commands which must be done after mission has been loaded
  ProcessAttackPositions;

  //If we have reach here without exiting then loading was successful if no errors were reported
  Result := (fFatalErrors = '');
end;


function TMissionParserStandard.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; TextParam: AnsiString = ''): Boolean;
var
  I: Integer;
  Qty: Integer;
  H: TKMHouse;
  HT: THouseType;
  iPlayerAI: TKMPlayerAI;
begin
  Result := False; //Set it right from the start. There are several Exit points below

  case CommandType of
    ct_SetMap:          begin
                          //Check for KaM format map path (disused, as Remake maps are always next to DAT script)
                          {MapFileName := RemoveQuotes(String(TextParam));
                          if FileExists(ExeDir + MapFileName) then
                          begin
                            fTerrain.LoadFromFile(ExeDir+MapFileName, fParsingMode = mpm_Editor)
                            if fParsingMode = mpm_Editor then
                              fTerrainPainter.LoadFromFile(ExeDir+MapFileName);
                          end}
                        end;
    ct_SetMaxPlayer:    begin
                          fPlayers.AddPlayers(P[0]);
                          //Set players to enabled/disabled
                          for I := 0 to fPlayers.Count - 1 do
                            fPlayers[i].Enabled := fPlayerEnabled[i];
                        end;
    ct_SetTactic:       begin
                          //Default is mm_Normal
                          fGame.MissionMode := mm_Tactic;
                        end;
    ct_SetCurrPlayer:   if InRange(P[0], 0, MAX_PLAYERS - 1) then
                        begin
                          if fPlayerEnabled[P[0]] then
                            fLastPlayer := P[0]
                          else
                            fLastPlayer := -1; //Lets us skip this player
                          fLastHouse := nil;
                          fLastTroop := nil;
                        end;
    ct_HumanPlayer:     //We use this command in a sense "Default human player"
                        //MP and SP set human players themselves
                        //Remains usefull for map preview and MapEd
                        if (fParsingMode = mpm_Editor) and (fPlayers <> nil) then
                        begin
                          fGame.MapEditor.DefaultHuman := P[0];
                          fGame.MapEditor.PlayerHuman[P[0]] := True;
                        end;
    ct_UserPlayer:      //New command added by KMR - mark player as allowed to be human
                        //MP and SP set human players themselves
                        //Remains usefull for map preview and MapEd
                        if (fParsingMode = mpm_Editor) and (fPlayers <> nil) then
                          if InRange(P[0], 0, fPlayers.Count - 1) then
                            fGame.MapEditor.PlayerHuman[P[0]] := True
                          else
                            fGame.MapEditor.PlayerHuman[fLastPlayer] := True;
    ct_AIPlayer:        //New command added by KMR - mark player as allowed to be human
                        //MP and SP set human players themselves
                        //Remains usefull for map preview and MapEd
                        if (fParsingMode = mpm_Editor) and (fPlayers <> nil) then
                          if InRange(P[0], 0, fPlayers.Count - 1) then
                            fGame.MapEditor.PlayerAI[P[0]] := True
                          else
                            fGame.MapEditor.PlayerAI[fLastPlayer] := True;
    ct_CenterScreen:    if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].CenterScreen := KMPoint(P[0]+1, P[1]+1);
    ct_ClearUp:         if fLastPlayer >= 0 then
                        begin
                          if fParsingMode = mpm_Editor then
                            if P[0] = 255 then
                              fGame.MapEditor.RevealAll[fLastPlayer] := True
                            else
                              fGame.MapEditor.Revealers[fLastPlayer].AddEntry(KMPoint(P[0]+1,P[1]+1), P[2])
                          else
                            if P[0] = 255 then
                              fPlayers[fLastPlayer].FogOfWar.RevealEverything
                            else
                              fPlayers[fLastPlayer].FogOfWar.RevealCircle(KMPoint(P[0]+1,P[1]+1), P[2], 255);
                        end;
    ct_SetHouse:        if fLastPlayer >= 0 then
                          if InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            if fTerrain.CanPlaceHouseFromScript(HouseIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1)) then
                              fLastHouse := fPlayers[fLastPlayer].AddHouse(
                                HouseIndexToType[P[0]], P[1]+1, P[2]+1, false)
                            else
                              AddError('ct_SetHouse failed, can not place house at ' + TypeToString(KMPoint(P[1]+1, P[2]+1)));
    ct_SetHouseDamage:  if fLastPlayer >= 0 then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                            fLastHouse.AddDamage(-1, min(P[0],high(word)), fParsingMode = mpm_Editor)
                          else
                            AddError('ct_SetHouseDamage without prior declaration of House');
    ct_SetUnit:         begin
                          //Animals should be added regardless of current player
                          if UnitOldIndexToType[P[0]] in [ANIMAL_MIN..ANIMAL_MAX] then
                            fPlayers.PlayerAnimals.AddUnit(UnitOldIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1))
                          else
                          if (fLastPlayer >= 0) and (UnitOldIndexToType[P[0]] in [HUMANS_MIN..HUMANS_MAX]) then
                            fPlayers[fLastPlayer].AddUnit(UnitOldIndexToType[P[0]], KMPoint(P[1]+1, P[2]+1));
                        end;

    ct_SetUnitByStock:  if fLastPlayer >= 0 then
                          if UnitOldIndexToType[P[0]] in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            H := fPlayers[fLastPlayer].FindHouse(ht_Store, 1);
                            if H <> nil then
                              fPlayers[fLastPlayer].AddUnit(UnitOldIndexToType[P[0]], KMPoint(H.GetEntrance.X, H.GetEntrance.Y+1));
                          end;
    ct_SetRoad:         if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]+1,P[1]+1));
    ct_SetField:        if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddField(KMPoint(P[0]+1,P[1]+1),ft_Corn);
    ct_SetWinefield:    if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddField(KMPoint(P[0]+1,P[1]+1),ft_Wine);
    ct_SetStock:        if fLastPlayer >= 0 then
                        begin //This command basically means: Put a SH here with road bellow it
                          fLastHouse := fPlayers[fLastPlayer].AddHouse(ht_Store, P[0]+1,P[1]+1, false);
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]+1,P[1]+2));
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0],P[1]+2));
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]-1,P[1]+2));
                        end;
    ct_AddWare:         if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          H := fPlayers[fLastPlayer].FindHouse(ht_Store,1);
                          if (H <> nil) and H.ResCanAddToIn(ResourceIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(ResourceIndexToType[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceIndexToType[P[0]], Qty);
                          end;

                        end;
    ct_AddWareToAll:    begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          for i:=0 to fPlayers.Count-1 do
                          begin
                            H := fPlayers[i].FindHouse(ht_Store, 1);
                            if (H <> nil) and H.ResCanAddToIn(ResourceIndexToType[P[0]]) then
                            begin
                              H.ResAddToIn(ResourceIndexToType[P[0]], Qty, True);
                              fPlayers[i].Stats.GoodInitial(ResourceIndexToType[P[0]], Qty);
                            end;
                          end;
                        end;
    ct_AddWareToSecond: if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := TKMHouseStore(fPlayers[fLastPlayer].FindHouse(ht_Store, 2));
                          if (H <> nil) and H.ResCanAddToIn(ResourceIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(ResourceIndexToType[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceIndexToType[P[0]], Qty);
                          end;
                        end;
    //Depreciated by ct_AddWareToLast, but we keep it for backwards compatibility in loading
    ct_AddWareTo:       if fLastPlayer >= 0 then
                        begin //HouseType, House Order, Ware Type, Count
                          Qty := EnsureRange(P[3], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := fPlayers[fLastPlayer].FindHouse(HouseIndexToType[P[0]], P[1]);
                          if (H <> nil) and H.ResCanAddToIn(ResourceIndexToType[P[2]]) then
                          begin
                            H.ResAddToIn(ResourceIndexToType[P[2]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceIndexToType[P[2]], Qty);
                          end;
                        end;
    ct_AddWareToLast:   if fLastPlayer >= 0 then
                        begin //Ware Type, Count
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          if (fLastHouse <> nil) and fLastHouse.ResCanAddToIn(ResourceIndexToType[P[0]]) then
                          begin
                            fLastHouse.ResAddToIn(ResourceIndexToType[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceIndexToType[P[0]], Qty);
                          end
                          else
                            AddError('ct_AddWareToLast without prior declaration of House');
                        end;
    ct_AddWeapon:       if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum weapons
                          H := TKMHouseBarracks(fPlayers[fLastPlayer].FindHouse(ht_Barracks, 1));
                          if (H <> nil) and H.ResCanAddToIn(ResourceIndexToType[P[0]]) then
                          begin
                            H.ResAddToIn(ResourceIndexToType[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceIndexToType[P[0]], Qty);
                          end;
                        end;
    ct_BlockTrade:      if fLastPlayer >= 0 then
                        begin
                          if ResourceIndexToType[P[0]] in [WARE_MIN..WARE_MAX] then
                            fPlayers[fLastPlayer].Stats.AllowToTrade[ResourceIndexToType[P[0]]] := false;
                        end;
    ct_BlockHouse:      if fLastPlayer >= 0 then
                        begin
                          if InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            fPlayers[fLastPlayer].Stats.HouseBlocked[HouseIndexToType[P[0]]] := True;
                        end;
    ct_ReleaseHouse:    if fLastPlayer >= 0 then
                        begin
                          if InRange(P[0], Low(HouseIndexToType), High(HouseIndexToType)) then
                            fPlayers[fLastPlayer].Stats.HouseGranted[HouseIndexToType[P[0]]] := True;
                        end;
    ct_ReleaseAllHouses:if fLastPlayer >= 0 then
                          for HT := HOUSE_MIN to HOUSE_MAX do
                            fPlayers[fLastPlayer].Stats.HouseGranted[HT] := True;
    ct_SetGroup:        if fLastPlayer >= 0 then
                          if InRange(P[0], Low(UnitIndexToType), High(UnitIndexToType)) and (UnitIndexToType[P[0]] <> ut_None) then
                            fLastTroop := fPlayers[fLastPlayer].AddUnitGroup(
                              UnitIndexToType[P[0]],
                              KMPoint(P[1]+1, P[2]+1),
                              TKMDirection(P[3]+1),
                              P[4],
                              P[5]
                              );
    ct_SendGroup:       if fLastPlayer >= 0 then
                        begin
                          if fLastTroop <> nil then
                            if fParsingMode = mpm_Editor then
                            begin
                              fLastTroop.MapEdOrder.Order := ioSendGroup;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1));
                            end
                            else
                              fLastTroop.OrderWalk(KMPoint(P[0]+1, P[1]+1), True, TKMDirection(P[2]+1))
                          else
                            AddError('ct_SendGroup without prior declaration of Troop');
                        end;
    ct_SetGroupFood:    if fLastPlayer >= 0 then
                        begin
                          if fLastTroop <> nil then
                            fLastTroop.Condition := UNIT_MAX_CONDITION
                          else
                            AddError('ct_SetGroupFood without prior declaration of Troop');
                        end;
    ct_AICharacter:     if fLastPlayer >= 0 then
                        begin
                          if fPlayers[fLastPlayer].PlayerType <> pt_Computer then Exit;
                          iPlayerAI := fPlayers[fLastPlayer].AI; //Setup the AI's character
                          if TextParam = PARAMVALUES[cpt_Recruits]     then iPlayerAI.Setup.RecruitFactor := P[1];
                          if TextParam = PARAMVALUES[cpt_Constructors] then iPlayerAI.Setup.WorkerFactor  := P[1];
                          if TextParam = PARAMVALUES[cpt_WorkerFactor] then iPlayerAI.Setup.SerfFactor    := P[1];
                          if TextParam = PARAMVALUES[cpt_RecruitCount] then iPlayerAI.Setup.RecruitDelay  := P[1];
                          if TextParam = PARAMVALUES[cpt_TownDefence]  then iPlayerAI.Setup.TownDefence   := P[1];
                          if TextParam = PARAMVALUES[cpt_MaxSoldier]   then iPlayerAI.Setup.MaxSoldiers   := P[1];
                          if TextParam = PARAMVALUES[cpt_EquipRate]    then //Now depreciated, kept for backwards compatibility
                          begin
                            iPlayerAI.Setup.EquipRateLeather := P[1];
                            iPlayerAI.Setup.EquipRateIron    := P[1]; //Both the same for now, could be separate commands later
                          end;
                          if TextParam = PARAMVALUES[cpt_EquipRateLeather] then iPlayerAI.Setup.EquipRateLeather := P[1];
                          if TextParam = PARAMVALUES[cpt_EquipRateIron]    then iPlayerAI.Setup.EquipRateIron    := P[1];
                          if TextParam = PARAMVALUES[cpt_AttackFactor]     then iPlayerAI.Setup.Aggressiveness   := P[1];
                          if TextParam = PARAMVALUES[cpt_TroopParam]   then
                          begin
                            iPlayerAI.General.DefencePositions.TroopFormations[TGroupType(P[1])].NumUnits := P[2];
                            iPlayerAI.General.DefencePositions.TroopFormations[TGroupType(P[1])].UnitsPerRow  := P[3];
                          end;
                        end;
    ct_AINoBuild:       if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Setup.AutoBuild := False;
    ct_AIAutoRepair:    if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Mayor.AutoRepair := True;
    ct_AIAutoDefend:    if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Setup.AutoDefend := True;
    ct_AIStartPosition: if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Setup.StartPosition := KMPoint(P[0]+1,P[1]+1);
    ct_SetAlliance:     if (fLastPlayer >= 0) and fPlayerEnabled[P[0]] then
                          if P[1] = 1 then
                            fPlayers[fLastPlayer].Alliances[P[0]] := at_Ally
                          else
                            fPlayers[fLastPlayer].Alliances[P[0]] := at_Enemy;
    ct_AttackPosition:  if fLastPlayer >= 0 then
                          //If target is building: Attack building
                          //If target is unit: Chase/attack unit
                          //If target is nothing: move to position
                          //However, because the unit/house target may not have been created yet, this must be processed after everything else
                          if fLastTroop <> nil then
                            if fParsingMode = mpm_Editor then
                            begin
                              fLastTroop.MapEdOrder.Order := ioAttackPosition;
                              fLastTroop.MapEdOrder.Pos := KMPointDir(P[0]+1, P[1]+1, dir_NA);
                            end
                            else
                            begin
                              Inc(fAttackPositionsCount);
                              SetLength(fAttackPositions, fAttackPositionsCount+1);
                              fAttackPositions[fAttackPositionsCount-1].Group := fLastTroop;
                              fAttackPositions[fAttackPositionsCount-1].Target := KMPoint(P[0]+1,P[1]+1);
                            end
                          else
                            AddError('ct_AttackPosition without prior declaration of Troop');
    ct_AddGoal:         if fLastPlayer < 0 then
                          AddError('Add_Goal for non existing player')
                        else
                        if not InRange(P[0], 0, Byte(High(TGoalCondition))) then
                          AddError('Add_Goal with unknown condition index ' + IntToStr(P[0]))
                        else
                        if InRange(P[3], 0, fPlayers.Count - 1)
                        and fPlayerEnabled[P[3]] then
                        begin
                          if not (TGoalCondition(P[0]) in GoalsSupported) then
                            AddError('Goal type ' + GoalConditionStr[TGoalCondition(P[0])] + ' is deprecated');
                          if (P[2] <> 0) then
                            AddError('Goals messages are deprecated. Use .script instead');
                          fPlayers[fLastPlayer].Goals.AddGoal(glt_Victory, TGoalCondition(P[0]), TGoalStatus(P[1]), 0, P[2], P[3]);
                        end;
    ct_AddLostGoal:     if fLastPlayer < 0 then
                          AddError('Add_LostGoal for non existing player')
                        else
                        if not InRange(P[0], 0, Byte(High(TGoalCondition))) then
                          AddError('Add_LostGoal with unknown condition index ' + IntToStr(P[0]))
                        else
                        if InRange(P[3], 0, fPlayers.Count - 1)
                        and fPlayerEnabled[P[3]] then
                        begin
                          if not (TGoalCondition(P[0]) in GoalsSupported) then
                            AddError('LostGoal type ' + GoalConditionStr[TGoalCondition(P[0])] + ' is deprecated');
                          if (P[2] <> 0) then
                            AddError('LostGoals messages are deprecated. Use .script instead');
                          fPlayers[fLastPlayer].Goals.AddGoal(glt_Survive, TGoalCondition(P[0]), TGoalStatus(P[1]), 0, P[2], P[3]);
                        end;
    ct_AIDefence:       if fLastPlayer >=0 then
                        if InRange(P[3], Integer(Low(TGroupType)), Integer(High(TGroupType))) then //TPR 3 tries to set TGroupType 240 due to a missing space
                          fPlayers[fLastPlayer].AI.General.DefencePositions.Add(KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1)),TGroupType(P[3]),P[4],TAIDefencePosType(P[5]));
    ct_SetMapColor:     if fLastPlayer >=0 then
                          //For now simply use the minimap color for all color, it is too hard to load all 8 shades from ct_SetNewRemap
                          fPlayers[fLastPlayer].FlagColor := fResource.Palettes.DefDal.Color32(P[0]);
    ct_AIAttack:        begin
                          //Set up the attack command
                          if TextParam = AI_ATTACK_PARAMS[cpt_Type] then
                            if InRange(P[1], Low(RemakeAttackType), High(RemakeAttackType)) then
                              fAIAttack.AttackType := RemakeAttackType[P[1]]
                            else
                              AddError('Unknown parameter ' + IntToStr(P[1]) + ' at ct_AIAttack');
                          if TextParam = AI_ATTACK_PARAMS[cpt_TotalAmount] then
                            fAIAttack.TotalMen := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Counter] then
                            fAIAttack.Delay := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Range] then
                            fAIAttack.Range := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_TroopAmount] then
                            fAIAttack.GroupAmounts[TGroupType(P[1])] := P[2];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Target] then
                            fAIAttack.Target := TAIAttackTarget(P[1]);
                          if TextParam = AI_ATTACK_PARAMS[cpt_Position] then
                            fAIAttack.CustomPosition := KMPoint(P[1]+1,P[2]+1);
                          if TextParam = AI_ATTACK_PARAMS[cpt_TakeAll] then
                            fAIAttack.TakeAll := True;
                        end;
    ct_CopyAIAttack:    begin
                          if fLastPlayer >= 0 then
                            //Save the attack to the AI assets
                            fPlayers[fLastPlayer].AI.General.Attacks.AddAttack(fAIAttack);

                          //Reset values before next Attack processing
                          FillChar(fAIAttack, SizeOf(fAIAttack), #0);
                        end;

    ct_EnablePlayer:    begin
                          //Serves no real purpose, all players have this command anyway
                        end;
    ct_SetNewRemap:     begin
                          //Disused. Minimap color is used for all colors now. However it might be better to use these values in the long run as sometimes the minimap colors do not match well
                        end;
  end;
  Result := true; //Must have worked if we haven't exited by now
end;


//Determine what we are attacking: House, Unit or just walking to some place
procedure TMissionParserStandard.ProcessAttackPositions;
var
  I: Integer;
  H: TKMHouse;
  U: TKMUnit;
begin
  Assert((fParsingMode <> mpm_Editor) or (fAttackPositionsCount = 0), 'AttackPositions should be handled by MapEd');

  for I := 0 to fAttackPositionsCount - 1 do
    with fAttackPositions[I] do
    begin
      H := fPlayers.HousesHitTest(Target.X, Target.Y); //Attack house
      if (H <> nil) and (not H.IsDestroyed) and (fPlayers.CheckAlliance(Group.Owner, H.Owner) = at_Enemy) then
        Group.OrderAttackHouse(H, True)
      else
      begin
        U := fTerrain.UnitsHitTest(Target.X, Target.Y); //Chase/attack unit
        if (U <> nil) and (not U.IsDeadOrDying) and (fPlayers.CheckAlliance(Group.Owner, U.Owner) = at_Enemy) then
          Group.OrderAttackUnit(U, True)
        else
          Group.OrderWalk(Target, True); //Just move to position
      end;
    end;
end;


//Write out a KaM format mission file to aFileName
procedure TMissionParserStandard.SaveDATFile(const aFileName: string);
const
  COMMANDLAYERS = 4;
var
  f: textfile;
  I: longint; //longint because it is used for encoding entire output, which will limit the file size
  K,iX,iY,CommandLayerCount: Integer;
  StoreCount, BarracksCount: Integer;
  Res: TResourceType;
  G: TGroupType;
  U: TKMUnit;
  H: TKMHouse;
  Group: TKMUnitGroup;
  HT: THouseType;
  ReleaseAllHouses: Boolean;
  SaveString: AnsiString;

  procedure AddData(aText: AnsiString);
  begin
    if CommandLayerCount = -1 then //No layering
      SaveString := SaveString + aText + eol //Add to the string normally
    else
    begin
      case (CommandLayerCount mod COMMANDLAYERS) of
        0:   SaveString := SaveString + eol + aText //Put a line break every 4 commands
        else SaveString := SaveString + ' ' + aText; //Just put spaces so commands "layer"
      end;
      inc(CommandLayerCount);
    end
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TKMCommandParamType; aParams: array of Integer); overload;
  var OutData: AnsiString; I:integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand];

    if aComParam <> cpt_Unknown then
      OutData := OutData + ' ' + PARAMVALUES[aComParam];

    for I:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TAIAttackParamType; aParams: array of Integer); overload;
  var OutData: AnsiString; I:integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand] + ' ' + AI_ATTACK_PARAMS[aComParam];

    for I:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[I]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aParams: array of Integer); overload;
  begin
    AddCommand(aCommand, cpt_Unknown, aParams);
  end;

begin

  //Put data into stream
  SaveString := '';
  CommandLayerCount := -1; //Some commands (road/fields) are layered so the file is easier to read (not so many lines)

  //Main header, use same filename for MAP
  //Discontinue KAM format, if mapmaker wants to use MapEd for KaM he needs to update/change other things too, might as well add this line
  //AddData('!'+COMMANDVALUES[ct_SetMap] + ' "data\mission\smaps\' + AnsiString(ExtractFileName(TruncateExt(aFileName))) + '.map"');
  if fGame.MissionMode = mm_Tactic then AddCommand(ct_SetTactic, []);
  AddCommand(ct_SetMaxPlayer, [fPlayers.Count]);
  AddCommand(ct_HumanPlayer, [fGame.MapEditor.DefaultHuman]);
  AddData(''); //NL

  //Player loop
  for I := 0 to fPlayers.Count - 1 do
  begin
    //Player header, using same order of commands as KaM
    AddCommand(ct_SetCurrPlayer, [I]);
    AddCommand(ct_EnablePlayer, [I]);

    if fGame.MapEditor.PlayerHuman[I] then AddCommand(ct_UserPlayer, []);
    if fGame.MapEditor.PlayerAI[I] then AddCommand(ct_AIPlayer, []);

    AddCommand(ct_SetMapColor, [fPlayers[I].FlagColorIndex]);
    if not KMSamePoint(fPlayers[I].CenterScreen, KMPoint(0,0)) then
      AddCommand(ct_CenterScreen, [fPlayers[I].CenterScreen.X-1, fPlayers[I].CenterScreen.Y-1]);

    with fGame.MapEditor.Revealers[I] do
    for K := 0 to Count - 1 do
      AddCommand(ct_ClearUp, [Items[K].X-1, Items[K].Y-1, Tag[K]]);

    if fGame.MapEditor.RevealAll[I] then
      AddCommand(ct_ClearUp, [255]);

    AddData(''); //NL

    //Human specific, e.g. goals, center screen (though all players can have it, only human can use it)
    for K:=0 to fPlayers[I].Goals.Count-1 do
      with fPlayers[I].Goals[K] do
      begin
        if (GoalType = glt_Victory) or (GoalType = glt_None) then //For now treat none same as normal goal, we can add new command for it later
          if GoalCondition = gc_Time then
            AddCommand(ct_AddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ct_AddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,PlayerIndex]);

        if GoalType = glt_Survive then
          if GoalCondition = gc_Time then
            AddCommand(ct_AddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ct_AddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,PlayerIndex]);
      end;
    AddData(''); //NL

    //Computer specific, e.g. AI commands. Always save these commands even if the player
    //is not AI so no data is lost from MapEd (human players will ignore AI script anyway)
    AddCommand(ct_AIStartPosition, [fPlayers[I].AI.Setup.StartPosition.X-1,fPlayers[I].AI.Setup.StartPosition.Y-1]);
    if not fPlayers[I].AI.Setup.AutoBuild then AddCommand(ct_AINoBuild, []);
    if fPlayers[I].AI.Mayor.AutoRepair then    AddCommand(ct_AIAutoRepair, []);
    if fPlayers[I].AI.Setup.AutoDefend then    AddCommand(ct_AIAutoDefend, []);
    AddCommand(ct_AICharacter,cpt_Recruits, [fPlayers[I].AI.Setup.RecruitFactor]);
    AddCommand(ct_AICharacter,cpt_WorkerFactor, [fPlayers[I].AI.Setup.SerfFactor]);
    AddCommand(ct_AICharacter,cpt_Constructors, [fPlayers[I].AI.Setup.WorkerFactor]);
    AddCommand(ct_AICharacter,cpt_TownDefence, [fPlayers[I].AI.Setup.TownDefence]);
    //Only store if a limit is in place (high is the default)
    if fPlayers[I].AI.Setup.MaxSoldiers <> -1 then
      AddCommand(ct_AICharacter,cpt_MaxSoldier, [fPlayers[I].AI.Setup.MaxSoldiers]);
    AddCommand(ct_AICharacter,cpt_EquipRateLeather, [fPlayers[I].AI.Setup.EquipRateLeather]);
    AddCommand(ct_AICharacter,cpt_EquipRateIron,    [fPlayers[I].AI.Setup.EquipRateIron]);
    AddCommand(ct_AICharacter,cpt_AttackFactor, [fPlayers[I].AI.Setup.Aggressiveness]);
    AddCommand(ct_AICharacter,cpt_RecruitCount, [fPlayers[I].AI.Setup.RecruitDelay]);
    for G:=Low(TGroupType) to High(TGroupType) do
      if fPlayers[I].AI.General.DefencePositions.TroopFormations[G].NumUnits <> 0 then //Must be valid and used
        AddCommand(ct_AICharacter, cpt_TroopParam, [KaMGroupType[G], fPlayers[I].AI.General.DefencePositions.TroopFormations[G].NumUnits, fPlayers[I].AI.General.DefencePositions.TroopFormations[G].UnitsPerRow]);
    AddData(''); //NL
    for K:=0 to fPlayers[I].AI.General.DefencePositions.Count - 1 do
      with fPlayers[I].AI.General.DefencePositions[K] do
        AddCommand(ct_AIDefence, [Position.Loc.X-1,Position.Loc.Y-1,byte(Position.Dir)-1,KaMGroupType[GroupType],Radius,byte(DefenceType)]);
    AddData(''); //NL
    AddData(''); //NL
    for K:=0 to fPlayers[I].AI.General.Attacks.Count - 1 do
      with fPlayers[I].AI.General.Attacks[K] do
      begin
        AddCommand(ct_AIAttack, cpt_Type, [KaMAttackType[AttackType]]);
        AddCommand(ct_AIAttack, cpt_TotalAmount, [TotalMen]);
        if TakeAll then
          AddCommand(ct_AIAttack, cpt_TakeAll, [])
        else
          for G:=Low(TGroupType) to High(TGroupType) do
            AddCommand(ct_AIAttack, cpt_TroopAmount, [KaMGroupType[G], GroupAmounts[G]]);

        if (Delay > 0) or (AttackType = aat_Once) then //Type once must always have counter because it uses the delay
          AddCommand(ct_AIAttack,cpt_Counter, [Delay]);

        AddCommand(ct_AIAttack,cpt_Target, [Byte(Target)]);
        if Target = att_CustomPosition then
          AddCommand(ct_AIAttack,cpt_Position, [CustomPosition.X-1,CustomPosition.Y-1]);

        if Range > 0 then
          AddCommand(ct_AIAttack,cpt_Range, [Range]);

        AddCommand(ct_CopyAIAttack, [K]); //Store attack with ID number
        AddData(''); //NL
      end;
    AddData(''); //NL

    //General, e.g. units, roads, houses, etc.
    //Alliances
    for K:=0 to fPlayers.Count-1 do
      if K<>I then
        AddCommand(ct_SetAlliance, [K, byte(fPlayers[I].Alliances[K])]); //0=enemy, 1=ally
    AddData(''); //NL

    //Release/block houses
    ReleaseAllHouses := True;
    for HT := HOUSE_MIN to HOUSE_MAX do
    begin
      if fPlayers[I].Stats.HouseBlocked[HT] then
      begin
        AddCommand(ct_BlockHouse, [HouseTypeToIndex[HT]-1]);
        ReleaseAllHouses := false;
      end
      else
        if fPlayers[I].Stats.HouseGranted[HT] then
          AddCommand(ct_ReleaseHouse, [HouseTypeToIndex[HT]-1])
        else
          ReleaseAllHouses := false;
    end;
    if ReleaseAllHouses then
      AddCommand(ct_ReleaseAllHouses, []);

    //Block trades
    for Res := WARE_MIN to WARE_MAX do
      if not fPlayers[I].Stats.AllowToTrade[Res] then
        AddCommand(ct_BlockTrade, [ResourceTypeToIndex[Res]]);

    //Houses
    StoreCount := 0;
    BarracksCount := 0;
    for K:=0 to fPlayers[I].Houses.Count-1 do
    begin
      H := fPlayers[I].Houses[K];
      if not H.IsDestroyed then
      begin
        AddCommand(ct_SetHouse, [HouseTypeToIndex[H.HouseType]-1, H.GetPosition.X-1, H.GetPosition.Y-1]);
        if H.IsDamaged then
          AddCommand(ct_SetHouseDamage, [H.GetDamage]);

        //Process any wares in this house
        //First two Stores use special KaM commands
        if (H.HouseType = ht_Store) and (StoreCount < 2) then
        begin
          Inc(StoreCount);
          for Res := WARE_MIN to WARE_MAX do
            if H.CheckResIn(Res) > 0 then
              case StoreCount of
                1:  AddCommand(ct_AddWare, [ResourceTypeToIndex[Res], H.CheckResIn(Res)]);
                2:  AddCommand(ct_AddWareToSecond, [ResourceTypeToIndex[Res], H.CheckResIn(Res)]);
              end;
        end
        else
        //First Barracks uses special KaM command
        if (H.HouseType = ht_Barracks) and (BarracksCount = 0) then
        begin
          Inc(BarracksCount);
          for Res := WARFARE_MIN to WARFARE_MAX do
            if H.CheckResIn(Res) > 0 then
              AddCommand(ct_AddWeapon, [ResourceTypeToIndex[Res], H.CheckResIn(Res)]); //Ware, Count
        end
        else
          for Res := WARE_MIN to WARE_MAX do
            if H.CheckResIn(Res) > 0 then
              AddCommand(ct_AddWareToLast, [ResourceTypeToIndex[Res], H.CheckResIn(Res)]);
      end;
    end;
    AddData(''); //NL

    //Roads and fields. We must check EVERY terrain tile
    CommandLayerCount := 0; //Enable command layering
    for iY := 1 to fTerrain.MapY do
      for iX := 1 to fTerrain.MapX do
        if fTerrain.Land[iY,iX].TileOwner = fPlayers[I].PlayerIndex then
        begin
          if fTerrain.Land[iY,iX].TileOverlay = to_Road then
            AddCommand(ct_SetRoad, [iX-1,iY-1]);
          if fTerrain.TileIsCornField(KMPoint(iX,iY)) then
            AddCommand(ct_SetField, [iX-1,iY-1]);
          if fTerrain.TileIsWineField(KMPoint(iX,iY)) then
            AddCommand(ct_SetWinefield, [iX-1,iY-1]);
        end;
    CommandLayerCount := -1; //Disable command layering
    AddData(''); //Extra NL because command layering doesn't put one
    AddData(''); //NL

    //Units
    for K := 0 to fPlayers[I].Units.Count - 1 do
    begin
      U := fPlayers[I].Units[K];
      if not (U is TKMUnitWarrior) then //Groups get saved separately
        AddCommand(ct_SetUnit, [UnitTypeToOldIndex[U.UnitType], U.GetPosition.X-1, U.GetPosition.Y-1]);
    end;

    //Unit groups
    for K := 0 to fPlayers[I].UnitGroups.Count - 1 do
    begin
      Group := fPlayers[I].UnitGroups[K];
      AddCommand(ct_SetGroup, [UnitTypeToIndex[Group.UnitType], Group.Position.X-1, Group.Position.Y-1, Byte(Group.Direction)-1, Group.UnitsPerRow, Group.MapEdCount]);
      if Group.Condition = UNIT_MAX_CONDITION then
        AddCommand(ct_SetGroupFood, []);

      case Group.MapEdOrder.Order of
        ioNoOrder: ;
        ioSendGroup:
          AddCommand(ct_SendGroup, [Group.MapEdOrder.Pos.Loc.X-1, Group.MapEdOrder.Pos.Loc.Y-1, Byte(Group.MapEdOrder.Pos.Dir)-1]);
        ioAttackPosition:
          AddCommand(ct_AttackPosition, [Group.MapEdOrder.Pos.Loc.X-1, Group.MapEdOrder.Pos.Loc.Y-1]);
        else
          Assert(False, 'Unexpected group order in MapEd');
      end;
    end;

    AddData(''); //NL
    AddData(''); //NL
  end; //Player loop

  //Main footer

  //Animals, wares to all, etc. go here
  AddData('//Animals');
  for I:=0 to fPlayers.PlayerAnimals.Units.Count-1 do
  begin
    U := fPlayers.PlayerAnimals.Units[I];
    AddCommand(ct_SetUnit, [UnitTypeToOldIndex[U.UnitType], U.GetPosition.X-1, U.GetPosition.Y-1]);
  end;
  AddData(''); //NL

  //Similar footer to one in Lewin's Editor, useful so ppl know what mission was made with.
  AddData('//This mission was made with KaM Remake Map Editor version '+GAME_VERSION+' at '+AnsiString(DateTimeToStr(Now)));

  //Write uncoded file for debug
  assignfile(f, aFileName+'.txt'); rewrite(f);
  write(f, SaveString);
  closefile(f);

  //Encode it
  for I:=1 to Length(SaveString) do
    SaveString[I] := AnsiChar(Byte(SaveString[I]) xor 239);

  //Write it
  assignfile(f, aFileName); rewrite(f);
  write(f, SaveString);
  closefile(f);
end;


end.