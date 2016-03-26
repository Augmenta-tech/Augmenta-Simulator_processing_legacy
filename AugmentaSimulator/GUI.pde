// GUI and settings functions

void showGUI(boolean val) {
  portInput.setVisible(val);
  sceneX.setVisible(val);
  sceneY.setVisible(val);
}

void setUI() {
  
  // IP / Port output OSC
  cp5.addTextlabel("labeloscport")
      .setText("OSC out   ip:port")
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
     .setPosition(211,10)
     .setSize(55,20)
     .setCaptionLabel("Broadcast")
     ;
  cp5.addButton("forceLocal")
     .setPosition(271,10)
     .setSize(40,20)
     .setCaptionLabel("Local")
     ;    
  inputError = cp5.addTextlabel("labelInputError")
                  .setPosition(320, 16)
                  .setText("Error : address not valid")
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
  sendDataBox = cp5.addToggle("changeSendData")
                .setPosition(14, 110)
                .setSize(15, 15)
                .setLabel("");
                ;
  sendDataBox.setState(send);
  cp5.addTextlabel("labelSendData")
      .setText("Send data")
      .setPosition(34, 113)
      ;
  
  // Generate
  generateBox = cp5.addToggle("changeGenerate")
                .setPosition(14, 85)
                .setSize(15, 15)
                .setLabel("");
                ;
  generateBox.setState(generate);
  cp5.addTextlabel("labelGenerate")
      .setText("Generate                     persons")
      .setPosition(34, 88)
      ;
  generateCountBox = cp5.addTextfield("changeGenerateCount")
     .setPosition(85,84)
     .setSize(25,17)
     .setAutoClear(false)
     .setCaptionLabel("")
     .setInputFilter(ControlP5.INTEGER)
     .setText(""+generateCount)
     ;
  
  // Move point
  movingBox = cp5.addToggle("changeMoving")
                .setPosition(14, 60)
                .setSize(15, 15)
                .setLabel("");
                ;
  if(moving){movingBox.setState(true);} else {movingBox.setState(false);}
  cp5.addTextlabel("labelMovePoint")
      .setText("Move point")
      .setPosition(34, 63)
      ;
      
  // Move point
  drawBox = cp5.addToggle("changeDraw")
                .setPosition(14, 135)
                .setSize(15, 15)
                .setLabel("");
                ;
  drawBox.setState(draw);
  cp5.addTextlabel("labelDraw")
      .setText("Draw")
      .setPosition(34, 138)
      ;
}

void changeInputAddress(String s){

  inputIsValid = false; // consider false until proven OK
  
  String[] ints = split(s, ':');
  String ip, port;
  try{
    ip = ints[0];
    port = ints[1];
    Integer.parseInt(port);
  } catch(Exception e){
    return; 
  }
  if (Integer.parseInt(port) != oscPort || ip != addressString) {
    if (Integer.parseInt(port) > 1024 && Integer.parseInt(port) < 65535){
      addressString = ip;
      oscPort = Integer.parseInt(port);
      augmenta.unbind();
      augmenta=null;
      augmenta= new AugmentaP5(this, 50000);
      sendingAddress = new NetAddress(addressString, oscPort);
      if (sendingAddress.isvalid()){
        inputIsValid = true; 
      }
    }
  }
  
}

void forceBroadcast(int v){
  
  println("force broadcast");
  int intPort;
  String[] ints = split(portInput.getText(), ':');
  String ip, port;
  try{
    ip = ints[0];
    port = ints[1];
    intPort = Integer.parseInt(port);
  } catch(Exception e){
    ip = "";
    intPort = 12000;
  }
  if (intPort != oscPort || ip != addressString) {
    if (intPort < 1024 || intPort > 65535){
      intPort=12000;
    }
    addressString="255.255.255.255";
    oscPort = intPort;
    augmenta.unbind();
    augmenta=null;
    augmenta= new AugmentaP5(this, 50000);
    sendingAddress = new NetAddress(addressString, oscPort);
    portInput.setText(addressString+":"+oscPort);
    inputIsValid = true;
  }
}

void forceLocal(int v){
  println("force local");
  int intPort;
  String[] ints = split(portInput.getText(), ':');
  String ip, port;
  try{
    ip = ints[0];
    port = ints[1];
    intPort = Integer.parseInt(port);
  } catch(Exception e){
    ip = "";
    intPort = 12000;
  }
  if (intPort != oscPort || ip != addressString) {
    if (intPort < 1024 || intPort > 65535){
      intPort=12000;
    }
    addressString="127.0.0.1";
    oscPort = intPort;
    augmenta.unbind();
    augmenta=null;
    augmenta= new AugmentaP5(this, 50000);
    sendingAddress = new NetAddress(addressString, oscPort);
    portInput.setText(addressString+":"+oscPort);
    inputIsValid = true;
  }
}

void changeSceneWidth(String s){
  adjustSceneSize();
}

void changeSceneHeight(String s){
  adjustSceneSize(); 
}

void changeSendData(boolean b) {
  send = b;
}

void changeGenerate(boolean b) {
  generate = b;
}

void changeGenerateCount(String s){
  try{
    generateCount = (Integer.parseInt(s));
    if(generateCount > 5000){
     generateCount = 5000;
     generateCountBox.setText(""+generateCount);
    }
  } catch(Exception e) {
    return;
  }
  updateGeneration();
}

void changeMoving(boolean b) {
  moving = b;
}
void changeDraw(boolean b) {
  draw = b;
}

void adjustSceneSize() {
  int sw, sh;
  try{
    sw = Integer.parseInt(sceneX.getText());
    sh = Integer.parseInt(sceneY.getText());
  } catch(Exception e){
    return;
  }
  if ( (augmentaWidth!=sw || augmentaHeight!=sh) && sw>=300 && sh>=300 && sw<=16000 && sh <=16000 ) {
    // Create the output canvas with the correct size
    augmentaWidth = sw;
    augmentaHeight = sh;
    float ratio = (float)sw/(float)sh;
    if (sw >= displayWidth*0.9f || sh >= displayHeight*0.9f) {
      // Resize the window to fit in the screen with the correct ratio
      if ( ratio > displayWidth/displayHeight ) {
        sw = (int)(displayWidth*0.8f);
        sh = (int)(sw/ratio);
      } else {
        sh = (int)(displayHeight*0.8f);
        sw = (int)(sh*ratio);
      }
    }
    surface.setSize(sw, sh);
    // Update the people generation to make sure everything's draw correctly
    updateGeneration();
  } else if (sw <300 || sh <300 || sw > 16000 || sh > 16000) {
     println("ERROR : cannot set a window size smaller than 300 or greater than 16000"); 
  }
}


// --------------------------------------
// Save / Load
// --------------------------------------
void saveSettings(){
  saveSettings(defaultSettingsFile);
}

void saveSettings(String file){
  println("Saving to : "+file);
  cp5.saveProperties(file);
}

void loadSettings(){
  loadSettings(defaultSettingsFile);
}

void loadSettings(String file){
  println("Loading from : "+file);
  cp5.loadProperties(file);
}
  
void applySettings(){  
  // Force the textfields callbacks
  List<Textfield> list = cp5.getAll(Textfield.class);
  for(Textfield b:list) {
    b.submit();
  }
}