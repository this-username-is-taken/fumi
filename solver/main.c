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

FILE *file;

void print_vel(float *u, float *v, int Nx, int Ny)
{
    int i, j;
    for (j=1;j<=Ny;j++)
        for (i=1;i<=Nx;i++)
            fprintf(file, "%f %f ", u[IX(i, j)], v[IX(i, j)]);
    fprintf(file, "\n");
}

int main(int argc, const char * argv[])
{
    int i;
    int Nx = 128;
    int Ny = 256;
    int center_x = 64;
    int center_y = 128;
    int frames = 8;
    float dt = 0.1f;
    float visc = 0.001f;
    
    float *u, *v;
    
    // allocate data
	int size = (Nx+2)*(Ny+2);
	u = calloc(size, sizeof(float));
	v = calloc(size, sizeof(float));
	if (!u || !v) printf("Cannot allocate data\n");
    
    file = fopen("output.txt","w");
    fprintf(file, "%d %d %d %d %d\n", frames, Nx, Ny, center_x, center_y);
    
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
        print_vel(u, v, Nx, Ny);
    }
    
    end_solver();
    fclose(file);
    
    return 0;
}