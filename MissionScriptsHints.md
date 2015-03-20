# Introduction #

This page is intended to help scripters who have some experience and want to learn how to write better script code. I originally wrote this page while judging the the Scripted Mission Competition. A lot of the hints here are mistakes I commonly saw in the competition entries.

# Contents #


# Basics #
### Indentation ###
Using proper indentation makes your code much easier to read and results in less mistakes. Here is some badly indented code:
```
procedure OnMissionStart;
var I: Integer;
begin
Actions.GiveHouse(0, 17, 113, 105);
for I:=0 to 7 do
begin
if States.PlayerEnabled(I) then
Actions.GiveHouse(...);
Actions.GiveUnit(...);
end;
end;
```
And here is the same code with proper indentation:
```
procedure OnMissionStart;
var I: Integer;
begin
  Actions.GiveHouse(0, 17, 113, 105);
  for I:=0 to 7 do
  begin
    if States.PlayerEnabled(I) then
      Actions.GiveHouse(...);
    Actions.GiveUnit(...);
  end;
end;
```
As you can see it is much easier to read. If you are using Notepad++ to edit your scripts (you should be, see MissionScriptsDynamicTutorial) there are shortcuts to make indentation easier. Select a block of code and press Tab to indent it 1 level. Press Shift+Tab to unindent it 1 level.


### Shorter ways to write things ###
These two lines are equivalent:
```
if States.PlayerEnabled(1) = true then
if States.PlayerEnabled(1) then
```
Similarly these two lines are also equivalent:
```
if States.PlayerEnabled(1) = false then
if not States.PlayerEnabled(1) then
```


You don't need to have `begin...ends` if you only have one statement within them. For example this code:
```
procedure OnMissionStart;
var I: Integer;
begin
  if States.KaMRandom >= 0.5 then
  begin
    for I:=0 to 7 do
    begin
      if States.PlayerEnabled(I) then
      begin
        Actions.GiveUnit(...);
      end;
    end;
  end;
  States.FogRevealAll(0);
end;
```
is equivalent to:
```
procedure OnMissionStart;
var I: Integer;
begin
  if States.KaMRandom >= 0.5 then
    for I:=0 to 7 do
      if States.PlayerEnabled(I) then
        Actions.GiveUnit(...);
  States.FogRevealAll(0);
end;
```
You can create multiline comments using `{` and `}` like this:
```
{ Comment line 1
  Comment line 2
  Comment line 3 }
```

### Booleans ###
You can combine and nest logic opperators like AND, OR, NOT, etc. with brackets. Here is an example from an entry in the Scripted Mission Competition:
```
if (Passage1 <> -1) and (States.UnitOwner(Passage1) = 0) and (BarracksCreated = false) then
begin
  TDLBarracks := Actions.GiveHouse(2, 21, 37, 41);
  BarracksCreated := True;
  Actions.ShowMsg(0, 'Wow! That barracks belongs to The Dark Lord! We should destroy it in order to get through.');
end;
if (Passage2 <> -1) and (States.UnitOwner(Passage2) = 0) and (BarracksCreated = false) then
begin
  TDLBarracks := Actions.GiveHouse(2, 21, 37, 41);
  BarracksCreated := True;
  Actions.ShowMsg(0, 'Wow! That barracks belongs to The Dark Lord! We should destroy it in order to get through.');
end;
if (Passage3 <> -1) and (States.UnitOwner(Passage3) = 0) and (BarracksCreated = false) then
begin
  TDLBarracks := Actions.GiveHouse(2, 21, 37, 41);
  BarracksCreated := True;
  Actions.ShowMsg(0, 'Wow! That barracks belongs to The Dark Lord! We should destroy it in order to get through.');
end;
```
As you can see, the code within each if-statement does not change. We can therefore combine this into one big if-statement like this:
```
if not BarracksCreated 
and (
       ((Passage1 <> -1) and (States.UnitOwner(Passage1) = 0))
    or ((Passage2 <> -1) and (States.UnitOwner(Passage2) = 0))
    or ((Passage3 <> -1) and (States.UnitOwner(Passage3) = 0))
    ) then
begin
  TDLBarracks := Actions.GiveHouse(2, 21, 37, 41);
  BarracksCreated := True;
  Actions.ShowMsg(0, 'Wow! That barracks belongs to The Dark Lord! We should destroy it in order to get through.');
end;
```
Note that the spacing is not required and you could also write the if-statement like this:
```
if not BarracksCreated and (((Passage1 <> -1) and (States.UnitOwner(Passage1) = 0)) or ((Passage2 <> -1) and (States.UnitOwner(Passage2) = 0)) or ((Passage3 <> -1) and (States.UnitOwner(Passage3) = 0))) then
```
But obviously it's much easier to read if you use spacing like I did in the first example.

