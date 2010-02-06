import hypermedia.video.*;

VideoStreamer streamer;
PImage[] cams = new PImage[6];
int camW = 640;
//int camW = 800;
int camH = 480;
int camW2 = camW/2;
int camH2 = camH/2;
OpenCV localVideo;
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
  localVideo = new OpenCV(this);
//  opencv.capture(camW, camH);
  localVideo.movie("Fish Comp 3.mov", camW, camH);
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
  if (cams[1] != null)
    image(cams[1],0,0);
}

void streamVideo() {
  localVideo.read();
//  opencv.convert(OpenCV.GRAY);
  streamer.send(localVideo.image());
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
