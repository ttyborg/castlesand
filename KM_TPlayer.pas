unit KM_TPlayer;
interface
uses KM_Defaults,SysUtils,Math;

type
TPlayer = class
public
//ColorID:byte;
//ColorRemap:array[1..6]of byte;
Enabled:boolean;
CenterScreen:record PosX,PosY:integer; end;
ReleaseHouse:array[1..29]of boolean;
BlockHouse:array[1..29]of boolean;
ClearUp:array of record
        PosX,PosY,Radius:integer;
        end;
House:array of record
      PosX,PosY:integer;
      Kind:byte;
      Damage:integer;
      end;
//Road:array of record
//     PosX,PosY:integer;
//     end;
private
pHouseCount:integer;
pRoadCount:integer;
pClearUpCount:integer;
published
constructor Create();
property HouseCount:integer read pHouseCount;
property RoadCount:integer read pRoadCount;
property ClearUpCount:integer read pClearUpCount;
procedure AddHouse(HouseID,PosX,PosY:integer);
procedure AddClearUp(PosX,PosY,Radius:integer);
procedure RemHouse(HouseID:integer);
function  GetAllHouseStrings():string;
end;

type
TMission = class
public
Player:array[1..6] of TPlayer;
Roads:array[1..256,1..256]of boolean;
Owner:array[1..256,1..256]of byte;
ActivePlayer:integer;
SetMapFile:string;
SetHumanPlayer:integer;
private
published
constructor Create();
procedure RemHouse(PosX,PosY:integer);
procedure RemRoad(PosX,PosY:integer);
procedure AddRoad(PosX,PosY,_Owner:integer);
function  GetAllRoadStrings(_Owner:integer):string;
end;

implementation
uses KM_Unit1, KM_Global_Data;

constructor TPlayer.Create();
var i:integer;
begin
pHouseCount:=0;
pClearUpCount:=0;
for i:=1 to 29 do ReleaseHouse[i]:=false;
for i:=1 to 29 do BlockHouse[i]:=false;
end;

procedure TPlayer.AddHouse(HouseID,PosX,PosY:integer);
begin
inc(pHouseCount);
setlength(House,pHouseCount+1);
House[pHouseCount].PosX:=PosX;
House[pHouseCount].PosY:=PosY;
House[pHouseCount].Kind:=HouseID;
House[pHouseCount].Damage:=0;
end;

procedure TPlayer.AddClearUp(PosX,PosY,Radius:integer);
begin
inc(pClearUpCount);
setlength(ClearUp,pClearUpCount+1);
ClearUp[pClearUpCount].PosX:=PosX;
ClearUp[pClearUpCount].PosY:=PosY;
ClearUp[pClearUpCount].Radius:=Radius;
end;

procedure TPlayer.RemHouse(HouseID:integer);
var i:integer;
begin
for i:=HouseID to HouseCount-1 do
House[i]:=House[i+1];
dec(pHouseCount);
setlength(House,pHouseCount+1);
end;

function TPlayer.GetAllHouseStrings():string;
var i:integer;
begin
Result:='';
for i:=1 to HouseCount do
Result:=Result+'!SET_HOUSE '
+inttostr(House[i].Kind-1)+' '
+inttostr(House[i].PosX-1)+' '
+inttostr(House[i].PosY-1)+#13+#10;
end;

constructor TMission.Create();
var i:integer;
begin
ActivePlayer:=1;
for i:=1 to 6 do Player[i]:=TPlayer.Create;
end;

//Remove house by given X,Y
//Check all players houses if they are in a way
procedure TMission.RemHouse(PosX,PosY:integer);
var i,k:integer;
begin
for i:=1 to 6 do
for k:=1 to Player[i].HouseCount do
if (PosX-Player[i].House[k].PosX+3 in [1..4])and(PosY-Player[i].House[k].PosY+4 in [1..4]) then
if HousePlanYX[Player[i].House[k].Kind,PosY-Player[i].House[k].PosY+4,PosX-Player[i].House[k].PosX+3]<>0 then
Player[i].RemHouse(k);
end;

//Remove road by given X,Y
procedure TMission.RemRoad(PosX,PosY:integer);
begin
Roads[PosX,PosY]:=false;
Owner[PosX,PosY]:=0;
end;

procedure TMission.AddRoad(PosX,PosY,_Owner:integer);
begin
Roads[PosX,PosY]:=true;
Owner[PosX,PosY]:=_Owner;
end;

function TMission.GetAllRoadStrings(_Owner:integer):string;
var i,k,Num:integer;
begin
Result:=''; Num:=0;
for i:=1 to fTerrain.MapY do for k:=1 to fTerrain.MapX do
if (Roads[k,i])and(Owner[k,i]=_Owner) then begin
Result:=Result+'!SET_STREET '+inttostr(k-1)+' '+inttostr(i-1);
inc(Num);
if Num mod 4 = 0  then Result:=Result+' '+#13+#10;
end;
end;

end.



