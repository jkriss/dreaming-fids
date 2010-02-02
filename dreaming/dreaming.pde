
Behavior[] behaviors = new Behavior[1];
Behavior activeBehavior;

void setup() {
  size(800,480);
  behaviors[0] = new CameraFeedSketch(this);
  activeBehavior = behaviors[0];
  for (int i=0; i<behaviors.length; i++) {
   behaviors[i].setup(); 
  }
}

void draw() {
 background(0); 
 activeBehavior.draw();
}
