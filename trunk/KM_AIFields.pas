unit KM_AIFields;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils, Graphics, Delaunay,
  KM_CommonClasses, KM_CommonTypes, KM_Terrain, KM_Defaults, KM_Player, KM_Utils, KM_Points, KM_PolySimplify;

type
  TKMWeightSegments = array of record
    A,B: TKMPoint;
    Weight: Single;
  end;

  //Strcucture to describe NavMesh layout
  TKMNavMesh = class
  private
    fNodeCount: Integer;
    fPolyCount: Integer;
    fNodes: array of record
      Loc: TKMPoint;
      Nearby: array of Word;
      Owner: array [0..MAX_PLAYERS-1] of Byte;
    end;
    //Edges: array of array [0..1] of Word;
    fPolygons: array of record
      Indices: array [0..2] of Word;
      //Nearby: array of Word; //Neighbour polygons
    end;
    procedure InitConnectivity;
    function GetBestOwner(aIndex: Integer): TPlayerIndex;
    function GetEnemyPresence(aIndex: Integer; aOwner: TPlayerIndex): Word;
    procedure UpdateOwnership;
  public
    procedure AssignMesh(const aTriMesh: TKMTriMesh);
    procedure GetDefenceOutline(aOwner: TPlayerIndex; out aOutline: TKMWeightSegments);
    function EnemyPresence(aLoc: TKMpoint): Word;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint(aRect: TKMRect);
  end;

  TKMInfluences = class
  private
    fMapX, fMapY: Word;

    procedure InitInfluenceAvoid;
    procedure InitInfluenceForest;
    procedure UpdateInfluenceMaps;
  public
    //Common map of areas where building is undesired (around Store, Mines, Woodcutters)
    AvoidBuilding: array of array of Byte;
    //Areas of forests, needed only for initial Woodcutters placement and gets calculated once on mission start
    Forest: array of array of Word;

    Influence: array of array of array of Byte;
    Ownership: array of array of array of SmallInt;
    //Tension: array of array of array of SmallInt;

    procedure AddAvoidBuilding(X,Y: Word; aRad: Byte);
    function GetBestOwner(X, Y: Word): TPlayerIndex;
    procedure Init;
    procedure ExportInfluenceMaps;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint(aRect: TKMRect);
  end;


  //Influence maps, navmeshes, etc
  TKMAIFields = class
  private
    fRawOutlines: TKMShapesArray;
    fSimpleOutlines: TKMShapesArray;
    fRawMesh: TKMTriMesh;

    fNavMesh: TKMNavMesh;
    fInfluences: TKMInfluences;

    procedure InitNavMesh;
  public
    constructor Create;
    destructor Destroy; override;

    property NavMesh: TKMNavMesh read fNavMesh;
    property Influences: TKMInfluences read fInfluences;

    procedure AfterMissionInit;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint(aRect: TKMRect);
  end;


var
  fAIFields: TKMAIFields;


implementation
uses KM_PlayersCollection, KM_RenderAux, KM_Houses;


const
  //Decay affects how much space AI needs to be able to expand
  //Values smaller than 3 start to block green AI on AcrossDesert too fast
  INFLUENCE_DECAY = 2;

  //Should be within 16 tiles and at least one corner within 8 tiles
  OWN_MARGIN = 160;
  OWN_THRESHOLD = 128;


{ TKMNavMesh }
procedure TKMNavMesh.AssignMesh(const aTriMesh: TKMTriMesh);
var
  I: Integer;
begin
  fNodeCount := Length(aTriMesh.Vertices);
  fPolyCount := Length(aTriMesh.Polygons);

  //Bring triangulated mesh back
  SetLength(fNodes, fNodeCount);
  for I := 0 to fNodeCount - 1 do
    fNodes[I].Loc := KMPoint(aTriMesh.Vertices[I]);

  SetLength(fPolygons, fPolyCount);
  for I := 0 to fPolyCount - 1 do
  begin
    fPolygons[I].Indices[0] := aTriMesh.Polygons[I,0];
    fPolygons[I].Indices[1] := aTriMesh.Polygons[I,1];
    fPolygons[I].Indices[2] := aTriMesh.Polygons[I,2];
  end;

  InitConnectivity;
end;


