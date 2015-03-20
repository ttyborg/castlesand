# Mission scripts #

Missions can be easily extended with custom scripts to add special events to them. Each missions script is located in `\Maps\map_name\map_name.script` file, which can be opened in any plain text editor (e.g. Notepad). Scripts are written in PascalScript language (syntax is very similar to usual Pascal).

Script has 3 ways of interacting with the game - **Events**, **States** and **Actions**. Events get called by the game when they happen. States are values that can be queried from the game. Actions are way to tell the game what to do. Scripts get verified on mission load and any errors are output in a message to a player.

Script file consists of several parts:

```
//Global constants section,  accessible from any place in the script.
//Useful to make parameters easy to change in one place.
const
  MY_CONSTANT = 7; //by convention constants are written in upper case

//Global variables section, accessible from any place in the script and stored in game memory
var
  I: Integer; //variable number
  A: array [0..3] of Boolean; //array of 4 booleans accessible as A[0], A[1] etc.

//Event handler, when the event happens ingame this function gets called
procedure OnHouseBuilt(..); //Each event has different input parameters list
var //Local variables, they exist only within this procedure
  L: Integer; //variable number 
begin
  //Event code
  L := 7; //assignment of number to a variable
  Actions.ShowMsg(L,'hello'); //Calling a games action with 2 parameters: L and a string 'hello'
end;

//Event handler for "tick" event, which happens 10 times per second (on each game logic update).
procedure OnTick;
begin
  //Code here
  if States.GameTime = 60 then //Check game time and show a message
    Actions.ShowMsg(0,'<$3>'); //<$3> is markup to fetch text ID 3 from LIBX translation file
end;
```

Here is Battle Tutorial script explained:

```
procedure OnPlayerDefeated(aIndex: Integer);
begin
  if aIndex = 2 then Actions.ShowMsg(0, '<$2>');
  if aIndex = 3 then Actions.ShowMsg(0, '<$3>');
  if aIndex = 4 then Actions.ShowMsg(0, '<$4>');
end;

procedure OnTick;
begin
  if States.GameTime = 20 then 
    Actions.ShowMsg(0, '<$1>');
end;
```

Above line means that when `PlayerDefeated` event comes from the game, we check the index of the player that was defeated (aIndex) and issue a command to show certain message to specified player (0, who is human). Also, each tick we check the games time and on tick 20 (2 seconds from mission starting) we show another message. Message text is retrieved from the mission's .LIBX file using the markup <$123> (fetches text ID 123 from LIBX), meaning it will be in the player's own language if a translation has been made.


## Global campaign data ##
This feature allows you to store data between missions in a campaign. First, create a file in your campaign folder `campaigndata.script`. In that file you must put the definition of the data you want to store. We recommend using a record so you can easily add more data in the future. Here is an example `campaigndata.script`:
```
record
  Mission1: record
    SoldiersRemaining: Integer;
    TimeOfVictory: Integer;
  end;
  Mission2: record
    Army: array of record
                     UnitType, X, Y: Integer;
                   end;
    TimeOfVictory: Integer;
  end;
end;
```
The data can then be accessed and modified with the global variable `CampaignData` (the type is TCampaignData), for example: `CampaignData.Mission1.TimeOfVictory`. The data is stored in the user's campaign progress file (Saves\Campaigns.dat).
  * The data will be loaded when a campaign mission is started, and saved whenever the user exits, regardless of whether they won the mission. This allows you to record information about failed attempts. If you only want to record data when the user wins the mission, you should only save data into the global variable `CampaignData` within the event `OnPlayerVictory`.
  * The user may go back and play an earlier mission, so it is advised to separate the data which each mission will modify, as shown in the above example. In other words, don't reuse the same structures in every mission since missions might be played out of order.


## Other resources ##
  * **Lookup tables** (unit/house/ware types): MissionScriptsLookups
  * **Scripting tutorial**: MissionScriptsDynamicTutorial
  * **Scripting hints**: MissionScriptsHints
  * **Language reference**: http://www.delphibasics.co.uk/ (note: our scripts don't have all the features of Delphi, but this is still a useful reference)


### Events ###

| Version | Event | Description | Parameters and types |
|:--------|:------|:------------|:---------------------|
| 6570 | `OnBeacon` | Occurs when a player places a beacon on the map. | aPlayerIndex: Integer; //Player who placed it <br> aX: Integer; //X coordinate of the beacon <br> aY: Integer; //Y coordinate of the beacon <br>
<tr><td> 6114 </td><td> <code>OnHouseAfterDestroyed</code> </td><td> Occurs after a house is destroyed and has been completely removed from the game, meaning the area it previously occupied can be used. If you need more information about the house use the OnHouseDestroyed event. </td><td> aHouseType: Integer; //Type of the house <br> aOwner: Integer; //Index of player who owned it <br> aX: Integer; //X coordinate of the house <br> aY: Integer; //Y coordinate of the house </td></tr>
<tr><td> 5057 </td><td> <code>OnHouseBuilt</code> </td><td> Occurs when player has built a house </td><td> aHouseID: Integer; //HouseID of the house that was built </td></tr>
<tr><td> 5882 </td><td> <code>OnHouseDamaged</code> </td><td> Occurs when a house is damaged by the enemy soldier. If AttackerIndex is -1 the house was damaged some other way, such as from Actions.HouseAddDamage. </td><td> aHouseID: Integer; //House that is damaged <br> aAttackerIndex: Integer; //UnitID of attacker </td></tr>
<tr><td> 5407 </td><td> <code>OnHouseDestroyed</code> </td><td> Occurs when a house is destroyed. If DestroyerIndex is -1 the house was destroyed some other way, such as from Actions.HouseDestroy. If DestroyerIndex is the same as the house owner (States.HouseOwner), the house was demolished by the player who owns it. Otherwise it was destroyed by an enemy. Called just before the house is destroyed so HouseID is usable only during this event, and the area occupied by the house is still unusable. </td><td> aHouseID: Integer; //HouseID of the house that was destroyed <br> aDestroyerIndex: Integer; //Index of player who destroyed it </td></tr>
<tr><td> 5871 </td><td> <code>OnHousePlanPlaced</code> </td><td> Occurs when player has placed a house plan </td><td> aPlayerIndex: Integer; //Player who placed it <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> aHouseType: Integer; //Type of house of the plan </td></tr>
<tr><td> 6298 </td><td> <code>OnHousePlanRemoved</code> </td><td> Occurs when player has removed a house plan </td><td> aPlayerIndex: Integer; //Player who removed it <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> aHouseType: Integer; //Type of house of the plan </td></tr>
<tr><td> 6220 </td><td> <code>OnGroupHungry</code> </td><td> Occurs when the player would be shown a message about a group being hungry (when they first get hungry, then every 4 minutes after that if there are still hungry group members). Occurs regardless of whether the group has hunger messages enabled or not </td><td> aGroupID: Integer </td></tr>
<tr><td> 6216 </td><td> <code>OnMarketTrade</code> </td><td> Occurs when a trade happens in a market (at the moment when resources are exchanged by serfs). </td><td> aHouseID: Integer; //HouseID of market <br> aFromWare: Integer; //From resource in the trade <br> aToWare: Integer; //To resource in the trade </td></tr>
<tr><td> 5057 </td><td> <code>OnMissionStart</code> </td><td> Occurs immediately after the mission is loaded </td><td>  </td></tr>
<tr><td> 5964 </td><td> <code>OnPlanRoadPlaced</code> </td><td> Occurs when a player places a road plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 6301 </td><td> <code>OnPlanRoadRemoved</code> </td><td> Occurs when a player removes a road plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 5964 </td><td> <code>OnPlanFieldPlaced</code> </td><td> Occurs when a player places a field plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 6301 </td><td> <code>OnPlanFieldRemoved</code> </td><td> Occurs when a player removes a field plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 5964 </td><td> <code>OnPlanWinefieldPlaced</code> </td><td> Occurs when a player places a winefield plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 6301 </td><td> <code>OnPlanWinefieldRemoved</code> </td><td> Occurs when a player removes a winefield plan </td><td> aIndex: Integer; //Index of the player <br> X: Integer; //X coordinate of the plan <br> Y: Integer; //Y coordinate of the plan <br> </td></tr>
<tr><td> 5057 </td><td> <code>OnPlayerDefeated</code> </td><td> Occurs when certain player has been defeated. Defeat conditions are checked separately by Player AI </td><td> aIndex: Integer; //Index of defeated player </td></tr>
<tr><td> 5057 </td><td> <code>OnPlayerVictory</code> </td><td> Occurs when certain player is declared victorious. Victory conditions are checked separately by Player AI </td><td> aIndex: Integer; //Index of victorious player </td></tr>
<tr><td> 5057 </td><td> <code>OnTick</code> </td><td> Occurs every game logic update </td><td>  </td></tr>
<tr><td> 6114 </td><td> <code>OnUnitAfterDied</code> </td><td> Occurs after a unit has died and has been completely removed from the game, meaning the tile it previously occupied can be used. If you need more information about the unit use the OnUnitDied event. Note: Because units have a death animation there is a delay of several ticks between OnUnitDied and OnUnitAfterDied. </td><td> aUnitType: Integer; //Type of the unit <br> aOwner: Integer; //Index of player who owned it <br> aX: Integer; //X coordinate of the unit <br> aY: Integer; //Y coordinate of the unit </td></tr>
<tr><td> 6587 </td><td> <code>OnUnitAttacked</code> </td><td> Happens when a unit is attacked (shot at by archers or hit in melee). Attacker is always a warrior (could be archer or melee). This event will occur very frequently during battles. </td><td> aUnitID: Integer; //UnitID who was attacked <br> AttackerID: Integer; //Warrior who attacked the unit </td></tr>
<tr><td> 5407 </td><td> <code>OnUnitDied</code> </td><td> Occurs when a unit dies. If KillerIndex is -1 the unit died from another cause such as hunger or Actions.UnitKill. Called just before the unit is killed so UnitID is usable only during this event, and the tile occupied by the unit is still taken. </td><td> aUnitID: Integer; //UnitID of the unit that was killed <br> aKillerIndex: Integer; //Index of player who killed it </td></tr>
<tr><td> 5057 </td><td> <code>OnUnitTrained</code> </td><td> Occurs when player trains a unit </td><td> aUnitID: Integer; //UnitID of the unit that was trained </td></tr>
<tr><td> 5884 </td><td> <code>OnUnitWounded</code> </td><td> Happens when unit is wounded. Attacker can be a warrior, recruit in tower or unknown (-1) </td><td> aUnitID: Integer; //UnitID who was wounded <br> AttackerID: Integer; //Unit who attacked the unit </td></tr>
<tr><td> 5057 </td><td> <code>OnWarriorEquipped</code> </td><td> Occurs when player equips a warrior </td><td> aUnitID: Integer; //UnitID of the warrior that was equipped <br> aGroupID: Integer; //GroupID of the warrior that was equipped </td></tr></tbody></table>

