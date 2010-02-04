
int[] cameraMappings = { 1, 0, 2, 1 };

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
    PImage c = cams[cameraMappings[i]];
    DetectionResult m = motion[cameraMappings[i]];
    
    if (c != null) {
      image(c,0,0,w,h);
      if (m != null && m.movementSum > 400000) {
//        image(m.image,0,0,w,h);
//        println("motion " + m.movementSum);
        noStroke();
        fill(200,0,0);
        ellipse(15,15,10,10);
      }
    }
  }
  
  void blobs(PImage img) {
//    if (motion == null || motion.movementSum < 300000) return;
//    opencv.copy(img.get());
//  //  opencv.threshold(80);
//    image(opencv.image(),0,0,w,h);
//    Blob[] blobs = opencv.blobs( 10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );
//    
//    int margin = 5;
//    for( int i=0; i<blobs.length; i++ ) {
//      Rectangle r = blobs[i].rectangle;
//      noFill();
//      stroke(100,0,0);
//      rect(r.x-margin,r.y-margin,r.width+(2*margin),r.height+(2*margin));
//    }
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
