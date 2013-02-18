unit KM_PathFindingAStarNew;
{$I KaM_Remake.inc}
interface
uses SysUtils, Math, KromUtils, KM_PathFinding,
  KM_CommonClasses, KM_Defaults, KM_Terrain, KM_Points, BinaryHeap;


{$DEFINE USEDNODES} //Optimize array reset

type
  TANode = class
             X,Y: SmallInt;
             CostTo: Word;
             Estim: Word;
             Parent: TANode;
           end;

  //This is a helper class for TTerrain
  //Here should be pathfinding and all associated stuff
  //I think we should refactor this unit and move some TTerrain methods here
  TPathFindingAStarNew = class(TPathFinding)
  private
    fHeap: TBinaryHeap;
    fMinN: TANode;
    fOpenRef: array of array of TANode; //References to OpenList, Sized as map
    {$IFDEF USEDNODES}
    fUsedNodes: array of TANode; //Used to make Reset more efficient
    fUsedNodeCount: Integer;
    {$ENDIF}
    function HeapCmp(A,B: Pointer): Boolean;
    function GetNodeAt(X,Y: SmallInt): TANode;
    procedure Reset;
  protected
    function MakeRoute: Boolean; override;
    procedure ReturnRoute(NodeList: TKMPointList); override;
  public
    constructor Create;
    destructor Destroy; override;
  end;


implementation


{ TPathFindingAStarNew }
constructor TPathFindingAStarNew.Create;
begin
  inherited;

  fHeap := TBinaryHeap.Create(High(Word));
  fHeap.Cmp := HeapCmp;
end;


destructor TPathFindingAStarNew.Destroy;
begin
  Reset;
  fHeap.Free;

  inherited;
end;


function TPathFindingAStarNew.HeapCmp(A, B: Pointer): Boolean;
begin
  if A = nil then
    Result := True
  else
    Result := (B = nil) or (TANode(A).Estim + TANode(A).CostTo < TANode(B).Estim + TANode(B).CostTo);
end;


function TPathFindingAStarNew.GetNodeAt(X,Y: SmallInt): TANode;
begin
  //Cell is new
  if fOpenRef[Y,X] = nil then
  begin
    fOpenRef[Y,X] := TANode.Create;
    fOpenRef[Y,X].X := X;
    fOpenRef[Y,X].Y := Y;

    {$IFDEF USEDNODES}
    if Length(fUsedNodes) <= fUsedNodeCount then
      SetLength(fUsedNodes, fUsedNodeCount+64);

    fUsedNodes[fUsedNodeCount] := fOpenRef[Y,X];
    Inc(fUsedNodeCount);
    {$ENDIF}
  end;

  Result := fOpenRef[Y,X];
end;


procedure TPathFindingAStarNew.Reset;
var
  I,K: Integer;
begin
  {$IFNDEF USEDNODES}
  for I := 0 to High(fOpenRef) do
  for K := 0 to High(fOpenRef[I]) do
  if fOpenRef[I,K] <> nil then
  begin
    fOpenRef[I,K].Free;
    fOpenRef[I,K] := nil;
  end;
  {$ENDIF}

  {$IFDEF USEDNODES}
  //Reverse seems to work ~10% faster (cos of cache access probably)
  for I := fUsedNodeCount - 1 downto 0 do
  begin
    fOpenRef[fUsedNodes[I].Y, fUsedNodes[I].X] := nil;
    fUsedNodes[I].Free;
  end;

  fUsedNodeCount := 0;
  {$ENDIF}

  //Tested having a second list that stores only used ORef cells, it's slower
  //@Krom: Did you do it the way I've done it? I get 10-40% performance improvement in path finder util (maybe I didn't test thoroughly enough)
  //@Lewin: I retested with your code and I get 20-60% boost now.
  //        Must be my bad at testing when I overlooked something ..
  //        I tested with TKMPoint, maybe that made the diff. To be deleted ..
end;


function TPathFindingAStarNew.MakeRoute: Boolean;
const c_closed = 65535;
var
  N: TANode;
  X, Y: Word;
  NewCost: Word;
begin
  //Clear previous data
  Reset;

  //Check that fOpenRef has been initialised (running SetLength when it's already correct size
  //is inefficient with such a large array, SetLength doesn't seem to test for that condition
  //because the CPU debugger runs through all of SetLength anyway on both dimensions)
  if (Length(fOpenRef) <> fTerrain.MapY+1) or (Length(fOpenRef[0]) <> fTerrain.MapX+1) then
    SetLength(fOpenRef, fTerrain.MapY+1, fTerrain.MapX+1);

  //Initialize first element
  N := GetNodeAt(fLocA.X, fLocA.Y);
  N.Estim := (Abs(fLocB.X - fLocA.X) + Abs(fLocB.Y - fLocA.Y)) * 10;
  N.Parent  := nil;

  //Seed
  fMinN := N;

  while (fMinN <> nil) and not DestinationReached(fMinN.X, fMinN.Y) do
  begin

    fMinN.Estim := c_closed;

    //Check all surrounding cells and issue costs to them
    for Y := Math.max(fMinN.Y-1,1) to Math.min(fMinN.Y+1, fTerrain.MapY-1) do
    for X := Math.max(fMinN.X-1,1) to Math.min(fMinN.X+1, fTerrain.MapX-1) do
    if fOpenRef[Y,X] = nil then //Cell is new
    begin
      if CanWalkTo(KMPoint(fMinN.X, fMinN.Y), X, Y) then
      begin

        N := GetNodeAt(X, Y);
        N.Parent := fMinN;

        if IsWalkableTile(X, Y) then
        begin
          N.CostTo := fMinN.CostTo + MovementCost(fMinN.X, fMinN.Y, X, Y);
          N.Estim := (Abs(X - fLocB.X) + Abs(Y - fLocB.Y)) * 10; //Use Estim even if destination is Passability, as it will make it faster. Target should be in the right direction even though it's not our destination.
          fHeap.Push(N);
        end
        else //If cell doen't meets Passability then mark it as Closed
          N.Estim := c_closed;

      end;
    end
    else //Else cell is old
    begin

      //If route through new cell is shorter than ORef[Y,X] then
      if fOpenRef[Y,X].Estim <> c_closed then
      if CanWalkTo(KMPoint(fMinN.X, fMinN.Y), X, Y) then
      begin
        NewCost := MovementCost(fMinN.X, fMinN.Y, X, Y);
        if fMinN.CostTo + NewCost < fOpenRef[Y,X].CostTo then
        begin
          fOpenRef[Y,X].Parent := fMinN;
          fOpenRef[Y,X].CostTo := fMinN.CostTo + NewCost;
        end;
      end;
    end;

    //Find next cell with least (Estim+CostTo)
    if fHeap.IsEmpty then
      Break;

    fMinN := fHeap.Pop;
  end;

  //Route found, no longer need the lookups
  fHeap.Clear;

  Result := DestinationReached(fMinN.X, fMinN.Y);
end;


procedure TPathFindingAStarNew.ReturnRoute(NodeList: TKMPointList);
var
  N: TANode;
begin
  NodeList.Clear;

  //Assemble the route
  N := fMinN;
  while N <> nil do
  begin
    NodeList.AddEntry(KMPoint(N.X, N.Y));
    N := N.Parent;
  end;

  //Reverse the list, since path is assembled LocB > LocA
  NodeList.Inverse;

  //Cache long paths
  if CACHE_PATHFINDING and (NodeList.Count > 20) then
    AddToCache(NodeList);
end;


end.
