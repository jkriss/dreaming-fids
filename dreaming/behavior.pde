class Behavior {
  
 PApplet parent;
 int w,h;
 int numScreens;
 int border;

 Behavior(PApplet parent, int numScreens, int border) {
   this.parent = parent;
   this.numScreens = numScreens;
   this.border = border;
   w = parent.width;
   h = parent.height;
 }
 
 void setup() {
 }
 
 void draw() {
 }
 
 void spanScreens() {
  w = parent.width;
 }
 
 void splitScreens() {
   w = parent.width/numScreens;
   pushMatrix();
   
   for (int i=0; i<numScreens; i++) {
     drawScreen(i);
     translate(w+border,0);
   }
   
   popMatrix();
 }
 
 void drawScreen(int screenNum) {
   // overridden by child classes
 }
 
 void scaleBlobs(Blob[] blobs, int w, int h, int targetW, int targetH) {
    float wScale = targetW / (float)w;
    float hScale = targetH / (float)h;
    for (int i=0; i<blobs.length; i++) {
      Blob b = blobs[i];
      for (int j=0; j<b.points.length; j++) {
        b.points[j].x *= wScale;
        b.points[j].y *= hScale;
      }
      b.rectangle.x *= wScale;
      b.rectangle.y *= hScale;
      b.rectangle.width *= wScale;
      b.rectangle.height *= hScale;
      b.centroid.x *= wScale;
      b.centroid.y *= hScale;
    } 
  }

 
}
