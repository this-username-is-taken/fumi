//
//  FMSolver.h
//  fumi
//
//  Created by Vincent Wen on 9/18/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#ifndef fumi_FMSolver_h
#define fumi_FMSolver_h

// Allocates memory for tmp variables used by the solver.
// Must be called before any other function can be used.
void start_solver(int size);
// Frees allocated memory. Must be called when the solver is no longer used.
void end_solver();

// Advances one timestep for the velocity field, computed in place.
// - Nx:    width of the grid
// - Ny:    height of the grid
// - u:     the x component of the vector field
// - v:     the y component of the vector field
// - visc:  the viscosity of the fluid
// - dt:    the change in time between timesteps
void vel_step(int Nx, int Ny, float *u, float *v, float visc, float dt);

// Advances one timestep for the density field, computed in place.
// - Nx:    width of the grid
// - Ny:    height of the grid
// - d:     the density (scalar) field
// - u:     the x component of the vector field
// - v:     the y component of the vector field
// - dt:    the change in time between timesteps
void den_step(int Nx, int Ny, float *d, float *u, float *v, float dt);

#endif
