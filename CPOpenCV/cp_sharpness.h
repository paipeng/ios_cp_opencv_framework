//
//  cp_sharpness.h
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

#ifndef cp_sharpness_h
#define cp_sharpness_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif
int cp_laplacian_sharpness(const unsigned char* data, int width, int height, float* score);


#ifdef __cplusplus
}
#endif
#endif /* cp_sharpness_h */