procedure TKMNavMesh.InitConnectivity;
  procedure DoConnectNodes(I, N1, N2: Word);
  begin
    with fNodes[I] do
    begin
      SetLength(Nearby, Length(Nearby) + 2);
      Nearby[High(Nearby)-1] := N1;
      Nearby[High(Nearby)] := N2;
    end;
  end;
  {procedure DoConnectPolys(aPoly, N1, N2, N3: Word);
  var
    I: Integer;
  begin
    for I := 0 to fPolyCount - 1 do
    with fPolygons[I] do
    if (I <> aPoly)
    and ((Indices[0] = N1) or (Indices[0] = N2) or (Indices[0] = N3)
      or (Indices[0] = N1) or (Indices[0] = N2) or (Indices[0] = N3)
      or (Indices[0] = N1) or (Indices[0] = N2) or (Indices[0] = N3))
    then
    begin
      SetLength(Nearby, Length(Nearby) + 1);
      Nearby[High(Nearby)] := aPoly;
    end;
  end;}
var I: Integer;
begin
  //Set nodes nearbies to fill influence field
  for I := 0 to fPolyCount - 1 do
  with fPolygons[I] do
  begin
    DoConnectNodes(Indices[0], Indices[1], Indices[2]);
    DoConnectNodes(Indices[1], Indices[0], Indices[2]);
    DoConnectNodes(Indices[2], Indices[0], Indices[1]);
  end;

  //Set polys connectivity to be able to expand
  {for I := 0 to fPolyCount - 1 do
  with fPolygons[I] do
    DoConnectPolys(I, Indices[0], Indices[1], Indices[2]);}
end;


function TKMNavMesh.GetBestOwner(aIndex: Integer): TPlayerIndex;
var
  I: Integer;
  Best: Byte;
begin
  Best := 0;
  Result := PLAYER_NONE;
  for I := 0 to fPlayers.Count - 1 do
  if fNodes[aIndex].Owner[I] > Best then
  begin
    Best := fNodes[aIndex].Owner[I];
    Result := I;
  end;
end;


function TKMNavMesh.GetEnemyPresence(aIndex: Integer; aOwner: TPlayerIndex): Word;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fPlayers.Count - 1 do
  if (I <> aOwner) and (fPlayers.CheckAlliance(aOwner, I) = at_Enemy) then
    Result := Result + fNodes[aIndex].Owner[I];
end;


function TKMNavMesh.EnemyPresence(aLoc: TKMpoint): Word;
begin
  //
end;


procedure TKMNavMesh.GetDefenceOutline(aOwner: TPlayerIndex; out aOutline: TKMWeightSegments);
var
  I, K: Integer;
  ECount: Integer;
  Edges: array of array [0..1] of Integer;
