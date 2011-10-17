unit KM_Defaults;
{$IFDEF FPC} {$MODE DELPHI} {$ENDIF}
interface

type bmBrushMode = (
            bmNone,
            bmTerrain,
            bmTiles,
            bmTileRotate,
            bmMagicWater,
            bmObjects,
            bmRelief,
            bmHouses,
            bmCopy,
            bmPaste);

type TPos= record X,Y:word; end;

const MapSizes:array[1..15]of word = (32,48,64,80,96,112,128,144,160,176,192,256,384,512,1024);

const MMap:array[1..256]of integer = (
131+149*256+ 25*65536,125+140*256+24*65536,133+150*256+41*65536,138+155*256+20*65536,
109+155*256+213*65536,133+156*256+24*65536,135+159*256+24*65536,214+131*256+47*65536,
117+134*256+ 22*65536,119+136*256+23*65536,132+160*256+215*65536,124+138*256+23*65536,
100+149*256+149*65536,121+130*256+26*65536,121+126*256+35*65536,172+131*256+79*65536,
141+134*256+ 37*65536,146+135*256+37*65536,120+138*256+23*65536,125+142*256+24*65536,
122+112*256+ 60*65536,119+108*256+54*65536,102+154*256+192*65536,102+151*256+150*65536,
133+125*256+ 89*65536,152+139*256+98*65536,151+146*256+33*65536,172+162*256+38*65536,
193+163*256+ 48*65536,208+158*256+56*65536,207+157*256+56*65536,188+159*256+89*65536,
194+167*256+ 97*65536,188+162*256+98*65536,123+118*256+34*65536,110+100*256+41*65536,
107+100*256+ 47*65536,115+105*256+53*65536,117+105*256+54*65536,120+108*256+56*65536,
103+103*256+ 33*65536,103+108*256+34*65536,100+113*256+30*65536,104+118*256+32*65536,
 93+153*256+205*65536,193+192*256+248*65536,177+173*256+227*65536,161+152*256+170*65536,
102+151*256+ 74*65536,161+152*256+169*65536,76+63*256+32*65536,145+137*256+126*65536,
175+169*256+207*65536,114+91*256+41*65536,149+130*256+94*65536,119+110*256+37*65536,
123+130*256+ 28*65536,117+115*256+33*65536,111+103*256+38*65536,124+116*256+38*65536,
152+133*256+ 42*65536,114+99*256+42*65536,108+95*256+41*65536,137+113*256+44*65536,
142+130*256+117*65536,153+142*256+143*65536,137+145*256+39*65536,139+141*256+41*65536,
143+139*256+ 44*65536,146+151*256+55*65536,163+154*256+76*65536,172+157*256+87*65536,
138+148*256+ 39*65536,144+147*256+41*65536,149+147*256+43*65536,157+150*256+45*65536,
160+154*256+ 46*65536,165+157*256+47*65536,172+160*256+49*65536,176+160*256+52*65536,
179+160*256+ 54*65536,184+160*256+57*65536,186+158*256+58*65536,189+157*256+59*65536,
129+138*256+ 39*65536,127+131*256+41*65536,126+125*256+42*65536,122+116*256+46*65536,
118+109*256+ 48*65536,115+105*256+49*65536,128+133*256+40*65536,121+120*256+44*65536,
114+110*256+ 44*65536,149+152*256+43*65536,164+156*256+49*65536,177+161*256+53*65536,
131+127*256+ 43*65536,135+130*256+44*65536,141+133*256+45*65536,185+160*256+87*65536,
189+160*256+ 76*65536,191+158*256+65*65536,177+161*256+83*65536,175+161*256+68*65536,
171+161*256+ 55*65536,96+121*256+87*65536,97+102*256+62*65536,102+95*256+52*65536,
179+158*256+ 94*65536,167+144*256+81*65536,141+117*256+61*65536,137+122*256+64*65536,
158+138*256+ 75*65536,170+150*256+86*65536,103+149*256+96*65536,103+149*256+113*65536,
174+163*256+103*65536,154+159*256+110*65536,129+154*256+124*65536,102+148*256+125*65536,
118+144*256+ 52*65536,108+143*256+65*65536,102+144*256+75*65536,130+138*256+77*65536,
131+145*256+100*65536,126+142*256+89*65536,112+151*256+133*65536,112+151*256+133*65536,
108+106*256+ 53*65536,101+93*256+65*65536,98+90*256+62*65536,95+88*256+61*65536,
129+122*256+ 87*65536,109+110*256+49*65536,100+93*256+65*65536,100+92*256+63*65536,
104+ 96*256+ 68*65536,123+114*256+81*65536,120+121*256+58*65536,128+140*256+37*65536,
124+129*256+ 47*65536,121+123*256+52*65536,107+132*256+104*65536,110+137*256+109*65536,
135+126*256+106*65536,138+128*256+107*65536,138+127*256+100*65536,145+132*256+97*65536,
134+108*256+ 52*65536,131+107*256+57*65536,139+115*256+68*65536,147+122*256+79*65536,
105+ 95*256+ 47*65536,98+88*256+43*65536,88+80*256+42*65536,79+73*256+43*65536,
128+119*256+105*65536,114+108*256+87*65536,117+109*256+86*65536,128+120*256+103*65536,
136+107*256+ 45*65536,134+106*256+45*65536,147+115*256+51*65536,145+115*256+52*65536,
157+122*256+ 54*65536,36+33*256+25*65536,168+159*256+177*65536,117+98*256+43*65536,
132+131*256+ 33*65536,174+144*256+78*65536,159+140*256+42*65536,156+148*256+155*65536,
133+141*256+ 58*65536,175+154*256+103*65536,160+150*256+63*65536,119+109*256+67*65536,
132+130*256+ 86*65536,146+134*256+104*65536,142+133*256+90*65536,127+118*256+91*65536,
135+148*256+ 41*65536,190+164*256+100*65536,171+161*256+46*65536,114+104*256+52*65536,
132+110*256+ 37*65536,141+111*256+50*65536,136+111*256+39*65536,128+100*256+41*65536,
129+140*256+ 25*65536,185+156*256+89*65536,165+153*256+37*65536,109+95*256+39*65536,
102+154*256+137*65536,97+146*256+127*65536,77+129*256+111*65536,113+114*256+67*65536,
 98+159*256+130*65536,131+114*256+67*65536,159+161*256+128*65536,106+108*256+81*65536,
108+167*256+140*65536,106+101*256+85*65536,132+126*256+91*65536,181+181*256+237*65536,
187+186*256+247*65536,191+191*256+252*65536,138+130*256+95*65536,132+118*256+74*65536,
101+153*256+136*65536,103+154*256+137*65536,113+170*256+144*65536,113+170*256+144*65536,
173+168*256+213*65536,176+172*256+221*65536,148+119*256+67*65536,129+112*256+60*65536,
181+215*256+202*65536,206+224*256+213*65536,235+251*256+249*65536,242+252*256+250*65536,
168+162*256+193*65536,168+135*256+76*65536,152+125*256+76*65536,140+125*256+80*65536,
180+206*256+187*65536,216+224*256+210*65536,218+230*256+220*65536,216+233*256+224*65536,
187+203*256+184*65536,219+229*256+219*65536,146+187*256+168*65536,30+28*256+23*65536,
170+207*256+194*65536,168+207*256+192*65536,122+148*256+122*65536,102+155*256+130*65536,
 99+153*256+132*65536,118+146*256+125*65536,128+144*256+99*65536,126+144*256+103*65536,
103+153*256+136*65536,110+148*256+94*65536,142+153*256+57*65536,165+158*256+42*65536,
 99+150*256+130*65536,22+22*256+22*65536,212+164*256+87*65536,129+116*256+84*65536,
118+122*256+ 93*65536,100+130*256+125*65536,114+126*256+101*65536,106+102*256+59*65536,
121+118*256+ 80*65536,107+102*256+61*65536,124+116*256+72*65536,112+115*256+82*65536
);

