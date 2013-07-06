unit KM_TextLibrary;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} lconvencoding, {$ENDIF}
  Classes, SysUtils, StrUtils, KromUtils, KM_Defaults;


const
  //NAME__## means that this const defines first element of some range that is ## long
  //TX_UNITS_NAMES__29 = 70; //todo: add animal unit names

  //Load text IDs from this include file that is managed by the Translation Manager
  {$I KM_TextIDs.inc}

  //Supposed for places where some text must be placed
  //That string was used in all Synetic games for missing texts
  NO_TEXT = '<<<LEER>>>';

type
  TKMStringArray = array of UnicodeString;

  TKMTextLibrary = class
  private
    procedure LoadLIBXFile(FilePath: string; var aArray: TKMStringArray);
  end;


  TKMTextLibrarySingle = class(TKMTextLibrary)
  private
    fTexts: TKMStringArray;
    function GetTexts(aIndex: Word): UnicodeString;
  public
    procedure LoadLocale(aPathTemplate: string; aLocale: AnsiString); //initial locale for UI strings
    property Texts[aIndex: Word]: UnicodeString read GetTexts; default;
  end;


  TKMTextLibraryMulti = class(TKMTextLibrary)
  private
    //Dynamic, depends on constructor
    fLocale: AnsiString;
    fFallbackLocale: AnsiString;
    fPref: array [0..2] of Integer;

    fTexts: array of TKMStringArray;
    function GetTexts(aIndex: Word): UnicodeString;
  public
    constructor Create(aLocale: AnsiString);
    procedure LoadLocale(aPathTemplate: string); //All locales for Mission strings
    function ParseTextMarkup(const aText: UnicodeString): UnicodeString;
    property Texts[aIndex: Word]: UnicodeString read GetTexts; default;
  end;


var
  //All games texts accessible from everywhere
  fTextMain: TKMTextLibrarySingle;


implementation
uses KM_Log, KM_Locales;


