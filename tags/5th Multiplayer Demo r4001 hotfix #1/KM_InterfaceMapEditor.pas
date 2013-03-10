unit KM_InterfaceMapEditor;
{$I KaM_Remake.inc}
interface
uses
     {$IFDEF MSWindows} Windows, {$ENDIF}
     {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
     Classes, Controls, KromUtils, Math, StrUtils, SysUtils, KromOGLUtils, TypInfo,
     KM_Controls, KM_Defaults, KM_Pics, KM_Maps, KM_Houses, KM_Units,
     KM_Points, KM_InterfaceDefaults, KM_Terrain;

type
  TKMVillageTab = (vtHouses, vtUnits, vtScript, vtDefences);

type
  TKMapEdInterface = class (TKMUserInterface)
  private
    fPrevHint: TObject;
    fStorehouseItem: Byte; //Selected ware in storehouse
    fBarracksItem: Byte; //Selected ware in barracks
    fTileDirection: Byte;
    //fShowRawMaterials: Boolean; //Not sure how we will enable this and blocked tiles display

    fMaps: TKMapsCollection;
    fMapsMP: TKMapsCollection;

    procedure Create_Terrain_Page;
    procedure Create_Village_Page;
    procedure Create_Player_Page;
    procedure Create_Mission_Page;
    procedure Create_Menu_Page;
    procedure Create_MenuSave_Page;
    procedure Create_MenuLoad_Page;
    procedure Create_MenuQuit_Page;
    procedure Create_Unit_Page;
    procedure Create_House_Page;
    procedure Create_Store_Page;
    procedure Create_Barracks_Page;

    procedure SwitchPage(Sender: TObject);
    procedure DisplayHint(Sender: TObject);
    procedure Minimap_Update(Sender: TObject; const X,Y: Integer);

    procedure Menu_Save(Sender:TObject);
    procedure Menu_Load(Sender:TObject);
    procedure Menu_QuitMission(Sender:TObject);
    procedure Load_MapTypeChange(Sender:TObject);
    procedure Load_MapListUpdate;
    procedure Load_MapListUpdateDone(Sender: TObject);
    procedure Terrain_HeightChange(Sender: TObject);
    procedure Terrain_TilesChange(Sender: TObject);
    procedure Terrain_ObjectsChange(Sender: TObject);
    procedure Build_ButtonClick(Sender: TObject);
    procedure Defence_FillList;
    procedure Defence_ItemClicked(Sender: TObject);
    procedure House_HealthChange(Sender: TObject; AButton: TMouseButton);
    procedure Unit_ButtonClick(Sender: TObject);
    procedure Unit_ArmyChange1(Sender: TObject); overload;
    procedure Unit_ArmyChange2(Sender: TObject; AButton: TMouseButton); overload;
    procedure Barracks_Fill(Sender:TObject);
    procedure Barracks_SelectWare(Sender:TObject);
    procedure Barracks_EditWareCount(Sender:TObject; AButton:TMouseButton);
    procedure Store_Fill(Sender:TObject);
    procedure Store_SelectWare(Sender:TObject);
    procedure Store_EditWareCount(Sender:TObject; AButton:TMouseButton);
    procedure Player_ChangeActive(Sender: TObject);
    procedure SetActivePlayer(aIndex: TPlayerIndex);
    procedure SetTileDirection(aTileDirection: byte);
    procedure Player_ColorClick(Sender:TObject);
    procedure Player_BlockRefresh;
    procedure Player_BlockClick(Sender:TObject);
    procedure Mission_AlliancesChange(Sender:TObject);
    procedure Mission_PlayerTypesChange(Sender:TObject);
    procedure View_Passability(Sender:TObject);

    function GetSelectedTile: TObject;
    function GetSelectedObject: TObject;
    function GetSelectedUnit: TObject;
  protected
    Panel_Main:TKMPanel;
      MinimapView: TKMMinimapView;
      Label_Coordinates:TKMLabel;
      TrackBar_Passability:TKMTrackBar;
      Label_Passability:TKMLabel;
      Button_PlayerSelect:array[0..MAX_PLAYERS-1]of TKMFlatButtonShape; //Animals are common for all
      Label_Stat,Label_Hint:TKMLabel;
      Label_MatAmount: TKMLabel;
      Shape_MatAmount: TKMShape;
      Label_DefenceID: TKMLabel;
      Label_DefencePos: TKMLabel;
      Shape_DefencePos: TKMShape;

    Panel_Common:TKMPanel;
      Button_Main:array[1..5]of TKMButton; //5 buttons
      Label_MenuTitle: TKMLabel; //Displays the title of the current menu below
      Label_MissionName: TKMLabel;

    Panel_Terrain:TKMPanel;
      Button_Terrain:array[1..4]of TKMButton;
      Panel_Brushes:TKMPanel;
        BrushSize:TKMTrackBar;
        BrushCircle,BrushSquare:TKMButtonFlat;
        //BrushesTable:array[1..27] of TKMButtonFlat; // todo
      Panel_Heights:TKMPanel;
        HeightSize,HeightShape:TKMTrackBar;
        HeightCircle,HeightSquare:TKMButtonFlat;
        HeightElevate, HeightUnequalize: TKMButtonFlat;
      Panel_Tiles:TKMPanel;
        TilesTable:array[1..MAPED_TILES_COLS*MAPED_TILES_ROWS] of TKMButtonFlat; //how many are visible?
        TilesScroll:TKMScrollBar;
        TilesRandom:TKMCheckBox;
      Panel_Objects:TKMPanel;
        ObjectErase:TKMButtonFlat;
        ObjectsTable:array[0..8] of TKMButtonFlat;
        ObjectsScroll:TKMScrollBar;

    Panel_Village: TKMPanel;
      Button_Village: array [TKMVillageTab] of TKMButton;
      Panel_Build: TKMPanel;
        Button_BuildRoad,Button_BuildField,Button_BuildWine,Button_BuildCancel: TKMButtonFlat;
        Button_Build: array [1..GUI_HOUSE_COUNT] of TKMButtonFlat;
      Panel_Units:TKMPanel;
        Button_UnitCancel:TKMButtonFlat;
        Button_Citizen:array[0..13]of TKMButtonFlat;
        Button_Warriors:array[0..13]of TKMButtonFlat;
        Button_Animals:array[0..7]of TKMButtonFlat;
      Panel_Script: TKMPanel;
      Panel_Defence: TKMPanel;
        List_Defences: TKMListBox;

    Panel_Player:TKMPanel;
      Button_Player:array[1..3]of TKMButton;
      Panel_Goals:TKMPanel;
      Panel_Color:TKMPanel;
        ColorSwatch_Color:TKMColorSwatch;
      Panel_Block: TKMPanel;
        Button_BlockHouse: array [1 .. GUI_HOUSE_COUNT] of TKMButtonFlat;
        Image_BlockHouse: array [1 .. GUI_HOUSE_COUNT] of TKMImage;

    Panel_Mission:TKMPanel;
      Button_Mission:array[1..2]of TKMButton;
      Panel_Alliances:TKMPanel;
        CheckBox_Alliances: array[0..MAX_PLAYERS-1,0..MAX_PLAYERS-1] of TKMCheckBox;
        CheckBox_AlliancesSym:TKMCheckBox;
      Panel_PlayerTypes:TKMPanel;
        CheckBox_PlayerTypes: array[0..MAX_PLAYERS-1,0..1] of TKMCheckBox;

    Panel_Menu:TKMPanel;
      Button_Menu_Save,Button_Menu_Load,Button_Menu_Settings,Button_Menu_Quit:TKMButton;

      Panel_Save:TKMPanel;
        Radio_Save_MapType:TKMRadioGroup;
        Edit_SaveName:TKMEdit;
        Label_SaveExists:TKMLabel;
        CheckBox_SaveExists:TKMCheckBox;
        Button_SaveSave:TKMButton;
        Button_SaveCancel:TKMButton;

      Panel_Load:TKMPanel;
        Radio_Load_MapType:TKMRadioGroup;
        ListBox_Load:TKMListBox;
        Button_LoadLoad:TKMButton;
        Button_LoadCancel:TKMButton;

      Panel_Quit:TKMPanel;
        Button_Quit_Yes,Button_Quit_No:TKMButton;

    Panel_Unit:TKMPanel;
      Label_UnitName:TKMLabel;
      Label_UnitCondition:TKMLabel;
      Label_UnitDescription:TKMLabel;
      KMConditionBar_Unit:TKMPercentBar;
      Image_UnitPic:TKMImage;

      Panel_Army:TKMPanel;
        Button_Army_RotCW,Button_Army_RotCCW: TKMButton;
        Button_Army_ForUp,Button_Army_ForDown: TKMButton;
        ImageStack_Army: TKMImageStack;
        Label_ArmyCount: TKMLabel;
        Button_ArmyDec,Button_ArmyFood,Button_ArmyInc: TKMButton;

    Panel_House:TKMPanel;
      Label_House:TKMLabel;
      Image_House_Logo,Image_House_Worker:TKMImage;
      Label_HouseHealth:TKMLabel;
      KMHealthBar_House:TKMPercentBar;
      Button_HouseHealthDec,Button_HouseHealthInc:TKMButton;

    Panel_HouseStore:TKMPanel;
      Button_Store:array[1..STORE_RES_COUNT]of TKMButtonFlat;
      Label_Store_WareCount:TKMLabel;
      Button_StoreDec100,Button_StoreDec:TKMButton;
      Button_StoreInc100,Button_StoreInc:TKMButton;
    Panel_HouseBarracks:TKMPanel;
      Button_Barracks:array[1..BARRACKS_RES_COUNT]of TKMButtonFlat;
      Label_Barracks_WareCount:TKMLabel;
      Button_BarracksDec100,Button_BarracksDec:TKMButton;
      Button_BarracksInc100,Button_BarracksInc:TKMButton;
  public
    constructor Create(aScreenX, aScreenY: word);
    destructor Destroy; override;
    procedure Player_UpdateColors;
    procedure ShowHouseInfo(Sender:TKMHouse);
    procedure ShowUnitInfo(Sender:TKMUnit);
    procedure SetMinimap;
    procedure SetMapName(const aName:string);
    procedure RightClick_Cancel;
    function GetShownPage: TKMMapEdShownPage;
    procedure SetLoadMode(aMultiplayer:boolean);

    procedure KeyDown(Key:Word; Shift: TShiftState); override;
    procedure KeyUp(Key:Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;

    procedure Resize(X,Y: Word); override;
    procedure UpdateState(aTickCount: Cardinal); override;
    procedure Paint; override;
  end;


implementation
uses KM_Units_Warrior, KM_PlayersCollection, KM_Player, KM_TextLibrary, KM_MapEditor,
     KM_Utils, KM_Game, KM_GameApp, KM_Resource, KM_ResourceUnit, KM_ResourceCursors, KM_ResourceMapElements;


{Switch between pages}
procedure TKMapEdInterface.SwitchPage(Sender: TObject);
var
  i, k:Integer;
begin

  //Reset cursor mode
  GameCursor.Mode := cm_None;
  GameCursor.Tag1 := 0;

  //If the user clicks on the tab that is open, it closes it (main buttons only)
  if ((Sender = Button_Main[1]) and Panel_Terrain.Visible) or
     ((Sender = Button_Main[2]) and Panel_Village.Visible) or
     ((Sender = Button_Main[3]) and Panel_Player.Visible) or
     ((Sender = Button_Main[4]) and Panel_Mission.Visible) or
     ((Sender = Button_Main[5]) and Panel_Menu.Visible) then
     Sender := nil;

  //Reset shown item if user clicked on any of the main buttons
  if (Sender=Button_Main[1])or(Sender=Button_Main[2])or
     (Sender=Button_Main[3])or(Sender=Button_Main[4])or
     (Sender=Button_Main[5])or
     (Sender=Button_Menu_Settings)or(Sender=Button_Menu_Quit) then
  begin
    fPlayers.Selected := nil;
  end;

  Label_MenuTitle.Caption := '';
  //Now hide all existing pages
    for i:=1 to Panel_Common.ChildCount do
      if Panel_Common.Childs[i] is TKMPanel then
      begin
        for k:=1 to TKMPanel(Panel_Common.Childs[i]).ChildCount do
          if TKMPanel(Panel_Common.Childs[i]).Childs[k] is TKMPanel then
            TKMPanel(Panel_Common.Childs[i]).Childs[k].Hide;
        Panel_Common.Childs[i].Hide;
      end;

  if (Sender = Button_Main[1])or(Sender = Button_Terrain[1]) then begin
    Panel_Terrain.Show;
    Panel_Brushes.Show;
    Label_MenuTitle.Caption:='Terrain - Brushes';
  end else

  if (Sender = Button_Main[1])or(Sender = Button_Terrain[2]) then begin
    Panel_Terrain.Show;
    Panel_Heights.Show;
    Label_MenuTitle.Caption:='Terrain - Heights';
    Terrain_HeightChange(HeightCircle); //Select the default mode
  end else

  if (Sender = Button_Main[1])or(Sender = Button_Terrain[3]) then begin
    Panel_Terrain.Show;
    Panel_Tiles.Show;
    Label_MenuTitle.Caption:='Terrain - Tiles';
    SetTileDirection(fTileDirection); //ensures tags are in allowed ranges
    Terrain_TilesChange(GetSelectedTile);
  end else

  if (Sender = Button_Main[1])or(Sender = Button_Terrain[4]) then begin
    Panel_Terrain.Show;
    Panel_Objects.Show;
    Label_MenuTitle.Caption:='Terrain - Objects';
    Terrain_ObjectsChange(GetSelectedObject);
  end else

  if (Sender = Button_Main[2])or(Sender = Button_Village[vtHouses]) then
  begin
    Panel_Village.Show;
    Panel_Build.Show;
    Label_MenuTitle.Caption := 'Village - Buildings';
    Build_ButtonClick(Button_BuildRoad);
  end else

  if (Sender = Button_Village[vtUnits]) then
  begin
    Panel_Village.Show;
    Panel_Units.Show;
    Label_MenuTitle.Caption := 'Village - Units';
    Unit_ButtonClick(GetSelectedUnit);
  end
  else
  if (Sender = Button_Village[vtScript]) then
  begin
    Panel_Village.Show;
    Panel_Script.Show;
    Label_MenuTitle.Caption := 'Village - Script';
  end
  else
  if (Sender = Button_Village[vtDefences]) then
  begin
    Defence_FillList;
    Panel_Village.Show;
    Panel_Defence.Show;
    Label_MenuTitle.Caption := 'Village - Defences';
  end
  else
  if (Sender = Button_Main[3])or(Sender = Button_Player[1]) then begin
    Panel_Player.Show;
    Panel_Goals.Show;
    Label_MenuTitle.Caption:='Player - Goals';
  end else

  if (Sender = Button_Main[3])or(Sender = Button_Player[2]) then begin
    Panel_Player.Show;
    Panel_Color.Show;
    Label_MenuTitle.Caption:='Player - Color';
  end else

  if (Sender = Button_Main[3])or(Sender = Button_Player[3]) then begin
    Player_BlockRefresh;
    Panel_Player.Show;
    Panel_Block.Show;
    Label_MenuTitle.Caption:='Player - Block houses';
  end else

  if (Sender = Button_Main[4])or(Sender = Button_Mission[1]) then begin
    Panel_Mission.Show;
    Panel_Alliances.Show;
    Label_MenuTitle.Caption:='Mission - Alliances';
    Mission_AlliancesChange(nil);
  end else

  if (Sender = Button_Main[4])or(Sender = Button_Mission[2]) then begin
    Panel_Mission.Show;
    Panel_PlayerTypes.Show;
    Label_MenuTitle.Caption:='Mission - Player Types';
    Mission_PlayerTypesChange(nil);
  end else

  if (Sender=Button_Main[5]) or
     (Sender=Button_Quit_No) or
     (Sender = Button_LoadCancel) or
     (Sender = Button_SaveCancel) then begin
    Panel_Menu.Show;
    Label_MenuTitle.Caption := fTextLibrary[TX_MENU_TAB_OPTIONS];
  end else

  if Sender=Button_Menu_Quit then begin
    Panel_Quit.Show;
  end;

  if Sender = Button_Menu_Save then begin
    Edit_SaveName.Text := fGame.GameName;
    Menu_Save(Edit_SaveName);
    Panel_Save.Show;
  end;

  if Sender = Button_Menu_Load then begin
    Load_MapListUpdate;
    Panel_Load.Show;
  end;

  //Now process all other kinds of pages
  if Sender=Panel_Unit then begin
    TKMPanel(Sender).Show;
  end else

  if Sender=Panel_House then begin
    TKMPanel(Sender).Show;
  end;

  if Sender=Panel_HouseBarracks then begin
    TKMPanel(Sender).Parent.Show;
    TKMPanel(Sender).Show;
  end else

  if Sender=Panel_HouseStore then begin
    TKMPanel(Sender).Parent.Show;
    TKMPanel(Sender).Show;
  end;

end;


procedure TKMapEdInterface.DisplayHint(Sender: TObject);
begin
  if (fPrevHint = Sender) then exit; //Hint didn't changed

  if Sender=nil then Label_Hint.Caption:=''
                else Label_Hint.Caption:=TKMControl(Sender).Hint;

  fPrevHint := Sender;
end;


//Update viewport position when user interacts with minimap
procedure TKMapEdInterface.Minimap_Update(Sender: TObject; const X,Y: Integer);
begin
  fGame.Viewport.Position := KMPointF(X,Y);
end;


constructor TKMapEdInterface.Create(aScreenX, aScreenY: word);
var
  i: Integer;
begin
  inherited;

  fBarracksItem   := 1; //First ware selected by default
  fStorehouseItem := 1; //First ware selected by default
  fTileDirection := 0;
  fMaps := TKMapsCollection.Create(False);
  fMapsMP := TKMapsCollection.Create(True);

  //Parent Page for whole toolbar in-game
  Panel_Main := TKMPanel.Create(fMyControls, 0, 0, aScreenX, aScreenY);

    Label_MatAmount := TKMLabel.Create(Panel_Main, 0, 0, '', fnt_Metal, taCenter);
    Shape_MatAmount := TKMShape.Create(Panel_Main,0,0,80,20);
    Shape_MatAmount.LineWidth := 2;
    Shape_MatAmount.LineColor := $F000FF00;
    Shape_MatAmount.FillColor := $80000000;

    Label_DefenceID := TKMLabel.Create(Panel_Main, 0, 0, '', fnt_Metal, taCenter);
    Label_DefencePos := TKMLabel.Create(Panel_Main, 0, 0, '', fnt_Metal, taCenter);
    Shape_DefencePos := TKMShape.Create(Panel_Main,0,0,80,20);
    Shape_DefencePos.LineWidth := 2;
    Shape_DefencePos.LineColor := $F0FF8000;
    Shape_DefencePos.FillColor := $80000000;

    TKMImage.Create(Panel_Main,0,   0,224,200,407); //Minimap place
    TKMImage.Create(Panel_Main,0, 200,224,400,404);
    TKMImage.Create(Panel_Main,0, 600,224,400,404);
    TKMImage.Create(Panel_Main,0,1000,224,400,404); //For 1600x1200 this is needed

    MinimapView := TKMMinimapView.Create(Panel_Main, 10, 10, 176, 176);
    MinimapView.OnChange := Minimap_Update;

    Label_Coordinates := TKMLabel.Create(Panel_Main,8,192,184,0,'X: Y:',fnt_Outline,taLeft);
    TrackBar_Passability := TKMTrackBar.Create(Panel_Main, 8, 210, 184, 0, Byte(High(TPassability)));
    TrackBar_Passability.Caption := 'View passability';
    TrackBar_Passability.Position := 0; //Disabled by default
    TrackBar_Passability.OnChange := View_Passability;
    Label_Passability := TKMLabel.Create(Panel_Main,8,248,184,0,'Off',fnt_Metal,taLeft);

    TKMLabel.Create(Panel_Main,8,270,184,0,'Player',fnt_Metal,taLeft);
    for i:=0 to MAX_PLAYERS-1 do begin
      Button_PlayerSelect[i]         := TKMFlatButtonShape.Create(Panel_Main, 8 + i*23, 290, 21, 32, inttostr(i+1), fnt_Grey, $FF0000FF);
      Button_PlayerSelect[i].CapOffsetY := -3;
      Button_PlayerSelect[i].Tag     := i;
      Button_PlayerSelect[i].OnClick := Player_ChangeActive;
    end;

    Label_MissionName := TKMLabel.Create(Panel_Main, 8, 340, 184, 10, '<<<LEER>>>', fnt_Metal, taLeft);

    Label_Stat:=TKMLabel.Create(Panel_Main,224+8,16,0,0,'',fnt_Outline,taLeft);
    Label_Hint:=TKMLabel.Create(Panel_Main,224+8,Panel_Main.Height-16,0,0,'',fnt_Outline,taLeft);
    Label_Hint.Anchors := [akLeft, akBottom];

  Panel_Common := TKMPanel.Create(Panel_Main,0,300,224,768);

    {5 big tabs}
    Button_Main[1] := TKMButton.Create(Panel_Common,   8, 72, 36, 36, 381, rxGui, bsGame);
    Button_Main[2] := TKMButton.Create(Panel_Common,  46, 72, 36, 36, 368, rxGui, bsGame);
    Button_Main[3] := TKMButton.Create(Panel_Common,  84, 72, 36, 36,  41, rxGui, bsGame);
    Button_Main[4] := TKMButton.Create(Panel_Common, 122, 72, 36, 36, 441, rxGui, bsGame);
    Button_Main[5] := TKMButton.Create(Panel_Common, 160, 72, 36, 36, 389, rxGui, bsGame);
    Button_Main[1].Hint := fTextLibrary[TX_MAPEDITOR_TERRAIN];
    Button_Main[2].Hint := fTextLibrary[TX_MAPEDITOR_VILLAGE];
    Button_Main[3].Hint := fTextLibrary[TX_MAPEDITOR_SCRIPTS_VISUAL];
    Button_Main[4].Hint := fTextLibrary[TX_MAPEDITOR_SCRIPTS_GLOBAL];
    Button_Main[5].Hint := fTextLibrary[TX_MAPEDITOR_MENU];
    for i:=1 to 5 do Button_Main[i].OnClick := SwitchPage;

    Label_MenuTitle:=TKMLabel.Create(Panel_Common,8,112,184,36,'',fnt_Metal,taLeft); //Should be one-line


{I plan to store all possible layouts on different pages which gets displayed one at a time}
{==========================================================================================}
  Create_Terrain_Page;
  Create_Village_Page;
  Create_Player_Page;
  Create_Mission_Page;

  Create_Menu_Page;
    Create_MenuSave_Page;
    Create_MenuLoad_Page;
    Create_MenuQuit_Page;

  Create_Unit_Page;
  Create_House_Page;
    Create_Store_Page;
    Create_Barracks_Page;
    //Create_TownHall_Page;

  fMyControls.OnHint := DisplayHint;

  SwitchPage(nil); //Update
end;


destructor TKMapEdInterface.Destroy;
begin
  fMaps.Free;
  fMapsMP.Free;
  SHOW_TERRAIN_WIRES := false; //Don't show it in-game if they left it on in MapEd
  SHOW_TERRAIN_PASS := 0; //Don't show it in-game if they left it on in MapEd
  inherited;
end;


//Update Hint position and etc..
procedure TKMapEdInterface.Resize(X,Y: Word);
begin
  Panel_Main.Width := X;
  Panel_Main.Height := Y;
end;


{Terrain page}
procedure TKMapEdInterface.Create_Terrain_Page;
var i,k:Integer;
begin
  Panel_Terrain := TKMPanel.Create(Panel_Common,0,128,196,28);
    Button_Terrain[1] := TKMButton.Create(Panel_Terrain,   8, 4, 36, 24, 383, rxGui, bsGame);
    Button_Terrain[2] := TKMButton.Create(Panel_Terrain,  48, 4, 36, 24, 388, rxGui, bsGame);
    Button_Terrain[3] := TKMButton.Create(Panel_Terrain,  88, 4, 36, 24, 382, rxGui, bsGame);
    Button_Terrain[4] := TKMButton.Create(Panel_Terrain, 128, 4, 36, 24, 385, rxGui, bsGame);
    for i:=1 to 4 do Button_Terrain[i].OnClick := SwitchPage;

    Panel_Brushes := TKMPanel.Create(Panel_Terrain,0,28,196,400);
      BrushSize   := TKMTrackBar.Create(Panel_Brushes, 8, 10, 100, 1, 12);
      BrushCircle := TKMButtonFlat.Create(Panel_Brushes, 114, 8, 24, 24, 359);
      BrushSquare := TKMButtonFlat.Create(Panel_Brushes, 142, 8, 24, 24, 352);

      TKMButtonFlat.Create(Panel_Brushes, 8, 30, 32, 32, 1, rxTiles);   // grass

      {TKMButtonFlat.Create(Panel_Brushes, 40, 30, 32, 32, 9, rxTiles);  // grass 2
      TKMButtonFlat.Create(Panel_Brushes, 8, 62, 32, 32, 35, rxTiles);  // dirt

      {BrushSize.OnChange   := TerrainBrush_Change;
      BrushCircle.OnChange := TerrainBrush_Change;
      BrushSquare.OnChange := TerrainBrush_Change;}

    Panel_Heights := TKMPanel.Create(Panel_Terrain,0,28,196,400);
      HeightSize   := TKMTrackBar.Create(Panel_Heights, 8, 10, 100, 1, 15); //1..15(4bit) for size
      HeightCircle := TKMButtonFlat.Create(Panel_Heights, 114, 8, 24, 24, 359);
      HeightSquare := TKMButtonFlat.Create(Panel_Heights, 142, 8, 24, 24, 352);
      HeightShape  := TKMTrackBar.Create(Panel_Heights, 8, 30, 100, 1, 15); //1..15(4bit) for slope shape

      HeightElevate             := TKMButtonFlat.Create(Panel_Heights,8,70,180,20,0);
      HeightElevate.OnClick     := Terrain_HeightChange;
      HeightElevate.Down        := True;
      HeightElevate.Caption     := 'Elevate';
      HeightElevate.CapOffsetY  := -12;
      HeightUnequalize          := TKMButtonFlat.Create(Panel_Heights,8,100,180,20,0);
      HeightUnequalize.OnClick  := Terrain_HeightChange;
      HeightUnequalize.Caption  := 'Unequalize/flatten';
      HeightUnequalize.CapOffsetY  := -12;

      HeightSize.OnChange   := Terrain_HeightChange;
      HeightShape.OnChange  := Terrain_HeightChange;
      HeightCircle.OnClick  := Terrain_HeightChange;
      HeightSquare.OnClick  := Terrain_HeightChange;

    Panel_Tiles := TKMPanel.Create(Panel_Terrain,0,28,196,400);
      TilesRandom := TKMCheckBox.Create(Panel_Tiles, 8, 4, 188, 20, 'Random Direction', fnt_Metal);
      TilesRandom.Checked := true;
      TilesRandom.OnClick := Terrain_TilesChange;
      TilesScroll := TKMScrollBar.Create(Panel_Tiles, 2, 30 + 4 + MAPED_TILES_ROWS * 32, 194, 20, sa_Horizontal, bsGame);
      TilesScroll.MaxValue := 256 div MAPED_TILES_ROWS - MAPED_TILES_COLS; // 16 - 6
      TilesScroll.Position := 0;
      TilesScroll.OnChange := Terrain_TilesChange;
      for i:=1 to MAPED_TILES_COLS do for k:=1 to MAPED_TILES_ROWS do begin
        TilesTable[(i-1)*MAPED_TILES_ROWS+k] := TKMButtonFlat.Create(Panel_Tiles,2+(i-1)*32,30+(k-1)*32,32,32,1,rxTiles); //2..9
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].Tag := (k-1)*MAPED_TILES_COLS+i; //Store ID
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].OnClick := Terrain_TilesChange;
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].OnMouseWheel := TilesScroll.MouseWheel;
      end;
      Terrain_TilesChange(TilesScroll); //This ensures that the displayed images get updated the first time
      Terrain_TilesChange(TilesTable[1]);

    Panel_Objects := TKMPanel.Create(Panel_Terrain,0,28,196,400);
      ObjectsScroll := TKMScrollBar.Create(Panel_Objects, 8, 295, 180, 20, sa_Horizontal, bsGame);
      ObjectsScroll.MinValue := 0;
      ObjectsScroll.MaxValue := fResource.MapElements.ValidCount div 3 - 2;
      ObjectsScroll.Position := 0;
      ObjectsScroll.OnChange := Terrain_ObjectsChange;
      ObjectErase := TKMButtonFlat.Create(Panel_Objects, 8, 8,32,32,340);
      for I := 0 to 2 do for K := 0 to 2 do
      begin
        ObjectsTable[I*3+K] := TKMButtonFlat.Create(Panel_Objects, 8+I*65, 40+K*85,64,84,1,rxTrees); //RXid=1  // 1 2
        ObjectsTable[I*3+K].Tag := I*3+K; //Store ID
        ObjectsTable[I*3+K].OnClick := Terrain_ObjectsChange;
        ObjectsTable[I*3+K].OnMouseWheel := ObjectsScroll.MouseWheel;
      end;
      ObjectErase.Tag := 255; //no object
      ObjectErase.OnClick := Terrain_ObjectsChange;
    Terrain_ObjectsChange(ObjectsScroll); //This ensures that the displayed images get updated the first time
    Terrain_ObjectsChange(ObjectsTable[0]);
