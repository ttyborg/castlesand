unit KM_Networking;
{$I KaM_Remake.inc}
interface
uses Classes, KM_Defaults, KM_CommonTypes, KM_Network, KM_Player, KromUtils, SysUtils, StrUtils, Math, Windows;


type TStringEvent = procedure (const aData: string) of object;
type TStreamEvent = procedure (aData: TKMemoryStream) of object;

type TLANPlayerKind = (lpk_Host, lpk_Joiner);

type TMessageKind = (
                      mkUnknown,
                      mk_AskToJoin,
                      mk_Timeout,
                      mk_AllowToJoin,
                      //mk_RefuseToJoin, //When max players is exceeded
                      mk_VerifyJoin,
                      mk_PlayersList,
                      mk_ReadyToStart, //Joiner telling he's ready
                      mk_MapSelect,

                      mk_Text,
                      mk_GameSetup,
                      mk_Gameplay);

type
  TKMPlayerInfo = class
    Addr:string;
    Nikname:string;
    PlayerType:TPlayerType;
    FlagColor:cardinal;
    StartLocID:integer;
    Alliances:array[1..MAX_PLAYERS] of TAllianceType;
    ReadyToStart:boolean;
  end;


//Handles everything related to players list,
//but knows nothing about networking nor game setup. Only players.
type
  TKMPlayersList = class
    private
      fCount:integer;
      fPlayers:array [1..MAX_PLAYERS] of TKMPlayerInfo;
      function GetAsStringList:string;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Clear;
      property Count:integer read fCount;

      //Setters
      procedure AddPlayer(aAddr,aNik:string);
      //procedure SetColor(aNik:string; aColor:cardinal);
      //procedure SetStartLoc(aNik:string; aLoc:integer);
      //procedure SetAlliances(aNik:string; aAlliances);
      procedure SetReady(aNik:string{; aReady:boolean});

      //Getters
      function GetAddress(aIndex:integer):string;
      function GetNikname(aIndex:integer):string;
      //function GetIndexByNik(aNikname:string):integer;
      function IsHuman(aIndex:integer):boolean;
      function AllReady:boolean;

      //Import/Export
      property AsStringList:string read GetAsStringList; //Acquire list of players for UI Listbox
      function GetAsText:string; //Gets all relevant information as text string
      procedure SetAsText(a:string); //Sets all relevant information from text string
    end;


type //Should handle message exchange and routing, interacting with UI
  TKMNetworking = class
    private
      fNetwork:TKMNetwork;
      fLANPlayerKind: TLANPlayerKind;
      fHostAddress:string;
      fMyAddress:string;
      fMyNikname:string;
      fPlayers:TKMPlayersList;

      fMapName:string;

      fJoinTick:cardinal;
      fOnJoinSucc:TNotifyEvent;
      fOnJoinFail:TNotifyEvent;
      fOnTextMessage:TStringEvent;
      fOnPlayersList:TStringEvent;
      fOnMapName:TStringEvent;
      fOnAllReady:TNotifyEvent;
      fOnCommands:TStreamEvent;

      procedure EncodeGameSetup(aStream:TKMemoryStream);

      procedure PacketRecieve(const aData: array of byte; aAddr:string); //Process all commands
      procedure PacketRecieveJoin(const aData: array of byte; aAddr:string); //Process only "Join" commands
      procedure PacketSend(const aAddress:string; aKind:TMessageKind; const aData:string='');
      procedure PacketToAll(aKind:TMessageKind; const aData:string='');
      procedure PacketToHost(aKind:TMessageKind; const aData:string='');
    public
      constructor Create;
      destructor Destroy; override;

      //Lobby
      function MyIPString:string;
      function MyIPStringAndPort:string;
      procedure Host(aUserName:string);
      procedure Connect(aServerAddress,aUserName:string);
      procedure Disconnect;
      function Connected: boolean;
      procedure MapSelect(aName:string);
      procedure ReadyToStart;
      procedure StartGame; //All arguments required are in our class

      //Common
      procedure PostMessage(aText:string);

      //Gameplay
      procedure SendCommands(aStream:TKMemoryStream);

      property OnJoinSucc:TNotifyEvent write fOnJoinSucc;
      property OnJoinFail:TNotifyEvent write fOnJoinFail;
      property OnTextMessage:TStringEvent write fOnTextMessage;
      property OnPlayersList:TStringEvent write fOnPlayersList;
      property OnMapName:TStringEvent write fOnMapName;
      property OnAllReady:TNotifyEvent write fOnAllReady;
      property OnCommands:TStreamEvent write fOnCommands;
      procedure UpdateState;
    end;


