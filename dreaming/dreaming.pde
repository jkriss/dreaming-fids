import hypermedia.video.*;

VideoStreamer cam;
PImage[] cams = new PImage[6];
int camW = 640;
int camH = 480;
int camW2 = camW/2;
int camH2 = camH/2;
OpenCV opencv;
UDP udp;

Behavior[] behaviors = new Behavior[1];
Behavior activeBehavior;
int[] screenSize = {800, 480};
int numScreens = 4;

void setup() {
  float scale = .5;
  size((int)(screenSize[0]*numScreens*scale),(int)(screenSize[1]*scale));
  behaviors[0] = new CameraFeedSketch(this, numScreens);
  activeBehavior = behaviors[0];
  for (int i=0; i<behaviors.length; i++) {
   behaviors[i].setup(); 
  }
  opencv = new OpenCV(this);
  opencv.capture(camW, camH);
  cam = new VideoStreamer(this, "224.0.0.0", 9091);
  udp = new UDP( this, 9091, "224.0.0.0"); // this, port, ip address
  udp.listen(true);
}

void draw() {
 background(0);
 streamVideo();
 activeBehavior.draw();
}

void streamVideo() {
  opencv.read();
  opencv.convert(OpenCV.GRAY);
  opencv.brightness(45);
  opencv.contrast(5);
  cam.send(opencv.image());
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
