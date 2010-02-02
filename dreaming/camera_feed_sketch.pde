
int[] cameraMappings = { 1, 0, 2, 1 };

class CameraFeedSketch extends Behavior {
  
  CameraFeedSketch(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    splitScreens();
  }
  
  void drawScreen(int i) {
    if (frameCount % 70 == 0) resetMappings();
    if (cams[cameraMappings[i]] != null)
      image(cams[cameraMappings[i]],0,0,w,h);
  }
  
  void resetMappings() {
    for (int i=0; i<cameraMappings.length; i++)
      cameraMappings[i] = round(random(5)); 
  }
}
