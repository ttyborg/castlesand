unit KM_CommonClasses;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_NetworkTypes, KM_Points;


type
  { Extended with custom Read/Write commands which accept various types without asking for their length}
  TKMemoryStream = class(TMemoryStream)
  public
    procedure Write(const Value:string); reintroduce; overload;
    procedure Write(const Value:TKMPointDir ); reintroduce; overload;
    function Write(const Value:TKMDirection): Longint; reintroduce; overload;
    function Write(const Value:TKMPoint ): Longint; reintroduce; overload;
    function Write(const Value:TKMPointF): Longint; reintroduce; overload;
    function Write(const Value:single   ): Longint; reintroduce; overload;
    function Write(const Value:integer  ): Longint; reintroduce; overload;
    function Write(const Value:cardinal ): Longint; reintroduce; overload;
    function Write(const Value:byte     ): Longint; reintroduce; overload;
    function Write(const Value:boolean  ): Longint; reintroduce; overload;
    function Write(const Value:word     ): Longint; reintroduce; overload;
    function Write(const Value:shortint ): Longint; reintroduce; overload;
    procedure WriteAsText(aText:string);

    procedure Read(out Value:string); reintroduce; overload;
    procedure Read(out Value:TKMPointDir); reintroduce; overload;
    function Read(out Value:TKMDirection): Longint; reintroduce; overload;
    function Read(out Value:TKMPoint    ): Longint; reintroduce; overload;
    function Read(out Value:TKMPointF   ): Longint; reintroduce; overload;
    function Read(out Value:single      ): Longint; reintroduce; overload;
    function Read(out Value:integer     ): Longint; reintroduce; overload;
    function Read(out Value:cardinal    ): Longint; reintroduce; overload;
    function Read(out Value:byte        ): Longint; reintroduce; overload;
    function Read(out Value:boolean     ): Longint; reintroduce; overload;
    function Read(out Value:word        ): Longint; reintroduce; overload;
    function Read(out Value:shortint    ): Longint; reintroduce; overload;
    function ReadAsText:string;
  end;

  TStreamEvent = procedure (aData: TKMemoryStream) of object;


  //Stores information about a multiplayer game to be sent: host -> server -> queriers
  TMPGameInfo = class
  public
    GameState:TMPGameState;
    Players:string;
    Map:string;
    GameTime:TDateTime;
    function GetFormattedTime:string;
    procedure LoadFromText(aText:string);
    function GetAsText:string;
    function GetAsHTML:string;
  end;


  //List that clears up its items, used only in Units/Houses}
  TKMList = class(TList)
  public
    procedure Clear; override;
  end;


  TKMPointList = class
  public
    Count:integer;
    List:array of TKMPoint; //1..Count
    procedure Load(LoadStream:TKMemoryStream); virtual;
    procedure Clearup; virtual;
    procedure AddEntry(aLoc:TKMPoint);
    function  RemoveEntry(aLoc:TKMPoint):cardinal; virtual;
    procedure InjectEntry(ID:integer; aLoc:TKMPoint);
    function  GetRandom(out Point: TKMPoint):Boolean;
    function  GetClosest(aLoc:TKMPoint; out Point: TKMPoint):Boolean;
    procedure Inverse;
    function  GetTopLeft(out TL: TKMPoint):Boolean;
    function  GetBottomRight(out RB: TKMPoint):Boolean;
    procedure Save(SaveStream:TKMemoryStream); virtual;
  end;


  TKMPointTagList = class(TKMPointList)
  public
    Tag,Tag2:array of integer; //1..Count
    procedure Load(LoadStream:TKMemoryStream); override;
    procedure Clearup; override;
    procedure AddEntry(aLoc:TKMPoint; aTag,aTag2:cardinal); reintroduce;
    function RemoveEntry(aLoc:TKMPoint):cardinal; override;
    procedure Save(SaveStream:TKMemoryStream); override;
  end;


  TKMPointDirList = class //Used for finding fishing places, fighting positions, etc.
  public
    Count:integer;
    List:array of TKMPointDir; //1..Count
    constructor Load(LoadStream:TKMemoryStream);
    procedure Clearup;
    procedure AddEntry(aLoc:TKMPointDir);
    function GetRandom(out Point: TKMPointDir):Boolean;
    procedure Save(SaveStream:TKMemoryStream);
  end;


  //Custom Exception that includes a TKMPoint
  ELocError = class(Exception)
    Loc: TKMPoint;
    constructor Create(const Msg: string; aLoc:TKMPoint);
  end;


implementation
uses KM_Utils;


