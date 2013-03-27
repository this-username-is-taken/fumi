/*
 ======================================================================
 Author : Jos Stam (jstam@aw.sgi.com)
 Creation Date : Jan 9 2003
 
 Description:
 
 This code is a simple prototype that demonstrates how to use the
 code provided in my GDC2003 paper entitles "Real-Time Fluid Dynamics
 for Games". This code uses OpenGL and GLUT for graphics and interface
 
 To run: gcc solver.c fumi/FMSolver.c -framework OpenGL -framework GLUT
 
 Arguments:
 
 - N      : grid resolution
 - dt     : time step
 - visc   : viscosity of the fluid
 - force  : scales the mouse movement that generate a force
 - source : amount of density that will be deposited
 
 While running:
 
 - right: Add densities
 - left: Add velocities
 - v: Toggle density/velocity display
 - c: Clear the simulation
 - q: Quit
 
 =======================================================================
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <GLUT/glut.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include "FMSolver.h"

#define IX(i,j) ((i)+(Nx+2)*(j))

/* global variables */

static int Nx, Ny;
static float dt, visc;
static float force, source;
static int mode;

static float *u, *v, *d;

static int win_id;
static int win_x, win_y;
static int mouse_down[3];
static int omx, omy, mx, my;

/*
 ----------------------------------------------------------------------
 free/clear/allocate simulation data
 ----------------------------------------------------------------------
 */

static void free_data ( void )
{
	if ( u ) free ( u );
	if ( v ) free ( v );
	if ( d ) free ( d );
}

static void clear_data ( void )
{
	int i, size=(Nx+2)*(Ny+2);
    
	for ( i=0 ; i<size ; i++ ) {
		u[i] = v[i] = d[i] = 0.0f;
	}
}

static int allocate_data ( void )
{
	int size = (Nx+2)*(Ny+2);
    
	u = (float *) malloc ( size*sizeof(float) );
	v = (float *) malloc ( size*sizeof(float) );
	d = (float *) malloc ( size*sizeof(float) );
    
	if ( !u || !v || !d ) {
		fprintf ( stderr, "cannot allocate data\n" );
		return ( 0 );
	}
    
	return ( 1 );
}


/*
 ----------------------------------------------------------------------
 OpenGL specific drawing routines
 ----------------------------------------------------------------------
 */

static void pre_display()
{
	glViewport(0, 0, win_x, win_y);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluOrtho2D(0.0, 1.0, 0.0, 1.0);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
}

static void post_display()
{
	glutSwapBuffers();
}

static void draw_velocity()
{
	int i, j;
	float x, y;
    
	glColor3f(1.0f, 1.0f, 1.0f);
	glLineWidth(1.0f);
    
	glBegin(GL_LINES);
    for (i=1;i<=Nx;i++) {
        x = (i-0.5f)/Nx;
        for (j=1;j<=Ny;j++) {
            y = (j-0.5f)/Ny;
            
            glVertex2f(x, y);
            glVertex2f(x+u[IX(i,j)], y+v[IX(i,j)]);
        }
    }
    
	glEnd();
}

static void draw_density()
{
	int i, j;
	float x, y, d00, d01, d10, d11;
    
	glBegin(GL_QUADS);
    
    for ( i=0 ; i<=Nx ; i++ ) {
        x = (i-0.5f)/Nx;
        for ( j=0 ; j<=Ny ; j++ ) {
            y = (j-0.5f)/Ny;
            
            d00 = d[IX(i,j)];
            d01 = d[IX(i,j+1)];
            d10 = d[IX(i+1,j)];
            d11 = d[IX(i+1,j+1)];
            
            glColor3f ( d00, d00, d00 ); glVertex2f ( x, y );
            glColor3f ( d10, d10, d10 ); glVertex2f ( x+1.0/Nx, y );
            glColor3f ( d11, d11, d11 ); glVertex2f ( x+1.0/Nx, y+1.0/Ny );
            glColor3f ( d01, d01, d01 ); glVertex2f ( x, y+1.0/Ny );
        }
    }
    
	glEnd();
}

