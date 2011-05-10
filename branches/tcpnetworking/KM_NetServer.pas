unit KM_NetServer;
{$I KaM_Remake.inc}
interface
uses Classes, SysUtils, KM_NetServerOverbyte;


{ Contains basic items we need for smooth Net experience:

    - start the server
    - stop the server

    - optionaly report non-important status messages

    - send server messages:
      1. player has disconnected
      2. players bindings (IDs)
      3. ...

  Everything except that whould be handled by Host (kick players, etc..)
}
type
  TKMNetServer = class
  private
    fClientList:TList; //Remember our clients in list
    fServer:TKMNetServerOverbyte;

    fBufferSize:cardinal;
    fBuffer:array of byte;

    fOnStatusMessage:TGetStrProc;
    procedure Error(const S: string);
    procedure ClientConnect(aHandle:integer);
    procedure ClientDisconnect(aHandle:integer);
    procedure DataAvailable(aHandle:integer; aData:pointer; aLength:cardinal);
  public
    constructor Create;
    destructor Destroy; override;
    procedure StartListening(aPort:string);
    procedure StopListening;
    property OnStatusMessage:TGetStrProc write fOnStatusMessage;
  end;


implementation


constructor TKMNetServer.Create;
begin
  Inherited;
  fClientList := TList.Create;
  fServer := TKMNetServerOverbyte.Create;
end;


destructor TKMNetServer.Destroy;
begin
  fServer.Free;
  fClientList.Free;
  Inherited;
end;


//There's an error in fServer, perhaps fatal for multiplayer.
procedure TKMNetServer.Error(const S: string);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Error '+S);
end;


procedure TKMNetServer.StartListening(aPort:string);
begin
  fServer.OnError := Error;
  fServer.OnClientConnect := ClientConnect;
  fServer.OnClientDisconnect := ClientDisconnect;
  fServer.OnDataAvailable := DataAvailable;
  fServer.StartListening(aPort);
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Listening..');
end;


procedure TKMNetServer.StopListening;
begin
  fServer.StopListening;
end;


//Someone has connected to us. We can use supplied Handle to negotiate
procedure TKMNetServer.ClientConnect(aHandle:integer);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Got connection '+inttostr(aHandle));
  fClientList.Add(pointer(aHandle));
end;


//Someone has disconnected from us. We can use supplied Handle to negotiate
procedure TKMNetServer.ClientDisconnect(aHandle:integer);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Client has disconnected '+inttostr(aHandle));
  fClientList.Remove(pointer(aHandle));
  //todo: Send message to remaining clients that client has disconnected
end;


//Someone has send us something
//For now just repeat the message to everyone excluding Sender
//Send only complete messages to allow to add server messages inbetween
procedure TKMNetServer.DataAvailable(aHandle:integer; aData:pointer; aLength:cardinal);
var i:integer; PacketLength:Cardinal;
begin
  //Append new data to buffer
  SetLength(fBuffer, fBufferSize + aLength);
  Move(aData^, fBuffer[fBufferSize], aLength);
  fBufferSize := fBufferSize + aLength;

  //Try to read data packet from buffer
  while fBufferSize >= 4 do
  begin
    PacketLength := PCardinal(fBuffer)^;
    if PacketLength <= fBufferSize-4 then
    begin

      for i:=0 to fClientList.Count-1 do
        if aHandle<>integer(fClientList.Items[i]) then
          fServer.SendData(cardinal(fClientList.Items[i]), @fBuffer[0], PacketLength+4);

      if 4+PacketLength < fBufferSize then //Check range
        Move(fBuffer[4+PacketLength], fBuffer[0], fBufferSize-PacketLength-4);
      fBufferSize := fBufferSize - PacketLength - 4;
    end else
      Exit;
  end;
end;


end.
