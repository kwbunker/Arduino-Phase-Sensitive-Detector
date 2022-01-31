// {PSDDrawProcessing.}
//    Copyright (C) {2014}  Kevin D. Schultz
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

/*
 Modifyed by FLE 20220130
 Make ADC input for ADC2 for OctoUNO hardware.  Useing A2.
 Move graphing into draw()
 
 Got good ideas from:https://discourse.processing.org/t/how-to-solve-disabling-serialevent-for-com3-null/10214/4
 Fix error of type: Disabling serialEvent for COMn null”
 Move from serial event handler to main loop these lines
 mix = int(split(myString, ','));     // split the string at the commas // and convert the sections into integers:
 PSD(choice);        //Draw the PSD
 
 Change sin cos look up table for single range of 2 Pi
 */

import processing.serial.*;
float TC=200.0;
float x=exp(-1/TC);
PFont f;
float a=1-x;
float b=x;
float I_filter_out;
float Q_filter_out;
float I_prev_filter;
float Q_prev_filter;
int linefeed = 10;      // linefeed in ASCII
Serial myPort;          // The serial port
float filter_out = 0;
float old_filter=0;// the value from the sensor
int graphPosition = 0;  // the horizontal position of the latest
float prev_filter=0;                     // line to be drawn on the graph
int mix[];
float mix_I;
float mix_Q;
PFont myFont;

float phase;
int choice=0;

String myString ="";
boolean gotString = false;  //Flag for the serial event  

void setup() {
  size(512, 256);
  background(0);
  // List all the available serial ports
  printArray(Serial.list());
  f = createFont("Arial", 16, true);
  // I know that the first port in the serial list on my Mac
  // is always my  Arduino, so I open Serial.list()[4].
  // Open whatever port is the one you're using (the output
  // of Serial.list() can help; the are listed in order
  // starting with the one that corresponds to [4]).


  // read bytes into a buffer until you get a linefeed (ASCII 10):

  myPort=new Serial(this, Serial.list()[6], 19200);
  //myPort=new Serial(this, Serial.list()[6], 38400);
  //myPort=new Serial(this, Serial.list()[6],115200);        //FLE Make Faster
  myPort.bufferUntil('\n');
}// end setup()

void draw() {

  if (gotString == true) {
    mix = int(split(myString, ','));     // split the string at the commas // and convert the sections into integers:
    PSD(choice);        //Draw the PSD
  }

  line(graphPosition-1, prev_filter, graphPosition, filter_out);
}

void serialEvent(Serial myPort) { 
  // read the serial buffer
  myString = myPort.readStringUntil('\n');
  if (myString != null) {
    myString = trim(myString);      // if you got any bytes other than the linefeed:
    gotString = true; 
    //mix = int(split(myString, ','));     // split the string at the commas // and convert the sections into integers:
    //PSD(choice);        //Draw the PSD
  }// end not null
}// end serialEvent()

void mousePressed()
{
  saveFrame("Snap.png");
  if (mouseButton == LEFT) {  
    println("Left pressed.");
  } else if (mouseButton == RIGHT) {
    background(0);      //FLE lets not erase.
    graphPosition=0;
    println("Right pressed.");
  } else if (mouseButton == CENTER) {
    println("Center pressed.\n");    
  } else {  
    println("Mouse but no button.\n");
    // No action
  }
}

/*  Key  Action
 z    decress TC
 x    increase TC
 i    Inphase
 m    Magnatude
 p    Phase
 q    Quadrature
 
 */

void keyReleased()
{
  if (key=='z'||key=='Z')
  {
    TC--;
    println(TC);
  }
  if (key=='x'||key=='X')
  {
    TC++;
    println(TC);
  }  
  if (key=='i'||key=='I')
  {
    choice=1;
  }
  if (key=='m'||key=='M')
  {
    choice=0;
  }
  if (key=='p'||key=='P')
  {
    choice=3;
  }
  if (key=='q'||key=='Q')
  {
    choice=2;
  }
}// end keyrelease() 

//Draw the PSD to the window.
void PSD(int option) {
  x=exp(-1/TC);
  a=1-x;
  b=x;

  mix_I = map(mix[0], -10000, 10000, height, 0);
  println("mixI= "+mix_I);
  mix_Q = map(mix[1], -10000, 10000, height, 0);
  println("mixQ="+mix_Q);

  switch(option) {
  case 0:
    prev_filter = filter_out;
    I_prev_filter = I_filter_out;
    Q_prev_filter = Q_filter_out;     
    I_filter_out = a*mix_I + b*I_prev_filter;
    Q_filter_out = a*mix_Q + b*Q_prev_filter;
    filter_out=sqrt(I_filter_out * I_filter_out + Q_filter_out * Q_filter_out);  //Magnitude
    println("mag");
    fill(0);
    noStroke();
    rect(0, 0, width, 100);
    textFont(f, 16);                 // STEP 4 Specify font to be used
    fill(56);                        // STEP 5 Specify font color 
    text("Magnitude="+filter_out, 10, 100);

    break;
  case 1:
    prev_filter=filter_out;
    filter_out=a*mix_I+b*prev_filter;
    println("in phase");
    fill(0);
    noStroke();
    rect(0, 0, width, 100);
    textFont(f, 16);                 // STEP 4 Specify font to be used
    fill(56);                        // STEP 5 Specify font color 
    text("I="+filter_out, 10, 100);
    break;
  case 2:
    prev_filter=filter_out;
    filter_out=a*mix_Q+b*prev_filter;
    println("Quadature");
    fill(0);
    noStroke();
    rect(0, 0, width, 100);
    textFont(f, 16);                 // STEP 4 Specify font to be used
    fill(56);                        // STEP 5 Specify font color 
    text("Q="+filter_out, 10, 100);
    break;
  case 3:
    prev_filter=filter_out;
    I_prev_filter=I_filter_out;
    Q_prev_filter=Q_filter_out;     
    I_filter_out=a*mix_I+b*I_prev_filter;
    Q_filter_out=a*mix_Q+b*Q_prev_filter;

    filter_out=atan(Q_filter_out/I_filter_out)*360/6.42;
    println("phase= "+filter_out);

    fill(0);
    noStroke();
    rect(0, 0, width, 100);
    textFont(f, 16);                 // STEP 4 Specify font to be used
    fill(56);                        // STEP 5 Specify font color 
    text("phase="+filter_out, 10, 100);
    break;
  }

  drawGraph();
  myPort.write("A"); 
  // println(filter_out);
}// end PSD()

void drawGraph() {
  smooth();
  fill(20);
  stroke(0, 255, 100);
  strokeWeight(2);

  line(graphPosition-1, prev_filter, graphPosition, filter_out);
  if (graphPosition>=width)
  {
    graphPosition=0;
    //    background(0);      //FLE lets not erase.
  } else {

    graphPosition++;
  }
}//end drawGraph()
