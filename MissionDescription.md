# Flags #

### `Author` ###
Text string. Author(s) of the map.

### `BigDesc` ###
Text string. Large description shown in SingleMap menu when player chooses the map

### `BigDescLIBX` ###
Followed by Id of the string to take from mission libx file. Large description shown in SingleMap menu when player chooses the map. Allows for localized mission description.

### `SmallDesc` ###
Text string. Map description given in few words.

### `SmallDescLIBX` ###
Followed by Id of the string to take from mission libx file. Map description given in few words. Allows for localized mission description.

### `SetCoop` ###
Flag is set if it exists. Sets this mission as cooperative (different list in multiplayer lobby). Includes `BlockPeacetime`, `BlockTeamSelection`, `BlockFullMapPreview` flags.

### `SetSpecial` ###
Flag is set if it exists. Sets this mission as special (different list in multiplayer lobby)

### `BlockPeacetime` ###
Flag is set if it exists. Disables peacetime selection in the lobby (automatically set for coop and battles)

### `BlockTeamSelection` ###
Flag is set if it exists. Disables team selection in the lobby, alliances from mission will be used (automatically set for coop)

### `BlockFullMapPreview` ###
Flag is set if it exists. Disables the entire map being revealed in the lobby preview (automatically set for coop)

# Example #
```
Title
Twenty Seven

Author
Map Author

SmallDesc
Story about faith and honor

BigDesc
1

SetSpecial

BlockPeacetime

```