{ ELocError }
constructor ELocError.Create(const Msg: string; aLoc:TKMPoint);
begin
  Inherited Create(Msg);
  Loc := aLoc;
end;


{ TMPGameInfo }
procedure TMPGameInfo.LoadFromText(aText:string);
var M:TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  try
    M.WriteAsText(aText);
    M.Read(GameState, SizeOf(GameState));
    M.Read(Players);
    M.Read(Map);
    M.Read(GameTime, SizeOf(GameTime));
  finally
    M.Free;
  end;
end;


function TMPGameInfo.GetFormattedTime:string;
begin
  if GameTime >= 0 then
    Result := FormatDateTime('hh:nn:ss', GameTime)
  else
    Result := '';
end;


function TMPGameInfo.GetAsText:string;
var M:TKMemoryStream;
begin
  M := TKMemoryStream.Create;

  M.Write(GameState, SizeOf(GameState));
  M.Write(Players);
  M.Write(Map);
  M.Write(GameTime, SizeOf(GameTime));

  Result := M.ReadAsText;
  M.Free;
end;


function TMPGameInfo.GetAsHTML:string;
begin
  Result := '';
  Result := Result + Map;
  Result := Result +'<BR>'+ GetFormattedTime;
  Result := Result +'<BR>'+ Players;
end;


{ TKMList }
procedure TKMList.Clear;
var i:integer;
begin
  for i:=0 to Count-1 do begin
    TObject(Items[i]).Free;
    Items[i]:=nil;
  end;
  Inherited;
end;


{ TKMemoryStream }
procedure TKMemoryStream.Write(const Value:string);
var i:word;
begin
  i := length(Value);
  Inherited Write(i, SizeOf(i));
  if i=0 then exit;
  Inherited Write(Value[1], i);
end;

procedure TKMemoryStream.Write(const Value:TKMPointDir);
begin
  Write(Value.Loc);
  Inherited Write(Value.Dir, SizeOf(Value.Dir));
end;


function TKMemoryStream.Write(const Value:TKMDirection): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:TKMPoint): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:TKMPointF): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:single): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:integer): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:cardinal): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:byte): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:boolean): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:word): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;
function TKMemoryStream.Write(const Value:shortint): Longint;
begin Result := Inherited Write(Value, SizeOf(Value)); end;


procedure TKMemoryStream.WriteAsText(aText:string);
begin
  Position := 0;
  Write(aText[1], length(aText));
  Position := 0;
end;


procedure TKMemoryStream.Read(out Value:string);
var i:word;
begin
  Read(i, SizeOf(i));
  SetLength(Value, i);
  if i=0 then exit;
  Read(Value[1], i);
end;

procedure TKMemoryStream.Read(out Value:TKMPointDir);
begin
  Read(Value.Loc);
  Read(Value.Dir, SizeOf(Value.Dir));
end;

function TKMemoryStream.Read(out Value:TKMDirection): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:TKMPoint): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:TKMPointF): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:single): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:integer): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:cardinal): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:byte): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:boolean): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:word): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;
function TKMemoryStream.Read(out Value:shortint): Longint;
begin Result := Inherited Read(Value, SizeOf(Value)); end;


function TKMemoryStream.ReadAsText:string;
begin
  SetString(Result, PChar(Memory), Size div SizeOf(Char));
end;


{ TKMPointList }
procedure TKMPointList.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited Create;
  LoadStream.Read(Count);
  setlength(List,Count+32);
  for i:=1 to Count do
  LoadStream.Read(List[i]);
end;


procedure TKMPointList.Clearup;
begin
  Count := 0;
  setlength(List, 0);
end;


procedure TKMPointList.AddEntry(aLoc:TKMPoint);
begin
  inc(Count);
  if Count>length(List)-1 then setlength(List,Count+32);
  List[Count]:=aLoc;
end;


{Remove point from the list if is there. Return 'true' if succeded}
function TKMPointList.RemoveEntry(aLoc:TKMPoint):cardinal;
var i: integer; Found: boolean;
begin
  Result:=0;
  Found := false;
  for i:=1 to Count do
  begin
    if (KMSamePoint(List[i],aLoc) and (not Found)) then
    begin
      dec(Count);
      Found := true;
      Result:=i;
    end;
    if (Found) and (i < Count) then List[i] := List[i+1];
  end;
end;


{ Insert an entry and check if list is still walkable
  Walkable means that every point is next to neighbour points }
procedure TKMPointList.InjectEntry(ID:integer; aLoc:TKMPoint);
var i:integer;
begin
  AddEntry(List[Count]);
  for i:=Count downto ID+1 do
    List[i]:=List[i-1];
  List[ID]:=aLoc;

  if ID = 1 then Assert(GetLength(List[ID],List[ID+1])<1.5); //Inject first
  if ID = Count then Assert(GetLength(List[ID-1],List[ID])<1.5); //Inject last
