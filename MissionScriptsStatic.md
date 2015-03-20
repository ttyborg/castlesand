## List of commands ##

| Command | Original | Remake | Description |
|:--------|:---------|:-------|:------------|
| `ADD_WARE_TO_LAST` | - | V | Adds wares to the last house |
| `ADD_UNIT_TO_LAST` | - | V | Adds the specified unit type inside the last house. Only works for barracks and recruits so far |
| `BLOCK_TRADE` | - | V | Blocks resources trade in Marketplace |
| `BLOCK_UNIT` | - | V | Disables training of units |
| `DISTRIBUTE_MULTIPLAYER_POSITIONS` | V | - | ..? |
| `ENABLE_PLAYER` | V | - | ... |
| `SET_AI_AUTO_REPAIR` | - | V | AI will repair damaged buildings |
| `SET_AI_AUTO_DEFEND` | - | V | AI will try to define and fill defense positions on his own |
| `SET_AI_CHARACTER EQUIP_RATE` | - | V | Instruct AI to equip 1 soldier every N ticks (depreciated, sets both iron and leather together) |
| `SET_AI_CHARACTER EQUIP_RATE_LEATHER` | - | V | Instruct AI to equip 1 iron soldier every N ticks (if iron one wasn't equipped first) |
| `SET_AI_CHARACTER EQUIP_RATE_IRON` | - | V | Instruct AI to equip 1 leather soldier every N ticks |
| `SET_AI_CHARACTER TOWN_DEFENCE` | V | - | This could be equip rate in KaM can we test it? |
| `SET_AI_CHARACTER AUTO_ATTACK_RANGE` | - | V | Idle AI soldiers will attack the enemy when they are within this range (default 4) |
| `CLEAR_AI_ATTACK` | - | V | Resets AI attack values so they don't carry over |
| `SET_MAP` | V | - | Sets the map file for the mission |
| `SET_NEW_REMAP` | V | - | Sets palette colors for player flags |
| **Player setup** |
| `SET_MAX_PLAYERS` | V | V | Sets the maximum number of players |
| `SET_AI_PLAYER` | V | V |Sets current player to be an AI |
| `SET_HUMAN_PLAYER` | V | V | Default human player |
| `SET_USER_PLAYER` | - | V | Allows human players to pick current player |
| **Conditional parts** |
| `ENDIF` | V | - | ..? |
| `IF` | V | - | VALID\_PLAYER, MEDIUM\_WARES, MANY\_WARES ..? |

_To be continued ..._


---


## Description and usage examples ##

#### ADD\_WARE\_TO\_LAST ####
Puts resources in the last defined house. If the house does not accept that kind of resource, it is ignored.
```
Syntax:
!ADD_WARE_TO_LAST <WARE_ID> <QUANTITY>
Example:
!ADD_WARE_TO 1 5 //Adds 5 stone to the last house that was defined in the script
```

#### BLOCK\_TRADE ####
Blocks trading (both in and out) of the specified resource for the current player.
```
Syntax:
!BLOCK_TRADE <WARE_ID>
Example: 
!BLOCK_TRADE 8 //Blocks trading wine
```

#### BLOCK\_UNIT ####
Disables training of units for the current player.
```
Syntax:
!BLOCK_UNIT <UNIT_ID>
Example: 
!BLOCK_UNIT 2 //Blocks training of Miners
```

#### SET\_AI\_AUTO\_REPAIR ####
Makes AI repair damaged buildings. If you do not specify this command, the AI will not repair damaged buildings.
```
Syntax/Example:
!SET_AI_AUTO_REPAIR
```

#### SET\_AI\_AUTO\_DEFEND ####
Makes AI to set up defense positions automatically. If you do not specify this command, the AI will use existing defense positions (placed by mapmaker in Map Editor).
```
Syntax/Example:
!SET_AI_AUTO_DEFEND
```

#### SET\_AI\_CHARACTER EQUIP\_RATE ####
Makes AI to train soldiers every N game ticks. If you do not specify this command, the default (in KaM TSK/TPR too) is every 100 seconds (1000 ticks).
```
Syntax:
!SET_AI_CHARACTER EQUIP_RATE <TICKS>
Example: 
!SET_AI_CHARACTER EQUIP_RATE 150 //AI will attempt to train 1 soldier every 15 seconds (150 game ticks). 
```

#### SET\_USER\_PLAYER ####
Allows to choose this player for a game. If no user\_players were specified, then user can pick only default player.
```
Syntax:
!SET_USER_PLAYER
Example:
!SET_CURR_PLAYER 1
!SET_USER_PLAYER //Allows to choose this player in MP and SP
```

_To be continued ..._