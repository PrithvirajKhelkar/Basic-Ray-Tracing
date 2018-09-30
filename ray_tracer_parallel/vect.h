#ifndef _VECT_H
#define _VECT_H

#include "math.h"

class vect {
  double x, y, z;

public:
  __host__ __device__ vect(){
    x=0;
    y=0;
    z=0;
  }

  __host__ __device__ vect(double i, double j, double k){
    x=i;
    y=j;
    z=k;
  }

  // method functions
  __host__ __device__ double getVectX() {return x;}
  __host__ __device__ double getVectY() {return y;}
  __host__ __device__ double getVectZ() {return z;}

  __host__ __device__ double magnitude() {
    return sqrt((x*x) + (y*y) + (z*z));
  }

  __host__ __device__ vect normalize() {
    double magnitude = sqrt((x*x) + (y*y) + (z*z));
    return vect(x/magnitude,y/magnitude,z/magnitude);
  }

  __host__ __device__ vect negative() {
    return vect(-x,-y,-z);
  }

  __host__ __device__ double dotProduct(vect v){
    return x*v.getVectX() + y*v.getVectY() +z*v.getVectZ();
  }

  __host__ __device__ vect crossProduct(vect v){
    return vect(y*v.getVectZ() - z*v.getVectY(), z*v.getVectX() - x*v.getVectZ(), x*v.getVectY() - y*v.getVectX());
  }

  __host__ __device__ vect vectAdd(vect v){
    return vect(x+v.getVectX(), y+v.getVectY(), z+v.getVectZ());
  }

  __host__ __device__ vect vectMul(double scalar){
    return vect(x*scalar, y*scalar, z*scalar);
  }


};

// vect::vect() {
//   x=0;
//   y=0;
//   z=0;
// }
// vect::vect(double i, double j, double k) {
//   x=i;
//   y=j;
//   z=k;
// }

#endif
