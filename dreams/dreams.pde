import controlP5.*;
import hypermedia.video.*;

OpenCV opencv;
ControlP5 controls;
ControlWindow controlWindow;

public int contrast = 60;
public int brightness = 80;
public int threshold = 80;

public int nextControlY = 10;

void setup() {
  size( 640, 480 );

  // set up control panel
  controls = new ControlP5(this);
  controls.setAutoDraw(false);
  controlWindow = controls.addControlWindow("controlP5window",200,100);
  controlWindow.hideCoordinates();
  slider("contrast", 0, 200, 10);
  slider("brightness", 0, 200, 10);
  slider("threshold", 0, 200, 10);
  controlWindow.setTitle("controls");
  // open video stream
  opencv = new OpenCV( this );
  opencv.capture( 640, 480 );
}

void slider(String name, int min, int max, int defaultValue) {
//  Controller slider = controls.addSlider(name,min,max,defaultValue,10,nextControlY,100,10);
  Controller slider = controls.addSlider(name,min,max,defaultValue,nextControlY,100,10);
  slider.setWindow(controlWindow);
  nextControlY += 15;
}

void draw() {
  background(192);
  
  opencv.read();           // grab frame from camera
  opencv.threshold(threshold);    // set black & white threshold 
  opencv.convert(OpenCV.GRAY);
  opencv.brightness(brightness);
  opencv.contrast(contrast);

  background(opencv.image());

  drawBlobs();
}

void drawBlobs() {
  // find blobs
  Blob[] blobs = opencv.blobs( 10, width*height/2, 100, true, OpenCV.MAX_VERTICES*4 );
  // draw blob results
  fill(0,124,157);
  for( int i=0; i<blobs.length; i++ ) {
    beginShape();
    for( int j=0; j<blobs[i].points.length; j++ ) {
      vertex( blobs[i].points[j].x, blobs[i].points[j].y );
    }
    endShape(CLOSE);
  }
}
