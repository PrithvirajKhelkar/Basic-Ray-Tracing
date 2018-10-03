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
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "vect.h"
#include "ray.h"
#include "camera.h"
#include "color.h"
#include "light.h"
#include "sphere.h"
#include "plane.h"
#include <stdio.h>
#include <stdlib.h>
#define cudaCheckErrors(msg) \
  do { \
    cudaError_t __err = cudaPeekAtLastError(); \
    if (__err != cudaSuccess) { \
      fprintf(stderr, "Fatal error: %s (%s at %s:%d)\n", \
          msg, cudaGetErrorString(__err), \
          __FILE__, __LINE__); \
      fprintf(stderr, "*** FAILED - ABORTING\n"); \
      return 0; \
    } \
  } while (0)



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



__device__ color getColorAt(int type,vect intersection_position,vect intersecting_ray_direction,sphere *scene_spheres,int sphere_count,plane *scene_planes,int plane_count,int index_of_winning_sphere, int index_of_winning_plane,light *light_sources,int total_sources,double accuracy,double ambientLight,int count){

                                        // stop here
 int object_type=type;
  color winning_object_color;
  vect winning_object_normal;
    // 0:sphere   ; 1:plane
  sphere winning_sphere;
  plane winning_plane;
    color final_color;
    vect final_normal;
    count = 0;

    if(object_type==0){
      winning_sphere=scene_spheres[index_of_winning_sphere];
      winning_object_color = winning_sphere.getColor();
      winning_object_normal = winning_sphere.getNormalAt(intersection_position);

    }else if(object_type==1){
      winning_plane=scene_planes[index_of_winning_plane];
      winning_object_color = winning_plane.getColor();
      winning_object_normal = winning_plane.getNormalAt(intersection_position);

    }


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



    final_color = winning_object_color.colorScalar(ambientLight);
    // stack[stack_index]=final_color;
    // stack_index++;

    if(count < 5 && winning_object_color.getColorSpecial() > 0 && winning_object_color.getColorSpecial() <= 1){
      // reflection from objects with specular intensity
      double dot1 = winning_object_normal.dotProduct(intersecting_ray_direction.negative());
      vect scalar1 = winning_object_normal.vectMul(dot1);
      vect add1 = scalar1.vectAdd(intersecting_ray_direction);
      vect scalar2 = add1.vectMul(2);
      vect add2 = intersecting_ray_direction.negative().vectAdd(scalar2);
      vect reflection_direction = add2.normalize();

      ray reflection_ray (intersection_position, reflection_direction);

      // determine what the ray intersects with first
      int reflection_intersections_sphere_index=0;
      sphere temp_sphere;
      int index_of_winning_sphere_with_reflection=-1;double winning_sphere_value=99999,temp_dist;
      for(;reflection_intersections_sphere_index < sphere_count; reflection_intersections_sphere_index++){
        temp_sphere=scene_spheres[reflection_intersections_sphere_index];
        temp_dist=temp_sphere.findIntersection(reflection_ray);
        if(temp_dist<winning_sphere_value && temp_dist>0){
          winning_sphere_value=temp_dist;
          index_of_winning_sphere_with_reflection=reflection_intersections_sphere_index;
        }
      }


      int reflection_intersections_plane_index=0;
      plane temp_plane;
      int index_of_winning_plane_with_reflection=-1;
      double winning_plane_value=99999;
      for(;reflection_intersections_plane_index < plane_count; reflection_intersections_plane_index++){
        temp_plane=scene_planes[reflection_intersections_plane_index];
        temp_dist=temp_plane.findIntersection(reflection_ray);
        if(temp_dist<winning_plane_value && temp_dist>0){
          winning_plane_value=temp_dist;
          index_of_winning_plane_with_reflection=reflection_intersections_plane_index;
        }
      }

      //int index_of_winning_sphere_with_reflection = winningObjectIndex(reflection_intersections_sphere,reflection_intersections_sphere_index);
      //int index_of_winning_plane_with_reflection = winningObjectIndex(reflection_intersections_plane,reflection_intersections_plane_index);

      //double winning_sphere_value = reflection_intersections_sphere[index_of_winning_sphere_with_reflection];
      //double winning_plane_value = reflection_intersections_plane[index_of_winning_plane_with_reflection];

      if(index_of_winning_sphere_with_reflection != -1 && index_of_winning_plane_with_reflection == -1){
        if(winning_sphere_value > accuracy) {

          vect reflection_intersection_position = intersection_position.vectAdd(reflection_direction.vectMul(winning_sphere_value));


            color reflection_intersection_color = getColorAt(0,reflection_intersection_position, reflection_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere_with_reflection,index_of_winning_plane_with_reflection, light_sources,total_sources, accuracy, ambientLight, count++);

        //  object_type=0;


          // index_of_winning_sphere=index_of_winning_sphere_with_reflection;
          // index_of_winning_plane=index_of_winning_plane_with_reflection;
          // stack_index++;
          // stack[stack_index]=final_color;
          // vect_stack[stack_index]=final_normal;
          // count++;
          // continue;
         final_color = final_color.colorAdd(reflection_intersection_color.colorScalar(winning_object_color.getColorSpecial()));

        }
      }else if(index_of_winning_sphere_with_reflection == -1 && index_of_winning_plane_with_reflection != -1){
        if(winning_plane_value > accuracy) {

        vect reflection_intersection_position = intersection_position.vectAdd(reflection_direction.vectMul(winning_plane_value));


          color reflection_intersection_color = getColorAt(1,reflection_intersection_position, reflection_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere_with_reflection,index_of_winning_plane_with_reflection, light_sources,total_sources, accuracy, ambientLight, count++);

          // object_type=1;
          //
          //
          // index_of_winning_sphere=index_of_winning_sphere_with_reflection;
          // index_of_winning_plane=index_of_winning_plane_with_reflection;
          // stack_index++;
          // stack[stack_index]=final_color;
          // vect_stack[stack_index]=final_normal;
          // count++;
          // continue;

          final_color = final_color.colorAdd(reflection_intersection_color.colorScalar(winning_object_color.getColorSpecial()));

        }
      }else if(index_of_winning_sphere_with_reflection != -1 && index_of_winning_plane_with_reflection != -1){
        if(winning_sphere_value < winning_plane_value){
          if(winning_sphere_value > accuracy) {

          vect   reflection_intersections_position = intersection_position.vectAdd(reflection_direction.vectMul(winning_sphere_value));


            color reflection_intersection_color = getColorAt(0,reflection_intersections_position, reflection_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere_with_reflection,index_of_winning_plane_with_reflection, light_sources,total_sources, accuracy, ambientLight, count++);

            object_type=0;


            // index_of_winning_sphere=index_of_winning_sphere_with_reflection;
            // index_of_winning_plane=index_of_winning_plane_with_reflection;
            // stack_index++;
            // stack[stack_index]=final_color;
            // vect_stack[stack_index]=final_normal;
            // count++;
            // continue;

            final_color = final_color.colorAdd(reflection_intersection_color.colorScalar(winning_object_color.getColorSpecial()));

          }
        }else{
          if(winning_plane_value > accuracy) {

        vect   reflection_intersections_position = intersection_position.vectAdd(reflection_direction.vectMul(winning_plane_value));

            color reflection_intersection_color = getColorAt(1,reflection_intersections_position, reflection_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere_with_reflection,index_of_winning_plane_with_reflection, light_sources,total_sources, accuracy, ambientLight, count++);

          // object_type=1;
          //
          //
          // index_of_winning_sphere=index_of_winning_sphere_with_reflection;
          // index_of_winning_plane=index_of_winning_plane_with_reflection;
          // stack_index++;
          // stack[stack_index]=winning_object_color;
          // vect_stack[stack_index]=final_normal;
          // count++;
          // continue;

            final_color = final_color.colorAdd(reflection_intersection_color.colorScalar(winning_object_color.getColorSpecial()));

          }
      }
    }
  }


  light light_source;





    for(int light_index = 0; light_index < total_sources;light_index++) {
      light_source=light_sources[light_index];
      vect light_direction = light_source.getLightPosition().vectAdd(intersection_position.negative()).normalize();


      float cosine_angle = winning_object_normal.dotProduct(light_direction);

      if(cosine_angle > 0) {
        // test for shadows
        bool shadowed = false;

        vect distance_to_light = light_source.getLightPosition().vectAdd(intersection_position.negative()).normalize();
        float distance_to_light_magnitude = distance_to_light.magnitude();

        ray shadow_ray (intersection_position, light_direction);



        int index=0;
        sphere temp_sphere;double temp_dist;
        for(; index < sphere_count && shadowed==false; index++){
          temp_sphere=scene_spheres[index];
          temp_dist=temp_sphere.findIntersection(shadow_ray);
          if(temp_dist > accuracy && temp_dist >0 && temp_dist <=distance_to_light_magnitude)
            shadowed=true;
        }


        plane temp_plane;
        for(index=0; index < plane_count && shadowed==false; index++){
          temp_plane=scene_planes[index];
          temp_dist=temp_plane.findIntersection(shadow_ray);
          if(temp_dist > accuracy && temp_dist >0 && temp_dist <=distance_to_light_magnitude)
            shadowed=true;
        }

        if(shadowed == false){

          final_color = final_color.colorAdd(winning_object_color.colorMultiply(light_source.getLightColor()).colorScalar(cosine_angle));

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
              final_color = final_color.colorAdd(light_source.getLightColor().colorScalar(specular*winning_object_color.getColorSpecial()));
            }
          }
        }
      }
    }                                        //TODO fix the lighting loop


  //  final_color = final_color.colorAdd(top_of_stack.colorScalar(ambientLight).colorScalar(top_of_stack.getColorSpecial()));





  //printf("%f %f %f \n",final.getColorRed(),final.getColorGreen(),final.getColorBlue());

  return final_color.clip();
}

