//
//  cp_opencv.hpp
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

#ifndef cp_opencv_hpp
#define cp_opencv_hpp

#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif

const char* getOpenCVVersion();
int convertGrayscale(char* data, int format, int width, int height, char* out_data);
void convertGrayscale2(int format, int width, int height);

#ifdef __cplusplus
}
#endif
#endif /* cp_opencv_hpp */
