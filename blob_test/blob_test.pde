import controlP5.*;
import hypermedia.video.*;

OpenCV opencv;
ControlP5 controls;
ControlWindow controlWindow;

public int contrast = 60;
public int brightness = 80;
public int threshold = 80;

public int minArea = 10;
public int maxArea = 50;
public int maxBlobs = 5;
public int maxVertices = 200;

public int nextControlY = 10;

void setup() {
  size( 640, 480 );

  // set up control panel
  controls = new ControlP5(this);
  controls.setAutoDraw(false);
  controls.setAutoInitialization(true);
  controlWindow = controls.addControlWindow("controlP5window",200,300);
  controlWindow.hideCoordinates();
  slider("contrast", 0, 200, 32);
  slider("brightness", 0, 200, 20);
  slider("threshold", 0, 200, 86);
  nextControlY += 15;
  slider("minArea",0, 500, 155);
  slider("maxArea",100,100000,9010);
  slider("maxBlobs",1,50,35);
  slider("maxVertices",4,200,100);
  controlWindow.setTitle("controls");

  // open video stream
  opencv = new OpenCV( this );
  opencv.movie( "1.mp4", width, height );
  // opencv.capture( 640, 480 );
}

void slider(String name, int min, int max, int defaultValue) {
//  Controller slider = controls.addSlider(name,min,max,defaultValue,10,nextControlY,100,10);
  Controller slider = controls.addSlider(name,min,max,defaultValue,10,nextControlY,100,10);
  slider.setWindow(controlWindow);
  nextControlY += 15;
}

void draw() {
  background(192);
  
  opencv.read();           // grab frame from camera
  background(opencv.image());
  opencv.convert(OpenCV.GRAY);
  opencv.threshold(threshold);    // set black & white threshold 

  opencv.invert();
  opencv.brightness(brightness);
  opencv.contrast(contrast);


  drawBlobs();
}

void drawBlobs() {
  // find blobs
  Blob[] blobs = opencv.blobs( minArea, maxArea, maxBlobs, false, maxVertices );
  // draw blob results
//  fill(0,124,157);
//  for( int i=0; i<blobs.length; i++ ) {
//    beginShape();
//    for( int j=0; j<blobs[i].points.length; j++ ) {
//      vertex( blobs[i].points[j].x, blobs[i].points[j].y );
//    }
//    endShape(CLOSE);
//  }
  int margin = 5;
  for( int i=0; i<blobs.length; i++ ) {
    Rectangle r = blobs[i].rectangle;
    noFill();
    stroke(100,0,0);
    rect(r.x-margin,r.y-margin,r.width+(2*margin),r.height+(2*margin));
  }
}