__device__ color computeColor(int N,int x,int y,int aadepth,double aathreshold,int width,int height,double aspectRatio,double accuracy,double ambientLight,int total_objects,sphere *scene_spheres,int sphere_count,plane *scene_planes,int plane_count,light *light_sources,int total_sources, camera scene_cam){

  // x=thisone%width;
  // y=lroundf(thisone/width);

  double xamnt,yamnt;

  //  int x,y;
  vect camPos=scene_cam.getCameraPosition();
  vect camDir=scene_cam.getCameraDirection();
  vect camDown=scene_cam.getCameraDown();
  vect camRight=scene_cam.getCameraRight();


  // start with a black pixel
  int aadepth2=aadepth*aadepth;
  double tempRed=0;//=new double[1];
  double tempGreen=0;//=new double[1];
  double tempBlue=0;//=new double[1];



  for(int aax = 0; aax<aadepth;aax++){
    for(int aay = 0; aay<aadepth;aay++){





      if(aadepth == 1){
        // no anti-aliasing
        if(width > height) {
          // the color is wider than is tall
          xamnt = ((x+0.5)/width)*aspectRatio - (((width-height)/(double)height)/2);
          yamnt = ((height - y) + 0.5)/height;
        }
        else if(height > width){
          // the color is taller than it is wide
          xamnt = (x + 0.5)/width;
          yamnt = (((height-y)+ 0.5)/height)/aspectRatio - (((height - width)/(double)width)/2);
        }
        else{
          // the color is a square
          xamnt = (x+0.5)/width;
          yamnt = ((height - y) + 0.5)/height;
        }
      }else{
        // anti aliasing
        if(width > height) {
          // the color is wider than is tall
          xamnt = ((x+(double)aax/((double)aadepth - 1))/width)*aspectRatio - (((width-height)/(double)height)/2);
          yamnt = ((height - y) + (double)aax/((double)aadepth - 1))/height;
        }
        else if(height > width){
          // the color is taller than it is wide
          xamnt = (x + (double)aax/((double)aadepth - 1))/width;
          yamnt = (((height-y)+ (double)aax/((double)aadepth - 1))/height)/aspectRatio - (((height - width)/(double)width)/2);
        }
        else{
          // the color is a square
          xamnt = (x+(double)aax/((double)aadepth - 1))/width;
          yamnt = ((height - y) + (double)aax/((double)aadepth - 1))/height;
        }

      }


      vect cam_ray_origin = scene_cam.getCameraPosition();
      vect cam_ray_direction = camDir.vectAdd(camRight.vectMul(xamnt-0.5).vectAdd(camDown.vectMul(yamnt - 0.5))).normalize();

      ray cam_ray (cam_ray_origin, cam_ray_direction);
      int intersection_sphere_index=0;
  //    double *intersections_sphere=new double[sphere_count];

        sphere temp_sphere;

      int index_of_winning_sphere=-1;double sphere_intersection=99999,temp_dist;

      for(; intersection_sphere_index<sphere_count;intersection_sphere_index++){
          temp_sphere=scene_spheres[intersection_sphere_index];
          temp_dist=temp_sphere.findIntersection(cam_ray);
        if(temp_dist<sphere_intersection && temp_dist>0){
          sphere_intersection=temp_dist;
          index_of_winning_sphere=intersection_sphere_index;
        }
      }



      int intersection_plane_index=0;
  //    double* intersections_plane=new double[plane_count];
      plane temp_plane;

        int index_of_winning_plane=-1;double plane_intersection=99999;

      for(; intersection_plane_index<plane_count;intersection_plane_index++){
        temp_plane=scene_planes[intersection_plane_index];
        temp_dist=temp_plane.findIntersection(cam_ray);
        if(temp_dist<plane_intersection && temp_dist>0){
          plane_intersection=temp_dist;
          index_of_winning_plane=intersection_plane_index;
        }
      }

    //  int index_of_winning_sphere = winningObjectIndex(intersections_sphere,intersection_sphere_index);
    //  int index_of_winning_plane = winningObjectIndex(intersections_plane,intersection_plane_index);


  //    double sphere_intersection = intersections_sphere[index_of_winning_sphere];
  //  double plane_intersection = intersections_plane[index_of_winning_plane];

      if(index_of_winning_sphere==-1 && index_of_winning_plane==-1){

        tempRed+= 0;
        tempGreen+= 0;
        tempBlue+= 0;

      }else if( index_of_winning_sphere!=-1 && index_of_winning_plane==-1){

        if(sphere_intersection > accuracy){
          // determine the position and direction vectors at the point of intersection

          vect intersection_position = cam_ray_origin.vectAdd(cam_ray_direction.vectMul(sphere_intersection));
        //  vect intersecting_ray_direction = cam_ray_direction;


          color intersection_color = getColorAt(0,intersection_position,cam_ray_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere,index_of_winning_plane, light_sources,total_sources, accuracy, ambientLight,0);
          //temp_sphere=scene_spheres[index_of_winning_sphere];
          //color intersection_color=temp_sphere.getColor();


          tempRed+= intersection_color.getColorRed();
          tempGreen+= intersection_color.getColorGreen();
          tempBlue+= intersection_color.getColorBlue();
        }
      }else if(index_of_winning_sphere==-1 && index_of_winning_plane!=-1){

        if(plane_intersection > accuracy){
          // determine the position and direction vectors at the point of intersection

          vect intersection_position = cam_ray_origin.vectAdd(cam_ray_direction.vectMul(plane_intersection));
        //  vect intersecting_ray_direction = cam_ray_direction;

          //return color(0.4,0.2,1.0,1);
          color intersection_color = getColorAt(1,intersection_position,cam_ray_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere,index_of_winning_plane, light_sources,total_sources, accuracy, ambientLight,0);
          //temp_plane=scene_planes[index_of_winning_plane];
        //  color intersection_color=temp_plane.getColor();
            //printf("%f %f %f\n",temp.getColor().getColorRed(),temp.getColor().getColorGreen(),temp.getColor().getColorBlue());

          tempRed+= intersection_color.getColorRed();
          tempGreen+= intersection_color.getColorGreen();
          tempBlue+= intersection_color.getColorBlue();
        }
      }else if(index_of_winning_sphere!=-1 && index_of_winning_plane!=-1){

          if(sphere_intersection<plane_intersection){
            if(sphere_intersection > accuracy){
              // determine the position and direction vectors at the point of intersection

             vect intersection_position = cam_ray_origin.vectAdd(cam_ray_direction.vectMul(sphere_intersection));
              //vect intersecting_ray_direction = cam_ray_direction;
              //return color(0.4,0.2,1.0,1);

              color intersection_color = getColorAt(0,intersection_position,cam_ray_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere,index_of_winning_plane, light_sources,total_sources, accuracy, ambientLight,1);
              //temp_sphere=scene_spheres[index_of_winning_sphere];
            //  color intersection_color=temp_sphere.getColor();


              tempRed+= intersection_color.getColorRed();
              tempGreen+= intersection_color.getColorGreen();
              tempBlue+= intersection_color.getColorBlue();
            }

          }else{
              if(plane_intersection > accuracy){
                // determine the position and direction vectors at the point of intersection

                vect intersection_position = cam_ray_origin.vectAdd(cam_ray_direction.vectMul(plane_intersection));
                //vect intersecting_ray_direction = cam_ray_direction;

          //      return color(0.4,0.2,1.0,1);
                color intersection_color = getColorAt(1,intersection_position,cam_ray_direction, scene_spheres,sphere_count,scene_planes,plane_count, index_of_winning_sphere,index_of_winning_plane, light_sources,total_sources, accuracy, ambientLight,0);
                //temp_plane=scene_planes[index_of_winning_plane];
                //color intersection_color=temp_plane.getColor();


                tempRed+= intersection_color.getColorRed();
                tempGreen+= intersection_color.getColorGreen();
                tempBlue+= intersection_color.getColorBlue();

              }
          }
      }
    }

  }


  double avgRed = tempRed/(aadepth2);
  double avgGreen = tempGreen/(aadepth2);
  double avgBlue = tempBlue/(aadepth2);
  //
  // pixels[thisone].r =avgRed;
  // pixels[thisone].g =avgGreen;
  // pixels[thisone].b =avgBlue;

  color temp (avgRed,avgGreen,avgBlue,0);

  return temp;
  // __syncthreads();

}
__global__ void render(RGBType *d_pixels,int N,int aadepth,double aathreshold,int width,int height,double aspectRatio,double accuracy,double ambientLight,int total_objects,sphere *scene_spheres,int sphere_count,plane *scene_planes,int plane_count,light *light_sources,int total_sources, camera scene_cam){


//       sphere test = scene_spheres[1];
// //      color test1=test.getColor();
//       printf("%f %f %f\n",test.getColor().getColorRed(),test.getColor().getColorGreen(),test.getColor().getColorBlue());

      int x = (blockIdx.x*blockDim.x) + threadIdx.x;
      int y = (blockIdx.y*blockDim.y) + threadIdx.y;
      int thisone = y*width + x;

    //  printf("gridDim.x:%d; gridDim.y:%d; BlockIdx.x:%d; blockIdx.y:%d; blockDim.x:%d; blockDim.y:%d; threadIdx.x:%d; threadIdx.y:%d; x:%d; y:%d; thisone:%d \n",gridDim.x,gridDim.y,blockIdx.x,blockIdx.y,blockDim.x,blockDim.y,threadIdx.x,threadIdx.y,x,y,thisone);
  //    int stride = blockDim.x*gridDim.x;

      //for(int thisone = index; thisone < N; thisone+=stride){
      if(thisone < N){
        color temp;
       temp=computeColor(N,x,y,aadepth,aathreshold,width,height,aspectRatio,accuracy,ambientLight,total_objects,scene_spheres,sphere_count,scene_planes,plane_count,light_sources,total_sources, scene_cam);
        d_pixels[thisone].r=temp.getColorRed();
        d_pixels[thisone].g=temp.getColorGreen();
        d_pixels[thisone].b=temp.getColorBlue();
        // d_r[thisone]=temp.getColorRed();
        // d_g[thisone]=temp.getColorGreen();
        // d_b[thisone]=temp.getColorBlue();
      //
      // color temp1 = d_pixels[thisone];
      //
      // printf("%f %f %f \n",temp1.getColorRed(),temp1.getColorGreen(),temp1.getColorBlue());

    }

}

