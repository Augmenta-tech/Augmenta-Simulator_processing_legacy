/**
 *
 *    * Augmenta simulator
 *    Send some generated Augmenta persons with your mouse
 *
 *    Author : David-Alexandre Chanel
 *             Tom Duchêne
 *
 *    Website : http://www.theoriz.com
 *
 */

import netP5.*; // Needed for Augmenta
import TUIO.*; // Needed for Augmenta
import augmentaP5.*; // Augmenta
import java.util.List; // Needed for the GUI implementation
import java.awt.geom.Point2D; // 2D points to send AugmentaPersons
import controlP5.*; // GUI

// Detect when the mouse is outside the window (to detect resize)
import java.awt.Point;
import java.awt.MouseInfo;
java.awt.Insets insets;

AugmentaP5 augmenta;
String addressString = "127.0.0.1";
NetAddress sendingAddress;
boolean inputIsValid = true;
AugmentaPerson movablePerson;
// Width and height to send
int augmentaWidth, augmentaHeight;

// ControlP5
ControlP5 cp5;
Textfield sceneX;
Textfield sceneY;
Textlabel sceneSizeInfo;
Textfield portInput;
Textlabel inputError;
Toggle sendDataBox;
Toggle movingBox;
Toggle generateBox;
Textfield generateCountBox;
Toggle drawBox;

// Save/Load
String defaultSettingsFile = "Simulator-settings";
// Key modifiers
boolean cmdKey = false;
boolean shiftKey = false;
boolean ctrlKey = false;
boolean upKey = false;
boolean downKey = false;
boolean leftKey = false;
boolean rightKey = false;

float x, oldX = 0;
float y, oldY = 0;
float accX, accY; // acceleration
float velX, velY; // velocity
float maxVel = 2;
float accFactor = 0.1;
float friction = 0.05;
float t = 0; // time
int age = 0;
int sceneAge = 0;
int direction = 1;
int pid = int(random(1,100)); // avoid collision with generated points
int oscPort = 12000;
// Fixed vector between centroid and highest point 
PVector vecHighest = new PVector(random(-0.02, 0.02),random(-0.02, 0.02));

Boolean send = true;
Boolean moving = false;
Boolean generate = false;
Boolean draw = true;
Boolean generateHasChanged = false;

// Array of TestPerson points
int generateCount = 10;
TestPerson[] persons;

void settings(){
  // Set the initial frame size
  size(640, 480, P2D);
  //PJOGL.profile=2;
}

void setup() {
 
  // Init
  background(0);
  x=width/2;
  y=height/2;
  frameRate(30);
  
  // Allow window to be resized
  /*if (surface != null) {
    surface.setResizable(true);
  }*/
  
  // GUI
  cp5 = new ControlP5(this);
  cp5.setUpdate(true);
  setUI();
  loadSettings();
  applySettings();
   
  // OSC network com
  augmenta = new AugmentaP5(this, 50000);
  sendingAddress = new NetAddress(addressString, oscPort);
  PVector pos = new PVector(0.5f, 0.5f);
  float size = 0.1f;
  RectangleF rect = new RectangleF(pos.x-size/2, pos.y-size/2, size, size);
  movablePerson = new AugmentaPerson(pid, pos, rect);
  movablePerson.highest.x = movablePerson.centroid.x + vecHighest.x;
  movablePerson.highest.y = movablePerson.centroid.y + vecHighest.y;
  movablePerson.highest.z = random(0.4, 0.6);
  
  updateGeneration();
}

