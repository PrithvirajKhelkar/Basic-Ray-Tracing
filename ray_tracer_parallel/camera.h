#ifndef _CAMERA_H
#define _CAMERA_H

#include "vect.h"

class camera {
  vect camPos, camDir, camRight, camDown;

public:
  __host__ __device__ camera(){
      camPos = vect(0,0,0);
      camDir = vect(0,0,1);
      camRight = vect(0,0,0);
      camDown = vect(0,0,0);
  }

  __host__ __device__ camera(vect pos, vect dir, vect right, vect down){
      camPos = pos;
      camDir = dir;
      camRight = right;
      camDown = down;
  }
  __host__ __device__ ~camera(){}
  // method functions
  __host__ __device__ vect getCameraPosition() {return camPos;}
  __host__ __device__ vect getCameraDirection() {return camDir;}
  __host__ __device__ vect getCameraRight() {return camRight;}
  __host__ __device__ vect getCameraDown() {return camDown;}

};

// __device__ camera::camera() {
//   camPos = vect(0,0,0);
//   camDir = vect(0,0,1);
//   camRight = vect(0,0,0);
//   camDown = vect(0,0,0);
// }
// __device__ camera::camera(vect pos, vect dir, vect right, vect down) {
//   camPos = pos;
//   camDir = dir;
//   camRight = right;
//   camDown = down;
// }

#endif
