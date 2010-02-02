import hypermedia.video.*;

OpenCV opencv;
int w,h;
int camW = 800;
int camH = 600;
int camW2 = camW/2;
int camH2 = camH/2;

PImage[] cams = new PImage[3];

class CameraFeedSketch extends Behavior {
  CameraFeedSketch(PApplet parent) {
    super(parent);
    w = parent.width/4;
    h = parent.height;
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
    
    pushMatrix();

    // screen 1
    image(cams[1],0,0,w,h);
    
    // screen 2
    translate(w,0);
    image(cams[0],0,0,w,h);
    
    // screen 3
    translate(w,0);
    image(cams[2],0,0,w,h);

    // screen 4
    translate(w,0);
    image(cams[1],0,0,w,h);

    popMatrix();
    
  }
}
