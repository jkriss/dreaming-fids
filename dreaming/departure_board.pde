
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
  int framesPerBlink = 30;
  
  color normalColor = 180;
  color blinkColor = 0;
  
  // this list will be shared across displays,
  // so that it flows along all four
  Row[] rows = new Row[nRows];
  
  DepartureBoard(PApplet parent, int numScreens, int border) {
    super(parent, numScreens, border); 
  }

  void setup() {
   
   rowHeight *= h;
   rowPadding *= h;
   topBorder *= h;
   leftBorder *= w/numScreens;
  
   for (int i=0; i<colPaddings.length; i++) colPaddings[i] *= w/numScreens;
   
   for (int i=0; i<maxWidths.length; i++) {
     maxWidths[i] *= w/numScreens;
   }
   for (int i=0; i<nRows; i++) {
     rows[i] = new Row(maxWidths);
   }
  }

  void draw() {
    splitScreens();
  }
  
  void drawScreen(int screenIndex) {
    background(0);
    noStroke();
    fill(180);
    pushMatrix();
    
    if (frameCount % framesPerBlink == 0 ) {
      for (int i=0; i<rows.length; i++) {
        rows[i].blinkIfBlinking();
      }
    }
    
    translate(leftBorder, topBorder);
    for (int colNum=0; colNum<3; colNum++) {
      pushMatrix();
      for (int i=0; i<nRows; i++) {
        Row r = rows[i];
        color c = r.blinkOn && colNum == 2 ? blinkColor : normalColor;
        fill(c);
        rect(0,0,r.colWidths[colNum], rowHeight);
        translate(0, rowPadding+rowHeight);
      }
      popMatrix();
      translate(maxWidths[colNum] + colPaddings[colNum], 0);
    }
    popMatrix();
  }

  void mousePressed() {
    pop();
  }
  
  void keyPressed() {
    rows[(int)random(rows.length)].startBlinking();
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
   int blinkCount = 0;
   Row(float[] maxWidths) {
     this.maxWidths = maxWidths;
     colWidths = new float[maxWidths.length];
     randomize();
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
