
float[] colPositions = { 0.5, 0.25, 0.25 };
float rowHeight = 30;
int rowPadding = 15;
int colPadding = 15;
int nRows = 7;
int topBorder = 65;
int leftBorder = 25;

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
  translate(leftBorder, topBorder);
  for (int colNum=0; colNum<3; colNum++) {
    pushMatrix();
    float maxWidth = (width - (2 * leftBorder) - ((colPositions.length-1) * colPadding)) * colPositions[colNum];
    for (int i=0; i<nRows; i++) {
      Row r = rows[i];
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

void pop() {
  arraycopy(rows, 1, rows, 0, rows.length-1);
  rows[rows.length-1] = new Row(maxWidths);
}

class Row {
 float[] maxWidths;
 float[] colWidths;
 Row(float[] maxWidths) {
   this.maxWidths = maxWidths;
   colWidths = new float[maxWidths.length];
   randomize();
 }
 void randomize() {
   for (int i=0; i<colWidths.length; i++) {
     colWidths[i] = maxWidths[i] * random(0.5, 1);
   }
 }
}
