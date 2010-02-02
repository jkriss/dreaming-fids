import hypermedia.video.*;

OpenCV opencv;
int camW = 800;
int camH = 600;
int camW2 = camW/2;
int camH2 = camH/2;

int[] cameraMappings = { 1, 0, 2, 1 };

PImage[] cams = new PImage[3];

class CameraFeedSketch extends Behavior {
  CameraFeedSketch(PApplet parent, int numScreens) {
    super(parent, numScreens);
  }
  void setup() {
    opencv = new OpenCV(parent);
    opencv.capture(camW, camH);
  }
  void draw() {
    opencv.read();
    cams[0] = opencv.image().get(0,0,camW2,camH2);
    cams[1] = opencv.image().get(camW2,0,camW2,camH2);
    cams[2] = opencv.image().get(0,camH2,camW2,camH2);
    
    splitScreens();
  }
  
  void drawScreen(int i) {
    image(cams[cameraMappings[i]],0,0,w,h);
  }
}
