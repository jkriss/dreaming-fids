import hypermedia.video.*;

OpenCV opencv;
Detector detector = new Detector();

PImage blank;

PImage[] samples = new PImage[3];

void setup() {

    size( 640, 480 );

    // open video stream
    opencv = new OpenCV( this );
//    opencv.capture( 640, 480 );
    opencv.movie( "Fish Comp 3.mov", width, height );
    
    blank = createImage(width, height, ALPHA);
    
}

void mousePressed() {
  if (samples[samples.length-1] != null) {
    Arrays.fill(samples, null);
  }
  int i=0;
  while (samples[i] != null) i++;
  println("taking sample " + i);
  opencv.read();
  samples[i] = opencv.image();
  background(i == 2 ? 255 : 100);
  
  if (i == 2) {
    PImage bg = detector.subtractForeground(samples[0], samples[1], samples[2]);
    detector.setBackground(bg);
    println("set background");
  }
}

//void keyPressed() {
//  println("saving background");
//  opencv.read();
//  opencv.convert(OpenCV.GRAY);
//  detector.setBackground(opencv.image()); 
//}

void draw() {

    background(192);

    opencv.read();           // grab frame from camera
    opencv.convert(OpenCV.GRAY);
    image(opencv.image(), 0, 0);

//    opencv.threshold(80);    // set black & white threshold 
    
//    DetectionResult motion = detector.motion(opencv.image());
//    DetectionResult presence = detector.presence(opencv.image());
    DetectionResult detect = detector.objects(opencv.image(), 0.3);
//    opencv.copy(motion.image);
//    opencv.copy(presence.image);
    if (detect != null) {
      println(detect.activity);
      
      // set it to black if not enough is happening
//      int activityThreshold = 1000000;
      int activityThreshold = 0;
      if (detect.activity < activityThreshold) {
        opencv.copy(blank);
      } else {
        opencv.copy(detect.image);
      }
      
      opencv.threshold(5, 255, OpenCV.THRESH_BINARY + OpenCV.THRESH_OTSU);
//      opencv.blur( OpenCV.BLUR, 13 );
//      opencv.invert();
//      image(opencv.image(), 0, 0);
    }
   
    // find blobs
    Blob[] blobs = opencv.blobs( 100, width*height/2, 100, false);
//    opencv.restore();

    // draw blob results
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


class Detector {
 
  int numPixels;
  PImage backgroundImage = null;
  PImage motionImage = null;
  PImage presenceImage = null;
  PImage objectImage = null;
  int[] previousFrame;
  
  void initImage(PImage img) {
    if (motionImage == null) {
      motionImage = createImage(img.width, img.height, ALPHA);
      presenceImage = createImage(img.width, img.height, ALPHA);
      objectImage = createImage(img.width, img.height, ALPHA);
      numPixels = img.width * img.height;
      previousFrame = new int[numPixels];
    }
  }
  
  void setBackground(PImage backgroundImage) {
    this.backgroundImage = backgroundImage;
  }
  
  PImage subtractForeground(PImage a, PImage b, PImage c) {
     int numPixels = a.width * b.height;
     PImage result = createImage(a.width, a.height, RGB);
     for (int i=0; i<numPixels; i++) {
       int aVal = a.pixels[i] & 0xFF; 
       int bVal = b.pixels[i] & 0xFF; 
       int cVal = c.pixels[i] & 0xFF;
      
       int diffAB = abs(aVal - bVal);
       int diffAC = abs(aVal - cVal);
       int diffBC = abs(bVal - cVal);
       
       int p;
       int bestMatch = min(diffAB, diffAC, diffBC);
       
       if (bestMatch == diffAB || bestMatch == diffAC)
         p = aVal;
       else
         p = cVal;
       
       result.pixels[i] = 0xFF000000 | (p << 16) | (p << 8) | p;
     }
     result.updatePixels();
     return result;
  }
  
  DetectionResult objects(PImage img, float motionWeight) {
    DetectionResult presence = presence(img);
    if (presence == null) return null;
    DetectionResult motion = motion(img);
    float presenceWeight = 1.0-motionWeight;
    for (int i=0; i<numPixels; i++) {
     //objectImage.pixels[i] = (int)((presence.image.pixels[i]*presenceWeight) + (motion.image.pixels[i]*motionWeight));
      int pB = presenceImage.pixels[i] & 0xFF;
      int mB = motionImage.pixels[i] & 0xFF;
      int cB = (int)((pB*presenceWeight)+(mB*motionWeight));
      objectImage.pixels[i] = 0xFF000000 | (cB << 16) | (cB << 8) | cB;
    }
    objectImage.updatePixels();
    return new DetectionResult(objectImage, presence.activity + motion.activity);
  }
  
  // from golan
  DetectionResult presence(PImage img) {
    if (backgroundImage == null) return null;
    initImage(img);
    arraycopy(img.pixels, presenceImage.pixels);
//    loadPixels();
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      int currB = presenceImage.pixels[i] & 0xFF;
      int bkgdB = backgroundImage.pixels[i] & 0xFF;
      int diffB = abs(currB - bkgdB);
      presenceSum += diffB;
      presenceImage.pixels[i] = 0xFF000000 | (diffB << 16) | (diffB << 8) | diffB;
    }
    presenceImage.updatePixels();
    return new DetectionResult(presenceImage, presenceSum);
  }
  
  DetectionResult motion(PImage img) {
    initImage(img);
    arraycopy(img.pixels, motionImage.pixels);
    int movementSum = 0; // Amount of movement in the frame
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      color currColor = motionImage.pixels[i];
      color prevColor = previousFrame[i];
      int currB = currColor & 0xFF;
      int prevB = prevColor & 0xFF;
      int diffB = abs(currB - prevB);
      // Add these differences to the running tally
      movementSum += diffB;
      motionImage.pixels[i] = 0xff000000 | (diffB << 16) | (diffB << 8) | diffB;
      // Save the current color into the 'previous' buffer
      previousFrame[i] = currColor;
    }
    return new DetectionResult(motionImage, movementSum);
  }
  
}

class DetectionResult {
 PImage image;
 int activity; 
 DetectionResult(PImage image, int activity) {
   this.image = image;
   this.activity = activity;
 }
}
