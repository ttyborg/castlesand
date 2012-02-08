unit KM_ResourceFonts;
{$I KaM_Remake.inc}
interface
uses
  Graphics, Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_RenderSetup;


type
  TKMFontData = class
  public
    TexID:Cardinal;
    Unk1,WordSpacing,CharSpacing,Unk3:smallint; //BaseCharHeight?, Unknown, CharSpacingX, LineOffset?
    Pal:array[0..255]of byte;
    Letters:array[0..255]of record
      Width,Height:word;
      Add1,Add2,YOffset,Add4:word; //Add1-4 always 0
      Data:array of byte;
      u1,v1,u2,v2:single;
    end;
    LineSpacing: Byte; //Not in KaM files, we use custom value that fits well
    procedure LoadFont(const aFileName: string; aRender: TRender; aFont: TKMFont; ExportToBMP: Boolean);
  end;


  TResourceFont = class
  private
    fRender: TRender;
    fFontData:array [TKMFont] of TKMFontData;
    function GetCodePage(aLocale:AnsiString):AnsiString;
    function GetFontData(aIndex: TKMFont): TKMFontData;
  public
    constructor Create(aRender: TRender);
    destructor Destroy; override;

    property FontData[aIndex: TKMFont]: TKMFontData read GetFontData;

    function WordWrap(aText: string; aFont: TKMFont; aMaxPxWidth: integer; aForced: boolean): string;
    function CharsThatFit(const aText: string; aFont: TKMFont; aMaxPxWidth: integer): integer;
    function GetTextSize(const aText: string; Fnt: TKMFont): TKMPoint;

    procedure LoadFonts(aLocale: AnsiString);
    procedure ExportFonts(aLocale: AnsiString);
    end;


implementation
uses KromUtils, KM_Log, KM_Resource, KM_ResourcePalettes;


const //Font01.fnt seems to be damaged..
  FontFiles: array [TKMFont] of AnsiString = (
    'antiqua', 'briefing', 'game', 'grey', 'mainb', 'mainmapgold', 'metal', 'mini', 'outline', 'won');

  //Note: Fonts with palette 0 are using custom coloring,
  //since no existing palette matches them well and they are monochrome
  FontPal: array [TKMFont] of TKMPal =
  (pal_0, pal_map, pal_lin, pal_0, pal_lin, pal2_mapgold, pal_0, pal_lin, pal_0, pal_set2);

   FONT_INTERLINE = 5; //Spacing between lines of text


{ TKMFontData }
procedure TKMFontData.LoadFont(const aFileName: string; aRender: TRender; aFont: TKMFont; ExportToBMP: Boolean);
const
  TexWidth = 256; //Connected to TexData, don't change
var
  S:TKMemoryStream;
  i,k,ci,ck:integer;
  MaxHeight:integer;
  AdvX,AdvY:integer;
  TD:array of cardinal;
  MyBitMap:TBitMap;
