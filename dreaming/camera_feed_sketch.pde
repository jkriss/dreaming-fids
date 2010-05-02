

class CameraFeedSketch extends Behavior {

  int[] cameraMappings = { 0, 1, 2, 3 };
  Mugshotter mugshotter = new Mugshotter();
  
  CameraFeedSketch(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }
  
  void setup() {
  }
  
  public void showMugshot(String url) {
//    println("receiving new mugshot url: " + url);
    mugshotter.showMugshot(url); 
  }
  
  public void resetMugshots() {
    mugshotter.mugshots.clear(); 
  }
  
  void draw() {
//    if (frameCount % 80 == 0) resetMappings();
    splitScreens();
    spanScreens();
    fill(0,0,0, 10);
    rect(0,0,w,h);
    mugshotter.draw();
  }
    
  void drawScreen(int screenIndex) {
    int camIndex = cameraMappings[screenIndex];
    
    // show video
    PImage c = cams[camIndex];
    if (c == null) return;
    
//    if (screenIndex > 1) return;

    image(c,0,0,w,h);
    
    textAlign(CENTER, CENTER);
    
    // draw blobs
    MotionBlob[] mblobs = fish[camIndex].blobs;
    if (mblobs != null) {
      scaleBlobs(mblobs, c.width, c.height, w, h);
      if (showBlobs) {
        stroke(200,0,0);
        fill(200,0,0,50);
        for( int i=0; i<mblobs.length; i++ ) {
            beginShape();
            for( int j=0; j<mblobs[i].blob.points.length; j++ ) {
                vertex( mblobs[i].blob.points[j].x, mblobs[i].blob.points[j].y );
            }
            endShape(CLOSE);
        }
      }
  
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
      if (score > 180) {
//      if (true) {
//        stroke(245,237,12, score);
        stroke(255,255,0);
        
        rectMode(CENTER);
        
        r.x *= wScale;
        r.y *= hScale;
        r.width *= wScale;
        r.height *= hScale;
        
        if (r.width == 0 || r.height == 0) return;
        
        float ratio = 1.61; //16/9;
               
        if (r.width/r.height > ratio) {
          // wider than ideal, scale height up based on width
          r.height = (int)(r.width / ratio);
        } else {
          // taller than ideal, scale width up based on height
          r.width = (int)(r.height * ratio);
        }
        
        Rectangle fishRect = (Rectangle)r.clone();
        fishRect.grow(-2, -2);
        
//        r = r.intersection(new Rectangle(m,m,w-m2,h-m2));
//        if (!r.equals(before)) println("before: " + before + ", after: " + r);

        int tooLeftBy = -1 * (r.x - r.width/2);
        if (tooLeftBy > 0) {
           r.x += tooLeftBy;
           r.width -= tooLeftBy;
        }

        int tooWideBy = (r.x + r.width/2) - w;
        if (tooWideBy > 0) {
          r.width -= tooWideBy;
          r.x -= tooWideBy;
        }
        
        int tooHighBy = -1 * (r.y - r.height/2);
        if (tooHighBy > 0) {
          r.y += tooHighBy;
          r.height -= tooHighBy;
        }
        
        int tooTallBy = (r.y + r.height/2) - h;
        if (tooTallBy > 0) {
          r.height -= tooTallBy;
          r.y -= tooTallBy;
        }

        // reapply aspect ratio fixing, but no size increase        
        if (r.height != 0 && r.width/r.height > ratio) {
          // wider than ideal, scale width down based on height
          r.width = (int)(r.height * ratio);
        } else {
          // taller than ideal, scale height down based on width
          r.height = (int)(r.width / ratio);
        }

        
        // remember, r.x and r.y are center points, here, so we need to adjust
//        PImage mug = get((int)(r.x*wScale)+(w*screenIndex)-(int)(rw/2), (int)(r.y*hScale)-(int)(rh/2), (int)rw, (int)rh);
//        image(mug,0,0,w,h);
//        println("drawing " + r);
        
        strokeWeight(4);
        
        if (r.contains(fishRect)) {
//          fill(255,255,255, 20);
//          println("caught one!");
          // cam image isn't scaled, so scale rect down to its size
          PImage scaledCam = createImage(w,h,ALPHA);
          scaledCam.copy(c,0,0,c.width,c.height,0,0,scaledCam.width,scaledCam.height);
          mugshotter.mugshot(scaledCam, r);
        }
        if (mugshotter.recentMugshot()) {
          fill(245,237,12,100);
        } else {
          noFill();
        }
        rect(r.x, r.y, r.width, r.height);
        
//        strokeWeight(1);
//        stroke(255,0,0);
//        rect(fishRect.x, fishRect.y, fishRect.width, fishRect.height);
        rectMode(CORNER);
      }
//      noStroke();
//      fill(255,255,255,150);
//      ellipse(r.x*wScale, r.y*hScale, 30, 30);
    }
    
    // draw activity meter
//    fill(45,99,137);
    noStroke();
//    rect(5,5,fish[camIndex].activity/10000,10);
       
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

class Mugshotter {
 
 long lastShot;
 ArrayList mugshots = new ArrayList();
 
 int scaleFactor = (int)(6 * (scale/.4));
 
 int mWidth = 16 * scaleFactor; 
 int mHeight = 9 * scaleFactor;
 int mMargin = (1 * scaleFactor) + 4;
 
 int shotsPerLine = 6;
 int maxShots = shotsPerLine * 4;
 
 boolean mugshot(PImage img, Rectangle r) {
   if (millis() - lastShot > 1000) { 
//     println("taking mugshot");
     PImage mug = img.get(r.x-r.width/2, r.y-r.height/2, r.width, r.height);
     String imageName = "mugshot-" + (mugshots.size()+1) + ".jpg";
     mug.save("mugshots/" + imageName);
     String mugshotUrl = "http://"+hostname()+":"+SERVER_PORT+"/"+imageName;
//     showMugshot(mugshotUrl);
     callMethod("jklabs-mbp", "showMugshot", mugshotUrl);
     callMethod("thing1", "showMugshot", mugshotUrl);
     callMethod("thing2", "showMugshot", mugshotUrl);
     return true;
   } else {
     return false;
   }
 }
 
 void showMugshot(String url) {
   println("adding mugshot " + url);
   PImage urlMug = loadImage(url);
   if (mugshots.size() == maxShots) mugshots.clear();
   mugshots.add(urlMug);
   lastShot = millis();
 }
 
 boolean recentMugshot() {
   return (millis() - lastShot < 300);
 }
 
 void draw() {
//   Iterator it = mugshots.iterator();
   pushMatrix();
   translate(mMargin, mMargin);
   int count = 0;
//   while(it.hasNext()) {
   int startAt = isThing1() ? 0 : maxShots / 2;
   int endAt = isThing1() ? min(mugshots.size(), maxShots / 2) : mugshots.size();
   for (int i=startAt; i<endAt; i++) {
//     PImage mug = (PImage)it.next();
     PImage mug = (PImage)mugshots.get(i);
     image(mug, 0, 0, mWidth, mHeight);
     if (i == mugshots.size()-1 && recentMugshot()) {
       fill(245,237,12,70);
       rect(0,0,mWidth,mHeight);
     }
     count++;
     if (count > 0 && count % shotsPerLine == 0) {
       popMatrix();
       translate(0,mMargin+mHeight);
       pushMatrix();
       translate(mMargin, mMargin);
     } else {
       translate(mMargin+mWidth, 0);
     }
   }
   popMatrix();
 }
}
