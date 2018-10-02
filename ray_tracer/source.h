#ifndef _SOURCE_H
#define _SOURCE_H

class source {
public:
  source();

  inline virtual vect getLightPosition(){return vect(0,0,0);}
  inline virtual color getLightColor(){return color(1,1,1,0);}
};

source::source(){}

#endif