end;


function TKMPointList.GetRandom(out Point: TKMPoint):Boolean;
begin
  if Count=0 then
    Result := False
  else begin
    Point := List[KaMRandom(Count)+1];
    Result := True;
  end;
end;


function TKMPointList.GetClosest(aLoc: TKMPoint; out Point: TKMPoint): Boolean;
var i:integer;
begin
  if Count=0 then
    Result := False
  else begin
    Point := List[1];
    for i:=2 to Count do
    if GetLength(List[i], aLoc) < GetLength(Point, aLoc) then
      Point := List[i];
    Result := True;
  end;
end;


//Reverse the list
procedure TKMPointList.Inverse;
var i:integer;
begin
  for i:=1 to Count div 2 do
    KMSwapPoints(List[i],List[Count-i+1]); //Do +1 since i starts from 1
end;


function TKMPointList.GetTopLeft(out TL: TKMPoint): Boolean;
var i:integer;
begin
  Result := Count > 0;
  if Result then
  begin
    TL := List[1]; //Something to start with
    for i:=2 to Count do begin
      if List[i].X < TL.X then TL.X := List[i].X;
      if List[i].Y < TL.Y then TL.Y := List[i].Y;
    end;
  end;
end;


function TKMPointList.GetBottomRight(out RB: TKMPoint): Boolean;
var i:integer;
begin
  Result := Count > 0;
  if Result then
  begin
    RB := List[1]; //Something to start with
    for i:=2 to Count do begin
      if List[i].X > RB.X then RB.X := List[i].X;
      if List[i].Y > RB.Y then RB.Y := List[i].Y;
    end;
  end;
end;


procedure TKMPointList.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write(Count);
  for i:=1 to Count do
  SaveStream.Write(List[i]);
end;


{ TKMPointTagList }
procedure TKMPointTagList.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited; //Reads Count

  setlength(Tag,Count+32); //Make space in lists to write data to, otherwise we get "Range Check Error"
  setlength(Tag2,Count+32);
  for i:=1 to Count do
  begin
    LoadStream.Read(Tag[i]);
    LoadStream.Read(Tag2[i]);
  end;
end;


procedure TKMPointTagList.Clearup;
begin
  Inherited;
  setlength(Tag,0);
  setlength(Tag2,0);
end;


procedure TKMPointTagList.AddEntry(aLoc:TKMPoint; aTag,aTag2:cardinal);
begin
  Inherited AddEntry(aLoc);
  if Count>length(Tag)-1 then setlength(Tag,Count+32); //Expand the list
  if Count>length(Tag2)-1 then setlength(Tag2,Count+32); //+32 is just a way to avoid further expansions
  Tag[Count]:=aTag;
  Tag2[Count]:=aTag2;
end;


function TKMPointTagList.RemoveEntry(aLoc:TKMPoint):cardinal;
var i: integer;
begin
  Result := Inherited RemoveEntry(aLoc);

  for i:=Result to Count-1 do
  begin
    Tag[i] := Tag[i+1];
    Tag2[i] := Tag2[i+1];
  end;
end;


procedure TKMPointTagList.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  Inherited; //Writes Count

  for i:=1 to Count do
  begin
    SaveStream.Write(Tag[i]);
    SaveStream.Write(Tag2[i]);
  end;
end;


{ TKMPointList }
constructor TKMPointDirList.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited Create;
  LoadStream.Read(Count);
  setlength(List,Count+32); //Make space in lists to write data to, otherwise we get "Range Check Error"
  for i:=1 to Count do
  begin
    LoadStream.Read(List[i].Loc);
    LoadStream.Read(List[i].Dir);
  end;
end;


procedure TKMPointDirList.Clearup;
begin
  Count:=0;
  setlength(List,0);
end;


procedure TKMPointDirList.AddEntry(aLoc:TKMPointDir);
begin
  inc(Count);
  if Count>length(List)-1 then setlength(List,Count+32);
  List[Count]:=aLoc;
end;


function TKMPointDirList.GetRandom(out Point: TKMPointDir):Boolean;
begin
  Result := False;
  if Count > 0 then begin
    Point := List[KaMRandom(Count)+1];
    Result := True;
  end;
end;


procedure TKMPointDirList.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write(Count);
  for i:=1 to Count do
  begin
    SaveStream.Write(List[i].Loc);
    SaveStream.Write(List[i].Dir);
  end;
end;


end.