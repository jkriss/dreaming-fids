import hypermedia.video.*;
import processing.video.*;

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
int numScreens = 4;
int numCameras = 6;
int border = 10;
int motionLevel;

FishInfo[] fish = new FishInfo[numCameras];

Detector[] detectors = new Detector[numCameras];

void setup() {
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
  }
//  localVideo = new Capture(this, camW, camH, 24);
  movie = new Movie(this, "Fish Comp 3.mov");
  movie.loop();
  movieFrame = createImage(camW, camH, ALPHA);

  streamer = new VideoStreamer(this, "224.0.0.0", 9091);
  udp = new UDP( this, 9091, "224.0.0.0"); // this, port, ip address
  udp.listen(true);
}

void mousePressed() {
  for (int i=0; i<detectors.length; i++) {
    detectors[i].sampleBackground(cams[i]);
    background(255);
  }
}

void draw() {
 background(0);
 streamVideo();
 activeBehavior.draw();
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
  Blob[] blobs;
  int activity;
}
