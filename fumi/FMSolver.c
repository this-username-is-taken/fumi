//
//  FMSolver.c
//  fumi
//
//  Created by Vincent Wen on 9/18/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#include "FMSolver.h"
#include <stdlib.h>

#define IX(i,j) ((i)+(Nx+2)*(j))
#define SWAP(x0,x) {float * tmp=x0;x0=x;x=tmp;}

float *u_tmp, *v_tmp, *d_tmp;

void start_solver(int size)
{
	u_tmp = (float *)calloc(size, sizeof(float));
	v_tmp = (float *)calloc(size, sizeof(float));
	d_tmp = (float *)calloc(size, sizeof(float));
}

void end_solver()
{
    free(u_tmp);
    free(v_tmp);
    free(d_tmp);
}

void set_bnd(int Nx, int Ny, int b, float *x)
{
	int i;
    
	for ( i=1 ; i<=Ny ; i++ ) {
		x[IX(0   ,i)] = b==1 ? -x[IX(1,i)] : x[IX(1,i)];
		x[IX(Nx+1,i)] = b==1 ? -x[IX(Nx,i)] : x[IX(Nx,i)];
	}
    for ( i=1 ; i<=Nx ; i++ ) {
		x[IX(i,0   )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];
		x[IX(i,Ny+1)] = b==2 ? -x[IX(i,Ny)] : x[IX(i,Ny)];
    }
    
	x[IX(0  ,0   )] = 0.5f*(x[IX(1,0   )]+x[IX(0   ,1)]);
	x[IX(0  ,Ny+1)] = 0.5f*(x[IX(1,Ny+1)]+x[IX(0  ,Ny)]);
	x[IX(Nx+1,0  )] = 0.5f*(x[IX(Nx,0  )]+x[IX(Nx+1,1)]);
	x[IX(Nx+1,Ny+1)] = 0.5f*(x[IX(Nx,Ny+1)]+x[IX(Nx+1,Ny)]);
}

void lin_solve(int Nx, int Ny, int b, float *x, float *x0, float a, float c)
{
	int i, j, k;
    
	for (k=0;k<20;k++) {
        for (i=1;i<Nx;i++) {
            for (j=1;j<Ny;j++) {
                x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
            }
        }
		set_bnd (Nx, Ny, b, x);
	}
}

void diffuse(int Nx, int Ny, int b, float *x_new, float *x_old, float diff, float dt)
{
	float a=dt*diff*Nx*Ny;
    
    // unstable: x_new(i,j) = x_old(i-1,j-1) + x_old(i-1,j+1) + x_old(i+1,j-1) + x_old(i+1,j+1) - 4*x_old(i,j)
    // stable:   x_old(i,j) = x_new(i,j) - a*[x_new(i-1,j-1) + x_new(i-1,j+1) + x_new(i+1,j-1) + x_new(i+1,j+1) - 4*x_new(i,j)]
	lin_solve(Nx, Ny, b, x_new, x_old, a, 1+4*a);
}

void advect(int Nx, int Ny, int b, float *d_new, float *d_old, float *u, float *v, float dt)
{
	int i, j, i0, j0, i1, j1;
	float x, y, s0, t0, s1, t1;
    
	for (i=1;i<Nx;i++) {
        for (j=1;j<Ny;j++) {
            // (x,y) is the past cell that we copy density from
            x = i-dt*Nx*u[IX(i,j)];
            y = j-dt*Ny*v[IX(i,j)];
            
            // makes sure that (x,y) is within the grid
            if (x<0.5f) x=0.5f;     if (x>Nx+0.5f) x=Nx+0.5f;
            if (y<0.5f) y=0.5f;     if (y>Ny+0.5f) y=Ny+0.5f;
            
            // compute the index of the 4 neighbouring cells
            i0=(int)x;  i1=i0+1;    j0=(int)y;  j1=j0+1;
            // compute the relative distance to those cells
            s1=x-i0;    s0=1-s1;    t1=y-j0;    t0=1-t1;
            
            // linearly interpolate a new value from the 4 neighbouring cells
            d_new[IX(i,j)] = s0*(t0*d_old[IX(i0,j0)]+t1*d_old[IX(i0,j1)])+
                             s1*(t0*d_old[IX(i1,j0)]+t1*d_old[IX(i1,j1)]);
        }
    }
	set_bnd(Nx, Ny, b, d_new);
}

void project(int Nx, int Ny, float *u, float *v, float *p, float *div)
{
	int i, j;
    
    // Compute the divergence (and initialize the pressure term)
	for (i=1;i<Nx;i++) {
        for (j=1;j<Ny;j++) {
            div[IX(i,j)] = -0.5f*(u[IX(i+1,j)]-u[IX(i-1,j)]+v[IX(i,j+1)]-v[IX(i,j-1)])/Ny;
            p[IX(i,j)] = 0;
        }
    }
	set_bnd(Nx, Ny, 0, div);
    set_bnd(Nx, Ny, 0, p);
    
    // Solve for the pressure term (Poisson equation)
	lin_solve(Nx, Ny, 0, p, div, 1, 4);

    // Subtract the pressure from velocity field
	for (i=1;i<Nx;i++) {
        for (j=1;j<Ny;j++) {
            u[IX(i,j)] -= 0.5f*Ny*(p[IX(i+1,j)]-p[IX(i-1,j)]);
            v[IX(i,j)] -= 0.5f*Ny*(p[IX(i,j+1)]-p[IX(i,j-1)]);
        }
    }
	set_bnd(Nx, Ny, 1, u);
    set_bnd(Nx, Ny, 2, v);
}

void den_step(int Nx, int Ny, float *d, float *u, float *v, float dt)
{
    advect(Nx, Ny, 0, d_tmp, d, u, v, dt);
    SWAP(d_tmp, d);
}

void vel_step(int Nx, int Ny, float *u, float *v, float visc, float dt)
{
	diffuse(Nx, Ny, 1, u_tmp, u, visc, dt);
	diffuse(Nx, Ny, 2, v_tmp, v, visc, dt);
    SWAP(u_tmp, u);
    SWAP(v_tmp, v);
    
	project(Nx, Ny, u, v, u_tmp, v_tmp);
    
	advect(Nx, Ny, 1, u_tmp, u, u, v, dt);
    advect(Nx, Ny, 2, v_tmp, v, u, v, dt);
	SWAP(u_tmp, u);
    SWAP(v_tmp, v);
    
	project(Nx, Ny, u, v, u_tmp, v_tmp);
}
