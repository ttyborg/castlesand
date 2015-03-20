# Mission events #

Using simple syntax events can be added to custom missions. The events are stored in `\Maps\map_name\map_name.evt` file, which can be opened by any text editor (e.g. Notepad).

Each line is an event. First comes Trigger (what sets event off) with player index and parameters, then comes Action (what will happen) with player index and parameters as well. Unless specially noted, events fire only once and then are deleted.

`HOUSE_BUILT 0 5 SHOW_MESSAGE 0 17`

Above line means that when Player0 has built house type 5 Player0 (himself) will receive a message #17.

Comments and empty lines are allowed, preceding with `//` mark.


## Available triggers ##

| Trigger | Description | Parameter 1 | Parameter 2 |
|:--------|:------------|:------------|:------------|
| ~~ATTACK\_REPELLED~~ | Player has repelled the scripted attack | 1. Attack index | - |
| **DEFEATED** | Occurs when certain player has been defeated. Defeat conditions are checked separately by Player AI | - | - |
| **HOUSE\_BUILT** | Occurs when player has built the specified house type | 1. House type index | - |
| **TIME** | Occurs when specified time has come | 1. Time value in game ticks (100ms by default) | - |
| _UNIT\_COUNT_ | Player has specified count of alive citizens | 1. Unit type | 2. Count |
| _UNITS\_LOST_ | Player has lost specified count of units (citizens and warriors) | 1. Count | - |
| _WARES\_COUNT_ | Player has total of specified amount of wares | 1. Ware type | 2. Count |

`*`triggers typed in _italic_ are not yet implemented.
`**`triggers typed in ~~crossed out~~ are planned to be rejected.

## Available actions ##

| Action | Description | Parameter 1 | Parameter 2 | Parameter 3 | Parameter 4 |
|:-------|:------------|:------------|:------------|:------------|:------------|
| _ALLIANCE\_CHANGE_ | Change the alliance setting between specified players | 1. Target player index | - | - |
| ~~ATTACK~~ | Issue attack order to AI | 1. Target player index | 2. Other attack parameters ... ? | - |
| ~~ATTACK\_WAVE~~ | Spawn group of warriors and set their attack goal | 1. Spawn location X, Y | 2. Other parameters ... ? | - |
| **DELAYED\_MESSAGE** | Displays a message after specified delay | 1. Delay amount in game ticks | 2. Message index | - |
| **GIVE\_UNITS** | Give specified player more units | 1. Unit type | 2. Location X | 3. Location Y | 4. Count |
| **GIVE\_WARES** | Adds amount of ware to oldest players Store | 1. Ware type | 2. Count | - |
| _SEND\_WARES_ | Take amount of ware from one player and give them to another players Store | 1. Ware type | 2. Count | 3. Receiver player index |
| _SHOW\_COUNTDOWN_ | Display countdown for player | 1. Value to count from | - | - |
| **SHOW\_MESSAGE** | Displays a message immediately | 1. Message index | - | - |
| **UNLOCK\_HOUSE** | Explicitly allow player to build houses of specified type | 1. House type | - | - |
| **VICTORY** | Proclaims victory to the player | - | - | - |

`*`actions typed in _italic_ are not yet implemented.
`**`actions typed in ~~crossed out~~ are planned to be rejected.

## Examples ##

TIME -1 600 SHOW\_MESSAGE 0 1 //After 1 minute show text message #1 to Player0

DEFEATED 1 DELAYED\_MESSAGE 0 50 2 //After Player1 gets defeated wait 5sec and show message #2 to Player0