#ifndef _SPHERE_H
#define _SPHERE_H

#include "math.h"
#include "object.h"
#include "vect.h"
#include "color.h"

class sphere : public object {
  vect center;
  double radius;
  color color_val;

public:
  sphere();

  sphere(vect, double, color);

  // method functions
  vect getSphereCenter() {return center;}
  double getSphereRadius() {return radius;}
  color getColor() {return color_val;}

  vect getNormalAt(vect point){
    vect normal = point.vectAdd(center.negative()).normalize();
    return normal;
  }

  double findIntersection(ray r){
    vect ray_origin = r.getRayOrigin();
    double ray_origin_x = ray_origin.getVectX();
    double ray_origin_y = ray_origin.getVectY();
    double ray_origin_z = ray_origin.getVectZ();

    vect ray_direction = r.getRayDirection();
    double ray_direction_x = ray_direction.getVectX();
    double ray_direction_y = ray_direction.getVectY();
    double ray_direction_z = ray_direction.getVectZ();

    double sphere_center_x = center.getVectX();
    double sphere_center_y = center.getVectY();
    double sphere_center_z = center.getVectZ();

    double a = 1; // normalized
    double b = (2*(ray_origin_x - sphere_center_x)*ray_direction_x) + (2*(ray_origin_y - sphere_center_y)*ray_direction_y) + (2*(ray_origin_z - sphere_center_z)*ray_direction_z);
    double c = pow(ray_origin_x - sphere_center_x, 2) + pow(ray_origin_y - sphere_center_y, 2) + pow(ray_origin_z - sphere_center_z, 2) - (radius*radius);

    double discriminant = b*b - 4*a*c;

    if(discriminant > 0){
      // the ray intersects the sphere

      //the first cross
      double root_1 = ((-1*b - sqrt(discriminant))/(2*a)) - 0.0000001;

      if(root_1 > 0){
        // the first root is smalllest positive root
        return root_1;
      }else{
        // the second root is the smallest positive root
        double root_2 = ((sqrt(discriminant)-b)/(2*a)) - 0.0000001;
        return root_2;
      }
    }else{
      // the ray missed the sphere
      return -1;
    }


  }

};

sphere::sphere() {
  center = vect(0,0,0);
  radius = 1.0;
  color_val = color(0.5,0.5,0.5,0);
}
sphere::sphere(vect c,double r, color col) {
  center = c;
  radius = r;
  color_val = col;
}

#endif
