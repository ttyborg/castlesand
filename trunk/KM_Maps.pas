unit KM_Maps;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SyncObjs, SysUtils, KM_Defaults;


type
  TMapsSortMethod = (
    smByNameAsc, smByNameDesc,
    smBySizeAsc, smBySizeDesc,
    smByPlayersAsc, smByPlayersDesc,
    smByModeAsc, smByModeDesc);

  TKMapInfo = class;
  TMapEvent = procedure (aMap: TKMapInfo) of object;

  TKMMapGoalInfo = packed record
    Cond: TGoalCondition;
    Play: TPlayerIndex;
    Stat: TGoalStatus;
  end;

  TKMapInfo = class
  private
    fPath: string;
    fFileName: string; //without extension
    fStrictParsing: Boolean; //Use strict map checking, important for MP
    fCRC: Cardinal;
    fDatCRC: Cardinal; //Used to speed up scanning
    fVersion: AnsiString; //Savegame version, yet unused in maps, they always have actual version
    procedure LoadFromFile(const aPath: string);
    procedure SaveToFile(const aPath: string);
  public
    MapSizeX, MapSizeY: Integer;
    MissionMode: TKMissionMode;
    PlayerCount: Byte;
    CanBeHuman: array [0..MAX_PLAYERS-1] of Boolean;
    CanBeAI: array [0..MAX_PLAYERS-1] of Boolean;
    DefaultHuman: TPlayerIndex;
    GoalsVictoryCount, GoalsSurviveCount: array [0..MAX_PLAYERS-1] of Byte;
    GoalsVictory: array [0..MAX_PLAYERS-1] of array of TKMMapGoalInfo;
    GoalsSurvive: array [0..MAX_PLAYERS-1] of array of TKMMapGoalInfo;
    Alliances: array [0..MAX_PLAYERS-1, 0..MAX_PLAYERS-1] of TAllianceType;
    FlagColors: array [0..MAX_PLAYERS-1] of Cardinal;
    Author, SmallDesc, BigDesc: AnsiString;
    IsCoop: Boolean; //Some multiplayer missions are defined as coop

    constructor Create;
    destructor Destroy; override;

    procedure AddGoal(aType: TGoalType; aPlayer: TPlayerIndex; aCondition: TGoalCondition; aStatus: TGoalStatus; aPlayerIndex: TPlayerIndex);
    procedure Load(const aFolder: string; aStrictParsing, aIsMultiplayer: Boolean);
    procedure LoadExtra;
    procedure Clear;

    property Path: string read fPath;
    property FileName: string read fFileName;
    function FullPath(const aExt: string): string;
    property CRC: Cardinal read fCRC;
    function LocationName(aIndex: TPlayerIndex): string;
    function SizeText: string;
    function IsValid: Boolean;
  end;

  TTMapsScanner = class(TThread)
  private
    fMultiplayerPath: Boolean;
    fOnMapAdd: TMapEvent;
    fOnMapAddDone: TNotifyEvent;
  public
    constructor Create(aMultiplayerPath: Boolean; aOnMapAdd: TMapEvent; aOnMapAddDone, aOnComplete: TNotifyEvent);
    procedure Execute; override;
  end;

  TKMapsCollection = class
  private
    fCount: Integer;
    fMaps: array of TKMapInfo;
    fMultiplayerPath: Boolean;
    fSortMethod: TMapsSortMethod;
    CS: TCriticalSection;
    fScanner: TTMapsScanner;
    fScanning: Boolean; //Flag if scan is in progress
    fUpdateNeeded: Boolean;
    fOnRefresh: TNotifyEvent;
    procedure Clear;
    procedure MapAdd(aMap: TKMapInfo);
    procedure MapAddDone(Sender: TObject);
    procedure ScanComplete(Sender: TObject);
    procedure DoSort;
    function GetMap(aIndex: Integer): TKMapInfo;
  public
    constructor Create(aMultiplayerPath: Boolean; aSortMethod: TMapsSortMethod = smByNameDesc);
    destructor Destroy; override;

    property Count: Integer read fCount;
    property Maps[aIndex: Integer]: TKMapInfo read GetMap; default;
    procedure Lock;
    procedure Unlock;

    class function FullPath(const aName, aExt: string; aMultiplayer: Boolean): string;

    procedure Refresh(aOnRefresh: TNotifyEvent);
    procedure TerminateScan;
    procedure Sort(aSortMethod: TMapsSortMethod; aOnSortComplete: TNotifyEvent);
    property SortMethod: TMapsSortMethod read fSortMethod; //Read-only because we should not change it while Refreshing

    //Should be accessed only as a part of aOnRefresh/aOnSort events handlers
    function MapList: string;
    procedure UpdateState;
  end;


