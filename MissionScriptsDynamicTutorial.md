This is a quick guide to help you get started with dynamic scripts.

First you need a nice enviroment to edit your scripts. We don't have a fancy IDE (yet), but Notepad++ is a nice text editor with syntax highlighting that I'd highly recommend:

http://notepad-plus-plus.org/

To set it up to automatically syntax highlight KaM Remake script files:
  1. Click Settings -> Style Configurator
  1. From the language list, select Pascal
  1. In "User ext." enter script
Here's a screenshot of the Style Configurator after it's been setup correctly:
![http://i.imgur.com/b9ux7TA.png](http://i.imgur.com/b9ux7TA.png)

Now when you open scripts they should be nice and colourful with syntax highlighting, which makes editing easier.

You should also know how to use the Script Validator. Run ScriptValidator.exe from the main KaM Remake folder. Browse to a script file and click validate. It will show you any warnings/errors about the script, which saves you from restarting the mission just to check for minor errors in the script.

Next, lets write your first script!
  1. Make a new map in the KaM Remake editor, give player 1 a storehouse, some supplies and serfs/labourers, and save it in singleplayer as "Hello World".
  1. Then browse to "Maps\Hello World" in your KaM Remake folder, which is where ever you have the KaM Remake installed (possibly C:\KaM Remake or C:\Program Files\KaM Remake)
  1. Make a new file in Notepad++ and save it in that folder as "Hello World.script".
  1. Put this into the file:
```
procedure OnTick;
begin
  if States.GameTime = 10 then
    Actions.ShowMsg(0, 'Hello World');
end;
```
5. Save the script file and run the mission from the singleplayer maps menu.

If you did it correctly you should get a message after 1 second saying "Hello World". Well done, you've made your first script! Now I'll explain what is going on in that script:

First open up our wiki page for dynamic scripts:

http://code.google.com/p/castlesand/wiki/MissionScriptsDynamic

This is a complete reference guide for all the commands we have implemented in the scripts. There are three main elements:
  * Events - If you have declared these procedures in your script the game will call them when certain events happen. They are the entry point for the game to run something within your script, there's no other way.
  * States - These allow you to query the game (without changing it). For example States.GameTime gives you the current game time.
  * Actions - These allow you to change the game in some way. For example Actions.ShowMsg displays a message to the player.

This page is also useful:

http://code.google.com/p/castlesand/wiki/MissionScriptsLookups

It has lookup tables for house, unit and ware types.

Now I'll explain each line of the code:

  * _procedure OnTick;_  - This is a procedure to handler an event which the game will run when a certain event occurs. In this case, the event is "Tick", which you can see from the wiki page occurs every time the game updates (10 times per second). So your procedure "OnTick" will be executed 10 times per second by the game each time it updates everything.
  * _if States.GameTime = 10 then_ - This line queries the game to get the current game time, measured in ticks (10 ticks per second). If that time is equal to 10, the statement after this line will be executed.
  * _Actions.ShowMsg(0, 'Hello World');_ - This line sends a message to player 0 (player 1 in the map editor, script players are zero based) with the text "Hello World".

Now lets try some more complicated expressions. Lets show a message every 30 seconds if the player has a school or an inn, but does not have a stonemason. Here is the code that would do that:
```
procedure OnTick;
begin
  if (States.GameTime mod 300 = 0) 
  and ((States.StatHouseTypeCount(0, 13) > 0) or (States.StatHouseTypeCount(0, 27) > 0)) 
  and not (States.StatHouseTypeCount(0, 14) > 0) then
    Actions.ShowMsg(0, 'You should built a stonemason');
end;
```
  * From the lookup tables page (linked above) you can see what the house indexes mean, 13 is school, 27 is inn and 14 is stonemason.
  * Lookup StatHouseTypeCount on the wiki page and make sure you understand what the two parameters are. The boolean logic (and/or/not) in the statement above should be fairly obvious.
  * The operator "mod" gives the remainder from division, so in this case we divide the game time by 300 (30 seconds) and take the remainder. This remainder will cycle from 0 to 299 every 30 seconds, so if we check when it is equal to 0 the statement will be true once every 30 seconds.

Now lets do something more complicated. At the start of the mission we will give the player a group of 9 knights at 10;10 (X;Y). When the player builds a school we will order those knights to move to 20;20. Each time the player builds a house the script will congratulate him, and tell him if the knights were moved.
Here is the script:
```
var Knights: Integer;

procedure OnMissionStart;
begin
  Knights := Actions.GiveGroup(0, 22, 10, 10, 0, 9, 3);
end;

procedure OnHouseBuilt(aHouseID: Integer);
var MyText: AnsiString;
begin
  if States.HouseOwner(aHouseID) <> 0 then
    Exit;

  MyText := 'You finished a house! Good job!';
  if (States.HouseType(aHouseID) = 13) then
  begin
    Actions.GroupOrderWalk(Knights, 20, 20, 0);
    MyText := MyText + '|Knights were ordered to walk!';
  end;

  Actions.ShowMsg(0, MyText);
end;
```
  * Firstly, at the top of the script we are declaring a global variable. A variable is used to store something for later, in this case we store a pointer to the group of knights (a Group ID), which is stored as an Integer (number).
  * We use the event OnMissionStart to add the knights to the game and remember their ID (pointer) for later, in the variable called "Knights".
  * 22 is the unit index for knights (you can see that in the lookup page)
  * 0 is used for the facing direction of the knights, which means north (you can see that in the lookup page)
  * When a house is built, we check we do nothing if the house is not owned by player 0. If it is, we check if the house is a school and if so, order the knights to move
  * <> means "not equal to" in Pascal
  * Exit leaves the procedure immediately without running any lines below it
  * We create a local variable (only accessible within this procedure) called MyText to store a string (text) and add to it throughout the procedure, then display that string to the player at the end
  * Vertical bar (|) is used in text to create a new line in KaM text messages


For more examples take a look at some of the scripted missions included in the Remake. For example the "special" multiplayer maps have more complicated scripts which you can learn from.

I hope you enjoyed this quick tutorial, please let us know if you find any parts of it confusing so we can improve it.

Thanks for reading, happy scripting!


## Resources ##
  * **Lookup tables** (unit/house/ware types): MissionScriptsLookups
  * **Scripting reference**: MissionScriptsDynamic
  * **Language reference**: http://www.delphibasics.co.uk/ (note: our scripts don't have all the features of Delphi, but this is still a useful reference)