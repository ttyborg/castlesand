unit KM_InterfaceGamePlay;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  SysUtils, KromUtils, KromOGLUtils, Math, Classes, Controls, 
  KM_Controls, KM_Houses, KM_Units, KM_Defaults, KM_CommonTypes, KM_Utils;


type
  TKMGamePlayInterface = class
  private
    //not saved
    fShownUnit:TKMUnit;
    fShownHouse:TKMHouse;
    PrevHint:TObject;
    ShownMessage:integer;
    PlayMoreMsg:TGameResultMsg; //Remember which message we are showing
    fJoiningGroups: boolean;
    AskDemolish:boolean;
    SelectedDirection: TKMDirection;
    SelectingTroopDirection:boolean;
    SelectingDirPosition: TPoint;
    //Saved
    LastSchoolUnit:integer;  //Last unit that was selected in School, global for all schools player owns
    LastBarracksUnit:integer;//Last unit that was selected in Barracks, global for all barracks player owns
    fMessageList:TKMMessageList;

    procedure Create_Replay_Page;
    procedure Create_Message_Page;
    procedure Create_Chat_Page;
    procedure Create_Pause_Page;
    procedure Create_PlayMore_Page;
    procedure Create_Build_Page;
    procedure Create_Ratios_Page;
    procedure Create_Stats_Page;
    procedure Create_Menu_Page;
    procedure Create_Save_Page;
    procedure Create_Load_Page;
    procedure Create_Settings_Page;
    procedure Create_Quit_Page;
    procedure Create_Unit_Page;
    procedure Create_House_Page;
    procedure Create_Store_Page;
    procedure Create_School_Page;
    procedure Create_Barracks_Page;

    procedure Army_ActivateControls(aActive:boolean);
    procedure Army_HideJoinMenu(Sender:TObject);
    procedure Army_Issue_Order(Sender:TObject);
    procedure House_BarracksUnitChange(Sender:TObject; AButton:TMouseButton);
    procedure House_Demolish(Sender:TObject);
    procedure House_RepairToggle(Sender:TObject);
    procedure House_WareDeliveryToggle(Sender:TObject);
    procedure House_OrderClick(Sender:TObject; AButton:TMouseButton);
    procedure House_SchoolUnitChange(Sender:TObject; AButton:TMouseButton);
    procedure House_SchoolUnitRemove(Sender:TObject);
    procedure House_StoreAcceptFlag(Sender:TObject);
    procedure Menu_Settings_Fill;
    procedure Menu_Settings_Change(Sender:TObject);
    procedure Menu_ShowLoad(Sender: TObject);
    procedure Menu_QuitMission(Sender:TObject);
    procedure Menu_NextTrack(Sender:TObject);
    procedure Menu_PreviousTrack(Sender:TObject);
    procedure Message_Close(Sender: TObject);
    procedure Message_Delete(Sender: TObject);
    procedure Message_Display(Sender: TObject);
    procedure Message_GoTo(Sender: TObject);
    procedure Message_UpdateStack;
    procedure Minimap_Update(Sender: TObject);
    procedure Minimap_RightClick(Sender: TObject);
    procedure Unit_Die(Sender:TObject);

    procedure Save_Click(Sender: TObject);
    procedure Load_Click(Sender: TObject);
    procedure SwitchPage(Sender: TObject);
    procedure SwitchPage_Ratios(Sender: TObject);
    procedure RatiosChange(Sender: TObject);
    procedure DisplayHint(Sender: TObject);
    procedure PlayMoreClick(Sender:TObject);
    procedure ReplayClick(Sender: TObject);
    procedure Build_ButtonClick(Sender: TObject);
    procedure Build_Fill(Sender:TObject);
    procedure Chat_Post(Sender:TObject; Key:word);
    procedure Store_Fill(Sender:TObject);
    procedure Stats_Fill(Sender:TObject);
    procedure Menu_Fill(Sender:TObject);
    procedure SetPause(aValue:boolean);
    procedure ShowDirectionCursor(Show:boolean; const aX: integer = 0; const aY: integer = 0; const Dir: TKMDirection = dir_NA);
  protected
    Panel_Main:TKMPanel;
      Image_Main1,Image_Main2,Image_Main3,Image_Main4,Image_Main5:TKMImage; //Toolbar background
      KMMinimap:TKMMinimap;
      Label_Stat, Label_PointerCount, Label_CmdQueueCount, Label_SoundsCount, Label_Hint:TKMLabel;
      Button_Main:array[1..5]of TKMButton; //4 common buttons + Return
      Image_Message:array[1..32]of TKMImage; //Queue of messages covers 32*48=1536px height
      Image_Clock:TKMImage; //Clock displayed when game speed is increased
      Label_Clock:TKMLabel;
      Label_MenuTitle: TKMLabel; //Displays the title of the current menu to the right of return
      Image_DirectionCursor:TKMImage;
    Panel_Replay:TKMPanel; //Bigger Panel to contain Shapes to block all interface below
    Panel_ReplayCtrl:TKMPanel; //Smaller Panel to contain replay controls
      PercentBar_Replay:TKMPercentBar;
      Label_Replay:TKMLabel;
      Button_ReplayRestart:TKMButton;
      Button_ReplayPause:TKMButton;
      Button_ReplayStep:TKMButton;
      Button_ReplayResume:TKMButton;
      Button_ReplayExit:TKMButton;
    Panel_Message:TKMPanel;
      Image_MessageBG:TKMImage;
      Image_MessageBGTop:TKMImage;
      Label_MessageText:TKMLabel;
      Button_MessageGoTo: TKMButton;
      Button_MessageDelete: TKMButton;
      Button_MessageClose: TKMButton;
    //For multiplayer: Send, reply, text area for typing, etc.
    Panel_Chat:TKMPanel;
      Label_ChatText:TKMLabel;
      Edit_ChatMsg:TKMEdit;
    Panel_Pause:TKMPanel;
      Bevel_Pause:TKMBevel;
      Image_Pause:TKMImage;
      Label_Pause1:TKMLabel;
      Label_Pause2:TKMLabel;
    Panel_PlayMore:TKMPanel;
      Bevel_PlayMore:TKMBevel;
      Panel_PlayMoreMsg:TKMPanel;
        Image_PlayMore:TKMImage;
        Label_PlayMore:TKMLabel;
        Button_PlayMore,Button_PlayQuit:TKMButton;
    Panel_Ratios:TKMPanel;
      Button_Ratios:array[1..4]of TKMButton;
      Image_RatioPic0:TKMImage;
      Label_RatioLab0:TKMLabel;
      Image_RatioPic:array[1..4]of TKMImage;
      Label_RatioLab:array[1..4]of TKMLabel;
      Ratio_RatioRat:array[1..4]of TKMRatioRow;
    Panel_Stats:TKMPanel;
      Stat_HousePic,Stat_UnitPic:array[1..32]of TKMImage;
      Stat_HouseQty,Stat_HouseWip,Stat_UnitQty:array[1..32]of TKMLabel;

    Panel_Build:TKMPanel;
      Label_Build:TKMLabel;
      Image_Build_Selected:TKMImage;
      Image_BuildCost_WoodPic:TKMImage;
      Image_BuildCost_StonePic:TKMImage;
      Label_BuildCost_Wood:TKMLabel;
      Label_BuildCost_Stone:TKMLabel;
      Button_BuildRoad,Button_BuildField,Button_BuildWine{,Button_BuildWall},Button_BuildCancel:TKMButtonFlat;
      Button_Build:array[1..HOUSE_COUNT]of TKMButtonFlat;

    Panel_Menu:TKMPanel;
      Button_Menu_Save,Button_Menu_Load,Button_Menu_Settings,Button_Menu_Quit,Button_Menu_TrackUp,Button_Menu_TrackDown:TKMButton;
      Label_Menu_Music, Label_Menu_Track: TKMLabel;

      Panel_Save:TKMPanel;
        Button_Save:array[1..SAVEGAME_COUNT]of TKMButton;

      Panel_Load:TKMPanel;
        Button_Load:array[1..SAVEGAME_COUNT]of TKMButton;

      Panel_Settings:TKMPanel;
        Ratio_Settings_Brightness:TKMRatioRow;
        CheckBox_Settings_Autosave,CheckBox_Settings_FastScroll:TKMCheckBox;
        Label_Settings_MouseSpeed,Label_Settings_SFX,Label_Settings_Music,Label_Settings_Music2:TKMLabel;
        Ratio_Settings_Mouse,Ratio_Settings_SFX,Ratio_Settings_Music:TKMRatioRow;
        CheckBox_Settings_MusicOn:TKMCheckBox;

      Panel_Quit:TKMPanel;
        Button_Quit_Yes,Button_Quit_No:TKMButton;

    Panel_Unit:TKMPanel;
      Label_UnitName:TKMLabel;
      Label_UnitCondition:TKMLabel;
      Label_UnitTask:TKMLabel;
      Label_UnitAct:TKMLabel;
      Label_UnitDescription:TKMLabel;
      ConditionBar_Unit:TKMPercentBar;
      Image_UnitPic:TKMImage;
      Button_Die:TKMButton;

      Panel_Army:TKMPanel;
        Button_Army_GoTo,Button_Army_Stop,Button_Army_Attack:TKMButton;
        Button_Army_RotCW,Button_Army_Storm,Button_Army_RotCCW:TKMButton;
        Button_Army_ForUp,Button_Army_ForDown:TKMButton;
        ImageStack_Army:TKMImageStack;
        Button_Army_Split,Button_Army_Join,Button_Army_Feed:TKMButton;

      Panel_Army_JoinGroups:TKMPanel;
        Button_Army_Join_Cancel:TKMButton;
        Label_Army_Join_Message:TKMLabel;

    Panel_House:TKMPanel;
      Label_House:TKMLabel;
      Button_House_Goods,Button_House_Repair:TKMButton;
      Image_House_Logo,Image_House_Worker:TKMImage;
      HealthBar_House:TKMPercentBar;
      Label_HouseHealth:TKMLabel;

    Panel_House_Common:TKMPanel;
      Label_Common_Demand,Label_Common_Offer,Label_Common_Costs,
      Label_House_UnderConstruction,Label_House_Demolish:TKMLabel;
      Button_House_DemolishYes,Button_House_DemolishNo:TKMButton;
      ResRow_Common_Resource:array[1..4]of TKMResourceRow; //4 bars is the maximum
      ResRow_Order:array[1..4]of TKMResourceOrderRow; //3 bars is the maximum
      ResRow_Costs:array[1..4]of TKMCostsRow; //3 bars is the maximum
    Panel_HouseStore:TKMPanel;
      Button_Store:array[1..28]of TKMButtonFlat;
      Image_Store_Accept:array[1..28]of TKMImage;
    Panel_House_School:TKMPanel;
      Label_School_Res:TKMLabel;
      ResRow_School_Resource:TKMResourceRow;
      Button_School_UnitWIP:TKMButton;
      Button_School_UnitWIPBar:TKMPercentBar;
      Button_School_UnitPlan:array[1..5]of TKMButtonFlat;
      Label_School_Unit:TKMLabel;
      Image_School_Right,Image_School_Train,Image_School_Left:TKMImage;
      Button_School_Right,Button_School_Train,Button_School_Left:TKMButton;
    Panel_HouseBarracks:TKMPanel;
      Button_Barracks:array[1..12]of TKMButtonFlat;
      Label_Barracks_Unit:TKMLabel;
      Image_Barracks_Right,Image_Barracks_Train,Image_Barracks_Left:TKMImage;
      Button_Barracks_Right,Button_Barracks_Train,Button_Barracks_Left:TKMButton;
  public
    MyControls: TKMMasterControl;
    constructor Create;
    destructor Destroy; override;
    procedure ResizeGameArea(X,Y:word);
    procedure ShowHouseInfo(Sender:TKMHouse; aAskDemolish:boolean=false);
    procedure ShowUnitInfo(Sender:TKMUnit);
    procedure MessageIssue(MsgTyp:TKMMessageType; Text:string; Loc:TKMPoint);
    procedure MenuIconsEnabled(NewValue:boolean);
    procedure ShowClock(DoShow:boolean);
    procedure ShowPlayMore(DoShow:boolean; Msg:TGameResultMsg);
    property ShownUnit: TKMUnit read fShownUnit;
    property ShownHouse: TKMHouse read fShownHouse;
    procedure ClearShownUnit;

    procedure KeyDown(Key:Word; Shift: TShiftState);
    procedure KeyPress(Key: Char);
    procedure KeyUp(Key:Word; Shift: TShiftState);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer);

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
    procedure UpdateState;
    procedure Paint;
  end;


implementation
uses KM_Unit1, KM_Units_Warrior, KM_GameInputProcess,
KM_PlayersCollection, KM_Render, KM_TextLibrary, KM_Terrain, KM_Viewport, KM_Game,
KM_Sound, KM_InterfaceMainMenu, Forms;


{Switch between pages}
procedure TKMGamePlayInterface.SwitchPage_Ratios(Sender: TObject);
const ResPic:array[1..4] of TResourceType = (rt_Steel,rt_Coal,rt_Wood,rt_Corn);
      ResLab:array[1..4] of word = (298,300,302,304);
      ResQty:array[1..4] of byte = (2,4,2,3);
      ResHouse:array[1..4,1..4] of THouseType = (
      (ht_WeaponSmithy,ht_ArmorSmithy,ht_None,ht_None),
      (ht_IronSmithy,ht_Metallurgists,ht_WeaponSmithy,ht_ArmorSmithy),
      (ht_ArmorWorkshop,ht_WeaponWorkshop,ht_None,ht_None),
      (ht_Mill,ht_Swine,ht_Stables,ht_None));
var i:integer; ResID:TResourceType; HouseID:THouseType;
begin

  if (MyPlayer=nil)or(MyPlayer.Stats=nil) then exit; //We need to be able to access these

  if not (Sender is TKMButton) then exit;

  //Hide everything but the tab buttons
  for i:=1 to Panel_Ratios.ChildCount do
    if not (Panel_Ratios.Childs[i] is TKMButton) then
      Panel_Ratios.Childs[i].Hide;

  ResID:=ResPic[TKMButton(Sender).Tag];

  Image_RatioPic0.TexID:=350+byte(ResID);
  Label_RatioLab0.Caption:=fTextLibrary.GetTextString(ResLab[TKMButton(Sender).Tag]);
  Image_RatioPic0.Show;
  Label_RatioLab0.Show;

  for i:=1 to ResQty[TKMButton(Sender).Tag] do begin
    HouseID:=ResHouse[TKMButton(Sender).Tag,i];
    Image_RatioPic[i].TexID := GUIBuildIcons[byte(HouseID)];
    Label_RatioLab[i].Caption := fTextLibrary.GetTextString(GUIBuildIcons[byte(HouseID)]-300);
    Ratio_RatioRat[i].Position := MyPlayer.Stats.GetRatio(ResID,HouseID);
    Image_RatioPic[i].Show;
    Label_RatioLab[i].Show;
    Ratio_RatioRat[i].Show;
  end;
end;


procedure TKMGamePlayInterface.RatiosChange(Sender: TObject);
var ResID:TResourceType; HouseID:THouseType;
begin
  if (MyPlayer=nil)or(MyPlayer.Stats=nil) then exit; //We need to be able to access these
  if not (Sender is TKMRatioRow) then exit;

  ResID   := TResourceType(Image_RatioPic0.TexID-350);
  HouseID := THouseType(Image_RatioPic[TKMRatioRow(Sender).Tag].TexID-300);

  fGame.fGameInputProcess.CmdRatio(gic_RatioChange, ResID, HouseID, TKMRatioRow(Sender).Position);
end;


procedure TKMGamePlayInterface.Save_Click(Sender: TObject);
begin
  if not (Sender is TKMButton) then exit; //Just in case
  //Don't allow saving over autosave (AUTOSAVE_SLOT)
  if (TKMControl(Sender).Tag = AUTOSAVE_SLOT) then exit;
  fGame.Save(TKMControl(Sender).Tag);
  SwitchPage(nil); //Close save menu after saving
end;


procedure TKMGamePlayInterface.Load_Click(Sender: TObject);
var LoadError:string;
begin
  LoadError := fGame.Load(TKMControl(Sender).Tag);
  if LoadError <> '' then fGame.fMainMenuInterface.ShowScreen(msError, LoadError); //This will show an option to return back to menu
end;


