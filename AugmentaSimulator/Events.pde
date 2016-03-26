// Keyboard and mouse events

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
  if (keyCode == 157 || key == CONTROL){
    cmdKey = true;
  }
  // Stop/Start the movement of the point
  else if (key == 'm' || key == 'M') {
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
  if (keyCode == 157 || key == CONTROL){
    cmdKey = false;
  }
}