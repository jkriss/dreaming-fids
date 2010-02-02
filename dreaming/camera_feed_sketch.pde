import hypermedia.video.*;

OpenCV opencv;

class CameraFeedSketch extends Behavior {
  CameraFeedSketch(PApplet parent) {
    super(parent);
  }
  void setup() {
    opencv = new OpenCV(parent);
    opencv.capture(parent.width, parent.height);
  }
  void draw() {
    opencv.read();
    background(opencv.image());
  }
}
