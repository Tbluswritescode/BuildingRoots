/*Written by Tristan Blus, started 3/19/2022
      revised 3/22/2022
      revised 3/24/2022 -- Renamed "Building Roots"

OUTDATED FILES: GP.Java and Root.Java are currently inactive files which I hope to use to create path objects in time

a number of improvements must be made from this point.  There need to be significantly more path types and they need to be ordered such that swaping up or
down by an increment of 1 will create a smooth curve.  This will make the swap function work significatnly better to create fewer hard angles and instead
gently curve the roots as they grow.  Further improvements are as follows:
    Find a way to continue a current path and spawn a second path from this path to branch
      ####limit ranges of random path swaps to prevent the zig zag problem.  
    Play with the framerate and swap threshholds to find the most root-like appearance.  
    Simplify global variables section and privatize any variables which can be privatized
    find a way to reduce the number of repetitive calls in draw
    Improve draw to allow for a variable number of paths rather than a constant 4
    Convert all paths to path objects
There are many further improvements to be made which I have not yet taken the time to assess

*/

import java.util.*;
import java.lang.Math;

//GLOBALS
int framecount = 1;
PGraphics img;
int horiz_size = 2450;
int vert_size = 2000;
int horiz_mid = int(.5 * horiz_size);
int vert_mid = 10;

int x = horiz_mid;
int y = vert_mid;
int q = horiz_mid;
int p = vert_mid;
int s = horiz_mid - int(random(50));
int t = vert_mid;
int v = horiz_mid + int(random(50));
int w = vert_mid;

int x1 = horiz_mid;
int y1 = vert_mid;
int q1 = horiz_mid;
int p1 = vert_mid;
int s1 = horiz_mid - int(random(50));
int t1 = vert_mid;
int v1 = horiz_mid + int(random(50));
int w1 = vert_mid;

int pathA = int(random(16));
int prevpathA = pathA;
int pathB = int(random(16));
int prevpathB = pathB;
int pathC = int(random(16));
int prevpathC = pathC;
int pathD = int(random(16));
int prevpathD = pathD;

boolean forward = true;
boolean down = true;

int count = 0;
//END GLOBALS

/* Enum represents growth paths, D stands for down, L for left, R for right.  As we get in to letter repeats the only difference with pathing is the degree / speed
of growth */

enum GP {
  DL(0),
  LD(1),
  DSL(2),
  DR(3),
  RD(4),
  DSR(5),
  DRR(6),
  DLL(7),
  DDRR(8),
  DDLL(9),
  DDL(10),
  DDR(11),
  DDDL(12),
  DDDR (13),
  DDDLLL(14),
  DDDRRR(15);
  
  int value;
  static Map map = new HashMap<>();
  
  GP(int value) {
        this.value = value;
  }
  static {
        for (GP path : GP.values()) {
            map.put(path.value, path);
        }
  }
  static GP valueOf(int path) { 
        return (GP) map.get(path);
  }
}
//END ENUM


void setup() { 
  /*This function sets up the window and fill colors of the window, and objects within it, and also changes the framerate
    
    PARAMETERS:: NONE
    
    RETURNS:: NONE
  */
  textSize(100);
  size(2450, 2000); 
  background(255, 255, 255, 0); 
  frameRate(240);
  fill(100, 120, 100);
  img = createGraphics(horiz_size, vert_size);
  PFont font = loadFont("AlHor-48.vlw");
 

}

