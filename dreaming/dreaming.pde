
Behavior[] behaviors = new Behavior[1];
Behavior activeBehavior;
int[] screenSize = {800, 480};
int numScreens = 4;
void setup() {
  float scale = 0.38;
  size((int)(screenSize[0]*numScreens*scale),(int)(screenSize[1]*scale));
  behaviors[0] = new CameraFeedSketch(this, numScreens);
  activeBehavior = behaviors[0];
  for (int i=0; i<behaviors.length; i++) {
   behaviors[i].setup(); 
  }
}

void draw() {
 background(0); 
 activeBehavior.draw();
}