bool create_scene(sphere **scene_spheres, int *sphere_count,plane **scene_planes,int *plane_count, light **light_sources, int *total_sources,int *total_objects){
  *sphere_count=2;
  *plane_count=1;
  *total_sources=1;

  *total_objects=3;

  sphere *h_spheres;
  plane *h_planes;
  light *h_sources;


  int error=0;
  h_spheres = (sphere*)malloc(sizeof(sphere)*(*sphere_count));
  if(!h_spheres) error = 1;
  if (error) return false;

  h_planes = (plane*)malloc(sizeof(plane)*(*plane_count));
  if(!h_planes) error = 1;
  if (error) return false;

  h_sources = (light*)malloc(sizeof(light)*(*total_sources));
  if(!h_sources) error = 1;
  if (error) return false;

  cudaMalloc((void**)&(*scene_spheres),sizeof(sphere)*(*sphere_count));
  cudaMalloc((void**)&(*scene_planes),sizeof(plane)*(*plane_count));
  cudaMalloc((void**)&(*light_sources),sizeof(light)*(*total_sources));

  vect O (0,0,0);
  vect X (1,0,0);
  vect Y (0,1,0);
  vect Z (0,0,1);

  color white_light (1.0,1.0,1.0,0);
  color pretty_green (0.5,1.0,0.5,0.3);
  color maroon (0.5,0.25,0.25,0);
  color tileFloor (0.2,0.7,1,2);
  color gray (0.5,0.5,0.5,0);
  color black (0.0,0.0,0.0,0);
  vect light_position (-7,10,-10);

  light scene_light (light_position, white_light);

  sphere scene_sphere (O, 1, pretty_green);
  sphere scene_sphere2 (X.vectMul(1.75), 0.5, maroon);
  plane scene_plane (Y, -1, tileFloor);

  memcpy(&h_sources[0],&scene_light,sizeof(light));

  memcpy(&h_spheres[0],&scene_sphere,sizeof(sphere));
  memcpy(&h_spheres[1],&scene_sphere2,sizeof(sphere));
  memcpy(&h_planes[0],&scene_plane,sizeof(plane));

  cudaMemcpy((*scene_spheres),h_spheres,sizeof(sphere)*(*sphere_count),cudaMemcpyHostToDevice);
   cudaCheckErrors ("Copying 'objects' array to device");

   cudaMemcpy((*scene_planes),h_planes,sizeof(plane)*(*plane_count),cudaMemcpyHostToDevice);
    cudaCheckErrors ("Copying 'objects' array to device");

  cudaMemcpy((*light_sources),h_sources,sizeof(light)*(*total_sources),cudaMemcpyHostToDevice);
   cudaCheckErrors ("Copying 'sources' array to device");
  // free (h_objects);
  // free (h_sources);

  if(cudaGetLastError()!=cudaSuccess)
    return false;
  return true;
}

