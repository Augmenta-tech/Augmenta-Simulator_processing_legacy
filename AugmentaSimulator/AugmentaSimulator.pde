/**
 *
 *    * Augmenta simulator
 *    Send some generated Augmenta Packet
 *    Use your mouse to send custom packets
 *
 *    Author : David-Alexandre Chanel
 *             Tom Duchêne
 *
 *    Website : http://www.theoriz.com
 *
 */

import netP5.*;
import java.awt.geom.Point2D;
import augmentaP5.*;
import controlP5.*;

// Detect when the mouse is outside the window (to detect resize)
import java.awt.Point;
import java.awt.MouseInfo;
java.awt.Insets insets;

AugmentaP5 augmenta;
String addressString = "127.0.0.1";
NetAddress sendingAddress;
AugmentaPerson testPerson;

// ControlP5
ControlP5 cp5;
Textfield sceneX;
Textfield sceneY;
Textlabel sceneSizeInfo;
Textfield portInput;
CheckBox sendDataBox;
CheckBox movingBox;
CheckBox gridBox;
Textfield gridCountBox;
CheckBox drawBox;
// Save/Load
String defaultSettingsFile = "settings";
// Key modifiers
boolean cmdKey = true;

float x, oldX = 0;
float y, oldY = 0;
float t = 0; // time
int age = 0;
int sceneAge = 0;
int direction = 1;
int pid = int(random(1000));
int oscPort = 12000;

Boolean send = true;
Boolean moving = false;
Boolean grid = false;
Boolean draw = true;
Boolean gridHasChanged = false;

// Array of TestPerson points
int gridCount = 10;
TestPerson[] persons;

// Store the size of the scene to detect when it changes
int oldWidth;
int oldHeight;

void settings(){
  // Set the initial frame size
  size(640, 480, P2D);
  PJOGL.profile=1;
}

void setup() {
  
 
  // New GUI instance
  cp5 = new ControlP5(this);
  // Set the properties format : needed to save/load correctly
  cp5.getProperties().setFormat(ControlP5.SERIALIZED);
cp5.setUpdate(true);
  // Set the UI
  setUI();
  loadSettings();
  cp5.update();
  
  oldWidth=width;
  oldHeight=height;
  surface.setResizable(true);
  frame.pack();
  smooth();
  frameRate(30);
  
  updateGrid();
 
  // Osc network com
  augmenta = new AugmentaP5(this, 50000);
  sendingAddress = new NetAddress(addressString, oscPort);
  RectangleF rect = new RectangleF(0.4f, 0.4f, 0.2f, 0.2f);
  PVector pos = new PVector(0.5f, 0.5f);
  testPerson = new AugmentaPerson(pid, pos, rect);
  testPerson.highest.z = random(0.4, 0.6);

  

  // Init
  y=height/2;
  x=width/2;
}

