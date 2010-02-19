
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
    
  void drawScreen(int screenIndex) {
    int camIndex = cameraMappings[screenIndex];
    
    // show video
    PImage c = cams[camIndex];
    if (c == null) return;

    image(c,0,0,w,h);
    
    // draw blobs
    Blob[] blobs = fish[camIndex].blobs;
    if (blobs != null) {
      scaleBlobs(blobs, c.width, c.height, w, h);
      stroke(200,0,0);
      fill(200,0,0,50);
      for( int i=0; i<blobs.length; i++ ) {
          beginShape();
          for( int j=0; j<blobs[i].points.length; j++ ) {
              vertex( blobs[i].points[j].x, blobs[i].points[j].y );
          }
          endShape(CLOSE);
      }
  
      // draw blob rects
      stroke(0,200,0);
      noFill();
      for( int i=0; i<blobs.length; i++ ) {
        Rectangle r = blobs[i].rectangle;
        rect(r.x, r.y, r.width, r.height);
      }
    }
    
    // draw activity meter
    fill(45,99,137);
    noStroke();
    rect(5,5,fish[camIndex].activity/10000,10);
    
//    if (camIndex == 1) println(fish[camIndex].activity);
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