{LIBX files consist of lines. Each line has an index and a text. Lines without index are skipped}
procedure TKMTextLibrary.LoadLIBXFile(FilePath: string; var aArray: TKMStringArray);
  function TextToArray(const Value: UnicodeString): TKMStringArray;
  var
    P, Start: PWideChar;
    S: UnicodeString;
  begin
    SetLength(Result, 0);
    P := Pointer(Value);
    if P = nil then Exit;

    // This is a lot faster than using StrPos/AnsiStrPos when
    // LineBreak is the default (#13#10)
    while P^ <> #0 do
    begin
      Start := P;
      while not (P^ in [#0, #10, #13]) do Inc(P);
      SetString(S, Start, P - Start);

      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := S;

      if P^ = #13 then Inc(P);
      if P^ = #10 then Inc(P);
    end;
  end;
var
  SL: TStringList;
  Tmp: TKMStringArray;
  langCode: AnsiString;
  libTxt: UnicodeString;
  I: Integer;
  s: UnicodeString;
  firstDelimiter: Integer;
  ID, MaxID: Integer;
begin
  if not FileExists(FilePath) then Exit;

  SL := TStringList.Create;
  try
    //Load ANSI file with codepage we say into unicode string
    langCode := Copy(FilePath, Length(FilePath) - 7, 3);
    {$IFDEF WDC}
      //Load the text file with default ANSI encoding. If file has embedded BOM it will be used
      SL.DefaultEncoding := TEncoding.GetEncoding(fLocales.GetLocale(langCode).FontCodepage);
      SL.LoadFromFile(FilePath);
      libTxt := SL.Text;
    {$ENDIF}
    {$IFDEF FPC}
      SL.LoadFromFile(FilePath);
      libTxt := UTF8Decode(ConvertEncoding(SL.Text, 'cp' + IntToStr(fLocales.GetLocale(langCode).FontCodepage), EncodingUTF8));
    {$ENDIF}
  finally
    SL.Free;
  end;

  Tmp := TextToArray(libTxt);

  //First line is empty or comment and could have first 3 bytes Unicode Byte-Order Mark (BOM)
  s := Tmp[1];
  if Copy(s, 1, 6) <> 'MaxID:' then Exit;

  firstDelimiter := Pos(':', s);
  if not TryStrToInt(RightStr(s, Length(s) - firstDelimiter), MaxID) then Exit;

  SetLength(aArray, MaxID + 1);

  for I := 2 to High(Tmp) do
  begin
    s := Tmp[I];

    //Get string index and skip erroneous lines
    firstDelimiter := Pos(':', s);
    if firstDelimiter = 0 then Continue;
    if not TryStrToInt(TrimLeft(LeftStr(s, firstDelimiter - 1)), ID) then Continue;
    if ID > MaxID then Continue;

    s := RightStr(s, Length(s) - firstDelimiter);
    //Required characters that can't be stored in plain text
    s := StringReplace(s, '\n', eol, [rfReplaceAll, rfIgnoreCase]); //EOL
    s := StringReplace(s, '\\', '\', [rfReplaceAll, rfIgnoreCase]); //Slash
    aArray[ID] := s;
  end;
end;


function TKMTextLibrarySingle.GetTexts(aIndex: Word): UnicodeString;
begin
  if aIndex < Length(fTexts) then
    Result := fTexts[aIndex]
  else
    Result := '~~~String ' + IntToStr(aIndex) + ' out of range!~~~';
end;


//Text file template, e.g.: ExeDir\text.%s.libx
procedure TKMTextLibrarySingle.LoadLocale(aPathTemplate: string; aLocale: AnsiString);
var
  fallbackLocale: AnsiString;
begin
  fallbackLocale := fLocales.GetLocale(aLocale).FallbackLocale;

  //We load the English LIBX by default, then overwrite it with the selected language
  //(this way missing strings are in English)
  LoadLIBXFile(Format(aPathTemplate, [DEFAULT_LOCALE]), fTexts);

  if fallbackLocale <> '' then
    LoadLIBXFile(Format(aPathTemplate, [fallbackLocale]), fTexts);

  LoadLIBXFile(Format(aPathTemplate, [aLocale]), fTexts);
end;


{ TKMTextLibraryMulti }
constructor TKMTextLibraryMulti.Create(aLocale: AnsiString);
begin
  inherited Create;

  //Remember preferred locale, it will remain constant until reinit
  fLocale := aLocale;
  fFallbackLocale := fLocales.GetLocale(fLocale).FallbackLocale;

  //Order of preferences of locales
  fPref[0] := fLocales.IndexByCode(fLocale);
  fPref[1] := fLocales.IndexByCode(fFallbackLocale);
  fPref[2] := fLocales.IndexByCode(DEFAULT_LOCALE);
end;


//Order of preference: Locale > Fallback > Default(Eng)
//Some locales may have no strings at all, just skip them
function TKMTextLibraryMulti.GetTexts(aIndex: Word): UnicodeString;
begin
  if (aIndex < Length(fTexts[fPref[0]])) and (fTexts[fPref[0], aIndex] <> '') then
    Result := fTexts[fPref[0], aIndex]
  else
  if (aIndex < Length(fTexts[fPref[1]])) and (fTexts[fPref[1], aIndex] <> '') then
    Result := fTexts[fPref[1], aIndex]
  else
  if (aIndex < Length(fTexts[fPref[2]])) and (fTexts[fPref[2], aIndex] <> '') then
    Result := fTexts[fPref[2], aIndex]
  else
    Result := '~~~String ' + IntToStr(aIndex) + ' out of range!~~~';
end;


procedure TKMTextLibraryMulti.LoadLocale(aPathTemplate: string);
var
  I: Integer;
begin
  SetLength(fTexts, fLocales.Count);

  for I := 0 to fLocales.Count - 1 do
    LoadLIBXFile(Format(aPathTemplate, [fLocales[I].Code]), fTexts[I]);
end;


//Dynamic Scripts should not have access to the actual strings (script variables should be identical for all MP players)
//Take the string and replace every occurence of <$tag> with corresponding text from LibX
function TKMTextLibraryMulti.ParseTextMarkup(const aText: UnicodeString): UnicodeString;
var
  I, ID, Last: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(aText) do
  begin
    if (I + 3 <= Length(aText)) and (aText[I] = '<') and (aText[I+1] = '$') then
    begin
      Last := PosEx('>', aText, I);
      ID := StrToIntDef(Copy(aText, I+2, Last-(I+2)), -1);
      if ID >= 0 then
      begin
        Result := Result + Texts[ID];
        I := Last + 1;
        Continue;
      end;
    end;
    Result := Result + aText[I];
    Inc(I);
  end;
end;


end.