{Switch between pages}
procedure TKMGamePlayInterface.SwitchPage(Sender: TObject);
var i:integer; LastVisiblePage: TKMPanel;

  procedure Flip4MainButtons(ShowEm:boolean);
  var k:integer;
  begin
    for k:=1 to 4 do Button_Main[k].Visible := ShowEm;
    Button_Main[5].Visible := not ShowEm;
    Label_MenuTitle.Visible := not ShowEm;
  end;

begin

  if (Sender=Button_Main[1])or(Sender=Button_Main[2])or
     (Sender=Button_Main[3])or(Sender=Button_Main[4])or
     (Sender=Button_Menu_Settings)or(Sender=Button_Menu_Quit) then begin
    fShownHouse:=nil;
    fShownUnit:=nil;
    fPlayers.Selected:=nil;
  end;

  //Reset the CursorMode, to cm_None
  Build_ButtonClick(nil);

  //Set LastVisiblePage to which ever page was last visible, out of the ones needed
  if Panel_Settings.Visible then LastVisiblePage := Panel_Settings else
  if Panel_Save.Visible     then LastVisiblePage := Panel_Save     else
  if Panel_Load.Visible     then LastVisiblePage := Panel_Load     else
    LastVisiblePage := nil;

  //If they just closed settings then we should save them (if something has changed)
  if LastVisiblePage = Panel_Settings then
    fGame.GlobalSettings.SaveSettings;

  //First thing - hide all existing pages, except for message page
  for i:=1 to Panel_Main.ChildCount do
    if (Panel_Main.Childs[i] is TKMPanel)
    and (Panel_Main.Childs[i] <> Panel_Message)
    and (Panel_Main.Childs[i] <> Panel_Replay)
    and (Panel_Main.Childs[i] <> Panel_Pause)
    and (Panel_Main.Childs[i] <> Panel_PlayMore) then
      Panel_Main.Childs[i].Hide;

  //First thing - hide all existing pages
    for i:=1 to Panel_House.ChildCount do
      if Panel_House.Childs[i] is TKMPanel then
        Panel_House.Childs[i].Hide;

  //If Sender is one of 4 main buttons, then open the page, hide the buttons and show Return button
  Flip4MainButtons(false);
  if Sender=Button_Main[1] then begin
    Build_Fill(nil);
    Panel_Build.Show;
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(166);
    Build_ButtonClick(Button_BuildRoad);
  end else

  if Sender=Button_Main[2] then begin
    Panel_Ratios.Show;
    SwitchPage_Ratios(Button_Ratios[1]); //Open 1st tab
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(167);
  end else

  if Sender=Button_Main[3] then begin
    Stats_Fill(nil);
    Panel_Stats.Show;
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(168);
  end else

  if (Sender=Button_Main[4]) or (Sender=Button_Quit_No) or
     ((Sender=Button_Main[5]) and (LastVisiblePage=Panel_Settings)) or
     ((Sender=Button_Main[5]) and (LastVisiblePage=Panel_Load)) or
     ((Sender=Button_Main[5]) and (LastVisiblePage=Panel_Save)) then begin
    Menu_Fill(Sender); //Make sure updating happens before it is shown
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(170);
    Panel_Menu.Show;
  end else

  if Sender=Button_Menu_Save then begin
    Menu_ShowLoad(Sender); //Update savegames names
    Panel_Save.Show;
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(173);
  end else

  if Sender=Button_Menu_Load then begin
    Menu_ShowLoad(Sender); //Update savegames names
    Panel_Load.Show;
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(172);
  end else

  if Sender=Button_Menu_Settings then begin
    Menu_Settings_Fill;
    Panel_Settings.Show;
    Label_MenuTitle.Caption:=fTextLibrary.GetTextString(179);
  end else

  if Sender=Button_Menu_Quit then
    Panel_Quit.Show
  else //If Sender is anything else - then show all 4 buttons and hide Return button
    Flip4MainButtons(true);

  //Now process all other kinds of pages
  if (Sender=Panel_Unit) or (Sender=Panel_House)
  or (Sender=Panel_House_Common) or (Sender=Panel_House_School)
  or (Sender=Panel_HouseBarracks) or (Sender=Panel_HouseStore) then
    TKMPanel(Sender).Show;       
end;


procedure TKMGamePlayInterface.DisplayHint(Sender: TObject);
begin
  if (PrevHint = Sender) then exit; //Hint didn't changed

  if Sender=nil then Label_Hint.Caption:=''
                else Label_Hint.Caption:=TKMControl(Sender).Hint;

  PrevHint := Sender;
end;


{Update minimap data}
procedure TKMGamePlayInterface.Minimap_Update(Sender: TObject);
begin
  if Sender=nil then begin //UpdateState loop
    KMMinimap.MapSize:=KMPoint(fTerrain.MapX,fTerrain.MapY);
  end else
    if KMMinimap.BoundRectAt.X*KMMinimap.BoundRectAt.Y <> 0 then //Quick bugfix incase minimap yet not inited it will center vp on 0;0
      fViewport.SetCenter(KMMinimap.BoundRectAt.X,KMMinimap.BoundRectAt.Y);

  KMMinimap.BoundRectAt := KMPointRound(fViewport.GetCenter);
  KMMinimap.ViewArea    := fViewport.GetMinimapClip;
end;


procedure TKMGamePlayInterface.Minimap_RightClick(Sender: TObject);
var
  P: TPoint;
  KMP: TKMPoint;
begin
  GetCursorPos(P); //Convert cursor position to KMPoint within Game render area
  P := Form1.Panel5.ScreenToClient(P);
  KMP := KMMinimap.GetMapCoords(P.X, P.Y, -1); //Outset by 1 pixel to catch cases "outside of map"
  if not KMMinimap.InMapCoords(KMP.X,KMP.Y) then exit; //Must be inside map

  //Send move order, if applicable
  if (fShownUnit is TKMUnitWarrior) and (not fJoiningGroups)
  and fTerrain.Route_CanBeMade(fShownUnit.GetPosition, KMP, CanWalk, 0, false) then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyWalk, TKMUnitWarrior(fShownUnit), KMP);
    fSoundLib.PlayWarrior(fShownUnit.UnitType, sp_Move);
  end;
end;


constructor TKMGamePlayInterface.Create;
var i:integer;
begin
  Inherited;
  fLog.AssertToLog(fViewport<>nil,'fViewport required to be init first');

  fShownUnit:=nil;
  fShownHouse:=nil;
  fJoiningGroups := false;
  SelectingTroopDirection := false;
  SelectingDirPosition.X := 0;
  SelectingDirPosition.Y := 0;

  LastSchoolUnit:=1;
  LastBarracksUnit:=1;
  fMessageList:=TKMMessageList.Create;

{Parent Page for whole toolbar in-game}
  MyControls := TKMMasterControl.Create;
  Panel_Main := TKMPanel.Create(MyControls,0,0,1024,768);

    Image_Main1 := TKMImage.Create(Panel_Main,0,   0,224,200,407);
    Image_Main2 := TKMImage.Create(Panel_Main,0, 200,224,168,554);
    Image_Main3 := TKMImage.Create(Panel_Main,0, 368,224,400,404);
    Image_Main4 := TKMImage.Create(Panel_Main,0, 768,224,400,404);
    Image_Main5 := TKMImage.Create(Panel_Main,0,1168,224,400,404); //For 1600x1200 this is needed

    KMMinimap := TKMMinimap.Create(Panel_Main,10,10,176,176);
    KMMinimap.OnChange := Minimap_Update; //Allow dragging with LMB pressed
    KMMinimap.OnClickRight := Minimap_RightClick;

    {Main 4 buttons +return button}
    for i:=0 to 3 do begin
      Button_Main[i+1]:=TKMButton.Create(Panel_Main,  8+46*i, 372, 42, 36, 439+i);
      Button_Main[i+1].OnClick:=SwitchPage;
      Button_Main[i+1].Hint:=fTextLibrary.GetTextString(160+i);
    end;
    Button_Main[4].Hint:=fTextLibrary.GetTextString(164); //This is an exception to the rule above
    Button_Main[5]:=TKMButton.Create(Panel_Main,  8, 372, 42, 36, 443);
    Button_Main[5].OnClick:=SwitchPage;
    Button_Main[5].Hint:=fTextLibrary.GetTextString(165);
    Label_MenuTitle:=TKMLabel.Create(Panel_Main,54,372,138,36,'',fnt_Metal,kaLeft);

    Image_Clock:=TKMImage.Create(Panel_Main,232,8,67,65,556);
    Image_Clock.Hide;
    Label_Clock:=TKMLabel.Create(Panel_Main,265,80,0,0,'mm:ss',fnt_Outline,kaCenter);
    Label_Clock.Hide;

    Image_DirectionCursor := TKMImage.Create(Panel_Main,0,0,35,36,519);
    Image_DirectionCursor.Hide;

    Create_Message_Page; //Must go bellow message stack
    Create_Chat_Page; //MessagePage sibling

    for i:=low(Image_Message) to high(Image_Message) do
    begin
      Image_Message[i] := TKMImage.Create(Panel_Main,TOOLBAR_WIDTH,fRender.RenderAreaSize.Y-i*48,30,48,495);
      Image_Message[i].Tag := i;
      Image_Message[i].HighlightOnMouseOver := true;
      Image_Message[i].Disable;
      Image_Message[i].Hide;
      Image_Message[i].OnClick := Message_Display;
      Image_Message[i].Anchors := [akLeft, akBottom];
    end;

    Label_Stat:=TKMLabel.Create(Panel_Main,224+80,16,0,0,'',fnt_Outline,kaLeft);
    Label_Stat.Visible := SHOW_SPRITE_COUNT;
    Label_PointerCount :=TKMLabel.Create(Panel_Main,224+80,80,0,0,'',fnt_Outline,kaLeft);
    Label_PointerCount.Visible := SHOW_POINTER_COUNT;
    Label_CmdQueueCount := TKMLabel.Create(Panel_Main,224+80,110,0,0,'',fnt_Outline,kaLeft);
    Label_CmdQueueCount.Visible := SHOW_CMDQUEUE_COUNT;
    Label_SoundsCount := TKMLabel.Create(Panel_Main,224+80,140,0,0,'',fnt_Outline,kaLeft);
    Label_SoundsCount.Visible := DISPLAY_SOUNDS;

    Label_Hint:=TKMLabel.Create(Panel_Main,224+32,fRender.RenderAreaSize.Y-16,0,0,'',fnt_Outline,kaLeft);
    Label_Hint.Anchors := [akLeft, akBottom]; 

{I plan to store all possible layouts on different pages which gets displayed one at a time}
{==========================================================================================}
  Create_Build_Page;
  Create_Ratios_Page;
  Create_Stats_Page;
  Create_Menu_Page;
    Create_Save_Page;
    Create_Load_Page;
    Create_Settings_Page;
    Create_Quit_Page;

  Create_Unit_Page;

  Create_House_Page;
    Create_Store_Page;
    Create_School_Page;
    Create_Barracks_Page;
    //Create_TownHall_Page; //I don't want to make it at all yet

  Create_Pause_Page;
  Create_Replay_Page;
  Create_PlayMore_Page; //Must be created last, so that all controls behind are blocked

  //Controls without a hint will reset the Hint to ''
  MyControls.OnHint := DisplayHint;

  if SHOW_1024_768_OVERLAY then
    with TKMShape.Create(Panel_Main, 0, 0, 1024, 768, $FF00FF00) do Hitable:=false;

  SwitchPage(nil); //Update
end;


destructor TKMGamePlayInterface.Destroy;
begin
  fMessageList.Free;
  MyControls.Free;
  Inherited;
end;


procedure TKMGamePlayInterface.ResizeGameArea(X,Y:word);
var S:TKMPoint; i: integer;
begin
  Panel_Main.Width := X;
  Panel_Main.Height := Y;
  fViewport.ResizeGameArea(X,Y);
  fViewport.SetZoom(fViewport.Zoom);
  Label_Hint.Top := Y-16;
  //Center pause controls when the screen is resized during gameplay
  S := fRender.RenderAreaSize;
  Image_Pause.Left := (S.X div 2);
  Image_Pause.Top  := (S.Y div 2)-40;
  Label_Pause1.Left  := (S.X div 2);
  Label_Pause1.Top   := (S.Y div 2);
  Label_Pause2.Left := (S.X div 2);
  Label_Pause2.Top  := (S.Y div 2)+20;
  Image_Pause.Center;
  Label_Pause1.Center;
  Label_Pause2.Center;
  //Messages
  Panel_Message.Top := Y - 190;
  for i := low(Image_Message) to high(Image_Message) do
    Image_Message[i].Top := Y - i*48;
end;


{Pause overlay page}
procedure TKMGamePlayInterface.Create_Pause_Page;
var S:TKMPoint;
begin
  S := fRender.RenderAreaSize;
  Panel_Pause:=TKMPanel.Create(Panel_Main,0,0,S.X,S.Y);
  Panel_Pause.Stretch;
    Bevel_Pause:=TKMBevel.Create(Panel_Pause,-1,-1,S.X+2,S.Y+2);
    Image_Pause:=TKMImage.Create(Panel_Pause,(S.X div 2),(S.Y div 2)-40,0,0,556);
    Label_Pause1:=TKMLabel.Create(Panel_Pause,(S.X div 2),(S.Y div 2),64,16,fTextLibrary.GetTextString(308),fnt_Antiqua,kaCenter);
    Label_Pause2:=TKMLabel.Create(Panel_Pause,(S.X div 2),(S.Y div 2)+20,64,16,'Press ''P'' to resume the game',fnt_Grey,kaCenter);
    Bevel_Pause.Stretch; //Anchor to all sides
    Image_Pause.ImageCenter;
    Label_Pause1.Center;
    Label_Pause2.Center;
    Image_Pause.Center;
    Panel_Pause.Hide
end;


{ Play More overlay page,
  It's backgrounded with a full-screen bevel area which not only fades image a bit,
  but also blocks all mouse clicks - neat }
procedure TKMGamePlayInterface.Create_PlayMore_Page;
var s:TKMPoint;
begin
  s := fRender.RenderAreaSize;

  Panel_PlayMore := TKMPanel.Create(Panel_Main,0,0,s.X,s.Y);
  Panel_PlayMore.Stretch;
    Bevel_PlayMore := TKMBevel.Create(Panel_PlayMore,-1,-1,s.X+2,s.Y+2);
    Bevel_PlayMore.Stretch;

    Panel_PlayMoreMsg := TKMPanel.Create(Panel_PlayMore,(s.X div 2)-100,(s.Y div 2)-100,200,200);
    Panel_PlayMoreMsg.Center;
      Image_PlayMore:=TKMImage.Create(Panel_PlayMoreMsg,100,40,0,0,556);
      Image_PlayMore.ImageCenter;

      Label_PlayMore  := TKMLabel.Create(Panel_PlayMoreMsg,100,80,64,16,'<<<LEER>>>',fnt_Outline,kaCenter);
      Button_PlayMore := TKMButton.Create(Panel_PlayMoreMsg,0,100,200,30,'<<<LEER>>>',fnt_Metal);
      Button_PlayQuit := TKMButton.Create(Panel_PlayMoreMsg,0,140,200,30,'<<<LEER>>>',fnt_Metal);
      Button_PlayMore.OnClick := PlayMoreClick;
      Button_PlayQuit.OnClick := PlayMoreClick;
    Panel_PlayMore.Hide; //Initially hidden
end;


