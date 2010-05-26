

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
//    if (localVideo == null) return;
//    image(localVideo,0,0,w,h/2);
    if (cams[0] != null) image(cams[0],0,0,w/2,h/2);
    if (cams[1] != null) image(cams[1],w/2,0,w/2,h/2);
    if (cams[2] != null) image(cams[2],0,h/2,w/2,h/2);
    if (cams[3] != null) image(cams[3],w/2,h/2,w/2,h/2);
  }
}
