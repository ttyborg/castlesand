unit KM_Unit1;
interface
uses
  Windows, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, FileCtrl, ExtCtrls, ComCtrls,
  Menus, Buttons, math, SysUtils, KromUtils, OpenGL, KromOGLUtils, dglOpenGL, JPEG,
  KM_Render, KM_RenderUI, KM_ReadGFX1, KM_Defaults, KM_GamePlayInterface,
  KM_Form_Loading, KM_Terrain, KM_Global_Data,
  KM_Units, KM_Houses, KM_Viewport, KM_Log, KM_Users, KM_Controls, ColorPicker, KM_LoadLib, KM_LoadSFX;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    Panel_Minimap: TPanel;
    MiniMap: TImage;
    ShapeFOV: TShape;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    OpenMapMenu: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    About1: TMenuItem;
    Advanced1: TMenuItem;
    ShowWires: TMenuItem;
    ShowObjects: TMenuItem;
    ShowFlatTerrain: TMenuItem;
    Panel5: TPanel;
    Timer100ms: TTimer;
    PrintScreen1: TMenuItem;
    Export1: TMenuItem;
    ExportGUIRX: TMenuItem;
    ExportTreesRX: TMenuItem;
    ExportHousesRX: TMenuItem;
    ExportUnitsRX: TMenuItem;
    Script1: TMenuItem;
    OpenDAT: TMenuItem;
    ExportDAT: TMenuItem;
    DecodeDAT: TMenuItem;
    Timer1sec: TTimer;
    ExportGUIMainRX: TMenuItem;
    Exportfonts1: TMenuItem;
    GroupBox1: TGroupBox;
    Image4: TImage;
    TBZoomControl: TTrackBar;
    Image3: TImage;
    Label1: TLabel;
    Pl1: TSpeedButton;
    Pl2: TSpeedButton;
    Pl3: TSpeedButton;
    Pl6: TSpeedButton;
    Pl5: TSpeedButton;
    Pl4: TSpeedButton;
    Shape267: TShape;
    CheckBox2: TCheckBox;
    CheckBox1: TCheckBox;
    CheckBox3: TCheckBox;
    ExportText: TMenuItem;
    ExportStatus1: TMenuItem;
    ExportDeliverlists1: TMenuItem;
    ExportSounds1: TMenuItem;
    procedure OpenMap(filename:string);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender:TObject);
    procedure DecodeDATClick(Sender: TObject);
    procedure OpenMapClick(Sender: TObject);
    procedure ZoomChange(Sender: TObject);
    procedure MiniMapMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure MiniMapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MiniMapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Panel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AboutClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ResetZoomClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure ShowWiresClick(Sender: TObject);
    procedure ShowObjectsClick(Sender: TObject);
    procedure ShowFlatTerrainClick(Sender: TObject);
    procedure Timer100msTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure PrintScreen1Click(Sender: TObject);
    procedure ExportGUIRXClick(Sender: TObject);
    procedure ExportTreesRXClick(Sender: TObject);
    procedure ExportHousesRXClick(Sender: TObject);
    procedure ExportUnitsRXClick(Sender: TObject);
    procedure Timer1secTimer(Sender: TObject);
    procedure ExportGUIMainRXClick(Sender: TObject);
    procedure Shape267MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Shape267DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure Exportfonts1Click(Sender: TObject);  
    procedure DoScrolling;
    procedure ExportTextClick(Sender: TObject);
    procedure ExportDeliverlists1Click(Sender: TObject);
    procedure ExportSounds1Click(Sender: TObject);

  private     { Private declarations }
    procedure OnIdle(Sender: TObject; var Done: Boolean);
  public      { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;
  ControlList: TKMUserControlList;

implementation  {$R *.DFM}


procedure TForm1.OnIdle(Sender: TObject; var Done: Boolean);
var
  FrameTime:integer;
begin //Counting FPS
if not Form1.Active then exit;
FrameTime:=GetTickCount-OldTimeFPS;
OldTimeFPS:=GetTickCount;
if (FPSLag<>1)and(FrameTime<FPSLag) then
begin
  sleep(FPSLag-FrameTime);
  FrameTime:=FPSLag;
end;
inc(OldFrameTimes,FrameTime);
inc(FrameCount);
if OldFrameTimes>=FPS_INTERVAL then
begin
  StatusBar1.Panels[2].Text:=floattostr(round((1000/(OldFrameTimes/FrameCount))*10)/10)+' fps ('+inttostr(1000 div FPSLag)+')';
  OldFrameTimes:=0;
  FrameCount:=0;
  fLog.AppendLog('First sec frame done');
end; //FPS calculation complete

fRender.Render;
done:=false; //repeats OnIdle event
end;

procedure TForm1.FormCreate(Sender: TObject);
begin               
  fTextLibrary:= TTextLibrary.Create(ExeDir+'data\misc\'); //Must be done earily on so GamePlayInterface can use it
  fControls:= TKMControlsCollection.Create;
  fGamePlayInterface:= TKMGamePlayInterface.Create;
  fRender:= TRender.Create;
  fViewport:= TViewport.Create;
  fTerrain:= TTerrain.Create;
  fSoundLibrary:= TSoundLibrary.Create;
  fMiniMap:= TMiniMap.Create(ShapeFOV,MiniMap,Label1);
  Application.OnIdle:=Form1.OnIdle;
  Panel_MiniMap.Color:=0; //Keep it colored until app is started, Controls should be visible in designtime 
end;

procedure TForm1.OpenMapClick(Sender: TObject);
begin
if not RunOpenDialog(OpenDialog1,'','','Knights & Merchants map (*.map)|*.map') then exit;
OpenMap(OpenDialog1.FileName);
end;

procedure TForm1.OpenMap(filename:string);
begin
fTerrain.OpenMapFromFile(filename);
fViewport.SetZoom(1);
Form1.FormResize(nil);
Form1.Caption:='KaM Remake - '+filename;
end;

procedure TForm1.FormResize(Sender:TObject);
begin
  fRender.RenderResize(Panel5.Width,Panel5.Height);
  fViewport.SetArea(Panel5.Width,Panel5.Height);
  fViewport.SetZoom(ZoomLevels[TBZoomControl.Position]);
  fMiniMap.SetRect(fViewport);
end;

procedure TForm1.DecodeDATClick(Sender: TObject);
var ii,fsize:integer; f:file; c:array[1..65536] of char;
begin
if not OpenDialog1.Execute then exit;
fsize:=GetFileSize(OpenDialog1.FileName);
assignfile(f,OpenDialog1.FileName); reset(f,1);
blockread(f,c,fsize);
for ii:=1 to fsize do c[ii]:=chr(ord(c[ii]) xor 239);
closefile(f);
assignfile(f,OpenDialog1.FileName+'.txt'); rewrite(f,1);
blockwrite(f,c,fsize);
closefile(f);
end;

procedure TForm1.ZoomChange(Sender: TObject);
begin
fViewport.SetZoom(ZoomLevels[TBZoomControl.Position]);
fMiniMap.SetRect(fViewport);
end;

procedure TForm1.MiniMapMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin MiniMapSpy:=true; MiniMapMouseMove(nil,Shift,X,Y); end;

procedure TForm1.MiniMapMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
begin
if not MiniMapSpy then exit;
fViewport.SetCenter(X,Y);
fMiniMap.SetRect(fViewport);
end;

procedure TForm1.MiniMapMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin MiniMapMouseMove(nil,Shift,X,Y); MiniMapSpy:=false; end;

procedure TForm1.Panel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  case Button of
    mbLeft:
      MouseButton:= mb2Left;
    mbRight:
      MouseButton:= mb2Right;
  else
    MouseButton:=mb2None;
  end;
  Panel1MouseMove(Panel5,Shift,X,Y);

  fControls.OnMouseDown(X,Y,Button);

  //example for units need change
  //Removed right since it interfers with the school buttons
  if Button = mbMiddle then
    ControlList.AddUnit(play_1, ut_Serf, KMPoint(CursorXc,CursorYc));
  //else if Button = mbMiddle then
  //  ControlList.AddUnit(play_1, ut_HorseScout, KMPoint(CursorXc,CursorYc));

end;

procedure TForm1.Panel1MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
begin
  if (X>0)and(X<Panel5.Width)and(Y>0)and(Y<Panel5.Height) then
  else exit;
CursorX:=fViewport.XCoord+(X-fViewport.ViewRect.Right/2+ToolBarWidth/2)/CellSize/fViewport.Zoom;
CursorY:=fViewport.YCoord+(Y-fViewport.ViewRect.Bottom/2)/CellSize/fViewport.Zoom;

CursorY:=fTerrain.ConvertCursorToMapCoord(CursorX,CursorY);

CursorXc:=EnsureRange(round(CursorX+0.5),1,fTerrain.MapX); //Cell below cursor
CursorYc:=EnsureRange(round(CursorY+0.5),1,fTerrain.MapY);
CursorXn:=EnsureRange(round(CursorX+1),1,fTerrain.MapX); //Node below cursor
CursorYn:=EnsureRange(round(CursorY+1),1,fTerrain.MapY);

StatusBar1.Panels.Items[1].Text:='Cursor: '+floattostr(round(CursorX*10)/10)+' '+floattostr(round(CursorY*10)/10)
+' | '+inttostr(CursorXc)+' '+inttostr(CursorYc);

if CursorMode.Mode=cm_None then
  if (ControlList.HousesHitTest(CursorXc, CursorYc)<>nil)or
     (ControlList.UnitsHitTest(CursorXc, CursorYc)<>nil) then
    Screen.Cursor:=c_Info
  else if not Scrolling then
    Screen.Cursor:=c_Default;

fTerrain.UpdateCursor(CursorMode.Mode,KMPoint(CursorXc,CursorYc));
fControls.OnMouseOver(X,Y,Shift);

end;

procedure TForm1.Panel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  var P:TKMPoint;
begin
  P.X:=CursorXc;
  P.Y:=CursorYc;

  if X<=ToolBarWidth then
    fControls.OnMouseUp(X,Y,Button)
  else if Button = mbLeft then //Only allow placing of roads etc. with the left mouse button

  case CursorMode.Mode of
    cm_None:
      begin
        if ControlList.UnitsHitTest(CursorXc, CursorYc)<>nil then begin
          fGamePlayInterface.ShowUnitInfo(ControlList.UnitsHitTest(CursorXc, CursorYc).GetUnitType);
        end; //Houses have prioraty over units, so you can't select an occupant 
        if ControlList.HousesHitTest(CursorXc, CursorYc)<>nil then begin
          ControlList.SelectedHouse:=ControlList.HousesHitTest(CursorXc, CursorYc);
          fGamePlayInterface.ShowHouseInfo(ControlList.HousesHitTest(CursorXc, CursorYc));
        end;
      end;
    cm_Road: ControlList.AddRoadPlan(P,mu_RoadPlan);
    cm_Field: ControlList.AddRoadPlan(P,mu_FieldPlan);
    cm_Wine: ControlList.AddRoadPlan(P,mu_WinePlan);

    cm_Erase:
      begin
        ControlList.RemPlan(P);
        ControlList.RemHouse(P);
      end;
    cm_Houses:
      begin
        ControlList.AddHousePlan(THouseType(CursorMode.Param),P,play_1);
        fGamePlayInterface.SelectRoad;
      end;
    end;
MouseButton:=mb2None;
end;

procedure TForm1.AboutClick(Sender: TObject);
begin
  FormLoading.Bar1.Position:=0;
  FormLoading.Show;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
fRender.Destroy;
end;

procedure TForm1.Timer100msTimer(Sender: TObject);
var i:integer;
begin
if not Form1.Active then exit;
if CheckBox1.Checked then exit;
ControlList.UpdateState;
fTerrain.UpdateState;

inc(GlobalTickCount);

if CheckBox2.Checked then
  for i:=1 to 100 do begin
    fTerrain.UpdateState;
    ControlList.UpdateState;
  end;
  DoScrolling; //Now check to see if we need to scroll
end;

procedure TForm1.Timer1secTimer(Sender: TObject);
begin
  if not Form1.Active then exit;
  fMiniMap.Repaint; //No need to repaint it more often
end;

procedure TForm1.ResetZoomClick(Sender: TObject);
begin
  TBZoomControl.Position:=4;
end;

procedure TForm1.ExitClick(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.ShowWiresClick(Sender: TObject);
begin
  ShowWires.Checked:=not ShowWires.Checked;
end;

procedure TForm1.ShowObjectsClick(Sender: TObject);
begin
  ShowObjects.Checked:=not ShowObjects.Checked;
end;

procedure TForm1.ShowFlatTerrainClick(Sender: TObject);
begin
  ShowFlatTerrain.Checked:= not ShowFlatTerrain.Checked;
  xh:=36+integer(ShowFlatTerrain.Checked)*164; // 1/36 .. 1/200
end;

constructor TForm1.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  ControlList:= TKMUserControlList.Create();
  ControlList.Add(play_1, uct_User);
end;

destructor TForm1.Destroy;
begin
  ControlList.Free;
  inherited;
end;

procedure TForm1.Button1Click(Sender: TObject);
var H:TKMHouseStore;
begin
TKMControl(Sender).Enabled:=false;
fViewPort.SetCenter(6,10);
ControlList.AddRoadPlan(KMPoint(2,6),mu_RoadPlan);

ControlList.AddRoadPlan(KMPoint(2,7),mu_FieldPlan);
ControlList.AddRoadPlan(KMPoint(3,7),mu_FieldPlan);
ControlList.AddRoadPlan(KMPoint(4,7),mu_FieldPlan);
ControlList.AddRoadPlan(KMPoint(5,7),mu_FieldPlan);

ControlList.AddHouse(ht_Farm, KMPoint(3,5), play_1);
ControlList.AddHouse(ht_Mill, KMPoint(8,5), play_1);
ControlList.AddHouse(ht_Bakery, KMPoint(13,5), play_1);
ControlList.AddUnit(play_1, ut_Farmer, KMPoint(3,7));
ControlList.AddUnit(play_1, ut_Baker, KMPoint(4,7));
ControlList.AddUnit(play_1, ut_Baker, KMPoint(5,7));

ControlList.AddHouse(ht_Store, KMPoint(17,5), play_1);

ControlList.AddHouse(ht_WoodCutters, KMPoint(4,9), play_1);
ControlList.AddHouse(ht_SawMill, KMPoint(7,9), play_1);
ControlList.AddHouse(ht_Quary, KMPoint(12,9), play_1);
ControlList.AddUnit(play_1, ut_WoodCutter, KMPoint(7,11));
ControlList.AddUnit(play_1, ut_Lamberjack, KMPoint(8,11));
ControlList.AddUnit(play_1, ut_StoneCutter, KMPoint(6,9));

ControlList.AddRoadPlan(KMPoint(2,14),mu_WinePlan);
ControlList.AddRoadPlan(KMPoint(3,14),mu_WinePlan);
ControlList.AddRoadPlan(KMPoint(4,14),mu_WinePlan);
ControlList.AddRoadPlan(KMPoint(5,14),mu_WinePlan);
ControlList.AddHouse(ht_WineYard, KMPoint(4,13), play_1);
ControlList.AddUnit(play_1, ut_Farmer, KMPoint(15,9));
ControlList.AddHouse(ht_CoalMine, KMPoint(8,13), play_1);
ControlList.AddUnit(play_1, ut_Miner, KMPoint(10,9));
ControlList.AddHouse(ht_FisherHut, KMPoint(12,13), play_1); //Added to demonstrate a house without an occupant in the building page

ControlList.AddUnit(play_1, ut_Serf, KMPoint(2,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(3,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(4,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(5,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(6,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(7,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(8,11));
ControlList.AddUnit(play_1, ut_Serf, KMPoint(9,11));
ControlList.AddUnit(play_1, ut_Worker, KMPoint(8,11));
ControlList.AddUnit(play_1, ut_Worker, KMPoint(9,11));

ControlList.AddUnit(play_1, ut_Recruit, KMPoint(10,11));

H:=ControlList.FindStore();
if H<>nil then H.AddMultiResource(rt_All,10);

ControlList.AddRoadPlan(KMPoint(3,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(4,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(5,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(6,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(7,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(8,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(9,6),mu_RoadPlan);
ControlList.AddRoadPlan(KMPoint(10,6),mu_RoadPlan);

ControlList.AddHousePlan(ht_School, KMPoint(4,17), play_1);
ControlList.AddHousePlan(ht_Barracks, KMPoint(9,18), play_1);
end;

procedure TForm1.PrintScreen1Click(Sender: TObject);
var sh,sw,i,k:integer; jpg: TJpegImage; mkbmp:TBitmap; bmp:array of cardinal;
begin
sh:=Panel5.Height;
sw:=Panel5.Width;

setlength(bmp,sw*sh+1);
glReadPixels(0,0,sw,sh,GL_BGRA,GL_UNSIGNED_BYTE,@bmp[0]);

//Mirror verticaly
for i:=0 to (sh div 2)-1 do for k:=0 to sw-1 do
SwapInt(bmp[i*sw+k],bmp[((sh-1)-i)*sw+k]);

mkbmp:=TBitmap.Create;
mkbmp.Handle:=CreateBitmap(sw,sh,1,32,@bmp[0]);

jpg:=TJpegImage.Create;
jpg.assign(mkbmp);
jpg.ProgressiveEncoding:=true;
jpg.ProgressiveDisplay:=true;
jpg.Performance:=jpBestQuality;
jpg.CompressionQuality:=90;
jpg.Compress;
DateTimeToString(s,'yyyy-mm-dd hh-nn-ss',Now); //2007-12-23 15-24-33
jpg.SaveToFile(ExeDir+'KaM '+s+'.jpg');

jpg.Free;
mkbmp.Free;
end;

procedure TForm1.ExportTreesRXClick(Sender: TObject);  begin ExportRX2BMP(1); end;
procedure TForm1.ExportHousesRXClick(Sender: TObject); begin ExportRX2BMP(2); end;
procedure TForm1.ExportUnitsRXClick(Sender: TObject);  begin ExportRX2BMP(3); end;
procedure TForm1.ExportGUIRXClick(Sender: TObject);    begin ExportRX2BMP(4); end;
procedure TForm1.ExportGUIMainRXClick(Sender: TObject);begin ExportRX2BMP(5); end;

procedure TForm1.ExportFonts1Click(Sender: TObject);
var i:integer;
begin
  for i:=1 to length(FontFiles) do
    ReadFont(ExeDir+'data\gfx\fonts\'+FontFiles[i]+'.fnt',TKMFont(i),true);
end;



procedure TForm1.Shape267MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DefineInputColor((Sender as TShape).Brush.Color,Sender);
end;

procedure TForm1.Shape267DragDrop(Sender, Source: TObject; X, Y: Integer);
begin
  TeamColors[3]:=Shape267.Brush.Color;
  fRender.Render;
end;

//Here we must test each edge to see if we need to scroll in that direction
//We scroll at SCROLLSPEED per 100 ms. That constant is defined in KM_Global_Data
procedure TForm1.DoScrolling;
const DirectinsBitfield:array[0..12]of byte = (0,c_Scroll6,c_Scroll0,c_Scroll7,c_Scroll2,0,c_Scroll1,0,c_Scroll4,c_Scroll5,0,0,c_Scroll3);
var XCoord, YCoord: integer; Temp:byte;
begin
  XCoord := fViewport.XCoord; //First set X and Y to be the current values
  YCoord := fViewport.YCoord;
  Temp:=0; //That is our bitfield variable for directions, 0..12 range
  //    3 2 6  These are directions
  //    1 * 4  They are converted from bitfield to actual cursor constants, see Arr array
  //    9 8 12

  //Left, Top, Right, Bottom
  if Mouse.CursorPos.X < SCROLLFLEX then begin inc(Temp,1); XCoord := XCoord-SCROLLSPEED; end;
  if Mouse.CursorPos.Y < SCROLLFLEX then begin inc(Temp,2); YCoord := YCoord-SCROLLSPEED; end;
  if Mouse.CursorPos.X > Screen.Width -1-SCROLLFLEX then begin inc(Temp,4); XCoord := XCoord+SCROLLSPEED; end;
  if Mouse.CursorPos.Y > Screen.Height-1-SCROLLFLEX then begin inc(Temp,8); YCoord := YCoord+SCROLLSPEED; end;
  if Temp<>0 then Screen.Cursor :=DirectinsBitfield[Temp]; //Sample cursor type from bitfield value

  //Now do actual the scrolling, if needed
  if (XCoord<>fViewport.XCoord)or(YCoord<>fViewport.YCoord) then
  begin
    fViewport.SetCenter(XCoord,YCoord);
    fMiniMap.SetRect(fViewport); //Update mini-map
    Scrolling := true; //Stop OnMouseOver from overriding my cursor changes
  end else begin
    Scrolling := false; //Allow cursor changes to be overriden and reset if still on a scrolling cursor
    if (Screen.Cursor = c_Scroll0) or (Screen.Cursor = c_Scroll1) or (Screen.Cursor = c_Scroll2) or (Screen.Cursor = c_Scroll3) or (Screen.Cursor = c_Scroll4) or (Screen.Cursor = c_Scroll5) or (Screen.Cursor = c_Scroll6) or (Screen.Cursor = c_Scroll7) then
      Screen.Cursor := c_Default; end;
end;


procedure TForm1.ExportTextClick(Sender: TObject);
begin
  fTextLibrary.ExportTextLibraries;
end;


procedure TForm1.ExportDeliverlists1Click(Sender: TObject);
var f:textfile;
begin
assignfile(f,ExeDir+'DeliverLists.txt'); Rewrite(f);
write(f,ControlList.DeliverList.WriteToText);
closefile(f);
end;

procedure TForm1.ExportSounds1Click(Sender: TObject);
begin
fSoundLibrary.ExportSounds;
end;

end.
