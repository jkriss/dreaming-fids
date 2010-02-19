
float[] colPositions = { 0.5, 0.25, 0.25 };
float rowHeight = 30;
int rowPadding = 15;
int colPadding = 15;
int rows = 7;
int topBorder = 65;
int leftBorder = 25;

void setup() {
 size(800, 480); 
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
    for (int r=0; r<rows; r++) {
      rect(0,0,maxWidth, rowHeight);
      translate(0, rowPadding+rowHeight);
    }
    popMatrix();
    translate(maxWidth + colPadding, 0);
  }
  popMatrix();
}