void draw() { 
  /*This function executes as many times per second as the framerate indicates, it collects each path, and draws a single point (either a 1 or a 0) along that path
  
    PARAMETERS:: NONE
  
    RETURNS:: NONE
  */
  GP xx = GP.valueOf(pathA);
  //GP yy = GP.valueOf(prevpathA);
  GP qq = GP.valueOf(pathB);
  //GP pp = GP.valueOf(prevpathB);
  GP tt = GP.valueOf(pathC);
  //GP ss = GP.valueOf(prevpathC);
  GP vv = GP.valueOf(pathD);
  //GP ww = GP.valueOf(prevpathD);
  
  int[] xy = drawHelp(x, y, xx);
  //int[] xxy = drawHelp(x, y, yy);
  int[] qp = drawHelp(q, p, qq);
  //int[] qqp = drawHelp(q, p, pp);
  int[] st = drawHelp(s, t, tt);
  //int[] sst = drawHelp(s, t, ss);
  int[] vw = drawHelp(v, w, vv);
  //int[] vvw = drawHelp(v, w, ww);
  //int[] xy = drawHelp(x, y, yy);
  //int[] qp = drawHelp(q, p, pp);
  //int[] st = drawHelp(s, t, ss);
  //int[] vw = drawHelp(v, w, ww);
  
  update(outOfRange(xy), 0);
  update(outOfRange(qp), 1);
  update(outOfRange(st), 2);
  update(outOfRange(vw), 3);
  //update(outOfRange(xxy), 0);
  //update(outOfRange(qqp), 1);
  //update(outOfRange(sst), 2);
  //update(outOfRange(vvw), 3);
  
  float rand = random(4);
  if (rand < 1.5){
    forward = false;
  }
  if (rand > 1.5 && rand < 3 ){
    down = false;
  }else{
    forward = true;
    down = true;
  }
  count += 1;
  if (count == 20){
    prevpathA = pathA;
    pathA = swapPath(count, pathA);
  }else if (count == 40){
    prevpathB = pathB;
    pathB = swapPath(count, pathB);
  }else if (count == 60){
    prevpathC = pathC;
    pathC = swapPath(count, pathC);
  }else if (count == 80){
    prevpathD = pathD;
    pathD = swapPath(count, pathA);
  }else if (count > 100){
    updateAllPaths();
    count = 0;
  }
  if (framecount < 10){
    img.save("frames/000" + framecount + ".png");
  }else if (framecount < 100){
    img.save("frames/00" + framecount + ".png");
  }else if (framecount < 1000){
    img.save("frames/0" + framecount + ".png");
  }else {
    img.save("frames/" + framecount + ".png");
  }
  framecount += 1;
  image(img, 0, 0);
}


int[] drawHelp(int x, int y, GP path){
  /*This is the function which does the actual drawing of 1s and 0s, it is called repeatedly in draw.  
    It also sets the coordinates for the next object along that path
    
    PARAMETERS:: 
      INTEGER: x
        The x coordinate to be drawn at
      INTEGER: y
        The y coordinate to be drawn at
      GrowthPath: path
        The path along which the coordinates are currently being placed at call time
    
    RETURNS:: 
      INTEGER ARRAY: drawHelp 
        Contains and X and Y values for the next placement
  */
  int is0 = int(random(2));
  img.beginDraw();
  img.fill(0, 0, 0);
  if (is0 == 0){
    img.text("0", x, y);
  }else{img.text("1", x, y);}
  
  double tSize = 28 + (.8 * (count < 60 ? count : 120 - count));
  img.textSize((float)tSize);
  img.endDraw();
  /*this section needs major expansion, the way to improve this project is by adding significantly more combinations of random numbers to work with.*/
  int randlrg = int(random(23, 28));
  int randmed = int(random(13, 18));
  int randsml = int(random(3, 8));
  int randhmed = int(random(18, 23));
  int randlmed = int(random(8, 13));
  
  x = newCoord(x, path, true, randlrg, randsml, randmed, randhmed, randlmed);
  y = newCoord(y, path, false, randlrg, randsml, randmed, randhmed, randlmed);
  return new int[]{x, y};
}



