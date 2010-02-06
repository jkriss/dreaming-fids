
int[] cameraMappings = { 0, 1, 2, 3 };

class CameraFeedSketch extends Behavior {
  
  CameraFeedSketch(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
//    if (frameCount % 80 == 0) resetMappings();
    splitScreens();
  }
  
  void drawScreen(int i) {
    int camIndex = cameraMappings[i];
    PImage c = cams[camIndex];
    if (c != null) {
      image(c,0,0,w,h);
    }
    fill(45,99,137);
    noStroke();
    rect(5,5,fish[camIndex].activity/10000,10);
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