procedure TKMGamePlayInterface.Create_Replay_Page;
var s:TKMPoint;
begin
  s := fRender.RenderAreaSize;

  Panel_Replay := TKMPanel.Create(Panel_Main, 0, 0, 1024, 768);
  Panel_Replay.Stretch;

    //Block all clicks except MinimapArea
    with TKMShape.Create(Panel_Replay,-1+196,-1-8,s.X+2-196,196+2, $00000000) do
      Anchors := [akLeft, akTop, akRight];
    with TKMShape.Create(Panel_Replay,-1,-1-8+196,s.X+2,s.Y+2-196, $00000000) do
      Anchors := [akLeft, akTop, akRight, akBottom];

    Panel_ReplayCtrl := TKMPanel.Create(Panel_Replay, 320, 8, 160, 60);
      PercentBar_Replay     := TKMPercentBar.Create(Panel_ReplayCtrl, 0, 0, 160, 20, 0);
      Label_Replay          := TKMLabel.Create(Panel_ReplayCtrl, 80, 2, 125, 10, '<<<LEER>>>', fnt_Grey, kaCenter);
      Button_ReplayRestart  := TKMButton.Create(Panel_ReplayCtrl, 0, 24, 24, 24, 'I<', fnt_Metal);
      Button_ReplayPause    := TKMButton.Create(Panel_ReplayCtrl,25, 24, 24, 24, 'II', fnt_Metal);
      Button_ReplayStep     := TKMButton.Create(Panel_ReplayCtrl,50, 24, 24, 24, '\\', fnt_Metal);
      Button_ReplayResume   := TKMButton.Create(Panel_ReplayCtrl,75, 24, 24, 24, 'I>', fnt_Metal);
      Button_ReplayExit     := TKMButton.Create(Panel_ReplayCtrl,100, 24, 24, 24, 'X', fnt_Metal);
      Button_ReplayRestart.OnClick := ReplayClick;
      Button_ReplayPause.OnClick   := ReplayClick;
      Button_ReplayStep.OnClick    := ReplayClick;
      Button_ReplayResume.OnClick  := ReplayClick;
      Button_ReplayExit.OnClick    := ReplayClick;
      Button_ReplayStep.Disable; //Initial state
      Button_ReplayResume.Disable; //Initial state
  Panel_Replay.Hide; //Initially hidden
end;


{Message page}
procedure TKMGamePlayInterface.Create_Message_Page;
begin
  Panel_Message:=TKMPanel.Create(Panel_Main, TOOLBAR_WIDTH, fRender.RenderAreaSize.Y - 190, fRender.RenderAreaSize.X - TOOLBAR_WIDTH, 190);
  Panel_Message.Anchors := [akLeft, akRight, akBottom];

    Image_MessageBG:=TKMImage.Create(Panel_Message,0,20,600,170,409);
    Image_MessageBG.ImageAnchors := Image_MessageBG.ImageAnchors{ + [akRight]}; //When stretched to 1920 screen it looks very bad
    Image_MessageBGTop:=TKMImage.Create(Panel_Message,0,0,600,20,551);
    Image_MessageBGTop.ImageAnchors := Image_MessageBGTop.ImageAnchors{ + [akRight]};

    Label_MessageText:=TKMLabel.Create(Panel_Message,47,67,432,122,'',fnt_Antiqua,kaLeft);
    Label_MessageText.AutoWrap := true;

    Button_MessageGoTo:=TKMButton.Create(Panel_Message,490,74,100,24,fTextLibrary.GetTextString(280),fnt_Antiqua);
    Button_MessageGoTo.Hint := fTextLibrary.GetTextString(281);
    Button_MessageGoTo.OnClick := Message_GoTo;

    Button_MessageDelete:=TKMButton.Create(Panel_Message,490,104,100,24,fTextLibrary.GetTextString(276),fnt_Antiqua);
    Button_MessageDelete.Hint := fTextLibrary.GetTextString(277);
    Button_MessageDelete.OnClick := Message_Delete;
    Button_MessageDelete.MakesSound := false; //Don't play default Click as these buttons use sfx_MessageClose

    Button_MessageClose:=TKMButton.Create(Panel_Message,490,134,100,24,fTextLibrary.GetTextString(282),fnt_Antiqua);
    Button_MessageClose.Hint := fTextLibrary.GetTextString(283);
    Button_MessageClose.OnClick := Message_Close;
    Button_MessageClose.MakesSound := false; //Don't play default Click as these buttons use sfx_MessageClose

  Panel_Message.Hide; //Hide it now because it doesn't get hidden by SwitchPage
end;


{Chat page}
procedure TKMGamePlayInterface.Create_Chat_Page;
begin
  Panel_Chat:=TKMPanel.Create(Panel_Main, TOOLBAR_WIDTH, fRender.RenderAreaSize.Y - 190, fRender.RenderAreaSize.X - TOOLBAR_WIDTH, 190);
  Panel_Chat.Anchors := [akLeft, akRight, akBottom];

    TKMImage.Create(Panel_Chat,0,20,600,170,409);
    TKMImage.Create(Panel_Chat,0,0,600,20,551);

    Label_ChatText:=TKMLabel.Create(Panel_Chat,45,67,500,122,'',fnt_Antiqua,kaLeft);
    Label_ChatText.AutoWrap := true;

    Edit_ChatMsg := TKMEdit.Create(Panel_Chat, 45, 160, 500, 20, fnt_Antiqua);
    Edit_ChatMsg.OnKeyDown := Chat_Post;

  Panel_Chat.Hide; //Hide it now because it doesn't get hidden by SwitchPage
end;


{Build page}
procedure TKMGamePlayInterface.Create_Build_Page;
var i:integer;
begin
  Panel_Build:=TKMPanel.Create(Panel_Main,0,412,196,400);
    Label_Build:=TKMLabel.Create(Panel_Build,100,10,100,30,'',fnt_Outline,kaCenter);
    Image_Build_Selected:=TKMImage.Create(Panel_Build,8,40,32,32,335);
    Image_Build_Selected.ImageCenter;
    Image_BuildCost_WoodPic:=TKMImage.Create(Panel_Build,75,40,32,32,353);
    Image_BuildCost_WoodPic.ImageCenter;
    Image_BuildCost_StonePic:=TKMImage.Create(Panel_Build,130,40,32,32,352);
    Image_BuildCost_StonePic.ImageCenter;
    Label_BuildCost_Wood:=TKMLabel.Create(Panel_Build,105,50,10,30,'',fnt_Outline,kaLeft);
    Label_BuildCost_Stone:=TKMLabel.Create(Panel_Build,160,50,10,30,'',fnt_Outline,kaLeft);
    Button_BuildRoad   := TKMButtonFlat.Create(Panel_Build,  8,80,33,33,335);
    Button_BuildField  := TKMButtonFlat.Create(Panel_Build, 45,80,33,33,337);
    Button_BuildWine   := TKMButtonFlat.Create(Panel_Build, 82,80,33,33,336);
//    Button_BuildWall   := TKMButtonFlat.Create(Panel_Build,119,80,33,33,339);
    Button_BuildCancel := TKMButtonFlat.Create(Panel_Build,156,80,33,33,340);
    Button_BuildRoad.OnClick:=Build_ButtonClick;
    Button_BuildField.OnClick:=Build_ButtonClick;
    Button_BuildWine.OnClick:=Build_ButtonClick;
//    Button_BuildWall.OnClick:=Build_ButtonClick;
    Button_BuildCancel.OnClick:=Build_ButtonClick;
    Button_BuildRoad.Hint:=fTextLibrary.GetTextString(213);
    Button_BuildField.Hint:=fTextLibrary.GetTextString(215);
    Button_BuildWine.Hint:=fTextLibrary.GetTextString(219);
//    Button_BuildWall.Hint:='Build a wall';
    Button_BuildCancel.Hint:=fTextLibrary.GetTextString(211);

    for i:=1 to HOUSE_COUNT do
      if GUIHouseOrder[i] <> ht_None then begin
        Button_Build[i]:=TKMButtonFlat.Create(Panel_Build, 8+((i-1) mod 5)*37,120+((i-1) div 5)*37,33,33,
        GUIBuildIcons[byte(GUIHouseOrder[i])]);

        Button_Build[i].OnClick:=Build_ButtonClick;
        Button_Build[i].Hint:=fTextLibrary.GetTextString(GUIBuildIcons[byte(GUIHouseOrder[i])]-300);
      end;
end;


{Ratios page}
procedure TKMGamePlayInterface.Create_Ratios_Page;
const ResPic:array[1..4] of TResourceType = (rt_Steel,rt_Coal,rt_Wood,rt_Corn);
      ResHint:array[1..4] of word = (297,299,301,303);
var i:integer;
begin
  Panel_Ratios:=TKMPanel.Create(Panel_Main,0,412,200,400);

  for i:=1 to 4 do begin
    Button_Ratios[i]         := TKMButton.Create(Panel_Ratios, 8+(i-1)*40,20,32,32,350+byte(ResPic[i]));
    Button_Ratios[i].Hint    := fTextLibrary.GetTextString(ResHint[i]);
    Button_Ratios[i].Tag     := i;
    Button_Ratios[i].OnClick := SwitchPage_Ratios;
  end;

  Image_RatioPic0 := TKMImage.Create(Panel_Ratios,12,76,32,32,327);
  Label_RatioLab0 := TKMLabel.Create(Panel_Ratios,44,72,100,30,'<<<LEER>>>',fnt_Outline,kaLeft);

  for i:=1 to 4 do begin
    Image_RatioPic[i]         := TKMImage.Create(Panel_Ratios,12,124+(i-1)*50,32,32,327);
    Label_RatioLab[i]         := TKMLabel.Create(Panel_Ratios,50,116+(i-1)*50,100,30,'<<<LEER>>>',fnt_Grey,kaLeft);
    Ratio_RatioRat[i]         := TKMRatioRow.Create(Panel_Ratios,48,136+(i-1)*50,140,20,0,5);
    Ratio_RatioRat[i].Tag     := i;
    Ratio_RatioRat[i].OnChange:= RatiosChange;
  end;
end;


{Statistics page}
procedure TKMGamePlayInterface.Create_Stats_Page;
const LineHeight=34; Nil_Width=10; House_Width=30; Unit_Width=26;
var i,k:integer; hc,uc,off:integer;
  LineBase:integer;
begin
  Panel_Stats:=TKMPanel.Create(Panel_Main,0,412,200,400);

  hc:=1; uc:=1;
  for i:=1 to 8 do begin
    LineBase := (i-1)*LineHeight;
    case i of
    1: begin
          TKMBevel.Create(Panel_Stats,  8,LineBase, 56,30);
          TKMBevel.Create(Panel_Stats, 71,LineBase, 56,30);
          TKMBevel.Create(Panel_Stats,134,LineBase, 56,30);
       end;
    2: begin
          TKMBevel.Create(Panel_Stats,  8,LineBase, 86,30);
          TKMBevel.Create(Panel_Stats,104,LineBase, 86,30);
       end;
    3: begin
          TKMBevel.Create(Panel_Stats,  8,LineBase, 86,30);
          TKMBevel.Create(Panel_Stats,104,LineBase, 86,30);
       end;
    4: begin
          TKMBevel.Create(Panel_Stats,  8,LineBase, 86,30);
          TKMBevel.Create(Panel_Stats,104,LineBase, 86,30);
       end;
    5:    TKMBevel.Create(Panel_Stats,  8,LineBase,116,30);
    6:    TKMBevel.Create(Panel_Stats,  8,LineBase,146,30);
    7:    TKMBevel.Create(Panel_Stats,  8,LineBase, 86,30);
    8: begin
          TKMBevel.Create(Panel_Stats,  8,LineBase,120,30);
          TKMBevel.Create(Panel_Stats,138,LineBase, 52,30);
       end;
    end;

    off:=8;
    for k:=1 to 8 do
    case StatCount[i,k] of
      0: if i=1 then
           inc(off,Nil_Width-3) //Special fix to fit first row of 3x2 items
         else
           inc(off,Nil_Width);
      1: begin
          Stat_HousePic[hc]:=TKMImage.Create(Panel_Stats,off,LineBase,House_Width,30,41); //Filled with [?] at start
          Stat_HouseWip[hc]:=TKMLabel.Create(Panel_Stats,off+House_Width  ,LineBase   ,37,30,'',fnt_Grey,kaRight);
          Stat_HouseQty[hc]:=TKMLabel.Create(Panel_Stats,off+House_Width-2,LineBase+16,37,30,'-',fnt_Grey,kaRight);
          Stat_HousePic[hc].Hint:=TypeToString(StatHouse[hc]);
          Stat_HouseWip[hc].Hint:=TypeToString(StatHouse[hc]);
          Stat_HouseQty[hc].Hint:=TypeToString(StatHouse[hc]);
          Stat_HousePic[hc].ImageCenter;
          inc(hc);
          inc(off,House_Width);
         end;
      2: begin
          Stat_UnitPic[uc]:=TKMImage.Create(Panel_Stats,off,LineBase,Unit_Width,30,byte(StatUnit[uc])+140);
          Stat_UnitQty[uc]:=TKMLabel.Create(Panel_Stats,off+Unit_Width-2,LineBase+16,33,30,'-',fnt_Grey,kaRight);
          Stat_UnitPic[uc].Hint:=TypeToString(StatUnit[uc]);
          Stat_UnitQty[uc].Hint:=TypeToString(StatUnit[uc]);
          Stat_UnitPic[uc].ImageCenter;
          inc(uc);
          inc(off,Unit_Width);
         end;
    end;
  end;
end;


{Menu page}
procedure TKMGamePlayInterface.Create_Menu_Page;
begin
  Panel_Menu:=TKMPanel.Create(Panel_Main,0,412,196,400);
    Button_Menu_Load:=TKMButton.Create(Panel_Menu,8,20,180,30,fTextLibrary.GetTextString(174),fnt_Metal);
    Button_Menu_Load.OnClick:=SwitchPage;
    Button_Menu_Load.Hint:=fTextLibrary.GetTextString(174);
    Button_Menu_Save:=TKMButton.Create(Panel_Menu,8,60,180,30,fTextLibrary.GetTextString(175),fnt_Metal);
    Button_Menu_Save.OnClick:=SwitchPage;
    Button_Menu_Save.Hint:=fTextLibrary.GetTextString(175);
    Button_Menu_Settings:=TKMButton.Create(Panel_Menu,8,100,180,30,fTextLibrary.GetTextString(179),fnt_Metal);
    Button_Menu_Settings.OnClick:=SwitchPage;
    Button_Menu_Settings.Hint:=fTextLibrary.GetTextString(179);
    Button_Menu_Quit:=TKMButton.Create(Panel_Menu,8,180,180,30,fTextLibrary.GetTextString(180),fnt_Metal);
    Button_Menu_Quit.Hint:=fTextLibrary.GetTextString(180);
    Button_Menu_Quit.OnClick:=SwitchPage;
    Button_Menu_TrackUp  :=TKMButton.Create(Panel_Menu,158,320,30,30,'>',fnt_Metal);
    Button_Menu_TrackDown:=TKMButton.Create(Panel_Menu,  8,320,30,30,'<',fnt_Metal);
    Button_Menu_TrackUp.Hint  :=fTextLibrary.GetTextString(209);
    Button_Menu_TrackDown.Hint:=fTextLibrary.GetTextString(208);
    Button_Menu_TrackUp.OnClick  :=Menu_NextTrack;
    Button_Menu_TrackDown.OnClick:=Menu_PreviousTrack;
    Label_Menu_Music:=TKMLabel.Create(Panel_Menu,100,298,100,30,fTextLibrary.GetTextString(207),fnt_Metal,kaCenter);
    Label_Menu_Track:=TKMLabel.Create(Panel_Menu,100,326,100,30,'Spirit',fnt_Grey,kaCenter);
end;


{Save page}
procedure TKMGamePlayInterface.Create_Save_Page;
var i:integer;
begin
  Panel_Save:=TKMPanel.Create(Panel_Main,0,412,200,400);
    for i:=1 to SAVEGAME_COUNT do begin
      Button_Save[i]:=TKMButton.Create(Panel_Save,12,10+(i-1)*28,170,24,'Savegame #'+inttostr(i),fnt_Grey);
      Button_Save[i].OnClick:=Save_Click;
      Button_Save[i].Tag:=i; //Simplify usage
    end;
end;


{Load page}
procedure TKMGamePlayInterface.Create_Load_Page;
var i:integer;
begin
  Panel_Load := TKMPanel.Create(Panel_Main,0,412,200,400);
    for i:=1 to SAVEGAME_COUNT do begin
      Button_Load[i] := TKMButton.Create(Panel_Load,12,10+(i-1)*28,170,24,'Savegame #'+inttostr(i),fnt_Grey);
      Button_Load[i].OnClick := Load_Click;
      Button_Load[i].Tag := i;
    end;
end;


