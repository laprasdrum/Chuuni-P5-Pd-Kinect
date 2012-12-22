import oscP5.*;
import netP5.*;
import SimpleOpenNI.*;

OscP5 oscP5;
NetAddress oscDestination;
SimpleOpenNI skeleton;

float thresholdRadius;
PVector thresholdCenter;

void setup()
{
  size(1680, 1050);
  frameRate(29);
  
  // set threshold according to application screen size
  thresholdRadius = width<height ? width/4 : height/4;
  thresholdCenter = new PVector(width/2, height/2);

  // oscP5 setting
  oscP5 = new OscP5(this, 10001);
  oscDestination = new NetAddress("127.0.0.1", 10001);

  // kinect setting
  skeleton = new SimpleOpenNI(this);
  skeleton.enableDepth();
  skeleton.enableRGB();
  skeleton.alternativeViewPointDepthToImage();
  skeleton.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
  skeleton.setMirror(true);
}

void draw()
{
  background(0);

  // get right hand position
  skeleton.update();
  if(skeleton.getNumberOfUsers() < 1 || skeleton.isTrackingSkeleton(1) == false){
     println("kinect cannot get a user");
     return;
  }
  PVector rightHand = getRightHandPosition();
  
  // calculate distance from center to right hand position
  PVector locationFromCenter = new PVector(rightHand.x-thresholdCenter.x, rightHand.y-thresholdCenter.y);
  float distance = sqrt(pow(locationFromCenter.x, 2)+pow(locationFromCenter.y, 2));

  // right hand position
  ellipseMode(CENTER);
  if (distance>thresholdRadius) fill(255);
  else fill(255, 0, 0);
  ellipse(rightHand.x, rightHand.y, 30, 30);

  // sound visualization
  drawLines(velocityValue(distance));

  // send osc message with velocity value
  OscMessage messageForPd = new OscMessage("/p5/soundValue");
  messageForPd.add(velocityValue(distance));
  oscP5.send(messageForPd, oscDestination);
}

/**
 * calculate velocity based on current mouse location.
 * the closer mouse pointer is to the center of application screen, the bigger velocity is.
 *
 * @return rightHandVector (x,y) coordination of a user's right hand got from kinect  
 */
PVector getRightHandPosition()
{
  PVector rightHandVector = new PVector();
  
  // get real position
  PVector realPosition = new PVector();
  skeleton.getJointPositionSkeleton(1, SimpleOpenNI.SKEL_RIGHT_HAND, realPosition);
  
  // convert from real position to screen position
  skeleton.convertRealWorldToProjective(realPosition, rightHandVector);
  rightHandVector.x *= width/skeleton.rgbWidth();
  rightHandVector.y *= height/skeleton.rgbHeight();
  return rightHandVector;
}

/**
 * calculate velocity based on current mouse location.
 * the closer mouse pointer is to the center of application screen, the bigger velocity is.
 *
 * @param radius distance from center to mouse location
 * @return velocity velocity value 
 */
float velocityValue(float radius)
{
  float maxVelocityValue = 127;
  float minVelocityValue = 0;
  float slope = -maxVelocityValue/thresholdRadius;

  // calculate velocity (intercept = maxVelocityValue)
  float velocity = slope*radius + maxVelocityValue;

  if (velocity < minVelocityValue) 
    velocity = minVelocityValue;
  else if (velocity > maxVelocityValue) 
    velocity = maxVelocityValue;

  return velocity;
}

/**
 * draw vertical lines.
 * the number of lines are based on velocity value
 *
 * @param velocity velocity value 
 */
void drawLines(float velocity)
{
  float linesNumber = velocity*3/2;
  float radian = PI/2*0.99;

  stroke(255);

  for (int i = 0; i<linesNumber; i++) {
    float x1 = random(width);
    float slope = pow(-1, i)*tan(radian);
    float x2 = height/slope+x1;

    line(x1, 0, x2, height);
  }
}

// SimpleOpenNI event
void onNewUser(int userId)
{
  skeleton.startTrackingSkeleton(userId);
}

boolean sketchFullScreen() {
  return true;
}
