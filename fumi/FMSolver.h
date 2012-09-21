//
//  FMSolver.h
//  fumi
//
//  Created by Vincent Wen on 9/18/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMSolver_h
#define fumi_FMSolver_h

void start_solver(int size);
void end_solver();

void add_source ( int Nx, int Ny, float * x, float * s, float dt );
void set_bnd ( int Nx, int Ny, int b, float * x );

void lin_solve ( int Nx, int Ny, int b, float * x, float * x0, float a, float c );

void diffuse ( int Nx, int Ny, int b, float * x, float * x0, float diff, float dt );
void advect ( int Nx, int Ny, int b, float * d, float * d0, float * u, float * v, float dt );

void project ( int Nx, int Ny, float * u, float * v, float * p, float * div );

void dens_step ( int Nx, int Ny, float * x, float * u, float * v, float dt );
void vel_step ( int Nx, int Ny, float * u, float * v, float visc, float dt );

#endif
