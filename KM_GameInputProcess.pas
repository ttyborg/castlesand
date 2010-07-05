unit KM_GameInputProcess;
{$I KaM_Remake.inc}
interface
uses ExtCtrls, SysUtils, Math, Types, Graphics, Controls, Forms, KromUtils, KromOGLUtils,
  {$IFDEF DELPHI} OpenGL, {$ENDIF}
  {$IFDEF FPC} GL, {$ENDIF}
  KM_Utils, KM_CommonTypes;

{ YET UNUSED, JUST AN IDEA}

{ A. This unit takes and adjoins players input from TGame and TGamePlayInterfaces clicks and keys
  Then passes it on to game events.
  E.g. there are 2 ways player can place an order to selected Warrior:
  1. Click on map
  2. Click on minimap

  B. And most important, it accumulates and feeds player input to the game.
  Thus making possible to:
   - record gameplay
   - playback replays
   - send input through LAN to make multiplayer games
  }

type
TGameInputProcess = class
  public
    constructor Create;
    procedure MouseDown(P:TKMPoint; Button: TMouseButton; Shift: TShiftState);
    procedure MouseMove(P:TKMPoint; Shift: TShiftState);
    procedure MouseUp  (P:TKMPoint; Button: TMouseButton; Shift: TShiftState);
end;



implementation
uses KM_Defaults, KM_Terrain, KM_Unit1, KM_Sound, KM_Game;


constructor TInputProcess.Create;
begin  
  Inherited;
end;


procedure MouseDown(P:TKMPoint; Button: TMouseButton; Shift: TShiftState);
begin

end;


procedure MouseMove(P:TKMPoint; Shift: TShiftState);
begin

end;


procedure MouseUp  (P:TKMPoint; Button: TMouseButton; Shift: TShiftState);
begin

end;


end.