void draw() {

  background(0);

  if (grid) {
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
    }
  }
  // Draw disk
  if (send) {
    fill(255);
  } else {
    fill(128);
  }
  if (draw){
    ellipse(x, y, 20, 20);
    //rect(
    textSize(16);
    text(""+pid, x+20, y-10, 50, 20);
  }
  

  // Increment val
  t= t + direction*TWO_PI/70; // 70 inc
  t = t % TWO_PI;
  age++;

  // Update point
  testPerson.centroid.x = (float)x/width;
  testPerson.centroid.y = (float)y/height;
  testPerson.velocity.x = (x - oldX)/width;
  testPerson.velocity.y = (y - oldY)/height;
  testPerson.boundingRect.x = (float)x/width-0.1;
  testPerson.boundingRect.y = (float)y/height-0.1;
  testPerson.highest.x = testPerson.centroid.x;
  testPerson.highest.y = testPerson.centroid.y;
  // Other values 
  testPerson.age = age;
  testPerson.depth = 0.5f;

  // Send point
  if (send) {
    augmenta.sendSimulation(testPerson, sendingAddress);
    if (grid) {
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
  if (grid) personsInScene +=  persons.length; // + the grid if activated
    
  augmenta.sendScene(width, height, 100, sceneAge, percentCovered, personsInScene, averageMotion, sendingAddress);

}

void mouseDragged() {
  oldX = x;
  oldY = y;
  // Update coords
  x = mouseX;
  y = mouseY;

  // The following code is here just for pure fun and aesthetic !
  // It enables the point to go on in its sinus road where
  // you left it !

  // Clamping
  if (x>width*9/10)
  {
    x=width*9/10;
  }
  if (x<width/10)
  {
    x=width/10;
  }
  // Reverse
  t = asin(map(x, width/10, width*9/10, -1, 1));
  // Don't do it visually
  x = mouseX;
  // Change direction by calculating speed vector
  if (mouseX - pmouseX < 0)
  {
    direction = -1;
  } else {
    direction = 1;
  }
}

void keyPressed() {
  if (keyCode == 157 || key == CONTROL){
    cmdKey = true;
  }
  // Stop/Start the movement of the point
  else if (key == 'm' || key == 'M') {
    moving=!moving;
  } else if (key == 's' || key == 'S') {
    if (cmdKey){
      saveSettings();
    } else {
      send=!send;
      if (send) {
        augmenta.sendSimulation(testPerson, sendingAddress, "personEntered");
        // Send personEntered for the grid
        if(grid){
          for (int i = 0; i < persons.length; i++) {
            persons[i].send(augmenta, sendingAddress, "personEntered");
          }
        }
      } else {
        augmenta.sendSimulation(testPerson, sendingAddress, "personWillLeave");
        // Send personWillLeave for the old grid
        if(grid){
          for (int i = 0; i < persons.length; i++) {
            persons[i].send(augmenta, sendingAddress, "personWillLeave");
          }
        }
      }
      pid = int(random(1000));
      age = 0;
    }
  } else if (keyCode == TAB){
    if (sceneX.isFocus()){
       sceneX.setFocus(false);
       sceneY.setFocus(true);
    }
  } else if(key == 's'){
   saveSettings("settings"); 
  }else if (key == 'g' || key == 'G') {
    grid=!grid;
    if (!grid && send) {
      // Send personWillLeave for the old grid
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personWillLeave");
      }
    }
  } else if (key == 'd' || key == 'D') {
    draw=!draw;
  }
}

void keyReleased(){
  if (keyCode == 157 || key == CONTROL){
    cmdKey = false;
  }
}