{Options page}
procedure TKMGamePlayInterface.Create_Settings_Page;
begin
  Panel_Settings:=TKMPanel.Create(Panel_Main,0,412,200,400);
    TKMLabel.Create(Panel_Settings,24,10,100,30,fTextLibrary.GetTextString(181),fnt_Metal,kaLeft);
    Ratio_Settings_Brightness:=TKMRatioRow.Create(Panel_Settings,18,30,160,20,fGame.GlobalSettings.SlidersMin,fGame.GlobalSettings.SlidersMax);
    Ratio_Settings_Brightness.OnChange := Menu_Settings_Change;
    CheckBox_Settings_Autosave:=TKMCheckBox.Create(Panel_Settings,18,70,100,30,fTextLibrary.GetTextString(203),fnt_Metal);
    CheckBox_Settings_Autosave.OnClick := Menu_Settings_Change;
    CheckBox_Settings_FastScroll:=TKMCheckBox.Create(Panel_Settings,18,95,100,30,fTextLibrary.GetTextString(204),fnt_Metal);
    CheckBox_Settings_FastScroll.OnClick := Menu_Settings_Change;
    Label_Settings_MouseSpeed:=TKMLabel.Create(Panel_Settings,24,130,100,30,fTextLibrary.GetTextString(192),fnt_Metal,kaLeft);
    Label_Settings_MouseSpeed.Disable;
    Ratio_Settings_Mouse:=TKMRatioRow.Create(Panel_Settings,18,150,160,20,fGame.GlobalSettings.SlidersMin,fGame.GlobalSettings.SlidersMax);
    Ratio_Settings_Mouse.Disable;
    Ratio_Settings_Mouse.Hint:=fTextLibrary.GetTextString(193);
    Ratio_Settings_Mouse.OnChange := Menu_Settings_Change;
    Label_Settings_SFX:=TKMLabel.Create(Panel_Settings,24,178,100,30,fTextLibrary.GetTextString(194),fnt_Metal,kaLeft);
    Ratio_Settings_SFX:=TKMRatioRow.Create(Panel_Settings,18,198,160,20,fGame.GlobalSettings.SlidersMin,fGame.GlobalSettings.SlidersMax);
    Ratio_Settings_SFX.Hint:=fTextLibrary.GetTextString(195);
    Ratio_Settings_SFX.OnChange := Menu_Settings_Change;
    Label_Settings_Music:=TKMLabel.Create(Panel_Settings,24,226,100,30,fTextLibrary.GetTextString(196),fnt_Metal,kaLeft);
    Ratio_Settings_Music:=TKMRatioRow.Create(Panel_Settings,18,246,160,20,fGame.GlobalSettings.SlidersMin,fGame.GlobalSettings.SlidersMax);
    Ratio_Settings_Music.Hint:=fTextLibrary.GetTextString(195);
    Ratio_Settings_Music.OnChange := Menu_Settings_Change;
    CheckBox_Settings_MusicOn:=TKMCheckBox.Create(Panel_Settings,18,276,180,30,'Disable',fnt_Metal);
    CheckBox_Settings_MusicOn.Hint:=fTextLibrary.GetTextString(198);
    CheckBox_Settings_MusicOn.OnClick := Menu_Settings_Change;
end;


{Quit page}
procedure TKMGamePlayInterface.Create_Quit_Page;
begin
  Panel_Quit:=TKMPanel.Create(Panel_Main,0,412,200,400);
    TKMLabel.Create(Panel_Quit,100,30,100,30,fTextLibrary.GetTextString(176),fnt_Outline,kaCenter);
    Button_Quit_Yes := TKMButton.Create(Panel_Quit,8,100,180,30,fTextLibrary.GetTextString(177),fnt_Metal);
    Button_Quit_No  := TKMButton.Create(Panel_Quit,8,140,180,30,fTextLibrary.GetTextString(178),fnt_Metal);
    Button_Quit_Yes.Hint := fTextLibrary.GetTextString(177);
    Button_Quit_No.Hint  := fTextLibrary.GetTextString(178);
    Button_Quit_Yes.OnClick := Menu_QuitMission;
    Button_Quit_No.OnClick  := SwitchPage;
end;


{Unit page}
procedure TKMGamePlayInterface.Create_Unit_Page;
begin
  Panel_Unit:=TKMPanel.Create(Panel_Main,0,412,200,400);
    Label_UnitName        := TKMLabel.Create(Panel_Unit,100,16,100,30,'',fnt_Outline,kaCenter);
    Image_UnitPic         := TKMImage.Create(Panel_Unit,8,38,54,100,521);
    Button_Die            := TKMButton.Create(Panel_Unit,8,120,54,20,'Die',fnt_Grey);
    Label_UnitCondition   := TKMLabel.Create(Panel_Unit,120,40,100,30,fTextLibrary.GetTextString(254),fnt_Grey,kaCenter);
    ConditionBar_Unit     := TKMPercentBar.Create(Panel_Unit,73,55,116,15,80);
    Label_UnitTask        := TKMLabel.Create(Panel_Unit,73,74,130,30,'',fnt_Grey,kaLeft);
    Label_UnitAct         := TKMLabel.Create(Panel_Unit,73,94,130,30,'',fnt_Grey,kaLeft);
    Label_UnitDescription := TKMLabel.Create(Panel_Unit,8,152,236,200,'',fnt_Grey,kaLeft); //Taken from LIB resource
    Label_UnitAct.AutoWrap:= true;
    Button_Die.OnClick    := Unit_Die;

  Panel_Army:=TKMPanel.Create(Panel_Unit,0,160,200,400);
    //Military buttons start at 8.170 and are 52x38/30 (60x46)
    Button_Army_GoTo   := TKMButton.Create(Panel_Army,  8,  0, 56, 40, 27);
    Button_Army_Stop   := TKMButton.Create(Panel_Army, 70,  0, 56, 40, 26);
    Button_Army_Attack := TKMButton.Create(Panel_Army,132,  0, 56, 40, 25);
    Button_Army_RotCW  := TKMButton.Create(Panel_Army,  8, 46, 56, 40, 23);
    Button_Army_Storm  := TKMButton.Create(Panel_Army, 70, 46, 56, 40, 28);
    Button_Army_RotCCW := TKMButton.Create(Panel_Army,132, 46, 56, 40, 24);
    Button_Army_ForUp  := TKMButton.Create(Panel_Army,  8, 92, 56, 40, 33);
    ImageStack_Army    := TKMImageStack.Create(Panel_Army, 70, 92, 56, 40, 43);
    Button_Army_ForDown:= TKMButton.Create(Panel_Army,132, 92, 56, 40, 32);
    Button_Army_Split  := TKMButton.Create(Panel_Army,  8,138, 56, 34, 31);
    Button_Army_Join   := TKMButton.Create(Panel_Army, 70,138, 56, 34, 30);
    Button_Army_Feed   := TKMButton.Create(Panel_Army,132,138, 56, 34, 29);

    //All one-click-action (i.e. not attack, move, link up) army controls have a single procedure that decides what to do based on Sender
    Button_Army_GoTo.OnClick   := Army_Issue_Order;
    Button_Army_Stop.OnClick   := Army_Issue_Order;
    Button_Army_Attack.OnClick := Army_Issue_Order;
    Button_Army_RotCW.OnClick  := Army_Issue_Order;
    Button_Army_Storm.OnClick  := Army_Issue_Order;
    Button_Army_RotCCW.OnClick := Army_Issue_Order;
    Button_Army_ForDown.OnClick:= Army_Issue_Order;
    Button_Army_ForUp.OnClick  := Army_Issue_Order;
    Button_Army_Split.OnClick  := Army_Issue_Order;
    Button_Army_Join.OnClick   := Army_Issue_Order;
    Button_Army_Feed.OnClick   := Army_Issue_Order;

    //Disable not working buttons
    Button_Army_GoTo.Disable;
    Button_Army_Attack.Disable;

    //Hints
    Button_Army_GoTo.Hint   := fTextLibrary.GetTextString(259);
    Button_Army_Stop.Hint   := fTextLibrary.GetTextString(258);
    Button_Army_Attack.Hint := fTextLibrary.GetTextString(257);
    //Button_Army_RotCW.Hint  := fTextLibrary.GetTextString; //KaM has no hint, I guess the icon is enough...
    Button_Army_Storm.Hint  := fTextLibrary.GetTextString(263);
    //Button_Army_RotCCW.Hint := fTextLibrary.GetTextString; //KaM has no hint, I guess the icon is enough...
    Button_Army_ForDown.Hint:= fTextLibrary.GetTextString(264);
    Button_Army_ForUp.Hint  := fTextLibrary.GetTextString(265);
    Button_Army_Split.Hint  := fTextLibrary.GetTextString(261);
    Button_Army_Join.Hint   := fTextLibrary.GetTextString(260);
    Button_Army_Feed.Hint   := fTextLibrary.GetTextString(262);

    {Army controls...
    Go to     Stop      Attack
    Rotate    Storm     Rotate
    -Column   [Info]    +Column
    Split     Join      Feed}

  Panel_Army_JoinGroups:=TKMPanel.Create(Panel_Unit,0,160,200,400);
    Label_Army_Join_Message := TKMLabel.Create(Panel_Army_JoinGroups, 98, 30, 188, 80, fTextLibrary.GetTextString(272),fnt_Outline,kaCenter);
    Button_Army_Join_Cancel := TKMButton.Create(Panel_Army_JoinGroups, 8, 95, 180, 30, fTextLibrary.GetTextString(274), fnt_Metal);

  Button_Army_Join_Cancel.OnClick := Army_HideJoinMenu;
end;


{House description page}
procedure TKMGamePlayInterface.Create_House_Page;
var i:integer;
begin
  Panel_House:=TKMPanel.Create(Panel_Main,0,412,200,400);
    //Thats common things
    //Custom things come in fixed size blocks (more smaller Panels?), and to be shown upon need
    Label_House:=TKMLabel.Create(Panel_House,100,14,100,30,'',fnt_Outline,kaCenter);
    Button_House_Goods:=TKMButton.Create(Panel_House,9,42,30,30,37);
    Button_House_Goods.OnClick := House_WareDeliveryToggle;
    Button_House_Goods.Hint := fTextLibrary.GetTextString(249);
    Button_House_Repair:=TKMButton.Create(Panel_House,39,42,30,30,40);
    Button_House_Repair.OnClick := House_RepairToggle;
    Button_House_Repair.Hint := fTextLibrary.GetTextString(250);
    Image_House_Logo:=TKMImage.Create(Panel_House,68,41,32,32,338);
    Image_House_Logo.ImageCenter;
    Image_House_Worker:=TKMImage.Create(Panel_House,98,41,32,32,141);
    Image_House_Worker.ImageCenter;
    Label_HouseHealth:=TKMLabel.Create(Panel_House,156,45,30,50,fTextLibrary.GetTextString(228),fnt_Mini,kaCenter,$FFE0E0E0);
    HealthBar_House:=TKMPercentBar.Create(Panel_House,129,57,55,15,50);
    Label_House_UnderConstruction:=TKMLabel.Create(Panel_House,100,170,100,30,fTextLibrary.GetTextString(230),fnt_Grey,kaCenter);

    Label_House_Demolish := TKMLabel.Create(Panel_House,100,130,100,30,fTextLibrary.GetTextString(232),fnt_Grey,kaCenter);
    Button_House_DemolishYes := TKMButton.Create(Panel_House,8,185,180,30,fTextLibrary.GetTextString(231),fnt_Metal);
    Button_House_DemolishNo  := TKMButton.Create(Panel_House,8,220,180,30,fTextLibrary.GetTextString(224),fnt_Metal);
    Button_House_DemolishYes.Hint := fTextLibrary.GetTextString(233);
    Button_House_DemolishNo.Hint  := fTextLibrary.GetTextString(224);
    Button_House_DemolishYes.OnClick := House_Demolish;
    Button_House_DemolishNo.OnClick  := House_Demolish;

    Panel_House_Common := TKMPanel.Create(Panel_House,0,76,200,400);
      Label_Common_Demand := TKMLabel.Create(Panel_House_Common,100,2,100,30,fTextLibrary.GetTextString(227),fnt_Grey,kaCenter);
      Label_Common_Offer  := TKMLabel.Create(Panel_House_Common,100,2,100,30,'',fnt_Grey,kaCenter);
      Label_Common_Costs  := TKMLabel.Create(Panel_House_Common,100,2,100,30,fTextLibrary.GetTextString(248),fnt_Grey,kaCenter);
      ResRow_Common_Resource[1] := TKMResourceRow.Create(Panel_House_Common,  8,22,180,20,rt_Trunk,5);
      ResRow_Common_Resource[2] := TKMResourceRow.Create(Panel_House_Common,  8,42,180,20,rt_Stone,5);
      ResRow_Common_Resource[3] := TKMResourceRow.Create(Panel_House_Common,  8,62,180,20,rt_Trunk,5);
      ResRow_Common_Resource[4] := TKMResourceRow.Create(Panel_House_Common,  8,82,180,20,rt_Stone,5);
      for i:=1 to 4 do begin
        ResRow_Order[i] := TKMResourceOrderRow.Create(Panel_House_Common,  8,22,180,20,rt_Trunk,5);
        ResRow_Order[i].OrderRem.OnClickEither := House_OrderClick;
        ResRow_Order[i].OrderAdd.OnClickEither := House_OrderClick;
        ResRow_Order[i].OrderRem.Hint          := fTextLibrary.GetTextString(234);
        ResRow_Order[i].OrderAdd.Hint          := fTextLibrary.GetTextString(235);
      end;
      ResRow_Costs[1] := TKMCostsRow.Create(Panel_House_Common,  8,22,180,20, 1);
      ResRow_Costs[2] := TKMCostsRow.Create(Panel_House_Common,  8,22,180,20, 1);
      ResRow_Costs[3] := TKMCostsRow.Create(Panel_House_Common,  8,22,180,20, 1);
      ResRow_Costs[4] := TKMCostsRow.Create(Panel_House_Common,  8,22,180,20, 1);
end;


{Store page}
procedure TKMGamePlayInterface.Create_Store_Page;
var i:integer;
begin
    Panel_HouseStore:=TKMPanel.Create(Panel_House,0,76,200,400);
      for i:=1 to 28 do begin
        Button_Store[i]:=TKMButtonFlat.Create(Panel_HouseStore, 8+((i-1)mod 5)*36,19+((i-1)div 5)*42,32,36,350+i);
        Button_Store[i].OnClick:=House_StoreAcceptFlag;
        Button_Store[i].Tag:=i;
        Button_Store[i].Hint:=TypeToString(TResourceType(i));
        Button_Store[i].FontColor := $FFE0E0E0;
        Image_Store_Accept[i]:=TKMImage.Create(Panel_HouseStore, 8+((i-1)mod 5)*36+20,18+((i-1)div 5)*42+1,12,12,49);
        Image_Store_Accept[i].Tag:=i;
        Image_Store_Accept[i].OnClick:=House_StoreAcceptFlag;
        Image_Store_Accept[i].Hint:=TypeToString(TResourceType(i));
      end;
end;


{School page}
procedure TKMGamePlayInterface.Create_School_Page;
var i:integer;
begin
    Panel_House_School:=TKMPanel.Create(Panel_House,0,76,200,400);
      Label_School_Res:=TKMLabel.Create(Panel_House_School,100,2,100,30,fTextLibrary.GetTextString(227),fnt_Grey,kaCenter);
      ResRow_School_Resource := TKMResourceRow.Create(Panel_House_School,  8,22,180,20,rt_Gold,5);
      ResRow_School_Resource.Hint :=TypeToString(rt_Gold);
      Button_School_UnitWIPBar :=TKMPercentBar.Create(Panel_House_School,42,54,138,20,0);
      Button_School_UnitWIP := TKMButton.Create(Panel_House_School,  8,48,32,32,0);
      Button_School_UnitWIP.Hint := fTextLibrary.GetTextString(225);
      Button_School_UnitWIP.Tag := 1;
      Button_School_UnitWIP.OnClick := House_SchoolUnitRemove;
      for i:=1 to 5 do begin
        Button_School_UnitPlan[i] := TKMButtonFlat.Create(Panel_House_School, 8+(i-1)*36,80,32,32,0);
        Button_School_UnitPlan[i].Tag := i+1;
        Button_School_UnitPlan[i].OnClick := House_SchoolUnitRemove;
      end;
      Label_School_Unit:=TKMLabel.Create(Panel_House_School,100,116,100,30,'',fnt_Outline,kaCenter);
      Image_School_Left :=TKMImage.Create(Panel_House_School,  8,136,54,80,521);
      Image_School_Left.Disable;
      Image_School_Train:=TKMImage.Create(Panel_House_School, 70,136,54,80,522);
      Image_School_Right:=TKMImage.Create(Panel_House_School,132,136,54,80,523);
      Image_School_Right.Disable;
      Button_School_Left :=TKMButton.Create(Panel_House_School,  8,226,54,40,35);
      Button_School_Train:=TKMButton.Create(Panel_House_School, 70,226,54,40,42);
      Button_School_Right:=TKMButton.Create(Panel_House_School,132,226,54,40,36);
      Button_School_Left.OnClickEither:=House_SchoolUnitChange;
      Button_School_Train.OnClickEither:=House_SchoolUnitChange;
      Button_School_Right.OnClickEither:=House_SchoolUnitChange;
      Button_School_Left.Hint :=fTextLibrary.GetTextString(242);
      Button_School_Train.Hint:=fTextLibrary.GetTextString(243);
      Button_School_Right.Hint:=fTextLibrary.GetTextString(241);