end;


{Build page}
procedure TKMapEdInterface.Create_Village_Page;
const VillageTabIcon: array [TKMVillageTab] of Word = (454, 141, 327, 43);
var
  I: Integer;
  VT: TKMVillageTab;
begin
  Panel_Village := TKMPanel.Create(Panel_Common,0,128,196,28);

    for VT := Low(TKMVillageTab) to High(TKMVillageTab) do
    begin
      Button_Village[VT] := TKMButton.Create(Panel_Village, Byte(VT) * 40 + 8, 4, 36, 24, VillageTabIcon[VT], rxGui, bsGame);
      Button_Village[VT].OnClick := SwitchPage;
    end;

    Panel_Build := TKMPanel.Create(Panel_Village,0,28,196,400);
      TKMLabel.Create(Panel_Build,100,10,184,0,'Roadworks',fnt_Outline,taCenter);
      Button_BuildRoad   := TKMButtonFlat.Create(Panel_Build,  8,28,33,33,335);
      Button_BuildField  := TKMButtonFlat.Create(Panel_Build, 45,28,33,33,337);
      Button_BuildWine   := TKMButtonFlat.Create(Panel_Build, 82,28,33,33,336);
      Button_BuildCancel := TKMButtonFlat.Create(Panel_Build,156,28,33,33,340);
      Button_BuildRoad.OnClick  := Build_ButtonClick;
      Button_BuildField.OnClick := Build_ButtonClick;
      Button_BuildWine.OnClick  := Build_ButtonClick;
      Button_BuildCancel.OnClick:= Build_ButtonClick;
      Button_BuildRoad.Hint     := fTextLibrary[TX_BUILD_ROAD_HINT];
      Button_BuildField.Hint    := fTextLibrary[TX_BUILD_FIELD_HINT];
      Button_BuildWine.Hint     := fTextLibrary[TX_BUILD_WINE_HINT];
      Button_BuildCancel.Hint   := fTextLibrary[TX_BUILD_CANCEL_HINT];

      TKMLabel.Create(Panel_Build,100,65,184,0,'Houses',fnt_Outline,taCenter);
      for I:=1 to GUI_HOUSE_COUNT do
        if GUIHouseOrder[I] <> ht_None then begin
          Button_Build[I]:=TKMButtonFlat.Create(Panel_Build, 8+((I-1) mod 5)*37,83+((I-1) div 5)*37,33,33,fResource.HouseDat[GUIHouseOrder[I]].GUIIcon);
          Button_Build[I].OnClick:=Build_ButtonClick;
          Button_Build[I].Hint := fResource.HouseDat[GUIHouseOrder[I]].HouseName;
        end;

    Panel_Units := TKMPanel.Create(Panel_Village,0,28,196,400);

      //TKMLabel.Create(Panel_Units,100,10,0,0,'Citizens',fnt_Outline,taCenter);
      for I:=0 to High(Button_Citizen) do
      begin
        Button_Citizen[I] := TKMButtonFlat.Create(Panel_Units,8+(I mod 5)*37,8+(I div 5)*37,33,33,fResource.UnitDat[School_Order[I]].GUIIcon); //List of tiles 5x5
        Button_Citizen[I].Hint := fResource.UnitDat[School_Order[I]].UnitName;
        Button_Citizen[I].Tag := byte(School_Order[I]); //Returns unit ID
        Button_Citizen[I].OnClick := Unit_ButtonClick;
      end;
      Button_UnitCancel := TKMButtonFlat.Create(Panel_Units,8+((High(Button_Citizen)+1) mod 5)*37,8+(length(Button_Citizen) div 5)*37,33,33,340);
      Button_UnitCancel.Hint := fTextLibrary[TX_BUILD_CANCEL_HINT];
      Button_UnitCancel.OnClick := Unit_ButtonClick;

      //TKMLabel.Create(Panel_Units,100,140,0,0,'Warriors',fnt_Outline,taCenter);
      for I:=0 to High(Button_Warriors) do
      begin
        Button_Warriors[I] := TKMButtonFlat.Create(Panel_Units,8+(I mod 5)*37,124+(I div 5)*37,33,33, MapEd_Icon[I], rxGui);
        Button_Warriors[I].Hint := fResource.UnitDat[MapEd_Order[I]].UnitName;
        Button_Warriors[I].Tag := byte(MapEd_Order[I]); //Returns unit ID
        Button_Warriors[I].OnClick := Unit_ButtonClick;
      end;

      //TKMLabel.Create(Panel_Units,100,230,0,0,'Animals',fnt_Outline,taCenter);
      for I:=0 to High(Button_Animals) do
      begin
        Button_Animals[I] := TKMButtonFlat.Create(Panel_Units,8+(I mod 5)*37,240+(I div 5)*37,33,33, Animal_Icon[I], rxGui);
        Button_Animals[I].Hint := fResource.UnitDat[Animal_Order[I]].UnitName;
        Button_Animals[I].Tag := byte(Animal_Order[I]); //Returns animal ID
        Button_Animals[I].OnClick := Unit_ButtonClick;
      end;
      Unit_ButtonClick(Button_Citizen[0]); //Select serf as default

    Panel_Script := TKMPanel.Create(Panel_Village, 0, 28, 196, 400);
      TKMLabel.Create(Panel_Script, 100, 10, 184, 0, 'Scripts', fnt_Outline, taCenter);
      {Button_ScriptReveal         := TKMButtonFlat.Create(Panel_Script,  8,28,33,33,335);
      Button_ScriptReveal.OnClick := Script_ButtonClick;
      Button_ScriptReveal.Hint    := 'Reveal a portion of map';}

    Panel_Defence := TKMPanel.Create(Panel_Village, 0, 28, 196, 400);
      TKMLabel.Create(Panel_Defence, 100, 10, 184, 0, 'Defence', fnt_Outline, taCenter);
      List_Defences := TKMListBox.Create(Panel_Defence, 8, 30, 180, 160, fnt_Grey, bsGame);
      List_Defences.OnDoubleClick := Defence_ItemClicked;
