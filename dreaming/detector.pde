class Detector {
 
  int numPixels;
  private PImage backgroundImage = null;
  private PImage motionImage = null;
  private PImage presenceImage = null;
  private PImage objectImage = null;
  private PImage prethresholdImage = null;
  private PImage previousFrame;
  
  private PImage currentMotionFrame;
  private PImage previousMotionFrame;
  
  private PImage blank;
  private PImage[] samples = new PImage[3];
  
  int activity;
  
  int id;
  
  private OpenCV vision;
  
  Detector(PApplet parent, int id) {
    vision = new OpenCV(parent); 
    this.id = id;
    loadBackground();
  }
  
  MotionBlob[] findBlobs(PImage img) {
    if (backgroundImage == null) return null;
    initImage(img);
    arraycopy(img.pixels, currentMotionFrame.pixels);
    DetectionResult detect = objects(img, 0.3);
    if (detect != null) {
      activity = detect.activity;
      // set it to black if not enough is happening
//      int activityThreshold = 120000;
      int activityThreshold = 0;
      if (detect.activity < activityThreshold) {
        vision.copy(blank);
      } else {
//        combine(prethresholdImage, detect.image, prethresholdImage, 0.95);
        vision.copy(detect.image);
//        vision.copy(prethresholdImage);
      }
//      vision.threshold(threshold, maxThreshold, OpenCV.THRESH_BINARY + OpenCV.THRESH_OTSU);
      vision.threshold(threshold, maxThreshold, OpenCV.THRESH_BINARY);
    }
   
    // find blobs
    Blob[] blobs = vision.blobs( 100, width*height/2, 100, false);
    
    // get motion amount for each blob
    MotionBlob[] mblobs = new MotionBlob[blobs.length];
    Blob b;
    for (int i=0; i<blobs.length; i++) {
      b = blobs[i];
      mblobs[i] = new MotionBlob((int)random(1000000), b, movement(b.rectangle.x, b.rectangle.y, b.rectangle.width, b.rectangle.height));
    }
    
    arraycopy(currentMotionFrame.pixels, previousMotionFrame.pixels);
    
    return mblobs;
  }
  
  int movement(int x, int y, int w, int h) {
    return difference(currentMotionFrame.get(x,y,w,h), previousMotionFrame.get(x,y,w,h));
  }
  
  int difference(PImage a, PImage b) {
    int totalDifference = 0;
    int numPixels = a.height * a.width;
    for (int i=0; i<numPixels; i++) {
      int ap = a.pixels[i] & 0xFF;
      int bp = b.pixels[i] & 0xFF;
      int diff = abs(ap - bp);
      totalDifference += diff;
    }
    return totalDifference;
  }
  
  void sampleBackground(PImage img) {
    if (samples[samples.length-1] != null) {
      Arrays.fill(samples, null);
    }
    int i=0;
    while (samples[i] != null) i++;
    samples[i] = img;
    if (i == 2) {
      PImage bg = subtractForeground(samples[0], samples[1], samples[2]);
      bg.save(imagePath());
      loadBackground();
    }
  }
  
  void loadBackground() {
    setBackground(loadImage(imagePath()));
  }
  
  String imagePath() {
    return "data/background-"+id+".jpg";
  }
  
  void initImage(PImage img) {
    if (img == null) return;
    if (motionImage == null) {
      vision.allocate(img.width, img.height);
      motionImage = createImage(img.width, img.height, ALPHA);
      presenceImage = createImage(img.width, img.height, ALPHA);
      objectImage = createImage(img.width, img.height, ALPHA);
      prethresholdImage = createImage(img.width, img.height, ALPHA);
      numPixels = img.width * img.height;
      previousFrame = createImage(img.width, img.height, ALPHA);
      previousMotionFrame = createImage(img.width, img.height, ALPHA);
      currentMotionFrame = createImage(img.width, img.height, ALPHA);
      blank = createImage(width, height, ALPHA);
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
    initImage(img);
    DetectionResult presence = presence(img);
    if (presence == null) return null;
    DetectionResult motion = motion(img);
    combine(motionImage, presenceImage, objectImage, motionWeight);
//    return new DetectionResult(objectImage, presence.activity + motion.activity);
    return new DetectionResult(objectImage, motion.activity);
  }
  
  void combine(PImage a, PImage b, PImage target, float aWeight) {
    float bWeight = 1.0 - aWeight;
    for (int i=0; i<numPixels; i++) {
      int ap = a.pixels[i] & 0xFF;
      int bp = b.pixels[i] & 0xFF;
      int cp = (int)((ap*aWeight)+(bp*bWeight));
      target.pixels[i] = 0xFF000000 | (cp << 16) | (cp << 8) | cp;
    }
    target.updatePixels();
  }
  
  DetectionResult presence(PImage img) {
    initImage(img);
    if (backgroundImage == null) return null;
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
      color prevColor = previousFrame.pixels[i];
      int currB = currColor & 0xFF;
      int prevB = prevColor & 0xFF;
      int diffB = abs(currB - prevB);
      // Add these differences to the running tally
      movementSum += diffB;
      motionImage.pixels[i] = 0xff000000 | (diffB << 16) | (diffB << 8) | diffB;
      // Save the current color into the 'previous' buffer
      previousFrame.pixels[i] = currColor;
    }
    previousFrame.updatePixels();
    return new DetectionResult(motionImage, movementSum);
  }
  
}

class MotionBlob {
 Blob blob;
 int motion;
 int id;
 MotionBlob(int id, Blob blob, int motion) {
   this.id = id;
   this.blob = blob;
   this.motion = motion;
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
