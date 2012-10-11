//
//  FMSolver.c
//  fumi
//
//  Created by Vincent Wen on 9/18/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#include "FMSolver.h"
#include <stdlib.h>
#include <stdio.h>

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
        for (i=1;i<=Nx;i++) {
            for (j=1;j<=Ny;j++) {
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
    
	for (i=1;i<=Nx;i++) {
        for (j=1;j<=Ny;j++) {
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

void d_advect(int Nx, int Ny, int b, float *d_new, float *d_old, float *u, float *v, float dt)
{
	int i, j, i0, j0, i1, j1, i2, j2, i3, j3;
	float f01, f02, f10, f11, f12, f13, f20, f21, f22, f23, f31, f32;
	float x, y;
	float tx11, tx12, tx21, tx22, ty11, ty12, ty21, ty22;
	float c[4][4];
    
	for (i=1;i<=Nx;i++) {
        for (j=1;j<=Ny;j++) {
            // (x,y) is the past cell that we copy density from
            x = i-dt*Nx*u[IX(i,j)];
            y = j-dt*Ny*v[IX(i,j)];
            
            if (x<1.5f) x=1.5f; if (x>Nx-0.5f) x=Nx-0.5f; i1=(int)x; i0=i1-1; i2=i1+1; i3=i1+2;
            if (y<1.5f) y=1.5f; if (y>Ny-0.5f) y=Ny-0.5f; j1=(int)y; j0=j1-1; j2=j1+1; j3=j1+2;
            
            f01 = d_old[IX(i0,j1)];
            f02 = d_old[IX(i0,j2)];
            f10 = d_old[IX(i1,j0)];
            f11 = d_old[IX(i1,j1)];
            f12 = d_old[IX(i1,j2)];
            f13 = d_old[IX(i1,j3)];
            f20 = d_old[IX(i2,j0)];
            f21 = d_old[IX(i2,j1)];
            f22 = d_old[IX(i2,j2)];
            f23 = d_old[IX(i2,j3)];
            f31 = d_old[IX(i3,j1)];
            f32 = d_old[IX(i3,j2)];
            
            tx11 = (f21 - f01)/2.0;
            tx21 = (f31 - f11)/2.0;
            tx12 = (f22 - f02)/2.0;
            tx22 = (f32 - f12)/2.0;
            
            ty11 = (f12 - f10)/2.0;
            ty21 = (f22 - f20)/2.0;
            ty12 = (f13 - f11)/2.0;
            ty22 = (f23 - f21)/2.0;
            
            c[0][0] = f11;
            c[1][0] = tx11;
            c[0][1] = ty11;
            c[2][0] = 3.0*(f21-f11) - tx21 - 2*tx11;
            c[0][2] = 3.0*(f12-f11) - ty12 - 2*ty11;
            c[3][0] = -2.0*(f21-f11) + tx21 + tx11;
            c[0][3] = -2.0*(f12-f11) + ty12 + ty11;
            c[2][1] = 3.0*f22 - 2.0*tx12 - tx22 - 3.0*(c[0][0]+c[0][1]+c[0][2]+c[0][3]) - c[2][0];
            c[3][1] = -2.0*f22 + tx12 + tx22 + 2.0*(c[0][0]+c[0][1]+c[0][2]+c[0][3]) - c[3][0];
            c[1][2] = 3.0*f22 - 2.0*ty21 - ty22 - 3.0*(c[0][0]+c[1][0]+c[2][0]+c[3][0]) - c[0][2];
            c[1][3] = -2.0*f22 + ty21 + ty22 + 2.0*(c[0][0]+c[1][0]+c[2][0]+c[3][0]) - c[0][3];
            c[1][1] = tx12 - c[1][3] - c[1][2] - c[1][0];
            
            x = x - i1;
            y = y - j1;
            
            d_new[IX(i,j)] = c[3][1]*x*x*x*y + c[1][3]*x*y*y*y + c[3][0]*x*x*x + c[2][1]*x*x*y + c[1][2]*x*y*y + c[0][3]*y*y*y +
                            c[2][0]*x*x + c[1][1]*x*y + c[0][2]*y*y + c[1][0]*x + c[0][1]*y + c[0][0];
            
            if (d_new[IX(i,j)]<0) d_new[IX(i,j)] = 0;
        }
    }
    
	set_bnd(Nx, Ny, b, d_new);
}

void project(int Nx, int Ny, float *u, float *v, float *p, float *div)
{
	int i, j;
    
    // Compute the divergence (and initialize the pressure term)
	for (i=1;i<=Nx;i++) {
        for (j=1;j<=Ny;j++) {
            div[IX(i,j)] = -0.5f*(u[IX(i+1,j)]-u[IX(i-1,j)]+v[IX(i,j+1)]-v[IX(i,j-1)])/Ny;
            p[IX(i,j)] = 0;
        }
    }
	set_bnd(Nx, Ny, 0, div);
    set_bnd(Nx, Ny, 0, p);
    
    // Solve for the pressure term (Poisson equation)
	lin_solve(Nx, Ny, 0, p, div, 1, 4);

    // Subtract the pressure from velocity field
	for (i=1;i<=Nx;i++) {
        for (j=1;j<=Ny;j++) {
            u[IX(i,j)] -= 0.5f*Ny*(p[IX(i+1,j)]-p[IX(i-1,j)]);
            v[IX(i,j)] -= 0.5f*Ny*(p[IX(i,j+1)]-p[IX(i,j-1)]);
        }
    }
	set_bnd(Nx, Ny, 1, u);
    set_bnd(Nx, Ny, 2, v);
}

void den_step(int Nx, int Ny, float *d, float *u, float *v, float dt)
{
    d_advect(Nx, Ny, 0, d_tmp, d, u, v, dt);
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