end;


procedure TKMapEdInterface.Create_Player_Page;
var I: Integer; Col: array [0..255] of TColor4;
begin
  Panel_Player := TKMPanel.Create(Panel_Common,0,128,196,28);
    Button_Player[1] := TKMButton.Create(Panel_Player,   8, 4, 36, 24,  41, rxGui, bsGame);
    Button_Player[2] := TKMButton.Create(Panel_Player,  48, 4, 36, 24, 382, rxGui, bsGame);
    Button_Player[3] := TKMButton.Create(Panel_Player,  88, 4, 36, 24,  38, rxGui, bsGame);
    for I := 1 to 3 do Button_Player[I].OnClick := SwitchPage;

    Panel_Goals := TKMPanel.Create(Panel_Player,0,28,196,400);
      TKMLabel.Create(Panel_Goals,100,10,184,0,'Goals',fnt_Outline,taCenter);

    Panel_Color := TKMPanel.Create(Panel_Player,0,28,196,400);
      TKMLabel.Create(Panel_Color,100,10,184,0,'Colors',fnt_Outline,taCenter);
      TKMBevel.Create(Panel_Color,8,30,180,210);
      ColorSwatch_Color := TKMColorSwatch.Create(Panel_Color, 10, 32, 16, 16, 11);
      for I:=0 to 255 do Col[I] := fResource.Palettes.DefDal.Color32(I);
      ColorSwatch_Color.SetColors(Col);
      ColorSwatch_Color.OnClick := Player_ColorClick;

    Panel_Block := TKMPanel.Create(Panel_Player,0,28,196,400);
      TKMLabel.Create(Panel_Block, 100, 10, 184, 0, 'Block houses', fnt_Outline, taCenter);

      for I := 1 to GUI_HOUSE_COUNT do
      if GUIHouseOrder[I] <> ht_None then begin
        Button_BlockHouse[I] := TKMButtonFlat.Create(Panel_Block, 8+((I-1) mod 5)*37, 30 + ((I-1) div 5)*37,33,33,fResource.HouseDat[GUIHouseOrder[I]].GUIIcon);
        Button_BlockHouse[I].Hint := fResource.HouseDat[GUIHouseOrder[I]].HouseName;
        Button_BlockHouse[I].OnClick := Player_BlockClick;
        Button_BlockHouse[I].Tag := I;
        Image_BlockHouse[I] := TKMImage.Create(Panel_Block, 8+((I-1) mod 5)*37 + 13, 30 + ((I-1) div 5)*37 + 13, 16, 16, 0, rxGuiMain);
        Image_BlockHouse[I].Hitable := False;
        Image_BlockHouse[I].ImageCenter;
      end;