implementation
uses KM_CommonClasses, KM_MissionScript_Info, KM_Player, KM_TextLibrary, KM_Utils;


const
  //Folder name containing single maps for SP/MP mode
  MAP_FOLDER_MP: array [Boolean] of string = ('Maps', 'MapsMP');


{ TKMapInfo }
constructor TKMapInfo.Create;
begin
  inherited;

end;


destructor TKMapInfo.Destroy;
begin

  inherited;
end;


procedure TKMapInfo.Clear;
var
  I: Integer;
begin
  for I := 0 to MAX_PLAYERS - 1 do
  begin
    GoalsVictoryCount[I] := 0;
    GoalsSurviveCount[I] := 0;
    SetLength(GoalsVictory[I], 0);
    SetLength(GoalsSurvive[I], 0);
  end;
  //TODO: clear all fields
end;


procedure TKMapInfo.AddGoal(aType: TGoalType; aPlayer: TPlayerIndex; aCondition: TGoalCondition; aStatus: TGoalStatus; aPlayerIndex: TPlayerIndex);
var G: TKMMapGoalInfo;
begin
  G.Cond := aCondition;
  G.Play := aPlayerIndex;
  G.Stat := aStatus;

  case aType of
    glt_Victory:  begin
                    SetLength(GoalsVictory[aPlayer], GoalsVictoryCount[aPlayer] + 1);
                    GoalsVictory[aPlayer, GoalsVictoryCount[aPlayer]] := G;
                    Inc(GoalsVictoryCount[aPlayer]);
                  end;
    glt_Survive:  begin
                    SetLength(GoalsSurvive[aPlayer], GoalsSurviveCount[aPlayer] + 1);
                    GoalsSurvive[aPlayer, GoalsSurviveCount[aPlayer]] := G;
                    Inc(GoalsSurviveCount[aPlayer]);
                  end;
    else          ;
  end;
end;


function TKMapInfo.FullPath(const aExt: string): string;
begin
  Result := fPath + fFileName + aExt;
end;


function TKMapInfo.LocationName(aIndex: TPlayerIndex): string;
begin
  Result := Format(fTextLibrary[TX_LOBBY_LOCATION_X], [aIndex + 1]);
end;


function TKMapInfo.SizeText: string;
begin
  Result := MapSizeText(MapSizeX, MapSizeY);
end;


procedure TKMapInfo.Load(const aFolder: string; aStrictParsing, aIsMultiplayer: Boolean);
var
  st, DatFile, MapFile, ScriptFile: string;
  DatCRC, OthersCRC: Cardinal;
  ft: TextFile;
  fMissionParser: TMissionParserInfo;