implementation


constructor TKMPlayersList.Create;
var i:integer;
begin
  for i:=1 to MAX_PLAYERS do
    fPlayers[i] := TKMPlayerInfo.Create;
end;


destructor TKMPlayersList.Destroy;
var i:integer;
begin
  for i:=1 to MAX_PLAYERS do
    fPlayers[i].Free;
  Inherited;
end;


procedure TKMPlayersList.Clear;
begin
  fCount := 0;
end;


function TKMPlayersList.GetAsStringList:string;
var i:integer;
begin
  Result := '';
  for i:=1 to fCount do
    Result := Result + fPlayers[i].Addr + '/' + fPlayers[i].Nikname + eol;
end;


procedure TKMPlayersList.AddPlayer(aAddr,aNik:string);
var i:integer;
begin
  inc(fCount);
  fPlayers[fCount].Addr := aAddr;
  fPlayers[fCount].Nikname := aNik;
  fPlayers[fCount].PlayerType := pt_Human;
  fPlayers[fCount].FlagColor := 0;
  fPlayers[fCount].StartLocID := fCount;
  for i:=1 to MAX_PLAYERS do
    fPlayers[fCount].Alliances[i] := at_Enemy;
  fPlayers[fCount].ReadyToStart := false;
end;


procedure TKMPlayersList.SetReady(aNik:string);
var i:integer;
begin
  for i:=1 to fCount do
    if fPlayers[i].Nikname = aNik then
      fPlayers[i].ReadyToStart := true;
end;


function TKMPlayersList.GetAddress(aIndex:integer):string;
begin
  Result := fPlayers[aIndex].Addr;
end;


function TKMPlayersList.GetNikname(aIndex:integer):string;
begin
  Result := fPlayers[aIndex].Nikname;
end;


{function TKMPlayersList.GetIndexByNik(aNikname:string):integer;
var i:integer;
begin
  Result := 0;
  for i:=1 to fCount do
    if fPlayers[i].Nikname = aNikname then begin
      Result := i;
      exit;
    end;
  Assert(Result <> 0, '');
end;}


function TKMPlayersList.IsHuman(aIndex:integer):boolean;
begin
  Result := fPlayers[aIndex].PlayerType = pt_Human;
end;


function TKMPlayersList.AllReady:boolean;
var i:integer;
begin
  Result := true;
  for i:=1 to fCount do
    Result := Result and fPlayers[i].ReadyToStart;
end;


{//Broadcast to all except self
procedure TKMPlayersList.PacketToAll(aNetwork:TKMNetwork; aKind:TMessageKind; const aData:string='');
var i:integer;
begin
  for i:=1 to fCount do
    if (fPlayers[i].PlayerType <> pt_Computer) and
       //(fPlayers[i].Addr <> fMyAddr) and //Disabled cos testing on 1 PC messes up Addresses
       (fPlayers[i].Nikname <> fMyNik) then
      aNetwork.SendTo(fPlayers[i].Addr, char(aKind) + aData);
end;}


{procedure TKMPlayersList.PacketToHost(aNetwork:TKMNetwork; aKind:TMessageKind; const aData:string='');
begin
  aNetwork.SendTo(fPlayers[1].Addr, char(aKind) + aData);
end;}


//Save whole amount of data as string to be sent across network to other players
//I estimate it ~50bytes per player at max
//later it will be byte array?
function TKMPlayersList.GetAsText:string;
var i:integer; M:TKMemoryStream;
begin
  M := TKMemoryStream.Create;

  M.Write(fCount);
  for i:=1 to fCount do
  begin
    M.Write(fPlayers[i].Addr);
    M.Write(fPlayers[i].Nikname);
  end;

  Result := M.ReadAsText;
  M.Free;