public void updateGrid(){
  
  // Send personWillLeave for the old grid
  if (persons != null){
    for (int i = 0; i < persons.length; i++) {
      persons[i].send(augmenta, sendingAddress, "personWillLeave");
    }
  }
  persons = new TestPerson[gridCount];

  // Create grid
  for (int i = 0; i < gridCount ; i++) {
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

void showGUI(boolean val) {
  // Show or hide the GUI after the Syphon output
  portInput.setVisible(val);

  sceneX.setVisible(val);
  sceneY.setVisible(val);
}

void setUI() {
  
  // IP / Port input OSC
  cp5.addTextlabel("labeloscport")
      .setText("OSC input ip:port")
      .setPosition(10, 16)
      ;
  portInput = cp5.addTextfield("changeInputAddress")
     .setPosition(100,10)
     .setSize(105,20)
     .setAutoClear(false)
     .setCaptionLabel("")
     ;
  portInput.setText(addressString+":"+oscPort);
  cp5.addButton("forceBroadcast")
     .setPosition(210,10)
     .setSize(55,20)
     .setCaptionLabel("Broadcast")
     ;
  cp5.addButton("forceLocal")
     .setPosition(270,10)
     .setSize(40,20)
     .setCaptionLabel("Local")
     ;      
     
  // CHANGE SCENE SIZE
  sceneX = cp5.addTextfield("changeSceneWidth")
     .setPosition(100,35)
     .setSize(30,20)
     .setAutoClear(false)
     .setCaptionLabel("")
     .setInputFilter(ControlP5.INTEGER);
     ;
  sceneX.setText(""+width);
  sceneY = cp5.addTextfield("changeSceneHeight")
     .setPosition(130,35)
     .setSize(30,20)
     .setAutoClear(false)
     .setCaptionLabel("")
     .setInputFilter(ControlP5.INTEGER);
     ;
  sceneY.setText(""+height);
  cp5.addTextlabel("labelchangesize")
      .setText("Change scene size")
      .setPosition(10, 41)
      ;
      
  // Data send
  sendDataBox = cp5.addCheckBox("changeSendData")
                .setPosition(10, 60)
                .setSize(15, 15)
                .addItem("Send data", 0)
                ;
  if(send){sendDataBox.activate(0);} else {sendDataBox.deactivate(0);}
  
  // Grid
  gridBox = cp5.addCheckBox("changeGrid")
                .setPosition(10, 85)
                .setSize(15, 15)
                .addItem("Activate grid", 0)
                ;
  if(grid){gridBox.activate(0);} else {gridBox.deactivate(0);}
  gridCountBox = cp5.addTextfield("changeGridCount")
     .setPosition(90,84)
     .setSize(25,17)
     .setAutoClear(false)
     .setCaptionLabel("")
     .setInputFilter(ControlP5.INTEGER)
     .setText(""+gridCount)
     ;
  
  // Move point
  movingBox = cp5.addCheckBox("changeMoving")
                .setPosition(10, 110)
                .setSize(15, 15)
                .addItem("Move the main point", 0)
                ;
  if(moving){movingBox.activate(0);} else {movingBox.deactivate(0);}
  
  // Move point
  drawBox = cp5.addCheckBox("changeDraw")
                .setPosition(10, 135)
                .setSize(15, 15)
                .addItem("Draw", 0)
                ;
  if(draw){drawBox.activate(0);} else {drawBox.deactivate(0);}
}

void changeInputAddress(String s){
  String[] ints = split(s, ':');
  String ip = ints[0];
  String port = ints[1];
  if (Integer.parseInt(port) != oscPort || ip != addressString) {
    println("input :"+ip+":"+port);
    if (Integer.parseInt(port) > 1024 && Integer.parseInt(port) < 65535){
      addressString = ip;
      oscPort = Integer.parseInt(port);
      augmenta.unbind();
      augmenta=null;
      augmenta= new AugmentaP5(this, 50000);
      sendingAddress = new NetAddress(addressString, oscPort);
    }
  }
}

void forceBroadcast(int v){
  println("force broadcast");
  String[] ints = split(portInput.getText(), ':');
  
  String ip = ints[0];
  String port = ints[1];
  int intPort;
  try{
   intPort = Integer.parseInt(port);
  } catch (NumberFormatException e) {
   intPort = 12000; 
  }
  if (intPort != oscPort || ip != addressString) {
    println("input :"+ip+":"+port);
    if (intPort > 1024 && intPort < 65535){
      addressString="255.255.255.255";
      oscPort = intPort;
      augmenta.unbind();
      augmenta=null;
      augmenta= new AugmentaP5(this, 50000);
      sendingAddress = new NetAddress(addressString, oscPort);
      portInput.setText(addressString+":"+oscPort);
    }
  }
}

void forceLocal(int v){
  println("force local");
  String[] ints = split(portInput.getText(), ':');
  
  String ip = ints[0];
  String port = ints[1];
  int intPort;
  try{
   intPort = Integer.parseInt(port);
  } catch (NumberFormatException e) {
   intPort = 12000; 
  }
  if (intPort != oscPort || ip != addressString) {
    println("input :"+ip+":"+port);
    if (intPort > 1024 && intPort < 65535){
      addressString="127.0.0.1";
      oscPort = intPort;
      augmenta.unbind();
      augmenta=null;
      augmenta= new AugmentaP5(this, 50000);
      sendingAddress = new NetAddress(addressString, oscPort);
      portInput.setText(addressString+":"+oscPort);
    }
  }
}

void changeSceneWidth(String s){
  adjustSceneSize();
}
void changeSceneHeight(String s){
  adjustSceneSize(); 
}

void changeSendData(float[] a) {
  if(a[0] == 1){
     send = true;
  } else {
    send = false;
  }
}

void changeGrid(float[] a) {
  if(a[0] == 1){
    grid = true;
  } else {
    grid = false;
  }
}

void changeGridCount(String s){
  gridCount = (Integer.parseInt(s));
  updateGrid();
}
  
  
void changeMoving(float[] a) {
  if(a[0] == 1){
    moving = true;
  } else {
    moving = false;
  }
}
void changeDraw(float[] a) {
  if(a[0] == 1){
    draw = true;
  } else {
    draw = false;
  }
}
void adjustSceneSize() {

  int sw = Integer.parseInt(sceneX.getText());
  int sh = Integer.parseInt(sceneY.getText());
    
  if ( (width!=sw || height!=sh) && sw>100 && sh>100 && sw<=16000 && sh <=16000 ) {
    surface.setSize(sw+frame.getInsets().left+frame.getInsets().right, sh+frame.getInsets().top+frame.getInsets().bottom);
  }
}

void saveSettings(String file){
  /*
  println("Saving to : "+file);
  cp5.saveProperties(file);
  */
}
void saveSettings(){
  saveSettings(defaultSettingsFile);
}

void loadSettings(String file){
  /*
  println("Loading from : "+file);
  cp5.loadProperties(file);
  */
}
void loadSettings(){
  loadSettings(defaultSettingsFile);
}

void stop(){
 saveSettings("settings"); 
}