begin
  Clear;

  fPath := ExeDir + MAP_FOLDER_MP[aIsMultiplayer] + '\' + aFolder + '\';
  fFileName := aFolder;

  fStrictParsing := aStrictParsing;

  DatFile := fPath + fFileName + '.dat';
  MapFile := fPath + fFileName + '.map';
  ScriptFile := fPath + fFileName + '.script'; //Needed for CRC

  if not FileExists(DatFile) then Exit;

  //Try loading info from cache, since map scanning is rather slow
  LoadFromFile(fPath + fFileName + '.mi'); //Data will be empty if failed

  //We will scan map once again if anything has changed
  //In SP mode (non-strict) we check DAT CRC and version, that is enough
  //In MP mode (strict) we also need exact CRCs to match maps between players

  DatCRC := Adler32CRC(DatFile);
  //.map file CRC is the slowest, so only calculate it if necessary
  OthersCRC := 0; //Supresses incorrect warning by Delphi
  if fStrictParsing then
    OthersCRC := Adler32CRC(MapFile) xor Adler32CRC(ScriptFile);

  //Does the map need to be fully rescanned? (.mi cache is outdated?)
  if (fVersion <> GAME_REVISION) or
     (fDatCRC <> DatCRC) or //In non-strict mode only DAT CRC matters (SP)
     (fStrictParsing and (fCRC <> DatCRC xor OthersCRC)) //In strict mode we check all CRCs (MP)
  then
  begin
    //Calculate OthersCRC if it wasn't calculated before
    if not fStrictParsing then
      OthersCRC := Adler32CRC(MapFile) xor Adler32CRC(ScriptFile);

    fCRC := DatCRC xor OthersCRC;
    fDatCRC := DatCRC;
    fVersion := GAME_REVISION;

    fMissionParser := TMissionParserInfo.Create(False);
    try
      //Fill Self properties with MissionParser
      fMissionParser.LoadMission(DatFile, Self, pmBase);
    finally
      fMissionParser.Free;
    end;

    //Load additional text info
    if FileExists(fPath + fFileName + '.txt') then
    begin
      AssignFile(ft, fPath + fFileName + '.txt');
      FileMode := fmOpenRead;
      Reset(ft);
      repeat
        ReadLn(ft, st);
        if SameText(st, 'SmallDesc') then ReadLn(ft, SmallDesc);
      until(eof(ft));
      CloseFile(ft);
    end;

    SaveToFile(fPath + fFileName + '.mi'); //Save new cache file
  end;
end;


//Load additional information for map that is not in main SP list
procedure TKMapInfo.LoadExtra;
var
  st, DatFile, MapFile: string;
  ft: TextFile;
  fMissionParser: TMissionParserInfo;
begin
  DatFile := fPath + fFileName + '.dat';
  MapFile := fPath + fFileName + '.map';

  fMissionParser := TMissionParserInfo.Create(False);
  try
    //Fill Self properties with MissionParser
    fMissionParser.LoadMission(DatFile, Self, pmExtra);
  finally
    fMissionParser.Free;
  end;

  //Load additional text info
  if FileExists(fPath + fFileName + '.txt') then
  begin
    AssignFile(ft, fPath + fFileName + '.txt');
    FileMode := fmOpenRead;
    Reset(ft);
    repeat
      ReadLn(ft, st);
      if SameText(st, 'Author')    then ReadLn(ft, Author);
      if SameText(st, 'BigDesc')   then ReadLn(ft, BigDesc);
      if SameText(st, 'SetCoop')   then IsCoop := True;
    until(eof(ft));
    CloseFile(ft);
  end;
end;


procedure TKMapInfo.LoadFromFile(const aPath: string);
var
  S: TKMemoryStream;
begin
  if not FileExists(aPath) then Exit;

  S := TKMemoryStream.Create;
  S.LoadFromFile(aPath);

  //Internal properties
  S.Read(fCRC);
  S.Read(fDatCRC);
  S.Read(fVersion);

  //Exposed properties
  S.Read(MapSizeX);
  S.Read(MapSizeY);
  S.Read(MissionMode, SizeOf(TKMissionMode));
  S.Read(PlayerCount);
  S.Read(SmallDesc);

  //Other properties are not saved, they are fast to reload
  S.Free;
end;


procedure TKMapInfo.SaveToFile(const aPath: string);
var
  S: TKMemoryStream;
begin
  S := TKMemoryStream.Create;
  try
    //Internal properties
    S.Write(fCRC);
    S.Write(fDatCRC);
    S.Write(fVersion);

    //Exposed properties
    S.Write(MapSizeX);
    S.Write(MapSizeY);
    S.Write(MissionMode, SizeOf(TKMissionMode));
    S.Write(PlayerCount);
    S.Write(SmallDesc);

    //Other properties from text file are not saved, they are fast to reload
    S.SaveToFile(aPath);
  finally
    S.Free;
  end;
