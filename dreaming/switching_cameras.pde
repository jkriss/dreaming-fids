
class SwitchingCameras extends Behavior {

  int[] cameraMappings = { 0, 1, 2, 3 };
  
  SwitchingCameras(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    if (frameCount % 80 == 0) resetMappings();
    splitScreens();
  }
    
  void drawScreen(int screenIndex) {
    int camIndex = cameraMappings[screenIndex];
    
    // show video
    PImage c = cams[camIndex];
    if (c == null) return;
  
    image(c,0,0,w,h);  
  }
  
  void resetMappings() {
    int[] choices = {0,1,2,3};
    for (int i=0; i<cameraMappings.length;) {
      int r = round(random(choices.length-1));
      cameraMappings[i] = choices[r];
      if (choices[r] == -1) continue;
      choices[r] = -1; 
      i++;
    }
  }
}