end;


procedure TKMapEdInterface.Create_Mission_Page;
var i,k:Integer;
begin
  Panel_Mission := TKMPanel.Create(Panel_Common,0,128,196,28);
    Button_Mission[1] := TKMButton.Create(Panel_Mission,  8, 4, 36, 24, 41, rxGui, bsGame);
    Button_Mission[2] := TKMButton.Create(Panel_Mission, 48, 4, 36, 24, 41, rxGui, bsGame);
    for i:=1 to 2 do Button_Mission[i].OnClick := SwitchPage;

    Panel_Alliances := TKMPanel.Create(Panel_Mission,0,28,196,400);
      TKMLabel.Create(Panel_Alliances,100,10,184,0,'Alliances',fnt_Outline,taCenter);
      for i:=0 to MAX_PLAYERS-1 do begin
        TKMLabel.Create(Panel_Alliances,32+i*20+2,30,20,20,inttostr(i+1),fnt_Outline,taLeft);
        TKMLabel.Create(Panel_Alliances,12,50+i*25,20,20,inttostr(i+1),fnt_Outline,taLeft);
        for k:=0 to MAX_PLAYERS-1 do begin
          CheckBox_Alliances[i,k] := TKMCheckBox.Create(Panel_Alliances, 28+k*20, 46+i*25, 20, 20, '', fnt_Metal);
          CheckBox_Alliances[i,k].Tag       := i * MAX_PLAYERS + k;
          CheckBox_Alliances[i,k].FlatStyle := true;
          CheckBox_Alliances[i,k].OnClick   := Mission_AlliancesChange;
        end;
      end;

      //It does not have OnClick event for a reason:
      // - we don't have a rule to make alliances symmetrical yet
      CheckBox_AlliancesSym := TKMCheckBox.Create(Panel_Alliances, 12, 50+MAX_PLAYERS*25, 176, 20, 'Symmetrical', fnt_Metal);
      CheckBox_AlliancesSym.Checked := true;
      CheckBox_AlliancesSym.Disable;

    Panel_PlayerTypes := TKMPanel.Create(Panel_Mission,0,28,196,400);
      TKMLabel.Create(Panel_PlayerTypes,100,10,184,0,'Player types',fnt_Outline,taCenter);
      for i:=0 to MAX_PLAYERS-1 do begin
        TKMLabel.Create(Panel_PlayerTypes,12,30,20,20,'#',fnt_Grey,taLeft);
        TKMLabel.Create(Panel_PlayerTypes,32,30,100,20,'Human',fnt_Grey,taLeft);
        TKMLabel.Create(Panel_PlayerTypes,102,30,100,20,'Computer',fnt_Grey,taLeft);
        TKMLabel.Create(Panel_PlayerTypes,12,50+i*25,20,20,inttostr(i+1),fnt_Outline,taLeft);
        for k:=0 to 1 do
        begin
          CheckBox_PlayerTypes[i,k] := TKMCheckBox.Create(Panel_PlayerTypes, 52+k*70, 48+i*25, 20, 20, '', fnt_Metal);
          CheckBox_PlayerTypes[i,k].Tag       := i;
          CheckBox_PlayerTypes[i,k].FlatStyle := true;
          CheckBox_PlayerTypes[i,k].OnClick   := Mission_PlayerTypesChange;
        end;
      end;
end;


{Menu page}
procedure TKMapEdInterface.Create_Menu_Page;
begin
  Panel_Menu:=TKMPanel.Create(Panel_Common,0,128,196,400);
    Button_Menu_Save:=TKMButton.Create(Panel_Menu,8,20,180,30,fTextLibrary[TX_MENU_SAVE_GAME],bsGame);
    Button_Menu_Save.OnClick:=SwitchPage;
    Button_Menu_Save.Hint:=fTextLibrary[TX_MENU_SAVE_GAME];
    Button_Menu_Load:=TKMButton.Create(Panel_Menu,8,60,180,30,fTextLibrary[TX_MENU_LOAD_GAME],bsGame);
    Button_Menu_Load.OnClick:=SwitchPage;
    Button_Menu_Load.Hint:=fTextLibrary[TX_MENU_LOAD_GAME];
    Button_Menu_Settings:=TKMButton.Create(Panel_Menu,8,100,180,30,fTextLibrary[TX_MENU_SETTINGS],bsGame);
    Button_Menu_Settings.Hint:=fTextLibrary[TX_MENU_SETTINGS];
    Button_Menu_Settings.Disable;
    Button_Menu_Quit:=TKMButton.Create(Panel_Menu,8,180,180,30,fTextLibrary[TX_MENU_QUIT_MAPED],bsGame);
    Button_Menu_Quit.Hint:=fTextLibrary[TX_MENU_QUIT_MAPED];
    Button_Menu_Quit.OnClick:=SwitchPage;
end;


{Save page}
procedure TKMapEdInterface.Create_MenuSave_Page;
begin
  Panel_Save := TKMPanel.Create(Panel_Common,0,128,196,400);
    TKMBevel.Create(Panel_Save, 8, 30, 180, 37);
    Radio_Save_MapType  := TKMRadioGroup.Create(Panel_Save,12,32,176,35,fnt_Grey);
    Radio_Save_MapType.ItemIndex := 0;
    Radio_Save_MapType.Items.Add(fTextLibrary[TX_MENU_MAPED_SPMAPS]);
    Radio_Save_MapType.Items.Add(fTextLibrary[TX_MENU_MAPED_MPMAPS]);
    Radio_Save_MapType.OnChange := Menu_Save;
    TKMLabel.Create(Panel_Save,100,90,184,20,'Save map',fnt_Outline,taCenter);
    Edit_SaveName       := TKMEdit.Create(Panel_Save,8,110,180,20, fnt_Grey);
    Edit_SaveName.AllowedChars := acFileName;
    Label_SaveExists    := TKMLabel.Create(Panel_Save,100,140,184,0,'Map already exists',fnt_Outline,taCenter);
    CheckBox_SaveExists := TKMCheckBox.Create(Panel_Save,8,160,180,20,'Overwrite', fnt_Metal);
    Button_SaveSave     := TKMButton.Create(Panel_Save,8,180,180,30,'Save',bsGame);
    Button_SaveCancel   := TKMButton.Create(Panel_Save,8,220,180,30,'Cancel',bsGame);
    Edit_SaveName.OnChange      := Menu_Save;
    CheckBox_SaveExists.OnClick := Menu_Save;
    Button_SaveSave.OnClick     := Menu_Save;
    Button_SaveCancel.OnClick   := SwitchPage;
end;


{Load page}
procedure TKMapEdInterface.Create_MenuLoad_Page;
begin
  Panel_Load := TKMPanel.Create(Panel_Common,0,108,196,400);
    TKMLabel.Create(Panel_Load, 8, 2, 184, 30, 'Available maps', fnt_Outline, taLeft);
    TKMBevel.Create(Panel_Load, 8, 20, 184, 38);
    Radio_Load_MapType := TKMRadioGroup.Create(Panel_Load,12,22,176,35,fnt_Grey);
    Radio_Load_MapType.ItemIndex := 0;
    Radio_Load_MapType.Items.Add(fTextLibrary[TX_MENU_MAPED_SPMAPS]);
    Radio_Load_MapType.Items.Add(fTextLibrary[TX_MENU_MAPED_MPMAPS]);
    Radio_Load_MapType.OnChange := Load_MapTypeChange;
    ListBox_Load := TKMListBox.Create(Panel_Load, 8, 75, 184, 205, fnt_Grey, bsGame);
    ListBox_Load.ItemHeight := 18;
    Button_LoadLoad     := TKMButton.Create(Panel_Load,8,290,184,30,'Load',bsGame);
    Button_LoadCancel   := TKMButton.Create(Panel_Load,8,325,184,30,'Cancel',bsGame);
    Button_LoadLoad.OnClick     := Menu_Load;
    Button_LoadCancel.OnClick   := SwitchPage;
end;


{Quit page}
procedure TKMapEdInterface.Create_MenuQuit_Page;
begin
  Panel_Quit:=TKMPanel.Create(Panel_Common,0,128,200,400);
    TKMLabel.Create(Panel_Quit,100,40,184,60,'Any unsaved|changes will be lost',fnt_Outline,taCenter);
    Button_Quit_Yes   := TKMButton.Create(Panel_Quit,8,100,180,30,fTextLibrary[TX_MENU_QUIT_MISSION],bsGame);
    Button_Quit_No    := TKMButton.Create(Panel_Quit,8,140,180,30,fTextLibrary[TX_MENU_DONT_QUIT_MISSION],bsGame);
    Button_Quit_Yes.Hint      := fTextLibrary[TX_MENU_QUIT_MISSION];
    Button_Quit_No.Hint       := fTextLibrary[TX_MENU_DONT_QUIT_MISSION];
    Button_Quit_Yes.OnClick   := Menu_QuitMission;
    Button_Quit_No.OnClick    := SwitchPage;
end;


{Unit page}
procedure TKMapEdInterface.Create_Unit_Page;
begin
  Panel_Unit:=TKMPanel.Create(Panel_Common,0,112,200,400);
    Label_UnitName        := TKMLabel.Create(Panel_Unit,100,16,184,0,'',fnt_Outline,taCenter);
    Image_UnitPic         := TKMImage.Create(Panel_Unit,8,38,54,100,521);
    Label_UnitCondition   := TKMLabel.Create(Panel_Unit,132,40,116,0,fTextLibrary[TX_UNIT_CONDITION],fnt_Grey,taCenter);
    KMConditionBar_Unit   := TKMPercentBar.Create(Panel_Unit,73,55,116,15);
    Label_UnitDescription := TKMLabel.Create(Panel_Unit,8,152,184,200,'',fnt_Grey,taLeft); //Taken from LIB resource
    Label_UnitDescription.AutoWrap := True;

  Panel_Army:=TKMPanel.Create(Panel_Unit,0,160,200,400);
    Button_Army_RotCCW   := TKMButton.Create(Panel_Army,  8, 0, 56, 40, 23, rxGui, bsGame);
    Button_Army_RotCW  := TKMButton.Create(Panel_Army,132, 0, 56, 40, 24, rxGui, bsGame);
    Button_Army_ForUp   := TKMButton.Create(Panel_Army,  8, 46, 56, 40, 33, rxGui, bsGame);
    ImageStack_Army     := TKMImageStack.Create(Panel_Army, 70, 46, 56, 40, 43, 50);
    Label_ArmyCount     := TKMLabel.Create(Panel_Army, 98, 60, 0, 0, '-', fnt_Outline, taCenter);
    Button_Army_ForDown := TKMButton.Create(Panel_Army,132, 46, 56, 40, 32, rxGui, bsGame);
    Button_Army_RotCW.OnClick   := Unit_ArmyChange1;
    Button_Army_RotCCW.OnClick  := Unit_ArmyChange1;
    Button_Army_ForUp.OnClick   := Unit_ArmyChange1;
    Button_Army_ForDown.OnClick := Unit_ArmyChange1;

    Button_ArmyDec      := TKMButton.Create(Panel_Army,  8,92,56,40,'-', bsGame);
    Button_ArmyFood     := TKMButton.Create(Panel_Army, 70,92,56,40,29, rxGui, bsGame);
    Button_ArmyInc      := TKMButton.Create(Panel_Army,132,92,56,40,'+', bsGame);
    Button_ArmyDec.OnClickEither := Unit_ArmyChange2;
    Button_ArmyFood.OnClick := Unit_ArmyChange1;
    Button_ArmyInc.OnClickEither := Unit_ArmyChange2;
end;


