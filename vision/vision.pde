import hypermedia.video.*;

OpenCV opencv;
Detector detector = new Detector();

void setup() {

    size( 640, 480 );

    // open video stream
    opencv = new OpenCV( this );
    opencv.capture( 640, 480 );
}

void keyPressed() {
  println("saving background");
  opencv.read();
  opencv.convert(OpenCV.GRAY);
  detector.setBackground(opencv.image()); 
}

void draw() {

    background(192);

    opencv.read();           // grab frame from camera
    opencv.convert(OpenCV.GRAY);
//    opencv.threshold(80);    // set black & white threshold 
    
//    DetectionResult motion = detector.motion(opencv.image());
    DetectionResult presence = detector.presence(opencv.image());
//    opencv.copy(motion.image);
//    opencv.copy(presence.image);
    if (presence != null) {
      opencv.copy(presence.image);
      opencv.threshold(10, 255, OpenCV.THRESH_BINARY);
//      opencv.blur( OpenCV.BLUR, 13 );
//      opencv.invert();
      image(opencv.image(), 0, 0);
    }
   
    // find blobs
    Blob[] blobs = opencv.blobs( 10, width*height/2, 100, false, OpenCV.MAX_VERTICES*4 );
//    opencv.restore();

    // draw blob results
    stroke(200,0,0);
    fill(200,0,0,150);
    for( int i=0; i<blobs.length; i++ ) {
        beginShape();
        for( int j=0; j<blobs[i].points.length; j++ ) {
            vertex( blobs[i].points[j].x, blobs[i].points[j].y );
        }
        endShape(CLOSE);
    }

}


class Detector {
 
  int numPixels;
  PImage backgroundImage = null;
  PImage workingImage = null;
  int[] previousFrame;
  
  void initImage(PImage img) {
    if (workingImage == null) {
      workingImage = createImage(img.width, img.height, RGB);
      numPixels = img.width * img.height;
      previousFrame = new int[numPixels];
    }
    workingImage.loadPixels();
  }
  
  void setBackground(PImage backgroundImage) {
    this.backgroundImage = backgroundImage;
  }
  
  // from golan
  DetectionResult presence(PImage img) {
    if (backgroundImage == null) return null;
    initImage(img);
    arraycopy(img.pixels, workingImage.pixels);
//    loadPixels();
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = workingImage.pixels[i];
      color bkgdColor = backgroundImage.pixels[i];
      // Extract the red, green, and blue components of the current pixelÕs color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixelÕs color
      int bkgdR = (bkgdColor >> 16) & 0xFF;
      int bkgdG = (bkgdColor >> 8) & 0xFF;
      int bkgdB = bkgdColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - bkgdR);
      int diffG = abs(currG - bkgdG);
      int diffB = abs(currB - bkgdB);
      // Add these differences to the running tally
      presenceSum += diffR + diffG + diffB;
      // Render the difference image to the screen
//      workingImage.pixels[i] = color(diffR, diffG, diffB);
      // The following line does the same thing much faster, but is more technical
      workingImage.pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
//      pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
    }
    workingImage.updatePixels();
    return new DetectionResult(workingImage, presenceSum);
  }
  
  DetectionResult motion(PImage img) {
    initImage(img);
    arraycopy(img.pixels, workingImage.pixels);
    int movementSum = 0; // Amount of movement in the frame
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      color currColor = workingImage.pixels[i];
      color prevColor = previousFrame[i];
      // Extract the red, green, and blue components from current pixel
      int currR = (currColor >> 16) & 0xFF; // Like red(), but faster
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract red, green, and blue components from previous pixel
      int prevR = (prevColor >> 16) & 0xFF;
      int prevG = (prevColor >> 8) & 0xFF;
      int prevB = prevColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - prevR);
      int diffG = abs(currG - prevG);
      int diffB = abs(currB - prevB);
      // Add these differences to the running tally
      movementSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      // pixels[i] = color(diffR, diffG, diffB);
      // The following line is much faster, but more confusing to read
      // pixels[i] = 0xff000000 | (diffR << 16) | (diffG << 8) | diffB;
      workingImage.pixels[i] = 0xff000000 | (diffR << 16) | (diffG << 8) | diffB;
      // Save the current color into the 'previous' buffer
      previousFrame[i] = currColor;
    }
    // To prevent flicker from frames that are all black (no movement),
    // only update the screen if the image has changed.
//    if (movementSum > 0) {
      // updatePixels();
      // println(movementSum); // Print the total amount of movement to the console     
//    }
    return new DetectionResult(workingImage, movementSum);
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