Events are written in a form <b>procedure EVENT_NAME(EVENT_PARAMETERS);</b> like so:<br>
<pre><code>procedure OnHouseBuilt(aHouseID: Integer);<br>
begin<br>
  //code<br>
end;<br>
</code></pre>

<h3>States</h3>
All states parameters are numeric and get mapped to unit/house types according to default tables used in DAT scripts.<br>
<br>
<table><thead><th> Version </th><th> State </th><th> Description </th><th> Query parameters </th><th> Type of return value </th></thead><tbody>
<tr><td> - </td><td> <code>FindUnitInZone</code> </td></tr>
<tr><td> 6216 </td><td> <code>ClosestGroup</code> </td><td> Returns the group of the specified player and group type that is closest to the specified coordinates, or -1 if no such group was found. If the group type is -1 any group type will be accepted </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Group type </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>ClosestHouse</code> </td><td> Returns the house of the specified player and house type that is closest to the specified coordinates, or -1 if no such house was found. If the house type is -1 any house type will be accepted </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - House type </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>ClosestUnit</code> </td><td> Returns the unit of the specified player and unit type that is closest to the specified coordinates, or -1 if no such unit was found. If the unit type is -1 any unit type will be accepted </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Unit type </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>ClosestGroupMultipleTypes</code> </td><td> Returns the group of the specified player and group types that is closest to the specified coordinates, or -1 if no such group was found. The group types is a "set of Byte", for example [1,3] </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Group types </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>ClosestHouseMultipleTypes</code> </td><td> Returns the house of the specified player and house types that is closest to the specified coordinates, or -1 if no such house was found. The house types is a "set of Byte", for example [11,13,21] </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - House types </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>ClosestUnitMultipleTypes</code> </td><td> Returns the unit of the specified player and unit types that is closest to the specified coordinates, or -1 if no such unit was found. The unit types is a "set of Byte", for example [0,9] </td><td>1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Unit types </td><td> Integer </td></tr>
<tr><td> 6602 </td><td> <code>ConnectedByRoad</code> </td><td> Check if two tiles are connected by walkable road </td><td>1 - X1 <br> 2 - Y1 <br> 3 - X2 <br> 4 - Y2 </td><td> Boolean </td></tr>
<tr><td> 6602 </td><td> <code>ConnectedByWalking</code> </td><td> Check if two tiles are connected by a walkable route </td><td>1 - X1 <br> 2 - Y1 <br> 3 - X2 <br> 4 - Y2 </td><td> Boolean </td></tr>
<tr><td> 5097 </td><td> <code>FogRevealed</code> </td><td> Check if a tile is revealed in fog of war for a player </td><td>1 - player index <br> 2 - X <br> 3 - Y </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>GameTime</code> </td><td> Get the number of game ticks since mission start </td><td> - </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>GroupAt</code> </td><td> Returns the ID of the group of the unit on the specified tile or -1 if no group exists there </td><td> 1 - X coordinate <br> 2 - Y coordinate </td><td> Integer </td></tr>
<tr><td> 5272 </td><td> <code>GroupColumnCount</code> </td><td> Returns the number of columns (units per row) of the specified group </td><td> 1 - Group ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>GroupDead</code> </td><td> Returns true if the group is dead (all members dead or joined other groups) </td><td> 1 - Group ID </td><td> Boolean </td></tr>
<tr><td> 6523 </td><td> <code>GroupIdle</code> </td><td> Returns true if specified group is idle (has no orders/action) </td><td> 1 - Group ID  </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>GroupMember</code> </td><td> Returns the unit ID of the specified group member. Member 0 will be the flag holder, 1...GroupMemberCount-1 will be the other members (0 <= MemberIndex <= GroupMemberCount-1) </td><td> 1 - Group ID <br> 2 - Member index </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>GroupMemberCount</code> </td><td> Returns the total number of members of the specified group </td><td> 1 - Group ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>GroupOwner</code> </td><td> Returns the owner of the specified group or -1 if Group ID invalid </td><td> 1 - Group ID </td><td> Integer </td></tr>
<tr><td> 5932 </td><td> <code>GroupType</code> </td><td> Returns the type of the specified group or -1 if Group ID invalid </td><td> 1 - Group ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HouseAt</code> </td><td> Returns the ID of the house at the specified location or -1 if no house exists there </td><td> 1 - X coordinate <br> 2 - Y coordinate </td><td> Integer </td></tr>
<tr><td> 6516 </td><td> <code>HouseBarracksRallyPointX</code> </td><td> Returns X coordinate of Rally Point of specified barracks or 0 if BarracksID is invalid </td><td> 1 - Barracks ID </td><td> Integer </td></tr>
<tr><td> 6516 </td><td> <code>HouseBarracksRallyPointY</code> </td><td> Returns Y coordinate of Rally Point of specified barracks or 0 if BarracksID is invalid </td><td> 1 - Barracks ID </td><td> Integer </td></tr>
<tr><td> 6285 </td><td> <code>HouseBuildingProgress</code> </td><td> Returns building progress of the specified house </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5993 </td><td> <code>HouseCanReachResources</code> </td><td> Returns true if the specified house can reach the resources that it mines (coal, stone, fish, etc.) </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>HouseDamage</code> </td><td> Returns the damage of the specified house or -1 if House ID invalid </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HouseDeliveryBlocked</code> </td><td> Returns true if the specified house has delivery disabled </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>HouseDestroyed</code> </td><td> Returns true if the house is destroyed </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>HouseHasOccupant</code> </td><td> Returns true if the specified house currently has an occupant </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5345 </td><td> <code>HouseIsComplete</code> </td><td> Returns true if the specified house is fully built </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 6284 </td><td> <code>HouseTypeMaxHealth</code> </td><td> Returns max health of the specified house type </td><td> 1 - House type </td><td> Integer </td></tr>
<tr><td> 5345 </td><td> <code>HouseTypeToOccupantType</code> </td><td> Returns the type of unit that should occupy the specified type of house, or -1 if no unit should occupy it. </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HouseOwner</code> </td><td> Returns the owner of the specified house or -1 if House ID invalid </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HousePositionX</code> </td><td> Returns the X coordinate of the specified house or -1 if House ID invalid </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HousePositionY</code> </td><td> Returns the Y coordinate of the specified house or -1 if House ID invalid </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>HouseRepair</code> </td><td> Returns true if the specified house has repair enabled </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>HouseResourceAmount</code> </td><td> Returns the amount of the specified resource in the specified house </td><td> 1 - House ID <br> 2 - Resource type </td><td> Integer </td></tr>
<tr><td> 5165 </td><td> <code>HouseSchoolQueue</code> </td><td> Returns the unit type in the specified slot of the school queue. Slot 0 is the unit currently training, slots 1..5 are the queue. </td><td> 1 - House ID <br> 2 - slot </td><td> Integer </td></tr>
<tr><td> 6510 </td><td> <code>HouseSiteIsDigged</code> </td><td> Returns true if specified WIP house area is digged </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>HouseType</code> </td><td> Returns the type of the specified house </td><td> 1 - House ID </td><td> Integer </td></tr>
<tr><td> 6001 </td><td> <code>HouseTypeName</code> </td><td> Returns the the translated name of the specified house type. Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup which is decoded on output, not the actual translated text. Therefore string operations like LowerCase will not work. </td><td> 1 - House type </td><td> AnsiString </td></tr>
<tr><td> 6220 </td><td> <code>HouseUnlocked</code> </td><td> Returns true if the specified player can build the specified house type (unlocked and allowed). </td><td> 1 - Player index <br> 2 - House type </td><td> Boolean </td></tr>
<tr><td> 5099 </td><td> <code>HouseWareBlocked</code> </td><td> Returns true if the specified ware in the specified storehouse or barracks is blocked </td><td> 1 - House ID <br> 2 - ware type </td><td> Boolean </td></tr>
<tr><td> 5165 </td><td> <code>HouseWeaponsOrdered</code> </td><td> Returns the number of the specified weapon ordered to be produced in the specified house </td><td> 1 - House ID <br> 2 - ware type </td><td> Integer </td></tr>
<tr><td> 5099 </td><td> <code>HouseWoodcutterChopOnly</code> </td><td> Returns true if the specified woodcutter's hut is on chop-only mode </td><td> 1 - House ID </td><td> Boolean </td></tr>
<tr><td> 5345 </td><td> <code>IsFieldAt</code> </td><td> Returns true if the specified player has a corn field at the specified location. If player index is -1 it will return true if any player has a corn field at the specified tile </td><td> 1 - player index <br> 2 - X <br> 3 - Y </td><td> Boolean </td></tr>
<tr><td> 5345 </td><td> <code>IsWinefieldAt</code> </td><td> Returns true if the specified player has a winefield at the specified location. If player index is -1 it will return true if any player has a winefield at the specified tile </td><td> 1 - player index <br> 2 - X <br> 3 - Y </td><td> Boolean </td></tr>
<tr><td> 5345 </td><td> <code>IsRoadAt</code> </td><td> Returns true if the specified player has a road at the specified location. If player index is -1 it will return true if any player has a road at the specified tile </td><td> 1 - player index <br> 2 - X <br> 3 - Y </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>KaMRandom</code> </td><td> Returns a random single (float) such that: 0 <= Number < 1.0 </td><td>  </td><td> Single </td></tr>
<tr><td> 5057 </td><td> <code>KaMRandomI</code> </td><td> Returns a random integer such that: 0 <= Number < LimitPlusOne </td><td> 1 - LimitPlusOne </td><td> Integer </td></tr>
<tr><td> 6611 </td><td> <code>LocationCount</code> </td><td> Returns the number of player locations available on the map (including AIs), regardless of whether the location was taken in multiplayer (use PlayerEnabled to check if a location is being used) </td><td>  </td><td> Integer </td></tr>
<tr><td> 6587 </td><td> <code>MapTileHeight</code> </td><td> Returns the height of the terrain at the top left corner (vertex) of the tile at the specified XY coordinates. Return value range is 0..100 </td><td> 1 - X <br> 2 - Y </td><td> Integer </td></tr>
<tr><td> 6587 </td><td> <code>MapTileObject</code> </td><td> Returns the terrain object ID on the tile at the specified XY coordinates. Object IDs can be seen in the map editor on the objects tab. Object 61 is "block walking". Return value range is 0..255. If there is no object on the tile, the result will be 255. </td><td> 1 - X <br> 2 - Y </td><td> Integer </td></tr>
<tr><td> 6587 </td><td> <code>MapTileRotation</code> </td><td> Returns the rotation of the tile at the specified XY coordinates. Return value range is 0..3 </td><td> 1 - X <br> 2 - Y </td><td> Integer </td></tr>
<tr><td> 6587 </td><td> <code>MapTileType</code> </td><td> Returns the tile type ID of the tile at the specified XY coordinates. Tile IDs can be seen by hovering over the tiles on the terrain tiles tab in the map editor. Return value range is 0..255 </td><td> 1 - X <br> 2 - Y </td><td> Integer </td></tr>
<tr><td> 6613 </td><td> <code>MapWidth</code> </td><td> Returns the width of the map </td><td>  </td><td> Integer </td></tr>
<tr><td> 6613 </td><td> <code>MapHeight</code> </td><td> Returns the height of the map </td><td>  </td><td> Integer </td></tr>
<tr><td> 6287 </td><td> <code>MarketFromWare</code> </td><td> Returns type of FromWare in specified market, or -1 if no ware is selected </td><td> 1 - Market ID </td><td> Integer </td></tr>
<tr><td> 6217 </td><td> <code>MarketLossFactor</code> </td><td> Returns the factor of resources lost during market trading, used to calculate the TradeRatio (see explanation in <code>MarketValue</code>). This value is constant within one KaM Remake release, but may change in future KaM Remake releases </td><td>  </td><td> Single </td></tr>
<tr><td> 6287 </td><td> <code>MarketOrderAmount</code> </td><td> Returns trade order amount in specified market </td><td> 1 - Market ID </td><td> Integer </td></tr>
<tr><td> 6287 </td><td> <code>MarketToWare</code> </td><td> Returns type of ToWare in specified market, or -1 if no ware is selected </td><td> 1 - Market ID </td><td> Integer </td></tr>
<tr><td> 6216 </td><td> <code>MarketValue</code> </td><td> Returns the relative market value of the specified resource type, which is a rough indication of the cost to produce that resource. These values are constant within one KaM Remake release, but may change in future KaM Remake releases. The TradeRatio is calculated as: <code>MarketLossFactor * MarketValue(To) / (MarketValue(From)</code>. If the TradeRatio is >= 1, then the number of <i>From</i> resources required to receive 1 <i>To</i> resource is: <code>Round(TradeRatio)</code>. If the trade ratio is < 1 then the number of <i>To</i> resources received for trading 1 <i>From</i> resource is: <code>Round(1 / TradeRatio)</code> </td><td> 1 - Resource type </td><td> Single </td></tr>
<tr><td> 5057 </td><td> <code>PeaceTime</code> </td><td> Length of peacetime in ticks (multiplayer) </td><td> - </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>PlayerAllianceCheck</code> </td><td> Check how player 1 feels towards player 2 (order matters). Returns true for ally, false for enemy </td><td>1 - player index <br> 2 - player index </td><td> Boolean </td></tr>
<tr><td> 4758 </td><td> <code>PlayerColorText</code> </td><td> Get players color as text in hex format </td><td> 1 - player index </td><td> AnsiString </td></tr>
<tr><td> 5057 </td><td> <code>PlayerDefeated</code> </td><td> See if player was defeated </td><td> 1 - player index </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlayerEnabled</code> </td><td> Will be false if nobody selected that location in multiplayer </td><td> 1 - player index </td><td> Boolean </td></tr>
<tr><td> 5165 </td><td> <code>PlayerGetAllUnits</code> </td><td> Returns an array with IDs for all the units of the specified player </td><td> 1 - player index </td><td> array of Integer </td></tr>
<tr><td> 5209 </td><td> <code>PlayerGetAllHouses</code> </td><td> Returns an array with IDs for all the houses of the specified player </td><td> 1 - player index </td><td> array of Integer </td></tr>
<tr><td> 5209 </td><td> <code>PlayerGetAllGroups</code> </td><td> Returns an array with IDs for all the groups of the specified player </td><td> 1 - player index </td><td> array of Integer </td></tr>
<tr><td> 5927 </td><td> <code>PlayerIsAI</code> </td><td> Wherever player is controlled by AI </td><td> 1 - player index </td><td> !Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlayerName</code> </td><td> Get name of player as a string (for multiplayer) </td><td> 1 - player index </td><td> AnsiString </td></tr>
<tr><td> 4545 </td><td> <code>PlayerVictorious</code> </td><td> See if player is victorious </td><td> 1 - player index </td><td> Boolean </td></tr>
<tr><td> 5345 </td><td> <code>PlayerWareDistribution</code> </td><td> Returns the ware distribution for the specified resource, house and player </td><td> 1 - player index <br> 2 - Resource type <br> 3 - House type </td><td> Integer </td></tr>
<tr><td> 6323 </td><td> <code>StatAIDefencePositionsCount</code> </td><td> How many defence positions AI player has. Useful for scripts like "if not enough positions and too much groups then add a new position" </td><td> 1 - player index </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatArmyCount</code> </td><td> How many military units player has </td><td> 1 - player index </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatCitizenCount</code> </td><td> How many citizen player has </td><td> 1 - player index </td><td> Integer </td></tr>
<tr><td> 6328 </td><td> <code>StatHouseMultipleTypesCount</code> </td><td> Returns number of specified house types for specified player. Types is a set of byte, f.e. [11, 13, 21] </td><td> 1 - player index  <br> 2 - Types - Set of byte </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatHouseTypeCount</code> </td><td> Specified house type count </td><td> 1 - player index  <br> 2 - house type </td><td> Integer </td></tr>
<tr><td> 6313 </td><td> <code>StatHouseTypePlansCount</code> </td><td> Specified house type plans count </td><td> 1 - player index  <br> 2 - house type </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatPlayerCount</code> </td><td> How many active players there are </td><td> - </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatResourceProducedCount</code> </td><td> Returns the number of the specified resource produced by the specified player </td><td> 1 - Player index <br> 2 - Resource type </td><td> Integer </td></tr>
<tr><td> 6331 </td><td> <code>StatResourceProducedMultipletypesCount</code> </td><td> Returns the number of the specified resource types produced by the specified player. Types is a set of byte, f.e. [8, 10, 13, 27] for food </td><td> 1 - Player index <br> 2 - Resource types - set of byte </td><td> Integer </td></tr>
<tr><td> 4289 </td><td> <code>StatUnitCount</code> </td><td> Returns the number of units of the specified player </td><td> 1 - Player index </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatUnitKilledCount</code> </td><td> Returns the number of the specified unit killed by the specified player </td><td> 1 - Player index <br> 2 - Unit type </td><td> Integer </td></tr>
<tr><td> 6331 </td><td> <code>StatUnitKilledMultipleTypesCount</code> </td><td> Returns the number of the specified unit types killed by the specified player. Types is a set of byte, f.e. [0, 5, 13] </td><td> 1 - Player index <br> 2 - Unit types - set of byte </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatUnitLostCount</code> </td><td> Returns the number of the specified unit lost by the specified player </td><td> 1 - Player index <br> 2 - Unit type </td><td> Integer </td></tr>
<tr><td> 6331 </td><td> <code>StatUnitLostMultipleTypesCount</code> </td><td> Returns the number of the specified unit types lost by the specified player. Types is a set of byte, f.e. [0, 5, 13] </td><td> 1 - Player index <br> 2 - Unit types - set of byte </td><td> Integer </td></tr>
<tr><td> 6328 </td><td> <code>StatUnitMultipleTypesCount</code> </td><td> Returns number of specified unit types for specified player. Types is a set of byte, f.e. [0, 5, 13] </td><td> 1 - player index  <br> 2 - Types - Set of byte </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>StatUnitTypeCount</code> </td><td> Specified unit type count </td><td> 1 - player index  <br> 2 - unit type </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitAt</code> </td><td> Returns the ID of the unit on the specified tile or -1 if no unit exists there </td><td> 1 - X coordinate <br> 2 - Y coordinate </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitCarrying</code> </td><td> Returns the ware a serf is carrying, or -1 if the unit is not a serf or is not carrying anything </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitDead</code> </td><td> Returns true if the unit is dead </td><td> 1 - Unit ID </td><td> Boolean </td></tr>
<tr><td> 5165 </td><td> <code>UnitDirection</code> </td><td> Returns the direction the specified unit is facing </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5997 </td><td> <code>UnitHome</code> </td><td> Returns the ID of the house which is the home of the specified unit or -1 if the unit does not have a home </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitHunger</code> </td><td> Returns the hunger level of the specified unit as number of ticks until death or -1 if Unit ID invalid </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 6523 </td><td> <code>UnitIdle</code> </td><td> Returns true if specified unit is idle (has no orders/action) </td><td> 1 - Unit ID  </td><td> Boolean </td></tr>
<tr><td> 5057 </td><td> <code>UnitLowHunger</code> </td><td> Gives the hunger level when a unit will try to eat in ticks until death </td><td>  </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitMaxHunger</code> </td><td> Gives the maximum hunger level a unit can have in ticks until death </td><td>  </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitOwner</code> </td><td> Returns the owner of the specified unit or -1 if Unit ID invalid </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitPositionX</code> </td><td> Returns the X coordinate of the specified unit or -1 if Unit ID invalid </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitPositionY</code> </td><td> Returns the Y coordinate of the specified unit or -1 if Unit ID invalid </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitsGroup</code> </td><td> Returns the group that the specified unit (warrior) belongs to or -1 if it does not belong to a group </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 5057 </td><td> <code>UnitType</code> </td><td> Returns the type of the specified unit </td><td> 1 - Unit ID </td><td> Integer </td></tr>
<tr><td> 6001 </td><td> <code>UnitTypeName</code> </td><td> Returns the the translated name of the specified unit type. Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup which is decoded on output, not the actual translated text. Therefore string operations like LowerCase will not work. </td><td> 1 - Unit type </td><td> AnsiString </td></tr>
<tr><td> 6001 </td><td> <code>WareTypeName</code> </td><td> Returns the the translated name of the specified ware type. Note: To ensure multiplayer consistency the name is returned as a number encoded within a markup which is decoded on output, not the actual translated text. Therefore string operations like LowerCase will not work. </td><td> 1 - Ware type </td><td> AnsiString </td></tr></tbody></table>

States are queried in a form <b>States.STATE_NAME(STATE_PARAMETERS)</b> like so:<br>
<pre><code>if States.PlayerCount &gt; 5 then<br>
  A := States.UnitCount(1);<br>
</code></pre>

<h3>Actions</h3>
All action parameters are numeric and get mapped to unit/house types according to default tables used in DAT scripts.<br>
<br>
<table><thead><th> Version </th><th> Action </th><th> Description </th><th> Parameters (Integer) </th><th> Return value () </th></thead><tbody>
<tr><td> 6251 </td><td> <code>AIAutoAttackRange</code> </td><td> Sets AI auto attack range. AI groups will automatically attack if you are closer than this many tiles. </td><td> 1 - player index <br> 2 - range (1 to 20) </td></tr>
<tr><td> 5924 </td><td> <code>AIAutoBuild</code> </td><td> Sets whether the AI should build and manage his own village </td><td> 1 - player index <br> 2 - Enabled: Boolean </td></tr>
<tr><td> 5924 </td><td> <code>AIAutoDefence</code> </td><td> Sets whether the AI should position his soldiers automatically </td><td> 1 - player index <br> 2 - Enabled: Boolean </td></tr>
<tr><td> 5932 </td><td> <code>AIAutoRepair</code> </td><td> Sets whether the AI should automatically repair damaged buildings </td><td> 1 - player index <br> 2 - Enabled: Boolean </td></tr>
<tr><td> 5932 </td><td> <code>AIDefencePositionAdd</code> </td><td> Adds a defence position for the specified AI player </td><td> 1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Direction <br> 5 - Group type <br> 6 - Radius <br> 7 - Defence type </td><td>  </td></tr>
<tr><td> 6309 </td><td> <code>AIDefencePositionRemove</code> </td><td> Removes defence position at X, Y</td><td> 1 - player index <br> 2 - X <br> 3 - Y <br> </td></tr>
<tr><td> 6323 </td><td> <code>AIDefencePositionRemoveAll</code> </td><td> Removes all defence positions for specified AI player </td><td> 1 - player index </td></tr>
<tr><td> 6251 </td><td> <code>AIDefendAllies</code> </td><td> Sets whether AI should defend units and houses of allies as if they were its own </td><td> 1 - player index <br> 2 - Defend: Boolean </td></tr>
<tr><td> 5778 </td><td> <code>AIEquipRate</code> </td><td> Sets the warriors equip rate for AI. (type: 0 - leather, 1 - iron) </td><td> 1 - player index <br> 2 - type <br> 3 - rate </td></tr>
<tr><td> 5778 </td><td> <code>AIGroupsFormationSet</code> </td><td> Sets the formation the AI uses for defence positions </td><td> 1 - player index <br> 2 - Group type <br> 3 - Units <br> 4 - Columns </td></tr>
<tr><td> 5932 </td><td> <code>AISoldiersLimit</code> </td><td> Sets the maximum number of soldiers the AI will train, or -1 for unlimited </td><td> 1 - player index <br> 2 - count </td></tr>
<tr><td> 5924 </td><td> <code>AIRecruitDelay</code> </td><td> Sets the number of ticks before the specified AI will start training recruits </td><td> 1 - player index <br> 2 - delay in ticks </td></tr>
<tr><td> 5345 </td><td> <code>AIRecruitLimit</code> </td><td> Sets the number of recruits the AI will keep in each barracks </td><td> 1 - player index <br> 2 - recruit limit </td></tr>
<tr><td> 5924 </td><td> <code>AISerfsPerHouse</code> </td><td> Sets the number of serfs the AI will train per house. Can be a decimal (0.25 for 1 serf per 4 houses) </td><td> 1 - player index <br> 2 - value (float) </td></tr>
<tr><td> 6251 </td><td> <code>AIStartPosition</code> </td><td> Sets the AI start position which is used for targeting AI attacks </td><td> 1 - player index <br> 2 - X <br> 3 - Y </td></tr>
<tr><td> 5924 </td><td> <code>AIWorkerLimit</code> </td><td> Sets the maximum number of laborers the AI will train </td><td> 1 - player index <br> 2 - count </td></tr>
<tr><td> 5938 </td><td> <code>CinematicStart</code> </td><td> Puts the player in cinematic mode, blocking user input and allowing the screen to be panned </td><td> 1 - player index </td></tr>
<tr><td> 5938 </td><td> <code>CinematicEnd</code> </td><td> Exits cinematic mode </td><td> 1 - player index </td></tr>
<tr><td> 5938 </td><td> <code>CinematicPanTo</code> </td><td> Pans the center of the player's screen to the given location over a set number of ticks. If Duration = 0 then the screen moves instantly. </td><td> 1 - player index <br> 2 - X <br> 3 - Y <br> 4 - Duration </td></tr>
<tr><td> 5097 </td><td> <code>FogCoverAll</code> </td><td> Covers (un-reveals) the entire map in fog of war for player </td><td> 1 - player index </td></tr>
<tr><td> 5097 </td><td> <code>FogCoverCircle</code> </td><td> Covers (un-reveals) a circle in fog of war for player </td><td> 1 - player index <br> 2 - location X <br> 3 - location Y <br> 4 - radius </td></tr>
<tr><td> 5777 </td><td> <code>FogCoverRect</code> </td><td> Covers a rectangular area in fog of war for player </td><td> 1 - player index <br> 2 - from X <br> 3 - from Y <br> 4 - to X <br> 5 - to Y </td></tr>
<tr><td> 5097 </td><td> <code>FogRevealAll</code> </td><td> Reveals the entire map in fog of war for player </td><td> 1 - player index </td></tr>
<tr><td> 5097 </td><td> <code>FogRevealCircle</code> </td><td> Reveals a circle in fog of war for player </td><td> 1 - player index <br> 2 - location X <br> 3 - location Y <br> 4 - radius </td></tr>
<tr><td> 5777 </td><td> <code>FogRevealRect</code> </td><td> Reveals a rectangular area in fog of war for player </td><td> 1 - player index <br> 2 - from X <br> 3 - from Y <br> 4 - to X <br> 5 - to Y </td></tr>
<tr><td> 5057 </td><td> <code>GiveAnimal</code> </td><td> Adds an animal to the game and returns the unit ID or -1 if the animal was not able to be added </td><td> 1 - Animal type <br> 2 - location X <br> 3 - location Y </td><td> UnitID: Integer </td></tr>
<tr><td> 6311 </td><td> <code>GiveField</code> </td><td> Adds finished field and returns true if field was successfully added </td><td> 1 - Player ID <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>GiveGroup</code> </td><td> Give player group of warriors and return the group ID or -1 if the group was not able to be added </td><td> 1 - player index <br> 2 - Unit type <br> 3 - location X <br> 4 - location Y <br> 5 - face direction <br> 6 - unit count <br> 7 - units per row </td><td> GroupID: Integer </td></tr>
<tr><td> 5097 </td><td> <code>GiveHouse</code> </td><td> Give player a built house and returns the house ID or -1 if the house was not able to be added </td><td> 1 - player index <br> 2 - House type <br> 3 - location X <br> 4 - location Y </td><td> HouseID: Integer </td></tr>
<tr><td> 6288 </td><td> <code>GiveHouseSite</code> </td><td> Give player a digged house area and returns House ID or -1 if house site was not able to be added. If AddMaterials = True, wood and stone will be added </td><td> 1 - player index <br> 2 - House type <br> 3 - location X <br> 4 - location Y<br> 5 - AddMaterials: Boolean </td><td> HouseID: Integer </td></tr>
<tr><td> 6311 </td><td> <code>GiveRoad</code> </td><td> Adds finished road and returns true if road was successfully added </td><td> 1 - Player ID <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>GiveUnit</code> </td><td> Give player a single citizen and returns the unit ID or -1 if the unit was not able to be added </td><td> 1 - player index <br> 2 - Unit type <br> 3 - location X <br> 4 - location Y <br> 5 - face direction </td><td> UnitID: Integer </td></tr>
<tr><td> 5057 </td><td> <code>GiveWares</code> </td><td> Adds amount of wares to players 1st Store </td><td> 1 - player index <br> 2 - ware type <br> 3 - count </td></tr>
<tr><td> 5165 </td><td> <code>GiveWeapons</code> </td><td> Adds amount of weapons to players 1st Barracks </td><td> 1 - player index <br> 2 - ware type <br> 3 - count </td></tr>
<tr><td> 6311 </td><td> <code>GiveWineField</code> </td><td> Adds finished winefield and returns true if winefield was successfully added </td><td> 1 - Player ID <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 6277 </td><td> <code>GroupBlockOrders</code> </td><td> Disables (Disable = True) or enables (Disable = False) control over specifed warriors group </td><td> 1 - Group ID <br> 2 - Disable: Boolean </td></tr>
<tr><td> 5993 </td><td> <code>GroupDisableHungryMessage</code> </td><td> Sets whether the specified group will alert the player when they become hungry (true to disable hunger messages, false to enable them) </td><td> 1 - Group ID <br> 2 - Disabled: Boolean </td></tr>
<tr><td> 5993 </td><td> <code>GroupHungerSet</code> </td><td> Set hunger level for all group members </td><td> 1 - Group ID <br> 2 - Hunger level (ticks until death) </td></tr>
<tr><td> 5993 </td><td> <code>GroupKillAll</code> </td><td> Kills all members of the specified group </td><td> 1 - Group ID <br> 2 - Silent: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderAttackHouse</code> </td><td> Order the specified group to attack the specified house </td><td> 1 - Group ID <br> 2 - House ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderAttackUnit</code> </td><td> Order the specified group to attack the specified unit </td><td> 1 - Group ID <br> 2 - Unit ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderFood</code> </td><td> Order the specified group to request food </td><td> 1 - Group ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderHalt</code> </td><td> Order the specified group to halt </td><td> 1 - Group ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderLink</code> </td><td> Order the first specified group to link to the second specified group </td><td> 1 - Group ID <br> 2 - Group ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderSplit</code> </td><td> Order the specified group to split in half and return the newly create group ID or -1 if splitting failed (e.g. only 1 member) </td><td> 1 - Group ID </td><td> NewGroupID: Integer </td></tr>
<tr><td> 6338 </td><td> <code>GroupOrderSplitUnit</code> </td><td> Splits specified unit from the group  and returns the newly create group ID or -1 if splitting failed (e.g. only 1 member) </td><td> 1 - Group ID<br> 2 - Unit ID</td><td> NewGroupID: Integer </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderStorm</code> </td><td> Order the specified group to storm attack </td><td> 1 - Group ID </td></tr>
<tr><td> 5057 </td><td> <code>GroupOrderWalk</code> </td><td> Order the specified group to walk somewhere </td><td> 1 - Group ID <br> 2 - X <br> 3 - Y <br> 4 - Direction </td></tr>
<tr><td> 5057 </td><td> <code>GroupSetFormation</code> </td><td> Sets the number of columns (units per row) for the specified group </td><td> 1 - Group ID <br> 2 - Columns </td></tr>
<tr><td> 6510 </td><td> <code>HouseAddBuildingMaterials</code> </td><td> Add building materials to the specified WIP house area </td><td> 1 - House ID </td></tr>
<tr><td> 6297 </td><td> <code>HouseAddBuildingProgress</code> </td><td> Add 5 points of building progress to the specified WIP house area </td><td> 1 - House ID </td></tr>
<tr><td> 5057 </td><td> <code>HouseAddDamage</code> </td><td> Add damage to the specified house </td><td> 1 - House ID <br> 2 - Damage amount </td></tr>
<tr><td> 5441 </td><td> <code>HouseAddRepair</code> </td><td> Reduces damage to the specified house </td><td> 1 - House ID <br> 2 - Repair amount </td></tr>
<tr><td> 5057 </td><td> <code>HouseAddWaresTo</code> </td><td> Add wares to the specified house </td><td> 1 - House ID <br> 2 - ware type <br> 3 - count </td></tr>
<tr><td> 5057 </td><td> <code>HouseAllow</code> </td><td> Sets whether the player is allowed to build the specified house. Note: The house must still be unlocked normally (e.g. sawmill for farm), use HouseUnlock to override that. </td><td> 1 - player index <br> 2 - House type <br> 3 - Allowed: Boolean </td></tr>
<tr><td> 5174 </td><td> <code>HouseBarracksEquip</code> </td><td> Equips the specified unit from the specified barracks. Returns the number of units successfully equipped. </td><td> 1 - House ID <br> 2 - Unit type <br> 3 - Count </td><td> Succeeded: Integer </td></tr>
<tr><td> 6125 </td><td> <code>HouseBarracksGiveRecruit</code> </td><td> Adds a recruit inside the specified barracks </td><td> 1 - House ID </td></tr>
<tr><td> 5057 </td><td> <code>HouseDeliveryBlock</code> </td><td> Sets delivery blocking for the specified house </td><td> 1 - House ID <br> 2 - Blocked: Boolean </td></tr>
<tr><td> 5263 </td><td> <code>HouseDestroy</code> </td><td> Destroys the specified house. Silent means the house will not leave rubble or play destroy sound </td><td> 1 - House ID <br> 2 - Silent </td></tr>
<tr><td> 5345 </td><td> <code>HouseDisableUnoccupiedMessage</code> </td><td> Sets whether the specified house displays unoccupied messages to the player </td><td> 1 - House ID <br> 2 - Disabled: Boolean </td></tr>
<tr><td> - </td><td> <code>HouseOwnerSet</code> </td><td> Take house from one player and give it to another </td></tr>
<tr><td> 5057 </td><td> <code>HouseRepairEnable</code> </td><td> Enables house repair for the specified house </td><td> 1 - House ID <br> 2 - EnableRepair: Boolean </td></tr>
<tr><td> 5174 </td><td> <code>HouseSchoolQueueAdd</code> </td><td> Adds the specified unit to the specified school's queue. Returns the number of units successfully added to the queue. </td><td> 1 - House ID <br> 2 - Unit type <br> 3 - Count </td><td> Succeeded: Integer </td></tr>
<tr><td> 5174 </td><td> <code>HouseSchoolQueueRemove</code> </td><td> Removes the unit from the specified slot of the school queue. Slot 0 is the unit currently training, slots 1..5 are the queue. </td><td> 1 - House ID <br> 2 - slot </td></tr>
<tr><td> 6015 </td><td> <code>HouseTakeWaresFrom</code> </td><td> Remove wares from the specified house. If a serf was on the way to pick up the ware, the serf will abandon his task </td><td> 1 - House ID <br> 2 - ware type <br> 3 - count </td></tr>
<tr><td> 5057 </td><td> <code>HouseUnlock</code> </td><td> Allows player to build the specified house even if they don't have the house built that normally unlocks it (e.g. sawmill for farm). Note: Does not override blocked houses, use HouseAllow for that. </td><td> 1 - player index <br> 2 - House type </td></tr>
<tr><td> 5099 </td><td> <code>HouseWareBlock</code> </td><td> Blocks a specific ware in a storehouse or barracks </td><td> 1 - House ID <br> 2 - ware type <br> 3 - Blocked: Boolean </td></tr>
<tr><td> 5099 </td><td> <code>HouseWoodcutterChopOnly</code> </td><td> Sets whether a woodcutter's hut is on chop-only mode </td><td> 1 - House ID <br> 2 - ChopOnly: Boolean </td></tr>
<tr><td> 5165 </td><td> <code>HouseWeaponsOrderSet</code> </td><td> Sets the amount of the specified weapon ordered to be produced in the specified house </td><td> 1 - House ID <br> 2 - ware type <br> 3 - amount </td></tr>
<tr><td> 6067 </td><td> <code>Log</code> </td><td> Writes a line of text to the game log file. Useful for debugging. Note that many calls to this procedure will have a noticeable performance impact, as well as creating a large log file, so it is recommended you don't use it outside of debugging </td><td> 1 - Text: AnsiString </td></tr>
<tr><td> 6587 </td><td> <code>MapTileHeightSet</code> </td><td> Sets the height of the terrain at the top left corner (vertex) of the tile at the specified XY coordinates. Returns true if the change succeeded or false if it failed. The change will fail if it would cause a unit to become stuck or a house to be damaged </td><td> 1 - X <br> 2 - Y <br> 3 - height (0..100) </td><td> Boolean </td></tr>
<tr><td> 6587 </td><td> <code>MapTileObjectSet</code> </td><td> Sets the terrain object on the tile at the specified XY coordinates. Object IDs can be seen in the map editor on the objects tab. Object 61 is "block walking". To set no object, use object type 255. Returns true if the change succeeded or false if it failed. The change will fail if it would cause a unit to become stuck or a house/field to be damaged </td><td> 1 - X <br> 2 - Y <br> 3 - object type (0..255) </td><td> Boolean </td></tr>
<tr><td> 6587 </td><td> <code>MapTileSet</code> </td><td> Sets the tile type and rotation at the specified XY coordinates. Tile IDs can be seen by hovering over the tiles on the terrain tiles tab in the map editor. Returns true if the change succeeded or false if it failed. The change will fail if it would cause a unit to become stuck or a house/field to be damaged </td><td> 1 - X <br> 2 - Y <br> 3 - tile type (0..255) <br> 4 - tile rotation (0..3) </td><td> Boolean </td></tr>
<tr><td> 6216 </td><td> <code>MarketSetTrade</code> </td><td> Sets the trade in the specified market </td><td> 1 - House ID <br> 2 - from ware type <br> 3 - to ware type <br> 4 - amount </td></tr>
<tr><td> 5333 </td><td> <code>OverlayTextSet</code> </td><td> Sets text overlaid on top left of screen. If the player index is -1 it will be set for all players. </td><td> 1 - player index <br> 2 - text (AnsiString) </td></tr>
<tr><td> 5333 </td><td> <code>OverlayTextSetFormatted</code> </td><td> Sets text overlaid on top left of screen with formatted arguments (same as <a href='http://www.delphibasics.co.uk/RTL.asp?Name=Format'>Format</a> function). If the player index is -1 it will be set for all players. </td><td> 1 - player index <br> 2 - text (AnsiString) <br> 3 - Array of arguments </td></tr>
<tr><td> 5333 </td><td> <code>OverlayTextAppend</code> </td><td> Appends to text overlaid on top left of screen. If the player index is -1 it will be appended for all players. </td><td> 1 - player index <br> 2 - text (AnsiString) </td></tr>
<tr><td> 5333 </td><td> <code>OverlayTextAppendFormatted</code> </td><td> Appends to text overlaid on top left of screen with formatted arguments (same as <a href='http://www.delphibasics.co.uk/RTL.asp?Name=Format'>Format</a> function). If the player index is -1 it will be appended for all players. </td><td> 1 - player index <br> 2 - text (AnsiString) <br> 3 - Array of arguments </td></tr>
<tr><td> 5057 </td><td> <code>PlanAddField</code> </td><td> Adds a corn field plan. Returns true if the plan was successfully added or false if it failed (e.g. tile blocked) </td><td> 1 - Player index <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlanAddHouse</code> </td><td> Adds a house plan. Returns true if the plan was successfully added or false if it failed (e.g. location blocked) </td><td> 1 - Player index <br> 2 - House type <br> 3 - X <br> 4 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlanAddRoad</code> </td><td> Adds a road plan. Returns true if the plan was successfully added or false if it failed (e.g. tile blocked) </td><td> 1 - Player index <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlanAddWinefield</code> </td><td> Adds a wine field plan. Returns true if the plan was successfully added or false if it failed (e.g. tile blocked) </td><td> 1 - Player index <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 6303 </td><td> <code>PlanConnectRoad</code> </td><td> Connects road plans between two points like AI builder and returns True if road plan was successfully added. If CompletedRoad = True, road will be added instead of plans </td><td> 1 - Player index <br> 2 - X1 <br> 3 - Y1<br> 4 - X2<br> 5 - Y2<br> 6 - Completed road - Boolean </td><td> Success: Boolean </td></tr>
<tr><td> 5345 </td><td> <code>PlanRemove</code> </td><td> Removes house, road or field plans from the specified tile for the specified player </td><td> 1 - player index <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> 5165 </td><td> <code>PlayerAddDefaultGoals</code> </td><td> Add default goals/lost goals for the specified player. If the parameter buildings is true the goals will be important buildings. Otherwise it will be troops. </td><td> 1 - player index <br> 2 - buildings: Boolean </td></tr>
<tr><td> 5097 </td><td> <code>PlayerAllianceChange</code> </td><td> Change whether player1 is allied to player2. If Compliment is true, then it is set both ways (so also whether player2 is allied to player1) </td><td> 1 - player1 index <br> 2 - player2 index <br> 3 - Compliment: Boolean <br> 4 - Allied: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>PlayerDefeat</code> </td><td> Proclaims player defeated </td><td> 1 - player index </td></tr>
<tr><td> 5345 </td><td> <code>PlayerShareFog</code> </td><td> Sets whether player A shares his vision with player B. Sharing can still only happen between allied players, but this command lets you disable allies from sharing. </td><td> 1 - player A <br> 2 - player B <br> 3 - Share: Boolean </td></tr>
<tr><td> 5345 </td><td> <code>PlayerWareDistribution</code> </td><td> Sets ware distribution for the specified resource, house and player. </td><td> 1 - player index <br> 2 - resource type <br> 3 - house type <br> 4 - distribution amount (0..5) </td></tr>
<tr><td> 5057 </td><td> <code>PlayerWin</code> </td><td> Set specified player(s) victorious, and all team members of those player(s) if the 2nd parameter TeamVictory is set to true. All players who were not set to victorious are set to defeated. </td><td> 1 - array of player index <br> 2 - TeamVictory: Boolean </td></tr>
<tr><td> 5309 </td><td> <code>PlayWAV</code> </td><td> Plays audio file. If the player index is -1 the sound will be played to all players. Mono or stereo WAV files are supported. WAV file goes in mission folder named: Mission Name.filename.wav </td><td> 1 - player index <br> 2 - filename <br> 3 - Volume (0.0 to 1.0) </td></tr>
<tr><td> 6220 </td><td> <code>PlayWAVFadeMusic</code> </td><td> Same as <code>PlayWAV</code> except music will fade then mute while the WAV is playing, then fade back in afterwards. You should leave a small gap at the start of your WAV file to give the music time to fade </td><td> 1 - player index <br> 2 - filename <br> 3 - Volume (0.0 to 1.0) </td></tr>
<tr><td> 5309 </td><td> <code>PlayWAVAtLocation</code> </td><td> Plays audio file at a location on the map. If the player index is -1 the sound will be played to all players. Radius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use radius 32). Only mono WAV files are supported. WAV file goes in mission folder named: Mission Name.filename.wav. Will not play if the location is not revealed to the player. Higher volume range is allowed than <code>PlayWAV</code> as positional sounds are quieter </td><td> 1 - player index <br> 2 - filename <br> 3 - Volume (0.0 to 4.0) <br> 4 - Radius (minimum 28) <br> 5 - X <br> 6 - Y </td></tr>
<tr><td> 6222 </td><td> <code>PlayWAVLooped</code> </td><td> Plays looped audio file. If the player index is -1 the sound will be played to all players. Mono or stereo WAV files are supported. WAV file goes in mission folder named: Mission Name.filename.wav. The sound will continue to loop if the game is paused and will restart automatically when the game is loaded. Returns the LoopIndex of the sound which can be used to stop it with <code>Actions.StopLoopedWAV</code> </td><td> 1 - player index <br> 2 - filename <br> 3 - Volume (0.0 to 1.0) </td><td> LoopIndex: Integer </td></tr>
<tr><td> 6222 </td><td> <code>PlayWAVAtLocationLooped</code> </td><td> Plays looped audio file at a location on the map. If the player index is -1 the sound will be played to all players. Radius specifies approximately the distance at which the sound can no longer be heard (normal game sounds use radius 32). Only mono WAV files are supported. WAV file goes in mission folder named: Mission Name.filename.wav. Will not play if the location is not revealed to the player (will start playing automatically when it is revealed). Higher volume range is allowed than <code>PlayWAV</code> as positional sounds are quieter. The sound will continue to loop if the game is paused and will restart automatically when the game is loaded. Returns the LoopIndex of the sound which can be used to stop it with <code>Actions.StopLoopedWAV</code> </td><td> 1 - player index <br> 2 - filename <br> 3 - Volume (0.0 to 4.0) <br> 4 - Radius (minimum 28) <br> 5 - X <br> 6 - Y </td><td> LoopIndex: Integer </td></tr>
<tr><td> 5927 </td><td> <code>RemoveRoad</code> </td><td> Removes road </td><td> 1 - X <br> 2 - Y </td></tr>
<tr><td> 5057 </td><td> <code>SetTradeAllowed</code> </td><td> Sets whether the player is allowed to trade the specified resource. </td><td> 1 - player index <br> 2 - ware type <br> 3 - Allowed: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>ShowMsg</code> </td><td> Displays a message to a player. If the player index is -1 the message will be shown to all players. </td><td> 1 - player index <br> 2 - text (AnsiString) </td></tr>
<tr><td> 5345 </td><td> <code>ShowMsgGoto</code> </td><td> Displays a message to a player with a goto button that takes the player to the specified location. If the player index is -1 the message will be shown to all players. </td><td> 1 - player index <br> 2 - X <br> 3 - Y <br> 4 - text (AnsiString) </td></tr>
<tr><td> 5333 </td><td> <code>ShowMsgFormatted</code> </td><td> Displays a message to a player with formatted arguments (same as <a href='http://www.delphibasics.co.uk/RTL.asp?Name=Format'>Format</a> function). If the player index is -1 the message will be shown to all players. </td><td> 1 - player index <br> 2 - text (AnsiString) <br> 3 - Array of arguments </td></tr>
<tr><td> 5345 </td><td> <code>ShowMsgGotoFormatted</code> </td><td> Displays a message to a player with formatted arguments (same as <a href='http://www.delphibasics.co.uk/RTL.asp?Name=Format'>Format</a> function) and a goto button that takes the player to the specified location. If the player index is -1 the message will be shown to all players. </td><td> 1 - player index <br> 2 - X <br> 3 - Y <br> 4 - text (AnsiString) <br> 5 - Array of arguments </td></tr>
<tr><td> 6222 </td><td> <code>StopLoopedWAV</code> </td><td> Stops playing a looped sound that was previously started with either <code>Actions.PlayWAVLooped</code> or <code>Actions.PlayWAVAtLocationLooped</code>. LoopIndex is the value that was returned by either of those functions when the looped sound was started. </td><td> 1 - LoopIndex </td></tr>
<tr><td> 5993 </td><td> <code>UnitBlock</code> </td><td> Sets whether the specified player can train/equip the specified unit type </td><td> 1 - player index <br> 2 - Unit type <br> 3 - Block: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>UnitDirectionSet</code> </td><td> Makes the specified unit face a certain direction. Note: Only works on idle units so as not to interfere with game logic and cause crashes. Returns true on success or false on failure. </td><td> 1 - Unit ID <br> 2 - Direction </td><td> Success: Boolean </td></tr>
<tr><td> 5057 </td><td> <code>UnitHungerSet</code> </td><td> Sets the hunger level of the specified unit in ticks until death </td><td> 1 - Unit ID <br> 2 - Hunger level (ticks until death) </td></tr>
<tr><td> 5099 </td><td> <code>UnitKill</code> </td><td> Kills the specified unit. Silent means the death animation (ghost) and sound won't play </td><td> 1 - Unit ID <br> 2 - Silent: Boolean </td></tr>
<tr><td> - </td><td> <code>UnitLock</code> </td><td> Lock out the unit from game updates and make it manually scriptable (?) </td></tr>
<tr><td> 5057 </td><td> <code>UnitOrderWalk</code> </td><td> Order the specified unit to walk somewhere. Note: Only works on idle units so as not to interfere with game logic and cause crashes. Returns true on success or false on failure. </td><td> 1 - Unit ID <br> 2 - X <br> 3 - Y </td><td> Success: Boolean </td></tr>
<tr><td> - </td><td> <code>UnitOwnerSet</code> </td><td> Take unit from one player and give it to another </td></tr>
<tr><td> - </td><td> <code>UnitPositionSet</code> </td><td> Magically move unit from one place to another (?) </td></tr></tbody></table>

Actions are placed in a form <b>Actions.ACT_NAME(ACT_PARAMETERS);</b> like so:<br>
<pre><code>if States.GameTime = 300 then<br>
  Actions.PlayerDefeat(0); //Defeat 1st player<br>
</code></pre>