# Text #

### Translations - basics ###

You can make your text translatable using LIBX files. This is a requirement to have your map added to the Remake (our translators will do any missing translations if they have time).

Create a blank text file _My Mission.eng.libx_ in your map folder, then run `TranslationManager.exe` from the main KaM Remake folder. In the top left select the libx file you just created for your map. In the bottom left you can see a list of strings in your translation files, each with a unique index starting at 0. Type the text on the right in the English section (you can choose which languages will be shown with the checkboxes). English is used as a fallback for missing languages so you must at least have an English translation. Click Insert New to add more strings. Save your work with File->Save.

Then to use the strings in your code, use markup like this:
```
Actions.ShowMsg(-1, 'Here is the first LIBX string: <$0>. Next message will contain the second LIBX string');
Actions.ShowMsg(-1, '<$1>');
```
The markup <$1> within a string will be automatically replaced with the LIBX string of that index before it is displayed. Take a look at some existing KaM Remake maps which use translations for more information (for example, the tutorials or campaigns)


### Translations - advanced ###

When you want to translate a string like this:
```
Actions.ShowMsg(0, 'You must kill ' + IntToStr(SomeVar) + ' bowmen to win');
```
The bad way to make this string translatable is placing two strings in your translation file 'You must kill' and 'bowmen to win':
```
Actions.ShowMsg(0, '<$1> ' + IntToStr(SomeVar) + ' <$2>');
```
A better way to do it is to use one string like this: 'You must kill %d bowmen to win'. This allows your translators to understand the context and move the number due to grammatical differences in their language.
There are "formatted" versions of commands like ShowMsg that replace %d with your number:
```
Actions.ShowMsgFormatted(0, '<$1>', [SomeVar]);
```
For more information about format commands like %d, read: http://www.delphibasics.co.uk/RTL.asp?Name=Format

### Displaying time ###
Format is also the best way to display times like 07:31 because it can add leading zeros automatically. For example:
```
Actions.OverlayTextSetFormatted(0, 'Time remaining: %.2d:%.2d', [Minutes, Seconds]);
```
For more information about using format commands like %.2d, read: http://www.delphibasics.co.uk/RTL.asp?Name=Format


# Performance #
You can improve the performance of your script by running slow code occasionally rather than every tick. _mod_ returns the remainder of a division, which is useful in this case. Example:
```
procedure OnTick;
begin
  //This will cause RunSlowCode to occur on ticks 10, 20, 30, etc.
  if States.GameTime mod 10 = 0 then
    RunSlowCode;
end;
```
However, that isn't ideal because the slow code can still cause the game to lag if it takes too long. Now you will have 9 smooth ticks and 1 slow tick, which can make the game feel choppy.

You can do this even more effectively if your script involves updating something for multiple players
```
procedure OnTick;
const USED_PLAYERS = 6; //Map only uses 6 locations
var PlayerToUpdate: Integer;
begin
  PlayerToUpdate := States.GameTime mod USED_PLAYERS;
  if States.PlayerEnabled(PlayerToUpdate) then
    UpdatePlayer(PlayerToUpdate);
end;
```
This means that each tick only 1 player is updated. It balances the load so all ticks do about the same amount of processing

Of course it doesn't have to be players, if you have 10 objectives numbered 0..9 which are slow to evaluate you could do something like this:
```
procedure OnTick;
begin
  CheckObjective(States.GameTime mod 10);
end;
```


