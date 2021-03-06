﻿unit KM_GUIGameChat;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Math, StrUtils, SysUtils,
  KM_Controls, KM_Defaults, KM_InterfaceDefaults, KM_InterfaceGame, KM_Networking;


type
  TKMGUIGameChat = class
  private
    fChatMode: TChatMode;
    fChatWhisperRecipient: Integer; //Server index of the player who will receive the whisper
    fLastChatTime: Cardinal; //Last time a chat message was sent to enforce cooldown
    procedure Chat_Close(Sender: TObject);
    procedure Chat_Post(Sender: TObject; Key:word);
    procedure Chat_Resize(Sender: TObject; X,Y: Integer);
    procedure Chat_MenuClick(Sender: TObject);
    procedure Chat_MenuSelect(aItem: Integer);
    procedure Chat_MenuShow(Sender: TObject);
  protected
    Panel_Chat: TKMPanel; //For multiplayer: Send, reply, text area for typing, etc.
      Dragger_Chat: TKMDragger;
      Image_Chat: TKMImage;
      Memo_ChatText: TKMMemo;
      Edit_ChatMsg: TKMEdit;
      Button_ChatRecipient: TKMButtonFlat;
      Image_ChatClose: TKMImage;
      Menu_Chat: TKMPopUpMenu;
  public
    constructor Create(aParent: TKMPanel);

    procedure SetChatState(const aChatState: TChatState);
    function GetChatState: TChatState;
    procedure ChatMessage(const aData: UnicodeString);

    procedure Show;
    procedure Hide;
    function Visible: Boolean;
  end;


implementation
uses KM_Main, KM_RenderUI, KM_ResTexts, KM_Game, KM_GameApp, KM_Utils,
  KM_ResSound, KM_Resource, KM_ResFonts, KM_Sound, KM_NetPlayersList;


{ TKMGUIGameChat }
constructor TKMGUIGameChat.Create(aParent: TKMPanel);
begin
  Panel_Chat := TKMPanel.Create(aParent, TOOLBAR_WIDTH, aParent.Height - MESSAGE_AREA_HEIGHT, 600, MESSAGE_AREA_HEIGHT);
  Panel_Chat.Anchors := [anLeft, anBottom];
  Panel_Chat.Hide;

    Image_Chat := TKMImage.Create(Panel_Chat, 0, 0, 600, 500, 409);
    Image_Chat.Anchors := [anLeft,anTop,anBottom];

    //Allow to resize chat area height
    Dragger_Chat := TKMDragger.Create(Panel_Chat, 45, 36, 600-130, 10);
    Dragger_Chat.Anchors := [anTop];
    Dragger_Chat.SetBounds(0, -MESSAGE_AREA_RESIZE_Y, 0, 0);
    Dragger_Chat.OnMove := Chat_Resize;

    Memo_ChatText := TKMMemo.Create(Panel_Chat,45,50,600-85,101, fnt_Arial, bsGame);
    Memo_ChatText.Anchors := [anLeft, anTop, anRight, anBottom];
    Memo_ChatText.AutoWrap := True;
    Memo_ChatText.IndentAfterNL := True; //Don't let players fake system messages
    Memo_ChatText.ScrollDown := True;

    Edit_ChatMsg := TKMEdit.Create(Panel_Chat, 75, 154, 380, 20, fnt_Arial);
    Edit_ChatMsg.Anchors := [anLeft, anRight, anBottom];
    Edit_ChatMsg.OnKeyDown := Chat_Post;
    Edit_ChatMsg.Text := '';
    Edit_ChatMsg.ShowColors := True;

    Button_ChatRecipient := TKMButtonFlat.Create(Panel_Chat,45,154,132,20,0);
    Button_ChatRecipient.Font := fnt_Grey;
    Button_ChatRecipient.CapOffsetY := -11;
    Button_ChatRecipient.OnClick := Chat_MenuShow;
    Button_ChatRecipient.Anchors := [anRight, anBottom];

    Image_ChatClose := TKMImage.Create(Panel_Chat, 600-80, 18, 32, 32, 52);
    Image_ChatClose.Anchors := [anTop, anRight];
    Image_ChatClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_ChatClose.OnClick := Chat_Close;
    Image_ChatClose.HighlightOnMouseOver := True;

    Menu_Chat := TKMPopUpMenu.Create(aParent, 120);
    Menu_Chat.Anchors := [anLeft, anBottom];
    //Menu gets populated right before show
    Menu_Chat.AddItem(NO_TEXT);
    Menu_Chat.OnClick := Chat_MenuClick;
    Chat_MenuSelect(-1); //Initialise it
