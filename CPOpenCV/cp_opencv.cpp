//
//  cp_opencv.cpp
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

#include "cp_opencv.hpp"


#ifdef __cplusplus
#import <opencv2/opencv.hpp>
//#import <opencv2/imgcodecs/ios.h>

#endif

const char* getOpenCVVersion() {
    return CV_VERSION;
}

int convertGrayscale(char* data, int format, int width, int height, char* out_data) {
#if 1
    cv::Mat mat(height, width, CV_8UC3, data);
    
    cv::Mat grayMat;
    
    cv::cvtColor(mat, grayMat, cv::COLOR_RGB2GRAY);
    
    memcpy(out_data, grayMat.data, sizeof(char) * width * height);
#endif
    return 1;
}


void convertGrayscale2(int format, int width, int height) {
    
}
