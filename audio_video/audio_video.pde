import ddf.minim.analysis.*;
import ddf.minim.*;
 
Minim minim;
AudioPlayer sample;
FFT fft;
float totalMax;
PVector direzione;
float speed;

boolean savePDF = false;

Capture video;

int x, y;
int curvePointX = 0; 
int curvePointY = 0;
int pointCount = 1;
float diffusion = 50;
ArrayList<Float> difference;
ArrayList<Float> old;
float maximum;
int indexMax;

import processing.video.*;
import processing.pdf.*;
import java.util.Calendar;

import processing.video.*;
import processing.pdf.*;
import java.util.Calendar;



void setup() {
  size(640, 480);
  background(255);
  x = width/2;
  y = height/2;
  video = new Capture(this, width, height, 30);
  video.start();
  minim = new Minim(this);
  sample = minim.loadFile("A.mp3", 2048); // buffer size affects totalMax
  sample.loop();
  fft = new FFT(sample.bufferSize(), sample.sampleRate());
  difference= new ArrayList<Float>();
   old= new ArrayList<Float>();
   maximum=-1;
   indexMax=0;
  
  
}
 
void initializeDiffArray(ArrayList<Float> difference, ArrayList<Float> old,float[] mma){

 
    for(int j=0;j<fft.specSize(); j++){
      difference.add(new Float(0.0));
      old.add(fft.getBand(j));
    }
  
 
}
 
void draw() {
  fft.forward(sample.mix);
  float[] mma = getMinMaxAvg(fft);
  if (mma[1] > totalMax) { totalMax = mma[1]; }
  println("min: " + nf(mma[0], 1, 3) + " | max: " + nf(mma[1], 2, 3) + " | avg: " + nf(mma[2], 1, 3) + " totalMax: " + nf(totalMax, 2, 3));
   // Calculate a "wind" force based on mouse horizontal position
  //float dx = map(mouseX, 0,width, -0.2, 0.2);
  //PVector wind = new PVector(dx, 0);
  float localMax=0;
  if(difference.size()==0 && difference.size()==0 ){
     initializeDiffArray( difference,  old, mma);
  }else{
    for(int i=0; i<fft.specSize();i++){
      if(fft.getBand(i)>localMax){
        localMax=fft.getBand(i);
      }
      if(difference.get(i)>maximum){
        maximum=(difference.get(i));
        indexMax=i;
      }
     difference.set(i,abs(fft.getBand(i)-old.get(i)));
     old.set(i,abs(fft.getBand(i)-old.get(i)));
        
   }
  }
  println("localMax: " + nf(localMax, 1, 3));
  if(mma[1]>0.8){
  draw2(fft.specSize(),localMax);
  }
  
}

void draw2(int mma_length,  float localMax) {
  colorMode(HSB, 360, 100, 100);
  smooth();
  noFill();
  float xpos= map(indexMax*100,0,mma_length*100,0,video.width);
  for (int j=0; j<=xpos/50; j++) {
    // get actual web cam image
    if (video.available()) video.read();
    video.loadPixels();

    // first line
    int pixelIndex = ((video.width-1-x) + y*video.width);
    color c = video.pixels[pixelIndex];
    //float hueValue = hue(c);
   
    stroke(c);
    //if(difference.size()>=4 && difference.get(4)!=null){
      
    diffusion = map(localMax, 0,423, 5,100);
    if(localMax<1){
       strokeWeight(hue(c)/150);
    }else{
      strokeWeight(hue(c)/(localMax));
    }
     
     println("diffusion: " + diffusion +"|| " );
    //}

    beginShape();
    curveVertex(x, y);
    curveVertex(x, y);
    for (int i = 0; i < pointCount; i++) {
      int rx = (int) random(-diffusion, diffusion);
      curvePointX = constrain(x+rx, 0, width-1);
      int ry = (int) random(-diffusion, diffusion);
      curvePointY = constrain(y+ry, 0, height-1);
      curveVertex(curvePointX, curvePointY);
    }
    curveVertex(curvePointX, curvePointY);
    endShape();
    
    x = curvePointX;
    y = curvePointY;
  }
}

 
float[] getMinMaxAvg(FFT fft) {
  float minimum = 99999, maximum = 0, avg = 0;
  for(int i=0; i<fft.specSize(); i++) {
   
    float value = fft.getBand(i);
    if(i==2 && totalMax>5 && direzione!=null){
      direzione.y=map(value,0,totalMax,0,height/2);
      if(direzione.y<0){
        direzione.y=0;
      }
      if(direzione.y>height){
        direzione.y=height;
      }
    }
    if(i==((int)fft.specSize()/3) && totalMax>5 && direzione!=null){
      direzione.x=map(value,0,totalMax,0,width/2);
      if(direzione.x<0){
        direzione.x=0;
      }
      if(direzione.x>width){
        direzione.x=width;
      }
    }
    if (value<minimum) { minimum = value; }
    if (value>maximum) { maximum = value; }
    avg += value;
  }
  avg /= fft.specSize();
  float[] mma = { minimum, maximum, avg };
  return mma;
}
 
void stop() {
  sample.close();
  minim.stop();
  super.stop();
}


void keyPressed(){
  switch(key){
  case BACKSPACE:
   stop();
    break;
  }
}



void keyReleased(){
  if (key == 's' || key == 'S') saveFrame(timestamp()+"_##.png");
  
  if (key == 'r' || key == 'R'){  
    background(360);
    beginRecord(PDF, timestamp()+".pdf");
  }
  if (key == 'e' || key == 'E'){  
    endRecord();
  }

  if (key == 'q' || key == 'S') noLoop();
  if (key == 'w' || key == 'W') loop();
  
  if (keyCode == UP) pointCount = min(pointCount+1, 30);
  if (keyCode == DOWN) pointCount = max(pointCount-1, 1); 

}

// timestamp
String timestamp() {
  Calendar now = Calendar.getInstance();
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now);
}