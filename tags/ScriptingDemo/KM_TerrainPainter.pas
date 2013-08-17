unit KM_TerrainPainter;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils, Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Terrain;


type
  TTerrainKind = (
    tkCustom,
    tkGrass, tkMoss, tkRustyGrass1, tkRustyGrass2, tkDirtGrass,
    tkSand, tkRichSand, tkDirt, tkCobbleStone, tkGrassSand1,
    tkGrassSand2, tkGrassyWater, tkSwamp, tkIce, tkShallowSnow,
    tkSnow, tkDeepSnow, tkStoneMount, tkGoldMount, tkIronMount,
    tkAbyss, tkGravel, tkWater, tkCoal, tkGold,
    tkIron, tkFastWater, tkLava);

  //Terrain helper that is used to paint terrain types by Map Editor
  TKMTerrainPainter = class
  private
    //Fraction part of height, for smooth height editing
    HeightAdd: array [1 .. MAX_MAP_SIZE, 1 .. MAX_MAP_SIZE] of Byte;

    Land2: array [1 .. MAX_MAP_SIZE, 1 .. MAX_MAP_SIZE] of record
      TerType: TTerrainKind; //Stores terrain type per node
      Tiles: SmallInt;  //Stores kind of transition tile used, no need to save into MAP footer
    end;

    MapXn,MapYn:integer; //Cursor position node
    MapXc,MapYc:integer; //Cursor position cell
    MapXn2,MapYn2:integer; //keeps previous node position
    MapXc2,MapYc2:integer; //keeps previous cell position

    procedure BrushTerrainTile(X, Y: SmallInt; aTerrainKind: TTerrainKind);
    function PickRandomTile(aTerrainKind: TTerrainKind): Byte;
    procedure RebuildMap(X,Y,Rad: Integer; aSquare: Boolean);
    procedure EditBrush(aLoc: TKMPoint; aTile: Byte);
    procedure EditHeight;
    procedure EditTile(aLoc: TKMPoint; aTile,aRotation: Byte);
    procedure GenerateAddnData;
    function GetTerrainKind(Y, X: Integer): TTerrainKind;
    procedure SetTerrainKind(Y, X: Integer; Kind: TTerrainKind);
  public
    RandomizeTiling: Boolean;
    constructor Create;
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
    procedure UpdateStateIdle;
    procedure MagicWater(aLoc: TKMPoint);
    property TerrainKind[Y,X: Integer]: TTerrainKind read GetTerrainKind write SetTerrainKind;
  end;


var
  fTerrainPainter: TKMTerrainPainter;


