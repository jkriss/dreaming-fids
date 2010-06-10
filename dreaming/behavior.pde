class Behavior {
  
 PApplet parent;
 int w,h;
 int numScreens;
 int border;
 
 int[] cameraMappings = { 0, 1, 2, 3 };
 int framesBeforeSwitch = 200;

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
 
}
