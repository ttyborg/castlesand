unit KM_Resource;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Graphics, SysUtils,
  KM_CommonTypes, KM_Defaults, KM_Pics,
  KM_Render,
  KM_ResourceCursors,
  KM_ResourceFonts,
  KM_ResourceHouse,
  KM_ResourceMapElements,
  KM_ResourcePalettes,
  KM_ResourceResource,
  KM_ResourceSprites,
  KM_ResourceTileset,
  KM_ResourceUnit
  {$IFDEF WDC}, ZLibEx {$ENDIF}
  {$IFDEF FPC}, BGRABitmap {$ENDIF};


type
  TDataLoadingState = (dls_None, dls_Menu, dls_All); //Resources are loaded in 2 steps, for menu and the rest


  TResource = class
  private
    fRender: TRender;
    fDataState: TDataLoadingState;
    fCursors: TKMCursors;
    fResourceFont: TResourceFont;
    fHouseDat: TKMHouseDatCollection;
    fUnitDat: TKMUnitDatCollection;
    fPalettes: TKMPalettes;
    fResources: TKMResourceCollection;
    fSprites: TKMSprites;
    fTileset: TKMTileset;
    fMapElements: TKMMapElements;

    procedure StepRefresh;
    procedure StepCaption(const aCaption: string);
  public
    OnLoadingStep: TEvent;
    OnLoadingText: TStringEvent;

    constructor Create(aRender: TRender; aLS: TEvent; aLT: TStringEvent);
    destructor Destroy; override;

    procedure LoadMenuResources(const aLocale: AnsiString);
    procedure LoadGameResources(aAlphaShadows: boolean);

    property DataState: TDataLoadingState read fDataState;
    property Cursors: TKMCursors read fCursors;
    property HouseDat: TKMHouseDatCollection read fHouseDat;
    property MapElements: TKMMapElements read fMapElements;
    property Palettes: TKMPalettes read fPalettes;
    property ResourceFont: TResourceFont read fResourceFont;
    property Resources: TKMResourceCollection read fResources;
    property Sprites: TKMSprites read fSprites;
    property Tileset: TKMTileset read fTileset;
    property UnitDat: TKMUnitDatCollection read fUnitDat;

    procedure ExportTreeAnim;
    procedure ExportHouseAnim;
    procedure ExportUnitAnim;
  end;


  var
    fResource: TResource;


implementation
uses KromUtils, KM_Log, KM_Points;


{ TResource }
constructor TResource.Create(aRender: TRender; aLS: TEvent; aLT: TStringEvent);
begin
  inherited Create;
  fDataState := dls_None;
  fLog.AppendLog('Resource loading state - None');

  fRender := aRender;
  OnLoadingStep := aLS;
  OnLoadingText := aLT;
end;


destructor TResource.Destroy;
begin
  FreeAndNil(fCursors);
  FreeAndNil(fHouseDat);
  FreeAndNil(fMapElements);
  FreeAndNil(fPalettes);
  FreeAndNil(fResourceFont);
  FreeAndNil(fResources);
  FreeAndNil(fSprites);
  FreeAndNil(fTileset);
  FreeAndNil(fUnitDat);
  inherited;
end;


procedure TResource.StepRefresh;
begin
  if Assigned(OnLoadingStep) then OnLoadingStep;
end;


procedure TResource.StepCaption(const aCaption: string);
begin
  if Assigned(OnLoadingText) then OnLoadingText(aCaption);
end;


procedure TResource.LoadMenuResources(const aLocale: AnsiString);
begin
  Assert(SKIP_RENDER or (fRender <> nil), 'fRenderSetup should be init before ReadGFX to be able access OpenGL');

  StepCaption('Reading palettes ...');
  fPalettes := TKMPalettes.Create;
  fPalettes.LoadPalettes;
  fLog.AppendLog('Reading palettes', True);

  fSprites := TKMSprites.Create(StepRefresh, StepCaption);

  fCursors := TKMCursors.Create;
  fSprites.LoadMenuResources;
  fCursors.MakeCursors(fSprites[rxGui]);
  fCursors.Cursor := kmc_Default;

  StepCaption('Reading fonts ...');
  fResourceFont := TResourceFont.Create(fRender);
  fResourceFont.LoadFonts(aLocale);
  fLog.AppendLog('Read fonts is done');

  fTileset := TKMTileset.Create(ExeDir + 'data\defines\pattern.dat');
  fTileset.TileColor := fSprites.Sprites[rxTiles].GetSpriteColors(248); //Tiles 249..256 are road overlays

  fMapElements := TKMMapElements.Create;
  fMapElements.LoadMapElements(ExeDir + 'data\defines\mapelem.dat');

  fSprites.ClearTemp;

  fResources := TKMResourceCollection.Create;
  fHouseDat := TKMHouseDatCollection.Create;
  fUnitDat := TKMUnitDatCollection.Create;

  StepRefresh;
  fLog.AppendLog('ReadGFX is done');
  fDataState := dls_Menu;
  fLog.AppendLog('Resource loading state - Menu');