TilePassability:array[1..256]of byte = (
255,255,255,255,255,255,255,  0,
255,255,255,255,255,255,255,  0,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,  0,255,255,  0,255,255,
255,255,255,255,255,255,255,255,

255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,

  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,255,255,255,255,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,
255,255,255,255,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,

  0,  0,  0,  0,  0,255,  0,  0,
  0,  0,  0,255,255,255,  0,255,
  0,  0,  0,  0,255,255,255,255,
  0,  0,  0,  0,255,255,255,255,
  0,  0,  0,  0,  0,  0,  0,  0,
  0,  0,  0,  0,  0,  0,  0,  0,
255,255,255,255,255,255,255,255,
255,255,255,255,255,255,255,255
);

//Lookup table
// 8 1 2
// 7 0 3
// 6 5 4
//todo: Add ice
TileDirection:array[1..256]of byte = (
0,0,0,0,4,0,0,0,
0,0,4,0,1,0,0,0,
0,0,0,0,0,0,4,4,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,4,0,0,0,
2,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,2,2,2,0,0,0,0,
0,0,2,2,2,1,6,2,
2,2,2,1,1,1,8,4,

0,0,0,0,0,0,0,0,
0,0,0,0,0,0,2,2,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,

2,2,2,0,2,0,0,0,
1,0,0,0,0,0,0,0,
1,1,3,7,0,0,0,0,
5,5,5,5,0,0,0,0,
5,5,5,5,5,5,5,0,
5,5,2,2,2,2,2,2,
2,1,1,1,1,0,0,0,
0,0,0,0,0,0,0,0
);


