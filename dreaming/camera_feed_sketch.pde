import hypermedia.video.*;

OpenCV opencv;
int w,h;

class CameraFeedSketch extends Behavior {
  CameraFeedSketch(PApplet parent) {
    super(parent);
    w = parent.width/4;
    h = parent.height;
  }
  void setup() {
    opencv = new OpenCV(parent);
    opencv.capture(w, h);
  }
  void draw() {
    opencv.read();
    for (int i=0; i<4; i++) {
      image(opencv.image(),i*w,0);
    }
  }
}