end;


function TKMapInfo.IsValid: Boolean;
begin
  Result := (PlayerCount > 0) and
            FileExists(fPath + fFileName + '.dat') and
            FileExists(fPath + fFileName + '.map');
end;


{ TKMapsCollection }
constructor TKMapsCollection.Create(aMultiplayerPath: Boolean; aSortMethod: TMapsSortMethod = smByNameDesc);
begin
  inherited Create;
  fMultiplayerPath := aMultiplayerPath;
  fSortMethod := aSortMethod;

  //CS is used to guard sections of code to allow only one thread at once to access them
  //We mostly don't need it, as UI should access Maps only when map events are signaled
  //it mostly acts as a safenet
  CS := TCriticalSection.Create;
end;


destructor TKMapsCollection.Destroy;
begin
  //Terminate and release the Scanner if we have one working or finished
  TerminateScan;

  //Release TKMapInfo objects
  Clear;

  CS.Free;
  inherited;
end;


function TKMapsCollection.GetMap(aIndex: Integer): TKMapInfo;
begin
  //No point locking/unlocking here since we return a TObject that could be modified/freed
  //by another thread before the caller uses it.
  Assert(InRange(aIndex, 0, fCount - 1));
  Result := fMaps[aIndex];
end;


procedure TKMapsCollection.Lock;
begin
  CS.Enter;
end;


procedure TKMapsCollection.Unlock;
begin
  CS.Leave;
end;


function TKMapsCollection.MapList: string;
var I: Integer;
begin
  Lock;
    Result := '';
    for I := 0 to fCount - 1 do
      Result := Result + fMaps[I].FileName + eol;
  Unlock;
end;


procedure TKMapsCollection.Clear;
var
  I: Integer;
begin
  Assert(not fScanning, 'Guarding from access to inconsistent data');
  for I := 0 to fCount - 1 do
    FreeAndNil(fMaps[I]);
  fCount := 0;
end;


procedure TKMapsCollection.UpdateState;
begin
  if fUpdateNeeded then
  begin
    if Assigned(fOnRefresh) then
      fOnRefresh(Self);

    fUpdateNeeded := False;
  end;
end;


//For private acces, where CS is managed by the caller
procedure TKMapsCollection.DoSort;
  //Return True if items should be exchanged
  function Compare(A, B: TKMapInfo; aMethod: TMapsSortMethod): Boolean;
  begin
    Result := False; //By default everything remains in place
    case aMethod of
      smByNameAsc:      Result := CompareText(A.FileName, B.FileName) < 0;
      smByNameDesc:     Result := CompareText(A.FileName, B.FileName) > 0;
      smBySizeAsc:      Result := (A.MapSizeX * A.MapSizeY) < (B.MapSizeX * B.MapSizeY);
      smBySizeDesc:     Result := (A.MapSizeX * A.MapSizeY) > (B.MapSizeX * B.MapSizeY);
      smByPlayersAsc:   Result := A.PlayerCount < B.PlayerCount;
      smByPlayersDesc:  Result := A.PlayerCount > B.PlayerCount;
      smByModeAsc:      Result := A.MissionMode < B.MissionMode;
      smByModeDesc:     Result := A.MissionMode > B.MissionMode;
    end;
  end;
var
  I, K: Integer;
begin
  for I := 0 to fCount - 1 do
  for K := I to fCount - 1 do
  if Compare(fMaps[I], fMaps[K], fSortMethod) then
    SwapInt(Cardinal(fMaps[I]), Cardinal(fMaps[K])); //Exchange only pointers to MapInfo objects
end;


//For public access
//Apply new Sort within Critical Section, as we could be in the Refresh phase
//note that we need to preserve fScanning flag
procedure TKMapsCollection.Sort(aSortMethod: TMapsSortMethod; aOnSortComplete: TNotifyEvent);
begin
  Lock;
  try
    if fScanning then
    begin
      fScanning := False;
      fSortMethod := aSortMethod;
      DoSort;
      if Assigned(aOnSortComplete) then
        aOnSortComplete(Self);
      fScanning := True;
    end
    else
    begin
      fSortMethod := aSortMethod;
      DoSort;
      if Assigned(aOnSortComplete) then
        aOnSortComplete(Self);
    end;
  finally
    Unlock;
  end;