{House description page}
procedure TKMapEdInterface.Create_House_Page;
begin
  Panel_House:=TKMPanel.Create(Panel_Common,0,112,200,400);
    //Thats common things
    Label_House:=TKMLabel.Create(Panel_House,100,14,184,0,'',fnt_Outline,taCenter);
    Image_House_Logo:=TKMImage.Create(Panel_House,8,41,32,32,338);
    Image_House_Logo.ImageCenter;
    Image_House_Worker:=TKMImage.Create(Panel_House,38,41,32,32,141);
    Image_House_Worker.ImageCenter;
    Label_HouseHealth := TKMLabel.Create(Panel_House,130,41,60,20,fTextLibrary[TX_HOUSE_CONDITION],fnt_Mini,taCenter);
    Label_HouseHealth.FontColor := $FFE0E0E0;
    KMHealthBar_House := TKMPercentBar.Create(Panel_House,100,53,60,20);
    Button_HouseHealthDec := TKMButton.Create(Panel_House,80,53,20,20,'-', bsGame);
    Button_HouseHealthInc := TKMButton.Create(Panel_House,160,53,20,20,'+', bsGame);
    Button_HouseHealthDec.OnClickEither := House_HealthChange;
    Button_HouseHealthInc.OnClickEither := House_HealthChange;
end;


{Store page}
procedure TKMapEdInterface.Create_Store_Page;
var I: Integer;
begin
  Panel_HouseStore := TKMPanel.Create(Panel_House,0,76,200,400);
    for I := 1 to STORE_RES_COUNT do
    begin
      Button_Store[I] := TKMButtonFlat.Create(Panel_HouseStore, 8+((I-1)mod 5)*36,8+((I-1)div 5)*42,32,36,0);
      Button_Store[I].TexID := fResource.Resources[StoreResType[I]].GUIIcon;
      Button_Store[I].Tag := I;
      Button_Store[I].Hint := fResource.Resources[StoreResType[I]].Title;
      Button_Store[I].OnClick := Store_SelectWare;
    end;

    Button_StoreDec100      := TKMButton.Create(Panel_HouseStore,116,218,20,20,'<', bsGame);
    Button_StoreDec100.Tag  := 100;
    Button_StoreDec       := TKMButton.Create(Panel_HouseStore,116,238,20,20,'-', bsGame);
    Button_StoreDec.Tag   := 1;
    Label_Store_WareCount:= TKMLabel.Create (Panel_HouseStore,156,230,40,20,'',fnt_Metal,taCenter);
    Button_StoreInc100      := TKMButton.Create(Panel_HouseStore,176,218,20,20,'>', bsGame);
    Button_StoreInc100.Tag  := 100;
    Button_StoreInc       := TKMButton.Create(Panel_HouseStore,176,238,20,20,'+', bsGame);
    Button_StoreInc.Tag   := 1;
    Button_StoreDec100.OnClickEither := Store_EditWareCount;
    Button_StoreDec.OnClickEither    := Store_EditWareCount;
    Button_StoreInc100.OnClickEither := Store_EditWareCount;
    Button_StoreInc.OnClickEither    := Store_EditWareCount;
end;


{Barracks page}
procedure TKMapEdInterface.Create_Barracks_Page;
var i:Integer;
begin
  Panel_HouseBarracks:=TKMPanel.Create(Panel_House,0,76,200,400);
    for i:=1 to BARRACKS_RES_COUNT do
    begin
      Button_Barracks[i]:=TKMButtonFlat.Create(Panel_HouseBarracks, 8+((i-1)mod 6)*31,8+((i-1)div 6)*42,28,38,0);
      Button_Barracks[i].Tag := i;
      Button_Barracks[i].TexID := fResource.Resources[BarracksResType[i]].GUIIcon;
      Button_Barracks[i].TexOffsetX := 1;
      Button_Barracks[i].TexOffsetY := 1;
      Button_Barracks[i].CapOffsetY := 2;
      Button_Barracks[i].Hint := fResource.Resources[BarracksResType[i]].Title;
      Button_Barracks[i].OnClick := Barracks_SelectWare;
    end;
    Button_BarracksDec100     := TKMButton.Create(Panel_HouseBarracks,116,218,20,20,'<', bsGame);
    Button_BarracksDec100.Tag := 100;
    Button_BarracksDec      := TKMButton.Create(Panel_HouseBarracks,116,238,20,20,'-', bsGame);
    Button_BarracksDec.Tag  := 1;
    Label_Barracks_WareCount:= TKMLabel.Create (Panel_HouseBarracks,156,230,40,20,'',fnt_Metal,taCenter);
    Button_BarracksInc100     := TKMButton.Create(Panel_HouseBarracks,176,218,20,20,'>', bsGame);
    Button_BarracksInc100.Tag := 100;
    Button_BarracksInc      := TKMButton.Create(Panel_HouseBarracks,176,238,20,20,'+', bsGame);
    Button_BarracksInc.Tag  := 1;
    Button_BarracksDec100.OnClickEither := Barracks_EditWareCount;
    Button_BarracksDec.OnClickEither    := Barracks_EditWareCount;
    Button_BarracksInc100.OnClickEither := Barracks_EditWareCount;
    Button_BarracksInc.OnClickEither    := Barracks_EditWareCount;
end;


//Should update any items changed by game (resource counts, hp, etc..)
procedure TKMapEdInterface.UpdateState(aTickCount: Cardinal);
begin
  //
end;


procedure TKMapEdInterface.Paint;
var
  I, K: Integer;
  MapLoc: TKMPointF;
  ScreenLoc: TKMPointI;
  R: TRawDeposit;
  Depo: TKMDeposits;
begin
  if fGame.MapEditor.ShowDeposits then
  begin
    Label_MatAmount.Show; //Only make it visible while we need it
    Shape_MatAmount.Show;
    Depo := fGame.MapEditor.Deposits;
    for R := Low(TRawDeposit) to High(TRawDeposit) do
      for I := 0 to Depo.Count[R] - 1 do
      begin
        Label_MatAmount.Caption := IntToStr(Depo.Amount[R, I]);

        MapLoc := fTerrain.FlatToHeight(Depo.Location[R, I]);
        ScreenLoc := fGame.Viewport.MapToScreen(MapLoc);

        //At extreme zoom coords may become out of range of SmallInt used in controls painting
        if KMInRect(ScreenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
        begin
          //Paint the background
          Shape_MatAmount.Width := 10 + 10 * Length(Label_MatAmount.Caption);
          Shape_MatAmount.Left := ScreenLoc.X - Shape_MatAmount.Width div 2;
          Shape_MatAmount.Top := ScreenLoc.Y - 10;
          Shape_MatAmount.Paint;
          //Paint the label on top of the background
          Label_MatAmount.Left := ScreenLoc.X;
          Label_MatAmount.Top := ScreenLoc.Y - 7;
          Label_MatAmount.Paint;
        end;
      end;
    Label_MatAmount.Hide; //Only make it visible while we need it
    Shape_MatAmount.Hide;
  end;

  if fGame.MapEditor.ShowDefencePositions then
  begin
    //Only make it visible while we need it
    Label_DefenceID.Show;
    Label_DefencePos.Show;
    Shape_DefencePos.Show;
    for I := 0 to fPlayers.Count - 1 do
      for K := 0 to fPlayers[I].AI.DefencePositions.Count - 1 do
      begin
        Label_DefenceID.Caption := IntToStr(K);
        Label_DefencePos.Caption := fPlayers[I].AI.DefencePositions[K].UITitle;

        MapLoc := fTerrain.FlatToHeight(KMPointF(fPlayers[I].AI.DefencePositions[K].Position.Loc));
        ScreenLoc := fGame.Viewport.MapToScreen(MapLoc);

        if KMInRect(ScreenLoc, KMRect(0, 0, Panel_Main.Width, Panel_Main.Height)) then
        begin
          //Paint the background
          Shape_DefencePos.Width := 10 + 10 * Length(Label_DefencePos.Caption);
          Shape_DefencePos.Left := ScreenLoc.X - Shape_DefencePos.Width div 2;
          Shape_DefencePos.Top := ScreenLoc.Y - 10;
          Shape_DefencePos.Paint;
          //Paint the label on top of the background
          Label_DefenceID.Left := ScreenLoc.X;
          Label_DefenceID.Top := ScreenLoc.Y - 22;
          Label_DefenceID.Paint;
          Label_DefencePos.Left := ScreenLoc.X;
          Label_DefencePos.Top := ScreenLoc.Y - 7;
          Label_DefencePos.Paint;
        end;
      end;
    //Only make it visible while we need it
    Label_DefenceID.Hide;
    Label_DefencePos.Hide;
    Shape_DefencePos.Hide;
  end;

  inherited;
end;


procedure TKMapEdInterface.SetMinimap;
begin
  MinimapView.SetMinimap(fGame.Minimap);
  MinimapView.SetViewport(fGame.Viewport);
end;


procedure TKMapEdInterface.SetMapName(const aName: string);
begin
  Label_MissionName.Caption := aName;
end;


procedure TKMapEdInterface.Defence_FillList;
var
  I: Integer;
begin
  List_Defences.Clear;

  with MyPlayer.AI.DefencePositions do
  for I := 0 to Count - 1 do
    List_Defences.Add(Positions[I].UITitle);
end;


procedure TKMapEdInterface.Defence_ItemClicked(Sender: TObject);
var
  I: Integer;
begin
  I := List_Defences.ItemIndex;
  if I = -1 then Exit;

  fGame.Viewport.Position := KMPointF(MyPlayer.AI.DefencePositions[I].Position.Loc);
end;


procedure TKMapEdInterface.Player_UpdateColors;
var I: Integer;
begin
  //Set player colors
  for I:=0 to MAX_PLAYERS-1 do
    Button_PlayerSelect[I].ShapeColor := fPlayers.Player[I].FlagColor;

  Button_Village[vtUnits].FlagColor := MyPlayer.FlagColor;
  for I := Low(Button_Citizen) to High(Button_Citizen) do
    Button_Citizen[I].FlagColor := MyPlayer.FlagColor;
  for I := Low(Button_Warriors) to High(Button_Warriors) do
    Button_Warriors[I].FlagColor := MyPlayer.FlagColor;
end;


procedure TKMapEdInterface.Player_ChangeActive(Sender: TObject);
begin
  if Panel_House.Visible or Panel_Unit.Visible or Panel_Defence.Visible then
    SwitchPage(nil);

  fPlayers.Selected := nil;

  if Sender <> nil then
    SetActivePlayer(TKMControl(Sender).Tag)
  else
    SetActivePlayer(-1);

  Player_BlockRefresh;
end;


procedure TKMapEdInterface.SetActivePlayer(aIndex: TPlayerIndex);
var I: Integer;
begin
  if aIndex <> -1 then
    MyPlayer := fPlayers.Player[aIndex]
  else
    MyPlayer := fPlayers.Player[0];

  for I := 0 to MAX_PLAYERS - 1 do
    Button_PlayerSelect[I].Down := (I = MyPlayer.PlayerIndex);

  Player_UpdateColors;
end;


procedure TKMapEdInterface.Terrain_HeightChange(Sender: TObject);
begin
  GameCursor.MapEdSize := HeightSize.Position;
  GameCursor.MapEdSlope := HeightShape.Position;

  if Sender = HeightCircle then
  begin
    HeightCircle.Down := true;
    HeightSquare.Down := false;
    GameCursor.MapEdShape := hsCircle;
  end else
  if Sender = HeightSquare then
  begin
    HeightSquare.Down := true;
    HeightCircle.Down := false;
    GameCursor.MapEdShape := hsSquare;
  end else
  if Sender = HeightElevate then
  begin
    HeightElevate.Down := True;
    HeightUnequalize.Down:=false;
    GameCursor.Mode := cm_Elevate;
  end;
  if Sender = HeightUnequalize then
  begin
    HeightElevate.Down  := false;
    HeightUnequalize.Down := true;
    GameCursor.Mode := cm_Equalize;
  end;
end;


procedure TKMapEdInterface.Terrain_TilesChange(Sender: TObject);

  function GetTileIDFromTag(aTag: byte):byte;
  var Tile:byte;
  begin
    Tile := 32*((aTag-1) div MAPED_TILES_COLS) + (aTag-1) mod MAPED_TILES_COLS + TilesScroll.Position;
    Result := MapEdTileRemap[EnsureRange(Tile+1,1,256)];
  end;

var i,k,TileID:Integer;
begin
  if Sender = TilesRandom then
    GameCursor.MapEdDir := 4 * byte(TilesRandom.Checked); //Defined=0..3 or Random=4

  if Sender = TilesScroll then //Shift tiles
    for i:=1 to MAPED_TILES_COLS do
    for k:=1 to MAPED_TILES_ROWS do
    begin
      if GetTileIDFromTag((k-1)*MAPED_TILES_COLS+i) <> 0 then
      begin
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].TexID := GetTileIDFromTag((k-1)*MAPED_TILES_COLS+i); //icons are in 2..9
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].Enable;
      end
      else
      begin
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].TexID := 0;
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].Disable;
      end;
      if GameCursor.Mode = cm_Tiles then
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].Down := (GameCursor.Tag1+1 = GetTileIDFromTag((k-1)*MAPED_TILES_COLS+i));
    end;
  if Sender is TKMButtonFlat then
  begin
    TileID := GetTileIDFromTag(TKMButtonFlat(Sender).Tag);
    if TileID <> 0 then
    begin
      GameCursor.Mode := cm_Tiles;
      GameCursor.Tag1 := TileID-1; //MapEdTileRemap is 1 based, tag is 0 based
      if TilesRandom.Checked then
        GameCursor.MapEdDir := 4;
      for i:=1 to MAPED_TILES_COLS do
      for k:=1 to MAPED_TILES_ROWS do
        TilesTable[(i-1)*MAPED_TILES_ROWS+k].Down := (Sender = TilesTable[(i-1)*MAPED_TILES_ROWS+k]);
    end;
  end;