end;


procedure TResource.LoadGameResources(aAlphaShadows: Boolean);
begin
  Assert(fRender <> nil, 'fRender inits OpenGL and we need OpenGL to make textures');

  if (fDataState <> dls_All) or (aAlphaShadows <> fSprites.AlphaShadows) then
  begin
    fSprites.LoadGameResources(aAlphaShadows);
    fSprites.ClearTemp;
  end;

  fDataState := dls_All;
  fLog.AppendLog('Resource loading state - Game');
end;


//Export Units graphics categorized by Unit and Action
procedure TResource.ExportUnitAnim;
var
  Folder: string;
  Bmp: TBitmap;
  U: TUnitType;
  A: TUnitActionType;
  D: TKMDirection;
  R: TResourceType;
  T: TUnitThought;
  i,ci:integer;
  sy,sx,y,x:integer;
  Used:array of Boolean;
  RXData: TRXData;
begin
  fSprites.LoadSprites(rxUnits, False); //BMP can't show alpha shadows anyways
  RXData := fSprites[rxUnits].RXData;

  Folder := ExeDir + 'Export\UnitAnim\';
  ForceDirectories(Folder);

  Bmp := TBitmap.Create;
  Bmp.PixelFormat := pf24bit;

  if fUnitDat = nil then
    fUnitDat := TKMUnitDatCollection.Create;

  for U := ut_Serf to ut_Serf do
  for A := Low(TUnitActionType) to High(TUnitActionType) do
  for D := dir_N to dir_NW do
  if fUnitDat[U].UnitAnim[A,D].Step[1] <> -1 then
  for i := 1 to fUnitDat[U].UnitAnim[A, D].Count do
  begin
    ForceDirectories(Folder + fUnitDat[U].UnitName + '\' + UnitAct[A] + '\');

    if fUnitDat[U].UnitAnim[A,D].Step[i] + 1 <> 0 then
    begin
      ci := fUnitDat[U].UnitAnim[A,D].Step[i] + 1;

      sx := RXData.Size[ci].X;
      sy := RXData.Size[ci].Y;
      Bmp.Width := sx;
      Bmp.Height := sy;

      for y:=0 to sy-1 do
      for x:=0 to sx-1 do
        Bmp.Canvas.Pixels[x,y] := RXData.RGBA[ci, y*sx+x] AND $FFFFFF;

      if sy > 0 then
        Bmp.SaveToFile(Folder +
          fUnitDat[U].UnitName + '\' + UnitAct[A] + '\' +
          'Dir' + IntToStr(Byte(D)) + '_' + int2fix(i, 2) + '.bmp');
    end;
  end;

  CreateDir(Folder + '_Unused');
  SetLength(Used, Length(RXData.Size));

  //Exclude actions
  for U := Low(TUnitType) to High(TUnitType) do
  for A := Low(TUnitActionType) to High(TUnitActionType) do
  for D := dir_N to dir_NW do
  if fUnitDat[U].UnitAnim[A,D].Step[1] <> -1 then
  for i := 1 to fUnitDat[U].UnitAnim[A,D].Count do
    Used[fUnitDat[U].UnitAnim[A,D].Step[i]+1] := fUnitDat[U].UnitAnim[A,D].Step[i]+1 <> 0;

  //Exclude serfs carrying stuff
  for R := Low(TResourceType) to High(TResourceType) do
  if R in [WARE_MIN..WARE_MAX] then
  for D := dir_N to dir_NW do
  if fUnitDat.SerfCarry[R,D].Step[1] <> -1 then
  for i := 1 to fUnitDat.SerfCarry[R,D].Count do
    Used[fUnitDat.SerfCarry[R,D].Step[i]+1] := fUnitDat.SerfCarry[R,D].Step[i]+1 <> 0;

  for T := Low(TUnitThought) to High(TUnitThought) do
  for i := ThoughtBounds[T,1] to  ThoughtBounds[T,2] do
    Used[I+1] := True;

  for ci:=1 to length(Used)-1 do
  if not Used[ci] then
  begin
    sx := RXData.Size[ci].X;
    sy := RXData.Size[ci].Y;
    Bmp.Width := sx;
    Bmp.Height := sy;

    for y:=0 to sy-1 do for x:=0 to sx-1 do
      Bmp.Canvas.Pixels[x,y] := RXData.RGBA[ci, y*sx+x] AND $FFFFFF;

    if sy>0 then Bmp.SaveToFile(Folder + '_Unused\_'+int2fix(ci,4) + '.bmp');
  end;

  fSprites.ClearTemp;
  Bmp.Free;
end;


//Export Houses graphics categorized by House and Action
procedure TResource.ExportHouseAnim;
var
  Folder: string;
  Bmp: TBitmap;
  HD: TKMHouseDatCollection;
  ID: THouseType;
  Ac: THouseActionType;
  Q, Beast, i, k, ci: Integer;
  sy, sx, y, x: Integer;
  RXData: TRXData;
begin
  fSprites.LoadSprites(rxHouses, False); //BMP can't show alpha shadows anyways
  RXData := fSprites[rxHouses].RXData;

  Folder := ExeDir + 'Export\HouseAnim\';
  ForceDirectories(Folder);

  Bmp := TBitmap.Create;
  Bmp.PixelFormat := pf24bit;

  HD := TKMHouseDatCollection.Create;

  ci:=0;
  for ID:=Low(THouseType) to High(THouseType) do
    for Ac:=ha_Work1 to ha_Flag3 do
      for k:=1 to HD[ID].Anim[Ac].Count do
      begin
        ForceDirectories(Folder+HD[ID].HouseName+'_'+HouseAction[Ac]+'\');
        if HD[ID].Anim[Ac].Step[k] <> -1 then
          ci := HD[ID].Anim[Ac].Step[k]+1;

        sx := RXData.Size[ci].X;
        sy := RXData.Size[ci].Y;
        Bmp.Width:=sx;
        Bmp.Height:=sy;

        for y:=0 to sy-1 do for x:=0 to sx-1 do
          Bmp.Canvas.Pixels[x,y] := RXData.RGBA[ci,y*sx+x] AND $FFFFFF;

        if sy>0 then Bmp.SaveToFile(
        Folder+HD[ID].HouseName+'_'+HouseAction[Ac]+'\_'+int2fix(k,2)+'.bmp');
      end;

  ci:=0;
  for Q:=1 to 2 do
  begin
    if Q=1 then ID:=ht_Swine
           else ID:=ht_Stables;
    CreateDir(Folder+'_'+HD[ID].HouseName+'\');
    for Beast:=1 to 5 do
      for i:=1 to 3 do
        for k:=1 to HD.BeastAnim[ID,Beast,i].Count do
        begin
          CreateDir(Folder+'_'+HD[ID].HouseName+'\'+int2fix(Beast,2)+'\');
          if HD.BeastAnim[ID,Beast,i].Step[k]+1<>0 then
            ci := HD.BeastAnim[ID,Beast,i].Step[k]+1;

          sx:=RXData.Size[ci].X;
          sy:=RXData.Size[ci].Y;
          Bmp.Width:=sx;
          Bmp.Height:=sy;

          for y:=0 to sy-1 do for x:=0 to sx-1 do
            Bmp.Canvas.Pixels[x,y] := RXData.RGBA[ci,y*sx+x] AND $FFFFFF;

          if sy>0 then Bmp.SaveToFile(Folder+'_'+HD[ID].HouseName+'\'+int2fix(Beast,2)+'\_'+int2fix(i,1)+'_'+int2fix(k,2)+'.bmp');
        end;
  end;

  HD.Free;
  fSprites.ClearTemp;
  Bmp.Free;
end;


//Export Trees graphics categorized by ID
procedure TResource.ExportTreeAnim;
var
  RXData: TRXData;
  Folder: string;
  Bmp: TBitmap;
  I, K, L, M: Integer;
  ElemID: Integer;
  SpriteID: Integer;
  SizeY,SizeX: Integer;
begin
  fSprites.LoadSprites(rxTrees, False);
  RXData := fSprites[rxTrees].RXData;

  Folder := ExeDir + 'Export\TreeAnim\';
  ForceDirectories(Folder);

  Bmp := TBitmap.Create;
  Bmp.PixelFormat := pf24bit;

  for I := 0 to fMapElements.ValidCount - 1 do
  begin
    ElemID := fMapElements.ValidToObject[I];

    for K := 1 to MapElem[ElemID].Anim.Count do
    if MapElem[ElemID].Anim.Step[K]+1 <> 0 then
    begin
      SpriteID := MapElem[ElemID].Anim.Step[K]+1;

      SizeX := RXData.Size[SpriteID].X;
      SizeY := RXData.Size[SpriteID].Y;
      Bmp.Width := SizeX;
      Bmp.Height := SizeY;

      for L := 0 to SizeY - 1 do
      for M := 0 to SizeX - 1 do
        Bmp.Canvas.Pixels[M,L] := RXData.RGBA[SpriteID, L * SizeX + M] and $FFFFFF;

      //We can insert field here and press Export>TreeAnim. Rename each folder after export to 'Cuttable',
      //'Quad' and etc.. there you'll have it. Note, we use 1..254 counting, JBSnorro uses 0..253 counting
      if SizeX * SizeY > 0 then
        Bmp.SaveToFile(Folder + Format('%.3d_%.2d', [I, K]) + '.bmp');
    end;
  end;

  fSprites.ClearTemp;
  Bmp.Free;
end;


end.
