#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <cmath>
#include <limits>
#include <chrono>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <omp.h>
#include "vect.h"
#include "ray.h"
#include "camera.h"
#include "color.h"
#include "light.h"
#include "source.h"
#include "object.h"
#include "sphere.h"
#include "plane.h"



using namespace std;
using namespace std::chrono;
struct RGBType {
  double r;
  double g;
  double b;
};

void saveBMP (const char *filename, int w, int h, int dpi, RGBType *data) {
  FILE *f;
  int k = w*h;
  int s = 4*k;
  int filesize = 54 + s;

  double factor = 39.375;
  int m = static_cast<int>(factor);

  int ppm = dpi*m;

  unsigned char bmpFileHeader[14] = {'B', 'M', 0,0,0,0, 0,0,0,0, 54,0,0,0};
  unsigned char bmpInfoHeader[40] = {40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,24,0};

  bmpFileHeader[ 2] = (unsigned char)(filesize);
  bmpFileHeader[ 3] = (unsigned char)(filesize>>8);
  bmpFileHeader[ 4] = (unsigned char)(filesize>>16);
  bmpFileHeader[ 5] = (unsigned char)(filesize>>24);

  bmpInfoHeader[ 4] = (unsigned char)(w);
  bmpInfoHeader[ 5] = (unsigned char)(w>>8);
  bmpInfoHeader[ 6] = (unsigned char)(w>>16);
  bmpInfoHeader[ 7] = (unsigned char)(w>>24);

  bmpInfoHeader[ 8] = (unsigned char)(h);
  bmpInfoHeader[ 9] = (unsigned char)(h>>8);
  bmpInfoHeader[10] = (unsigned char)(h>>16);
  bmpInfoHeader[11] = (unsigned char)(h>>24);

  bmpInfoHeader[21] = (unsigned char)(s);
  bmpInfoHeader[22] = (unsigned char)(s>>8);
  bmpInfoHeader[23] = (unsigned char)(s>>16);
  bmpInfoHeader[24] = (unsigned char)(s>>24);

  bmpInfoHeader[25] = (unsigned char)(ppm);
  bmpInfoHeader[26] = (unsigned char)(ppm>>8);
  bmpInfoHeader[27] = (unsigned char)(ppm>>16);
  bmpInfoHeader[28] = (unsigned char)(ppm>>24);

  bmpInfoHeader[29] = (unsigned char)(ppm);
  bmpInfoHeader[20] = (unsigned char)(ppm>>8);
  bmpInfoHeader[31] = (unsigned char)(ppm>>16);
  bmpInfoHeader[32] = (unsigned char)(ppm>>24);

  f = fopen(filename, "wb");

  fwrite(bmpFileHeader,1,14,f);
  fwrite(bmpInfoHeader,1,40,f);

  for(int i=0;i<k;i++){
    RGBType rgb = data[i];

    double red = (rgb.r)*255;
    double green = (rgb.g)*255;
    double blue = (rgb.b)*255;

    unsigned char color[3] = {(int)floor(blue),(int)floor(green),(int)floor(red)};

    fwrite(color,1,3,f);
  }
  fclose(f);
}

int winningObjectIndex(vector<double> object_intersections){
  // return the index of the winning intersections
  int index_of_minimum_value;

  // prevent unnessary calculations
  if(object_intersections.size() == 0){
    // if there is no intersections

    return -1;
  }else if(object_intersections.size()==1){

    if(object_intersections.at(0)>0){
      // if that intersection is greater than zero then its the index of minimum value
      return 0;
    }else{
      return -1;
    }
  }else{
    double max = 0;
    for(int i = 0; i< object_intersections.size();i++){
      if (max<object_intersections.at(i)){
        max = object_intersections.at(i);
      }
    }

    if(max>0){
      for(int i=0;i<object_intersections.size();i++){
        if(object_intersections.at(i)>0 && object_intersections.at(i)<=max){
          max=object_intersections.at(i);
          index_of_minimum_value = i;
        }
      }
      return index_of_minimum_value;
    }else{
      return -1;
    }
  }
}