TileMagicWater:array[1..256]of byte = (
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,

0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,

1,0,0,0,1,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0
);

Combo:array[1..26,1..26,1..3]of integer = (
 //Grass        //Moss  //GrassRed    //GrassRed2//GrassGrnd//Sand           //OrangeSand  //Ground         //Cobblest       //SandGrass   //GrassSand      //Swamp       //GrndSwmp //Ice         //SnowLittle   //SnowMedium  //SnowBig  //StoneMount     //GreyMount      //RedMount       //Black        //GroundStoned   //Water          //Coal    //Gold    //Iron
((  0,   0,  0),(8,0,0),( 17,  0,  0),(26, 0, 0),(34, 0, 0),(  32,   0,   0),( 29,  0,  0),(  35,   0,   0),( 215,   0,   0),( 28,  0,  0),(  27,   0,   0),( 48,  0,  0),(40, 0, 0),( 44,  0,  0),( 47,  0,   0),( 46,  0,  0),(45, 0, 0),( 132,   0,   0),( 159,   0,   0),( 164,   0,   0),(245, 0,    0),( 20,  0,  0),( 192,   0,   0),(155,0,0),(147,0,0),(151,0,0)), //Grass
((-19, -18,  9),(8,8,8),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Moss
(( 66,  67, 68),(0,0,0),( 17, 17, 17),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GrassRed
(( 72,  73, 74),(0,0,0),(  0,  0,  0),(26,26,26),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GrassRed2
(( 84,  85, 86),(0,0,0),(-98,-97,-96),( 0, 0, 0),(34,34,34),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GrassGround
(( 69,  70, 71),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(  32,  32,  32),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Sand
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(  99, 100, 101),( 29, 29, 29),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //RoughSand
(( 56,  57, 58),(0,0,0),(  0,  0,  0),( 0, 0, 0),(87,88,89),(-113,-112,-111),(  0,  0,  0),(  35,  35,  35),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),( 21, 21, 21),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Ground
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  38,  39, 215),( 215, 215, 215),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Cobblestones
(( 93,  94, 95),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(-83,-82,-81),(   0,   0,   0),(   0,   0,   0),( 28, 28, 28),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //SandGrass
((  0,   0,  0),(0,0,0),(  0,  0,  0),(75,76,77),( 0, 0, 0),( 102, 103, 104),(-83,-82,-81),(   0,   0,   0),(   0,   0,   0),(-80,-79,-78),(  27,  27,  27),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GrassSand
((120, 121,122),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),( 48, 48, 48),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Swamp
(( 90,  91, 92),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),(40,40,40),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GroundSwamp
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, 44, 44),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Ice
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),( 247,  64,  65),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 47, 47,  47),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //SnowLittle
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, -4,-10),(220,212, 213),( 46, 46, 46),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //SnowMedium
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(203,204,205),(45,45,45),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //SnowBig
((  0, 139,138),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),( 132, 132, 132),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Moss
((180, 172,176),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 181, 173, 177),(  0,  0,  0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 182, 174, 178),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( 159, 159, 159),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Grey Mountains
((188, 168,184),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 189, 169, 185),(  0,  0,  0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 190, 170, 186),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 164, 164, 164),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Red Mountains
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( -53, -50,-165),(245, 0,    0),(  0,  0,  0),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Black
((  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(-113,-112,-111),(  0,  0,  0),(  21,  21,  20),( -38, -39, -38),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(-65,-64,-247),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(-179,-175,-183),(-187,-167,-191),(  0, 0,    0),( 20, 20, 20),(   0,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //GroundStoned
((123,-125,127),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 116,-117, 118),(  0,  0,  0),(-107,-106,-105),(-107,-106,-105),(  0,  0,  0),(-243,-242,-241),(114,115,119),( 0, 0, 0),(-22,-12,-23),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(-143,-200,-236),(-237,-200,-236),(-239,-200,-236),(245, 0,    0),(  0,  0,  0),( 192,   0,   0),(0,0,0),(0,0,0),(0,0,0)), //Water
(( 56,  57, 58),(0,0,0),(  0,  0,  0),( 0, 0, 0),(87,88,89),(-113,-112,-111),(  0,  0,  0),( 152, 153, 154),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0,  0,   0),(  0,  0,  0),(   0,   0,   0),(155,0,0),(0,0,0),(0,0,0)), //Coal
((180, 172,176),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 181, 173, 177),(  0,  0,  0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 182, 174, 178),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( 144, 145, 146),(   0,   0,   0),(  0,  0,   0),(183,175,179),( 236, 200, 237),(0,0,0),(147,0,0),(0,0,0)), //Gold
((188, 168,184),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 189, 169, 185),(  0,  0,  0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 190, 170, 186),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 148, 149, 150),(-53,-50,-165),(191,167,187),( 236, 200, 239),(0,0,0),(0,0,0),(151,0,0))  //Iron
);

