#ifndef _OBJECT_H
#define _OBJECT_H

#include "ray.h"
#include "vect.h"
#include "color.h"

class object {
public:
  object();
  // method functions
  virtual color getColor() {return color (0,0,0,0);}

  virtual double findIntersection(ray r){
    return 0;
  }

  virtual vect getNormalAt(vect point) {
    return vect(0,0,0);
  }
};

object::object() {}

#endif