const
  //Table of combinations between terrain types (0-based)
  //1 - no transition
  //2 - in half
  //3 - one corner
  //"-" means flip before use
  Combo: array [TTerrainKind, TTerrainKind, 1..3] of SmallInt = (
   //Custom //Grass        //Moss  //GrassRed    //GrassRed2//GrassGrnd//Sand           //OrangeSand  //Ground         //Cobblest       //SandGrass   //GrassSand      //Swamp       //GrndSwmp //Ice         //SnowLittle   //SnowMedium  //SnowBig  //StoneMount     //GreyMount      //RedMount       //Abyss        //Gravel      //Water          //Coal    //Gold           //Iron           //FastWater  //Lava
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Custom
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Grass
  ((0,0,0),(-19, -18,  9),(8,8,8),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Moss
  ((0,0,0),( 66,  67, 68),(0,0,0),( 17, 17, 17),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassRed
  ((0,0,0),( 72,  73, 74),(0,0,0),(  0,  0,  0),(26,26,26),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassRed2
  ((0,0,0),( 84,  85, 86),(0,0,0),(-98,-97,-96),( 0, 0, 0),(34,34,34),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassGround
  ((0,0,0),( 69,  70, 71),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(  32,  32,  32),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Sand
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(  99, 100, 101),( 29, 29, 29),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //RoughSand
  ((0,0,0),( 56,  57, 58),(0,0,0),(  0,  0,  0),( 0, 0, 0),(87,88,89),(-113,-112,-111),(  0,  0,  0),(  35,  35,  35),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),( 21, 21, 21),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Ground
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(  38,  39, 215),( 215, 215, 215),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Cobblestones
  ((0,0,0),( 93,  94, 95),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(-83,-82,-81),(   0,   0,   0),(   0,   0,   0),( 28, 28, 28),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //SandGrass
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),(75,76,77),( 0, 0, 0),( 102, 103, 104),(-83,-82,-81),(   0,   0,   0),(   0,   0,   0),(-80,-79,-78),(  27,  27,  27),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GrassSand
  ((0,0,0),(120, 121,122),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),( 48, 48, 48),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Swamp
  ((0,0,0),( 90,  91, 92),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),(40,40,40),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GroundSwamp
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, 44, 44),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Ice
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),( 247,  64,  65),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 47, 47,  47),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //SnowLittle
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),( 44, -4,-10),(220,212, 213),( 46, 46, 46),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //SnowMedium
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(203,204,205),(45,45,45),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //SnowBig
  ((0,0,0),(  0, 139,138),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),( 132, 132, 132),(   0,   0,   0),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Moss
  ((0,0,0),(180, 172,176),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 181, 173, 177),(  0,  0,  0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 182, 174, 178),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( 159, 159, 159),(   0,   0,   0),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Grey Mountains
  ((0,0,0),(188, 168,184),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 189, 169, 185),(  0,  0,  0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 190, 170, 186),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 164, 164, 164),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Red Mountains
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( -53, -50,-165),(245, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Black
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(-113,-112,-111),(  0,  0,  0),(  21,  21,  20),( -38, -39, -38),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(-65,-64,-247),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(-179,-175,-183),(-187,-167,-191),(  0, 0,    0),( 20, 20, 20),(   0,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //GroundStoned
  ((0,0,0),(123,-125,127),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 116,-117, 118),(  0,  0,  0),(-107,-106,-105),(-107,-106,-105),(  0,  0,  0),(-243,-242,-241),(114,115,119),( 0, 0, 0),(-22,-12,-23),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(-143,-200,-236),(-237,-200,-236),(-239,-200,-236),(245, 0,    0),(  0,  0,  0),( 192,   0,   0),(  0,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Water
  ((0,0,0),( 56,  57, 58),(0,0,0),(  0,  0,  0),( 0, 0, 0),(87,88,89),(-113,-112,-111),(  0,  0,  0),( 152, 153, 154),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),(   0,   0,   0),(  0,  0,   0),(  0,  0,  0),(   0,   0,   0),(155,0,0),(   0,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Coal
  ((0,0,0),(180, 172,176),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 181, 173, 177),(  0,  0,  0),( 183, 175, 179),(   0,   0,   0),(  0,  0,  0),( 182, 174, 178),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),( 49,171,  51),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( 144, 145, 146),(   0,   0,   0),(  0,  0,   0),(183,175,179),( 236, 200, 237),(  0,0,0),( 147,   0,   0),(   0,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Gold
  ((0,0,0),(188, 168,184),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 189, 169, 185),(  0,  0,  0),( 191, 167, 187),(   0,   0,   0),(  0,  0,  0),( 190, 170, 186),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),( 52,166, 54),( 0, 0, 0),(   0,   0,   0),(   0,   0,   0),( 148, 149, 150),(-53,-50,-165),(191,167,187),( 236, 200, 239),(  0,0,0),(   0,   0,   0),( 151,   0,   0),(   0, 0, 0),(   0, 0, 0)), //Iron
  ((0,0,0),(123,-125,127),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),( 116,-117, 118),(  0,  0,  0),(-107,-106,-105),(-107,-106,-105),(  0,  0,  0),(-243,-242,-241),(114,115,119),( 0, 0, 0),(-22,-12,-23),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(-143,-200,-236),(-237,-200,-236),(-239,-200,-236),(245, 0,    0),(  0,  0,  0),( 192, 192, 209),(  0,0,0),(-236,-200,-237),(-236,-200,-239),( 209, 0, 0),(   0, 0, 0)), //FastWater
  ((0,0,0),(  0,   0,  0),(0,0,0),(  0,  0,  0),( 0, 0, 0),( 0, 0, 0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(   0,   0,   0),(  0,  0,  0),(   0,   0,   0),(  0,  0,  0),( 0, 0, 0),(  0,  0,  0),(  0,  0,   0),(  0,  0,  0),( 0, 0, 0),(   0,   0,   0),( 159, 159, -15),( 164, 164,   7),(  0, 0,    0),(  0,  0,  0),(   0,   0,   0),(  0,0,0),( 147, 147, -15),(   0,   0,   0),(   0, 0, 0),(   7, 7, 7))  //Lava
  );

  //0     number of variants (1..X)
  //1..X  tile variants
  //
  RandomTiling: array [TTerrainKind, 0..15] of Byte = (
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (15,1,1,1,2,2,2,3,3,3,5,5,5,11,13,14), //reduced chance for "eye-catching" tiles
    (1,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (1,16,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (1,33,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (2,36,37,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),//Cobblestone
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), //swamp
    (3,41,42,43,0,0,0,0,0,0,0,0,0,0,0,0),//brownswamp
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (8,129,130,131,132,134,135,136,137,0,0,0,0,0,0,0),    //Stone
    (5,156,157,158,159,201{?},0,0,0,0,0,0,0,0,0,0),       //Grey
    (5,160,161,162,163,164,0,0,0,0,0,0,0,0,0,0),          //Rusty
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (1,196,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    (9,152,153,154,154,154,155,155,155,155,0,0,0,0,0,0), //Coal //enriched pattern
    (9,144,145,146,146,146,147,147,147,147,0,0,0,0,0,0), //Gold
    (9,148,149,150,150,150,151,151,151,151,0,0,0,0,0,0),  //Iron
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0), //FastWater
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) //Lava
  );


implementation
uses KM_Resource,  KM_Log, KM_Utils;


constructor TKMTerrainPainter.Create;
var
  I,K: Integer;
begin
  inherited;

  for I := 1 to MAX_MAP_SIZE do
  for K := 1 to MAX_MAP_SIZE do
    Land2[I,K].TerType := tkGrass; //Grass
end;


procedure TKMTerrainPainter.BrushTerrainTile(X, Y: SmallInt; aTerrainKind: TTerrainKind);
begin
  if not gTerrain.TileInMapCoords(X, Y) then
    Exit;

  Land2[Y, X].TerType := aTerrainKind;
  Land2[Y, X + 1].TerType := aTerrainKind;
  Land2[Y + 1, X + 1].TerType := aTerrainKind;
  Land2[Y + 1, X].TerType := aTerrainKind;

  gTerrain.Land[Y, X].Terrain := PickRandomTile(TTerrainKind(GameCursor.Tag1));
  gTerrain.Land[Y, X].Rotation := Random(4); //Random direction for all plain tiles
end;


function TKMTerrainPainter.PickRandomTile(aTerrainKind: TTerrainKind): Byte;
begin
  Result := Abs(Combo[aTerrainKind, aTerrainKind, 1]);
  if not RandomizeTiling or (RandomTiling[aTerrainKind, 0] = 0) then Exit;

  if aTerrainKind in [tkStoneMount..tkIronMount, tkCoal..tkIron] then
    //Equal chance
    Result := RandomTiling[aTerrainKind, Random(RandomTiling[aTerrainKind, 0]) + 1]
  else
  if Random(6) = 1 then
    //Chance reduced to 1/6
    Result := RandomTiling[aTerrainKind, Random(RandomTiling[aTerrainKind, 0]) + 1];
end;


procedure TKMTerrainPainter.RebuildMap(X,Y,Rad: Integer; aSquare: Boolean);
var
  I, K, pY, pX, Nodes, Rot, T: Integer;
  Tmp, Ter1, Ter2, A, B, C, D: TTerrainKind;
begin
  for I := -Rad to Rad do
  for K := -Rad to Rad do
  if aSquare or (Sqr(I) + Sqr(K) < Sqr(Rad)) then
  begin
    pX := EnsureRange(X+K, 1, gTerrain.MapX - 1);
    pY := EnsureRange(Y+I, 1, gTerrain.MapY - 1);

    //don't touch custom placed tiles (tkCustom type)
    if (Land2[pY  ,pX].TerType <> tkCustom)
    and (Land2[pY  ,pX+1].TerType <> tkCustom)
    and (Land2[pY+1,pX].TerType <> tkCustom)
    and (Land2[pY+1,pX+1].TerType <> tkCustom) then
    begin
      A := (Land2[pY    , pX    ].TerType);
      B := (Land2[pY    , pX + 1].TerType);
      C := (Land2[pY + 1, pX    ].TerType);
      D := (Land2[pY + 1, pX + 1].TerType);
      Rot := 0;
      Nodes := 1;

      //A-B
      //C-D
      Ter1 := tkCustom;
      Ter2 := tkCustom;

      if (A=B)or(C=D)  then begin Ter1:=A; Ter2:=C; Nodes:=2; if A<C then Rot:=2 else Rot:=0; end;
      if (A=C)or(B=D)  then begin Ter1:=A; Ter2:=B; Nodes:=2; if A<B then Rot:=1 else Rot:=3; end;

      //special case \ and /
      if A=D then begin Ter1:=A; Ter2:=B; Nodes:=4+1; Rot:=1; end;
      if B=C then begin Ter1:=A; Ter2:=B; Nodes:=4+2; Rot:=0; end;

      if (A=B)and(C=D) then begin Ter1:=A; Ter2:=C; Nodes:=2; if A<C then Rot:=2 else Rot:=0; end;
      if (A=C)and(B=D) then begin Ter1:=A; Ter2:=B; Nodes:=2; if A<B then Rot:=1 else Rot:=3; end;

      if (B=C)and(C=D) then begin Ter1:=C; Ter2:=A; Nodes:=3; if C<A then Rot:=3 else Rot:=1; end;
      if (A=C)and(C=D) then begin Ter1:=A; Ter2:=B; Nodes:=3; if A<B then Rot:=0 else Rot:=2; end;
      if (A=B)and(B=D) then begin Ter1:=A; Ter2:=C; Nodes:=3; if A<C then Rot:=2 else Rot:=0; end;
      if (A=B)and(B=C) then begin Ter1:=A; Ter2:=D; Nodes:=3; if A<D then Rot:=1 else Rot:=3; end;

      if (A=B)and(B=C)and(C=D) then begin Ter1:=A; Ter2:=A; Nodes:=4; Rot:=0; end;

      //Terrain table has only half filled, so make sure first comes bigger ID
      if Ter1 < Ter2 then
      begin
       Tmp := Ter1;
       Ter1 := Ter2;
       Ter2 := Tmp;
       case Nodes of
          1..3: Nodes := 4 - Nodes;  //invert nodes count
          5..6: Rot := 1;
        end;
      end;

      //Some tiles placed upside down or need other special treatment
      if Nodes < 4 then
      begin
        //Flip direction
        if Combo[Ter1, Ter2, Nodes] < 0 then
          Rot := (Rot + 2) mod 4;
        //For some weird reason lava needs to be rotated 90`
        if Ter1 = tkLava then
          Rot := (Rot + 1) mod 4;
      end;

      T := 0;
      if Nodes < 4 then T := Abs(Combo[Ter1, Ter2, Nodes]);     //transition tiles
      if Nodes = 4 then T := Abs(Combo[Ter1, Ter2, 1]);         //no transition
      if Nodes > 4 then T := Abs(Combo[Ter1, Ter2, 3]);         //transition use 1 or 3

      //for plain tiles only
      if Ter1 = Ter2 then
      begin
        T := PickRandomTile(Ter1);

        Rot := Random(4); //random direction for all plain tiles
      end;

      //Need to check if this tile was already smart-painted, "4-Nodes" hence default value is 0
      if Land2[pY,pX].Tiles <> Byte(Ter1)*Byte(Ter2)*(4-Nodes) then
      begin
        Land2[pY,pX].Tiles := Byte(Ter1)*Byte(Ter2)*(4-Nodes);//store not only nodes info, but also terrain type used
        gTerrain.Land[pY,pX].Terrain := T;
        gTerrain.Land[pY,pX].Rotation := Rot mod 4;
      end;
    end;
  end;
end;


procedure TKMTerrainPainter.EditBrush(aLoc: TKMPoint; aTile: Byte);
var
  I,K,Size,Rad: Integer;
begin
  //Cell below cursor
  MapXc := EnsureRange(round(GameCursor.Float.X+0.5),1,gTerrain.MapX);
  MapYc := EnsureRange(round(GameCursor.Float.Y+0.5),1,gTerrain.MapY);

  //Node below cursor
  MapXn := EnsureRange(round(GameCursor.Float.X+1),1,gTerrain.MapX);
  MapYn := EnsureRange(round(GameCursor.Float.Y+1),1,gTerrain.MapY);

  Size := GameCursor.MapEdSize;
  Rad := Size div 2;

  if Size = 0 then
  begin
    if (MapXn2 <> MapXn) or (MapYn2 <> MapYn) then
      Land2[MapYn, MapXn].TerType := TTerrainKind(GameCursor.Tag1);
  end
  else
    if (MapXc2 <> MapXc) or (MapYc2 <> MapYc) then
    begin
      //There are two brush types here, even and odd size
      if Size mod 2 = 1 then
      begin
        //first comes odd sizes 1,3,5..
        for I:=-Rad to Rad do for K:=-Rad to Rad do
        if (GameCursor.MapEdShape = hsSquare) or (Sqr(I) + Sqr(K) < Sqr(Rad + 0.5)) then               //Rounding corners in a nice way
        BrushTerrainTile(MapXc+K, MapYc+I, TTerrainKind(GameCursor.Tag1));
      end
      else
      begin
        //even sizes 2,4,6..
        for I:=-Rad to Rad-1 do for K:=-Rad to Rad-1 do
        if (GameCursor.MapEdShape = hsSquare) or (Sqr(I + 0.5) + Sqr(K + 0.5) < Sqr(Rad)) then           //Rounding corners in a nice way
        BrushTerrainTile(MapXc+K, MapYc+I, TTerrainKind(GameCursor.Tag1));
      end;
    end;
  RebuildMap(MapXc, MapYc, Rad+3, (GameCursor.MapEdShape = hsSquare)); //+3 for surrounding tiles

  MapXn2 := MapXn;
  MapYn2 := MapYn;
  MapXc2 := MapXc;
  MapYc2 := MapYc;

  gTerrain.UpdatePassability(KMRectGrow(KMRect(aLoc), Rad+1));
end;


procedure TKMTerrainPainter.EditHeight;
var
  I, K: Integer;
  Rad, Slope, Speed: Byte;
  Tmp: Single;
  R: TKMRect;
  aLoc : TKMPointF;
  aRaise: Boolean;
begin
  aLoc    := KMPointF(GameCursor.Float.X+1, GameCursor.Float.Y+1); // Mouse point
  aRaise  := ssLeft in GameCursor.SState;         // Raise or Lowered (Left or Right mousebtn)
  Rad     := GameCursor.MapEdSize;                // Radius basing on brush size
  Slope   := GameCursor.MapEdSlope;               // Elevation slope
  Speed   := GameCursor.MapEdSpeed;               // Elvation speed
  for I := Max((round(aLoc.Y) - Rad), 1) to Min((round(aLoc.Y) + Rad), gTerrain.MapY) do
  for K := Max((round(aLoc.X) - Rad), 1) to Min((round(aLoc.X) + Rad), gTerrain.MapX) do
  begin

    // We have square area basing on mouse point +/- radius
    // Now we need to check whether point is inside brush type area(circle etc.)
    // Every MapEdShape case has it's own check routine
    case GameCursor.MapEdShape of
      hsCircle: Tmp := Max((1 - GetLength(I - round(aLoc.Y), round(K - aLoc.X)) / Rad), 0);   // Negative number means that point is outside circle
      hsSquare: Tmp := 1 - Max(Abs(I - round(aLoc.Y)), Abs(K - round(aLoc.X))) / Rad;
      else      Tmp := 0;
    end;

    // Default cursor mode is elevate/decrease
    if GameCursor.Mode = cmEqualize then
    begin // START Unequalize
      if aRaise then
      begin
        if (i > 1) and (k >1) and (i < gTerrain.MapY - 1) and (k < gTerrain.MapX - 1) then
        begin
        // Unequalize compares heights of adjacent tiles and increases differences
          if (gTerrain.Land[I,K].Height < gTerrain.Land[I-1,K+1].Height) then
            Tmp := -Min(gTerrain.Land[I-1,K+1].Height - gTerrain.Land[I,K].Height, Tmp)
          else
          if (gTerrain.Land[I,K].Height > gTerrain.Land[I-1,K+1].Height) then
            Tmp := Min(gTerrain.Land[I,K].Height - gTerrain.Land[I-1,K+1].Height, Tmp)
          else
            Tmp := 0;
        end
        else
          Tmp := 0;
       //END Unequalize
      end else
      // START Flatten
      begin
      //Flatten compares heights of mouse click and active tile then it increases/decreases height of active tile
        if (gTerrain.Land[I,K].Height < gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height) then
          Tmp := - Min(gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height - gTerrain.Land[I,K].Height, Tmp)
        else
          if (gTerrain.Land[I,K].Height > gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height) then
            Tmp := Min(gTerrain.Land[I,K].Height - gTerrain.Land[Max(trunc(aLoc.Y), 1), Max(trunc(aLoc.X), 1)].Height, Tmp)
          else
            Tmp := 0;
      end;
      //END Flatten
    end;
    //COMMON PART FOR Elevate/Lower and Unequalize/Flatten
    //Compute resulting floating-point height
    Tmp := power(abs(Tmp),(Slope+1)/6)*sign(Tmp); //Modify slopes curve
    Tmp := Tmp * (4.75/14*(Speed - 1) + 0.25);
    Tmp := EnsureRange(gTerrain.Land[I,K].Height + HeightAdd[I,K]/255 + Tmp * (Byte(aRaise)*2 - 1), 0, 100); // (Byte(aRaise)*2 - 1) - LeftButton pressed it equals 1, otherwise equals -1
    gTerrain.Land[I,K].Height := trunc(Tmp);
    HeightAdd[I,K] := round(frac(Tmp)*255); //write fractional part in 0..255 range (1Byte) to save us mem
  end;

  R := KMRectGrow(KMRect(aLoc), Rad);
  gTerrain.UpdateLighting(R);
  gTerrain.UpdatePassability(R);
end;


procedure TKMTerrainPainter.EditTile(aLoc: TKMPoint; aTile, aRotation: Byte);
begin
  if gTerrain.TileInMapCoords(aLoc.X, aLoc.Y) then
  begin
    Land2[aLoc.Y, aLoc.X].TerType := tkCustom;
    gTerrain.Land[aLoc.Y, aLoc.X].Terrain := aTile;
    gTerrain.Land[aLoc.Y, aLoc.X].Rotation := aRotation;
    gTerrain.UpdatePassability(aLoc);
  end;
end;


procedure TKMTerrainPainter.MagicWater(aLoc: TKMPoint);
type
  TMagicType = (mtNone, mtWater, mtShore);
var
  FilledTiles: array of array of TMagicType;

  function CanRotate(aTileID: Byte): Boolean;
  begin
    Result := fResource.Tileset.TileIsWater(aTileID)
              and not (aTileID in [114, 115, 119, 194, 200, 210, 211, 235, 236]);
  end;

  procedure MagicFillArea(X, Y: Word);
  begin
    if FilledTiles[Y, X] <> mtNone then
      Exit;

    //Detect rotateable shores
    if (gTerrain.Land[y,x].Terrain in [126, 127]) then
      FilledTiles[y,x] := mtShore;

    //Detect water
    if CanRotate(gTerrain.Land[y,x].Terrain) then
    begin
      FilledTiles[y,x] := mtWater;

      if x-1>=1 then
      begin
        if y-1>=1 then             MagicFillArea(x-1,y-1);
                                   MagicFillArea(x-1,y  );
        if y+1<=gTerrain.MapY then MagicFillArea(x-1,y+1);
      end;

      if y-1>=1 then               MagicFillArea(x,y-1);
      if y+1<=gTerrain.MapY then   MagicFillArea(x,y+1);

      if x+1<=gTerrain.MapX then
      begin
        if y-1>=1 then             MagicFillArea(x+1,y-1);
                                   MagicFillArea(x+1,y  );
        if y+1<=gTerrain.MapY then MagicFillArea(x+1,y+1);
      end;
    end;
  end;

var
  I,K:Integer;
  NewRot: Byte;
begin
  if not CanRotate(gTerrain.Land[aLoc.Y, aLoc.X].Terrain) then
    Exit;

  SetLength(FilledTiles, gTerrain.MapY+1, gTerrain.MapX+1);

  MagicFillArea(aLoc.X,aLoc.Y);

  NewRot := (gTerrain.Land[aLoc.Y,aLoc.X].Rotation + 1) mod 4;
  for I := 1 to gTerrain.MapY do
    for K := 1 to gTerrain.MapX do
      case FilledTiles[I,K] of
        mtWater:  begin
                    gTerrain.Land[I,K].Rotation := NewRot;
                  end;
        mtShore:  begin
                    //These shores can be flipped
                    if (gTerrain.Land[I,K].Terrain in [126, 127]) then
                      case gTerrain.Land[I,K].Rotation of
                        0: if NewRot = 3 then gTerrain.Land[I,K].Terrain := 126 else
                           if NewRot = 1 then gTerrain.Land[I,K].Terrain := 127;

                        1: if NewRot = 0 then gTerrain.Land[I,K].Terrain := 126 else
                           if NewRot = 2 then gTerrain.Land[I,K].Terrain := 127;

                        2: if NewRot = 1 then gTerrain.Land[I,K].Terrain := 126 else
                           if NewRot = 3 then gTerrain.Land[I,K].Terrain := 127;

                        3: if NewRot = 2 then gTerrain.Land[I,K].Terrain := 126 else
                           if NewRot = 0 then gTerrain.Land[I,K].Terrain := 127;
                      end;
                  end;
      end;
end;


function TKMTerrainPainter.GetTerrainKind(Y, X: Integer): TTerrainKind;
begin
  Result := Land2[Y, X].TerType;
end;


procedure TKMTerrainPainter.SetTerrainKind(Y, X: Integer; Kind: TTerrainKind);
begin
  Land2[Y, X].TerType := Kind;
end;


procedure TKMTerrainPainter.GenerateAddnData;
const
  SPECIAL_TILES = [24,25,194,198,199,202,206,207,214,216..219,221..233,246]; //Waterfalls and bridges
  OTHER_WATER_TILES = [193,208,209,240,244]; //Water tiles not used in painting (fast, straight, etc.)
  //Accuracies
  ACC_MAX = 5;  //Special tiles
  ACC_HIGH = 4; //Primary tiles
  ACC_MED = 3; //Random tiling
  ACC_LOW = 2; //Edges
  ACC_MIN = 1; //Coal random tiling (edges are better in this case)
  ACC_NONE = 0;
var
  Accuracy: array [1 .. MAX_MAP_SIZE, 1 .. MAX_MAP_SIZE] of Byte;

  procedure SetTerrainKindVertex(X,Y: Integer; T:TTerrainKind; aAccuracy:Byte);
  begin
    if not gTerrain.TileInMapCoords(X,Y) then Exit;

    //Special rules to fix stone hill corners:
    // - Never overwrite tkStoneMount with tkGrass
    // - Always allow tkStoneMount to overwrite tkGrass
    if (Land2[Y,X].TerType = tkStoneMount) and (T = tkGrass) then Exit;
    if (Land2[Y,X].TerType = tkGrass) and (T = tkStoneMount) then aAccuracy := ACC_MAX;

    //Skip if already set more accurately
    if aAccuracy < Accuracy[Y,X] then Exit;

    Land2[Y,X].TerType := T;
    Accuracy[Y,X] := aAccuracy;
  end;

  procedure SetTerrainKindTile(X,Y: Integer; T:TTerrainKind; aAccuracy:Byte);
  begin
    SetTerrainKindVertex(X  , Y  , T, aAccuracy);
    SetTerrainKindVertex(X+1, Y  , T, aAccuracy);
    SetTerrainKindVertex(X  , Y+1, T, aAccuracy);
    SetTerrainKindVertex(X+1, Y+1, T, aAccuracy);
  end;

var
  I,K,J,Rot: Integer;
  A: Byte;
  T, T2: TTerrainKind;
begin
  for I := 1 to MAX_MAP_SIZE do
  for K := 1 to MAX_MAP_SIZE do
  begin
    Land2[I,K].TerType := tkCustom; //Everything custom by default
    Accuracy[I,K] := ACC_NONE;
  end;

  for I := 1 to MAX_MAP_SIZE do
  for K := 1 to MAX_MAP_SIZE do
    //Special tiles such as bridges should remain as tkCustom
    if gTerrain.Land[I,K].Terrain in SPECIAL_TILES then
      SetTerrainKindTile(K, I, tkCustom, ACC_MAX) //Maximum accuracy
    else
      //Water tiles not used in painting (fast, straight, etc.)
      if gTerrain.Land[I,K].Terrain in OTHER_WATER_TILES then
        SetTerrainKindTile(K, I, tkWater, ACC_MED) //Same accuracy as random tiling (see below)
      else
        for T := Low(TTerrainKind) to High(TTerrainKind) do
          if T <> tkCustom then
          begin
            //METHOD 1: Terrain type is the primary tile for this terrain
            if gTerrain.Land[I,K].Terrain = Abs(Combo[T,T,1]) then
            begin
              SetTerrainKindTile(K, I, T, ACC_HIGH);
              Break; //Neither of the methods below can beat this one, so save time and don't check more TerrainKinds
            end;

            //METHOD 2: Terrain type is in RandomTiling
            for J := 1 to RandomTiling[T,0] do
              if gTerrain.Land[I,K].Terrain = RandomTiling[T,J] then
              begin
                A := ACC_MED; //Random tiling is fairly accurate
                if T = tkCoal then A := ACC_MIN; //Random coal tiles are also used for edges, so edges are more accurate
                SetTerrainKindTile(K, I, T, A);
              end;

            //METHOD 3: Edging data
            A := ACC_LOW; //Edging data is not as accurate as other methods (some edges reuse the same tiles)
            for T2 := Low(TTerrainKind) to High(TTerrainKind) do
            begin
              //1 vertex is T, 3 vertexes are T2
              if gTerrain.Land[I,K].Terrain = Abs(Combo[T,T2,1]) then
              begin
                Rot := gTerrain.Land[I,K].Rotation mod 4;
                if Combo[T,T2,1] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
              //Half T, half T2
              if gTerrain.Land[I,K].Terrain = Abs(Combo[T,T2,2]) then
              begin
                Rot := gTerrain.Land[I,K].Rotation mod 4;
                if Combo[T,T2,2] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
              //3 vertex are T, 1 vertexes is T2
              if gTerrain.Land[I,K].Terrain = Abs(Combo[T,T2,3]) then
              begin
                Rot := gTerrain.Land[I,K].Rotation mod 4;
                if Combo[T,T2,3] < 0 then Rot := (Rot+2) mod 4; //Flip
                case Rot of
                  0: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T2, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  1: begin
                       SetTerrainKindVertex(K,   I,   T2, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  2: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T2, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T, A);
                     end;
                  3: begin
                       SetTerrainKindVertex(K,   I,   T, A);
                       SetTerrainKindVertex(K+1, I,   T, A);
                       SetTerrainKindVertex(K,   I+1, T, A);
                       SetTerrainKindVertex(K+1, I+1, T2, A);
                     end;
                end;
              end;
            end;
          end;
end;


//Skip the KaM data and load MapEd vertice info
procedure TKMTerrainPainter.LoadFromFile(FileName: string);
var
  I,K: Integer;
  TerType: ShortInt; //Krom's editor saves terrain kind as ShortInt
  S: TKMemoryStream;
  NewX,NewY: Integer;
  ResHead: packed record x1:word; Allocated,Qty1,Qty2,x5,Len17:integer; end;
  Chunk: AnsiString;
  MapEdChunkFound: Boolean;
begin
  if not CheckFileExists(FileName) then Exit;

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(FileName);
    S.Read(NewX); //We read header to new variables to avoid damage to existing map if header is wrong
    S.Read(NewY);
    Assert((NewX = gTerrain.MapX) and (NewY = gTerrain.MapY), 'Map size does not match map size');

    //Skip terrain data
    S.Seek(23 * NewX * NewY, soFromCurrent);

    //For now we just throw away the resource footer because we don't understand it (and save a blank one)
    S.Read(ResHead, 22);
    S.Seek(17 * ResHead.Allocated, soFromCurrent);

    //ADDN
    MapEdChunkFound := False;
    if S.Position < S.Size then
    begin
      Chunk := '    ';
      S.Read(Chunk[1], 4);
      if Chunk = 'ADDN' then
      begin
        S.Read(Chunk[1], 4);
        if Chunk = 'TILE' then
        begin
          S.Read(I, 4); //Chunk size
          S.Read(I, 4); //Cypher - ommited
          for I := 1 to NewY do
          for K := 1 to NewX do
          begin
            //Krom's editor saves negative numbers for tiles placed manually
            S.Read(TerType, 1);
            if InRange(TerType, ShortInt(Low(TTerrainKind)), ShortInt(High(TTerrainKind))) then
              Land2[I,K].TerType := TTerrainKind(TerType)
            else
              Land2[I,K].TerType := tkCustom;
          end;
          MapEdChunkFound := True; //Only set it once it's all loaded successfully
        end
        else
          gLog.AddNoTime(FileName + ' has no MapEd.TILE chunk');
      end
      else
        gLog.AddNoTime(FileName + ' has no MapEd.ADDN chunk');
    end
    else
      gLog.AddNoTime(FileName + ' has no MapEd chunk');
  finally
    S.Free;
  end;
  //We can regenerate the MapEd data if it's missing (won't be as good as the original)
  if not MapEdChunkFound then
  begin
    gLog.AddNoTime('Regenerating missing MapEd data as best as we can');
    GenerateAddnData;
  end;
end;


procedure TKMTerrainPainter.SaveToFile(FileName: string);
var
  I,K: Integer;
  S: TKMemoryStream;
  NewX,NewY: Integer;
  ResHead: packed record x1:word; Allocated,Qty1,Qty2,x5,Len17:integer; end;
begin
  if not CheckFileExists(FileName) then Exit;

  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(FileName);
    S.Read(NewX); //We read header to new variables to avoid damage to existing map if header is wrong
    S.Read(NewY);
    Assert((NewX = gTerrain.MapX) and (NewY = gTerrain.MapY), 'Map size does not match map size');

    //Skip terrain data
    S.Seek(23 * NewX * NewY, soFromCurrent);

    //For now we just throw away the resource footer because we don't understand it (and save a blank one)
    S.Read(ResHead, 22);
    S.Seek(17 * ResHead.Allocated, soFromCurrent);

    S.Write(AnsiString('ADDN')[1], 4);
    S.Write(AnsiString('TILE')[1], 4);

    S.Write(Integer(NewX * NewY)); //Chunk size
    S.Write(Integer(0)); //Cypher - ommited
    for I := 1 to NewY do
    for K := 1 to NewX do
      S.Write(Land2[I,K].TerType, 1);

    S.SaveToFile(FileName);
  finally
    S.Free;
  end;
end;


//Only MapEd accesses it
procedure TKMTerrainPainter.UpdateStateIdle;
begin
  case GameCursor.Mode of
    cmElevate,
    cmEqualize:  if (ssLeft in GameCursor.SState) or (ssRight in GameCursor.SState) then
                    EditHeight;
    cmBrush:     if (ssLeft in GameCursor.SState) then
                    EditBrush(GameCursor.Cell, GameCursor.Tag1);
    cmTiles:     if (ssLeft in GameCursor.SState) then
                    if GameCursor.MapEdDir in [0..3] then //Defined direction
                      EditTile(GameCursor.Cell, GameCursor.Tag1, GameCursor.MapEdDir)
                    else //Random direction
                      EditTile(GameCursor.Cell, GameCursor.Tag1, KaMRandom(4));
  end;
end;


end.