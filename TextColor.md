# How does it works #

The game allows to color any text (except players name in multiplayer) with the following tag: **`[$BBGGRR]`** where BB is hex value for blue component, GG - hex for green and RR hex for red. **`[]`** ends the color and reverts to default white.

For example: **`[$FF00FF]One [$00FF0F]Two [$808080]Three[] Four`** will print **One** in violet, **Two** in yellow, **Three** in grey and **Four** in default white color and willlook like so: <font color='#FF00FF'>One </font><font color='#0FFF00'>Two </font><font color='#808080'>Three </font><font color='#FFFFFF'>Four </font>**("four" being rendered white gets lost on white background here).**

Text coloring is commonly used in multiplayer server names (list in lobby), multiplayer server greetings. However one can you use to say colored chat messages or mission texts.

Note that text coloring works multiplicatively, so if you take font which is yellow (Outline.fnt) and apply [$FF0000] to it, it will look black, because original font has no blue component in it.