import augmentaP5.*;

class TestPerson {
  AugmentaPerson p;
  float oldX, oldY;
  float xDirection;
  float yDirection;
  float speed = 0.002;
  float drawingRadius = 10;
  
  // Contructor
  TestPerson(float x, float y) {
    // Setup the augmenta person
    int pid = int(random(101,10000000)); // avoid collision with generated points
    float size = 0.1f;
    RectangleF rect = new RectangleF(x-size/2, y-size/2, size, size);
    PVector pos = new PVector(x,y);
    p = new AugmentaPerson(pid, pos, rect);
    p.highest.x = x + random(-0.02, 0.02);
    p.highest.y = y + random(-0.02, 0.02);
    p.highest.z = random(0.4, 0.6);
    // Compute direction
    float angle = random(0,6.28); // radians angle
    yDirection = speed * sin(angle);
    xDirection = speed * cos(angle);
  }
  
  // Custom method for updating the variables
  void update() {
    float x,y;
    x = p.centroid.x;
    y = p.centroid.y;
    // Store the oldX oldY values
    oldX = x;
    oldY = y;
    
    // Compute the new values
    x = x + xDirection;
    y = y + yDirection;
    
    if (x >= (1-p.boundingRect.width/2) || x <= p.boundingRect.width/2) {
      xDirection *= -1;
      x = x + (2 * xDirection);
    }
    if (y >= (1-p.boundingRect.height/2) || y <= p.boundingRect.height/2) {
      yDirection *= -1;
      y = y + (2 * yDirection);
    }
    // Compute the velocity
    p.velocity.x = (x - oldX);
    p.velocity.y = (y - oldY);
    // Update augmenta
    p.depth = 0.5f;
    p.centroid.x = x;
    p.centroid.y = y;
    p.boundingRect.x = p.centroid.x - p.boundingRect.width/2;
    p.boundingRect.y = p.centroid.y - p.boundingRect.height/2;
    p.highest.x = p.highest.x + p.velocity.x;
    p.highest.y = p.highest.y + p.velocity.y;
    p.age++;
  }
  
  void send(AugmentaP5 augmenta, NetAddress a){
     augmenta.sendSimulation(p, a);
  }
  void send(AugmentaP5 augmenta, NetAddress a, String s){
     augmenta.sendSimulation(p, a, s);
  }
    
  // Custom method for drawing the object
  void draw() {
    ellipse(p.centroid.x*(float)width, p.centroid.y*(float)height, drawingRadius*2, drawingRadius*2);
  }
}