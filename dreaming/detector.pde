class Detector {
 
  int numPixels;
  PImage backgroundImage = null;
  PImage motionImage = null;
  PImage presenceImage = null;
  PImage objectImage = null;
  int[] previousFrame;
  
  PImage blank;
  PImage[] samples = new PImage[3];
  
  int activity;
  
  OpenCV opencv;
  
  Detector(PApplet parent) {
    this.opencv = new OpenCV(parent); 
  }
  
  Blob[] findBlobs(PImage img) {
    if (backgroundImage == null) return null;
    DetectionResult detect = objects(img, 0.3);
    if (detect != null) {
      activity = detect.activity;
      if (true) return null;
      // set it to black if not enough is happening
//      int activityThreshold = 1000000;
      int activityThreshold = 0;
      if (detect.activity < activityThreshold) {
        opencv.copy(blank);
      } else {
        opencv.copy(detect.image);
      }
      opencv.threshold(5, 255, OpenCV.THRESH_BINARY + OpenCV.THRESH_OTSU);
    }
   
    // find blobs
    return opencv.blobs( 100, width*height/2, 100, false);
  }
  
  PImage sampleBackground(PImage img) {
    if (samples[samples.length-1] != null) {
      Arrays.fill(samples, null);
    }
    int i=0;
    while (samples[i] != null) i++;
    samples[i] = img;
    if (i == 2) {
      PImage bg = subtractForeground(samples[0], samples[1], samples[2]);
      setBackground(bg);
      return bg;
    }
    return null;
  }
  
  void initImage(PImage img) {
    if (motionImage == null) {
      opencv.allocate(img.width, img.height);
      motionImage = createImage(img.width, img.height, ALPHA);
      presenceImage = createImage(img.width, img.height, ALPHA);
      objectImage = createImage(img.width, img.height, ALPHA);
      numPixels = img.width * img.height;
      previousFrame = new int[numPixels];
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