begin
  //1. Get ownership area
  //Collect edges of polys that are well within our ownership area
  ECount := 0;
  for I := 0 to fPolyCount - 1 do
  with fPolygons[I] do
  if ((fNodes[Indices[0]].Owner[aOwner] >= OWN_MARGIN)
    or (fNodes[Indices[1]].Owner[aOwner] >= OWN_MARGIN)
    or (fNodes[Indices[2]].Owner[aOwner] >= OWN_MARGIN))
  and (fNodes[Indices[0]].Owner[aOwner] >= OWN_THRESHOLD)
  and (fNodes[Indices[1]].Owner[aOwner] >= OWN_THRESHOLD)
  and (fNodes[Indices[2]].Owner[aOwner] >= OWN_THRESHOLD)
  and (GetBestOwner(Indices[0]) = aOwner)
  and (GetBestOwner(Indices[1]) = aOwner)
  and (GetBestOwner(Indices[2]) = aOwner) then
  begin
    SetLength(Edges, ECount + 3);
    Edges[ECount  , 0] := Indices[0];
    Edges[ECount  , 1] := Indices[1];
    Edges[ECount+1, 0] := Indices[1];
    Edges[ECount+1, 1] := Indices[2];
    Edges[ECount+2, 0] := Indices[2];
    Edges[ECount+2, 1] := Indices[0];
    Inc(ECount, 3);
  end;

  //2. Obtain suboptimal outline
  //Remove duplicate edges, that will leave us with an outline
  for I := 0 to ECount - 1 do
  if (Edges[I, 0] > -1) and (Edges[I, 1] > -1) then
  for K := I + 1 to ECount - 1 do
  if (Edges[K, 0] > -1) and (Edges[K, 1] > -1) then
  if (Edges[I, 0] = Edges[K, 1]) and (Edges[I, 1] = Edges[K, 0]) then
  begin
    Edges[I, 0] := -1;
    Edges[I, 1] := -1;
    Edges[K, 0] := -1;
    Edges[K, 1] := -1;
  end;

  //3. Detect and dismiss inner edges
  //Separate edges into open (having 2 polys) and closed (only 1 poly)
  //Once again we take advantage of the fact that polys built in CW order
  for I := 0 to fPolyCount - 1 do
  with fPolygons[I] do
  for K := 0 to ECount - 1 do
  if (Edges[K, 0] <> -1) then
  if ((Edges[K, 0] = Indices[1]) and (Edges[K, 1] = Indices[0]))
  or ((Edges[K, 0] = Indices[2]) and (Edges[K, 1] = Indices[1]))
  or ((Edges[K, 0] = Indices[0]) and (Edges[K, 1] = Indices[2])) then
  begin
    //Mark outer edges
    Edges[K, 0] := -1000 - Edges[K, 0];
    Edges[K, 1] := -1000 - Edges[K, 1];
  end;
  K := 0;
  for I := 0 to ECount - 1 do
  if (Edges[I, 0] >= 0) then
  begin //Dismiss inner edges
    Edges[I, 0] := -1;
    Edges[I, 1] := -1;
  end
  else
  if (Edges[I, 0] < -1) then
  begin //Promote marked outer edges back
    Edges[I, 0] := -Edges[I, 0] - 1000;
    Edges[I, 1] := -Edges[I, 1] - 1000;
    Inc(K);
  end;

  //4. Now we can assemble suboptimal outline from kept edges
  SetLength(aOutline, K);
  K := 0;
  for I := 0 to ECount - 1 do
  if (Edges[I, 0] >= 0) then
  begin
    aOutline[K].A := fNodes[Edges[I,0]].Loc;
    aOutline[K].B := fNodes[Edges[I,1]].Loc;
    aOutline[K].Weight := GetEnemyPresence(Edges[I,0], aOwner) + GetEnemyPresence(Edges[I,1], aOwner);
    Inc(K);
  end;

  //5. Remove spans that face isolated areas

  //6. See if we can expand our area while reducing outline length

  //7. Deal with allies
  //   Two players could be on same island and share defence lines,
  //   also they dont need defence line between them
end;


procedure TKMNavMesh.UpdateOwnership;
var
  I, K: Integer;
begin
  if not AI_GEN_NAVMESH then Exit;

  for I := 0 to fNodeCount - 1 do
    for K := 0 to fPlayers.Count - 1 do
      fNodes[I].Owner[K] := Min(255, Max(
        Max(fAIFields.Influences.Ownership[K, Max(fNodes[I].Loc.Y, 1), Max(fNodes[I].Loc.X, 1)],
            fAIFields.Influences.Ownership[K, Max(fNodes[I].Loc.Y, 1), Min(fNodes[I].Loc.X+1, fTerrain.MapX - 1)]),
        Max(fAIFields.Influences.Ownership[K, Min(fNodes[I].Loc.Y+1, fTerrain.MapY - 1), Max(fNodes[I].Loc.X, 1)],
            fAIFields.Influences.Ownership[K, Min(fNodes[I].Loc.Y+1, fTerrain.MapY - 1), Min(fNodes[I].Loc.X+1, fTerrain.MapX - 1)])
            ));
end;


procedure TKMNavMesh.UpdateState(aTick: Cardinal);
begin
  //Maybe we recalculate Influences or navmesh sectors once in a while

  if (aTick mod 60 = 0) then
  begin
    UpdateOwnership;
  end;
end;


//Render debug symbols
procedure TKMNavMesh.Paint(aRect: TKMRect);
var
  I, K, J: Integer;
  T1, T2: TKMPointF;
  Col, Col2: Cardinal;
  Sz: Single;
  Outline: TKMWeightSegments;
