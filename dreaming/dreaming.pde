import org.jklabs.easyosc.*;

import hypermedia.video.*;
import processing.video.*;
import controlP5.*;
import fullscreen.*; 

import oscP5.*;
import netP5.*;

VideoStreamer streamer;
PImage[] cams = new PImage[4];
int camW = 640;
//int camW = 800;
int camH = 480;
int camW2 = camW/2;
//int camH2 = camH/2;
int camH2 = camH; // only using the top quads now
Capture localVideo;
Movie movie;
PImage movieFrame;
UDP udp;

int SERVER_PORT = 4567;
NetAddress oscBroadcast;

boolean showBlobs = true;
boolean useMovie = false;

Behavior[] behaviors = new Behavior[4];
Behavior activeBehavior;
//int[] screenSize = {800, 480};
int[] screenSize = {
  800, 600};
//int screenFactor = screenSize[0] * screenSize[1] / 7000;
int numScreens = 2;
int numCameras = 4;
int border = 0; //10;
int motionLevel;
float scale = 1;

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

EasyOsc osc, thisFish;
OscP5 oscP5;
String hostname = null;

boolean cursorHidden;

CameraFeedSketch mugshotBehavior, zoomingBehavior;
DepartureBoard departureBoardBehavior;
SwitchingCameras switchingCamerasBehavior;
RawInput rawInput;

int framesPerBehavior = 300;
boolean randomCycleTime = false;
int minFramesPerBehavior = 100;
int maxFramesPerBehavior = 1000;

int behaviorIndex = 0;
boolean cycleBehaviors = false;
boolean showFrameRate = false;

Recorder inputRecorder, outputRecorder;

AutoClicker autoclicker = new AutoClicker();
OpenCV adjuster;
int videoBrightness, videoContrast;

void setup() {
  
  try {

    smooth();
  
    inputRecorder = new Recorder(this, "mugshots/input.mov", 10);
    outputRecorder = new Recorder(this, "mugshots/output.mov", 10);
  
    osc = new EasyOsc(this, "fish");
    thisFish = new EasyOsc(this, isThing1() ? "thing1" : "thing2");
    oscP5 = new OscP5(this, "239.0.0.1", 7777); 
    oscBroadcast = new NetAddress("230.0.0.1", 7447);
    PFont font = loadFont("Helvetica-Bold-16.vlw");
    textFont(font);
  
    frameRate(25);
    size((border*(numScreens-1)) + (int)(screenSize[0]*numScreens*scale),(int)(screenSize[1]*scale));
  
    Graphics2D g2 = ((PGraphicsJava2D)g).g2;
    g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
  
    mugshotBehavior = new CameraFeedSketch(this, numScreens, border);
    zoomingBehavior = new CameraFeedSketch(this, numScreens, border);
    switchingCamerasBehavior = new SwitchingCameras(this, numScreens, border);
    zoomingBehavior.zooming = true;
    departureBoardBehavior = new DepartureBoard(this, numScreens, border);
    behaviors[0] = departureBoardBehavior;
    behaviors[1] = mugshotBehavior;
    //behaviors[2] = new RawCameras(this, numScreens, border);
    behaviors[2] = switchingCamerasBehavior;
    //  behaviors[4] = new RawInput(this, numScreens, border);
//    behaviors[4] = zoomingBehavior;
    behaviors[3] = zoomingBehavior;
  
    rawInput = new RawInput(this, numScreens, border);
  
    activeBehavior = behaviors[0];
  
    for (int i=0; i<behaviors.length; i++) {
      if (behaviors[i] != null) behaviors[i].setup(); 
    }
    for (int i=0; i<detectors.length; i++) {
      detectors[i] = new Detector(this, i); 
    }
    for (int i=0; i<fish.length; i++) {
      fish[i] = new FishInfo(); 
      interestRects[i] = new MotionRect(new Rectangle(camW,camH));
    }
    
    movie = new Movie(this, "Fish Comp 3.mov");
    //  movie = new Movie(this, "camera test.mov");
    //  movie = new Movie(this, "Fish Comp 1.mov");
  //  movie = new Movie(this, "input.mov");
  //  movie = new Movie(this, "input2.mov");
  //  movie = new Movie(this, "input-long1-jpeg grayscale.mov");
    movie.loop();
    movieFrame = createImage(camW, camH/2, ALPHA);
  
    streamer = new VideoStreamer(this, sendIP(), 9091);
    udp = new UDP( this, 9091, receiveIP()); // this, port, ip address
    udp.listen(true);
  
    println("sending on " + sendIP() + ", receiving on " + receiveIP());
  
    fs = new SoftFullScreen(this);
    if (hostname().startsWith("thing")) fs.setFullScreen(true);
  
    try {
      setSettings(loadStrings("settings.txt")[0]);
    } catch (Exception e) {
      e.printStackTrace();
    }
    
    //if (!useMovie) 
      initVideo();
  } catch (Exception e) {
    handleError(e);
  }

}

