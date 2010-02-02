
int[] cameraMappings = { 1, 0, 2, 1 };

class CameraFeedSketch extends Behavior {
  
  CameraFeedSketch(PApplet parent, int numScreens) {
    super(parent, numScreens); 
  }
  
  void setup() {
  }
  
  void draw() {
    splitScreens();
  }
  
  void drawScreen(int i) {
    if (cams[cameraMappings[i]] != null)
      image(cams[cameraMappings[i]],0,0,w,h);
  }
}
