unit KM_ClientOverbyte;
{$I KaM_Remake.inc}
interface
uses Classes, SysUtils, WSocket, WinSock;


{ This unit knows nothing about KaM, it's just a puppet in hands of KM_ClientControl,
doing all the low level work on TCP. So we can replace this unit with other TCP client
without KaM even noticing. }
type
  TNotifyDataEvent = procedure(aData:pointer; aLength:cardinal)of object;

  TKMClient = class
  private
    fSocket:TWSocket;
    fOnError:TGetStrProc;
    fOnConnectSucceed:TNotifyEvent;
    fOnConnectFailed:TGetStrProc;
    fOnSessionDisconnected:TNotifyEvent;
    fOnRecieveData:TNotifyDataEvent;
    procedure Connected(Sender: TObject; Error: Word);
    procedure Disconnected(Sender: TObject; Error: Word);
    procedure DataAvailable(Sender: TObject; Error: Word);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ConnectTo(const aAddress:string; const aPort:string);
    procedure Disconnect;
    procedure SendData(aData:pointer; aLength:cardinal);
    property OnError:TGetStrProc write fOnError;
    property OnConnectSucceed:TNotifyEvent write fOnConnectSucceed;
    property OnConnectFailed:TGetStrProc write fOnConnectFailed;
    property OnSessionDisconnected:TNotifyEvent write fOnSessionDisconnected;
    property OnRecieveData:TNotifyDataEvent write fOnRecieveData;
  end;


implementation


constructor TKMClient.Create;
var wsaData: TWSAData;
begin
  Inherited Create;
  Assert(WSAStartup($101, wsaData) = 0, 'Error in Network');
end;


destructor TKMClient.Destroy;
begin
  if fSocket<>nil then fSocket.Free;
  Inherited;
end;


procedure TKMClient.ConnectTo(const aAddress:string; const aPort:string);
begin
  fSocket := TWSocket.Create(nil);
  fSocket.Proto     := 'tcp';
  fSocket.Addr      := aAddress;
  fSocket.Port      := aPort;
  fSocket.OnSessionClosed := Disconnected;
  fSocket.OnSessionConnected := Connected;
  fSocket.OnDataAvailable := DataAvailable;
  fSocket.Connect;
end;


procedure TKMClient.Disconnect;
begin
  fSocket.Close;
end;


procedure TKMClient.SendData(aData:pointer; aLength:cardinal);
begin
  fSocket.Send(aData, aLength);
end;


procedure TKMClient.Connected(Sender: TObject; Error: Word);
begin
  if Error <> 0 then
    fOnConnectFailed('Error #' + IntToStr(Error))
  else
    fOnConnectSucceed(Self);
end;


procedure TKMClient.Disconnected(Sender: TObject; Error: Word);
begin
  if Error <> 0 then
    fOnError('Client: Disconnection error #' + IntToStr(Error))
  else
    fOnSessionDisconnected(Self);
end;


procedure TKMClient.DataAvailable(Sender: TObject; Error: Word);
const BufferSize = 10240; //10kb
var P:pointer; L:cardinal;
begin
  GetMem(P, BufferSize);
  L := TWSocket(Sender).Receive(P, BufferSize);
  fOnRecieveData(P, L);
  FreeMem(P);
end;


end.