color getColorAt(vect intersection_position,vect intersecting_ray_direction,vector<object*> scene_objects,int index_of_winning_object,vector<source*> light_sources,double accuracy,double ambientLight,int count){

  color winning_object_color = scene_objects.at(index_of_winning_object)->getColor();
  vect winning_object_normal = scene_objects.at(index_of_winning_object)->getNormalAt(intersection_position);

  if(winning_object_color.getColorSpecial() == 2){
    // checkered/tile floor pattern

    int square = (int) floor(intersection_position.getVectX()) + (int) floor(intersection_position.getVectZ());

    if((square % 2) == 0){
      // black tile
      winning_object_color.setColorRed(0);
      winning_object_color.setColorGreen(0);
      winning_object_color.setColorBlue(0);
    }else{
      winning_object_color.setColorRed(1);
      winning_object_color.setColorGreen(1);
      winning_object_color.setColorBlue(1);
    }
  }

  color final_color = winning_object_color.colorScalar(ambientLight);

  if(winning_object_color.getColorSpecial() > 0 && winning_object_color.getColorSpecial() <= 1 && count<3){
    // reflection from objects with specular intensity
    double dot1 = winning_object_normal.dotProduct(intersecting_ray_direction.negative());
    vect scalar1 = winning_object_normal.vectMul(dot1);
    vect add1 = scalar1.vectAdd(intersecting_ray_direction);
    vect scalar2 = add1.vectMul(2);
    vect add2 = intersecting_ray_direction.negative().vectAdd(scalar2);
    vect reflection_direction = add2.normalize();

    ray reflection_ray (intersection_position, reflection_direction);

    // determine what the ray intersects with first
    vector<double> reflection_intersections;

    for(int reflection_index=0;reflection_index < scene_objects.size(); reflection_index++){
      reflection_intersections.push_back(scene_objects.at(reflection_index)->findIntersection(reflection_ray));
    }

    int index_of_winning_object_with_reflection = winningObjectIndex(reflection_intersections);

    if(index_of_winning_object_with_reflection != -1){
      // reflecion ray didnt intersect with anything
      if(reflection_intersections.at(index_of_winning_object_with_reflection) > accuracy) {

        vect reflection_intersections_position = intersection_position.vectAdd(reflection_direction.vectMul(reflection_intersections.at(index_of_winning_object_with_reflection)));
        vect reflection_intersections_ray_direction = reflection_direction;

        color reflection_intersection_color = getColorAt(reflection_intersections_position, reflection_intersections_ray_direction, scene_objects, index_of_winning_object_with_reflection, light_sources, accuracy, ambientLight,++count);
        final_color = final_color.colorAdd(reflection_intersection_color.colorScalar(winning_object_color.getColorSpecial()));

      }
    }
  }


  for(int light_index = 0; light_index < light_sources.size();light_index++) {
    vect light_direction = light_sources.at(light_index)->getLightPosition().vectAdd(intersection_position.negative()).normalize();


    float cosine_angle = winning_object_normal.dotProduct(light_direction);

    if(cosine_angle > 0) {
      // test for shadows
      bool shadowed = false;

      vect distance_to_light = light_sources.at(light_index)->getLightPosition().vectAdd(intersection_position.negative()).normalize();
      float distance_to_light_magnitude = distance_to_light.magnitude();

      ray shadow_ray (intersection_position, light_direction);

      vector<double> secondary_intersections;

      for(int object_index = 0; object_index < scene_objects.size() && shadowed==false; object_index++){
        secondary_intersections.push_back(scene_objects.at(object_index)->findIntersection(shadow_ray));
      }

      for (int c=0;c<secondary_intersections.size();c++){
        if(secondary_intersections.at(c) > accuracy){
          if(secondary_intersections.at(c) <= distance_to_light_magnitude){
            shadowed=true;
          }
          break;
        }
      }
      if(shadowed == false){
        final_color = final_color.colorAdd(winning_object_color.colorMultiply(light_sources.at(light_index)->getLightColor()).colorScalar(cosine_angle));

        if(winning_object_color.getColorSpecial() > 0 && winning_object_color.getColorSpecial() <=1 ){
          // special 0-1 : shiny
          double dot1=winning_object_normal.dotProduct(intersecting_ray_direction.negative());
          vect scalar1 = winning_object_normal.vectMul(dot1);
          vect add1 = scalar1.vectAdd(intersecting_ray_direction);
          vect scalar2 = add1.vectMul(2);
          vect add2 = intersecting_ray_direction.negative().vectAdd(scalar2);
          vect reflection_direction = add2.normalize();

          double specular = reflection_direction.dotProduct(light_direction);
          if(specular > 0){
            specular = pow(specular, 10);
            final_color = final_color.colorAdd(light_sources.at(light_index)->getLightColor().colorScalar(specular*winning_object_color.getColorSpecial()));
          }
        }
      }
    }
  }
  return final_color.clip();
}

