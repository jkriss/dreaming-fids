
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
    
    textAlign(CENTER, CENTER);
    
    // draw blobs
    MotionBlob[] mblobs = fish[camIndex].blobs;
    if (mblobs != null) {
      scaleBlobs(mblobs, c.width, c.height, w, h);
//      stroke(200,0,0);
//      fill(200,0,0,50);
//      for( int i=0; i<mblobs.length; i++ ) {
//          beginShape();
//          for( int j=0; j<mblobs[i].blob.points.length; j++ ) {
//              vertex( mblobs[i].blob.points[j].x, mblobs[i].blob.points[j].y );
//          }
//          endShape(CLOSE);
//      }
  
      // draw blob rects
      stroke(0,200,0);
      strokeWeight(1);
      for( int i=0; i<mblobs.length; i++ ) {
        
//        if (mblobs[i].id == suspiciousFish.id) {
//          stroke(200,0,0);
//          fill(200,0,0,50);
//          beginShape();
//          Blob b = mblobs[i].blob;
//          for( int j=0; j<b.points.length; j++ ) {
//              vertex( b.points[j].x, b.points[j].y );
//          }
//          endShape(CLOSE);
//        }

        
//        if (mblobs[i].id == suspiciousFish.id) 
//          stroke(0,200,0);
//        else
//          noStroke(); //stroke(0,200,0);
//        
//        Rectangle r = mblobs[i].blob.rectangle;
//        noFill();
//        rect(r.x, r.y, r.width, r.height);
//        // show activity level
//        fill(0);
//        text(mblobs[i].motion, r.x + (r.width/2), r.y + (r.height/2));
      }
    }
    
    float wScale = w / (float)c.width;
    float hScale = h / (float)c.height;

    // draw following rect, scaled
    if (mostInterestingRect != null && mostInterestingRect.cameraIndex == camIndex) {
      noFill();
      Rectangle r = mostInterestingRect.current;
//      println("stability: " + mostInterestingRect.stability);
//      println("activity: " + mostInterestingRect.activity);
      float scaledAct = 0.2*max(0,map(mostInterestingRect.activity,3000,8000, 0, 255));
      float scaledStab = 0.8*max(0,map(mostInterestingRect.stability,100,10, 0, 255));
      
//      println("stability: " + mostInterestingRect.stability + ", scaled stability: " + scaledStab);
//      stroke(245,237,12, map(mostInterestingRect.activity,3000,8000, 0, 255));
      float score = scaledAct+scaledStab;
//      println("rect score: " + score);
//      if (score > 200) {
      if (true) {
        stroke(245,237,12, score);
        strokeWeight(2);
        rectMode(CENTER);
        
        float rw = r.width*wScale;
        float rh = r.height*hScale;
        float ratio = 1.61; //16/9;
        
        if (rw/rh > ratio) {
          // wider than ideal, scale height up based on width
          rh = rw / ratio;
        } else {
          // taller than ideal, scale width up based on height
          rw = rh * ratio;
        }
        
        rect(r.x*wScale, r.y*hScale, rw, rh);
        rectMode(CORNER);
      }
      noStroke();
      fill(255,255,255,150);
      ellipse(r.x*wScale, r.y*hScale, 30, 30);
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