void initVideo() {
 if (localVideo == null) {
   localVideo = new Capture(this, camW+40, camH+40, 24);
   localVideo.crop(20,20,camW,camH/2);
 }
}

void useMovie(boolean b) {
  println("using movie? " + b);
  useMovie = b;
  if (b) {
    //localVideo.stop();
    //localVideo = null;
  } else {
    initVideo();
  }
}

String sendIP() {
  return isThing1() ? "225.0.0.0" : "224.0.0.0";
}

String receiveIP() {
  return "225.0.0.0"; 
  //  return isThing1() ? "224.0.0.0" : "225.0.0.0"; 
}

boolean isThing1() {
  //  return hostname().equals("thing1.local");
  return !hostname().equals("thing2.local");
}

String hostname() {
  if (hostname == null) {
    try {
      String[] cmd_elements = {
        "hostname"            };
      Process p = Runtime.getRuntime().exec(cmd_elements);
      hostname = new BufferedReader(new InputStreamReader(p.getInputStream())).readLine();
    } 
    catch (IOException e) {
    }
  }
  return hostname;
}

void hideCursor() {
  if (cursorHidden || frameCount < 100) return;
  int[] pixels = new int[16 * 16];
  Image image = Toolkit.getDefaultToolkit().createImage(
  new MemoryImageSource(16, 16, pixels, 0, 16));
  Cursor transparentCursor =
    Toolkit.getDefaultToolkit().createCustomCursor
    (image, new Point(0, 0), "invisibleCursor"); 
  setCursor(transparentCursor);
  try {
    new Robot().mouseMove(4,4);
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }
  cursorHidden = true;
}

void showRawInput(String s) {
  activeBehavior = rawInput;
}

void click(String message) {
  // println("osc message: " + message); 
  println("clicking");
  mousePressed();
}

void behavior(int index) {
  println("switching to behavior " + index);
  mugshotBehavior.resetMugshots();
  behaviorIndex = index;
  activeBehavior = behaviors[behaviorIndex];
}

//void cycleBehaviors(String bString) {
//  boolean b = (bString.equals("true"));
//  cycleBehaviors = b;
//}

//void showBlobs(String bString) {
//  boolean b = (bString.equals("true"));
//  println("showing blobs? " + b);
//  showBlobs = b;
//}