int main(){
  cout<<"rendering...."<<endl;

  int dpi = 72;
  int width=640;
  int height=480;

// = new RGBType[n];
  //cudaMallocManaged(&pixels, n*sizeof(RGBType));
  //double *h_r,*h_g,*h_b,*d_r,*d_g,*d_b;
  int aadepth = 3;
  double aathreshold = 0.1;
  double aspectRatio = (double) width/ (double) height;
  double ambientLight = 0.2;
  double accuracy = 0.000001;

  vect O (0,0,0);
  vect X (1,0,0);
  vect Y (0,1,0);
  vect Z (0,0,1);

  int total_objects;
  int total_sources;
  vect camPos (3,1.5,-4);
  vect look_at (0,0,0);
  vect diff_btw (camPos.getVectX()-look_at.getVectX(),camPos.getVectY()-look_at.getVectY(),camPos.getVectZ()-look_at.getVectZ());

  vect camDir = diff_btw.negative().normalize();
  vect camRight = Y.crossProduct(camDir).normalize();
  vect camDown = camRight.crossProduct(camDir);
  camera scene_cam (camPos, camDir, camRight, camDown);

  // color white_light (1.0,1.0,1.0,0);
  // color pretty_green (0.5,1.0,0.5,0.3);
  // color maroon (0.5,0.25,0.25,0.5);
  // color tileFloor (1,1,1,2);
  // color gray (0.5,0.5,0.5,0);
  // color black (0.0,0.0,0.0,0);

   light *light_sources;

   sphere *scene_spheres;
   int sphere_count;
   int plane_count;
   plane *scene_planes;
  if(create_scene(&scene_spheres,&sphere_count,&scene_planes,&plane_count,&light_sources,&total_sources,&total_objects)){
    cout<<"created the scene successfully \n";
  }else{
    cout<<"scene creation failed spectacularly";
     return 0;}

    RGBType* h_pixels = (RGBType*)malloc(width*height*sizeof(RGBType));
    RGBType* d_pixels;
    // h_r = (double*)malloc(num_bytes);
    // h_g = (double*)malloc(num_bytes);
    // h_b = (double*)malloc(num_bytes);
    cudaError_t x=cudaMalloc(&d_pixels,width*height*sizeof(RGBType));
    if(x!= cudaSuccess) printf("Error: %s\n",cudaGetErrorString(x));
    else cout<<"this one worked \n";
    // cudaMalloc(&d_r,num_bytes);
    // cudaMalloc(&d_g,num_bytes);
    // cudaMalloc(&d_b,num_bytes);
  //  memset(h_pixels,0,num_bytes);
    //cudaMemcpy(d_pixels,h_pixels,num_bytes,cudaMemcpyHostToDevice);



// calling the kernel function


  int N = width*height;
  //int blockSize = 64;
  //int numBlocks = N/blockSize;
  dim3 threadsPerBlock(16,16);
  dim3 numBlocks(ceil(width/threadsPerBlock.x) +1,ceil(height/threadsPerBlock.y) +1);

  auto start=high_resolution_clock::now();
  render<<<numBlocks, threadsPerBlock>>>(d_pixels,N,aadepth,aathreshold,width,height,aspectRatio,accuracy,ambientLight,total_objects,scene_spheres,sphere_count,scene_planes,plane_count,light_sources,total_sources,scene_cam);
  cudaError_t err = cudaGetLastError();
  if (err != cudaSuccess)
    printf("Error: %s\n", cudaGetErrorString(err));
  else cout<<"kernel worked"<<endl;
  cudaDeviceSynchronize();
  auto stop=high_resolution_clock::now();

  auto duration=duration_cast<microseconds>(stop-start);
  cout<<duration.count()<<" microseconds"<<endl;

  cudaError_t s = cudaMemcpy(h_pixels,d_pixels,width*height*sizeof(RGBType),cudaMemcpyDeviceToHost);
  if(s!= cudaSuccess) printf("Error: %s\n",cudaGetErrorString(s));
  else cout<<"shits successful";


  // cudaMemcpy(h_r,d_r,num_bytes,cudaMemcpyDeviceToHost);
  // cudaMemcpy(h_g,d_g,num_bytes,cudaMemcpyDeviceToHost);
  // cudaMemcpy(h_b,d_b,num_bytes,cudaMemcpyDeviceToHost);
//   RGBType rgb;
//   for(int i=0;i<n;i++){
//     rgb = h_pixels[i];
//   cout<<i<<" "<<rgb.r<<","<<rgb.g<<","<<rgb.b<<endl;
// }
  saveBMP("scene_1.bmp",width,height,dpi,h_pixels);
  //delete pixels, tempRed, tempGreen, tempBlue;
  //delete h_pixels;

  cudaFree(d_pixels);

  cudaFree(scene_spheres);
  cudaFree(scene_planes);
  cudaFree(light_sources);


  return 0;
}
