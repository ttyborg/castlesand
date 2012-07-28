unit KM_Alerts;
{$I KaM_Remake.inc}
interface
uses Classes, Math, SysUtils,
  KM_Defaults, KM_Pics, KM_Points, KM_Sound, KM_Viewport;


type
  TAlertType = (atBeacon, atFight);

  TKMAlert = class
  private
    fAlertType: TAlertType;
    fExpiration: Cardinal;
    fLoc: TKMPointF;
    fOwner: TPlayerIndex;
  protected
    function GetTexMinimap: TKMPic; virtual; abstract;
    function GetTexMinimapOffset: TKMPointI; virtual; abstract;
    function GetTexTerrain: TKMPic; virtual; abstract;
    function GetTeamColor: Cardinal; virtual; abstract;
    function GetVisibleMinimap: Boolean; virtual; abstract;
    function GetVisibleTerrain: Boolean; virtual; abstract;
  public
    constructor Create(aAlertType: TAlertType; aLoc: TKMPointF; aOwner: TPlayerIndex; aTick: Cardinal);

    property AlertType: TAlertType read fAlertType;
    property Loc: TKMPointF read fLoc;
    property Owner: TPlayerIndex read fOwner;
    property TexMinimap: TKMPic read GetTexMinimap;
    property TexMinimapOffset: TKMPointI read GetTexMinimapOffset;
    property TexTerrain: TKMPic read GetTexTerrain;
    property TeamColor: Cardinal read GetTeamColor;
    property VisibleMinimap: Boolean read GetVisibleMinimap;
    property VisibleTerrain: Boolean read GetVisibleTerrain;

    function IsExpired(aTick: Cardinal): Boolean;
    procedure Update(const aView: TKMRect); virtual;
  end;

  //Alerts are signals in game that draw Players attention to something,
  //Unlike simple messages that are fired-and-forget, alerts do have a lifespan
  //and some interaction with e.g. Viewport
  //Alerts are not saved between game sessions because by nature they are short
  //lived and last only a few seconds
  TKMAlerts = class
  private
    fTickCounter: PCardinal;
    fViewport: TViewport;
    fList: TList;
    function GetAlert(aIndex: Integer): TKMAlert;
    function GetCount: Integer;
  public
    constructor Create(aTickCounter: PCardinal; aViewport: TViewport);
    destructor Destroy; override;
    procedure AddBeacon(aLoc: TKMPointF; aOwner: TPlayerIndex);
    procedure AddFight(aLoc: TKMPointF; aPlayer: TPlayerIndex; aAsset: TAttackNotification);
    property Count: Integer read GetCount;
    property Items[aIndex: Integer]: TKMAlert read GetAlert; default;
    procedure Paint;
    procedure UpdateState;
  end;


implementation
uses KM_PlayersCollection, KM_RenderPool;


type
  //These classes are only accessed locally, hence they aren't interfaced
  TKMAlertBeacon = class(TKMAlert)
  protected
    function GetTexMinimap: TKMPic; override;
    function GetTexMinimapOffset: TKMPointI; override;
    function GetTexTerrain: TKMPic; override;
    function GetTeamColor: Cardinal; override;
    function GetVisibleMinimap: Boolean; override;
    function GetVisibleTerrain: Boolean; override;
  public
    constructor Create(aLoc: TKMPointF; aOwner: TPlayerIndex; aTick: Cardinal);
  end;

  TKMAlertAttacked = class(TKMAlert)
  private
    fAsset: TAttackNotification; //What was attacked?
    fLastLookedAt: Byte;
  protected
    function GetTexMinimap: TKMPic; override;
    function GetTexMinimapOffset: TKMPointI; override;
    function GetTexTerrain: TKMPic; override;
    function GetTeamColor: Cardinal; override;
    function GetVisibleMinimap: Boolean; override;
    function GetVisibleTerrain: Boolean; override;
  public
    constructor Create(aLoc: TKMPointF; aOwner: TPlayerIndex; aAsset: TAttackNotification; aTick: Cardinal);
    property Asset: TAttackNotification read fAsset;
    procedure Refresh(aTick: Cardinal);
    procedure Update(const aView: TKMRect); override;
  end;


