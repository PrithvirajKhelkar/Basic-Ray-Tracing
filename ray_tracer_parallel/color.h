#ifndef _COLOR_H
#define _COLOR_H

class color {
  double red, green, blue, special;

public:
  __host__ __device__ color(){
      red=0.5;
      green=0.5;
      blue=0.5;
  }

  __host__ __device__ color(double redValue, double greenValue, double blueValue, double specialValue){
      red=redValue;
      green=greenValue;
      blue=blueValue;
      special=specialValue;
  }
__host__ __device__ ~color(){}
  // method functions
  __host__ __device__  double getColorRed() {return red;}
  __host__ __device__  double getColorGreen() {return green;}
  __host__ __device__  double getColorBlue() {return blue;}
  __host__ __device__  double getColorSpecial() {return special;}

  __host__ __device__  void setColorRed(double redValue) {red=redValue;}
  __host__ __device__  void setColorGreen(double greenValue) {green=greenValue;}
  __host__ __device__  void setColorBlue(double blueValue) {blue=blueValue;}
  __host__ __device__  void setColorSpecial(double specialValue) {special=specialValue;}

  __host__ __device__  double brightness() {
    return (red + green + blue)/3;
  }

  __host__ __device__  color colorScalar(double scalar){
    return color (red*scalar, green*scalar, blue*scalar, special);
  }

  __host__ __device__  color colorAdd(color c) {
    return color (red+c.getColorRed(), green+c.getColorGreen(), blue+c.getColorBlue(),special);
  }

  __host__ __device__  color colorMultiply(color c){
    return color (red*c.getColorRed(),green*c.getColorGreen(),blue*c.getColorBlue(),special);
  }

  __host__ __device__  color colorAverage(color c){
    return color ((red+c.getColorRed())/2,(green+c.getColorGreen())/2,(blue+c.getColorBlue())/2,special);
  }

  __host__ __device__  color clip(){
    double allLight = red+blue+green;
    double excessLight = allLight - 3;
    if(excessLight > 0){
      red = red + excessLight*(red/allLight);
      green = green + excessLight*(green/allLight);
      blue = blue + excessLight*(blue/allLight);
    }
    if(red > 1){
      red = 1;
    }
    if(green > 1){
      green = 1;
    }
    if(blue > 1){
      blue = 1;
    }
    if(red < 0){
      red = 0;
    }
    if(green < 0){
      green = 0;
    }
    if(blue < 0){
      blue = 0;
    }
    return color (red,green,blue,special);
  }

};

// color::color() {
//   red=0.5;
//   green=0.5;
//   blue=0.5;
// }
// color::color(double redValue, double greenValue, double blueValue, double specialValue) {
//   red=redValue;
//   green=greenValue;
//   blue=blueValue;
//   special=specialValue;
// }

#endif
