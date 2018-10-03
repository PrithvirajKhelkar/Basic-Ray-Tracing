#ifndef _LIGHT_H
#define _LIGHT_H

#include "vect.h"
#include "color.h"

class light {
  vect position;
  color color_val;

public:
  __host__ __device__ light(){
      position = vect(0,0,0);
      color_val = color(1,1,1,0);
  }

  __host__ __device__ light(vect p, color c){
      position = p;
      color_val = c;
  }
__host__ __device__ ~light(){}
  // method functions
  __host__ __device__ vect getLightPosition() {return position;}
  __host__ __device__ color getLightColor() {return color_val;}

};

// light::light() {
//   position = vect(0,0,0);
//   color_val = color(1,1,1,0);
// }
// light::light(vect p, color c) {
//   position = p;
//   color_val = c;
// }

#endif
