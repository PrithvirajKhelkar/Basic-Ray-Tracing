#ifndef _PLANE_H
#define _PLANE_H

#include "math.h"
#include "object.h"
#include "vect.h"
#include "color.h"

class plane : public object {
  vect normal;
  double distance;
  color color_val;

public:
  plane();

  plane(vect, double, color);

  // method functions
  vect getPlaneNormal() {return normal;}
  double getPlaneDistance() {return distance;}
  color getColor() {return color_val;}

  vect getNormalAt(vect point) {
    return normal;
  }

  double findIntersection(ray r) {
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

plane::plane() {
  normal = vect(1,0,0);
  distance = 0;
  color_val = color(0.5,0.5,0.5,0);
}
plane::plane(vect n,double d, color col) {
  normal = n;
  distance = d;
  color_val = col;
}

#endif