end;


procedure TKMapEdInterface.Terrain_ObjectsChange(Sender: TObject);
var I, ObjID: Integer;
begin
  for I := 0 to 8 do
    ObjectsTable[i].Down := False;

  ObjectErase.Down := False;

  if Sender = ObjectsScroll then
  begin
    for I := 0 to 8 do
    begin
      ObjID := ObjectsScroll.Position * 3 + I;
      if ObjID < fResource.MapElements.ValidCount then
      begin
        ObjectsTable[I].TexID := MapElem[fResource.MapElements.ValidToObject[ObjID]].Anim.Step[1] + 1;
        ObjectsTable[I].Caption := IntToStr(ObjID);
        ObjectsTable[I].Enable;
      end
      else
      begin
        ObjectsTable[I].TexID := 0;
        ObjectsTable[I].Caption := '';
        ObjectsTable[I].Disable;
      end;
      ObjectsTable[I].Down := ObjID = fResource.MapElements.ObjectToValid[GameCursor.Tag1]; //Mark the selected one using reverse lookup
    end;
    ObjectErase.Down := (GameCursor.Tag1 = 255); //or delete button
  end;

  if Sender is TKMButtonFlat then
  begin
    ObjID := ObjectsScroll.Position * 3 + TKMButtonFlat(Sender).Tag; //0..n-1

    if (not InRange(ObjID, 0, fResource.MapElements.ValidCount - 1))
    and not (TKMButtonFlat(Sender).Tag = 255) then
      Exit; //Don't let them click if it is out of range

    GameCursor.Mode := cm_Objects;
    if TKMButtonFlat(Sender).Tag = 255 then
      GameCursor.Tag1 := 255 //erase object
    else
      GameCursor.Tag1 := fResource.MapElements.ValidToObject[ObjID]; //0..n-1
    for I := 0 to 8 do
      ObjectsTable[I].Down := (Sender = ObjectsTable[I]); //Mark the selected one
    ObjectErase.Down := (Sender = ObjectErase); //or delete button
  end;
end;


procedure TKMapEdInterface.Build_ButtonClick(Sender: TObject);
var I: Integer;
begin
  //Release all buttons
  for I := 1 to Panel_Build.ChildCount do
    if Panel_Build.Childs[I] is TKMButtonFlat then
      TKMButtonFlat(Panel_Build.Childs[I]).Down := False;

  //Press the button
  TKMButtonFlat(Sender).Down := True;

  //Reset cursor and see if it needs to be changed
  GameCursor.Mode := cm_None;
  GameCursor.Tag1 := 0;

  if Button_BuildCancel.Down then
    GameCursor.Mode := cm_Erase
  else
  if Button_BuildRoad.Down then
    GameCursor.Mode := cm_Road
  else
  if Button_BuildField.Down then
    GameCursor.Mode := cm_Field
  else
  if Button_BuildWine.Down then
    GameCursor.Mode := cm_Wine
  else
  //if Button_BuildWall.Down then
  //  GameCursor.Mode:=cm_Wall;
  //else
  for I := 1 to GUI_HOUSE_COUNT do
  if GUIHouseOrder[I] <> ht_None then
  if Button_Build[I].Down then begin
     GameCursor.Mode := cm_Houses;
     GameCursor.Tag1 := Byte(GUIHouseOrder[I]);
  end;
end;


procedure TKMapEdInterface.Unit_ButtonClick(Sender: TObject);
var I: Integer;
begin
  //Reset cursor and see if it needs to be changed
  GameCursor.Mode := cm_None;
  GameCursor.Tag1 := 0;

  if Sender = nil then Exit;

  //Release all buttons
  for I := 1 to Panel_Units.ChildCount do
    if Panel_Units.Childs[I] is TKMButtonFlat then
      TKMButtonFlat(Panel_Units.Childs[I]).Down := False;

  //Press the Sender button
  TKMButtonFlat(Sender).Down := True;

  if Button_UnitCancel.Down then
    GameCursor.Mode := cm_Erase
  else
  if (TKMButtonFlat(Sender).Tag in [byte(UNIT_MIN)..byte(UNIT_MAX)]) then
  begin
    GameCursor.Mode := cm_Units;
    GameCursor.Tag1 := byte(TKMButtonFlat(Sender).Tag);
  end;
end;


procedure TKMapEdInterface.View_Passability(Sender: TObject);
begin
  SHOW_TERRAIN_WIRES := (TKMTrackBar(Sender).Position <> 0);
  SHOW_TERRAIN_PASS := TKMTrackBar(Sender).Position;

  if TKMTrackBar(Sender).Position <> 0 then
    Label_Passability.Caption := GetEnumName(TypeInfo(TPassability), SHOW_TERRAIN_PASS)
  else
    Label_Passability.Caption := 'Off';
end;


procedure TKMapEdInterface.ShowHouseInfo(Sender: TKMHouse);
begin
  if Sender = nil then
  begin
    SwitchPage(nil);
    exit;
  end;

  SetActivePlayer(Sender.GetOwner);

  {Common data}
  Label_House.Caption:=fResource.HouseDat[Sender.HouseType].HouseName;
  Image_House_Logo.TexID:=fResource.HouseDat[Sender.HouseType].GUIIcon;
  Image_House_Worker.TexID:=fResource.UnitDat[fResource.HouseDat[Sender.HouseType].OwnerType].GUIIcon;
  Image_House_Worker.FlagColor := fPlayers[Sender.GetOwner].FlagColor;
  Image_House_Worker.Hint := fResource.UnitDat[fResource.HouseDat[Sender.HouseType].OwnerType].UnitName;
  KMHealthBar_House.Caption:=inttostr(round(Sender.GetHealth))+'/'+inttostr(fResource.HouseDat[Sender.HouseType].MaxHealth);
  KMHealthBar_House.Position := Sender.GetHealth / fResource.HouseDat[Sender.HouseType].MaxHealth;

  Image_House_Worker.Visible := fResource.HouseDat[Sender.HouseType].OwnerType <> ut_None;


  case Sender.HouseType of
    ht_Store: begin
          Store_Fill(nil);
          SwitchPage(Panel_HouseStore);
          Store_SelectWare(Button_Store[fStorehouseItem]); //Reselect the ware so the display is updated
        end;

    ht_Barracks: begin
          Barracks_Fill(nil);
          Image_House_Worker.Enable; //In the barrack the recruit icon is always enabled
          SwitchPage(Panel_HouseBarracks);
          Barracks_SelectWare(Button_Barracks[fBarracksItem]); //Reselect the ware so the display is updated
          end;
    ht_TownHall:;
    else SwitchPage(Panel_House);
  end;
end;


procedure TKMapEdInterface.ShowUnitInfo(Sender: TKMUnit);
var Commander: TKMUnitWarrior;
begin
  if (Sender = nil) or not Sender.Visible or Sender.IsDead then
  begin
    SwitchPage(nil);
    Exit;
  end;

  SetActivePlayer(Sender.GetOwner);

  SwitchPage(Panel_Unit);
  Label_UnitName.Caption := fResource.UnitDat[Sender.UnitType].UnitName;
  Image_UnitPic.TexID := fResource.UnitDat[Sender.UnitType].GUIScroll;
  Image_UnitPic.FlagColor := fPlayers[Sender.GetOwner].FlagColor;
  KMConditionBar_Unit.Position := Sender.Condition / UNIT_MAX_CONDITION;
  if Sender is TKMUnitWarrior then
  begin
    //Warrior specific
    Label_UnitDescription.Hide;
    Commander := TKMUnitWarrior(Sender).GetCommander;
    if Commander<>nil then
    begin
      ImageStack_Army.SetCount(Commander.fMapEdMembersCount + 1, Commander.UnitsPerRow, Commander.UnitsPerRow div 2 + 1); //Count+commander, Columns
      Label_ArmyCount.Caption := IntToStr(Commander.fMapEdMembersCount + 1);
    end;
    Panel_Army.Show;
  end
  else
  begin
    //Citizen specific
    Label_UnitDescription.Caption := fResource.UnitDat[Sender.UnitType].Description;
    Label_UnitDescription.Show;
  end;
end;


procedure TKMapEdInterface.Menu_Save(Sender:TObject);
begin
  if (Sender = Edit_SaveName) or (Sender = Radio_Save_MapType) then
  begin
    CheckBox_SaveExists.Enabled := FileExists(MapNameToPath(Edit_SaveName.Text, 'dat', Radio_Save_MapType.ItemIndex = 1));
    Label_SaveExists.Visible := CheckBox_SaveExists.Enabled;
    CheckBox_SaveExists.Checked := false;
    Button_SaveSave.Enabled := not CheckBox_SaveExists.Enabled;
  end;

  if Sender = CheckBox_SaveExists then
    Button_SaveSave.Enabled := CheckBox_SaveExists.Checked;

  if Sender = Button_SaveSave then begin
    //Should we expand the path here? It depends.. since we are passing mask for map/dat files/folder
    fGame.SaveMapEditor(Edit_SaveName.Text, Radio_Save_MapType.ItemIndex = 1);

    Player_UpdateColors;
    Player_ChangeActive(nil);
    Label_MissionName.Caption := fGame.GameName;

    SwitchPage(Button_SaveCancel); //return to previous menu
  end;
end;


//Mmission loading dialog
procedure TKMapEdInterface.Menu_Load(Sender: TObject);
var
  MapName: string;
  IsMulti: Boolean;
begin
  if ListBox_Load.ItemIndex = -1 then Exit;

  MapName := ListBox_Load.Item[ListBox_Load.ItemIndex];
  IsMulti := Radio_Load_MapType.ItemIndex = 1;
  fGameApp.NewMapEditor(MapNameToPath(MapName, 'dat', IsMulti), 0, 0);
  //Keep MP/SP selected in the new map editor interface (this one is destroyed already)
  if (fGame <> nil) and (fGame.MapEditorInterface <> nil) then
    fGame.MapEditorInterface.SetLoadMode(IsMulti);
end;


{Quit the mission and return to main menu}
procedure TKMapEdInterface.Menu_QuitMission(Sender:TObject);
begin
  fGameApp.Stop(gr_MapEdEnd);
end;


procedure TKMapEdInterface.Load_MapTypeChange(Sender: TObject);
begin
  Load_MapListUpdate;
end;


procedure TKMapEdInterface.Load_MapListUpdate;
begin
  fMaps.TerminateScan;
  fMapsMP.TerminateScan;

  ListBox_Load.SetItems('');
  ListBox_Load.ItemIndex := -1;

  if Radio_Load_MapType.ItemIndex = 0 then
    fMaps.Refresh(Load_MapListUpdateDone)
  else
    fMapsMP.Refresh(Load_MapListUpdateDone);
end;


procedure TKMapEdInterface.Load_MapListUpdateDone(Sender: TObject);
begin
  if Radio_Load_MapType.ItemIndex = 0 then
    ListBox_Load.SetItems(fMaps.MapList)
  else
    ListBox_Load.SetItems(fMapsMP.MapList);

  //Try to select first map by default
  if ListBox_Load.ItemIndex = -1 then
    ListBox_Load.ItemIndex := 0;
end;


//This function will be called if the user right clicks on the screen.
procedure TKMapEdInterface.RightClick_Cancel;
begin
  //We should drop the tool but don't close opened tab. This allows eg: Place a warrior, right click so you are not placing more warriors, select the placed warrior.
  //Before you would have had to close the tab to do this.
  if GetShownPage = esp_Terrain then exit; //Terrain uses both buttons for relief changing, tile rotation etc.
  GameCursor.Mode:=cm_None;
  GameCursor.Tag1:=0;