end;


{Barracks page}
procedure TKMGamePlayInterface.Create_Barracks_Page;
var i:integer;
begin
    Panel_HouseBarracks:=TKMPanel.Create(Panel_House,0,76,200,400);
      for i:=1 to 12 do
      begin
        Button_Barracks[i]:=TKMButtonFlat.Create(Panel_HouseBarracks, 8+((i-1)mod 6)*31,8+((i-1)div 6)*42,28,38,366+i);
        Button_Barracks[i].TexOffsetX:=1;
        Button_Barracks[i].TexOffsetY:=1;
        Button_Barracks[i].CapOffsetY:=2;
        Button_Barracks[i].HideHighlight:=true;
        Button_Barracks[i].Hint:=TypeToString(TResourceType(16+i));
      end;
      Button_Barracks[12].TexID:=154;
      Button_Barracks[12].Hint:=TypeToString(ut_Recruit);

      Label_Barracks_Unit:=TKMLabel.Create(Panel_HouseBarracks,100,96,100,30,'',fnt_Outline,kaCenter);

      Image_Barracks_Left :=TKMImage.Create(Panel_HouseBarracks,  8,116,54,80,535);
      Image_Barracks_Left.Disable;
      Image_Barracks_Train:=TKMImage.Create(Panel_HouseBarracks, 70,116,54,80,536);
      Image_Barracks_Right:=TKMImage.Create(Panel_HouseBarracks,132,116,54,80,537);
      Image_Barracks_Right.Disable;

      Button_Barracks_Left :=TKMButton.Create(Panel_HouseBarracks,  8,226,54,40,35);
      Button_Barracks_Train:=TKMButton.Create(Panel_HouseBarracks, 70,226,54,40,42);
      Button_Barracks_Right:=TKMButton.Create(Panel_HouseBarracks,132,226,54,40,36);
      Button_Barracks_Left.OnClickEither:=House_BarracksUnitChange;
      Button_Barracks_Train.OnClickEither:=House_BarracksUnitChange;
      Button_Barracks_Right.OnClickEither:=House_BarracksUnitChange;
      Button_Barracks_Left.Hint :=fTextLibrary.GetTextString(237);
      Button_Barracks_Train.Hint:=fTextLibrary.GetTextString(240);
      Button_Barracks_Right.Hint:=fTextLibrary.GetTextString(238);
      Button_Barracks_Train.Disable; //Unimplemented yet
end;


procedure TKMGamePlayInterface.Message_Display(Sender: TObject);
var i: integer;
begin
  if not TKMImage(Sender).Visible then exit; //Exit if the message is not active

  ShownMessage := 0; //Can be replaced with Tag querring, but it not important
  for i := low(Image_Message) to high(Image_Message) do begin
    Image_Message[i].Highlight := false; //dim all messages
    if Sender = Image_Message[i] then
      ShownMessage := i;
  end;

  if ShownMessage=0 then exit; //Exit if the sender cannot be found

  Image_Message[ShownMessage].Highlight := true; //make it brighter

  if fMessageList.GetMsgType(ShownMessage) <> msgScroll then begin
    Label_MessageText.Caption := fMessageList.GetText(ShownMessage);
    Button_MessageGoTo.Enabled := fMessageList.GetMsgHasGoTo(ShownMessage);
    Panel_Chat.Hide;
    Panel_Message.Show;
  end else begin
    //Label_ChatText.Caption := fGame.fChat.GetAllMessages;
    MyControls.CtrlFocus := Edit_ChatMsg;
    Panel_Chat.Show;
    Panel_Message.Hide;
  end;
  fSoundLib.Play(sfx_MessageOpen); //Play parchment sound when they open the message
end;


procedure TKMGamePlayInterface.Message_Close(Sender: TObject);
begin
  Message_UpdateStack;
  if ShownMessage <> 0 then
  begin
    Image_Message[ShownMessage].Highlight := false;
    fSoundLib.Play(sfx_MessageClose);
  end;
  ShownMessage := 0;
  Panel_Message.Hide;
end;


procedure TKMGamePlayInterface.Message_Delete(Sender: TObject);
begin
  if ShownMessage = 0 then exit; //Player pressed DEL with no Msg opened
  fMessageList.RemoveEntry(ShownMessage);
  Message_Close(Sender);
  DisplayHint(nil);
end;


procedure TKMGamePlayInterface.Message_GoTo(Sender: TObject);
begin
  if (fMessageList.GetLoc(ShownMessage).X <> 0) and (fMessageList.GetLoc(ShownMessage).Y <> 0) then
    fViewport.SetCenter(fMessageList.GetLoc(ShownMessage).X,fMessageList.GetLoc(ShownMessage).Y);
end;


procedure TKMGamePlayInterface.Build_ButtonClick(Sender: TObject);
var i:integer;
begin
  if Sender=nil then begin GameCursor.Mode:=cm_None; exit; end;

  //Release all buttons
  for i:=1 to Panel_Build.ChildCount do
    if Panel_Build.Childs[i] is TKMButtonFlat then
      TKMButtonFlat(Panel_Build.Childs[i]).Down:=false;

  //Press the button
  TKMButtonFlat(Sender).Down := true;

  //Reset cursor and see if it needs to be changed
  GameCursor.Mode := cm_None;
  GameCursor.Tag1 := 0;
  GameCursor.Tag2 := 0;
  Label_BuildCost_Wood.Caption  := '-';
  Label_BuildCost_Stone.Caption := '-';
  Label_Build.Caption := '';

  if Button_BuildCancel.Down then begin
    GameCursor.Mode:=cm_Erase;
    Image_Build_Selected.TexID := 340;
    Label_Build.Caption := fTextLibrary.GetTextString(210);
  end;
  if Button_BuildRoad.Down then begin
    GameCursor.Mode:=cm_Road;
    Image_Build_Selected.TexID := 335;
    Label_BuildCost_Stone.Caption:='1';
    Label_Build.Caption := fTextLibrary.GetTextString(212);
  end;
  if Button_BuildField.Down then begin
    GameCursor.Mode:=cm_Field;
    Image_Build_Selected.TexID := 337;
    Label_Build.Caption := fTextLibrary.GetTextString(214);
  end;
  if Button_BuildWine.Down then begin
    GameCursor.Mode:=cm_Wine;
    Image_Build_Selected.TexID := 336;
    Label_BuildCost_Wood.Caption:='1';
    Label_Build.Caption := fTextLibrary.GetTextString(218);
  end;
{  if Button_BuildWall.Down then begin
    CursorMode.Mode:=cm_Wall;
    Image_Build_Selected.TexID := 339;
    Label_BuildCost_Wood.Caption:='1';
    //Label_Build.Caption := fTextLibrary.GetTextString(218);
  end;}

  for i:=1 to HOUSE_COUNT do
  if GUIHouseOrder[i] <> ht_None then
  if Button_Build[i].Down then begin
     GameCursor.Mode:=cm_Houses;
     GameCursor.Tag1:=byte(GUIHouseOrder[i]);
     Image_Build_Selected.TexID := GUIBuildIcons[byte(GUIHouseOrder[i])];
     Label_BuildCost_Wood.Caption:=inttostr(HouseDAT[byte(GUIHouseOrder[i])].WoodCost);
     Label_BuildCost_Stone.Caption:=inttostr(HouseDAT[byte(GUIHouseOrder[i])].StoneCost);
     Label_Build.Caption := TypeToString(THouseType(byte(GUIHouseOrder[i])));
  end;
end;


procedure TKMGamePlayInterface.ShowHouseInfo(Sender:TKMHouse; aAskDemolish:boolean=false);
const LineAdv = 25; //Each new Line is placed ## pixels after previous
var i,RowRes,Base,Line:integer;
begin
  fShownUnit  := nil;
  fShownHouse := Sender;
  AskDemolish := aAskDemolish;

  if not Assigned(Sender) then begin //=nil produces wrong result when there's no object at all
    SwitchPage(nil);
    exit;
  end;

  {Common data}
  Label_House.Caption:=TypeToString(Sender.GetHouseType);
  Image_House_Logo.TexID:=300+byte(Sender.GetHouseType);
  Image_House_Worker.TexID:=140+HouseDAT[byte(Sender.GetHouseType)].OwnerType+1;
  Image_House_Worker.Hint := TypeToString(TUnitType(HouseDAT[byte(Sender.GetHouseType)].OwnerType+1));
  HealthBar_House.Caption:=inttostr(round(Sender.GetHealth))+'/'+inttostr(HouseDAT[byte(Sender.GetHouseType)].MaxHealth);
  HealthBar_House.Position:=round( Sender.GetHealth / HouseDAT[byte(Sender.GetHouseType)].MaxHealth * 100 );

  if AskDemolish then
  begin
    for i:=1 to Panel_House.ChildCount do
      Panel_House.Childs[i].Hide; //hide all
    Label_House_Demolish.Show;
    Button_House_DemolishYes.Show;
    Button_House_DemolishNo.Show;
    Label_House.Show;
    Image_House_Logo.Show;
    Image_House_Worker.Show;
    Image_House_Worker.Enable;
    HealthBar_House.Show;
    Label_HouseHealth.Show;
    SwitchPage(Panel_House);
    exit;
  end;

  if not Sender.IsComplete then
  begin
    for i:=1 to Panel_House.ChildCount do
      Panel_House.Childs[i].Hide; //hide all
    Label_House_UnderConstruction.Show;
    Label_House.Show;
    Image_House_Logo.Show;
    Image_House_Worker.Show;
    Image_House_Worker.Enable;
    HealthBar_House.Show;
    Label_HouseHealth.Show;
    SwitchPage(Panel_House);
    exit;
  end;


  for i:=1 to Panel_House.ChildCount do
    Panel_House.Childs[i].Show; //show all

  Image_House_Worker.Enabled := Sender.GetHasOwner;
  Image_House_Worker.Visible := TUnitType(HouseDAT[byte(Sender.GetHouseType)].OwnerType+1) <> ut_None;
  Button_House_Goods.Enabled := not (HouseInput[byte(Sender.GetHouseType)][1] in [rt_None,rt_All,rt_Warfare]);
  if Sender.BuildingRepair then Button_House_Repair.TexID:=39 else Button_House_Repair.TexID:=40;
  if Sender.WareDelivery then Button_House_Goods.TexID:=37 else Button_House_Goods.TexID:=38;
  Label_House_UnderConstruction.Hide;
  Label_House_Demolish.Hide;
  Button_House_DemolishYes.Hide;
  Button_House_DemolishNo.Hide;
  SwitchPage(Panel_House);

  case Sender.GetHouseType of
    ht_Store: begin
          Store_Fill(nil);
          SwitchPage(Panel_HouseStore);
        end;

    ht_School: begin
          ResRow_School_Resource.ResourceCount:=Sender.CheckResIn(rt_Gold);
          House_SchoolUnitChange(nil, mbLeft);
          SwitchPage(Panel_House_School);
        end;

    ht_Barracks: begin
          Image_House_Worker.Enable; //In the barrack the recruit icon is always enabled
          House_BarracksUnitChange(nil, mbLeft);
          SwitchPage(Panel_HouseBarracks);
          end;
    ht_TownHall:;
    else begin

      //First thing - hide everything
      for i:=1 to Panel_House_Common.ChildCount do
        Panel_House_Common.Childs[i].Hide;

      //Now show only what we need
      RowRes:=1; Line:=0; Base := 2;
      //Show Demand
      if HouseInput[byte(Sender.GetHouseType),1] in [rt_Trunk..rt_Fish] then begin
        Label_Common_Demand.Show;
        Label_Common_Demand.Top:=Base+Line*LineAdv+6;
        inc(Line);
        for i:=1 to 4 do if HouseInput[byte(Sender.GetHouseType),i] in [rt_Trunk..rt_Fish] then begin
          ResRow_Common_Resource[RowRes].Resource:=HouseInput[byte(Sender.GetHouseType),i];
          ResRow_Common_Resource[RowRes].Hint:=TypeToString(HouseInput[byte(Sender.GetHouseType),i]);
          ResRow_Common_Resource[RowRes].ResourceCount:=Sender.CheckResIn(HouseInput[byte(Sender.GetHouseType),i]);
          ResRow_Common_Resource[RowRes].Show;
          ResRow_Common_Resource[RowRes].Top:=Base+Line*LineAdv;
          inc(Line);
          inc(RowRes);
        end;
      end;
      //Show Output
      if not HousePlaceOrders[byte(Sender.GetHouseType)] then
      if HouseOutput[byte(Sender.GetHouseType),1] in [rt_Trunk..rt_Fish] then begin
        Label_Common_Offer.Show;
        Label_Common_Offer.Caption:=fTextLibrary.GetTextString(229)+'(x'+inttostr(HouseDAT[byte(Sender.GetHouseType)].ResProductionX)+'):';
        Label_Common_Offer.Top:=Base+Line*LineAdv+6;
        inc(Line);
        for i:=1 to 4 do
        if HouseOutput[byte(Sender.GetHouseType),i] in [rt_Trunk..rt_Fish] then begin
          ResRow_Common_Resource[RowRes].Resource:=HouseOutput[byte(Sender.GetHouseType),i];
          ResRow_Common_Resource[RowRes].ResourceCount:=Sender.CheckResOut(HouseOutput[byte(Sender.GetHouseType),i]);
          ResRow_Common_Resource[RowRes].Show;
          ResRow_Common_Resource[RowRes].Top:=Base+Line*LineAdv;
          ResRow_Common_Resource[RowRes].Hint:=TypeToString(HouseOutput[byte(Sender.GetHouseType),i]);
          inc(Line);
          inc(RowRes);
        end;
      end;
      //Show Orders
      if HousePlaceOrders[byte(Sender.GetHouseType)] then begin
        Label_Common_Offer.Show;
        Label_Common_Offer.Caption:=fTextLibrary.GetTextString(229)+'(x'+inttostr(HouseDAT[byte(Sender.GetHouseType)].ResProductionX)+'):';
        Label_Common_Offer.Top:=Base+Line*LineAdv+6;
        inc(Line);
        for i:=1 to 4 do //Orders
        if HouseOutput[byte(Sender.GetHouseType),i] in [rt_Trunk..rt_Fish] then begin
          ResRow_Order[i].Resource:=HouseOutput[byte(Sender.GetHouseType),i];
          ResRow_Order[i].ResourceCount:=Sender.CheckResOut(HouseOutput[byte(Sender.GetHouseType),i]);
          ResRow_Order[i].OrderCount:=Sender.CheckResOrder(i);
          ResRow_Order[i].Show;
          ResRow_Order[i].OrderAdd.Show;
          ResRow_Order[i].OrderRem.Show;
          ResRow_Order[i].Hint:=TypeToString(HouseOutput[byte(Sender.GetHouseType),i]);
          ResRow_Order[i].Top:=Base+Line*LineAdv;
          inc(Line);
        end;
        Label_Common_Costs.Show;
        Label_Common_Costs.Top:=Base+Line*LineAdv+6;
        inc(Line);
        for i:=1 to 4 do //Costs
        if HouseOutput[byte(Sender.GetHouseType),i] in [rt_Trunk..rt_Fish] then begin
          ResRow_Costs[i].CostID:=byte(HouseOutput[byte(Sender.GetHouseType),i]);
          ResRow_Costs[i].Show;
          ResRow_Costs[i].Top:=Base+Line*LineAdv;
          inc(Line);
        end;
      end;
      SwitchPage(Panel_House_Common);
    end;
  end;
end;


