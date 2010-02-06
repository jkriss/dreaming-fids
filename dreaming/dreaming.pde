import hypermedia.video.*;

VideoStreamer cam;
PImage[] cams = new PImage[6];
int camW = 640;
//int camW = 800;
int camH = 480;
int camW2 = camW/2;
int camH2 = camH/2;
OpenCV opencv;
UDP udp;

Behavior[] behaviors = new Behavior[1];
Behavior activeBehavior;
int[] screenSize = {800, 480};
int numScreens = 4;
int numCameras = 6;
int border = 10;
int motionLevel;

FishInfo[] fish = new FishInfo[3];

PImage blank;
PImage[] samples = new PImage[3];

Detector detector = new Detector();

void setup() {
  float scale = .45;
  size((border*(numScreens-1)) + (int)(screenSize[0]*numScreens*scale),(int)(screenSize[1]*scale));
  behaviors[0] = new CameraFeedSketch(this, numScreens, border);
  activeBehavior = behaviors[0];
  for (int i=0; i<behaviors.length; i++) {
   behaviors[i].setup(); 
  }
  blank = createImage(width, height, ALPHA);
  opencv = new OpenCV(this);
//  opencv.capture(camW, camH);
  opencv.movie("Fish Comp 2.mov", camW, camH);
  cam = new VideoStreamer(this, "224.0.0.0", 9091);
  udp = new UDP( this, 9091, "224.0.0.0"); // this, port, ip address
  udp.listen(true);
}

void mousePressed() {
  if (samples[samples.length-1] != null) {
    Arrays.fill(samples, null);
  }
  int i=0;
  while (samples[i] != null) i++;
  println("taking sample " + i);
  opencv.read();
  samples[i] = opencv.image();
  background(i == 2 ? 255 : 100);
  
  if (i == 2) {
    PImage bg = detector.subtractForeground(samples[0], samples[1], samples[2]);
    detector.setBackground(bg);
    image(bg,0,0);
    saveFrame("background.jpeg");
    println("set background");
  }
}

void draw() {
 background(0);
 streamVideo();
 findFish();
 activeBehavior.draw();
}

void findFish() {
 DetectionResult detect = detector.objects(opencv.image(), 0.3);
 if (detect != null) {
   println(detect.activity);
//      int activityThreshold = 1000000;
   int activityThreshold = 0;
    if (detect.activity < activityThreshold) {
      opencv.copy(blank);
    } else {
      opencv.copy(detect.image);
    }
  
    opencv.threshold(5, 255, OpenCV.THRESH_BINARY + OpenCV.THRESH_OTSU);
  }
  Blob[] blobs = opencv.blobs( 100, width*height/2, 100, false);
  // split by camera
}

void streamVideo() {
  opencv.read();
  opencv.convert(OpenCV.GRAY);
//  opencv.brightness(45);
//  opencv.contrast(5);
  PImage img = opencv.image();
  cam.send(img);
  
//  cam.send(cams[1]);
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

class FishInfo {
  Blob[] blobs;
  FishInfo(Blob[] blobs) {
    this.blobs = blobs;
  } 
}
