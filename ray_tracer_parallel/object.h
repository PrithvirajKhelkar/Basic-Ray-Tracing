#ifndef _OBJECT_H
#define _OBJECT_H

#include "ray.h"
#include "vect.h"
#include "color.h"

class object {
public:
  __host__ __device__ object(){}
  // method functions
  inline __host__ __device__  color getColor() {return color (0.5,0,0,0);}

  __host__ __device__  double findIntersection(ray r){
    return 0;
  }

  __host__ __device__  vect getNormalAt(vect point) {
    return vect(0,0,0);
  }
};

// object::object() {}

#endif