# Neater code #
### Records ###
Records are a good way to make your code neater and easier to understand. You can define your own records to group variables together. This is especially useful when the variables are in arrays. By convention, new type definiations like records start with T, for example TMyOwnRecord. This makes them easy to distinguish.

Here is an example of some code we want to neaten:
```
var
  EnemyStartX: array[1..10] of Integer;
  EnemyStartY: array[1..10] of Integer;
  EnemyPoints: array[1..10] of Integer;
  EnemyU: array[1..10] of Integer; //Unit ID

procedure OnMissionStart;
begin
  EnemyStartX[1] := 5;
  EnemyStartY[1] := 7;
  EnemyPoints[1] := 100;
  EnemyU[1] := Actions.GiveUnit(...);
end;
```

Here is a way to write the same code using records:
```
type TEnemy = record
  StartX: Integer;
  StartY: Integer;
  Points: Integer;
  U: Integer; //Unit ID
end;

var
  Enemies: array[1..10] of TEnemy;

procedure OnMissionStart;
begin
  Enemies[1].StartX := 5;
  Enemies[1].StartY := 7;
  Enemies[1].Points := 100;
  Enemies[1].U := Actions.GiveUnit(...);
end;
```
You can also pass a record as a parameter to a procedure or function, as well as return them:
```
function GenerateBackupEnemy(EnemyToReinforce: TEnemy; NewUnit: Integer): TEnemy;
begin
  //Generate and return another TEnemy using the provided NewUnit that will defend next to the existing TEnemy
  Result.StartX := EnemyToReinforce.StartX + 1;
  Result.StartY := EnemyToReinforce.StartY;
  Result.Points := 200;
  Result.U := NewUnit;
end;
```

### Avoid copy paste code ###
Sometimes you want to do the same thing multiple times but with slight changes, so you copy a big block of code and modify it slightly. This makes your scripts much longer than necessary, easier to make mistakes and harder to maintain. If you find yourself copy-pasting the same piece of code multiple times (with only small changes) then there's probably a better way.

Here is an example of some copy pasted code from an entry in the Scripted Mission Competition:
```
procedure SetUpTowerSpots;
var 
counter1, fastHouse: integer;
begin
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
    PlayerTowersCarrier:= counter1; break; end;
  end;
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 89, 27);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[0]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 86, 87);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[1]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 148, 92);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[2]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 21, 85);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[3]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 89, 157);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[4]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 71, 72);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[5]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 114, 50);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[6]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 65, 124);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[7]:= fastHouse;
  
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, 113, 105);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[8]:= fastHouse;
end;
```
An easy way to make code like this smaller is to put the copy-paste code into a procedure and pass the parameters that change to the procedure:
```
procedure AddTower(X,Y, Index: Integer);
var 
counter1, fastHouse: integer;
begin
  fastHouse:=Actions.GiveHouse(PlayerTowersCarrier, 17, X, Y);
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
      Actions.FogCoverCircle(counter1, States.HousePositionX(fastHouse), States.HousePositionY(fastHouse), 19); end; end;
  Actions.HouseDisableUnoccupiedMessage(fastHouse, true);
  Actions.HouseAddDamage(fastHouse, 245);
  SpotTowersList[Index]:= fastHouse;
end;

procedure SetUpTowerSpots;
begin
  for counter1:= 0 to 7 do begin
    if ( States.PlayerEnabled(counter1)=true ) then begin
    PlayerTowersCarrier:= counter1; break; end;
  end;
  AddTower(89, 27, 0);
  AddTower(86, 87, 1);
  AddTower(148, 92, 2);
  AddTower(21, 85, 3);
  AddTower(89, 157, 4);
  AddTower(71, 72, 5);
  AddTower(114, 50, 6);
  AddTower(65, 124, 7);
  AddTower(113, 105, 8);
end;
```
It was 80 lines, now it's 29. It's also much easier if we need to make changes to the way towers are added as we only need to edit one place instead of 9. There are also many other aspects of this code which could be improved to make it more readable and maintainable using techniques already discussed on this page. See if you can spot some :)