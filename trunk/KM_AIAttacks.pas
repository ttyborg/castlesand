unit KM_AIAttacks;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, SysUtils, StrUtils,
    KM_CommonClasses, KM_Defaults, KM_Houses, KM_Units, KM_Units_Warrior, KM_Utils, KM_Points;

type

  //Indexes must match with KaM script values (for now)
  TAIAttackTarget = (att_ClosestUnit=0, //Closest enemy unit (untested as to whether this is relative to army or start position)
                     att_ClosestBuildingFromArmy=1, //Closest building from the group(s) lauching the attack
                     att_ClosestBuildingFromStartPos=2, //Closest building from the AI's start position
                     att_CustomPosition=3); //Custom point defined with CustomPosition


  TAIAttack = record
    AttackType: TAIAttackType; //Once or repeating
    HasOccured: boolean; //Has this attack happened already?
    Delay: cardinal; //The attack will not occur before this time has passed
    TotalMen: integer; //Number of idle (i.e. back line) warriors required in the AI army before the attack will launch
    GroupAmounts: array[TGroupType] of byte; //How many squads of each group type will be taken
    TakeAll: boolean; //Used instead of GroupAmounts, chooses groups randomly taking at most TotalMen warriors
    Target: TAIAttackTarget;
    Range: integer; //Will only occur when target is within this tile range (not properly tested yet)
    CustomPosition: TKMPoint; //Used when Target = att_CustomPosition
  end;


  TAIAttacks = class
  private
    fCount: Integer;
    fAttacks: array of TAIAttack;
    function GetAttack(aIndex: Integer): TAIAttack;
  public
    constructor Create;
    destructor Destroy; override;

    property Count: Integer read fCount;
    property Items[aIndex: Integer]: TAIAttack read GetAttack; default;
    procedure AddAttack(aAttack: TAIAttack);
    function MayOccur(aIndex: Integer; MenAvailable: Integer; GroupsAvailableCount: array of Integer): Boolean;
    procedure Occured(aIndex: Integer);

    function GetAsText: string;

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
  end;


implementation
uses KM_Game;


{ TAIAttacks }
constructor TAIAttacks.Create;
begin
  //
end;


destructor TAIAttacks.Destroy;
begin
  //
  inherited;
end;


function TAIAttacks.MayOccur(aIndex: Integer; MenAvailable: Integer; GroupsAvailableCount: array of Integer): Boolean;
var GT: TGroupType;
begin
  begin
    Result := ((fAttacks[aIndex].AttackType = aat_Repeating) or not fAttacks[aIndex].HasOccured)
              and fGame.CheckTime(fAttacks[aIndex].Delay)
              and (fAttacks[aIndex].TotalMen <= MenAvailable);

    if not fAttacks[aIndex].TakeAll then
      for GT := Low(TGroupType) to High(TGroupType) do
        Result := Result AND (fAttacks[aIndex].GroupAmounts[GT] <= GroupsAvailableCount[byte(GT)]);

    //todo: Add support for the AI attack feature Range
  end;
end;


procedure TAIAttacks.Occured(aIndex: Integer);
begin
  fAttacks[aIndex].HasOccured := True;
end;


procedure TAIAttacks.AddAttack(aAttack: TAIAttack);
begin
  if fCount >= Length(fAttacks) then
    SetLength(fAttacks, fCount + 16);

  fAttacks[fCount] := aAttack;
  inc(fCount);
end;


function TAIAttacks.GetAsText: string;
var I: Integer;
begin
  Result := '';

  {  AttackType: TAIAttackType; //Once or repeating
    HasOccured: boolean; //Has this attack happened already?
    Delay: cardinal; //The attack will not occur before this time has passed
    TotalMen: integer; //Number of idle (i.e. back line) warriors required in the AI army before the attack will launch
    GroupAmounts: array[TGroupType] of byte; //How many squads of each group type will be taken
    TakeAll: boolean; //Used instead of GroupAmounts, chooses groups randomly taking at most TotalMen warriors
    Target: TAIAttackTarget;
    Range: integer; //Will only occur when target is within this tile range (not properly tested yet)
    CustomPosition: TKMPoint; //Used when Target = att_CustomPosition
  }

  for I := 0 to fCount - 1 do
  begin
    Result := Result + 'Attack #' + IntToStr(I) + eol;
    Result := Result + IfThen(fAttacks[I].AttackType = aat_Once, 'Once', 'Repeating') + eol;
    Result := Result + 'Delay' + IntToStr(fAttacks[I].Delay) + eol;
    Result := Result + 'TotalMen' + IntToStr(fAttacks[I].TotalMen) + eol;
    {Result := Result + 'TotalMen' + IntToStr(fAttacks[I].TotalMen) + eol;
    Result := Result + 'TotalMen' + IntToStr(fAttacks[I].TotalMen) + eol;
    Result := Result + 'TotalMen' + IntToStr(fAttacks[I].TotalMen) + eol;}
  end;
end;

function TAIAttacks.GetAttack(aIndex: Integer): TAIAttack;
begin
  Result := fAttacks[aIndex];
end;


procedure TAIAttacks.Save(SaveStream: TKMemoryStream);
var I: Integer;
begin
  SaveStream.Write(fCount);
  for I := 0 to fCount - 1 do
    SaveStream.Write(fAttacks[i], SizeOf(fAttacks[i]));
end;


procedure TAIAttacks.Load(LoadStream: TKMemoryStream);
var I: Integer;
begin
  LoadStream.Read(fCount);
  SetLength(fAttacks, fCount);
  for I := 0 to fCount - 1 do
    LoadStream.Read(fAttacks[i], SizeOf(fAttacks[i]));
end;


end.
