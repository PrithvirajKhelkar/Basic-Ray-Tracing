#ifndef _LIGHT_H
#define _LIGHT_H

#include "source.h"
#include "vect.h"
#include "color.h"

class light : public source {
  vect position;
  color color_val;

public:
  light();

  light(vect, color);

  // method functions
  inline vect getLightPosition() {return position;}
  inline color getLightColor() {return color_val;}

};

light::light() {
  position = vect(0,0,0);
  color_val = color(1,1,1,0);
}
light::light(vect p, color c) {
  position = p;
  color_val = c;
}

#endif