end;


procedure TKMGUIGameChat.Chat_Close(Sender: TObject);
begin
  Hide;
end;


procedure TKMGUIGameChat.Chat_Post(Sender: TObject; Key: Word);
begin
  //Sending chat during reconnections at best causes messages to be lost and at worst causes
  //crashes due to intermediate connecting states. Therefore we block sending completely.
  if (Key = VK_RETURN) and (Trim(Edit_ChatMsg.Text) <> '')
  and (gGame.Networking <> nil) and not gGame.Networking.IsReconnecting
  and (GetTimeSince(fLastChatTime) >= CHAT_COOLDOWN) then
  begin
    fLastChatTime := TimeGet;
    if fChatMode = cmWhisper then
      gGame.Networking.PostChat(Edit_ChatMsg.Text, fChatMode, gGame.Networking.NetPlayers[fChatWhisperRecipient].IndexOnServer)
    else
      gGame.Networking.PostChat(Edit_ChatMsg.Text, fChatMode);
    Edit_ChatMsg.Text := '';
  end;
end;


procedure TKMGUIGameChat.Chat_Resize(Sender: TObject; X,Y: Integer);
var H: Integer;
begin
  H := EnsureRange(-Y, 0, MESSAGE_AREA_RESIZE_Y);
  Panel_Chat.Top := Panel_Chat.Parent.Height - (MESSAGE_AREA_HEIGHT + H);
  Panel_Chat.Height := MESSAGE_AREA_HEIGHT + H;
end;


procedure TKMGUIGameChat.Chat_MenuSelect(aItem: Integer);

  procedure UpdateButtonCaption(aCaption: UnicodeString; aColor: Cardinal = 0);
  const
    MIN_SIZE = 80; //Minimum size for the button
  var
    txtWidth: Word;
  begin
    //Update button width according to selected item
    txtWidth := gRes.Fonts.GetTextSize(aCaption, Button_ChatRecipient.Font).X;
    txtWidth := Max(MIN_SIZE, txtWidth + 10); //Apply minimum size

    if aColor <> 0 then
      aCaption := WrapColor(aCaption, aColor);
    Button_ChatRecipient.Caption := aCaption;
    Button_ChatRecipient.Width := txtWidth;

    Edit_ChatMsg.AbsLeft := Button_ChatRecipient.AbsLeft + Button_ChatRecipient.Width + 4;
    Edit_ChatMsg.Width := Memo_ChatText.Width - Button_ChatRecipient.Width - 4;
  end;

var
  I: Integer;
begin
  case aItem of
    -1:   begin //All
            fChatMode := cmAll;
            UpdateButtonCaption(gResTexts[TX_CHAT_ALL]);
            Edit_ChatMsg.DrawOutline := False; //No outline for All
          end;
    -2:   begin //Team
            fChatMode := cmTeam;
            UpdateButtonCaption(gResTexts[TX_CHAT_TEAM], $FF66FF66);
            Edit_ChatMsg.DrawOutline := True;
            Edit_ChatMsg.OutlineColor := $FF66FF66;
          end;
    -3:   begin //Spectators
            fChatMode := cmSpectators;
            UpdateButtonCaption(gResTexts[TX_CHAT_SPECTATORS], $FF66FF66);
            Edit_ChatMsg.DrawOutline := True;
            Edit_ChatMsg.OutlineColor := $FF66FF66;
          end;
    else  begin //Whisper to player
            I := gGame.Networking.NetPlayers.ServerToLocal(aItem);
            if I <> -1 then
            begin
              fChatMode := cmWhisper;
              Edit_ChatMsg.DrawOutline := True;
              Edit_ChatMsg.OutlineColor := $FF00B9FF;
              with gGame.Networking.NetPlayers[I] do
              begin
                fChatWhisperRecipient := I;
                UpdateButtonCaption(UnicodeString(Nikname), IfThen(FlagColorID <> 0, FlagColorToTextColor(FlagColor), 0));
              end;
            end;
          end;
    end;
