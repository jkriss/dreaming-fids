import hypermedia.video.*;

OpenCV opencv;
//int camW = 320;
//int camH = 240;
int camW = 640;
int camH = 480;
int camW2 = camW/2;
int camH2 = camH/2;

int[] cameraMappings = { 1, 0, 2, 1 };
VideoStreamer stream1, stream2, stream3;

PImage[] cams = new PImage[3];

class CameraFeedSketch extends Behavior {
  
  CameraFeedSketch(PApplet parent, int numScreens) {
    super(parent, numScreens); 
  }
  
  void setup() {
    opencv = new OpenCV(parent);
    opencv.capture(camW, camH);
    stream1 = new VideoStreamer(parent, "localhost", 9091);
    stream2 = new VideoStreamer(parent, "localhost", 9092);
    stream3 = new VideoStreamer(parent, "localhost", 9093);
  }
  
  void draw() {
    opencv.read();
    opencv.convert(OpenCV.GRAY);
    PImage img = opencv.image();
    cams[0] = img.get(0,0,camW2,camH2);
    cams[1] = img.get(camW2,0,camW2,camH2);
    cams[2] = img.get(0,camH2,camW2,camH2);
    
//    stream1.send(cams[(millis() / 10000) % 3]);
//    stream2.send(cams[1]);
//    stream3.send(cams[2]);
    opencv.brightness(45);
    opencv.contrast(5);
    stream1.send(opencv.image());
    
    splitScreens();
  }
  
  void drawScreen(int i) {
    image(cams[cameraMappings[i]],0,0,w,h);
  }
}
