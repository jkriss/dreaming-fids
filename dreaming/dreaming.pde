import org.jklabs.easyosc.*;

import controlP5.*;
import fullscreen.*; 

import oscP5.*;
import netP5.*;

int camW = 640;
//int camW = 800;
int camH = 480;
int camW2 = camW/2;
//int camH2 = camH/2;
int camH2 = camH; // only using the top quads now

int SERVER_PORT = 4567;
NetAddress oscBroadcast;

boolean showBlobs = true;
boolean useMovie = false;

Behavior activeBehavior;

int[] screenSize = {
  800, 600};
//int screenFactor = screenSize[0] * screenSize[1] / 7000;
int numScreens = 2;
int numCameras = 4;
int border = 0; //10;
int motionLevel;
float scale = 1;

public int threshold = 16;
public int maxThreshold = 500;

SoftFullScreen fs; 

EasyOsc osc, thisFish;
OscP5 oscP5;
String hostname = null;

boolean cursorHidden;

DepartureBoard departureBoardBehavior;

int framesPerBehavior = 300;
boolean randomCycleTime = false;
int minFramesPerBehavior = 100;
int maxFramesPerBehavior = 1000;

int behaviorIndex = 0;
boolean cycleBehaviors = false;
boolean showFrameRate = false;

void setup() {

  try {

    smooth();

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

    departureBoardBehavior = new DepartureBoard(this, numScreens, border);
    activeBehavior = departureBoardBehavior;
    activeBehavior.setup();

    fs = new SoftFullScreen(this);
    if (hostname().startsWith("thing")) fs.setFullScreen(true);

    try {
      setSettings(loadStrings("settings.txt")[0]);
    } 
    catch (Exception e) {
      e.printStackTrace();
    }

  } 
  catch (Exception e) {
    handleError(e);
  }

}


String sendIP() {
  return isThing1() ? "225.0.0.0" : "224.0.0.0";
}

String receiveIP() {
  return isThing1() ? "224.0.0.0" : "225.0.0.0"; 
}

boolean isThing1() {
  return hostname().equals("thing1.local");
}

String hostname() {
  if (hostname == null) {
    try {
      String[] cmd_elements = {
        "hostname"                  };
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

void fullscreen(String foo) {
  fs.setFullScreen(!fs.isFullScreen());
}

public void setSettings(String settingsString) {
  println("got settings: " + settingsString);
  saveStrings("settings.txt",new String[]{
    settingsString  }
  );
  String[] settings = settingsString.split("&");
  for (int i=0; i<settings.length; i++) {
    String entry[] = settings[i].split("=");
    String key = entry[0];
    String value = entry.length > 1 ? entry[1] : null; 

    if (key.equals("departuresBlinkRate") && value != null) {
      departureBoardBehavior.framesPerBlink = Integer.valueOf(value);
    } 
    else if (key.equals("departuresBlinkDuration") && value != null) {
      departureBoardBehavior.maxBlinks = Integer.valueOf(value);
    } 
    else if (key.equals("departuresFramesBeforeNewBlink") && value != null) {
      departureBoardBehavior.framesPerNewBlink = Integer.valueOf(value);
    } 
    else if (key.equals("departuresShuffleInterval") && value != null) {
      departureBoardBehavior.framesBeforeShuffle = Integer.valueOf(value);
    } 
    else if (key.equals("departuresShuffleSpeed") && value != null) {
      departureBoardBehavior.framesHiddenOnShuffle = Integer.valueOf(value);
    } 
  }
}

void draw() {

  try {

    background(0);
    
    activeBehavior.draw();

    fill(106,161,204);
    hideCursor();
  } 
  catch (Exception e) {
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
      if (method.equals("startDepartureReshuffle")) {
        departureBoardBehavior.startDepartureReshuffle();
      } else if (method.equals("departureBlink")) {
        departureBoardBehavior.blink();
      }
    }
  } 
  catch (Exception e) {
    handleError(e);
  }
}


static class Tweeter {

  static void tweet(String message) {
    String[] cmd = {
      "curl", "-u", "dreamingfids:dreaming", "-d", "status=d jkriss " + message, "http://twitter.com/statuses/update.xml"    };
    println("tweeting: " + cmd);
    try {
      Process p = Runtime.getRuntime().exec(cmd);
      try { 
        p.waitFor(); 
      } 
      catch (InterruptedException e) { 
        e.printStackTrace(); 
      }
      println("tweeted! or something! exit value: " + p.exitValue());
    } 
    catch (IOException e) { 
      e.printStackTrace(); 
    }
  }

}


