class Behavior {
  
 PApplet parent;
 int w,h;
 int numScreens;

 Behavior(PApplet parent, int numScreens) {
   this.parent = parent;
   this.numScreens = numScreens;
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
     translate(w,0);
   }
   
   popMatrix();
 }
 
 void drawScreen(int screenNum) {
   // overridden by child classes
 }
 
 
}