end;


procedure TKMapEdInterface.SetTileDirection(aTileDirection: byte);
begin
  fTileDirection := aTileDirection mod 4; //0..3
  GameCursor.MapEdDir := fTileDirection;
end;


procedure TKMapEdInterface.SetLoadMode(aMultiplayer:boolean);
begin
  if aMultiplayer then
  begin
    Radio_Load_MapType.ItemIndex := 1;
    Radio_Save_MapType.ItemIndex := 1;
  end
  else
  begin
    Radio_Load_MapType.ItemIndex := 0;
    Radio_Save_MapType.ItemIndex := 0;
  end;
end;


function TKMapEdInterface.GetSelectedTile: TObject;
var i: byte;
begin
  Result := nil;
  for i:=1 to MAPED_TILES_COLS*MAPED_TILES_ROWS do
    if TilesTable[i].Down then Result := TilesTable[i];
end;


function TKMapEdInterface.GetSelectedObject: TObject;
var i: byte;
begin
  Result := nil;
  for i:=1 to 4 do
    if ObjectsTable[i].Down then Result := ObjectsTable[i];
end;


function TKMapEdInterface.GetSelectedUnit: TObject;
var i: byte;
begin
  Result := nil;
  for i:=0 to High(Button_Citizen) do
    if Button_Citizen[i].Down then Result := Button_Citizen[i];
  for i:=0 to High(Button_Warriors) do
    if Button_Warriors[i].Down then Result := Button_Warriors[i];
  for i:=0 to High(Button_Animals) do
    if Button_Animals[i].Down then Result := Button_Animals[i];
end;


procedure TKMapEdInterface.Store_Fill(Sender:TObject);
var i,Tmp:Integer;
begin
  if fPlayers.Selected=nil then exit;
  if not (fPlayers.Selected is TKMHouseStore) then exit;
  for i:=1 to STORE_RES_COUNT do begin
    Tmp := TKMHouseStore(fPlayers.Selected).CheckResIn(StoreResType[i]);
    Button_Store[i].Caption := IfThen(Tmp = 0, '-', inttostr(Tmp));
  end;
end;


procedure TKMapEdInterface.Barracks_Fill(Sender:TObject);
var i,Tmp:Integer;
begin
  if fPlayers.Selected=nil then exit;
  if not (fPlayers.Selected is TKMHouseBarracks) then exit;

  for i:=1 to BARRACKS_RES_COUNT do begin
    Tmp := TKMHouseBarracks(fPlayers.Selected).CheckResIn(BarracksResType[i]);
    Button_Barracks[i].Caption := IfThen(Tmp = 0, '-', inttostr(Tmp));
  end;
end;


procedure TKMapEdInterface.House_HealthChange(Sender: TObject; AButton: TMouseButton);
var
  H: TKMHouse;
begin
  if not (fPlayers.Selected is TKMHouse) then Exit;
  H := TKMHouse(fPlayers.Selected);

  if Sender = Button_HouseHealthDec then H.AddDamage(ClickAmount[AButton] * 5, True);
  if Sender = Button_HouseHealthInc then H.AddRepair(ClickAmount[AButton] * 5);
  if H.IsDestroyed then
    ShowHouseInfo(nil)
  else
    ShowHouseInfo(H);
end;


procedure TKMapEdInterface.Unit_ArmyChange1(Sender: TObject);
var Commander:TKMUnitWarrior;
begin
  if not (fPlayers.Selected is TKMUnitWarrior) then Exit;

  Commander := TKMUnitWarrior(fPlayers.Selected).GetCommander;
  if Sender = Button_Army_ForUp then Commander.UnitsPerRow := max(Commander.UnitsPerRow-1,1);
  if Sender = Button_Army_ForDown then Commander.UnitsPerRow := min(Commander.UnitsPerRow+1,Commander.fMapEdMembersCount+1);
  ImageStack_Army.SetCount(Commander.fMapEdMembersCount + 1, Commander.UnitsPerRow, Commander.UnitsPerRow div 2 + 1);
  Label_ArmyCount.Caption := IntToStr(Commander.fMapEdMembersCount + 1);

  if Sender = Button_Army_RotCW then Commander.Direction := KMNextDirection(Commander.Direction);
  if Sender = Button_Army_RotCCW then Commander.Direction := KMPrevDirection(Commander.Direction);
  Commander.AnimStep := UnitStillFrames[Commander.Direction];

  //Toggle between full and half condition
  if Sender = Button_ArmyFood then
  begin
    if Commander.Condition = UNIT_MAX_CONDITION then
      Commander.Condition := UNIT_MAX_CONDITION div 2
    else
      Commander.Condition := UNIT_MAX_CONDITION;
    KMConditionBar_Unit.Position := Commander.Condition / UNIT_MAX_CONDITION;
  end;
end;


procedure TKMapEdInterface.Unit_ArmyChange2(Sender: TObject; AButton: TMouseButton);
var
  NewCount: Integer;
  Commander: TKMUnitWarrior;
begin
  if not (fPlayers.Selected is TKMUnitWarrior) then Exit;

  Commander := TKMUnitWarrior(fPlayers.Selected).GetCommander;

  if Sender = Button_ArmyDec then //Decrease
    NewCount := Commander.fMapEdMembersCount - ClickAmount[AButton]
  else //Increase
    NewCount := Commander.fMapEdMembersCount + ClickAmount[AButton];

  Commander.fMapEdMembersCount := EnsureRange(NewCount, 0, 200); //Limit max members
  Commander.UnitsPerRow := min(Commander.UnitsPerRow,Commander.fMapEdMembersCount+1); //Ensure units per row is <= unit count
  ImageStack_Army.SetCount(Commander.fMapEdMembersCount + 1, Commander.UnitsPerRow, Commander.UnitsPerRow div 2 + 1);
  Label_ArmyCount.Caption := IntToStr(Commander.fMapEdMembersCount + 1);
end;


procedure TKMapEdInterface.Barracks_SelectWare(Sender: TObject);
var I: Integer;
begin
  if not Panel_HouseBarracks.Visible then exit;
  if not (Sender is TKMButtonFlat) then exit; //Only FlatButtons
  if TKMButtonFlat(Sender).Tag = 0 then exit; //with set Tag

  for i:=1 to BARRACKS_RES_COUNT do
    Button_Barracks[i].Down := False;
  TKMButtonFlat(Sender).Down := True;
  fBarracksItem := TKMButtonFlat(Sender).Tag;
  Barracks_EditWareCount(Sender, mbLeft);
end;


procedure TKMapEdInterface.Store_SelectWare(Sender:TObject);
var i:Integer;
begin
  if not Panel_HouseStore.Visible then exit;
  if not (Sender is TKMButtonFlat) then exit; //Only FlatButtons
  if TKMButtonFlat(Sender).Tag = 0 then exit; //with set Tag
  for i:=1 to length(Button_Store) do
    Button_Store[i].Down := false;
  TKMButtonFlat(Sender).Down := true;
  fStorehouseItem := TKMButtonFlat(Sender).Tag;
  Store_EditWareCount(Sender, mbLeft);
end;


procedure TKMapEdInterface.Barracks_EditWareCount(Sender:TObject; AButton:TMouseButton);
var
  Res: TResourceType;
  Barracks: TKMHouseBarracks;
  NewCount: Word;
begin
  if not Panel_HouseBarracks.Visible or not (fPlayers.Selected is TKMHouseBarracks) then Exit;

  Res := BarracksResType[fBarracksItem];
  Barracks := TKMHouseBarracks(fPlayers.Selected);

  if (Sender = Button_BarracksDec100) or (Sender = Button_BarracksDec) then begin
    NewCount := Math.Min(Barracks.CheckResIn(Res), ClickAmount[aButton] * TKMButton(Sender).Tag);
    Barracks.ResTakeFromOut(Res, NewCount);
  end;

  if (Sender = Button_BarracksInc100) or (Sender = Button_BarracksInc) then begin
    NewCount := Math.Min(High(Word) - Barracks.CheckResIn(Res), ClickAmount[aButton] * TKMButton(Sender).Tag);
    Barracks.ResAddToIn(Res, NewCount);
  end;

  Label_Barracks_WareCount.Caption := IntToStr(Barracks.CheckResIn(Res));
  Barracks_Fill(nil);
end;


procedure TKMapEdInterface.Store_EditWareCount(Sender:TObject; AButton:TMouseButton);
var
  Res: TResourceType;
  Store: TKMHouseStore;
  NewCount: Word;
begin
  if not Panel_HouseStore.Visible or not (fPlayers.Selected is TKMHouseStore) then Exit;

  Res := StoreResType[fStorehouseItem];
  Store := TKMHouseStore(fPlayers.Selected);

  //We need to take no more than it is there, thats part of bugtracking idea
  if (Sender = Button_StoreDec100) or (Sender = Button_StoreDec) then begin
    NewCount := Math.Min(Store.CheckResIn(Res), ClickAmount[aButton]*TKMButton(Sender).Tag);
    Store.ResTakeFromOut(Res, NewCount);
  end;

  //We can always add any amount of resource, it will be capped by Store
  if (Sender = Button_StoreInc100) or (Sender = Button_StoreInc) then
    Store.ResAddToIn(Res, ClickAmount[aButton]*TKMButton(Sender).Tag);

  Label_Store_WareCount.Caption := inttostr(Store.CheckResIn(Res));
  Store_Fill(nil);
end;


procedure TKMapEdInterface.Player_ColorClick(Sender:TObject);
begin
  if not (Sender = ColorSwatch_Color) then exit;
  MyPlayer.FlagColor := ColorSwatch_Color.GetColor;
  Player_UpdateColors;
end;


procedure TKMapEdInterface.Player_BlockClick(Sender:TObject);
var
  I: Integer;
  H: THouseType;
begin
  I := TKMButtonFlat(Sender).Tag;
  H := GUIHouseOrder[I];

  //Loop through states CanBuild > CantBuild > Released
  if not MyPlayer.Stats.HouseBlocked[H] and not MyPlayer.Stats.HouseGranted[H] then
  begin
    MyPlayer.Stats.HouseBlocked[H] := True;
    MyPlayer.Stats.HouseGranted[H] := False;
    Image_BlockHouse[I].TexID := 32;
  end else
  if MyPlayer.Stats.HouseBlocked[H] and not MyPlayer.Stats.HouseGranted[H] then
  begin
    MyPlayer.Stats.HouseBlocked[H] := False;
    MyPlayer.Stats.HouseGranted[H] := True;
    Image_BlockHouse[I].TexID := 33;
  end else
  begin
    MyPlayer.Stats.HouseBlocked[H] := False;
    MyPlayer.Stats.HouseGranted[H] := False;
    Image_BlockHouse[I].TexID := 0;
  end;
end;


procedure TKMapEdInterface.Player_BlockRefresh;
var
  I: Integer;
  H: THouseType;
begin
  for I := 1 to GUI_HOUSE_COUNT do
  begin
    H := GUIHouseOrder[I];
    if MyPlayer.Stats.HouseBlocked[H] and not MyPlayer.Stats.HouseGranted[H] then
      Image_BlockHouse[I].TexID := 32
    else
    if MyPlayer.Stats.HouseGranted[H] and not MyPlayer.Stats.HouseBlocked[H] then
      Image_BlockHouse[I].TexID := 33
    else
    if not MyPlayer.Stats.HouseGranted[H] and not MyPlayer.Stats.HouseBlocked[H] then
      Image_BlockHouse[I].TexID := 0
    else
      Image_BlockHouse[I].TexID := 24; //Some erroneous value
  end;
end;


procedure TKMapEdInterface.Mission_AlliancesChange(Sender:TObject);
var i,k:Integer;
begin
  if Sender = nil then begin
    for i:=0 to fPlayers.Count-1 do
    for k:=0 to fPlayers.Count-1 do
      if (fPlayers.Player[i]<>nil)and(fPlayers.Player[k]<>nil) then
        CheckBox_Alliances[i,k].Checked := (fPlayers.CheckAlliance(fPlayers.Player[i].PlayerIndex, fPlayers.Player[k].PlayerIndex)=at_Ally)
      else
        CheckBox_Alliances[i,k].Disable; //Player does not exist?
    exit;
  end;

  i := TKMCheckBox(Sender).Tag div fPlayers.Count;
  k := TKMCheckBox(Sender).Tag mod fPlayers.Count;
  if CheckBox_Alliances[i,k].Checked then fPlayers.Player[i].Alliances[k] := at_Ally
                                     else fPlayers.Player[i].Alliances[k] := at_Enemy;

  //Copy status to symmetrical item
  if CheckBox_AlliancesSym.Checked then begin
    CheckBox_Alliances[k,i].Checked := CheckBox_Alliances[i,k].Checked;
    fPlayers.Player[k].Alliances[i] := fPlayers.Player[i].Alliances[k];
  end;
