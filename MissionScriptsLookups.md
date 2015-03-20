# Introduction #

This page contains lookup tables for the indexes used in dynamic (.script) and static (.dat) scripts to represent things like unit and house types.


# Unit types #
| **Index** | **Unit type** |
|:----------|:--------------|
| 0 |Serf |  | 10 |Stone Mason |  | 20 |Pikeman |  | 30 |Wolf|
| 1 |Woodcutter |  | 11 |Blacksmith |  | 21 |Scout |  | 31 |Fish|
| 2 |Miner |  | 12 |Metallurgist |  | 22 |Knight |  | 32 |Seasnake|
| 3 |Animal Breeder |  | 13 |Recruit |  | 23 |Barbarian |  | 33 |Seastar|
| 4 |Farmer |  | 14 |Militia |  | 24 |Rebel |  | 34 |Crab|
| 5 |Carpenter |  | 15 |Axe Fighter |  | 25 |Rogue |  | 35 |Water flower|
| 6 |Baker |  | 16 |Sword Fighter |  | 26 |Warrior |  | 36 |Water leaf|
| 7 |Butcher |  | 17 |Bowman |  | 27 |Vagabond |  | 37 |Duck|
| 8 |Fisherman |  | 18 |Crossbowman |
| 9 |Laborer |  | 19 |Lance Carrier |


Note: Animals indexes above (30-37) are for dynamic scripts only, static scripts use 24-31 for animals in the !SET\_UNIT command (for KaM compatibility).


# House Types #
| **Index** | **House type** |
|:----------|:---------------|
| 0| Sawmill |  | 10| Armor Smithy |  | 20| Armory Workshop |
| 1| Iron Smithy |  | 11| Storehouse |  | 21| Barracks |
| 2| Weapon Smithy |  | 12| Stables |  | 22| Mill |
| 3| Coal Mine |  | 13| School House |  | 23| Vehicles Workshop |
| 4| Iron Mine |  | 14| Quarry |  | 24| Butcher's |
| 5| Gold Mine |  | 15| Metallurgist's |  | 25| Tannery |
| 6| Fisherman's Hut |  | 16| Swine farm |  | 26| _Unused_ |
| 7| Bakery |  | 17| Watch Tower |  | 27| Inn |
| 8| Farm |  | 18| Town Hall |  | 28| Vineyard |
| 9| Woodcutter's |  | 19| Weapons Workshop |  | 29| Market |


# Ware Types #
| **Index** | **Ware type** |
|:----------|:--------------|
| 0| Tree trunk |  | 10| Loaves |  | 20| Handaxe |
| 1| Stone |  | 11| Flour |  | 21| Longsword |
| 2| Timber |  | 12| Leather |  | 22| Lance |
| 3| Iron ore |  | 13| Sausages |  | 23| Pike |
| 4| Gold ore |  | 14| Pig |  | 24| Longbow |
| 5| Coal |  | 15| Skin |  | 25| Crossbow |
| 6| Iron |  | 16| Wooden Shield |  | 26| Horse |
| 7| Gold |  | 17| Long Shield |  | 27| Fish |
| 8| Wine |  | 18| Leather Armor |
| 9| Corn |  | 19| Iron Armament |


# Group Types #
| **Index** | **Group type** |
|:----------|:---------------|
| 0| Melee |
| 1| Anti-horse |
| 2| Ranged |
| 3| Mounted |


# Unit facing directions #
x is the unit, the numbers are the index for each direction:
```
7 0 1
6 x 2
5 4 3
```