begin
  if not AI_GEN_NAVMESH then Exit;

  //NavMesh polys coverage
  if OVERLAY_NAVMESH then
    for I := 0 to fPolyCount - 1 do
      fRenderAux.Triangle(
        fNodes[fPolygons[I].Indices[0]].Loc.X,
        fNodes[fPolygons[I].Indices[0]].Loc.Y,
        fNodes[fPolygons[I].Indices[1]].Loc.X,
        fNodes[fPolygons[I].Indices[1]].Loc.Y,
        fNodes[fPolygons[I].Indices[2]].Loc.X,
        fNodes[fPolygons[I].Indices[2]].Loc.Y, $60FF0000);

  //NavMesh edges
  if OVERLAY_NAVMESH then
    for I := 0 to fPolyCount - 1 do
    with fPolygons[I] do
    for K := 0 to 2 do
    begin
      T1 := KMPointF(fNodes[Indices[K]].Loc);
      J := (K + 1) mod 2;
      T2 := KMPointF(fNodes[Indices[J]].Loc);
      fRenderAux.Line(T1, T2, $FFFF8000, $F0F0);
    end;

  //NavMesh vertice ids
  {if OVERLAY_NAVMESH then
    for I := 0 to High(fVertices) do
      fRenderAux.Text(fVertices[I].X,fVertices[I].Y, IntToStr(I), $FF000000); //}

  {//Simplified obstacle outlines
  if OVERLAY_NAVMESH then
    for I := 0 to fSimpleOutlines.Count - 1 do
    for K := 0 to fSimpleOutlines.Shape[I].Count - 1 do
    with fSimpleOutlines.Shape[I] do
      fRenderAux.Line(Nodes[K], Nodes[(K + 1) mod Count], $FF00FF00, $FF00);//}

  //NavMesh influences
  if OVERLAY_NAVMESH then
    for I := 0 to fNodeCount - 1 do
    begin
      K := GetBestOwner(I);
      if K <> PLAYER_NONE then
      begin
        Col := fPlayers[K].FlagColor or $FF000000;
        Col2 := IfThen(fNodes[I].Owner[K] = 255, $FFFFFFFF);
        Sz := Max(fNodes[I].Owner[K] - 128, 0) / 64;

        fRenderAux.CircleOnTerrain(
          fNodes[I].Loc.X,
          fNodes[I].Loc.Y, Sz, Col, Col2);
      end;
    end;

  //Defence outlines
  if OVERLAY_NAVMESH then
    for I := 0 to fPlayers.Count - 1 do
    begin
      GetDefenceOutline(I, Outline);
      for K := 0 to High(Outline) do
      begin
        fRenderAux.Line(Outline[K].A, Outline[K].B, $FF00F0F0);
        T1 := KMPointF(Outline[K].A);
        T2 := KMPerpendecular(Outline[K].A, Outline[K].B);
        fRenderAux.Line(T1, T2, $FF00F0F0);
      end;
    end;
end;


{ TKMInfluenceMaps }
//Make the area around to be avoided by common houses
procedure TKMInfluences.AddAvoidBuilding(X,Y: Word; aRad: Byte);
var I,K: Integer;
begin
  for I := Max(Y - aRad, 1) to Min(Y + aRad, fTerrain.MapY - 1) do
  for K := Max(X - aRad, 1) to Min(X + aRad, fTerrain.MapX - 1) do
    if Sqr(X-K) + Sqr(Y-I) <= Sqr(aRAD) then
      AvoidBuilding[I,K] := 255;
end;




//Return index of player who has most influence on this tile, or none
function TKMInfluences.GetBestOwner(X, Y: Word): TPlayerIndex;
var
  I: Integer;
  Best: Integer;
begin
  Best := 0;
  Result := PLAYER_NONE;
  for I := 0 to fPlayers.Count - 1 do
  if Ownership[I,Y,X] > Best then
  begin
    Best := Ownership[I,Y,X];
    Result := I;
  end;
end;


procedure TKMInfluences.Init;
begin
  fMapX := fTerrain.MapX;
  fMapY := fTerrain.MapY;
  SetLength(AvoidBuilding, fMapY, fMapX);
  SetLength(Forest, fMapY, fMapX);
  SetLength(Influence, fPlayers.Count, fMapY, fMapX);
  SetLength(Ownership, fPlayers.Count, fMapY, fMapX);
  InitInfluenceAvoid;
  InitInfluenceForest;
  UpdateInfluenceMaps;
end;


//AI should avoid certain areas, keeping them for special houses
procedure TKMInfluences.InitInfluenceAvoid;
var
  S: TKMHouse;
  I, K, J: Integer;
  Bmp: TBitmap;
  M: Integer;
  N: Integer;
begin
  //Avoid areas where Gold/Iron mines should be
  for I := 1 to fTerrain.MapY - 1 do
  for K := 1 to fTerrain.MapX - 1 do
  if (fTerrain.TileIsIron(K, I) > 1) or (fTerrain.TileIsGold(K, I) > 1) then
    for M := I to Min(I + 2, fTerrain.MapY - 1) do
    for N := Max(K - 1, 1) to Min(K + 1, fTerrain.MapX - 1) do
      AvoidBuilding[M, N] := 255;

  //Avoid Coal fields
  for I := 1 to fTerrain.MapY - 1 do
  for K := 1 to fTerrain.MapX - 1 do
   AvoidBuilding[I,K] := AvoidBuilding[I,K] or (Byte(fTerrain.TileIsCoal(K, I) > 1) * $FF);

  //Leave free space around all players Stores
  for J := 0 to fPlayers.Count - 1 do
  begin
    S := fPlayers[J].FindHouse(ht_Store);
    if S <> nil then
    for I := Max(S.GetEntrance.Y - 4, 1) to Min(S.GetEntrance.Y + 3, fTerrain.MapY - 1) do
    for K := Max(S.GetEntrance.X - 3, 1) to Min(S.GetEntrance.X + 3, fTerrain.MapX - 1) do
      AvoidBuilding[I,K] := AvoidBuilding[I,K] or $FF;
  end;
end;


procedure TKMInfluences.InitInfluenceForest;
  procedure DoFill(X,Y: SmallInt);
  const
    //Each tree adds this weight lineary fading to forest map
    TREE_WEIGHT = 8;
  var
    I,K: Integer;
  begin
    //Distribute tree weight lineary in TREE_WEIGHT radius
    //loops are TREE_WEIGHT-1 because we skip 0 weight edges
    for I := Max(Y - TREE_WEIGHT+1, 1) to Min(Y + TREE_WEIGHT-1, fTerrain.MapY - 1) do
    for K := Max(X - TREE_WEIGHT+1, 1) to Min(X + TREE_WEIGHT-1, fTerrain.MapX - 1) do
    if Abs(I-Y) + Abs(K-X) < TREE_WEIGHT then
      Forest[I,K] := Forest[I,K] + TREE_WEIGHT - (Abs(I-Y) + Abs(K-X));
  end;
var
  I, K: Integer;
begin
  if not AI_GEN_INFLUENCE_MAPS then Exit;
  Assert(fTerrain <> nil);

  for I := 0 to fMapY - 1 do
  for K := 0 to fMapX - 1 do
    Forest[I,K] := 0;

  //Update forest influence map
  for I := 1 to fMapY - 1 do
  for K := 1 to fMapX - 1 do
  if fTerrain.ObjectIsChopableTree(K,I) then
    DoFill(K,I);
end;


procedure TKMInfluences.UpdateInfluenceMaps;
var
  J: Integer;

  procedure DoFill(X,Y: Integer; V: Word);
  begin
    if  InRange(Y, 1, fTerrain.MapY - 1)
    and InRange(X, 1, fTerrain.MapX - 1)
    and (V > Influence[J, Y, X])
    and (CanOwn in fTerrain.Land[Y,X].Passability) then
    begin
      Influence[J, Y, X] := V;
      DoFill(X, Y-1, Max(V - INFLUENCE_DECAY, 0));
      DoFill(X-1, Y, Max(V - INFLUENCE_DECAY, 0));
      DoFill(X+1, Y, Max(V - INFLUENCE_DECAY, 0));
      DoFill(X, Y+1, Max(V - INFLUENCE_DECAY, 0));
      //We can get away with 4-tap fill, it looks fine already
    end;
  end;
var
  I, K, H: Integer;
  L: Integer;
  P: TKMPoint;
begin
  if not AI_GEN_INFLUENCE_MAPS then Exit;
  Assert(fTerrain <> nil);

  //Update direct influence maps
  for J := 0 to fPlayers.Count - 1 do
  begin
    for I := 1 to fTerrain.MapY - 1 do
    for K := 1 to fTerrain.MapX - 1 do
      Influence[J, I, K] := 0;

    //Sync tile ownership
    for I := 0 to fPlayers[J].Houses.Count - 1 do
    if fPlayers[J].Houses[I].HouseType <> ht_WatchTower then
    begin
      P := fPlayers[J].Houses[I].GetPosition;
      Influence[J, P.Y, P.X] := 254;
    end;

    //Expand influence with faloff
    for I := 1 to fTerrain.MapY - 1 do
    for K := 1 to fTerrain.MapX - 1 do
    if Influence[J, I, K] = 254 then
      DoFill(K,I,Influence[J, I, K]+1);
  end;

  //Fill Ownership map
  //Ownerhip = influence of player - influences of enemies
  for J := 0 to fPlayers.Count - 1 do
  begin
    for I := 1 to fTerrain.MapY - 1 do
    for K := 1 to fTerrain.MapX - 1 do
    begin
      if Influence[J, I, K] <> 0 then
      begin
        L := Influence[J, I, K];

        for H := 0 to fPlayers.Count - 1 do
        if (H <> J) and (fPlayers[J].Alliances[H] = at_Enemy) then
          L := L - Influence[H, I, K] div 3;

        Ownership[J, I, K] := Max(L, 0);
      end
      else
        Ownership[J, I, K] := 0;
    end;
    //Normalization is not working as intended,
    //it gives unfair advantage to one using it,
    //muting neighbours areas beyond reason
  end;
end;


procedure TKMInfluences.ExportInfluenceMaps;
var
  I, J, K: Integer;
begin
  for J := 0 to fPlayers.Count - 1 do
  with TBitmap.Create do
  begin
    Width := fTerrain.MapX;
    Height:= fTerrain.MapY;
    PixelFormat := pf32bit;
    for I := 0 to Height-1 do
      for K := 0 to Width-1 do
        Canvas.Pixels[K,I] := Influence[J, I, K];
    SaveToFile(ExeDir + 'Export\Influence map Player'+IntToStr(J) + '.bmp');
  end;

  for J := 0 to fPlayers.Count - 1 do
  with TBitmap.Create do
  begin
    Width := fTerrain.MapX;
    Height:= fTerrain.MapY;
    PixelFormat := pf32bit;
    for I := 0 to Height-1 do
      for K := 0 to Width-1 do
        Canvas.Pixels[K,I] := Influence[J, I, K];
    SaveToFile(ExeDir + 'Export\Influence map Player'+IntToStr(J) + '.bmp');
  end;
end;


procedure TKMInfluences.UpdateState(aTick: Cardinal);
begin
  if aTick mod 600 = 0 then
    UpdateInfluenceMaps;
end;


//Render debug symbols
procedure TKMInfluences.Paint(aRect: TKMRect);
var
  I, K, J: Integer;
  Col: Cardinal;
begin
  if not AI_GEN_INFLUENCE_MAPS then Exit;

  if OVERLAY_INFLUENCES then
    for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
    begin
      Col := $80000000;
      J := GetBestOwner(K,I);
      if J <> PLAYER_NONE then
        Col := (fPlayers[J].FlagColor and $FFFFFF) or (Byte(Max(Ownership[J,I,K],0)) shl 24);
      fRenderAux.Quad(K, I, Col);
    end;

  if OVERLAY_AVOID then
    for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
    begin
      Col := AvoidBuilding[I,K] * 65793 or $80000000;
      fRenderAux.Quad(K, I, Col);
    end;

  if OVERLAY_FOREST then
    for I := aRect.Top to aRect.Bottom do
    for K := aRect.Left to aRect.Right do
    begin
      Col := Min(Forest[I,K] * 6, 255) * 65793 or $80000000;
      fRenderAux.Quad(K, I, Col);
    end;
end;


constructor TKMAIFields.Create;
begin
  inherited;

  fNavMesh := TKMNavMesh.Create;
  fInfluences := TKMInfluences.Create;
end;


destructor TKMAIFields.Destroy;
begin
  FreeAndNil(fNavMesh);
  FreeAndNil(fInfluences);
  inherited;
end;


procedure TKMAIFields.AfterMissionInit;
begin
  if AI_GEN_INFLUENCE_MAPS then
    fInfluences.Init;

  if AI_GEN_NAVMESH then
  begin
    InitNavMesh;
    fNavMesh.UpdateOwnership;
  end;
end;


procedure TKMAIFields.InitNavMesh;
type
  TStepDirection = (sdNone, sdUp, sdRight, sdDown, sdLeft);
var
  fTileOutlines: TKMShapesArray;
  Tmp: array of array of Byte;
  PrevStep, NextStep: TStepDirection;

  procedure Step(X,Y: Word);
    function IsTilePassable(aX, aY: Word): Boolean;
    begin
      Result := InRange(aX, 1, fTerrain.MapX-1)
                and InRange(aY, 1, fTerrain.MapY-1)
                and (Tmp[aY,aX] > 0);
      //Mark tiles we've been on, so they do not trigger new duplicate contour
      if Result then
        Tmp[aY,aX] := Tmp[aY,aX] - (Tmp[aY,aX] div 2);
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

  procedure WalkPerimeter(aStartX, aStartY: Word);
  var
    X, Y: Integer;
  begin
    X := aStartX;
    Y := aStartY;
    nextStep := sdNone;

    SetLength(fTileOutlines.Shape, fTileOutlines.Count + 1);
    fTileOutlines.Shape[fTileOutlines.Count].Count := 0;

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
      with fTileOutlines.Shape[fTileOutlines.Count] do
      begin
        if Length(Nodes) <= Count then
          SetLength(Nodes, Count + 32);
        Nodes[Count] := KMPointI(X, Y);
        Inc(Count);
      end;
    until((X = aStartX) and (Y = aStartY));

    //Do not include too small regions
    if fTileOutlines.Shape[fTileOutlines.Count].Count >= 12 then
      Inc(fTileOutlines.Count);
  end;

var
  fDelaunay: TDelaunay;
  I, K, L, M: Integer;
  C1, C2, C3, C4: Boolean;
  MeshDensityX, MeshDensityY: Byte;
  SizeX, SizeY: Word;
  PX,PY,TX,TY: Integer;
  Skip: Boolean;
begin
  SetLength(Tmp, fTerrain.MapY+1, fTerrain.MapX+1);

  //Copy map to temp array where we can use Keys 0-1-2 for internal purposes
  //0 - no obstacle
  //1 - parsed obstacle
  //2 - non-parsed obstacle
  for I := 1 to fTerrain.MapY - 1 do
  for K := 1 to fTerrain.MapX - 1 do
    Tmp[I,K] := 2 - Byte(CanOwn in fTerrain.Land[I,K].Passability) * 2;

  fTileOutlines.Count := 0;
  for I := 1 to fTerrain.MapY - 2 do
  for K := 1 to fTerrain.MapX - 2 do
  begin
    //Find new seed among unparsed obstacles
    //C1-C2
    //C3-C4
    C1 := (Tmp[I,K] = 2);
    C2 := (Tmp[I,K+1] = 2);
    C3 := (Tmp[I+1,K] = 2);
    C4 := (Tmp[I+1,K+1] = 2);

    //todo: Skip cases where C1..C4 are all having value of 1-2
    if (C1 or C2 or C3 or C4) <> (C1 and C2 and C3 and C4) then
      WalkPerimeter(K,I);
  end;

  SimplifyStraights(fTileOutlines, KMRect(0, 0, fTerrain.MapX-1, fTerrain.MapY-1), fRawOutlines);

  with TKMSimplifyShapes.Create(2, KMRect(0, 0, fTerrain.MapX-1, fTerrain.MapY-1)) do
  begin
    Execute(fRawOutlines, fSimpleOutlines);
    Free;
  end;

  //Fill Delaunay triangles
  fDelaunay := TDelaunay.Create(-1, -1, fTerrain.MapX, fTerrain.MapY);
  try
    fDelaunay.Tolerance := 1;
    for I := 0 to fSimpleOutlines.Count - 1 do
    with fSimpleOutlines.Shape[I] do
      for K := 0 to Count - 1 do
        fDelaunay.AddPoint(Nodes[K].X, Nodes[K].Y);

    //Add more points on edges
    SizeX := fTerrain.MapX-1;
    SizeY := fTerrain.MapY-1;
    MeshDensityX := SizeX div 15; //once per 15 tiles
    MeshDensityY := SizeY div 15;
    for I := 0 to MeshDensityY do
    for K := 0 to MeshDensityX do
    if (I = 0) or (I = MeshDensityY) or (K = 0) or (K = MeshDensityX) then
    begin
      Skip := False;
      PX := Round(SizeX / MeshDensityX * K);
      PY := Round(SizeY / MeshDensityY * I);

      //Don't add point to obstacle outline if there's one below
      for L := 0 to fSimpleOutlines.Count - 1 do
      with fSimpleOutlines.Shape[L] do
        for M := 0 to Count - 1 do
        begin
          TX := Nodes[(M + 1) mod Count].X;
          TY := Nodes[(M + 1) mod Count].Y;
          if InRange(PX, Nodes[M].X, TX) and InRange(PY, Nodes[M].Y, TY)
          or InRange(PX, TX, Nodes[M].X) and InRange(PY, TY, Nodes[M].Y) then
            Skip := True;
        end;

      if not Skip then
        fDelaunay.AddPoint(PX, PY);
    end;

    //Tolerance must be a little higher than longest span we expect from polysimplification
    //so that not a single node was placed on an outline segment (otherwise RemObstaclePolys will not be able to trace outlines)
    fDelaunay.Tolerance := 7;
    for I := 1 to MeshDensityY - 1 do
    for K := 1 to MeshDensityX - Byte(I mod 2 = 1) - 1 do
      fDelaunay.AddPoint(Round(SizeX / MeshDensityX * (K + Byte(I mod 2 = 1) / 2)), Round(SizeY / MeshDensityY * I));

    fDelaunay.Mesh;

    //Bring triangulated mesh back
    SetLength(fRawMesh.Vertices, fDelaunay.VerticeCount);
    for I := 0 to fDelaunay.VerticeCount - 1 do
    begin
      fRawMesh.Vertices[I].X := Round(fDelaunay.Vertex[I].X);
      fRawMesh.Vertices[I].Y := Round(fDelaunay.Vertex[I].Y);
    end;
    SetLength(fRawMesh.Polygons, fDelaunay.PolyCount);
    for I := 0 to fDelaunay.PolyCount - 1 do
    begin
      fRawMesh.Polygons[I,0] := fDelaunay.Triangle^[I].vv0;
      fRawMesh.Polygons[I,1] := fDelaunay.Triangle^[I].vv1;
      fRawMesh.Polygons[I,2] := fDelaunay.Triangle^[I].vv2;
    end;
  finally
    FreeAndNil(fDelaunay);
  end;

  ForceOutlines(fRawMesh, KMRect(0, 0, fTerrain.MapX-1, fTerrain.MapY-1), fSimpleOutlines);

  RemoveObstaclePolies(fRawMesh, fSimpleOutlines);

  RemoveFrame(fRawMesh);

  CheckForDegenerates(fRawMesh);//}

  Assert(Length(fRawMesh.Polygons) > 8);

  fNavMesh.AssignMesh(fRawMesh);
end;


procedure TKMAIFields.UpdateState(aTick: Cardinal);
begin
  fInfluences.UpdateState(aTick);

  fNavMesh.UpdateState(aTick);
end;


//Render debug symbols
procedure TKMAIFields.Paint(aRect: TKMRect);
var
  I, K: Integer;
begin
  if AI_GEN_INFLUENCE_MAPS then
    fInfluences.Paint(aRect);

  //Raw obstacle outlines
  if OVERLAY_NAVMESH then
    for I := 0 to fRawOutlines.Count - 1 do
    for K := 0 to fRawOutlines.Shape[I].Count - 1 do
    with fRawOutlines.Shape[I] do
      fRenderAux.Line(Nodes[K], Nodes[(K + 1) mod Count], $FFFF00FF);

  if AI_GEN_NAVMESH then
    fNavMesh.Paint(aRect);
end;


end.
