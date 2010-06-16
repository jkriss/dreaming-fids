import hypermedia.net.*;
import javax.imageio.*;
import javax.imageio.stream.*;

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
      img = new BufferedImage(srcimg.width, srcimg.height, BufferedImage.TYPE_INT_ARGB);
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
//      JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out); 
//      JPEGEncodeParam encpar = encoder.getDefaultJPEGEncodeParam(img); 
//      encpar.setQuality(0.7,true); // 0.0-1.0, force baseline 
//      encoder.setJPEGEncodeParam(encpar); 
//      encoder.encode(img); 
      Iterator iter = ImageIO.getImageWritersByFormatName("jpeg");
      ImageWriter writer = (ImageWriter)iter.next();
      ImageWriteParam iwp = writer.getDefaultWriteParam();
      iwp.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
      iwp.setCompressionQuality(0.7); 
      MemoryCacheImageOutputStream memOut = new MemoryCacheImageOutputStream(out);
    
      writer.setOutput(memOut);
      IIOImage ioimage = new IIOImage(img, null, null);
      writer.write(null, ioimage, iwp);
      writer.dispose();

    }catch(FileNotFoundException e){ 
      System.out.println(e); 
    }catch(IOException ioe){ 
      System.out.println(ioe); 
    }
    
    return out.toByteArray(); 
  }

}
