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

void print_vel(float *u, float *v, int size)
{
    int i;
    for (i=0;i<size;i++)
        printf("%f %f ", u[i], v[i]);
    printf("\n");
}

int main(int argc, const char * argv[])
{
    int i;
    int Nx = 64;
    int Ny = 128;
    int center_x = 32;
    int center_y = 64;
    int frames = 8;
    float dt = 0.1f;
    float visc = 0.004f;
    
    float *u, *v;
    
    // allocate data
	int size = (Nx+2)*(Ny+2);
	u = calloc(size, sizeof(float));
	v = calloc(size, sizeof(float));
	if (!u || !v) printf("Cannot allocate data\n");
    
    printf("%d %d %d %d %d\n", frames, Nx, Ny, center_x, center_y);
    
    start_solver((Nx+2)*(Ny+2));
    
    v[IX(center_x, center_y)] = 100.0;
    vel_step(Nx, Ny, u, v, visc, dt);
    vel_step(Nx, Ny, u, v, visc, dt);
    vel_step(Nx, Ny, u, v, visc, dt);
    vel_step(Nx, Ny, u, v, visc, dt);
    for (i=0;i<frames;i++) {
        vel_step(Nx, Ny, u, v, visc, dt);
        vel_step(Nx, Ny, u, v, visc, dt);
        vel_step(Nx, Ny, u, v, visc, dt);
        vel_step(Nx, Ny, u, v, visc, dt);
        print_vel(u, v, size);
    }
    
    end_solver();
    
    return 0;
}