
class SwitchingCameras extends Behavior {
  
  SwitchingCameras(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    if (frameCount % framesBeforeSwitch == 0) resetMappings();
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
