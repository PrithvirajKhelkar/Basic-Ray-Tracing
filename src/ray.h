#ifndef _RAY_H
#define _RAY_H

#include "vect.h"

class ray {
  vect origin, direction;

public:
  __host__ __device__ ray(){
    origin = vect(0,0,0);
    direction = vect(1,0,0);
  }

  __host__ __device__ ray(vect o, vect d){
    origin = o;
    direction = d;
  }

__host__ __device__ ~ray(){}
  // method functions
  __device__ vect getRayOrigin() {return origin;}
  __device__ vect getRayDirection() {return direction;}

};

// ray::ray() {
//   origin = vect(0,0,0);
//   direction = vect(1,0,0);
// }
// ray::ray(vect o, vect d) {
//   origin = o;
//   direction = d;
// }

#endif
