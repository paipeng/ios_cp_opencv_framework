//
//  cp_sharpness.c
//  CPOpenCV
//
//  Created by Pai Peng on 26.09.24.
//

#include "cp_sharpness.h"



int cp_laplacian1(const unsigned char* data, int width, int height, char *filter_mat) {
    int i, j;
    int pixel;
    // Apply the filter
    for (i = 1; i< height-1; i++) {
        for (j = 1; j < width-1; j++) {
            pixel = ((int)data[i* width + j] * 4 - data[(i - 1)* width + j] - data[(i + 1)* width + j] - data[i* width + j + 1] - data[i* width + j - 1])/4;
            filter_mat[i * width + j] = (char)pixel;
        }
    }
    return 0;
}


int cp_laplacian_sharpness(const unsigned char* data, int width, int height, float* score) {
    char *filter_mat = NULL;
    int i, j;
    int sum = 0;
    int mean = 0;
    int variance = 0;
    
    filter_mat = malloc(width * height * sizeof(char));
    //pc_laplacian(data, width, height, filter_mat);
    cp_laplacian1(data, width, height, filter_mat);
    
    // calculate mean
    for (i = 1; i< height-1; i++) {
        for (j = 1; j < width-1; j++) {
            sum += abs(filter_mat[i * width + j]);
        }
    }
    *score = 1.0 * sum / ((width -2) * (height-2));
    
    free(filter_mat);
    
    /*
    mean = sum / ((width -2) * (height-2));
    // standard deviation
    for (i = 1; i< height-1; i++) {
        for (j = 1; j < width-1; j++) {
            //variance += (filter_mat[i * width + j] - mean) * (filter_mat[i * width + j] - mean);
            variance += (filter_mat[i * width + j] - mean) >= 0? (filter_mat[i * width + j] - mean) : (mean - filter_mat[i * width + j]);
        }
    }
    
    free(filter_mat);
    *score = variance / ((width -2) * (height-2));//sqrt(variance / ((width -2) * (height-2)));
     */
    return 1;
}