void fullscreen(String foo) {
  fs.setFullScreen(!fs.isFullScreen());
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

public void setSettings(String settingsString) {
  println("got settings: " + settingsString);
  saveStrings("settings.txt",new String[]{settingsString});
  String[] settings = settingsString.split("&");
  for (int i=0; i<settings.length; i++) {
    String entry[] = settings[i].split("=");
    String key = entry[0];
    String value = entry.length > 1 ? entry[1] : null; 

    if ("showBlobs".equals(key)) {
      showBlobs = value.equals("showBlobs");
    } else if ("cycleBehaviors".equals(key)) {
      cycleBehaviors = value.equals("cycleBehaviors");
    } else if ("randomCycleTime".equals(key)) {
      randomCycleTime = value.equals("randomCycleTime");
    } else if (key.equals("cycleLength") && value != null) {
      framesPerBehavior = Integer.valueOf(value);
    } else if (key.equals("minFramesPerBehavior") && value != null) {
      minFramesPerBehavior = Integer.valueOf(value);
    } else if (key.equals("maxFramesPerBehavior") && value != null) {
      maxFramesPerBehavior = Integer.valueOf(value);
    } else if (key.equals("switchingCameraInterval") && value != null) {
      switchingCamerasBehavior.framesBeforeSwitch = Integer.valueOf(value);
    } else if (key.equals("zoomCameraInterval") && value != null) {
      zoomingBehavior.framesBeforeSwitch = Integer.valueOf(value);
    } else if (key.equals("mugshotRectThreshold") && value != null) {
      mugshotBehavior.scoreThreshold = Integer.valueOf(value);
      zoomingBehavior.scoreThreshold = Integer.valueOf(value);
    } else if (key.equals("mugshotCameraInterval") && value != null) {
      mugshotBehavior.framesBeforeSwitch = Integer.valueOf(value);
    } else if (key.equals("departuresCameraInterval") && value != null) {
      departureBoardBehavior.framesBeforeSwitch = Integer.valueOf(value);
    } else if (key.equals("departuresBlinkRate") && value != null) {
      departureBoardBehavior.framesPerBlink = Integer.valueOf(value);
    } else if (key.equals("departuresBlinkDuration") && value != null) {
      departureBoardBehavior.maxBlinks = Integer.valueOf(value);
    } else if (key.equals("departuresFramesBeforeNewBlink") && value != null) {
      departureBoardBehavior.framesPerNewBlink = Integer.valueOf(value);
    } else if (key.equals("departuresShuffleInterval") && value != null) {
      departureBoardBehavior.framesBeforeShuffle = Integer.valueOf(value);
    } else if (key.equals("departuresShuffleSpeed") && value != null) {
      departureBoardBehavior.framesHiddenOnShuffle = Integer.valueOf(value);
    } else if (key.equals("departuresVideoOpacity") && value != null) {
      departureBoardBehavior.videoOpacity = Integer.valueOf(value);
    } else if (key.equals("showFrameRate")) {
      showFrameRate = value.equals("showFrameRate");
    } else if (key.equals("brightness") && value != null) {
      videoBrightness = Integer.valueOf(value);
    } else if (key.equals("contrast") && value != null) {
      videoContrast = Integer.valueOf(value);
    } else if (key.equals("useMovie") && value != null) {
      useMovie(value.equals("useMovie"));
    }
  }
}

void draw() {
  
  try {

    autoclicker.doClick(); // will only trigger if it's supposed to
  
    if (frameCount % 1000 == 0) autoclicker.start();
  
    if (cycleBehaviors && isThing1() && frameCount % framesPerBehavior == 0) {
      if (randomCycleTime) framesPerBehavior = (int)random(minFramesPerBehavior, maxFramesPerBehavior);
      behaviorIndex += 1;
      if (behaviorIndex >= behaviors.length) behaviorIndex = 0;
      callMethod("all","setBehavior", ""+behaviorIndex);
    }
  
    background(0);
    streamVideo();
    synchronized(this) {
      findSuspiciousActivity();
      activeBehavior.draw();
    }
  
    fill(106,161,204);
    hideCursor();
  
    if (showFrameRate) text(frameRate, 40, 20);
  
    outputRecorder.record();
  } catch (Exception e) {
    handleError(e);
  }
}

void handleError(Exception e) {
  PrintWriter out = new PrintWriter(createOutput("mugshots/log/processing-error.log"), true);
  e.printStackTrace(out);
  out.close();
  String message =  hostname() + ": " + e.toString();
  println(message);
  Tweeter.tweet(message);
  throw new RuntimeException(e);
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
  if (localVideo != null && !useMovie) {
    if (localVideo.available()) {
      localVideo.read();
      localVideo.loadPixels();
      
      // adjust with opencv
//      if (adjuster == null) {
//        adjuster = new OpenCV(this);
//        println("allocating for " + localVideo.width + "x" + localVideo.height);
//        adjuster.allocate(localVideo.width, localVideo.height);
//      }
////      println("copying " + localVideo.width + "x" + localVideo.height);
//      adjuster.copy(localVideo);
//      adjuster.convert(GRAY);
//      adjuster.brightness(videoBrightness);
//      adjuster.contrast(videoContrast);
//      println("adjusted image is " + adjuster.image().width + "x" + adjuster.image().height);
//      streamer.send(adjuster.image());
      
      // or not
      streamer.send(localVideo);
      inputRecorder.record(localVideo);
    }
  } 
  else {
    movie.read();
    movieFrame.copy(movie, 0, 0, movie.width, movie.height, 0, 0, camW, camH);
    //    int border = 20;
    //    movieFrame.copy(movie, border, border, movie.width-(2*border), movie.height-(2*border), 0, 0, camW, camH);
    streamer.send(movieFrame); 
  }
}

void callMethod(String target, String method) {
  callMethod(target, method, null);
}

void callMethod(String target, String method, String message) {
  OscMessage m = new OscMessage("/"+method);
  m.add(target);
  if (message != null) m.add(message);
  oscP5.send(m);
  // println("sent " + method + " : " + message + " to " + target);
}

void takeMugshot(String m) {
  mugshotBehavior.forceMugshot = true;
}

void oscEvent(OscMessage m) {
  try {
    // println("received an osc message at " + m.addrPattern() + " of type " + m.typetag());
    String method = m.addrPattern().substring(1);
    String target = m.get(0).stringValue();
    String value = null;
    if (m.arguments().length > 1) value = m.get(1).stringValue();
    //  println("target : " + target + ", hostname: " + hostname());
    if (hostname().startsWith(target) || target.equals("all")) {
      // println("calling osc method " + method);
      if (method.equals("showMugshot")) {
        mugshotBehavior.showMugshot(value);
      } 
      else if (method.equals("startDepartureReshuffle")) {
        departureBoardBehavior.startDepartureReshuffle();
      } 
      else if (method.equals("resetMugshots")) {
        mugshotBehavior.resetMugshots();
      } 
      else if (method.equals("setBehavior")) {
        behavior(Integer.valueOf(value));
      } 
      else if (method.equals("departureBlink")) {
        departureBoardBehavior.blink();
      }
    }
  } catch (Exception e) {
    handleError(e);
  }
}

void receive( byte[] data, String ip, int port ) {
  try {
    PImage img = loadPImageFromBytes(data, this);
  
    synchronized(this) {
      cams[isThing1() ? 0 : 2] = img.get(0,0,camW2,camH2);
      cams[isThing1() ? 1 : 3] = img.get(camW2,0,camW2,camH2);
      //  cams[isThing1() ? 2 : 5] = img.get(0,camH2,camW2,camH2);
    
      // for now
      //  cams[isThing1() ? 3 : 0] = cams[0];
      //  cams[isThing1() ? 4 : 1] = cams[1];
      //  cams[isThing1() ? 5 : 2] = cams[2];
    
      PImage frame = null;
      if (movieFrame != null) frame = movieFrame;
      if (localVideo != null && !useMovie) frame = localVideo;
    
      if (frame != null) {
        cams[isThing1() ? 2 : 0] = frame.get(0,0,camW2,camH2);
        cams[isThing1() ? 3 : 1] = frame.get(0,0,camW2,camH2);
    
        //    cams[isThing1() ? 3 : 0] = frame.get(0,0,camW2,camH2);
        //    cams[isThing1() ? 4 : 1] = frame.get(camW2,0,camW2,camH2);
        //    cams[isThing1() ? 5 : 2] = frame.get(0,camH2,camW2,camH2);
      }
    
      for (int i=0; i<cams.length; i++) {
        fish[i].blobs = detectors[i].findBlobs(cams[i]);
        fish[i].activity = detectors[i].activity;
      }
    }
  } catch (Exception e) {
    handleError(e);
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
  boolean logging = false;
  Rectangle bounds;
  MotionRect(Rectangle bounds) {
    this.bounds = bounds;
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
  float maxDist = dist(0,0,screenSize[0], screenSize[1]);
  void step() {
    //   float amt = .6;
    //   current.x = interp(current.x, target.x, amt, 0.7);   
    //   current.y = interp(current.y, target.y, amt, 0.7);   
    //   current.width = interp(current.width, target.width, 0.2, 0.3);   
    //   current.height = interp(current.height, target.height, 0.2, 0.3);   
//    float amt = 1;
    
    float thisDist = dist(current.x, current.y, target.x, target.y);
    
    if (thisDist == 0) return;
    
    if (this == mostInterestingRect && logging)
      println("linear motion: " + thisDist);
    
    float positionAmt = exponentialEasing(thisDist/maxDist,0.22);
    
    positionAmt = .98;
    
    //print("moved from " + current.x + "," + current.y + " to ");
    
    float fastFactor = 2.5;

    current.x = interp(current.x, target.x, screenSize[0]/fastFactor);   
    current.y = interp(current.y, target.y, screenSize[1]/fastFactor);

    
//    println(current.x + "," + current.y);
//    println("position shifting by a factor of " + positionAmt);

    current.width = interp(current.width, target.width, screenSize[0]/fastFactor);   
    current.height = interp(current.height, target.height, screenSize[1]/fastFactor);   

    if (this == mostInterestingRect && logging)
      println("   now at " + current.x + "," + current.y + " (" + current.width + "x" + current.height + "), cam " + cameraIndex);

    stability += dist(current.x, current.y, target.x, target.y);
    activity *= 0.95;
    //stability *= 0.7;
    
    //activity *= 0.95;
    stability *= 0.85;
  }

  int interp(int start, int end, float maxAmt) {
    //   return end;
    int delta = abs(end-start);
    float percentOfMax = delta/maxAmt;
    float threshholdedMax = min(1.0, percentOfMax);
//    float scaledFactor = exponentialEasing(threshholdedMax, 0.22);
    float scaledFactor = exponentialEasing(threshholdedMax, 0.005);
    
    if (this == mostInterestingRect && logging) {
      print("   ");
      if (percentOfMax > threshholdedMax) print("MAX - ");
      println("moving along by " + scaledFactor + " for " + percentOfMax + " (capped at " + threshholdedMax + ")");
    }
    //   return (int)lerp(start,end,min(maxAmt, amt*screenFactor/delta));
    //return (int)lerp(start,end,min(maxAmt, amt*screenSize[0]*scale*screenSize[1]*scale*768/delta));

    return (int)lerp(start,end,scaledFactor); // most recent

    //   return (int)lerp(start,end,min(maxAmt, amt*100/delta));
  }
  float exponentialEasing (float x, float a){
    float epsilon = 0.00001;
    float min_param_a = 0.0 + epsilon;
    float max_param_a = 1.0 - epsilon;
    a = max(min_param_a, min(max_param_a, a));
    
    if (a < 0.5){
      // emphasis
      a = 2.0*(a);
      float y = pow(x, a);
      return y;
    } else {
      // de-emphasis
      a = 2.0*(a-0.5);
      float y = pow(x, 1.0/(1-a));
      return y;
    }
  }
}

public void record(int frames) {
  println("starting to record...");
  inputRecorder.startRecording(frames);
  outputRecorder.startRecording(frames);
}

class Recorder {

  MovieMaker mm;

  boolean recording = false;
  int maxFrames, count;

  PApplet parent;
  String filename;
  int frameRate;

  public Recorder(PApplet parent, String filename, int frameRate) {
    this.parent = parent; 
    this.filename = filename;
    this.frameRate = frameRate;
  }

  void startRecording(int frames) {
    recording = true;
    count = 0;
    maxFrames = frames;
  } 

  void record() {
    record(null);
  }

  void record(PImage inputFrame) {
    if (mm == null && recording) {
      String path = sketchPath+"/"+filename;
      File f = new File(path);
      println("recording to " + path);
      if (f.exists()) f.delete();
      if (inputFrame == null)
        mm = new MovieMaker(parent, width, height, filename, frameRate, MovieMaker.H263, MovieMaker.HIGH);
      else
        mm = new MovieMaker(parent, inputFrame.width, inputFrame.height, filename, frameRate, MovieMaker.H263, MovieMaker.HIGH);
    }
    if (mm != null) {
      if (inputFrame == null)
        mm.addFrame();
      else
        mm.addFrame(inputFrame.pixels, inputFrame.width, inputFrame.height);
    }
    count += 1;
    if (count > maxFrames && recording) {
      println("writing movie file");
      mm.finish();
      mm = null;
      recording = false;
    }
  }

}

class AutoClicker {
  int clicks = 0;
  int pause = 100;

  void start() {
    clicks = 0;
    doClick();
  }

  void doClick() {
    if (clicks < 3 && frameCount % pause == 0) {
      println("autoclicking");
      clicks++;
      click("tbbttth");
    }
  }
}

static class Tweeter {
 
 static void tweet(String message) {
   String[] cmd = {"curl", "-u", "dreamingfids:dreaming", "-d", "status=d jkriss " + message, "http://twitter.com/statuses/update.xml"};
   println("tweeting: " + cmd);
   try {
     Process p = Runtime.getRuntime().exec(cmd);
     try { p.waitFor(); } catch (InterruptedException e) { e.printStackTrace(); }
     println("tweeted! or something! exit value: " + p.exitValue());
   } catch (IOException e) { 
     e.printStackTrace(); 
   }
 }
  
}