end;


procedure TKMapsCollection.TerminateScan;
begin
  if (fScanner <> nil) then
  begin
    fScanner.Terminate;
    fScanner.WaitFor;
    fScanner.Free;
    fScanner := nil;
    fScanning := False;
  end;
end;


//Start the refresh of maplist
procedure TKMapsCollection.Refresh(aOnRefresh: TNotifyEvent);
begin
  //Terminate previous Scanner if two scans were launched consequentialy
  TerminateScan;
  Clear;

  fOnRefresh := aOnRefresh;

  //Scan will launch upon create automatcally
  fScanning := True;
  fScanner := TTMapsScanner.Create(fMultiplayerPath, MapAdd, MapAddDone, ScanComplete);
end;


procedure TKMapsCollection.MapAdd(aMap: TKMapInfo);
begin
  Lock;
  try
    SetLength(fMaps, fCount + 1);
    fMaps[fCount] := aMap;
    Inc(fCount);

    //Set the scanning to false so we could Sort
    fScanning := False;

    //Keep the maps sorted
    //We signal from Locked section, so everything caused by event can safely access our Maps
    DoSort;

    fScanning := True;
  finally
    Unlock;
  end;
end;


procedure TKMapsCollection.MapAddDone(Sender: TObject);
begin
  fUpdateNeeded := True; //Next time the GUI thread calls UpdateState we will run fOnRefresh
end;


//All maps have been scanned
//No need to resort since that was done in last MapAdd event
procedure TKMapsCollection.ScanComplete(Sender: TObject);
begin
  Lock;
  try
    fScanning := False;
  finally
    Unlock;
  end;
end;


class function TKMapsCollection.FullPath(const aName, aExt: string; aMultiplayer: Boolean): string;
begin
  Result := ExeDir + MAP_FOLDER_MP[aMultiplayer] + '\' + aName + '\' + aName + aExt;
end;


{ TTMapsScanner }
//aOnMapAdd - signal that there's new map that should be added
//aOnMapAddDone - signal that map has been added
//aOnComplete - scan is complete
constructor TTMapsScanner.Create(aMultiplayerPath: Boolean; aOnMapAdd: TMapEvent; aOnMapAddDone, aOnComplete: TNotifyEvent);
begin
  //Thread isn't started until all constructors have run to completion
  //so Create(False) may be put in front as well
  inherited Create(False);

  Assert(Assigned(aOnMapAdd));

  fMultiplayerPath := aMultiplayerPath;
  fOnMapAdd := aOnMapAdd;
  fOnMapAddDone := aOnMapAddDone;
  OnTerminate := aOnComplete;
  FreeOnTerminate := False;
end;


procedure TTMapsScanner.Execute;
var
  SearchRec: TSearchRec;
  PathToMaps: string;
  Map: TKMapInfo;
begin
  PathToMaps := ExeDir + MAP_FOLDER_MP[fMultiplayerPath] + '\';

  if not DirectoryExists(PathToMaps) then Exit;

  FindFirst(PathToMaps + '*', faDirectory, SearchRec);
  repeat
    if (SearchRec.Name <> '.') and (SearchRec.Name <> '..')
    and FileExists(TKMapsCollection.FullPath(SearchRec.Name, '.dat', fMultiplayerPath))
    and FileExists(TKMapsCollection.FullPath(SearchRec.Name, '.map', fMultiplayerPath)) then
    begin
      Map := TKMapInfo.Create;
      Map.Load(SearchRec.Name, false, fMultiplayerPath);
      if SLOW_MAP_SCAN then
        Sleep(50);
      fOnMapAdd(Map);
      fOnMapAddDone(Self);
    end;
  until (FindNext(SearchRec) <> 0) or Terminated;
  FindClose(SearchRec);
end;


end.

