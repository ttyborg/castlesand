unit KM_CommonTypes;
{$I KaM_Remake.inc}
interface


type
  TCardinalArray = array of Cardinal;
  TRGBArray = array of record R,G,B: Byte end;

  TEvent = procedure of object;
  TPointEvent = procedure (Sender:TObject; const X,Y: integer) of object;
  TIntegerEvent = procedure (aValue: Integer) of object;
  TStringEvent = procedure (const aData: string) of object;
  TResyncEvent = procedure (aSender:Integer; aTick: cardinal) of object;
  TIntegerStringEvent = procedure (aValue: Integer; const aText: string) of object;

  TKMAnimLoop = packed record
                  Step: array [1 .. 30] of SmallInt;
                  Count: SmallInt;
                  MoveX, MoveY: Integer;
                end;


implementation


end.
