import oscP5.*; // this can certainly be deleted once augmenta lib will be updated (see below) 
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.UnknownHostException;

NetAddress myRemoteLocation;

// Keyboard, mouse and osc events

void mouseDragged() {
  oldX = x;
  oldY = y;
  // Update coords
  x = mouseX;
  y = mouseY;

  // The following code is here just for pure fun and aesthetic !
  // It enables the point to go on in its sinus road where
  // you left it !
  
  float xSin = x;
  
  // Clamping
  if (x>width*9/10){
    xSin=width*9/10;
  }
  if (x<width/10){
    xSin=width/10;
  }
  // Reverse
  t = asin(map(xSin, width/10,width*9/10, -1, 1));
}

void keyPressed() {
  if (keyCode == 157 || key == CONTROL){ cmdKey = true; } 
  if (keyCode == 16 || key == SHIFT) { shiftKey = true; }
  if (keyCode == 17) { ctrlKey = true; }
  if (keyCode == UP) { upKey = true; } 
  if (keyCode == DOWN) { downKey = true; } 
  if (keyCode == LEFT) { leftKey = true; } 
  if (keyCode == RIGHT) { rightKey = true; }

  // Stop/Start the movement of the point
  if (key == 'm' || key == 'M') {
    moving=!moving;
    movingBox.setState(moving);
  } else if (key == 's' || key == 'S') {
    if (cmdKey){
      saveSettings();
    } else {
      send=!send;
      sendDataBox.setState(send);
      if (send) {
        pid = int(random(1000));
        age = 0;
        augmenta.sendSimulation(movablePerson, sendingAddress, "personEntered");
        // Send personEntered for the people generation
        if(generate){
          for (int i = 0; i < persons.length; i++) {
            persons[i].send(augmenta, sendingAddress, "personEntered");
          }
        }
      } else {
        augmenta.sendSimulation(movablePerson, sendingAddress, "personWillLeave");
        // Send personWillLeave for the old generated people
        if(generate){
          for (int i = 0; i < persons.length; i++) {
            persons[i].send(augmenta, sendingAddress, "personWillLeave");
          }
        }
      }
    }
  } else if (keyCode == TAB){
    if (sceneX.isFocus()){
       sceneX.setFocus(false);
       sceneY.setFocus(true);
    }
  } else if(cmdKey && key == 'l'){
    loadSettings();
  }else if (key == 'g' || key == 'G') {
    generate=!generate;
    generateBox.setState(generate);
    if (send && !generate) {
      // Send personWillLeave for the old people generated
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personWillLeave");
      }
    } else if (send && generate) {
      // Send personEntered for the old people generated
      for (int i = 0; i < persons.length; i++) {
        persons[i].send(augmenta, sendingAddress, "personEntered");
      }
    }
  } else if (key == 'd' || key == 'D') {
    draw=!draw;
    drawBox.setState(draw);
  }
}

void keyReleased(){
  if (keyCode == 157 || key == CONTROL){ cmdKey = false; } 
  if (keyCode == 16 || key == SHIFT) { shiftKey = false; }
  if (keyCode == 17) { ctrlKey = false; }
  if (keyCode == UP) { upKey = false; } 
  if (keyCode == DOWN) { downKey = false; } 
  if (keyCode == LEFT) { leftKey = false; } 
  if (keyCode == RIGHT) { rightKey = false; }
}

// To make this work we have to update Augmenta library to invoke another oscEvent event
void oscEvent(OscMessage _oscMessage) {
  
  StringBuilder sb = new StringBuilder();
  InetAddress ip = null;
  
  if(_oscMessage.checkAddrPattern("/info"))
  {
    
    println("Received " + _oscMessage.addrPattern() + " " + _oscMessage.get(0).toString() + " " + _oscMessage.get(1).toString());
    
    // Parse osc message
    String remoteIp = _oscMessage.get(0).stringValue();
    int remotePort = _oscMessage.get(1).intValue();
    myRemoteLocation = new NetAddress(remoteIp,remotePort);
    
    // Get own ip and mac address
    try
    {
      ip = InetAddress.getLocalHost();
      println("Current IP address: " + ip.getHostAddress());
      NetworkInterface network = NetworkInterface.getByInetAddress(ip);
   
      byte[] mac = network.getHardwareAddress();
   
      print("Current MAC address: ");
   
      for (int i = 0; i < mac.length; i++)
      {
        sb.append(String.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : ""));
      }
      println(sb.toString());
    }
    catch (UnknownHostException e)
    {
      e.printStackTrace();
    }
    catch (SocketException e)
    {
      e.printStackTrace();
    }
    
    // Send osc message
    
     /* Protocol :
     *
     * /info
     * [0] - daemonIp (string)
     * [1] - name(string) ==> nicename, configurable via web interface (ex: "cam lointain")
     * [2] - mac (string)
     * [3] - software version (version_date) (string)
     * [4] - current settings file name (string)
     * [5] - type (grabber-pipe si augmenta cam)(string)
     * [6] - plane status (string : "Off", "Manual","Auto-Found","Auto-NotFound")
     *
     */

    OscMessage myMessage = new OscMessage("/info");
    myMessage.add(ip.getHostAddress());
    myMessage.add("Simulator");
    myMessage.add(sb.toString());
    myMessage.add("0.1");
    myMessage.add("N/A");
    myMessage.add("Simulator Processing");
    myMessage.add("N/A");

    // send the message
    oscP5.send(myMessage, myRemoteLocation);
    
  } else {
    /* print the address pattern and the typetag of the received OscMessage */
    print("### received an osc message.");
    print(" addrpattern: "+_oscMessage.addrPattern());
    println(" typetag: "+_oscMessage.typetag());
  }
}