void draw() {

  background(0);

  if (generate) {
    // Update and draw the TestPersons
    for (int i = 0; i < persons.length; i++) {
      persons[i].update();
      //persons[i].send(augmenta, sendingAddress);
      if (send) {
        fill(255);
      } else {
        fill(128);
      }
      if(draw){
        persons[i].draw();
      }
    }
  } 

  if (!mousePressed)
  {
    // Save the old positions for the main point
    oldX = x;
    oldY = y;
    // Sin animation
    if (moving) {
      x = map(sin(t), -1, 1, width/10, width*9/10);
       // Increment val
      t = t + direction*TWO_PI/70; // 70 inc
      t = t % TWO_PI;
    }
    
    // Inertia and friction
    accX = 0;
    accY = 0;
    // Update acceleration
    float acc = accFactor;
    if(ctrlKey || cmdKey){ acc/=2; }
    if ( upKey ) { accY-=acc; }
    if ( downKey ) { accY+=acc; }
    if ( leftKey ) { accX-=acc; }
    if ( rightKey ) { accX+=acc; }
    // Update velocity
    float maxVelocity = maxVel;
    if(shiftKey){ maxVelocity*=2; }
    if( abs(velX) < maxVelocity) { velX+=accX; }
    if( abs(velY) < maxVelocity) { velY+=accY; }
    // Decelerate
    if ( (!upKey && !downKey) || (abs(velY) > maxVelocity)) { velY*=(1-friction); }
    if ( (!leftKey && !rightKey) || (abs(velX) > maxVelocity)) { velX*=(1-friction); }
    // Update position
    x+=velX;
    y+=velY;
  } 
  // mousePressed
  else {
    // Stop inertial movement
    velX = 0;
    velY = 0;
  }

  // Draw disk
  if (send) {
    fill(255);
  } else {
    fill(128);
  }
  if (draw){
    ellipse(oldX, oldY, 19, 19);
    //rect(
    textSize(14);
    text(""+pid, oldX+20, oldY-9, 50, 20);
  }

  age++;

  // Update point
  movablePerson.centroid.x = (float)x/width;
  movablePerson.centroid.y = (float)y/height;
  movablePerson.velocity.x = (x - oldX)/width;
  movablePerson.velocity.y = (y - oldY)/height;
  movablePerson.boundingRect.x = movablePerson.centroid.x - movablePerson.boundingRect.width/2;
  movablePerson.boundingRect.y = movablePerson.centroid.y - movablePerson.boundingRect.height/2;
  movablePerson.highest.x = movablePerson.centroid.x + vecHighest.x;
  movablePerson.highest.y = movablePerson.centroid.y + vecHighest.y;
  // Other values
  movablePerson.age = age;
  movablePerson.depth = 0.5f;

  // Send point
  if (send) {
    augmenta.sendSimulation(movablePerson, sendingAddress);
    if (generate) {
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress);
      }
    }
  }
  // Send scene
  sceneAge++;
  // Warning : percentCovered and averageMotion are not implemented yet and replaced by random values
  float percentCovered = random(0.1)+0.2f;
  Point2D.Float averageMotion = new Point2D.Float(2f+random(0.1), -2f+random(0.1));
  // Compute the number of persons in the scene
  int personsInScene = 1; // The "mouse" person
  if (generate) personsInScene +=  persons.length; // + the generation if activated
  augmenta.sendScene(augmentaWidth, augmentaHeight, 100, sceneAge, percentCovered, personsInScene, averageMotion, sendingAddress);

  // Draw input error if needed
  if(inputIsValid){
    inputError.setVisible(false);
  } else {
    inputError.setVisible(true); 
  }
}

public void updateGeneration(){
  
  // Send personWillLeave for the old generated people
  if (persons != null){
    for (int i = 0; i < persons.length; i++) {
      persons[i].send(augmenta, sendingAddress, "personWillLeave");
    }
  }
  persons = new TestPerson[generateCount];

  // generate people
  for (int i = 0; i < generateCount ; i++) {
      persons[i] = new TestPerson(random(0.1, 0.9), random(0.1, 0.9));
      persons[i].p.oid = i; // set oid
  } 
}

// Check if the mouse is inside the frame
boolean mouseIsInFrame() {
  Point mouse = new Point(0,0);
  try{
    mouse = MouseInfo.getPointerInfo().getLocation();
  } catch(Exception e){
  }
  Point win = frame.getLocation();

  if(!frame.isUndecorated()){
    //add borders of window
    insets = frame.getInsets();
    win.x += insets.left;
    win.y += insets.top;
  }
  
  boolean in = false;
  if(mouse.x-win.x >= 20 && width-20 >= mouse.x-win.x)
    if(mouse.y-win.y >= 20 && height-20 >= mouse.y-win.y)
      in = true;

  return in;
}

// --------------------------------------
// Exit function (This way of handling the exit of the app works everywhere except in the editor)
// --------------------------------------
void exit(){
  // Save the settings on exit
  saveSettings();
  
  // Add custom code here
  // ...
  
  // Finish by forwarding the exit call
  super.exit();
}
// --------------------------------------