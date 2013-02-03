//
//  main.cpp
//  solver
//
//  Created by Vincent Wen on 2/2/13.
//  Copyright (c) 2013 fumi. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "FMSolver.h"

#define IX(i,j) ((i)+(Nx+2)*(j))

void print_vel(float *u, float *v, int Nx, int Ny)
{
    int i, j;
    for (i=1;i<=Ny;i++) {
        for (j=1;j<=Nx;j++) {
            printf("%f %f ", u[IX(i, j)], v[IX(i, j)]);
        }
    }
    printf("\n");
}

int main(int argc, const char * argv[])
{
    int i;
    int Nx = 80;
    int Ny = 120;
    int center_x = 40;
    int center_y = 60;
    int frames = 15;
    float dt = 0.1f;
    float visc = 0.002f;
    
    float *u, *v;
    
    // allocate data
	int size = (Nx+2)*(Ny+2);
	u = (float *) malloc ( size*sizeof(float) );
	v = (float *) malloc ( size*sizeof(float) );
	if (!u || !v) printf("Cannot allocate data\n");
    
    printf("%d %d %d %d %d\n", frames, Nx, Ny, center_x, center_y);
    
    start_solver((Nx+2)*(Ny+2));
    
    v[IX(center_x, center_y)] = 1.0;
    for (i=0;i<frames;i++) {
        vel_step(Nx, Ny, u, v, visc, dt);
        print_vel(u, v, Nx, Ny);
    }
    
    end_solver();
    
    return 0;
}