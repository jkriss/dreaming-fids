import hypermedia.net.*;
import com.sun.image.codec.jpeg.*; 

class VideoStreamer {
  
  UDP udp;
  String ip;
  int port;
  BufferedImage img = null;

  VideoStreamer(PApplet parent, String ip, int port) {
    udp = new UDP(parent); 
    this.ip = ip;
    this.port = port;
  }
  
  void send(PImage img) {
    byte[] jpgBytes=jpgFromPImage(img); 
    udp.send( jpgBytes, ip, port );
  }
  
  //following function modified from forum post by seltar 
  //http://processing.org/discourse/yabb_beta/YaBB.cgi?board=Syntax;action=display;num=1138221586 
  
  byte[] jpgFromPImage(PImage srcimg){ 
    if (srcimg == null) {
      println("src image null, returning");
      return null; 
    }
    ByteArrayOutputStream out = new ByteArrayOutputStream(); 
    if (img == null) {
//      img = (BufferedImage)createImage(srcimg.width, srcimg.height); 
      img = new BufferedImage(srcimg.width, srcimg.height, BufferedImage.TYPE_USHORT_GRAY);
    }
    
    try {  // make sure we can access the buffered image
      img.setRGB(0,0, 0);
    } catch (Exception e) {
      return null;
    }
    
    try {
      img.getRaster().setPixels(0,0,srcimg.width, srcimg.height, srcimg.pixels);
    }catch (Exception e) {}   
    
    try{ 
      JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out); 
      JPEGEncodeParam encpar = encoder.getDefaultJPEGEncodeParam(img); 
      encpar.setQuality(0.7,true); // 0.0-1.0, force baseline 
      encoder.setJPEGEncodeParam(encpar); 
      encoder.encode(img); 
    }catch(FileNotFoundException e){ 
      System.out.println(e); 
    }catch(IOException ioe){ 
      System.out.println(ioe); 
    }
    
    return out.toByteArray(); 
  }

}
