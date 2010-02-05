import hypermedia.video.*;

OpenCV opencv;
Detector detector = new Detector();

void setup() {

    size( 640, 480 );

    // open video stream
    opencv = new OpenCV( this );
    opencv.capture( 640, 480 );

}

void draw() {

    background(192);

    opencv.read();           // grab frame from camera
    opencv.threshold(80);    // set black & white threshold 
    
    DetectionResult motion = detector.motion(opencv.image());
    opencv.copy(motion.image);

    // find blobs
    Blob[] blobs = opencv.blobs( 10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );

    // draw blob results
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
  PImage workingImage = null;
  int[] previousFrame;
  
  // from golan
  DetectionResult motion(PImage img) {
    if (workingImage == null) {
      workingImage = createImage(img.width, img.height, RGB);
      numPixels = img.width * img.height;
      previousFrame = new int[numPixels];
    }
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
 int movementSum; 
 DetectionResult(PImage image, int movementSum) {
   this.image = image;
   this.movementSum = movementSum;
 }
}
