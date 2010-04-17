
class RawCameras extends Behavior {

  int[] cameraMappings = { 0, 1, 2, 3 };
  
  RawCameras(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    splitScreens();
  }
    
  void drawScreen(int screenIndex) {
    int camIndex = cameraMappings[screenIndex];
    
    // show video
    PImage c = cams[camIndex];
    if (c == null) return;
  
    image(c,0,0,w,h);  
  }
 
}
