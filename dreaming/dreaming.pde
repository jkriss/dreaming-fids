import hypermedia.video.*;
import processing.video.*;
import controlP5.*;
import fullscreen.*; 

VideoStreamer streamer;
PImage[] cams = new PImage[6];
int camW = 640;
//int camW = 800;
int camH = 480;
int camW2 = camW/2;
int camH2 = camH/2;
Capture localVideo;
Movie movie;
PImage movieFrame;
UDP udp;

Behavior[] behaviors = new Behavior[1];
Behavior activeBehavior;
int[] screenSize = {800, 480};
//int screenFactor = screenSize[0] * screenSize[1] / 7000;
int numScreens = 4;
int numCameras = 6;
int border = 0; //10;
int motionLevel;

FishInfo[] fish = new FishInfo[numCameras];

Detector[] detectors = new Detector[numCameras];

ControlP5 controls;
ControlWindow controlWindow;
int nextControlY = 10;

public int threshold = 16;
public int maxThreshold = 500;

MotionBlob suspiciousFish = null;
MotionRect[] interestRects = new MotionRect[numCameras];
MotionRect mostInterestingRect;

SoftFullScreen fs; 

void setup() {
  
  smooth();
  
  PFont font = loadFont("Helvetica-Bold-16.vlw");
  textFont(font);
  
  float scale = .45;
  size((border*(numScreens-1)) + (int)(screenSize[0]*numScreens*scale),(int)(screenSize[1]*scale));
  behaviors[0] = new CameraFeedSketch(this, numScreens, border);
  activeBehavior = behaviors[0];
  for (int i=0; i<behaviors.length; i++) {
   behaviors[i].setup(); 
  }
  for (int i=0; i<detectors.length; i++) {
   detectors[i] = new Detector(this); 
  }
  for (int i=0; i<fish.length; i++) {
    fish[i] = new FishInfo(); 
    interestRects[i] = new MotionRect();
  }
//  localVideo = new Capture(this, camW, camH, 24);
  movie = new Movie(this, "Fish Comp 1.mov");
  movie.loop();
  movieFrame = createImage(camW, camH, ALPHA);

  streamer = new VideoStreamer(this, "224.0.0.0", 9091);
  udp = new UDP( this, 9091, "224.0.0.0"); // this, port, ip address
  udp.listen(true);
  
  // set up control panel
//  controls = new ControlP5(this);
//  controls.setAutoDraw(false);
//  controls.setAutoInitialization(true);
//  controlWindow = controls.addControlWindow("controlP5window",200,300);
//  controlWindow.hideCoordinates();
//  slider("threshold", 0, 200, 16);
//  slider("maxThreshold", 0, 500, 500);

  fs = new SoftFullScreen(this);
}

void slider(String name, int min, int max, int defaultValue) {
//  Controller slider = controls.addSlider(name,min,max,defaultValue,10,nextControlY,100,10);
  Controller slider = controls.addSlider(name,min,max,defaultValue,10,nextControlY,100,10);
  slider.setWindow(controlWindow);
  nextControlY += 15;
}

void mousePressed() {
  for (int i=0; i<detectors.length; i++) {
    detectors[i].sampleBackground(cams[i]);
    background(150);
  }
}

void draw() {
 background(0);
 streamVideo();
 findSuspiciousActivity();
 activeBehavior.draw();
}

void findSuspiciousActivity() {
  int maxMotion = 0;
  for (int i=0; i<interestRects.length; i++) {
    interestRects[i].step();
    interestRects[i].active(0);
  }
  for (int c=0; c<fish.length; c++) {
    MotionBlob[] mblobs = fish[c].blobs;
    if (mblobs == null) continue;
    for( int i=0; i<mblobs.length; i++ ) {
      if (mblobs[i].motion > maxMotion) {
        suspiciousFish = mblobs[i];
        Rectangle r = mblobs[i].blob.rectangle;
        Point center = mblobs[i].blob.centroid;
        interestRects[c].setTarget(center.x, center.y, r.width, r.height, c);
        interestRects[c].active(sqrt(suspiciousFish.motion));
//        mostInterestingRect = interestRects[i];
//        mostInterestingRect.active(true);
        maxMotion = suspiciousFish.motion;
      }
    }
  }

  float maxActivity = -1;
  for (int i=0; i<interestRects.length; i++) {
//    println("rect " + i + " activity: " + interestRects[i].activity);
    if (interestRects[i].activity > maxActivity) {
      maxActivity = interestRects[i].activity;
      mostInterestingRect = interestRects[i];
    }
  }
  
//  println("most interesting rect: " + mostInterestingRect.cameraIndex + ", activity: " + mostInterestingRect.activity);

}

void streamVideo() {
  if (localVideo != null) {
    if (localVideo.available()) {
      localVideo.read();
      localVideo.loadPixels();
    //  opencv.convert(OpenCV.GRAY);
      streamer.send(localVideo);
    }
  } else {
    movie.read();
    movieFrame.copy(movie, 0, 0, movie.width, movie.height, 0, 0, camW, camH);
    streamer.send(movieFrame); 
  }
}

void receive( byte[] data, String ip, int port ) {
  PImage img = loadPImageFromBytes(data, this);

  cams[0] = img.get(0,0,camW2,camH2);
  cams[1] = img.get(camW2,0,camW2,camH2);
  cams[2] = img.get(0,camH2,camW2,camH2);
   
  // for now
  cams[3] = cams[0];
  cams[4] = cams[1];
  cams[5] = cams[2];
  
  for (int i=0; i<cams.length; i++) {
    fish[i].blobs = detectors[i].findBlobs(cams[i]);
    fish[i].activity = detectors[i].activity;
  }
} 

PImage loadPImageFromBytes(byte[] b, PApplet p){ 
 Image img = Toolkit.getDefaultToolkit().createImage(b); 
 MediaTracker t=new MediaTracker(p); 
 t.addImage(img,0); 
 try{ 
   t.waitForAll(); 
 } 
 catch(Exception e){ 
   println(e); 
 } 
 return new PImage(img); 
}

class FishInfo {
  MotionBlob[] blobs;
  int activity;
}

class MotionRect {
 Rectangle current;
 Rectangle target;
 int cameraIndex;
 float activity;
 float stability;
 boolean active;
 MotionRect() {
  current = new Rectangle();
  target = new Rectangle();
 }
 void active(float motion) {
   active = motion > 0;
   activity += motion;
 }
 void setTarget(Rectangle r, int cameraIndex) {
   setTarget(r.x, r.y, r.width, r.height, cameraIndex);
 }
 void setTarget(int x, int y, int w, int h, int cameraIndex) {
   int margin = 25;
   target.x = x;
   target.y = y;
   target.width = w+(2*margin);
   target.height = h+(2*margin);
   this.cameraIndex = cameraIndex;
 }
 void step() {
   float amt = .6;
   current.x = interp(current.x, target.x, amt, 0.7);   
   current.y = interp(current.y, target.y, amt, 0.7);   
   current.width = interp(current.width, target.width, 0.2, 0.3);   
   current.height = interp(current.height, target.height, 0.2, 0.3);   
   stability += dist(current.x, current.y, target.x, target.y);
   activity *= 0.95;
   stability *= 0.7;
 }
 
 int interp(int start, int end, float amt, float maxAmt) {
//   return end;
   int delta = abs(end-start);
//   return (int)lerp(start,end,min(maxAmt, amt*screenFactor/delta));
   return (int)lerp(start,end,min(maxAmt, amt*100/delta));
 }
}
