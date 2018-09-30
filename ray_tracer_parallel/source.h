#ifndef _SOURCE_H
#define _SOURCE_H

class source {
public:
  __host__ __device__ source(){}

  __host__ __device__ virtual vect getLightPosition(){return vect(0,0,0);}
  __host__ __device__ virtual color getLightColor(){return color(1,1,1,0);}
};

//source::source(){}

#endif