begin
  MaxHeight := 0;
  if not FileExists(aFileName) then exit;

  S := TKMemoryStream.Create;
  S.LoadFromFile(aFileName);

  S.Read(Unk1, 8);
  S.Read(Pal[0], 256);

  //Read font data
  for i:=0 to 255 do
    if Pal[i] <> 0 then
    begin
      S.Read(Letters[i].Width, 4);
      S.Read(Letters[i].Add1, 8);

      MaxHeight := Math.max(MaxHeight, Letters[i].Height);

      fLog.AssertToLog(Letters[i].Width*Letters[i].Height <> 0, 'Font data Width*Height = 0'); //Font01.fnt seems to be damaged..

      SetLength(Letters[i].Data, Letters[i].Width*Letters[i].Height);
      S.Read(Letters[i].Data[0], Letters[i].Width*Letters[i].Height);
    end;
  S.Free;

  LineSpacing := FONT_INTERLINE;

  //Special fix for monochrome fonts
  if FontPal[aFont] = pal_lin then
    for i:=0 to 255 do
      if Pal[i]<>0 then //see if letterspace is used
        for k:=0 to Length(Letters[i].Data)-1 do
          if Letters[i].Data[k]<>0 then
            Letters[i].Data[k] := 255; //Full white


  //Compile texture
  AdvX := 0; AdvY := 0;
  SetLength(TD, TexWidth*TexWidth);

  for i:=0 to 255 do
    if Pal[i] <> 0 then
      with Letters[i] do
      begin

        fLog.AssertToLog(Pal[i]=1, 'FontData palette <> 1');

        //Switch to new line
        if AdvX+Width+2>TexWidth then begin
          AdvX := 0;
          inc(AdvY, MaxHeight);
        end;

        //Fill in colors
        for ci:=0 to Height-1 do for ck:=0 to Width-1 do
          TD[(AdvY+ci)*TexWidth+AdvX+1+ck] := fResource.Palettes[FontPal[aFont]].Color32(Data[ci*Width+ck]);

        u1 := (AdvX+1)/TexWidth;
        v1 := AdvY/TexWidth;
        u2 := (AdvX+1+Width)/TexWidth;
        v2 := (AdvY+Height)/TexWidth;

        inc(AdvX, 1+Width+1);
      end;

  TexID := aRender.GenTexture(TexWidth, TexWidth, @TD[0], tf_Normal);

  if ExportToBMP then
  begin
    MyBitMap := TBitMap.Create;
    MyBitMap.PixelFormat := pf24bit;
    MyBitMap.Width  := TexWidth;
    MyBitMap.Height := TexWidth;

    for ci:=0 to TexWidth-1 do for ck:=0 to TexWidth-1 do
      MyBitMap.Canvas.Pixels[ck,ci]:= TD[ci*TexWidth+ck] AND $FFFFFF;

    CreateDir(ExeDir+'Export\');
    CreateDir(ExeDir+'Export\Fonts\');
    MyBitMap.SaveToFile(ExeDir+'Export\Fonts\'+ExtractFileName(aFileName)+fResource.Palettes.PalFile(FontPal[aFont])+'.bmp');
    MyBitMap.Free;
  end;

  SetLength(TD, 0);
end;


{ TResourceFont }
constructor TResourceFont.Create(aRender: TRender);
var F: TKMFont;
begin
  Inherited Create;
  fRender := aRender;

  for F := Low(TKMFont) to High(TKMFont) do
    fFontData[F] := TKMFontData.Create;
end;


destructor TResourceFont.Destroy;
var F: TKMFont;
begin
  for F := Low(TKMFont) to High(TKMFont) do
    fFontData[F].Free;

  Inherited;
end;


function TResourceFont.GetFontData(aIndex: TKMFont): TKMFontData;
begin
  Result := fFontData[aIndex];
end;


function TResourceFont.GetCodePage(aLocale: AnsiString):AnsiString;
var k:integer;
begin
  Result := '';
  for k:=1 to LOCALES_COUNT do
    if Locales[k,1] = aLocale then
    begin
      Result := Locales[k,2];
      Exit;
    end;
end;


procedure TResourceFont.LoadFonts(aLocale: AnsiString);
var
  F: TKMFont;
  CodePage: AnsiString;
begin
  CodePage := GetCodePage(aLocale);
  for F := Low(TKMFont) to High(TKMFont) do
    if FileExists(ExeDir+FONTS_FOLDER+FontFiles[F]+'.'+CodePage+'.fnt') then
      fFontData[F].LoadFont(ExeDir+FONTS_FOLDER+FontFiles[F]+'.'+CodePage+'.fnt', fRender, F, false)
    else
      fFontData[F].LoadFont(ExeDir+FONTS_FOLDER+FontFiles[F]+'.fnt', fRender, F, False);
end;


procedure TResourceFont.ExportFonts(aLocale: AnsiString);
var
  F: TKMFont;
  CodePage: AnsiString;
begin
  CodePage := GetCodePage(aLocale);
  for F := Low(TKMFont) to High(TKMFont) do
    if FileExists(ExeDir+FONTS_FOLDER+FontFiles[F]+'.'+CodePage+'.fnt') then
      fFontData[F].LoadFont(ExeDir+FONTS_FOLDER+FontFiles[F]+'.'+CodePage+'.fnt', fRender, F, true)
    else
      fFontData[F].LoadFont(ExeDir+FONTS_FOLDER+FontFiles[F]+'.fnt', fRender, F, True);
end;


function TResourceFont.WordWrap(aText: string; aFont: TKMFont; aMaxPxWidth:integer; aForced:boolean): string;
var
  i, CharSpacing, AdvX, PrevX, LastSpace: integer;
begin
  AdvX := 0;
  PrevX := 0;
  LastSpace := -1;
  CharSpacing := fFontData[aFont].CharSpacing; //Spacing between letters, this varies between fonts

  i:=1;
  while i <= length(aText) do
  begin
    if aText[i]=#32 then inc(AdvX, fFontData[aFont].WordSpacing)
                    else inc(AdvX, fFontData[aFont].Letters[byte(aText[i])].Width + CharSpacing);

    if (aText[i]=#32) or (aText[i]=#124) then
    begin
      LastSpace := i;
      PrevX := AdvX;
    end;

    //This algorithm is not perfect, somehow line width is not within SizeX, but very rare
    if ((AdvX > aMaxPxWidth)and(LastSpace<>-1))or(aText[i]=#124) then
    begin
      aText[LastSpace] := #124; //Replace last whitespace with EOL
      dec(AdvX, PrevX); //Subtract width since replaced whitespace
      LastSpace := -1;
    end;
    //Force an EOL part way through a word
    if aForced and (AdvX > aMaxPxWidth) and (LastSpace = -1) then
    begin
      Insert(#124,aText,i); //Insert an EOL before this character
      AdvX := 0;
      LastSpace := -1;
    end;
    inc(i);
  end;
  Result := aText;
end;


function TResourceFont.CharsThatFit(const aText: string; aFont: TKMFont; aMaxPxWidth:integer):integer;
var i,CharSpacing,AdvX:integer;
begin
  AdvX := 0;
  Result := Length(aText);
  CharSpacing := fFontData[aFont].CharSpacing; //Spacing between letters, this varies between fonts

  for i:=1 to length(aText) do
  begin
    if aText[i]=#32 then inc(AdvX, fFontData[aFont].WordSpacing)
                    else inc(AdvX, fFontData[aFont].Letters[byte(aText[i])].Width + CharSpacing);

    if (AdvX > aMaxPxWidth) then
    begin
      Result := i-1; //Previous character fits, this one does not
      Exit;
    end;
  end;
end;


function TResourceFont.GetTextSize(const aText: string; Fnt:TKMFont):TKMPoint;
var
  i:integer;
  CharSpacing,LineCount:integer;
  LineWidth:array of integer; //Some fonts may have negative CharSpacing
begin
  Result.X := 0;
  Result.Y := 0;

  if aText='' then Exit;

  LineCount := 1;
  for i:=1 to length(aText) do
    if aText[i]=#124 then inc(LineCount);

  SetLength(LineWidth, LineCount+2); //1..n+1 (for last line)

  LineCount := 1;
  CharSpacing := fFontData[Fnt].CharSpacing; //Spacing between letters, this varies between fonts
  for i:=1 to length(aText) do begin
    if aText[i]<>#124 then
      if aText[i]=#32 then inc(LineWidth[LineCount], fFontData[Fnt].WordSpacing)
                     else inc(LineWidth[LineCount], fFontData[Fnt].Letters[byte(aText[i])].Width+CharSpacing);
    if (aText[i]=#124)or(i=length(aText)) then
    begin //If EOL or aText end
      LineWidth[LineCount] := Math.max(0, LineWidth[LineCount]-CharSpacing); //Remove last interletter space and negate double EOLs
      inc(LineCount);
    end;
  end;

  dec(LineCount);
  Result.Y := (fFontData[Fnt].Unk1 + FONT_INTERLINE)*LineCount;
  for i:=1 to LineCount do
    Result.X := Math.max(Result.X, LineWidth[i]);
end;


end.