end;


procedure TKMPlayersList.SetAsText(a:string);
var i:integer; M:TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  M.WriteAsText(a);

  M.Read(fCount);
  for i:=1 to fCount do
  begin
    M.Read(fPlayers[i].Addr);
    M.Read(fPlayers[i].Nikname);
  end;

  M.Free;
end;


{ TKMNetworking }
constructor TKMNetworking.Create;
begin
  Inherited;
  fNetwork  := TKMNetwork.Create(MULTIPLE_COPIES);
  fPlayers  := TKMPlayersList.Create;
end;


destructor TKMNetworking.Destroy;
begin
  fPlayers.Free;
  fNetwork.Free;
  Inherited;
end;


function TKMNetworking.MyIPString:string;
begin
  Result := fNetwork.MyIPString;
end;


function TKMNetworking.MyIPStringAndPort:string;
begin
  Result := fNetwork.MyIPStringAndPort;
end;


procedure TKMNetworking.Host(aUserName:string);
begin
  fJoinTick := 0;
  fHostAddress := ''; //Thats us
  fMyAddress := MyIPString;
  fMyNikname := aUserName;
  fLANPlayerKind := lpk_Host;
  fPlayers.Clear;
  fPlayers.AddPlayer(MyIPString, aUserName);
  fPlayers.SetReady(fMyNikname);
  fNetwork.StartListening;
  fNetwork.OnRecieveKMPacket := PacketRecieve; //Start listening
  if Assigned(fOnPlayersList) then fOnPlayersList(fPlayers.AsStringList);
end;


procedure TKMNetworking.Connect(aServerAddress,aUserName:string);
begin
  fHostAddress := aServerAddress;
  fMyAddress := MyIPString;
  fMyNikname := aUserName;
  fLANPlayerKind := lpk_Joiner;
  fJoinTick := GetTickCount + 3000; //3sec
  fPlayers.Clear;
  fPlayers.AddPlayer(MyIPString, aUserName);
  fNetwork.StartListening;
  PacketToHost(mk_AskToJoin);
  fNetwork.OnRecieveKMPacket := PacketRecieveJoin; //Unless we join use shortlist
end;


procedure TKMNetworking.Disconnect;
begin
  fNetwork.StopListening;
  fPlayers.Clear;
end;


function TKMNetworking.Connected: boolean;
begin
  Result := fNetwork.fListening;
end;


//Tell other players which map we will be using
procedure TKMNetworking.MapSelect(aName:string);
begin
  Assert(fLANPlayerKind = lpk_Host, 'Only host can select maps');

  fMapName := aName;
  PacketToAll(mk_MapSelect, fMapName);

  if Assigned(fOnMapName) then fOnMapName(fMapName);

  //Compare map availability and CRC
end;


//Joiner indicates that he is ready to start
procedure TKMNetworking.ReadyToStart;
begin
  fPlayers.SetReady(fMyNikname);
  PacketToAll(mk_ReadyToStart, fMyNikname);
end;


//Tell other players we want to start
//Send whole game setup info at once, making sure there are no misunderstandings,
//especially about random values (e.g. start locations)
procedure TKMNetworking.StartGame;
var Msg:TKMemoryStream;
begin
  Assert(fLANPlayerKind = lpk_Host, 'Only host can start the game');
  Assert(fPlayers.AllReady, 'Not everyone is ready to start');

  Msg := TKMemoryStream.Create;
  EncodeGameSetup(Msg);
  //fPlayers.PacketSend(mk_StartGame, Msg);
  Msg.Free;

  //Now we will await confirmation messages from other players and start the game
end;


//Encode whole set of game settings into a stream (including players list)
procedure TKMNetworking.EncodeGameSetup(aStream:TKMemoryStream);
begin
  aStream.Write(fMapName);
  //aStream.Write(AllianceMode); //Fixed / changeable
  //aStream.Write(StartupConditions);
  //aStream.Write(WinConditions);
  //aStream.Write(DefeatConditions);
  //fPlayers.Save(aStream);