procedure TKMGamePlayInterface.ShowUnitInfo(Sender:TKMUnit);
var Commander:TKMUnitWarrior;
begin
  fShownUnit  := Sender;
  fShownHouse := nil;

  if (fShownUnit=nil) or (not fShownUnit.Visible) or (fShownUnit.IsDeadOrDying) then begin
    SwitchPage(nil);
    exit;
  end;

  SwitchPage(Panel_Unit);
  Label_UnitName.Caption:=TypeToString(Sender.UnitType);
  Image_UnitPic.TexID:=520+byte(Sender.UnitType);
  ConditionBar_Unit.Position:=EnsureRange(round(Sender.Condition / UNIT_MAX_CONDITION * 100),-10,110);
  Label_UnitTask.Caption:='Task: '+Sender.GetUnitTaskText;
  Label_UnitAct.Caption:='Act: '+Sender.GetUnitActText;

  if Sender is TKMUnitWarrior then
  begin
    Label_UnitDescription.Hide;
    Commander := TKMUnitWarrior(Sender).GetCommander;
    if not Commander.ArmyCanTakeOrders then
      Army_HideJoinMenu(nil); //Cannot be joining while in combat/charging
    if fJoiningGroups then
    begin
      Panel_Army_JoinGroups.Show;
      Panel_Army.Hide;
    end
    else
    begin
      Panel_Army.Show;
      ImageStack_Army.SetCount(Commander.GetMemberCount + 1,Commander.UnitsPerRow); //Count+commander, Columns
      Panel_Army_JoinGroups.Hide;
      Army_ActivateControls(Commander.ArmyCanTakeOrders);
      Button_Army_Split.Enabled := (Commander.GetMemberCount > 0)and Commander.ArmyCanTakeOrders;
    end;
    Button_Army_Storm.Enabled := (UnitGroups[byte(Sender.UnitType)] = gt_Melee)and Commander.ArmyCanTakeOrders; //Only melee groups may charge
  end
  else
  begin //Citizen specific
    Label_UnitDescription.Caption := fTextLibrary.GetTextString(siUnitDescriptions+byte(Sender.UnitType));
    Label_UnitDescription.Show;
    Panel_Army.Hide;
    Panel_Army_JoinGroups.Hide;
  end;
end;


procedure TKMGamePlayInterface.Unit_Die(Sender:TObject);
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMUnit) then exit;
  fGame.fGameInputProcess.CmdTemp(gic_TempKillUnit, TKMUnit(fPlayers.Selected));
end;


procedure TKMGamePlayInterface.House_Demolish(Sender:TObject);
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouse) then exit;

  if Sender=Button_House_DemolishYes then begin
    fGame.fGameInputProcess.CmdBuild(gic_BuildRemoveHouse, TKMHouse(fPlayers.Selected).GetPosition);
    ShowHouseInfo(nil, false); //Simpliest way to reset page and ShownHouse
    SwitchPage(Button_Main[1]); //Return to build menu after demolishing
  end else begin
    AskDemolish:=false;
    SwitchPage(Button_Main[1]); //Cancel and return to build menu
  end;
end;


procedure TKMGamePlayInterface.House_RepairToggle(Sender:TObject);
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouse) then exit;
  fGame.fGameInputProcess.CmdHouse(gic_HouseRepairToggle, TKMHouse(fPlayers.Selected));
  case TKMHouse(fPlayers.Selected).BuildingRepair of
    true:   Button_House_Repair.TexID := 39;
    false:  Button_House_Repair.TexID := 40;
  end;
end;


procedure TKMGamePlayInterface.House_WareDeliveryToggle(Sender:TObject);
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouse) then exit;
  fGame.fGameInputProcess.CmdHouse(gic_HouseDeliveryToggle, TKMHouse(fPlayers.Selected));
  case TKMHouse(fPlayers.Selected).WareDelivery of
    true:   Button_House_Goods.TexID := 37;
    false:  Button_House_Goods.TexID := 38;
  end;
end;


procedure TKMGamePlayInterface.House_OrderClick(Sender:TObject; AButton:TMouseButton);
var i:integer; Amt:byte;
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouse) then exit;

  Amt := 0;
  if AButton = mbLeft then Amt := 1;
  if AButton = mbRight then Amt := 10;

  for i:=1 to 4 do begin
    if Sender = ResRow_Order[i].OrderRem then
      fGame.fGameInputProcess.CmdHouse(gic_HouseOrderProduct, TKMHouse(fPlayers.Selected), i, -Amt);
    if Sender = ResRow_Order[i].OrderAdd then
      fGame.fGameInputProcess.CmdHouse(gic_HouseOrderProduct, TKMHouse(fPlayers.Selected), i, Amt);
  end;
end;


procedure TKMGamePlayInterface.House_BarracksUnitChange(Sender:TObject; AButton:TMouseButton);
var i, k, Tmp: integer; Barracks:TKMHouseBarracks; CanEquip: boolean;
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouseBarracks) then exit;

  Barracks:=TKMHouseBarracks(fPlayers.Selected);

  if (Sender=Button_Barracks_Left) and (AButton = mbRight) then LastBarracksUnit := 1;
  if (Sender=Button_Barracks_Right) and (AButton = mbRight) then LastBarracksUnit := Length(Barracks_Order);

  if (Sender=Button_Barracks_Left)and(LastBarracksUnit > 1) then dec(LastBarracksUnit);
  if (Sender=Button_Barracks_Right)and(LastBarracksUnit < length(Barracks_Order)) then inc(LastBarracksUnit);

  if Sender=Button_Barracks_Train then //Equip unit
  begin
    fGame.fGameInputProcess.CmdHouse(gic_HouseTrain, Barracks, TUnitType(14+LastBarracksUnit));
  end;

  CanEquip:=true;
  for i:=1 to 12 do begin
    if i in [1..11] then Tmp:=TKMHouseBarracks(fPlayers.Selected).CheckResIn(TResourceType(i+16))
                    else Tmp:=TKMHouseBarracks(fPlayers.Selected).RecruitsList.Count;
    if Tmp=0 then Button_Barracks[i].Caption:='-'
             else Button_Barracks[i].Caption:=inttostr(Tmp);
    //Set highlights
    Button_Barracks[i].Down:=false;
    for k:=1 to 4 do
      if i = TroopCost[TUnitType(14+LastBarracksUnit),k] then
      begin
        Button_Barracks[i].Down:=true;
        if Tmp=0 then CanEquip := false; //Can't equip if we don't have a required resource
      end;
  end;
  Button_Barracks[12].Down:=true; //Recruit is always enabled, all troops require one

  Button_Barracks_Train.Enabled := CanEquip and (Barracks.RecruitsList.Count > 0);
  Button_Barracks_Left.Enabled := LastBarracksUnit > 1;
  Button_Barracks_Right.Enabled := LastBarracksUnit < length(Barracks_Order);
  Image_Barracks_Left.Visible:= Button_Barracks_Left.Enabled;
  Image_Barracks_Right.Visible:= Button_Barracks_Right.Enabled;

  if Button_Barracks_Left.Enabled then
    Image_Barracks_Left.TexID:=520+byte(Barracks_Order[LastBarracksUnit-1]);

  Label_Barracks_Unit.Caption:=TypeToString(TUnitType(Barracks_Order[LastBarracksUnit]));
  Image_Barracks_Train.TexID:=520+byte(Barracks_Order[LastBarracksUnit]);

  if Button_Barracks_Right.Enabled then
    Image_Barracks_Right.TexID:=520+byte(Barracks_Order[LastBarracksUnit+1]);
end;


{Process click on Left-Train-Right buttons of School}
procedure TKMGamePlayInterface.House_SchoolUnitChange(Sender:TObject; AButton:TMouseButton);
var i:byte; School:TKMHouseSchool;
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouseSchool) then exit;
  School:=TKMHouseSchool(fPlayers.Selected);

  if (AButton = mbRight) and (Sender=Button_School_Left) then LastSchoolUnit := 1;
  if (AButton = mbRight) and (Sender=Button_School_Right) then LastSchoolUnit := Length(School_Order);

  if (Sender=Button_School_Left)and(LastSchoolUnit > 1) then dec(LastSchoolUnit);
  if (Sender=Button_School_Right)and(LastSchoolUnit < length(School_Order)) then inc(LastSchoolUnit);

  if Sender=Button_School_Train then //Add unit to training queue
    for i:=0 to byte(AButton = mbRight)*5 do //If they right click fill the entire queue
      fGame.fGameInputProcess.CmdHouse(gic_HouseTrain, School, TUnitType(School_Order[LastSchoolUnit]));

  if School.UnitQueue[1]<>ut_None then
    Button_School_UnitWIP.TexID :=140+byte(School.UnitQueue[1])
  else
    Button_School_UnitWIP.TexID :=41; //Question mark

  Button_School_UnitWIPBar.Position:=School.GetTrainingProgress;

  for i:=1 to 5 do
    if School.UnitQueue[i+1]<>ut_None then
    begin
      Button_School_UnitPlan[i].TexID:=140+byte(School.UnitQueue[i+1]);
      Button_School_UnitPlan[i].Hint:=TypeToString(School.UnitQueue[i+1]);
    end
    else
    begin
      Button_School_UnitPlan[i].TexID:=0;
      Button_School_UnitPlan[i].Hint:='';
    end;

  Button_School_Train.Enabled := School.UnitQueue[length(School.UnitQueue)]=ut_None;
  Button_School_Left.Enabled := LastSchoolUnit > 1;
  Button_School_Right.Enabled := LastSchoolUnit < length(School_Order);
  Image_School_Left.Visible:= Button_School_Left.Enabled;
  Image_School_Right.Visible:= Button_School_Right.Enabled;

  if Button_School_Left.Enabled then
    Image_School_Left.TexID:=520+byte(School_Order[LastSchoolUnit-1]);

  Label_School_Unit.Caption:=TypeToString(School_Order[LastSchoolUnit]);
  Image_School_Train.TexID:=520+byte(School_Order[LastSchoolUnit]);

  if Button_School_Right.Enabled then
    Image_School_Right.TexID:=520+byte(School_Order[LastSchoolUnit+1]);
end;


{Process click on Remove-from-queue buttons of School}
procedure TKMGamePlayInterface.House_SchoolUnitRemove(Sender:TObject);
begin
  if not (TKMControl(Sender).Tag in [1..6]) then exit;
  fGame.fGameInputProcess.CmdHouse(gic_HouseRemoveTrain, TKMHouseSchool(fPlayers.Selected), TKMControl(Sender).Tag);
  House_SchoolUnitChange(nil, mbLeft);
end;


{That small red triangle blocking delivery of goods to Storehouse}
{Resource determined by Button.Tag property}
procedure TKMGamePlayInterface.House_StoreAcceptFlag(Sender:TObject);
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMHouseStore) then exit;
  fGame.fGameInputProcess.CmdHouse(gic_HouseStoreAcceptFlag, TKMHouse(fPlayers.Selected), TResourceType((Sender as TKMControl).Tag));
end;


procedure TKMGamePlayInterface.Menu_Settings_Fill;
begin
  Ratio_Settings_Brightness.Position    := fGame.GlobalSettings.Brightness;
  CheckBox_Settings_Autosave.Checked    := fGame.GlobalSettings.Autosave;
  CheckBox_Settings_FastScroll.Checked  := fGame.GlobalSettings.FastScroll;
  Ratio_Settings_Mouse.Position         := fGame.GlobalSettings.MouseSpeed;
  Ratio_Settings_SFX.Position           := fGame.GlobalSettings.SoundFXVolume;
  Ratio_Settings_Music.Position         := fGame.GlobalSettings.MusicVolume;
  CheckBox_Settings_MusicOn.Checked     := not fGame.GlobalSettings.MusicOn;
  
  Ratio_Settings_Music.Enabled := not CheckBox_Settings_MusicOn.Checked;
end;


procedure TKMGamePlayInterface.Menu_Settings_Change(Sender:TObject);
begin
  fGame.GlobalSettings.Brightness    := Ratio_Settings_Brightness.Position;
  fGame.GlobalSettings.Autosave      := CheckBox_Settings_Autosave.Checked;
  fGame.GlobalSettings.FastScroll    := CheckBox_Settings_FastScroll.Checked;
  fGame.GlobalSettings.MouseSpeed    := Ratio_Settings_Mouse.Position;
  fGame.GlobalSettings.SoundFXVolume := Ratio_Settings_SFX.Position;
  fGame.GlobalSettings.MusicVolume   := Ratio_Settings_Music.Position;
  fGame.GlobalSettings.MusicOn       := not CheckBox_Settings_MusicOn.Checked;

  Ratio_Settings_Music.Enabled := not CheckBox_Settings_MusicOn.Checked;
end;


{Show list of savegames and act depending on Sender (Save or Load)}
procedure TKMGamePlayInterface.Menu_ShowLoad(Sender: TObject);
var i:integer;
begin
  for i:=1 to SAVEGAME_COUNT do begin //We can update both for simplicity
    Button_Save[i].Caption := fGame.SavegameTitle(i);
    Button_Load[i].Caption := Button_Save[i].Caption;
  end;
end;


{Quit the mission and return to main menu}
procedure TKMGamePlayInterface.Menu_QuitMission(Sender:TObject);
begin
  //Show outcome depending on actual situation. By default PlayOnState is gr_Cancel, if playing on after victory/defeat it changes
  fGame.GameStop(fGame.PlayOnState);
end;


procedure TKMGamePlayInterface.Menu_NextTrack(Sender:TObject); begin fGame.MusicLib.PlayNextTrack; end;
procedure TKMGamePlayInterface.Menu_PreviousTrack(Sender:TObject); begin fGame.MusicLib.PlayPreviousTrack; end;


procedure TKMGamePlayInterface.Army_Issue_Order(Sender:TObject);
var Commander: TKMUnitWarrior;
begin
  if fPlayers.Selected = nil then exit;
  if not (fPlayers.Selected is TKMUnitWarrior) then exit;

  Commander := TKMUnitWarrior(fPlayers.Selected).GetCommander;

  //if Sender = Button_Army_GoTo    then ; //This command makes no sense unless player has no right-mouse-button
  if Sender = Button_Army_Stop    then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyHalt, Commander, 0, 0);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_Halt);
  end;
  //if Sender = Button_Army_Attack  then ; //This command makes no sense unless player has no right-mouse-button
  if Sender = Button_Army_RotCW   then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyHalt, Commander, -1, 0);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_RotLeft);
  end;
  if Sender = Button_Army_Storm   then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyStorm, Commander);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_StormAttack);
  end;
  if Sender = Button_Army_RotCCW  then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyHalt, Commander, 1, 0);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_RotRight);
  end;
  if Sender = Button_Army_ForDown then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyHalt, Commander, 0, 1);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_Formation);
  end;
  if Sender = Button_Army_ForUp   then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyHalt, Commander, 0, -1);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_Formation);
  end;
  if Sender = Button_Army_Split   then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmySplit, Commander);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_Split);
  end;
  if Sender = Button_Army_Join    then
  begin
    Panel_Army.Hide;
    Panel_Army_JoinGroups.Show;
    fJoiningGroups := true;
  end;
  if Sender = Button_Army_Feed    then
  begin
    fGame.fGameInputProcess.CmdArmy(gic_ArmyFeed, Commander);
    fSoundLib.PlayWarrior(Commander.UnitType, sp_Eat);
  end;
end;


procedure TKMGamePlayInterface.Army_HideJoinMenu(Sender:TObject);
begin
  fJoiningGroups := false;
  if (Screen.Cursor = c_JoinYes) or (Screen.Cursor = c_JoinNo) then //Do not override non-joining cursors
    Screen.Cursor := c_Default; //In case this is run with keyboard shortcut, mouse move won't happen
  Panel_Army_JoinGroups.Hide;
  if fShownUnit <> nil then
    Panel_Army.Show;
end;


procedure TKMGamePlayInterface.Build_Fill(Sender:TObject);
var i:integer;
begin
  for i:=1 to HOUSE_COUNT do
  if GUIHouseOrder[i] <> ht_None then
  if MyPlayer.Stats.GetCanBuild(THouseType(byte(GUIHouseOrder[i]))) then begin
    Button_Build[i].Enable;
    Button_Build[i].TexID:=GUIBuildIcons[byte(GUIHouseOrder[i])];
    Button_Build[i].OnClick:=Build_ButtonClick;
    Button_Build[i].Hint:=TypeToString(THouseType(byte(GUIHouseOrder[i])));
  end else begin
    Button_Build[i].OnClick:=nil;
    Button_Build[i].TexID:=41;
    Button_Build[i].Hint:=fTextLibrary.GetTextString(251); //Building not available
  end;