int thisone;

int main(int argc, char *argv[]){
  cout<<"rendering...."<<endl;

  int dpi = 72;
  int width=640;
  int height=480;
  int n = width*height;
  RGBType *pixels = new RGBType[n];

  int aadepth = 1;
  double aathreshold = 0.1;
  double aspectRatio = (double) width/ (double) height;
  double ambientLight = 0.2;
  double accuracy = 0.000001;

  vect O (0,0,0);
  vect X (1,0,0);
  vect Y (0,1,0);
  vect Z (0,0,1);


  vect camPos (3,1.5,-4);
  vect look_at (0,0,0);
  vect diff_btw (camPos.getVectX()-look_at.getVectX(),camPos.getVectY()-look_at.getVectY(),camPos.getVectZ()-look_at.getVectZ());

  vect camDir = diff_btw.negative().normalize();
  vect camRight = Y.crossProduct(camDir).normalize();
  vect camDown = camRight.crossProduct(camDir);
  camera scene_cam (camPos, camDir, camRight, camDown);
    printf("%f \n",scene_cam.getCameraDirection().getVectX());
  color white_light (1.0,1.0,1.0,0);
  color pretty_green (0.5,1.0,0.5,0.3);
  color maroon (0.5,0.25,0.25,0);
  color tileFloor (1,1,1,2);
  color gray (0.5,0.5,0.5,0);
  color black (0.0,0.0,0.0,0);

  vect light_position (-7,10,-10);
  light scene_light (light_position, white_light);
  vector<source*> light_sources;
  light_sources.push_back(dynamic_cast<source*>(&scene_light));


  // scene objects
  sphere scene_sphere (O, 1, pretty_green);
  sphere scene_sphere2 (X.vectMul(1.75), 0.5, maroon);
  plane scene_plane (Y, -1, tileFloor);

  vector<object*> scene_objects;
  scene_objects.push_back(dynamic_cast<object*>(&scene_sphere));
  scene_objects.push_back(dynamic_cast<object*>(&scene_sphere2));
  scene_objects.push_back(dynamic_cast<object*>(&scene_plane));

  int thisone, aa_index;
  double xamnt, yamnt;
  //double tempRed, tempGreen,tempBlue;
  auto start=high_resolution_clock::now();

  for(int x=0; x<width; x++){
    for(int y=0;y<height;y++){
      thisone = y*width + x;

      // start with a black pixel
      double tempRed[aadepth*aadepth];
      double tempGreen[aadepth*aadepth];
      double tempBlue[aadepth*aadepth];



      for(int aax = 0; aax<aadepth;aax++){
        for(int aay = 0; aay<aadepth;aay++){

          aa_index = aay*aadepth + aax;


        //  srand(time(0));
          if(aadepth == 1){
            // no anti-aliasing
            if(width > height) {
              // the image is wider than is tall
              xamnt = ((x+0.5)/width)*aspectRatio - (((width-height)/(double)height)/2);
              yamnt = ((height - y) + 0.5)/height;
            }
            else if(height > width){
              // the image is taller than it is wide
              xamnt = (x + 0.5)/width;
              yamnt = (((height-y)+ 0.5)/height)/aspectRatio - (((height - width)/(double)width)/2);
            }
            else{
              // the image is a square
              xamnt = (x+0.5)/width;
              yamnt = ((height - y) + 0.5)/height;
            }
          }else{
            // anti aliasing
            if(width > height) {
              // the image is wider than is tall
              xamnt = ((x+(double)aax/((double)aadepth - 1))/width)*aspectRatio - (((width-height)/(double)height)/2);
              yamnt = ((height - y) + (double)aax/((double)aadepth - 1))/height;
            }
            else if(height > width){
              // the image is taller than it is wide
              xamnt = (x + (double)aax/((double)aadepth - 1))/width;
              yamnt = (((height-y)+ (double)aax/((double)aadepth - 1))/height)/aspectRatio - (((height - width)/(double)width)/2);
            }
            else{
              // the image is a square
              xamnt = (x+(double)aax/((double)aadepth - 1))/width;
              yamnt = ((height - y) + (double)aax/((double)aadepth - 1))/height;
            }

          }

          vect cam_ray_origin = scene_cam.getCameraPosition();
          vect cam_ray_direction = camDir.vectAdd(camRight.vectMul(xamnt-0.5).vectAdd(camDown.vectMul(yamnt - 0.5))).normalize();

          ray cam_ray (cam_ray_origin, cam_ray_direction);

          vector<double> intersections;

          for(int index = 0; index<scene_objects.size();index++){
            intersections.push_back(scene_objects.at(index)->findIntersection(cam_ray));
          }

          int index_of_winning_object = winningObjectIndex(intersections);

          if(index_of_winning_object==-1){
            tempRed[aa_index] = 0;
            tempGreen[aa_index] = 0;
            tempBlue[aa_index] = 0;
          }else{
            if(intersections.at(index_of_winning_object) > accuracy){
              // determine the position and direction vectors at the point of intersection

              vect intersection_position = cam_ray_origin.vectAdd(cam_ray_direction.vectMul(intersections.at(index_of_winning_object)));
              vect intersecting_ray_direction = cam_ray_direction;


              color intersection_color = getColorAt(intersection_position,intersecting_ray_direction, scene_objects, index_of_winning_object, light_sources, accuracy, ambientLight,0);


              tempRed[aa_index] = intersection_color.getColorRed();
              tempGreen[aa_index] = intersection_color.getColorGreen();
              tempBlue[aa_index] = intersection_color.getColorBlue();
            }
          }

        }
      }

      //average the pixel color
      double totalRed = 0;
      double totalGreen = 0;
      double totalBlue = 0;

      for(int iColor = 0; iColor< aadepth*aadepth;iColor++){
        totalRed = totalRed + tempRed[iColor];
        totalGreen = totalGreen + tempGreen[iColor];
        totalBlue = totalBlue + tempBlue[iColor];
      }
      double avgRed = totalRed/(aadepth*aadepth);
      double avgGreen = totalGreen/(aadepth*aadepth);
      double avgBlue = totalBlue/(aadepth*aadepth);

      pixels[thisone].r =avgRed;
      pixels[thisone].g =avgGreen;
      pixels[thisone].b =avgBlue;

    }
  }

  auto stop=high_resolution_clock::now();

  auto duration=duration_cast<microseconds>(stop-start);
  cout<<duration.count()<<" microseconds"<<endl;

  saveBMP("scene.bmp",width,height,dpi,pixels);

  delete pixels;

  return 0;
}
