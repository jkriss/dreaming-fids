

class RawInput extends Behavior {
  
  RawInput(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  void draw() {
    splitScreens();
  }
    
  void drawScreen(int screenIndex) {
    if (localVideo == null) return;
    image(localVideo,0,0,w,h);
  }
}