end;


procedure TKMGamePlayInterface.Chat_Post(Sender:TObject; Key:word);
begin
  if (Key <> VK_RETURN) or (Trim(Edit_ChatMsg.Text) = '') then exit;
  fGame.Networking.PostMessage(Edit_ChatMsg.Text);
  Edit_ChatMsg.Text := '';
end;


procedure TKMGamePlayInterface.ReplayClick;
  procedure SetButtons(aPaused:boolean);
  begin
    Button_ReplayPause.Enabled := aPaused;
    Button_ReplayStep.Enabled := not aPaused;
    Button_ReplayResume.Enabled := not aPaused;
  end;
begin
  if (Sender = Button_ReplayRestart) then begin
    fGame.GameStop(gr_Silent);
    fGame.ReplayView; //reload it once again
  end;

  if (Sender = Button_ReplayPause) then begin
    fGame.SetGameState(gsPaused);
    SetButtons(false);
  end;

  if (Sender = Button_ReplayStep) then begin
    fGame.StepOneFrame;
    fGame.SetGameState(gsReplay);
    SetButtons(false);
  end;

  if (Sender = Button_ReplayResume) then begin
    fGame.SetGameState(gsReplay);
    SetButtons(true);
  end;

  if (Sender = Button_ReplayExit) then
    fGame.GameHold(true, gr_ReplayEnd);
end;


procedure TKMGamePlayInterface.MessageIssue(MsgTyp:TKMMessageType; Text:string; Loc:TKMPoint);
begin
  fMessageList.AddEntry(MsgTyp,Text,Loc);
  Message_UpdateStack;
  if fMessageList.GetMsgHasSound(fMessageList.Count) then
    fSoundLib.Play(sfx_MessageNotice,4); //Play horn sound on new message if it is the right type
end;


procedure TKMGamePlayInterface.Message_UpdateStack;
var i:integer;
begin
  //MassageList is unlimited, while Image_Message has fixed depth and samples data from the list on demand
  for i:=low(Image_Message) to high(Image_Message) do
  begin
    Image_Message[i].TexID := fMessageList.GetMsgPic(i);
    Image_Message[i].Enabled := i in [1..fMessageList.Count]; //Disable and hide at once for safety
    Image_Message[i].Visible := i in [1..fMessageList.Count];
  end;
end;


procedure TKMGamePlayInterface.Store_Fill(Sender:TObject);
var i,Tmp:integer;
begin
  if fPlayers.Selected=nil then exit;
  if not (fPlayers.Selected is TKMHouseStore) then exit;

  for i:=1 to 28 do begin
    Tmp:=TKMHouseStore(fPlayers.Selected).CheckResIn(TResourceType(i));
    if Tmp=0 then Button_Store[i].Caption:='-' else
    //if Tmp>999 then Button_Store[i].Caption:=float2fix(round(Tmp/10)/100,2)+'k' else
                  Button_Store[i].Caption:=inttostr(Tmp);
    Image_Store_Accept[i].Visible := TKMHouseStore(fPlayers.Selected).NotAcceptFlag[i];
  end;
end;


procedure TKMGamePlayInterface.Menu_Fill(Sender:TObject);
begin
  if fGame.GlobalSettings.MusicOn then
  begin
    Label_Menu_Track.Caption := fGame.MusicLib.GetTrackTitle;
    Label_Menu_Track.Enable;
    Button_Menu_TrackUp.Enable;
    Button_Menu_TrackDown.Enable;
  end
  else begin
    Label_Menu_Track.Caption := '-';
    Label_Menu_Track.Disable;
    Button_Menu_TrackUp.Disable;
    Button_Menu_TrackDown.Disable;
  end;
end;


procedure TKMGamePlayInterface.Stats_Fill(Sender:TObject);
var i,Tmp,Tmp2:integer;
begin
  for i:=low(StatHouse) to high(StatHouse) do
  begin
    Tmp := MyPlayer.Stats.GetHouseQty(StatHouse[i]);
    Tmp2 := MyPlayer.Stats.GetHouseWip(StatHouse[i]);
    if Tmp  = 0 then Stat_HouseQty[i].Caption := '-' else Stat_HouseQty[i].Caption := inttostr(Tmp);
    if Tmp2 = 0 then Stat_HouseWip[i].Caption := ''  else Stat_HouseWip[i].Caption := '+'+inttostr(Tmp2);
    if MyPlayer.Stats.GetCanBuild(StatHouse[i]) or (Tmp>0) then
    begin
      Stat_HousePic[i].TexID := byte(StatHouse[i])+300;
      Stat_HousePic[i].Hint := TypeToString(StatHouse[i]);
      Stat_HouseQty[i].Hint := TypeToString(StatHouse[i]);
    end
    else
    begin
      Stat_HousePic[i].TexID := 41;
      Stat_HousePic[i].Hint := fTextLibrary.GetTextString(251); //Building not available
      Stat_HouseQty[i].Hint := fTextLibrary.GetTextString(251); //Building not available
    end;
  end;
  for i:=low(StatUnit) to high(StatUnit) do
  begin
    Tmp := MyPlayer.Stats.GetUnitQty(StatUnit[i]);
    if Tmp = 0 then Stat_UnitQty[i].Caption := '-' else Stat_UnitQty[i].Caption := inttostr(Tmp);
    Stat_UnitPic[i].Hint := TypeToString(StatUnit[i]);
    Stat_UnitQty[i].Hint := TypeToString(StatUnit[i]);
  end;
end;


procedure TKMGamePlayInterface.Army_ActivateControls(aActive:boolean);
begin
  //Button_Army_GoTo.Enabled := aActive;
  Button_Army_Stop.Enabled := aActive;
  //Button_Army_Attack.Enabled := aActive;
  Button_Army_RotCW.Enabled := aActive;
  Button_Army_Storm.Enabled := aActive;
  Button_Army_RotCCW.Enabled := aActive;
  Button_Army_ForUp.Enabled := aActive;
  Button_Army_ForDown.Enabled := aActive;
  Button_Army_Split.Enabled := aActive;
  Button_Army_Join.Enabled := aActive;
  Button_Army_Feed.Enabled := aActive;
end;


procedure TKMGamePlayInterface.MenuIconsEnabled(NewValue:boolean);
begin
  Button_Main[1].Enabled := NewValue;
  Button_Main[2].Enabled := NewValue;
  Button_Main[3].Enabled := NewValue;
end;


procedure TKMGamePlayInterface.ShowClock(DoShow:boolean);
begin
  Image_Clock.Visible := DoShow;
  Label_Clock.Visible := DoShow;
  if DoShow then //With slow GPUs it will keep old values till next frame, that can take some seconds
    Label_Clock.Caption := int2time(fGame.GetMissionTime);
end;


procedure TKMGamePlayInterface.SetPause(aValue:boolean);
begin
  if aValue then fGame.SetGameState(gsPaused)
            else fGame.SetGameState(gsRunning);
  Panel_Pause.Visible := aValue;
end;


procedure TKMGamePlayInterface.ShowPlayMore(DoShow:boolean; Msg:TGameResultMsg);
begin
  PlayMoreMsg := Msg;
  case Msg of
    gr_Win:       begin
                    Label_PlayMore.Caption := fTextLibrary.GetRemakeString(39);
                    Button_PlayMore.Caption := fTextLibrary.GetRemakeString(40);
                    Button_PlayQuit.Caption := fTextLibrary.GetRemakeString(41);
                  end;
    gr_Defeat:    begin
                    Label_PlayMore.Caption := fTextLibrary.GetRemakeString(42);
                    Button_PlayMore.Caption := fTextLibrary.GetRemakeString(43);
                    Button_PlayQuit.Caption := fTextLibrary.GetRemakeString(44);
                  end;
    gr_ReplayEnd: begin
                    Label_PlayMore.Caption := fTextLibrary.GetRemakeString(45);
                    Button_PlayMore.Caption := fTextLibrary.GetRemakeString(46);
                    Button_PlayQuit.Caption := fTextLibrary.GetRemakeString(47);
                  end;
    else if DoShow then Assert(false,'Wrong message in ShowPlayMore'); //Can become hidden with any message
  end;
  Panel_PlayMore.Visible := DoShow;
end;


procedure TKMGamePlayInterface.PlayMoreClick(Sender:TObject);
begin
  ShowPlayMore(false,PlayMoreMsg); //Hide anyways

  if Sender = Button_PlayQuit then
    case PlayMoreMsg of
      gr_Win:       fGame.GameStop(gr_Win);
      gr_Defeat:    fGame.GameStop(gr_Defeat);
      gr_ReplayEnd: fGame.GameStop(gr_ReplayEnd);
    end
  else //GameStop has Destroyed our Sender by now
  if Sender = Button_PlayMore then
    case PlayMoreMsg of
      gr_Win:       begin MyPlayer.SkipWinConditionCheck; fGame.GameHold(false, gr_Win); end;
      gr_Defeat:    begin MyPlayer.SkipDefeatConditionCheck; fGame.GameHold(false, gr_Defeat); end;
      gr_ReplayEnd: begin fGame.SkipReplayEndCheck := true; fGame.GameHold(false, gr_ReplayEnd); end;
    end;
end;


procedure TKMGamePlayInterface.ShowDirectionCursor(Show:boolean; const aX: integer = 0; const aY: integer = 0; const Dir: TKMDirection = dir_NA);
begin
  Image_DirectionCursor.Visible := Show;
  if not Show then exit;
  Image_DirectionCursor.Left := aX+RXData[Image_DirectionCursor.RXid].Pivot[TKMCursorDirections[Dir]].x;
  Image_DirectionCursor.Top  := aY+RXData[Image_DirectionCursor.RXid].Pivot[TKMCursorDirections[Dir]].y;
  Image_DirectionCursor.TexID := TKMCursorDirections[Dir];
end;


procedure TKMGamePlayInterface.ClearShownUnit;
begin
  fShownUnit := nil;
  SwitchPage(nil);
end;


procedure TKMGamePlayInterface.KeyDown(Key:Word; Shift: TShiftState);
begin
  if fGame.GameState in [gsRunning, gsReplay] then
  begin
    if (fGame.GameState = gsRunning) and MyControls.KeyDown(Key, Shift) then
      Exit;
    if Key = VK_LEFT  then fViewport.ScrollKeyLeft  := true;
    if Key = VK_RIGHT then fViewport.ScrollKeyRight := true;
    if Key = VK_UP    then fViewport.ScrollKeyUp    := true;
    if Key = VK_DOWN  then fViewport.ScrollKeyDown  := true;
  end;
end;


procedure TKMGamePlayInterface.KeyPress(Key: Char);
begin
  MyControls.KeyPress(Key);
end;


//Note: we deliberately don't pass any Keys to MyControls when game is not running
//thats why MyControls.KeyUp is only in gsRunning clause
//Ignore all keys if game is on 'Pause'
procedure TKMGamePlayInterface.KeyUp(Key:Word; Shift: TShiftState);
begin
  case fGame.GameState of
    gsPaused:   if (Key = ord('P')) and not fGame.MultiplayerMode then SetPause(false);
    gsOnHold:   ; //Ignore all keys if game is on victory 'Hold', only accept mouse clicks
    gsRunning:  begin //Game is running normally
                  if MyControls.KeyUp(Key, Shift) then Exit;

                  //Scrolling
                  if Key = VK_LEFT  then fViewport.ScrollKeyLeft  := false;
                  if Key = VK_RIGHT then fViewport.ScrollKeyRight := false;
                  if Key = VK_UP    then fViewport.ScrollKeyUp    := false;
                  if Key = VK_DOWN  then fViewport.ScrollKeyDown  := false;

                  if Key = VK_BACK then  fViewport.SetZoom(1);
                  //Game speed
                  if (Key = VK_F8) and not fGame.MultiplayerMode then fGame.SetGameSpeed; //Speed will toggle automatically
                  if (Key = ord('P')) and not fGame.MultiplayerMode then SetPause(true); //Display pause overlay

                  //Menu shortcuts
                  if Key in [ord('1')..ord('4')] then Button_Main[Key-48].DoClick;
                  if Key=VK_ESCAPE then if Button_Army_Join_Cancel.DoClick then exit
                                        else if Button_MessageClose.DoClick then exit
                                        else if Button_Main[5].DoClick then exit;
                  //Messages
                  if Key=VK_SPACE  then Button_MessageGoTo.DoClick; //In KaM spacebar centers you on the message
                  if Key=VK_DELETE then Button_MessageDelete.DoClick;

                  //Army shortcuts from KaM. (these are also in hints) Can be improved/changed later if we want to
                  if (Key = ord('A')) and (Panel_Army.Visible) then Button_Army_Attack.DoClick;
                  if (Key = ord('D')) and (Panel_Army.Visible) then Button_Army_GoTo.DoClick;
                  if (Key = ord('H')) and (Panel_Army.Visible) then Button_Army_Stop.DoClick;
                  if (Key = ord('L')) and (Panel_Army.Visible) then Button_Army_Join.DoClick;
                  if (Key = ord('S')) and (Panel_Army.Visible) then Button_Army_Split.DoClick;

                  {Thats my debug example}
                  if Key=ord('5') then MessageIssue(msgText,'123',KMPoint(0,0));
                  if Key=ord('6') then MessageIssue(msgHouse,'123',KMPointRound(fViewport.GetCenter));
                  if Key=ord('7') then MessageIssue(msgUnit,'123',KMPoint(0,0));
                  if Key=ord('8') then MessageIssue(msgHorn,'123',KMPoint(0,0));
                  if Key=ord('9') then MessageIssue(msgQuill,'123',KMPoint(0,0));
                  if Key=ord('0') then MessageIssue(msgScroll,'123',KMPoint(0,0));

                  {Temporary cheat codes}
                  if Key=ord('W') then fGame.fGameInputProcess.CmdTemp(gic_TempRevealMap);
                  if (Key=ord('V')) and not fGame.MultiplayerMode then begin fGame.GameHold(true, gr_Win); exit; end; //Instant victory
                  if (Key=ord('D')) and not fGame.MultiplayerMode then begin fGame.GameHold(true, gr_Defeat); exit; end; //Instant defeat
                  if (Key=ord('Q')) and not fGame.MultiplayerMode then fGame.fGameInputProcess.CmdTemp(gic_TempAddScout, GameCursor.Cell);

                end;
    gsReplay:   begin
                  //Scrolling
                  if Key = VK_LEFT  then fViewport.ScrollKeyLeft  := false;
                  if Key = VK_RIGHT then fViewport.ScrollKeyRight := false;
                  if Key = VK_UP    then fViewport.ScrollKeyUp    := false;
                  if Key = VK_DOWN  then fViewport.ScrollKeyDown  := false;

                  if Key = VK_BACK then fViewport.SetZoom(1);
                  if Key = VK_F8 then   fGame.SetGameSpeed; //Speed will toggle automatically
                end;
   end;
end;


//1. Process Controls
//2. Show SelectingTroopDirection
procedure TKMGamePlayInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var U:TKMUnit; MyRect:TRect;
begin
  MyControls.MouseDown(X,Y,Shift,Button);
  if (fGame.GameState <> gsRunning) or (MyControls.CtrlOver <> nil) then exit;

  if SelectingTroopDirection then
  begin
    Form1.ApplyCursorRestriction; //Reset the cursor restrictions from selecting direction
    SelectingTroopDirection := false;
    ShowDirectionCursor(false);
  end;

  //See if we can show DirectionSelector
  //Can walk to ally units place, can't walk to house place anyway
  if (Button = mbRight) and (not fJoiningGroups) and(fShownUnit is TKMUnitWarrior)
    and(fShownUnit.GetOwner = MyPlayer.PlayerID) then
  begin
    U := fTerrain.UnitsHitTest(GameCursor.Cell.X, GameCursor.Cell.Y);
    if ((U = nil) or (fPlayers.CheckAlliance(MyPlayer.PlayerID, U.GetOwner) = at_Ally)) and
      fTerrain.Route_CanBeMade(fShownUnit.GetPosition, GameCursor.Cell, CanWalk, 0, false) then
    begin
      SelectingTroopDirection := true; //MouseMove will take care of cursor changing
      //Record current cursor position so we can stop it from moving while we are setting direction
      GetCursorPos(SelectingDirPosition); //First record it in referance to the screen pos for the clipcursor function
      //Restrict cursor to a rectangle (half a rect in both axes)
      MyRect.Left   := SelectingDirPosition.X-((DirCursorSqrSize-1) div 2);
      MyRect.Top    := SelectingDirPosition.Y-((DirCursorSqrSize-1) div 2);
      MyRect.Right  := SelectingDirPosition.X+((DirCursorSqrSize-1) div 2)+1;
      MyRect.Bottom := SelectingDirPosition.Y+((DirCursorSqrSize-1) div 2)+1;
      {$IFDEF MSWindows}
      ClipCursor(@MyRect);
      {$ENDIF}
      //Now record it as Client XY
      SelectingDirPosition.X := X;
      SelectingDirPosition.Y := Y;
      SelectedDirection := dir_NA;
      ShowDirectionCursor(true,X,Y,SelectedDirection);
      Screen.Cursor := c_Invisible;
    end;
  end;