int newCoord(int coord, GP x, boolean isX, int lrg, int sml, int med, int hmed, int lmed){
  /*This function takes many parameters all used to change a set of coordinates to the next point along a given growth path
    
    PARAMETERS :: 
      INTEGER: coord 
        the coordinate to be changed
      GrowthPath: x
        the current growth path of the coordinate to be changes
      BOOLEAN: isX
        tells the function if the given coordinate is considered an X coordinate
      INTEGER: lrg
        large random integer
      INTEGER: sml
        small random integer
      INTEGER: med
        medium random integer
    
    RETURNS:: 
      INTEGER: newCoord
        the newly updated coordinate value
  */
  if (x == GP.DL){
    if (isX){
      coord -= random(sml);
    }else{
      coord += random(lrg);
    }
  }else if (x == GP.DR){
    if (isX){
      coord += random(sml);
    }else{
      coord += random(lrg);
    }
  } else if (x == GP.LD){
    if (isX){
      coord -= random(med);
    }else{
      coord += random(sml);
    }
  }else if (x == GP.RD){
    if (isX){
      coord += random(med);
    }else{
      coord += random(sml);
    }
  }else if (x == GP.DRR){
    if (isX){
      coord += random(lrg);
    }else{
      coord += random(sml);
    }
  }else if (x == GP.DLL){
    if (isX){
      coord -= random(lrg);
    }else{
      coord += random(sml);
    }
  }else if (x == GP.DSL){
    if (isX){
      coord -= random(med);
    }else{
      coord += random(lrg);
    }
  }else if (x == GP.DSR){
    if (isX){
      coord += random(med);
    }else{
      coord += random(lrg);
    }
  }else if (x == GP.DDLL){
    if (isX){
      coord -= random(med);
    }else{
      coord += random(med);
    }
  }else if (x == GP.DDRR){
    if (isX){
      coord += random(med);
    }else{
      coord += random(med);
    }
  }else if (x == GP.DDDLLL){
    if (isX){
      coord -= random(med);
    }else{
      coord += random(med);
    }
  }else if (x == GP.DDDRRR){
    if (isX){
      coord += random(lrg);
    }else{
      coord += random(lrg);
    }
  }else if (x == GP.DDL){
    if (isX){
      coord -= random(sml);
    }else{
      coord += random(lmed);
    }
  }else if (x == GP.DDR){
    if (isX){
      coord += random(sml);
    }else{
      coord += random(lmed);
    }
  }else if (x == GP.DDDL){
    if (isX){
      coord -= random(sml);
    }else{
      coord += random(hmed);
    }
  }else if (x == GP.DDDR){
    if (isX){
      coord += random(sml);
    }else{
      coord += random(hmed);
    }
  }
  return int(coord);
}
int[] outOfRange(int[] xy){
  /*The function takes an integer array xy which contains a set or coordinates.  It checks them against size limits of the window and returns the path
    to the origin point at (500,400)
    
    PARAMETERS:: 
      INTEGER ARRAY: xy
        Contains the coordinates to be checked for range
        
    RETURNS:: 
      INTEGER ARRAY: outOfRange
        If the coordinates are out of range of the screen they reset back to the origin point, and the origin point is returned as the new coordinates
  */
  int x = xy[0];
  int y = xy[1];
  
  if (x > horiz_size || y > vert_size || x < 0 || y < 0){
    //x = int(random(horiz_size));
    //y = int(random(vert_size));
    x = horiz_mid;
    y = vert_mid;
    forward = false;
    down = false;
  }
  return new int[] {x, y};
}
int swapPath(int c, int path){
  /*Swaps the current integer representation of the current Growth Path to the next or previous integer
  
    PARAMETERS::
      INTEGER: c (count)
        The count of draws completed since last reset of count
      INTEGER: path
        The integer representation of the current path
    
    RETURNS:: 
      INTEGER: swapPath
        The integer representation of the incremented/decremented Growth Path
  */
  if (path > 6){
    path -= 1;
  }if (path > 0) {
    path += 1;
  }else{
    path += 1;
  }
  return path;
}

void update(int[] ab, int swap){
  /*PARAMETERS:: 
    RETURNS:: NONE*/
  int a = ab[0];
  int b = ab[1];
  switch (swap){
    case 0: x = a;
            y = b;
            break;
    case 1: q = a;
            p = b;
            break;
    case 2: s = a;
            t = b;
            break;
    case 3: v = a;
            w = b;
            break;
    default: break;
  }
}

void updateAllPaths(){
  prevpathA = pathA;
  pathA = int(random(16));
  prevpathB = pathB;
  pathB = int(random(16));
  prevpathC = pathC;
  pathC = int(random(16));
  prevpathD = pathD;
  pathD = int(random(16));

}