const
  ALERT_DURATION: array [TAlertType] of Byte = (80, 60); //Typical beacon duration after which it will be gone
  FIGHT_DISTANCE = 24; //Fights this far apart are treated as separate
  INTERVAL_ATTACKED_MSG = 20; //Time between audio messages saying you are being attacked
  MAX_BEACONS = 5; //Maximum number of simultanious beacons per player


{ TKMAlert }
constructor TKMAlert.Create(aAlertType: TAlertType; aLoc: TKMPointF; aOwner: TPlayerIndex; aTick: Cardinal);
begin
  inherited Create;

  fAlertType := aAlertType;
  fLoc := aLoc;
  fOwner := aOwner;
  fExpiration := aTick + ALERT_DURATION[fAlertType];
end;


function TKMAlert.IsExpired(aTick: Cardinal): Boolean;
begin
  Result := aTick >= fExpiration;
end;


procedure TKMAlert.Update(const aView: TKMRect);
begin
  //
end;


{ TKMAlertBeacon }
constructor TKMAlertBeacon.Create(aLoc: TKMPointF; aOwner: TPlayerIndex; aTick: Cardinal);
begin
  inherited Create(atBeacon, aLoc, aOwner, aTick);
end;


function TKMAlertBeacon.GetTexMinimap: TKMPic;
begin
  Result.RX := rxGui;
  Result.ID := 54;
end;


function TKMAlertBeacon.GetTexMinimapOffset: TKMPointI;
begin
  Result := KMPointI(-4,-9);
end;


function TKMAlertBeacon.GetTexTerrain: TKMPic;
begin
  Result.RX := rxGui;
  Result.ID := 250; //Located near the house tablets so we can include it in soft shadows range
end;


function TKMAlertBeacon.GetTeamColor: Cardinal;
begin
  Result := fPlayers[fOwner].FlagColor;
end;


function TKMAlertBeacon.GetVisibleMinimap: Boolean;
begin
  //Beacons placed by player are always visible until expired
  Result := True;
end;


function TKMAlertBeacon.GetVisibleTerrain: Boolean;
begin
  Result := True;
end;


{ TKMAlertFight }
constructor TKMAlertAttacked.Create(aLoc: TKMPointF; aOwner: TPlayerIndex; aAsset: TAttackNotification; aTick: Cardinal);
begin
  inherited Create(atFight, aLoc, aOwner, aTick);

  fAsset := aAsset;
  fLastLookedAt := High(Byte) - 1;
end;


function TKMAlertAttacked.GetTexMinimap: TKMPic;
begin
  Result.RX := rxGui;
  Result.ID := 53;
end;


function TKMAlertAttacked.GetTexMinimapOffset: TKMPointI;
begin
  Result := KMPointI(-11,-7);
end;


function TKMAlertAttacked.GetTexTerrain: TKMPic;
begin
  //Has no sprite on terrain
  Result.RX := rxTrees;
  Result.ID := 0;
end;


function TKMAlertAttacked.GetTeamColor: Cardinal;
begin
  Result := fPlayers[fOwner].FlagColor;
end;


function TKMAlertAttacked.GetVisibleMinimap: Boolean;
begin
  //UnderAttack alerts are visible only when not looked at
  //When looked at alert is muted for the next 20sec
  Result := fLastLookedAt >= INTERVAL_ATTACKED_MSG;
end;


function TKMAlertAttacked.GetVisibleTerrain: Boolean;
begin
  Result := False;
end;


procedure TKMAlertAttacked.Refresh(aTick: Cardinal);
begin
  fExpiration := aTick + ALERT_DURATION[fAlertType];
end;