end;


procedure TKMNetworking.PostMessage(aText:string);
begin
  PacketToAll(mk_Text, fMyAddress + '/' + fMyNikname + ': ' + aText);
  fOnTextMessage(fMyAddress + '/' + fMyNikname + ': ' + aText);
end;


procedure TKMNetworking.SendCommands(aStream:TKMemoryStream);
//var i:integer;
begin
  //for i:=1 to fPlayersList.Count-1 do
  //todo: send commands to all players
end;


procedure TKMNetworking.PacketRecieve(const aData: array of byte; aAddr:string);
var Kind:TMessageKind; Data:string;
begin
  Assert(Length(aData) >= 1, 'Unexpectedly short message'); //Kind, Message

  Kind := TMessageKind(aData[0]);
  if Length(aData) > 1 then
    SetString(Data, PAnsiChar(@aData[1]), Length(aData)-1)
  else
    Data := '';

  case Kind of
    mk_AskToJoin:   PacketSend(aAddr, mk_AllowToJoin);
    mk_VerifyJoin:  begin
                      fPlayers.AddPlayer(aAddr, Data);
                      if Assigned(fOnPlayersList) then fOnPlayersList(fPlayers.AsStringList);
                      PacketToAll(mk_PlayersList, fPlayers.GetAsText);
                      PostMessage(aAddr+'/'+Data+' has joined');
                    end;
    mk_PlayersList: begin
                      fPlayers.SetAsText(Data);
                      if Assigned(fOnPlayersList) then fOnPlayersList(fPlayers.AsStringList);
                    end;
    mk_ReadyToStart:begin
                      fPlayers.SetReady(Data);
                      if (fLANPlayerKind = lpk_Host) and fPlayers.AllReady and (fPlayers.Count>1) then
                        if Assigned(fOnAllReady) then fOnAllReady(nil);
                    end;
    mk_MapSelect:   begin
                      fMapName := Data;
                      if Assigned(fOnMapName) then fOnMapName(fMapName);
                    end;
    mk_Text:        if Assigned(fOnTextMessage) then fOnTextMessage(Data);
  end;
end;


procedure TKMNetworking.PacketRecieveJoin(const aData: array of byte; aAddr:string);
var Kind:TMessageKind;
begin
  Kind := TMessageKind(aData[0]);
  case Kind of //Handle only 2 messages kinds
    mk_AllowToJoin: begin
                      fJoinTick := 0;
                      fNetwork.OnRecieveKMPacket := PacketRecieve;
                      PacketToHost(mk_VerifyJoin, fMyNikname);
                      fOnJoinSucc(Self);
                    end;
    mk_Timeout:     begin
                      fJoinTick := 0;
                      fNetwork.OnRecieveKMPacket := nil;
                      fNetwork.StopListening;
                      fOnJoinFail(Self);
                    end;
  end;
end;


procedure TKMNetworking.PacketSend(const aAddress:string; aKind:TMessageKind; const aData:string='');
begin
  fNetwork.SendTo(aAddress, char(aKind) + aData);
end;


procedure TKMNetworking.PacketToAll(aKind:TMessageKind; const aData:string='');
var i:integer;
begin
  for i:=1 to fPlayers.Count do
    if fPlayers.IsHuman(i) and (fPlayers.GetNikname(i) <> fMyNikname) then
      PacketSend(fPlayers.GetAddress(i), aKind, aData);
end;


procedure TKMNetworking.PacketToHost(aKind:TMessageKind; const aData:string='');
begin
  Assert(fLANPlayerKind = lpk_Joiner, 'Only joined player can send data to Host');
  PacketSend(fHostAddress, aKind, aData);
end;


procedure TKMNetworking.UpdateState;
const MyArray : array[0..0] of byte = (byte(mk_Timeout)); //Convert byte to array
begin
  if (fJoinTick<>0) and (fJoinTick <= GetTickCount) then
    PacketRecieveJoin(MyArray, '127.0.0.1'); //Time is up, wait no longer
end;


end.