end;


procedure TKMGUIGameChat.Chat_MenuClick(Sender: TObject);
begin
  if Menu_Chat.ItemIndex <> -1 then
    Chat_MenuSelect(Menu_Chat.ItemTags[Menu_Chat.ItemIndex]);
end;


procedure TKMGUIGameChat.Chat_MenuShow(Sender: TObject);
var
  C: TKMControl;
  I: Integer;
  n: TKMNetPlayerInfo;
begin
  Menu_Chat.Clear;

  //Fill lists with options to whom player can whisper
  Menu_Chat.AddItem(gResTexts[TX_CHAT_ALL], -1);

  //Only show "Team" if the player is on a team
  if gGame.Networking.NetPlayers[gGame.Networking.MyIndex].Team <> 0 then
    Menu_Chat.AddItem('[$66FF66]' + gResTexts[TX_CHAT_TEAM], -2);

  //Only show "Spectator" if the player is a spectator
  if gGame.Networking.NetPlayers[gGame.Networking.MyIndex].IsSpectator then
    Menu_Chat.AddItem('[$66FF66]' + gResTexts[TX_CHAT_SPECTATORS], -3);

  //Fill
  for I := 1 to gGame.Networking.NetPlayers.Count do
  if I <> gGame.Networking.MyIndex then //Can't whisper to self
  begin
    n := gGame.Networking.NetPlayers[I];

    if n.IsHuman and n.Connected and not n.Dropped then
      Menu_Chat.AddItem(UnicodeString(n.NiknameColored), n.IndexOnServer);
  end;

  C := TKMControl(Sender);
  //Position the menu next to the icon, but do not overlap players name
  Menu_Chat.ShowAt(C.AbsLeft, C.AbsTop - Menu_Chat.Height);
end;


//Access text that user was typing to copy it over to lobby chat
function TKMGUIGameChat.GetChatState: TChatState;
begin
  if fChatMode = cmWhisper then
    Result.WhisperRecipient := gGame.Networking.NetPlayers[fChatWhisperRecipient].IndexOnServer
  else
    Result.WhisperRecipient := 0;
  Result.Mode := fChatMode;
  Result.ChatText := Edit_ChatMsg.Text;
  Result.Messages := Memo_ChatText.Text;
end;


procedure TKMGUIGameChat.SetChatState(const aChatState: TChatState);
const CHAT_TAG: array[TChatMode] of Integer = (
  -1,  //cmAll
  -2,  //cmTeam
  -3,  //cmSpectators
  -1); //cmWhisper
begin
  if aChatState.Mode = cmWhisper then
    Chat_MenuSelect(aChatState.WhisperRecipient)
  else
    Chat_MenuSelect(CHAT_TAG[aChatState.Mode]);
  Edit_ChatMsg.Text := aChatState.ChatText;
  Memo_ChatText.Text := aChatState.Messages;
  Memo_ChatText.ScrollToBottom;
end;


procedure TKMGUIGameChat.ChatMessage(const aData: UnicodeString);
begin
  if fGameApp.GameSettings.FlashOnMessage then
    fMain.FlashingStart;

  Memo_ChatText.Add(aData);
end;


procedure TKMGUIGameChat.Show;
begin
  if not Panel_Chat.Visible then
    gSoundPlayer.Play(sfxn_MPChatOpen);

  Panel_Chat.Show;
end;


procedure TKMGUIGameChat.Hide;
begin
  if Panel_Chat.Visible then
    gSoundPlayer.Play(sfxn_MPChatClose);
  Panel_Chat.Hide;
  Menu_Chat.HideMenu;
end;


function TKMGUIGameChat.Visible: Boolean;
begin
  Result := Panel_Chat.Visible;
end;


end.
