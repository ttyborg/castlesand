# Attacks #

AI attacks are defined by the following parameters:
  * Type (Repeating or Once)
  * Initial delay
  * Target
  * Number of soldiers to attack
  * Number of each group type, OR "choose randomly"

## Groups that can attack ##
The only groups that can participate in AI attacks are:
  * Idle groups not in any defence position
  * Idle groups in a backline defence positions

The first groups to be used are the ones not in any defence position. Next it takes the backline defence positions using the lowest priority (highest index) first (so defence position 5 will be taken before defence position 4).

## Trigger ##

The AI attack is launched when all these conditions are satisfied:
  * If multiplayer, it must be after peacetime
  * Game time is at least **initial delay**
  * If the attack type is **Once**, the attack must not have occurred previously
  * The AI must have at least the **number of each group type** requested (unless **choose randomly** is set)
  * The total number of soldiers in the group types chosen (all groups if **choose randomly**) must be at least as large as **number of soldiers to attack**

Currently attacks are checked once every 1.2 seconds, so if an attack can be launched multiple times (trigger is still satisfied after launching it once) it will launch again after 1.2 seconds.

## Launch ##
When the attack launches it will cause the chosen groups to attack the target.

If **choose randomly** the AI will repeatedly take one of each group type until it has at least **number of soldiers to attack** (so it isn't technically random, it's evenly mixed)

Otherwise the AI will take the **number of each group type** you specified. If that still isn't as large as **number of soldiers to attack** then the AI takes more groups out of the types you specified until it has at least **number of soldiers to attack**. This guarantees the attack will have at least **number of soldiers to attack**, even if some groups it selects are small.

The AI will never split groups, so sometimes it may take more than **number of soldiers to attack** in order to take a full group rather than splitting it.

---

# Army types #
## Iron then leather (default, used in original campaigns) ##
If in autobuild mode the AI will build a town that can satisfy "iron equip rate". If there is no iron available or the iron is depleted they will build a leather production that satisfies "leather equip rate".

AI tries to equip iron soldiers. If iron weapons are not available it will equip leather soldiers instead. However the time between each soldier are not counted separately for iron/leather.

## Iron only ##
AI only makes iron soldiers, and builds their town as such. Leather equip rate is ignored.

## Leather only ##
AI only makes leather soldiers, and builds their town as such. Iron equip rate is ignored.

## Mixed (used for MP AI builder) ##
If in autobuild mode the AI will build a town that can satisfy both "iron equip rate" and "leather equip rate" at once.

AI equips both iron and leather soldiers, counting time between each soldier separately for iron and leather. So if you have both equip rates set to 60 (1 minute) you will get 2 soldiers per minute, 1 iron and 1 leather.

If iron is not available or becomes depleted, the AI will expand their leather production and make leather soldiers instead of iron (so they are still equipping "leather equip rate" + "iron equip rate" soldiers per minute, but the soldiers are now all leather).