end;


//1. Process Controls
//2. Perform SelectingTroopDirection if it is active
//3. Display various cursors depending on whats below (might be called often)
procedure TKMGamePlayInterface.MouseMove(Shift: TShiftState; X,Y: Integer);
var DeltaX,DeltaY:integer; U:TKMUnit; H:TKMHouse;
begin
  MyControls.MouseMove(X,Y,Shift);

  if (MyControls.CtrlOver <> nil) and (MyControls.CtrlOver <> Image_DirectionCursor) then
  begin
    Screen.Cursor := c_Default;
    exit;
  end;

  if fGame.GameState = gsReplay then
    fTerrain.ComputeCursorPosition(X,Y,Shift); //To show coords in status bar

  if (fGame.GameState <> gsRunning) then exit;

  if SelectingTroopDirection then
  begin
    DeltaX := SelectingDirPosition.X - X;
    DeltaY := SelectingDirPosition.Y - Y;
    //Compare cursor position and decide which direction it is
    SelectedDirection := KMGetCursorDirection(DeltaX, DeltaY);
    //Update the cursor based on this direction and negate the offset
    ShowDirectionCursor(true,X+DeltaX,Y+DeltaY,SelectedDirection);
    Screen.Cursor := c_Invisible; //Keep it invisible, just in case
    exit;
  end;

  fTerrain.ComputeCursorPosition(X,Y,Shift);

  if GameCursor.Mode<>cm_None then exit;

  if fJoiningGroups and (fShownUnit is TKMUnitWarrior) then
  begin
    U := MyPlayer.UnitsHitTest(GameCursor.Cell.X, GameCursor.Cell.Y); //Scan only teammates
    if (U <> nil) and (U is TKMUnitWarrior) and
       (not TKMUnitWarrior(U).IsSameGroup(TKMUnitWarrior(fShownUnit))) and
       (UnitGroups[byte(U.UnitType)] = UnitGroups[byte(fShownUnit.UnitType)]) then
      Screen.Cursor := c_JoinYes
    else
      Screen.Cursor := c_JoinNo;
    exit;
  end;

  if (MyPlayer.HousesHitTest(GameCursor.Cell.X, GameCursor.Cell.Y)<>nil)or
     (MyPlayer.UnitsHitTest(GameCursor.Cell.X, GameCursor.Cell.Y)<>nil) then begin
    Screen.Cursor := c_Info;
    exit;
  end;

  if fShownUnit is TKMUnitWarrior then
  begin
    if (MyPlayer.FogOfWar.CheckTileRevelation(GameCursor.Cell.X, GameCursor.Cell.Y)>0) then
    begin
      U := fTerrain.UnitsHitTest (GameCursor.Cell.X, GameCursor.Cell.Y);
      H := fPlayers.HousesHitTest(GameCursor.Cell.X, GameCursor.Cell.Y);
      if ((U<>nil) and (fPlayers.CheckAlliance(MyPlayer.PlayerID, U.GetOwner) = at_Enemy)) or
         ((H<>nil) and (fPlayers.CheckAlliance(MyPlayer.PlayerID, H.GetOwner) = at_Enemy)) then
        Screen.Cursor := c_Attack
      else
      if not fViewport.Scrolling then
        Screen.Cursor := c_Default;
    end;
    exit;
  end;

  if not fViewport.Scrolling then
    Screen.Cursor := c_Default;
end;


procedure TKMGamePlayInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var P:TKMPoint; U:TKMUnit; H:TKMHouse; OldSelected: TObject;
begin
  if (MyControls.CtrlOver <> nil) and (MyControls.CtrlOver <> Image_DirectionCursor) then begin
    MyControls.MouseUp(X,Y,Shift,Button);
    exit;
  end;

  if fGame.GameState <> gsRunning then exit;

  P := GameCursor.Cell; //It's used in many places here

  if (Button = mbMiddle) then
    fGame.fGameInputProcess.CmdTemp(gic_TempAddScout, P);

  //Select direction
  if (Button = mbRight) and SelectingTroopDirection then
  begin
    //Reset the cursor position as it will have moved during direction selection
    SetCursorPos(Form1.Panel5.ClientToScreen(SelectingDirPosition).X,Form1.Panel5.ClientToScreen(SelectingDirPosition).Y);
    Form1.ApplyCursorRestriction; //Reset the cursor restrictions from selecting direction
    SelectingTroopDirection := false; //As soon as mouse is released
    Screen.Cursor := c_Default; //Reset direction selecting cursor cursor when mouse released
    ShowDirectionCursor(false);
  end;

  //Attack or Walk
  if (Button = mbRight) and (not fJoiningGroups) and(fShownUnit is TKMUnitWarrior)
    and TKMUnitWarrior(fShownUnit).GetCommander.ArmyCanTakeOrders //Can't give orders to busy warriors
    and(fShownUnit.GetOwner = MyPlayer.PlayerID) then
  begin
    //Try to Attack unit
    U := fTerrain.UnitsHitTest(P.X, P.Y);
    if (U <> nil) and (not U.IsDeadOrDying) and
    (fPlayers.CheckAlliance(MyPlayer.PlayerID, U.GetOwner) = at_Enemy) then
      fGame.fGameInputProcess.CmdArmy(gic_ArmyAttackUnit, TKMUnitWarrior(fShownUnit).GetCommander, U)
    else
    begin //If there's no unit - try to Attack house
      H := fPlayers.HousesHitTest(P.X, P.Y);
      if (H <> nil) and (not H.IsDestroyed) and
      (fPlayers.CheckAlliance(MyPlayer.PlayerID, H.GetOwner) = at_Enemy) then
        fGame.fGameInputProcess.CmdArmy(gic_ArmyAttackHouse, TKMUnitWarrior(fShownUnit).GetCommander, H)
      else //If there's no house - Walk to spot
        if fTerrain.Route_CanBeMade(fShownUnit.GetPosition, P, CanWalk, 0, false) then
          fGame.fGameInputProcess.CmdArmy(gic_ArmyWalk, TKMUnitWarrior(fShownUnit), P, SelectedDirection);
    end;
  end;

  //Cancel join
  if (Button = mbRight) then begin
    if Panel_Build.Visible then
      SwitchPage(Button_Main[5]);
    if fJoiningGroups then
      Army_HideJoinMenu(nil);
  end;

  if Button = mbLeft then
  if fJoiningGroups and (fShownUnit <> nil) and (fShownUnit is TKMUnitWarrior) then
  begin
    U  := MyPlayer.UnitsHitTest(P.X, P.Y); //Scan only teammates
    if (U <> nil) and (U is TKMUnitWarrior) and
       (not TKMUnitWarrior(U).IsSameGroup(TKMUnitWarrior(fShownUnit))) and
       (UnitGroups[byte(U.UnitType)] = UnitGroups[byte(fShownUnit.UnitType)]) then
    begin
      fGame.fGameInputProcess.CmdArmy(gic_ArmyLink, TKMUnitWarrior(fShownUnit), U);
      Army_HideJoinMenu(nil);
    end;
    exit;
  end;

  if Button = mbLeft then //Only allow placing of roads etc. with the left mouse button
  case GameCursor.Mode of
    cm_None:  begin
                //You cannot select nil (or unit/house from other team) simply by clicking on the terrain
                OldSelected := fPlayers.Selected;
                if (not fPlayers.HitTest(P.X, P.Y)) or
                  ((fPlayers.Selected is TKMHouse) and (TKMHouse(fPlayers.Selected).GetOwner <> MyPlayer.PlayerID))or
                  ((fPlayers.Selected is TKMUnit) and (TKMUnit(fPlayers.Selected).GetOwner <> MyPlayer.PlayerID)) then
                  fPlayers.Selected := OldSelected;

                if (fPlayers.Selected is TKMHouse) then
                  ShowHouseInfo(TKMHouse(fPlayers.Selected));

                if (fPlayers.Selected is TKMUnit) then begin
                  ShowUnitInfo(TKMUnit(fPlayers.Selected));
                  if (fPlayers.Selected is TKMUnitWarrior) and (OldSelected <> fPlayers.Selected) then
                    fSoundLib.PlayWarrior(TKMUnit(fPlayers.Selected).UnitType, sp_Select);
                end;
              end;
    cm_Road:  if fTerrain.Land[P.Y,P.X].Markup = mu_RoadPlan then
                fGame.fGameInputProcess.CmdBuild(gic_BuildRemovePlan, P)
              else
                fGame.fGameInputProcess.CmdBuild(gic_BuildRoadPlan, P);
    cm_Field: if fTerrain.Land[P.Y,P.X].Markup = mu_FieldPlan then
                fGame.fGameInputProcess.CmdBuild(gic_BuildRemovePlan, P)
              else
                fGame.fGameInputProcess.CmdBuild(gic_BuildFieldPlan, P);
    cm_Wine:  if fTerrain.Land[P.Y,P.X].Markup = mu_WinePlan then
                fGame.fGameInputProcess.CmdBuild(gic_BuildRemovePlan, P)
              else
                fGame.fGameInputProcess.CmdBuild(gic_BuildWinePlan, P);
    cm_Wall:  if fTerrain.Land[P.Y,P.X].Markup = mu_WallPlan then
                fGame.fGameInputProcess.CmdBuild(gic_BuildRemovePlan, P)
              else
                fGame.fGameInputProcess.CmdBuild(gic_BuildWallPlan, P);
    cm_Houses:if fTerrain.CanPlaceHouse(P, THouseType(GameCursor.Tag1), MyPlayer) then begin
                fGame.fGameInputProcess.CmdBuild(gic_BuildHousePlan, P, THouseType(GameCursor.Tag1));
                fSoundLib.Play(sfx_placemarker);
                Build_ButtonClick(Button_BuildRoad);
              end else
                fSoundLib.Play(sfx_CantPlace,P,false,4.0);
    cm_Erase: begin
                fPlayers.Selected := MyPlayer.HousesHitTest(P.X, P.Y); //Select the house irregardless of unit below/above
                if MyPlayer.RemHouse(P,false,true) then //Ask wherever player wants to destroy own house
                begin
                  //don't ask about houses that are not started, they are removed below
                  if TKMHouse(fPlayers.Selected).BuildingState <> hbs_Glyph then
                  begin
                    ShowHouseInfo(TKMHouse(fPlayers.Selected),true);
                    fSoundLib.Play(sfx_Click);
                  end;
                end;
                if (not MyPlayer.RemPlan(P)) and (not MyPlayer.RemHouse(P,false,true)) then
                  fSoundLib.Play(sfx_CantPlace,P,false,4.0); //Otherwise there is nothing to erase
                //Now remove houses that are not started
                if MyPlayer.RemHouse(P,false,true) and (TKMHouse(fPlayers.Selected).BuildingState = hbs_Glyph) then
                begin
                  fGame.fGameInputProcess.CmdBuild(gic_BuildRemoveHouse, P);
                  fSoundLib.Play(sfx_Click);
                end;
              end;
  end;
end;


//e.g. if we're over a scrollbar it shouldn't zoom map,
//but this can apply for all controls (i.e. only zoom when over the map not controls)
procedure TKMGamePlayInterface.MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer);
var PrevCursor, ViewCenter: TKMPointF;
begin
  MyControls.MouseWheel(X, Y, WheelDelta);
  if (X < 0) or (Y < 0) then exit; //This occours when you use the mouse wheel on the window frame
  if MOUSEWHEEL_ZOOM_ENABLE and (MyControls.CtrlOver = nil) and (fGame.GameState in [gsReplay,gsRunning]) then
  begin
    fTerrain.ComputeCursorPosition(X, Y, Shift); //Make sure we have the correct cursor position to begin with
    PrevCursor := GameCursor.Float;
    fViewport.SetZoom(fViewport.Zoom+WheelDelta/2000);
    fTerrain.ComputeCursorPosition(X, Y, Shift); //Zooming changes the cursor position
    //Move the center of the screen so the cursor stays on the same tile, thus pivoting the zoom around the cursor
    ViewCenter := fViewport.GetCenter; //Required for Linux compatibility
    fViewport.SetCenter(ViewCenter.X + PrevCursor.X-GameCursor.Float.X,
                        ViewCenter.Y + PrevCursor.Y-GameCursor.Float.Y);
    fTerrain.ComputeCursorPosition(X, Y, Shift); //Recentering the map changes the cursor position
  end;
end;


procedure TKMGamePlayInterface.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(LastSchoolUnit);
  SaveStream.Write(LastBarracksUnit);
  fMessageList.Save(SaveStream);
  //Everything else (e.g. ShownUnit or AskDemolish) can't be seen in Save_menu anyways
end;


procedure TKMGamePlayInterface.Load(LoadStream:TKMemoryStream);
begin
  LoadStream.Read(LastSchoolUnit);
  LoadStream.Read(LastBarracksUnit);
  fMessageList.Load(LoadStream);
  //Everything else (e.g. ShownUnit or AskDemolish) can't be seen in Save_menu anyways
  Message_UpdateStack;
  fLog.AppendLog('Interface loaded');
end;


{Should update any items changed by game (resource counts, hp, etc..)}
{If it ever gets a bottleneck then some static Controls may be excluded from update}
procedure TKMGamePlayInterface.UpdateState;
begin
  if fShownUnit<>nil then ShowUnitInfo(fShownUnit) else
  if fShownHouse<>nil then ShowHouseInfo(fShownHouse,AskDemolish);

  if fShownUnit=nil then fJoiningGroups := false;

  if fGame.fGameInputProcess.ReplayState = gipReplaying then begin
    Panel_Replay.Show;
    PercentBar_Replay.Position := EnsureRange(round(fGame.GameTickCount / fGame.fGameInputProcess.GetLastTick * 100), 0, 100);
    Label_Replay.Caption := Format('%d / %d', [fGame.GameTickCount div 10, fGame.fGameInputProcess.GetLastTick div 10]);
  end else
    Panel_Replay.Hide;

  Minimap_Update(nil);
  if Image_Clock.Visible then begin
    Image_Clock.TexID := ((Image_Clock.TexID-556)+1)mod 16 +556;
    Label_Clock.Caption := int2time(fGame.GetMissionTime);
  end;

  if Panel_Build.Visible then Build_Fill(nil);
  if Panel_Stats.Visible then Stats_Fill(nil);
  if Panel_Menu.Visible then Menu_Fill(nil);

  if Panel_Chat.Visible then begin
    //todo: Change this to TKMMemo that will scroll and cut older messages automatically
    //Label_ChatText.Caption := Label_ChatText.Caption + fGame.fChat.GetNewMessages;
  end;

  if SHOW_SPRITE_COUNT then
  Label_Stat.Caption:=
        inttostr(fPlayers.GetUnitCount)+' units on map'+#124+
        inttostr(fRender.Stat_Sprites)+'/'+inttostr(fRender.Stat_Sprites2)+' sprites/rendered'+#124+
        inttostr(CtrlPaintCount)+' controls rendered';

  if SHOW_POINTER_COUNT then
    Label_PointerCount.Caption := Format('Pointers: %d units, %d houses', [MyPlayer.Units.GetTotalPointers, MyPlayer.Houses.GetTotalPointers]);

  if SHOW_CMDQUEUE_COUNT then
    Label_CmdQueueCount.Caption := inttostr(fGame.fGameInputProcess.Count)+' commands stored';

  if DISPLAY_SOUNDS then
    Label_SoundsCount.Caption := inttostr(fSoundLib.ActiveCount)+' sounds playing';
end;


procedure TKMGamePlayInterface.Paint;
begin
  MyControls.Paint;
end;


end.