/*
 ----------------------------------------------------------------------
 relates mouse movements to forces sources
 ----------------------------------------------------------------------
 */

static void get_from_UI()
{
	int i, j, size = (Nx+2)*(Ny+2);
    
	if (!mouse_down[0] && !mouse_down[2]) return;
    
	i = (int)((       mx /(float)win_x)*Nx+1);
	j = (int)(((win_y-my)/(float)win_y)*Ny+1);
    
	if (i<1 || i>Nx || j<1 || j>Ny) return;
    
	if (mouse_down[0]) {
		u[IX(i,j)] = force * (mx-omx);
		v[IX(i,j)] = force * (omy-my);
	}
    
	if (mouse_down[2]) {
		d[IX(i,j)] = source;
	}
    
	omx = mx;
	omy = my;
    
	return;
}

/*
 ----------------------------------------------------------------------
 GLUT callback routines
 ----------------------------------------------------------------------
 */

static void key_func(unsigned char key, int x, int y)
{
	switch (key)
	{
		case 'c':
		case 'C':
			clear_data();
			break;
		case 'q':
		case 'Q':
			free_data();
			exit(0);
			break;
		case 'v':
		case 'V':
			mode = !mode;
			break;
	}
}

static void mouse_func ( int button, int state, int x, int y )
{
	omx = mx = x;
	omx = my = y;
    
	mouse_down[button] = state == GLUT_DOWN;
}

static void motion_func ( int x, int y )
{
	mx = x;
	my = y;
}

static void reshape_func(int width, int height)
{
	glutSetWindow(win_id);
	glutReshapeWindow(width, height);
    
	win_x = width;
	win_y = height;
}

static void idle_func()
{
#ifdef SHOW_TIME
    struct timeval tvStart, tvEnd, tvDiff;
    gettimeofday(&tvStart, NULL);
#endif
    
	get_from_UI();
	vel_step(Nx, Ny, u, v, visc, dt);
	den_step(Nx, Ny, d, u, v, dt);
    
	glutSetWindow(win_id);
	glutPostRedisplay();
    
#ifdef SHOW_TIME
    gettimeofday(&tvEnd, NULL);
    tvDiff = timeval_subtract(&tvEnd, &tvStart);
    timeval_print(&tvDiff);
#endif
}

static void display_func()
{
	pre_display();
    
    if (mode)
    	draw_velocity();
    else
    	draw_density();
    
	post_display();
}

/*
 ----------------------------------------------------------------------
 open_glut_window --- open a glut compatible window and set callbacks
 ----------------------------------------------------------------------
 */

static void open_glut_window()
{
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
    
	glutInitWindowPosition(0, 0);
	glutInitWindowSize(win_x, win_y);
	win_id = glutCreateWindow("Fluid");
    
	glutKeyboardFunc(key_func);
	glutMouseFunc(mouse_func);
	glutMotionFunc(motion_func);
	glutReshapeFunc(reshape_func);
	glutIdleFunc(idle_func);
	glutDisplayFunc(display_func);
}

/*
 ----------------------------------------------------------------------
 main --- main routine
 ----------------------------------------------------------------------
 */

int main(int argc, char **argv)
{
    glutInit(&argc, argv);
    
    Nx = 128;
    Ny = 128;
    dt = 0.1f;
    visc = 0.001f;
    force = 1.0f;
    source = 100.0f;
    printf("Settings: N=%dx%d dt=%g visc=%g force = %g source=%g\n", Nx, Ny, dt, visc, force, source);
    
    // 0 for density, 1 for velocity
	mode = 0;
    
    start_solver((Nx+2)*(Ny+2));
	if (!allocate_data())
        exit (1);
    
	clear_data();
    
	win_x = 512;
	win_y = 512;
	open_glut_window();
    
	glutMainLoop();
    end_solver();
    
	exit(0);
}