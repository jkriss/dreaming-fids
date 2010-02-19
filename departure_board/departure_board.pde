
float[] colPositions = { 0.5, 0.35, 0.15 };
float[] minWidths = { 0.6, 0.7, 0.8 };
float rowHeight = 30;
int rowPadding = 15;
int colPadding = 15;
int nRows = 7;
int topBorder = 65;
int leftBorder = 25;
int maxBlinks = 20;
int framesPerBlink = 20;

color normalColor = 180;
color blinkColor = 210;

// this list will be shared across displays,
// so that it flows along all four
Row[] rows = new Row[nRows];
float[] maxWidths;

void setup() {
 size(800, 480); 
 maxWidths = new float[colPositions.length];
 for (int i=0; i<maxWidths.length; i++) {
   maxWidths[i] = (width - (2 * leftBorder) - ((colPositions.length-1) * colPadding)) * colPositions[i];
 }
 for (int i=0; i<nRows; i++) {
   rows[i] = new Row(maxWidths);
 }
}

void draw() {   
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
    float maxWidth = (width - (2 * leftBorder) - ((colPositions.length-1) * colPadding)) * colPositions[colNum];
    for (int i=0; i<nRows; i++) {
      Row r = rows[i];
      color c = r.blinkOn ? blinkColor : normalColor;
      fill(c);
      rect(0,0,r.colWidths[colNum], rowHeight);
      translate(0, rowPadding+rowHeight);
    }
    popMatrix();
    translate(maxWidth + colPadding, 0);
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
