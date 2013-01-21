unit KM_Outline;
{$I KaM_Remake.inc}
interface
uses
  Math,
  KM_CommonTypes, KM_Points, KM_PolySimplify;


  //Procedure that converts 2D Byte array into outlines
  //aMap:   Values are 0/1,
  //        Note that procedure stores internal data in same array as 255
  //aTrim:  Skip area smaller than this size in tiles (1 is buggy and misfires within obstacles)
  procedure GenerateOutline(aMap: TKMByte2Array; aTrim: Byte; out aOutlines: TKMShapesArray);


implementation


procedure GenerateOutline(aMap: TKMByte2Array; aTrim: Byte; out aOutlines: TKMShapesArray);
type
  TStepDirection = (sdNone, sdUp, sdRight, sdDown, sdLeft);
var
  PrevStep, NextStep: TStepDirection;

  procedure Step(X,Y: ShortInt);
    function IsTilePassable(aX, aY: ShortInt): Boolean;
    begin
      Result := InRange(aY, Low(aMap), High(aMap))
                and InRange(aX, Low(aMap[aY]), High(aMap[aY]))
                and (aMap[aY,aX] > 0);
      //Mark tiles we've been on, so they do not trigger new duplicate contour
      if Result then
        aMap[aY,aX] := 255; //Mark unpassable but visited
    end;
  var
    State: Byte;
  begin
    prevStep := nextStep;

    //Assemble bitmask
    State :=  Byte(IsTilePassable(X  ,Y  )) +
              Byte(IsTilePassable(X+1,Y  )) * 2 +
              Byte(IsTilePassable(X  ,Y+1)) * 4 +
              Byte(IsTilePassable(X+1,Y+1)) * 8;

    //Where do we go from here
    case State of
      1:  nextStep := sdUp;
      2:  nextStep := sdRight;
      3:  nextStep := sdRight;
      4:  nextStep := sdLeft;
      5:  nextStep := sdUp;
      6:  if (prevStep = sdUp) then
            nextStep := sdLeft
          else
            nextStep := sdRight;
      7:  nextStep := sdRight;
      8:  nextStep := sdDown;
      9:  if (prevStep = sdRight) then
            nextStep := sdUp
          else
            nextStep := sdDown;
      10: nextStep := sdDown;
      11: nextStep := sdDown;
      12: nextStep := sdLeft;
      13: nextStep := sdUp;
      14: nextStep := sdLeft;
      else nextStep := sdNone;
    end;
  end;

  procedure WalkPerimeter(aStartX, aStartY: ShortInt);
  var
    X, Y: Integer;
  begin
    X := aStartX;
    Y := aStartY;
    nextStep := sdNone;

    SetLength(aOutlines.Shape, aOutlines.Count + 1);
    aOutlines.Shape[aOutlines.Count].Count := 0;

    repeat
      Step(X, Y);

      case NextStep of
        sdUp:     Dec(Y);
        sdRight:  Inc(X);
        sdDown:   Inc(Y);
        sdLeft:   Dec(X);
        else
      end;

      //Append new node vertice
      with aOutlines.Shape[aOutlines.Count] do
      begin
        if Length(Nodes) <= Count then
          SetLength(Nodes, Count + 32);
        Nodes[Count] := KMPointI(X, Y);
        Inc(Count);
      end;
    until((X = aStartX) and (Y = aStartY));

    //Do not include too small regions
    if aOutlines.Shape[aOutlines.Count].Count >= aTrim then
      Inc(aOutlines.Count);
  end;

var
  I, K: Integer;
  C1, C2, C3, C4: Boolean;
begin
  aOutlines.Count := 0;
  for I := Low(aMap) to High(aMap) - 1 do
  for K := Low(aMap[I]) to High(aMap[I]) - 1 do
  begin
    //Find new seed among unparsed obstacles
    //C1-C2
    //C3-C4
    C1 := (aMap[I,K] = 1);
    C2 := (aMap[I,K+1] = 1);
    C3 := (aMap[I+1,K] = 1);
    C4 := (aMap[I+1,K+1] = 1);

    //Maybe skip cases where C1..C4 are all having value of 1-2
    //but I'm not sure this is going to get us any improvements
    if (C1 or C2 or C3 or C4) <> (C1 and C2 and C3 and C4) then
      WalkPerimeter(K,I);
  end;
end;


end.
