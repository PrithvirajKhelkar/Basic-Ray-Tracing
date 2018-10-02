#ifndef _COLOR_H
#define _COLOR_H

class color {
  double red, green, blue, special;

public:
  color();

  color(double, double, double, double);

  // method functions
  inline double getColorRed() {return red;}
  inline double getColorGreen() {return green;}
  inline double getColorBlue() {return blue;}
  inline double getColorSpecial() {return special;}

  inline double setColorRed(double redValue) {red=redValue;}
  inline double setColorGreen(double greenValue) {green=greenValue;}
  inline double setColorBlue(double blueValue) {blue=blueValue;}
  inline double setColorSpecial(double specialValue) {special=specialValue;}

  inline double brightness() {
    return (red + green + blue)/3;
  }

  inline color colorScalar(double scalar){
    return color (red*scalar, green*scalar, blue*scalar, special);
  }

  inline color colorAdd(color c) {
    return color (red+c.getColorRed(), green+c.getColorGreen(), blue+c.getColorBlue(),special);
  }

  inline color colorMultiply(color c){
    return color (red*c.getColorRed(),green*c.getColorGreen(),blue*c.getColorBlue(),special);
  }

  inline color colorAverage(color c){
    return color ((red+c.getColorRed())/2,(green+c.getColorGreen())/2,(blue+c.getColorBlue())/2,special);
  }

  inline color clip(){
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

color::color() {
  red=0.5;
  green=0.5;
  blue=0.5;
}
color::color(double redValue, double greenValue, double blueValue, double specialValue) {
  red=redValue;
  green=greenValue;
  blue=blueValue;
  special=specialValue;
}

#endif
