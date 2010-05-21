

class TestPattern extends Behavior {
  
  PImage pattern;
  
  TestPattern(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
    pattern = loadImage("data/test-pattern.gif");
    println("loaded pattern: " + pattern);
  }
  
  void draw() {
    splitScreens();
  }
    
  void drawScreen(int screenIndex) {
    image(pattern,0,0,w,h);
  }
}
