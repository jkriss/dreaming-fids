
class DepartureBoard extends Behavior {

  float[] colPositions = { 57/104.0, 14/104.0, 7/104.0 };
  float[] minWidths = { 14/57.0, 1, 1 };
  float[] maxWidths = { 57/104.0, 14/104.0, 7/104.0 };
  float rowHeight = 5/78.0;
  float rowPadding = 2/78.0;
  float[] colPaddings = { 10/104.0, 4/104.0, 0 };
  int nRows = 10;
  float topBorder = 5/78.0;
  float leftBorder = 6/104.0;
  int maxBlinks = 20;
  int framesPerBlink = 10;
  int framesBeforeShuffle = 200;
  int framesPerNewBlink = 100;
  
  color normalColor = 255;
  color blinkColor = 0;
  
  PGraphics b;
  // this list will be shared across displays,
  // so that it flows along all four
  Row[] rows = new Row[nRows*numScreens];
  
  DepartureBoard(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }

  void setup() {
     
  }
  
  public void startDepartureReshuffle() {
    println("starting departure board reshuffle");
    rows[0].hide(); 
  }

  void draw() {
    
    if (isThing1() && frameCount % framesBeforeShuffle == 0) {
      //pop();
      if (rows[0] != null) rows[0].hide();
    }
    if (frameCount % framesPerNewBlink == 0) {
      Row r = rows[(int)random(rows.length)];
      if (r != null) r.startBlinking();
    }
    if (frameCount % framesPerBlink == 0 ) {
      for (int i=0; i<rows.length; i++) {
        if (rows[i] != null) rows[i].blinkIfBlinking();
      }
    }
    background(0);
    splitScreens();
  }
    
  void drawScreen(int screenIndex) {
    
    
    PImage cam = cams[screenIndex];

    if (cam == null) return;
//    image(cam,0,0,w,h);

    if (b == null) {
//      b = createGraphics(cam.width, cam.height,JAVA2D);
      b = createGraphics(width/2, height, JAVA2D);  
      rowHeight *= b.height;
      rowPadding *= b.height;
      topBorder *= b.height;
      leftBorder *= b.width;

       for (int i=0; i<colPaddings.length; i++) colPaddings[i] *= b.width;
       
       for (int i=0; i<maxWidths.length; i++) {
         maxWidths[i] *= b.width;
       }
       for (int i=0; i<rows.length; i++) {
         rows[i] = new Row(maxWidths);
       }
    }
    
//    b.beginDraw();
    //background(0);
        image(cam, 0, 0, w, h);
    fill(0,0,0,128);
    rect(0,0,w,h);

//    b.background(75);
    noStroke();
    fill(normalColor);
    pushMatrix();
    
    translate(leftBorder, topBorder);
    for (int colNum=0; colNum<3; colNum++) {
      pushMatrix();
      int start = screenIndex*nRows;
      for (int i=start; i<nRows+start; i++) {
        Row r = rows[i];
        Row nextRow = null;
        if (i < rows.length-1) {
          nextRow = rows[i+1];
        }
//        color c = r.blinkOn && colNum == 2 ? blinkColor : normalColor;

        if (r.blinkOn && colNum == 2) continue;
//        fill(c);
        if (!r.hidden(nextRow)) {
          rect(0,0,r.colWidths[colNum], rowHeight);
        }
        translate(0, rowPadding+rowHeight);
      }
      popMatrix();
      translate(maxWidths[colNum] + colPaddings[colNum], 0);
    }
    popMatrix();
//    b.endDraw();
    
//    PImage board = get(w*screenIndex, 0, w, h);
//    PImage board = b.get(0,0,b.width,b.height);
//    image(cam, 0, 0, w, h);
//    PImage scaledCam = get(w*screenIndex, 0, w, h);
//    cam.mask(board);
//    image(board, 0, 0, w, h);
//    image(cam, 0, 0, w, h);
    
//    image(board, 0, 0, w, h);

  }

  void pop() {
    arraycopy(rows, 1, rows, 0, rows.length-1);
    rows[rows.length-1] = new Row(maxWidths);
  }

  class Row {
   float[] maxWidths;
   float[] colWidths;
   boolean blinking;
   boolean blinkOn;
   boolean hidden;
   int hiddenFrames;
   int blinkCount = 0;
   Row(float[] maxWidths) {
     this.maxWidths = maxWidths;
     colWidths = new float[maxWidths.length];
     randomize();
   }
   void hide() {
     hidden = true;
     hiddenFrames = 0;
   }
   boolean hidden(Row nextHidden) {
     if (!hidden) return false;
     hiddenFrames += 1;
     boolean done = hiddenFrames > 5;
     if (done) {
       hidden = false;
       if (nextHidden != null) {
         arrayCopy(nextHidden.colWidths, colWidths);
         nextHidden.hide();
       } else {
         randomize();
         // this means we're done updating for this machine
         if (isThing1()) {
           callMethod("thing2", "startDepartureReshuffle");
         }
       }
     }
     return !done;
   }
   void startBlinking() {
     blinking = true;
   }
   void blinkIfBlinking() {
     if (blinking) {
       blinkCount += 1;
       blinkOn = !blinkOn;
       if (blinkCount == maxBlinks) {
         blinking = false;
         blinkOn = false;
       }
     }
   }
   void randomize() {
     for (int i=0; i<colWidths.length; i++) {
       colWidths[i] = maxWidths[i] * random(minWidths[i], 1);
     }
     if (random(1) > 0.7) colWidths[colWidths.length-1] = 0;
   }
  }
}
