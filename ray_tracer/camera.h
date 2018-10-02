#ifndef _CAMERA_H
#define _CAMERA_H

#include "vect.h"

class camera {
  vect camPos, camDir, camRight, camDown;

public:
  camera();

  camera(vect, vect, vect, vect);

  // method functions
  inline vect getCameraPosition() {return camPos;}
  inline vect getCameraDirection() {return camDir;}
  inline vect getCameraRight() {return camRight;}
  inline vect getCameraDown() {return camDown;}

};

camera::camera() {
  camPos = vect(0,0,0);
  camDir = vect(0,0,1);
  camRight = vect(0,0,0);
  camDown = vect(0,0,0);
}
camera::camera(vect pos, vect dir, vect right, vect down) {
  camPos = pos;
  camDir = dir;
  camRight = right;
  camDown = down;
}

#endif