end;


procedure TKMapEdInterface.Mission_PlayerTypesChange(Sender:TObject);
var i:Integer;
begin
  if Sender = nil then begin
    for i:=0 to fPlayers.Count-1 do
    begin
      CheckBox_PlayerTypes[i,0].Enabled := fPlayers[i]<>nil;
      CheckBox_PlayerTypes[i,1].Enabled := fPlayers[i]<>nil;
      CheckBox_PlayerTypes[i,0].Checked := (fPlayers[i]<>nil) and (fPlayers[i].PlayerType = pt_Human);
      CheckBox_PlayerTypes[i,1].Checked := (fPlayers[i]<>nil) and (fPlayers[i].PlayerType = pt_Computer);
    end;
    Exit;
  end;

  //@Lewin: Are we allowed to define players freely, e.g. make 5 Human players?
  //How is it working in multiplayer?
  //@Krom: In KaM it works like this: Single player missions have 1 human player and the others computer.
  //       For multiplayer the players are all humans. (although they are not defined in the script with !SET_HUMAN_PLAYER as that is for single missions)
  //       I think we should be a bit more relaxed about it. Here are some cases:
  //       1. Campaign/single missions: Only 1 player is human, the others are computer and this cannot be changed. (usually story based)
  //       2. Tournament missions: (like single missions from TPR but configurable for every game) All players start equal and any can be
  //                               human/AI/not-participating. This means you can chose the number of enemies you wish to fight, and configure alliances.
  //                               e.g. I can chose to fight with me plus 1 computer (team 1) against 3 computers allied together. (team 2)
  //       3. Multiplayer tournament: Same as a single tournament mission, but you can have many humans and many AI. (with configurable teams or deathmatch)
  //       4. Multiplayer cooperative: Similar to a tournament but one or more AI are fixed and cannot be made human. (and the mission is usually story based)
  //                                   This allows a mission to be made where many humans siege AI players in a castle, where the AI have an obvious
  //                                   advantage and the humans must work together to defeat them.
  //       These are just some ideas for the kinds of missions I think we should allow. Note that TPR only allows for types 1 and 3.
  //       I do NOT think that each mission should be given a "type" of the ones mentioned above. That just makes things complicated having 4 mission types.
  //       We do not even need a single/multiplayer distinction. I think we can make this work by having two kinds of players:
  //       a) General: which can be controlled by a human or a computer
  //       b) Fixed AI: which can only be computers, never human controlled.
  //       Therefore both single and multiplayer tournament missions will only use General players, but the other two types will use
  //       some Fixed AI for the players which must always be computer controlled, and some General players which can be either or not-participating.
  //       When you make a mission you can define AI options for the General players if you wish, otherwise they will use defaults. (and figure it out
  //       automatically) Fixed AI will mostly need to be told how to behave, for the story make sense and fit with the circumstances.
  //       (e.g. so they don't try to build a city when it is a siege mission) This allows single player missions to be used for multiplayer and vice versa.
  //       These are just ideas and I think they could be redesigned in a less confusing way for both the players and mission creators.
  //       Let me know what you think. Maybe we should discuss this.
  //@Lewin: Looks like we can't achieve it without changing(adding) mission scripts.. discussed in ICQ.

  //Reset everything
  for i:=0 to fPlayers.Count-1 do
  begin
    CheckBox_PlayerTypes[i,0].Checked := false;
    CheckBox_PlayerTypes[i,1].Checked := true;
    fPlayers[i].PlayerType := pt_Computer;
  end;

  //Define only 1 human player
  i := TKMCheckBox(Sender).Tag;
  if Sender = CheckBox_PlayerTypes[i,0] then
  begin
    CheckBox_PlayerTypes[i,0].Checked := true;
    CheckBox_PlayerTypes[i,1].Checked := false;
    fPlayers[i].PlayerType := pt_Human
  end;
end;


procedure TKMapEdInterface.KeyDown(Key: Word; Shift: TShiftState);
begin
  if fMyControls.KeyDown(Key, Shift) then
  begin
    fGame.Viewport.ReleaseScrollKeys; //Release the arrow keys when you open a window with an edit to stop them becoming stuck
    Exit; //Handled by Controls
  end;

  //DoPress is not working properly yet. GamePlay only uses DoClick so MapEd can be the same for now.
  //1-5 game menu shortcuts
  //if Key in [49..53] then
  //  Button_Main[Key-48].DoPress;

  //Scrolling
  if Key = VK_LEFT  then fGame.Viewport.ScrollKeyLeft  := true;
  if Key = VK_RIGHT then fGame.Viewport.ScrollKeyRight := true;
  if Key = VK_UP    then fGame.Viewport.ScrollKeyUp    := true;
  if Key = VK_DOWN  then fGame.Viewport.ScrollKeyDown  := true;
end;


procedure TKMapEdInterface.KeyUp(Key: Word; Shift: TShiftState);
begin
  if fMyControls.KeyUp(Key, Shift) then Exit; //Handled by Controls

  //1-5 game menu shortcuts
  if Key in [49..53] then
    Button_Main[Key-48].Click;

  //Scrolling
  if Key = VK_LEFT  then fGame.Viewport.ScrollKeyLeft  := false;
  if Key = VK_RIGHT then fGame.Viewport.ScrollKeyRight := false;
  if Key = VK_UP    then fGame.Viewport.ScrollKeyUp    := false;
  if Key = VK_DOWN  then fGame.Viewport.ScrollKeyDown  := false;

  //Backspace resets the zoom and view, similar to other RTS games like Dawn of War.
  //This is useful because it is hard to find default zoom using the scroll wheel, and if not zoomed 100% things can be scaled oddly (like shadows)
  if Key = VK_BACK  then fGame.Viewport.ResetZoom;
end;


procedure TKMapEdInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  inherited;

  //So terrain brushes start on mouse down not mouse move
  if fMyControls.CtrlOver = nil then
    fGame.UpdateGameCursor(X,Y,Shift);
end;


procedure TKMapEdInterface.MouseMove(Shift: TShiftState; X,Y: Integer);
var P: TKMPoint;
begin
  inherited;

  if fMyControls.CtrlOver <> nil then
  begin
    GameCursor.SState := []; //Don't do real-time elevate when the mouse is over controls, only terrain
    Exit;
  end;

  fGame.UpdateGameCursor(X,Y,Shift);
  if GameCursor.Mode = cm_None then
    if fPlayers.HitTest(GameCursor.Cell.X, GameCursor.Cell.Y, False) <> nil then
      fResource.Cursors.Cursor := kmc_Info
    else
      if not fGame.Viewport.Scrolling then
        fResource.Cursors.Cursor := kmc_Default;

  Label_Coordinates.Caption := Format('X: %d, Y: %d',[GameCursor.Cell.X,GameCursor.Cell.Y]);

  if ssLeft in Shift then //Only allow placing of roads etc. with the left mouse button
  begin
    P := GameCursor.Cell; //Get cursor position tile-wise
    case GameCursor.Mode of
      cm_Road:      if MyPlayer.CanAddFieldPlan(P, ft_Road) then MyPlayer.AddField(P, ft_Road);
      cm_Field:     if MyPlayer.CanAddFieldPlan(P, ft_Corn) then MyPlayer.AddField(P, ft_Corn);
      cm_Wine:      if MyPlayer.CanAddFieldPlan(P, ft_Wine) then MyPlayer.AddField(P, ft_Wine);
      //cm_Wall:  if MyPlayer.CanAddFieldPlan(P, ft_Wall) then MyPlayer.AddField(P, ft_Wine);
      cm_Objects:   if GameCursor.Tag1 = 255 then fTerrain.SetTree(P, 255); //Allow many objects to be deleted at once
      cm_Erase:     case GetShownPage of
                      esp_Terrain:    fTerrain.Land[P.Y,P.X].Obj := 255;
                      esp_Units:      fPlayers.RemAnyUnit(P);
                      esp_Buildings:  begin
                                        fPlayers.RemAnyHouse(P);
                                        if fTerrain.Land[P.Y,P.X].TileOverlay = to_Road then
                                          fTerrain.RemRoad(P);
                                        if fTerrain.TileIsCornField(P) or fTerrain.TileIsWineField(P) then
                                          fTerrain.RemField(P);
                                      end;
                    end;
    end;
  end;
end;


procedure TKMapEdInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
var P: TKMPoint;
begin
  inherited;

  if fMyControls.CtrlOver <> nil then begin
    fMyControls.MouseUp(X,Y,Shift,Button);
    exit; //We could have caused fGame reinit, so exit at once
  end;

  fGame.UpdateGameCursor(X, Y, Shift); //Updates the shift state
  P := GameCursor.Cell; //Get cursor position tile-wise
  if Button = mbRight then
  begin
    RightClick_Cancel;

    //Right click performs some special functions and shortcuts
    case GameCursor.Mode of
      cm_Tiles:   begin
                    SetTileDirection(GameCursor.MapEdDir+1); //Rotate tile direction
                    TilesRandom.Checked := false; //Reset
                  end;
      cm_Objects: fTerrain.Land[P.Y,P.X].Obj := 255; //Delete object
    end;
    //Move the selected object to the cursor location
    if fPlayers.Selected is TKMHouse then
      TKMHouse(fPlayers.Selected).SetPosition(P); //Can place is checked in SetPosition

    if fPlayers.Selected is TKMUnit then
      if fTerrain.CanPlaceUnit(P, TKMUnit(fPlayers.Selected).UnitType) then
        TKMUnit(fPlayers.Selected).SetPosition(P);

  end
  else
  if Button = mbLeft then //Only allow placing of roads etc. with the left mouse button
    case GameCursor.Mode of
      cm_None:  begin
                  fPlayers.SelectHitTest(GameCursor.Cell.X, GameCursor.Cell.Y, False);

                  if fPlayers.Selected is TKMHouse then
                    ShowHouseInfo(TKMHouse(fPlayers.Selected));
                  if fPlayers.Selected is TKMUnit then
                    ShowUnitInfo(TKMUnit(fPlayers.Selected));
                end;
      cm_Road:  if MyPlayer.CanAddFieldPlan(P, ft_Road) then MyPlayer.AddField(P, ft_Road);
      cm_Field: if MyPlayer.CanAddFieldPlan(P, ft_Corn) then MyPlayer.AddField(P, ft_Corn);
      cm_Wine:  if MyPlayer.CanAddFieldPlan(P, ft_Wine) then MyPlayer.AddField(P, ft_Wine);
      //cm_Wall:
      cm_Houses:if MyPlayer.CanAddHousePlan(P, THouseType(GameCursor.Tag1)) then
                begin
                  MyPlayer.AddHouse(THouseType(GameCursor.Tag1), P.X, P.Y, true);
                  Build_ButtonClick(Button_BuildRoad);
                end;
      cm_Elevate,
      cm_Equalize:; //handled in UpdateStateIdle
      cm_Objects: fTerrain.SetTree(P, GameCursor.Tag1);
      cm_Units: if fTerrain.CanPlaceUnit(P, TUnitType(GameCursor.Tag1)) then
                begin //Check if we can really add a unit
                  if TUnitType(GameCursor.Tag1) in [HUMANS_MIN..HUMANS_MAX] then
                    MyPlayer.AddUnit(TUnitType(GameCursor.Tag1), P, false)
                  else
                    fPlayers.PlayerAnimals.AddUnit(TUnitType(GameCursor.Tag1), P, false);
                end;
      cm_Erase:
                case GetShownPage of
                  esp_Terrain:    fTerrain.Land[P.Y,P.X].Obj := 255;
                  esp_Units:      begin
                                    fPlayers.RemAnyUnit(P);
                                  end;
                  esp_Buildings:  begin
                                    fPlayers.RemAnyHouse(P);
                                    if fTerrain.Land[P.Y,P.X].TileOverlay = to_Road then
                                      fTerrain.RemRoad(P);
                                    if fTerrain.TileIsCornField(P) or fTerrain.TileIsWineField(P) then
                                      fTerrain.RemField(P);
                                  end;
                end;
    end;
end;


function TKMapEdInterface.GetShownPage: TKMMapEdShownPage;
begin
  Result := esp_Unknown;
  if Panel_Terrain.Visible then
    Result := esp_Terrain;
  if Panel_Build.Visible then
    Result := esp_Buildings;
  if Panel_Units.Visible then
    Result := esp_Units;
end;


end.