//
//  FMSolver.c
//  fumi
//
//  Created by Vincent Wen on 9/18/12.
//  Copyright (c) 2012 fumi. All rights reserved.
//

#include "FMSolver.h"

#define IX(i,j) ((i)+(Nx+2)*(j))
#define SWAP(x0,x) {float * tmp=x0;x0=x;x=tmp;}
#define FOR_EACH_CELL for ( i=1 ; i<=Nx ; i++ ) { for ( j=1 ; j<=Ny ; j++ ) {
#define END_FOR }}

void add_source ( int Nx, int Ny, float * x, float * s, float dt )
{
	int i, size=(Nx+2)*(Ny+2);
	for ( i=0 ; i<size ; i++ ) x[i] += dt*s[i];
}

void set_bnd ( int Nx, int Ny, int b, float * x )
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

void lin_solve ( int Nx, int Ny, int b, float * x, float * x0, float a, float c )
{
	int i, j, k;
    
	for ( k=0 ; k<20 ; k++ ) {
		FOR_EACH_CELL
        x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
		END_FOR
		set_bnd ( Nx, Ny, b, x );
	}
}

void diffuse ( int Nx, int Ny, int b, float * x, float * x0, float diff, float dt )
{
	float a=dt*diff*Nx*Ny;
	lin_solve ( Nx, Ny, b, x, x0, a, 1+4*a );
}

void advect ( int Nx, int Ny, int b, float * d, float * d0, float * u, float * v, float dt )
{
	int i, j, i0, j0, i1, j1;
	float x, y, s0, t0, s1, t1;
    
	FOR_EACH_CELL
    x = i-dt*Nx*u[IX(i,j)]; y = j-dt*Ny*v[IX(i,j)];
    if (x<0.5f) x=0.5f; if (x>Nx+0.5f) x=Nx+0.5f; i0=(int)x; i1=i0+1;
    if (y<0.5f) y=0.5f; if (y>Ny+0.5f) y=Ny+0.5f; j0=(int)y; j1=j0+1;
    s1 = x-i0; s0 = 1-s1; t1 = y-j0; t0 = 1-t1;
    d[IX(i,j)] = s0*(t0*d0[IX(i0,j0)]+t1*d0[IX(i0,j1)])+
    s1*(t0*d0[IX(i1,j0)]+t1*d0[IX(i1,j1)]);
	END_FOR
	set_bnd ( Nx, Ny, b, d );
}

void project ( int Nx, int Ny, float * u, float * v, float * p, float * div )
{
	int i, j;
    
	FOR_EACH_CELL
    div[IX(i,j)] = -0.5f*(u[IX(i+1,j)]-u[IX(i-1,j)]+v[IX(i,j+1)]-v[IX(i,j-1)])/Ny;
    p[IX(i,j)] = 0;
	END_FOR
	set_bnd ( Nx, Ny, 0, div ); set_bnd ( Nx, Ny, 0, p );
    
	lin_solve ( Nx, Ny, 0, p, div, 1, 4 );
    
	FOR_EACH_CELL
    u[IX(i,j)] -= 0.5f*Ny*(p[IX(i+1,j)]-p[IX(i-1,j)]);
    v[IX(i,j)] -= 0.5f*Ny*(p[IX(i,j+1)]-p[IX(i,j-1)]);
	END_FOR
	set_bnd ( Nx, Ny, 1, u ); set_bnd ( Nx, Ny, 2, v );
}

void dens_step ( int Nx, int Ny, float * x, float * x0, float * u, float * v, float diff, float dt )
{
    /*
	add_source ( Nx, Ny, x, x0, dt );
	SWAP ( x0, x ); diffuse ( N, 0, x, x0, diff, dt );
	SWAP ( x0, x ); advect ( N, 0, x, x0, u, v, dt );
     */
}

void vel_step ( int Nx, int Ny, float * u, float * v, float * u0, float * v0, float visc, float dt )
{
	add_source ( Nx, Ny, u, u0, dt ); add_source ( Nx, Ny, v, v0, dt );
	SWAP ( u0, u ); diffuse ( Nx, Ny, 1, u, u0, visc, dt );
	SWAP ( v0, v ); diffuse ( Nx, Ny, 2, v, v0, visc, dt );
	project ( Nx, Ny, u, v, u0, v0 );
	SWAP ( u0, u ); SWAP ( v0, v );
	advect ( Nx, Ny, 1, u, u0, u0, v0, dt ); advect ( Nx, Ny, 2, v, v0, u0, v0, dt );
	project ( Nx, Ny, u, v, u0, v0 );
}
