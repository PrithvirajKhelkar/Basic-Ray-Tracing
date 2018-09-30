#ifndef _PLANE_H
#define _PLANE_H

#include "math.h"
#include "vect.h"
#include "color.h"

class plane{
  vect normal;
  double distance;
  color color_val;

public:
  __host__ __device__ plane(){
    normal = vect(1,0,0);
    distance = 0;
    color_val = color(0.5,0.5,0.5,0);
  }

  __host__ __device__ plane(vect n, double d, color col){
    normal = n;
    distance = d;
    color_val = col;
  }

  // method functions
   __host__ __device__ vect getPlaneNormal() {return normal;}
   __host__ __device__ double getPlaneDistance() {return distance;}
   __host__ __device__ color getColor() {return color_val;}

   __host__ __device__ vect getNormalAt(vect point) {
    return normal;
  }

   __host__ __device__ double findIntersection(ray r) {
    vect ray_direction = r.getRayDirection();

    double a = ray_direction.dotProduct(normal);

    if(a == 0) {
      // ray is parallel to the plane
      return -1;
    }else{
      double b = normal.dotProduct(r.getRayOrigin().vectAdd(normal.vectMul(distance).negative()));
      return -1*b/a;
    }
  }

};

// plane::plane() {
//   normal = vect(1,0,0);
//   distance = 0;
//   color_val = color(0.5,0.5,0.5,0);
// }
// plane::plane(vect n,double d, color col) {
//   normal = n;
//   distance = d;
//   color_val = col;
// }

#endif
