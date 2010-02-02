
int[] cameraMappings = { 1, 0, 2, 1 };

class CameraFeedSketch extends Behavior {
  
  CameraFeedSketch(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    if (frameCount % 80 == 0) resetMappings();
    splitScreens();
  }
  
  void drawScreen(int i) {
    if (cams[cameraMappings[i]] != null)
      image(cams[cameraMappings[i]],0,0,w,h);
  }
  
  void resetMappings() {
    int[] choices = {0,1,2,3,4,5};
    for (int i=0; i<cameraMappings.length;) {
      int r = round(random(choices.length-1));
      cameraMappings[i] = choices[r];
      if (choices[r] == -1) continue;
      choices[r] = -1; 
      i++;
    }
  }
}