procedure TKMAlertAttacked.Update(const aView: TKMRect);
begin
  inherited;

  //If alerts gets into view - mute it.
  //Alert will be unmuted when going out of view
  if KMInRect(fLoc, aView) then
    fLastLookedAt := 0
  else
  begin
    Inc(fLastLookedAt);

    //Alert is automatically repeated
    if fLastLookedAt >= INTERVAL_ATTACKED_MSG * 2 then
      fLastLookedAt := INTERVAL_ATTACKED_MSG;

    //Make the sound
    if (fOwner = MyPlayer.PlayerIndex)
    and (fLastLookedAt = INTERVAL_ATTACKED_MSG) then
      fSoundLib.PlayNotification(fAsset);
  end;
end;


{ TKMAlerts }
constructor TKMAlerts.Create(aTickCounter: PCardinal; aViewport: TViewport);
begin
  inherited Create;

  fTickCounter := aTickCounter;
  fViewport := aViewport;
  fList := TList.Create;
end;


destructor TKMAlerts.Destroy;
var
  I: Integer;
begin
  for I := 0 to fList.Count - 1 do
    Items[I].Free;

  fList.Free;
  inherited;
end;


function TKMAlerts.GetAlert(aIndex: Integer): TKMAlert;
begin
  Result := fList[aIndex];
end;


function TKMAlerts.GetCount: Integer;
begin
  Result := fList.Count;
end;


//Ally has placed a beacon for ue
procedure TKMAlerts.AddBeacon(aLoc: TKMPointF; aOwner: TPlayerIndex);
  procedure RemoveExcessBeacons;
  var I, OldestID, OldestExpiry, Count: Integer;
  begin
    Count := 0;
    OldestID := -1;
    OldestExpiry := 0;
    for I := 0 to fList.Count - 1 do
      if (Items[I].AlertType = atBeacon)
      and (Items[I].Owner = aOwner) then
      begin
        Inc(Count);
        if (OldestID = -1) or (Items[I].fExpiration < OldestExpiry) then
        begin
          OldestExpiry := Items[I].fExpiration;
          OldestID := I;
        end;
      end;
    if (Count > MAX_BEACONS) and (OldestID <> -1) then
      fList.Delete(OldestID);
  end;

begin
  //If this player has too many beacons remove his oldest one
  RemoveExcessBeacons;

  fList.Add(TKMAlertBeacon.Create(aLoc, aOwner, fTickCounter^));
end;


//Player belongings signal that they are under attack
procedure TKMAlerts.AddFight(aLoc: TKMPointF; aPlayer: TPlayerIndex; aAsset: TAttackNotification);
var
  I: Integer;
begin
  //Check previous alerts and see if there's one like that already
  for I := 0 to fList.Count - 1 do
    if Items[I] is TKMAlertAttacked then
      with TKMAlertAttacked(Items[I]) do
        if (Owner = aPlayer) and (Asset = aAsset)
        and (GetLength(Loc, aLoc) < FIGHT_DISTANCE) then
        begin
          Refresh(fTickCounter^);
          Exit;
        end;

  //Otherwise create a new alert
  fList.Add(TKMAlertAttacked.Create(aLoc, aPlayer, aAsset, fTickCounter^));
end;


procedure TKMAlerts.Paint;
var
  I: Integer;
  R: TKMRect;
begin
  R := KMRectGrow(fViewport.GetMinimapClip, 4); //Beacons may stick up over a few tiles

  for I := 0 to fList.Count - 1 do
    if Items[I].VisibleTerrain
    and KMInRect(Items[I].Loc, R) then
      fRenderPool.AddAlert(Items[I].Loc, Items[I].TexTerrain.ID, fPlayers[Items[I].Owner].FlagColor);
end;


procedure TKMAlerts.UpdateState;
var
  I: Integer;
begin
  //Update alerts visibility
  if (fTickCounter^ mod 10 = 0) then
  for I := fList.Count - 1 downto 0 do
    Items[I].Update(fViewport.GetMinimapClip);

  //Remove expired alerts
  for I := fList.Count - 1 downto 0 do
    if Items[I].IsExpired(fTickCounter^) then
    begin
      Items[I].Free;
      fList.Delete(I);
    end;
end;


end.