//0     number of variants (1..X)
//1..X  tile variants
//
RandomTiling:array[1..26,0..15]of byte = (
(15,1,1,1,2,2,2,3,3,3,5,5,5,11,13,14), //reduced chance for "eye-catching" tiles
(1,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(1,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,26,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(1,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,29,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(2,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,215,0,0,0,0,0,0,0,0,0,0,0,0,0,0),//Cobblestone
(0,28,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,27,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0), //swamp
(3,41,42,43,0,0,0,0,0,0,0,0,0,0,0,0),//brownswamp
(0,44,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,47,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,46,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,45,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(8,129,130,131,132,134,135,136,137,0,0,0,0,0,0,0),    //Stone
(5,156,157,158,159,201{?},0,0,0,0,0,0,0,0,0,0),       //Grey
(5,160,161,162,163,164,0,0,0,0,0,0,0,0,0,0),          //Rusty
(0,245,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(0,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(1,196,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
(9,152,153,154,154,154,155,155,155,155,0,0,0,0,0,0), //Coal //enriched pattern
(9,144,145,146,146,146,147,147,147,147,0,0,0,0,0,0), //Gold
(9,148,149,150,150,150,151,151,151,151,0,0,0,0,0,0)  //Iron
);

//Tiles table made by JBSnorro, thanks to him :)
TileRemap:array[1..256]of integer = (
 1,73,74,75,37,21,22, 38, 33, 34, 32,181,173,177,129,130,131,132,133, 49,193,197,217,225,  0,  0, 45, 24, 13, 23,208,224,
27,76,77,78,36,39,40,198,100,101,102,189,169,185,134,135,136,137,138,124,125,126,229,218,219,220, 46, 11,  5,  0, 26,216,
28,79,80,81,35,88,89, 90, 70, 71, 72,182,174,178,196,139,140,141,142,127,128,  0,230,226,227,228, 47,204,205,206,203,207,
29,82,83,84,85,86,87,  0,112,113,114,190,170,186,161,162,163,164,165,106,107,108,233,234,231,  0, 48,221,213,214,199,200,
30,94,95,96,57,58,59,  0,103,104,105,183,175,179,157,202,158,159,160,117,118,119,209,210,241,245,194,248, 65, 66,195, 25,
31, 9,19,20,41,42,43, 44,  6,  7, 10,191,171,187,149,150,151,152, 16,242,243,244,235,238,239,240,  0, 50,172, 52,222,223,
18,67,68,69,91,92,93,  0,  3,  4,  2,184,176,180,145,146,147,148,  8,115,116,120,236,237,143,144,  0, 53,167, 55,215,232,
17,97,98,99, 0, 0, 0,  0, 12, 14, 15,192,168,188,153,154,155,156,  0,121,122,123,211,212,201,  0,246,166, 51, 54,  0,  0);
// 247 - doesn't work in game, replaced with random road

ObjIndex:array[1..90]of integer = (
0  , 1  , 2  , 3  , 4  , 5  , 6  , 7  , 8  , 9  , //8,9 boulders, can't walk/build
10 , 11 , 12 , 13 , 14 , 15 , 16 , 17 , 18 , 19 ,
20 , 21 , 22 , 23 , 24 , 30 , 58 , 59 , 60 , 61 , //61 is a non-walk tile
62 , 68 , 69 , 70 , 71 , 72 , 73 , 88 , 89 , 90 , //80,81 red stop signs in GFX
94 , 95 , 97 , 98 , 100, 102, 103, 104, 105, 109,
110, 114, 118, 119, 122, 123, 124, 151, 155, 160,
165, 170, 172, 190, 191, 192, 193, 194, 195, 196,
200, 201, 202, 203, 204, 205, 206, 210, 211, 212, //212,213,215 palmettes, can't walk on them
213, 214, 215, 216, 217, 218, 219, 220, 249, 250  //249,250 red flowers, can't walk build on them
{, 255}); //255 empty place, no object

//Inverse for ObjectIndex
ObjIndexInv:array[0..255]of integer = (
   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,
  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,
  21,  22,  23,  24,  25,   0,   0,   0,   0,   0,
  26,   0,   0,   0,   0,   0,   0,   0,   0,   0,
   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
   0,   0,   0,   0,   0,   0,   0,   0,  27,  28,
  29,  30,  31,   0,   0,   0,   0,   0,  32,  33,
  34,  35,  36,  37,   0,   0,   0,   0,   0,   0,
   0,   0,   0,   0,   0,   0,   0,   0,  38,  39,
  40, 0, 0, 0, 41, 42, 0, 43, 44, 0, 45, 0, 46, 47, 48, 49, 0, 0, 0, 50, 51, 0, 0, 0, 52, 0, 0, 0, 53, 54, 0, 0, 55, 56, 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 0, 0, 59, 0, 0, 0, 0, 60, 0, 0, 0, 0, 61, 0, 0, 0, 0, 62, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 65, 66, 67, 68, 69, 70, 0, 0, 0, 71, 72, 73, 74, 75, 76, 77, 0, 0, 0, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 89, 90, 0, 0, 0, 0, 0);

ObjIndexGFX:array[1..90]of integer = (
34 , 18 , 19 , 21 , 20 , 35 , 36 , 40 , 23 , 22 ,
38 , 39 , 41 , 26 , 176, 194, 238, 2  , 3  , 4  ,
221, 5  , 12 , 13 , 14 , 195, 61 , 64 , 250, 42 , //42 is a non-walk tile
250, 244, 245, 246, 247, 248, 249, 27 , 129, 132,
117, 91 , 27 , 129, 28 , 27 , 129, 132, 31 , 135,
67 , 82 , 82 , 75 , 126, 123, 94 , 222, 112, 106,
88 , 97 , 109, 208, 150, 151, 153, 202, 152, 154,
167, 138, 146, 159, 163, 78 , 155, 142, 143, 144,
145, 16 , 15 , 173, 174, 171, 172, 175, 13 , 14 );
//GFX 254,255 are stop signs.

HouseName:array[1..29]of string = (
'Sawmill','Iron smithy','Weapon smithy','Coal mine','Iron mine',
'Gold mine','Fisher hut','Bakery','Farm','Woodcutter',
'Armor smithy','Store','Stables','School','Quary',
'Metallurgist','Swine','Watch tower','Town hall','Weapon workshop',
'Armor workshop','Barracks','Mill','Siege workshop','Butchers',
'Tannery','N/A','Inn','Wineyard');

//1-building area
//2-entrance
HousePlanYX:array[1..29,1..4,1..4]of byte = (
((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1)), //Sawmill        //1
((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,1,2,1)), //Iron smithy    //21
((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1)), //Weapon smithy  //244
((0,0,0,0), (0,0,0,0), (1,1,1,0), (1,2,1,0)), //Coal mine      //134
((0,0,0,0), (0,0,0,0), (0,0,0,0), (0,1,2,1)), //Iron mine      //61
((0,0,0,0), (0,0,0,0), (0,0,0,0), (0,1,2,0)), //Gold mine      //239
((0,0,0,0), (0,0,0,0), (0,1,1,0), (0,2,1,1)), //Fisher hut     //81
((0,0,0,0), (0,1,1,1), (0,1,1,1), (0,1,1,2)), //Bakery         //101
((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,2,1,1)), //Farm           //124
((0,0,0,0), (0,0,0,0), (1,1,1,0), (1,1,2,0)), //Woodcutter     //142
((0,0,0,0), (0,1,1,0), (1,1,1,1), (1,2,1,1)), //Armor smithy   //41
((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0)), //Store          //138
((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,1,2,1)), //Stables        //146
((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0)), //School         //250
((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1)), //Quarry         //211
((0,0,0,0), (1,1,1,0), (1,1,1,0), (1,2,1,0)), //Metallurgist   //235
((0,0,0,0), (0,1,1,1), (1,1,1,1), (1,1,1,2)), //Swine          //368
((0,0,0,0), (0,0,0,0), (0,1,1,0), (0,1,2,0)), //Watch tower    //255
((0,0,0,0), (1,1,1,1), (1,1,1,1), (1,2,1,1)), //Town hall      //1657
((0,0,0,0), (0,0,0,0), (1,1,1,1), (1,2,1,1)), //Weapon workshop//273
((0,0,0,0), (0,1,1,0), (0,1,1,1), (0,2,1,1)), //Armor workshop //663
((1,1,1,1), (1,1,1,1), (1,1,1,1), (1,2,1,1)), //Barracks       //334
((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1)), //Mill           //358
((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,2,1,1)), //Siege workshop //1681
((0,0,0,0), (0,1,1,0), (0,1,1,1), (0,1,1,2)), //Butcher        //397
((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,2,1)), //Tannery        //668
((0,0,0,0), (0,0,0,0), (0,0,0,0), (0,0,0,0)), //N/A
((0,0,0,0), (0,1,1,1), (1,1,1,1), (1,2,1,1)), //Inn            //363
((0,0,0,0), (0,0,0,0), (0,1,1,1), (0,1,1,2))  //Wineyard       //378
);

HouseIndexGFX:array[1..29]of integer = (
1,21,41,134,61,239,81,101,124,142,
244,138,146,250,211,235,368,255,1657,273,
663,334,358,1681,397,668,0,363,378);

//   1      //Depending on surrounding tiles
//  8*2
//   4
RoadsConnectivity:array [0..15,1..2]of byte = (
(249,0),(249,0),(249,1),(251,3),
(249,0),(249,0),(251,0),(253,0),
(249,1),(251,2),(249,1),(253,3),
(251,1),(253,2),(253,1),(255,0));

PlayerColors:array[1..8,1..4]of byte =(
(255,  0,0,255),(0,255,  0,255),(  0,0,255,255),
(255,255,0,255),(0,255,255,255),(255,0,255,255),
(255,255,255,255),(0,0,0,255));

implementation

end.
