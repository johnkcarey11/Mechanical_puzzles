/*

pplanner.c

This program finds a path for a pushed polygon in a bounding box from
a specified start position and orientation to a user-specified
neighborhood of a goal position, while avoiding obstacles.  The
planner is described in detail in "Stable Pushing: Mechanics,
Controllability, and Planning," by Kevin M. Lynch and Matthew
T. Mason, appearing in _Algorithmic Foundations of Robotics_,
Goldberg, Latombe, Wilson, and Halperin, ed., A. K. Peters, Boston,
1995.  Also to appear in the International Journal of Robotics Research.

Usage:  pplanner [problemfile]

If the problemfile is not specified, the default is INFILE.  Here
it's set to push.problem.

To compile,
cc -o pplanner pplanner.c -lm

-----------------------
The format for the problem specification.

xmin xmax ymin ymax        {floats; bounding box.  xmin, ymin should be 0.0}

objpolys                   {int; number of polygons in object representation}
poly1_vertices             {int; number of vertices in first object polygon}
x1 y1 ... xn yn            {floats; vertices of polygon}
poly2_vertices             {int; number of vertices in second object polygon}
x1 y1 ... xn yn            {floats; vertices of polygon}
 :                         {continue for all object polygons}

obstacles                  {int; number of obstacles}
obs1_vertices              {int; number of vertices in first obstacle}
x1 y1 ... xn yn
obs2_vertices
x1 y1 ... xn yn
 :

startx starty starttheta   {floats; start position of object reference pt}
goalx goaly goaltheta      {floats; nominal goal position}
xerr yerr thetaerr         {floats; +/- error allowed in goal location}
arclength                  {float; arclength of motion of reference point}
numedges                   {int; number of edges to push on}
numcontrols1               {int; number of object velocities for first edge}
vx1 vy1 omega1             {floats; first x, y, angular velocity}
vx2 vy2 omega2             {floats; second x, y, angular velocity}
 :
numcontrols2               {int; number of object velocities}
vx1 vy1 omega1
 :

xcell ycell thetacell      {floats; size of cell which only one path can enter}
pushcost                   {int; cost of one push with same edge}
actionswitchcost           {int; cost of changing the pushing direction}
edgeswitchcost             {int; cost of changing pushing edges}
maxcost                    {int; maximum cost of a path before it's cut off}
-----------------------

Some notes on the input file:

1)  Angles are specified in radians.
2)  The definition of the polygons comprising the object are assumed with
    respect to the (0,0,0) configuration.
3)  The reference point of the robot (which moves constant distance during 
    each control) is the point (0, 0).
4)  The robot is treated as the smallest disk centered at (0, 0) which 
    includes the entire robot AND the max distance any point on the robot
    can move during each control.
5)  The goal neighborhood should be chosen large enough that it's not missed.
6)  The size of each cell should be chosen small enough such that the 
    object is guaranteed to move outside of it with each move.
7)  Angles should be specified in the range [0, 2PI).
8)  Each polygon in the robot and obstacles is assumed to be defined
    by points such that the inside of the polygon lies to the left as
    we travel from one point in the list to the next.

***********************************************************************
History (well, approximately):

1/23/93    Kevin Lynch   created
           (lynch)       path planner for a mobile robot pushing
                         a box from one edge with a discrete set
                         of velocity directions

11/16/93   lynch         modified to allow the robot to switch pushing
                         edges (without planning robot motion between
                         edges)

7/8/95     lynch         modified to allow nonconvex obstacles.
                         also prints some diagnostic messages regarding
                         the input and, to conserve memory (but not
			 time), checks for obstacle collisions before
			 inserting into the tree, not when deciding
			 whether to expand.

7-8/95     Costa Nikou   various changes to allow writing Adept files

AS OF NOW..we can only deal with writing adept files for MONOpolygonal
robots.  It will solve for poly-polys, but won't write a correct Adeptfile 
without some changes...


Should alter the program so that the array "occupied" is an
array of bits.  Right now using char, so using 8x too much memory.
Also, memory for nodes array could be more efficient.
***********************************************************************

*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "pglobals.h"

typedef struct {
  float x;
  float y;
  float theta; } pose;

typedef struct {
  int numvertices; 
  float xverts[MAXVERTICES];
  float yverts[MAXVERTICES];
  float nx[MAXVERTICES];   /* nx[1] is the x comp of normal from 0->1 verts */
  float ny[MAXVERTICES];
  float xmin;
  float ymin;
  float xmax;
  float ymax;} obs;

typedef struct {
  float r;
  float alpha;
  float dtheta;} control;

typedef struct {
  int numvertices;
  float xverts[MAXVERTICES];
  float yverts[MAXVERTICES];} poly;

struct {
  int numobjects;
  poly object[ROBOTPOLY]; } robot;

struct {
  float xmin;     /* IMPORTANT!  It is assumed that the world x and y min */
  float ymin;     /* positions are >= 0, i.e., all coordinates are nonnneg. */
  float xmax;
  float ymax;
  int numobstacles;
  obs obstacle[MAXOBSTACLES]; } world;

struct {
  float xmin;
  float ymin;
  float thetamin;
  float xmax;
  float ymax;
  float thetamax;} goal;

struct {
  float x;
  float y;
  float theta;} cell;

struct {
  int edges;
  int number[MAXEDGES];
  float tool_rotation[MAXEDGES];
  float tool_offset[MAXEDGES];
  control direction[MAXEDGES][MAXCONTROLS];} controls;

int sortedhead[MAXCOST];
int sortedtail[MAXCOST];
int currentdistance;
int currentnode;
int nodetail;
int pushcost,actionswitchcost,edgeswitchcost,maxcost;

struct {
  short edge;
  short action;
  int previous;
  int nextsorted;
  pose p;} node[MAXNODES];

char occupied[MAXEDGES][XCELLS][YCELLS][THETACELLS];

FILE *infile;
int Adept = 0;  /* 1 if writing to adeptfile, 0 if not */
float obs_growth,obs_growth_squared;

/*************************************************************
*  Helper functions
*************************************************************/

float cross_product(a,b,c,d)
float a,b,c,d;
{
  return(a*d-b*c);
}

float dot_product(a,b,c,d)
float a,b,c,d;
{
  return(a*c+b*d);
}

float length(x,y)
float x,y;
{
  return(sqrt(x*x+y*y));
}

float length_squared(x,y)
float x,y;
{
  return(x*x+y*y);
}

void fix_theta(p)
pose *p;
{
  if(p->theta<0) p->theta=p->theta + TWOPI;
  if(p->theta>=TWOPI) p->theta=p->theta - TWOPI;
}

float actual_theta(theta)
float theta;
{
  float ans = theta;

  if(ans<0) ans=ans + TWOPI;
  if(ans>=TWOPI) ans=ans - TWOPI;
  return(ans);
}

int mysignum(x)
float x;
{
  if(x>0) return(1);
  else if(x<0) return(-1);
  return(0);
}

/*************************************************************
*  Initialization
*************************************************************/

void initialize_occupied()
{
  int h,i,j,k;

  for(h=0; h<MAXEDGES; h++)
    for(i=0; i<=world.xmax/cell.x; i++)
      for(j=0; j<=world.ymax/cell.y; j++)
	for(k=0; k<=TWOPI/cell.theta; k++)
	  occupied[h][i][j][k] = 'n';
}

void initialize()
{
  int i; 

  initialize_occupied();
  nodetail = 1;
  node[0].previous = -1;
  node[0].action = -1;
  node[0].edge = -1;
  currentdistance = 0;
  currentnode = 0;
  for(i=0; i<MAXCOST; i++) sortedhead[i] = sortedtail[i] = -1;
  sortedhead[0] = sortedtail[0] = 0;
  node[0].nextsorted = -1;
}

/*************************************************************
*  Collision detection, goal detection, etc.
*************************************************************/

void set_occupied(i,p)
int i;
pose *p;
{
  occupied[i][(int) (p->x/cell.x)][(int) (p->y/cell.y)][(int) (p->theta/cell.theta)] = 'y';
}

int prev_occupied(j,p)
int j;
pose *p;
{
  return((j>= 0) && (occupied[j][(int) (p->x/cell.x)][(int) (p->y/cell.y)][(int) (p->theta/cell.theta)] == 'y'));
}

int in_goal_region(p)
pose *p;
{
  return(p->x>=goal.xmin && p->y>=goal.ymin && 
	 p->x<=goal.xmax && p->y<=goal.ymax &&
	 ((p->theta>=goal.thetamin && p->theta<=goal.thetamax) ||
	  (goal.thetamin>goal.thetamax && (p->theta<=goal.thetamax ||
					    p->theta>=goal.thetamin))));
}

int out_of_world(p)
pose *p;
{
  return(p->x<world.xmin || p->y<world.ymin ||
	 p->x>world.xmax || p->y>world.ymax);
}

int obs_collision(p)
pose *p;
{
  int i;
  for(i=0; i<world.numobstacles; i++)
    if(p->x>=world.obstacle[i].xmin && p->x<=world.obstacle[i].xmax &&
       p->y>=world.obstacle[i].ymin && p->y<=world.obstacle[i].ymax &&
       polygon_collision(p,i)) {
      return(TRUE);
    }
  return(FALSE);
}

int polygon_collision(p,i)
pose *p;
int i;
{
  float x1,y1,x2,y2,nx,ny,d,d2;
  int k;
  obs *obstaclep;

  obstaclep = &world.obstacle[i];
  k = obstaclep->numvertices - 1;
  x1 = p->x - obstaclep->xverts[k];
  y1 = p->y - obstaclep->yverts[k];
  for(k=0; k<obstaclep->numvertices; k++) {
    x2 = p->x - obstaclep->xverts[k];
    y2 = p->y - obstaclep->yverts[k];
    nx = obstaclep->nx[k];
    ny = obstaclep->ny[k];
    if(cross_product(nx,ny,x1,y1)<=0) {
      d2 = length_squared(x1,y1);
      if (d2<=obs_growth_squared)
	return(TRUE);
    }
    else if(cross_product(nx,ny,x2,y2)>=0) {
      d2 = length_squared(x2,y2);
      if (d2<=obs_growth_squared)
	return(TRUE);
    }
    else {
      d = fabs(dot_product(nx,ny,x1,y1)); /* normal could dot with either */
      if (d<=obs_growth)
	return(TRUE);
    }
    x1 = x2; y1 = y2;
  }
  return(FALSE);
}

/*************************************************************
*  File input, world setup
*************************************************************/

void calculate_controls(changeintheta)
float changeintheta;
{
  float arclength,vx,vy,omega,rx,ry,d,endang,finalx,finaly;
  int i,j;

  printf("\nIntegration steps:\n");
  printf("          Distance   Angle   Rotation\n");
  fscanf(infile,"%f",&arclength);
  fscanf(infile,"%d",&controls.edges);
  for(i=0; i<controls.edges; i++) {
    fscanf(infile,"%d",&controls.number[i]);
    if(controls.number[i]>0)
      printf("Edge %d\n");
    for(j=0; j<controls.number[i]; j++) {
      fscanf(infile,"%f %f %f",&vx,&vy,&omega);
      if(omega == 0) {
        controls.direction[i][j].r = arclength;
        controls.direction[i][j].dtheta = 0;
        controls.direction[i][j].alpha = atan2(vy,vx);}
      else {
        rx = -vy/omega; ry = vx/omega;
        d = length(rx,ry);
        controls.direction[i][j].dtheta = (arclength*mysignum(omega)/d);
	if(controls.direction[i][j].dtheta>changeintheta)
	  controls.direction[i][j].dtheta=changeintheta;
	else if(controls.direction[i][j].dtheta<(-1.0*changeintheta))
	  controls.direction[i][j].dtheta = -1.0*changeintheta;
        endang = controls.direction[i][j].dtheta+atan2(-ry,-rx);
        finalx = rx+d*cos(endang);
        finaly = ry+d*sin(endang);
        controls.direction[i][j].r = length(finalx,finaly);
        controls.direction[i][j].alpha = atan2(finaly,finalx);
      }
      printf("          %8.3f  %6.3f   %8.3f\n",controls.direction[i][j].r,controls.direction[i][j].alpha,controls.direction[i][j].dtheta); 
    }
  }
}

void find_obstacle_min_max()
{
  float xmin,xmax,ymin,ymax,x,y;
  int i,j;

  for(i=0; i<world.numobstacles; i++) {
    xmin = ymin = 10000;
    xmax = ymax = -100;
    for(j=0; j<world.obstacle[i].numvertices; j++) {
      x=world.obstacle[i].xverts[j];
      y=world.obstacle[i].yverts[j];
      if(x<xmin) xmin=x;
      if(x>xmax) xmax=x;
      if(y<ymin) ymin=y;
      if(y>ymax) ymax=y;
    }
    world.obstacle[i].xmin=xmin-obs_growth;
    world.obstacle[i].xmax=xmax+obs_growth;
    world.obstacle[i].ymin=ymin-obs_growth;
    world.obstacle[i].ymax=ymax+obs_growth;
  }
}
      
float find_obstacle_growth()   
{
  float dmax=0.0,d,dx,dy,dtheta,newx,newy;
  int h,i,j,k;

  for(h=0; h<controls.edges; h++)
    for(i=0; i<controls.number[h]; i++) {
      dx = controls.direction[h][i].r*cos(controls.direction[h][i].alpha);
      dy = controls.direction[h][i].r*sin(controls.direction[h][i].alpha);
      dtheta = controls.direction[h][i].dtheta;
      for(j=0; j<robot.numobjects; j++)
        for(k=0; k<robot.object[j].numvertices; k++) {
	  newx = dx+robot.object[j].xverts[k]*cos(dtheta) -
	    robot.object[j].yverts[k] * sin(dtheta);
	  newy = dy+robot.object[j].xverts[k]*sin(dtheta) +
	    robot.object[j].yverts[k] * cos(dtheta);
	  d=length(newx,newy);
/*	  d=length(robot.object[j].yverts[k],robot.object[j].xverts[k]); */
/* 
 * substitute this for previous line if you want tighter paths; in this
 * case, it just checks that each configuration is free, not all
 * possible motions from that configuration. 
 */
	  if(d>dmax) dmax=d; }
    }
  return(dmax);
}

void grow_obstacles()
{
  int i,j;
  float xp,yp,x,y,v1x,v1y,nx,ny,d;

  obs_growth = find_obstacle_growth();
  printf("Radius of the bounding disk:  %6.2f.\n",obs_growth);
  obs_growth_squared = obs_growth*obs_growth;
  world.xmin += obs_growth; world.ymin += obs_growth;
  world.xmax += -obs_growth; world.ymax += -obs_growth;
  for(i=0; i<world.numobstacles; i++) {
    for(j=0; j<world.obstacle[i].numvertices; j++) {
      if(j==0) {
	xp = world.obstacle[i].xverts[world.obstacle[i].numvertices-1];
	yp = world.obstacle[i].yverts[world.obstacle[i].numvertices-1];
      }
      else {
	xp = world.obstacle[i].xverts[j-1];
	yp = world.obstacle[i].yverts[j-1];
      }
      x = world.obstacle[i].xverts[j];
      y = world.obstacle[i].yverts[j];
      v1x = x-xp; v1y = y-yp;
      nx = v1y; ny = -v1x;
      d = length(nx,ny);
      nx = nx/d; ny = ny/d;
      world.obstacle[i].nx[j] = nx;
      world.obstacle[i].ny[j] = ny;
    }
  }
  find_obstacle_min_max();
}

void read_problem_file()
{
  int i,j;
  float dx,dy,dtheta;

  fscanf(infile,"%f %f %f %f",&world.xmin,&world.xmax,&world.ymin,&world.ymax);
  fscanf(infile,"%d",&robot.numobjects);
  for(i=0; i<robot.numobjects; i++) {
    fscanf(infile,"%d",&robot.object[i].numvertices);
    for(j=0; j<robot.object[i].numvertices; j++)
      fscanf(infile,"%f %f",&robot.object[i].xverts[j],
	     &robot.object[i].yverts[j]);
  }
  fscanf(infile,"%d",&world.numobstacles);
  for(i=0; i<world.numobstacles; i++) {
    fscanf(infile,"%d",&world.obstacle[i].numvertices);
    for(j=0; j<world.obstacle[i].numvertices; j++) {
      fscanf(infile,"%f %f",&world.obstacle[i].xverts[j],&world.obstacle[i].yverts[j]);
    }
  }
  fscanf(infile,"%f %f %f",&node[0].p.x,&node[0].p.y,&node[0].p.theta);
  fscanf(infile,"%f %f %f",&goal.xmin,&goal.ymin,&goal.thetamin);
  fscanf(infile,"%f %f %f",&dx,&dy,&dtheta);
  goal.xmax = goal.xmin + dx; goal.ymax = goal.ymin + dy;
  goal.thetamax = actual_theta(goal.thetamin + dtheta);
  goal.xmin = goal.xmin - dx; goal.ymin = goal.ymin - dy;
  goal.thetamin = actual_theta(goal.thetamin - dtheta);
  calculate_controls(1.99*dtheta);
  fscanf(infile,"%f %f %f",&cell.x,&cell.y,&cell.theta);
  fscanf(infile,"%d %d %d %d",&pushcost,&actionswitchcost,&edgeswitchcost,&maxcost);
  if (maxcost>MAXCOST) maxcost = MAXCOST;
  fclose(infile);
}

void check_inputs()
{
  if(out_of_world(&node[0].p) || obs_collision(&node[0].p)) {
    printf("Error:  start configuration is in collision!\n");
    exit(1);
  }
  if((world.xmax/cell.x)>=XCELLS) {
    printf("Warning:  X cell size %4.1f too small.\n",cell.x);
    printf("          Choose size >= (%6.1f / %d = %5.2f).\n",
	   world.xmax,XCELLS,world.xmax/XCELLS);
  }
  if((world.ymax/cell.y)>=YCELLS) {
    printf("Warning:  Y cell size %4.1f too small.\n",cell.y);
    printf("          Choose size >= (%6.1f / %d = %5.2f).\n",
	   world.ymax,YCELLS,world.ymax/YCELLS);
  }
  if((TWOPI/cell.theta)>=THETACELLS) {
    printf("Warning:  THETA cell size %5.3f too small.\n",cell.theta);
    printf("          Choose size >= (%5.3f / %d = %5.3f).\n",
	   TWOPI,THETACELLS,TWOPI/THETACELLS);
  }
}

/*************************************************************
*  Routines specific to writing an Adept program in V++.
*************************************************************/

float rad_to_deg(ang)
float ang;
{
  return(ang*57.2958);
}

float angle_conv(prev,cur)
float prev,cur;
{
  float plus,minus;
  plus = cur + 360.0; minus = cur - 360.0;
  if (fabs(plus-prev)<fabs(cur-prev)) return(plus);
  if (fabs(minus-prev)<fabs(cur-prev)) return(minus);
  return(cur);
}

float angle_in_bounds(theta)
float theta;
{
  float temp = theta;
  while (temp < -180) temp += 360.0;
  while (temp > 180) temp -= 360.0;
  return temp;
}

float tool_rotation(x1, y1, x2, y2)
float x1, y1, x2, y2;
{
  float rot;
  rot = rad_to_deg( atan2((y2-y1),(x2-x1)));
  /* now make the transform shift */
  rot -= 90.0;
  rot = angle_in_bounds(rot);
}

float tool_offset(xa,ya,xb,yb)
float xa,ya,xb,yb;
{
  /*float dis, normalx, normaly, off;
  dis = hypot(xb-xa, yb-ya);
  normalx = (xb-xa)/dis;
  normaly = (yb-ya)/dis;
  off = (fabs( dot_product(xa,ya,normalx,normaly)));
  return(off); */

  return fabs(hypot(xa, ya) * sin(atan2(yb-ya,xb-xa) - atan2(-ya, -xa)));
}

void write_adept_file(count)
int count;
{
  FILE *program,*header,*trailer;
  char str[100];
  int index,i,j;
  float prevedge;	
  float xpos[400],ypos[400],theta[400];
  int edgechange[400];
  int nowedge[400];
  float xa,xb,ya,yb;

  header = fopen("prog.header","r");
  program = fopen("plan.pg","w");
  while(fgets(str,100,header) != NULL) {
    fprintf(program,"%s",str);
  }
  fclose(header);
  index = currentnode;
  fprintf(program,"  numpos = %d\n",count);
  fprintf(program,"  offset = %f\n", TOOLOFFSET);
  fprintf(program,"  backup = %f\n", BACKUP);
  prevedge = node[index].edge;
  i = count;
  do {
    xpos[i] = node[index].p.x;
    ypos[i] = node[index].p.y;
    theta[i] = rad_to_deg(node[index].p.theta); 
    if (prevedge != node[index].edge) edgechange[i+1] = 1;
    else edgechange[i+1] = 0;
    nowedge[i] = node[index].edge;
    prevedge = node[index].edge;
    index = node[index].previous;
    i--;
  } while (index!=-1);

  /* NEW STUFF!!! to adjust and only push from one side of tool */
  for (j=0; j < (robot.object[0].numvertices - 1 ); j++) {
    xa = robot.object[0].xverts[j];
    ya = robot.object[0].yverts[j];
    xb = robot.object[0].xverts[j+1];
    yb = robot.object[0].yverts[j+1];
    controls.tool_rotation[j] = tool_rotation(xa,ya,xb,yb);
    controls.tool_offset[j] = tool_offset(xa,ya,xb,yb);
  }  
  xa = robot.object[0].xverts[j];
  ya = robot.object[0].yverts[j];
  xb = robot.object[0].xverts[0];
  yb = robot.object[0].yverts[0];
  
  controls.tool_rotation[j] = tool_rotation(xa,ya,xb,yb);
  controls.tool_offset[j] = tool_offset(xa,ya,xb,yb);
  

  fprintf(program, "  SET fake.tool = TRANS(%7.3f + offset + backup,0,0,%7.3f,0,0)\n",
	 controls.tool_offset[nowedge[2]], controls.tool_rotation[nowedge[2]]);  
  fprintf(program, "  SET hand.tool = TRANS(%7.3f + offset,0,0,%7.3f,0,0)\n", 
	  controls.tool_offset[nowedge[2]], controls.tool_rotation[nowedge[2]]);
  fprintf(program, "  TOOL fake.tool\n");

  if (theta[1]>=0) 
    fprintf(program,"  SET pos = TRANS(%7.3f,%7.3f,0,0,180,-%6.2f)\n",
  	    xpos[1],ypos[1],theta[1]);
  else fprintf(program,"  SET pos = TRANS(%7.3f,%7.3f,0,0,180,%6.2f)\n",
	       xpos[1],ypos[1],fabs(theta[1]));
  fprintf(program,"  APPRO pos,above\n");
  fprintf(program,"  MOVES pos\n");
  fprintf(program,"  BREAK\n");
  fprintf(program,"  SPEED 5 ALWAYS\n");
  fprintf(program,"  TOOL hand.tool\n");
  fprintf(program,"  MOVES pos\n");
  edgechange[2] = 0;
  for (i = 2; i<=count; i++) {
    if (edgechange[i]) {
      /* actions for edge change */    
      fprintf(program,"  TOOL fake.tool\n");  /* back off in x direction */
      fprintf(program,"  MOVES pos\n");
      fprintf(program,"  BREAK\n");
      fprintf(program,"  SPEED 100 ALWAYS\n"); /* warp speed */
      fprintf(program,"  DEPARTS above\n");   /* back off in z direction */
      fprintf(program,"  SET fake.tool = TRANS(%7.3f + offset + backup,0,0,%7.3f,0,0)\n",
	      controls.tool_offset[nowedge[i]], controls.tool_rotation[nowedge[i]]);  
      fprintf(program,"  SET hand.tool = TRANS(%7.3f + offset,0,0,%7.3f,0,0)\n", 
	      controls.tool_offset[nowedge[i]], controls.tool_rotation[nowedge[i]]);
      fprintf(program,"  TOOL fake.tool\n");

      fprintf(program,"  APPRO pos,above\n");
      fprintf(program,"  BREAK\n");
      fprintf(program,"  MOVES pos\n");
      fprintf(program,"  BREAK\n");
      fprintf(program,"  SPEED 5 ALWAYS\n");
      fprintf(program,"  TOOL hand.tool\n");
      fprintf(program,"  MOVES pos\n");
    }
    theta[i] = angle_conv(theta[i-1],theta[i]);
    if (theta[i]>=0) {
      fprintf(program,"      CALL zerodegrees\n");
      fprintf(program,"  SET pos = TRANS(%7.3f,%7.3f,0,0,180,-%6.2f)\n",
	      xpos[i],ypos[i],theta[i]);
    }
    else {  
      fprintf(program,"          CALL zerodegrees\n");
      fprintf(program,"  SET pos = TRANS(%7.3f,%7.3f,0,0,180,%6.2f)\n",
	      xpos[i],ypos[i],fabs(theta[i]));
    }
    fprintf(program, "  MOVE pos\n");
  }
  trailer = fopen("prog.trailer","r");
  while(fgets(str,100,trailer) != NULL) {
    fprintf(program,"%s",str);
  }
  fclose(trailer);
  fclose(program);
}

/*************************************************************
*  Success!
*************************************************************/

void report_success()
{
  FILE *pathp,*controlp;
  int index,count = -1;

  printf("\nSuccess at node %d, configuration %f %f %f.\n",currentnode,
	 node[currentnode].p.x,node[currentnode].p.y,
	 node[currentnode].p.theta);
  printf("Solution found; being written to file.\n");
  printf("Total cost of the path: %d\n",currentdistance);
  pathp = fopen(PATHOUT,"w");
  controlp = fopen(CONTROLOUT,"w");
  index = currentnode;
  do {
    count++;
    fprintf(pathp,"%10.5f %10.5f %5.3f %d\n",
	    node[index].p.x,node[index].p.y,node[index].p.theta,node[index].edge);
    fprintf(controlp,"%d %d\n",node[index].edge,node[index].action);
    index = node[index].previous;
  } while ((index!=-1) && (count<500));
  printf("\nNumber of pushing steps: %d\n",count);
  fclose(pathp);
  fclose(controlp);
  if (Adept) write_adept_file(count+1); 
}

/*********************************************************
*  Failure   :(
**********************************************************/
void report_failure() {
  printf("\nSorry, no solution found.\n");
}

  
/*************************************************************
*  Search
*************************************************************/

void find_potential_pose(pnew,pold,c)
pose *pnew,*pold;
control *c;
{
  float trans_angle;

  trans_angle = pold->theta + c->alpha;
  pnew->x = pold->x + c->r*cos(trans_angle);
  pnew->y = pold->y + c->r*sin(trans_angle);
  pnew->theta = pold->theta + c->dtheta;
}

void find_new_pose(pnew,pold,c)
pose *pnew,*pold;
control *c;
{
  find_potential_pose(pnew,pold,c);
  fix_theta(pnew);
}

void expand_node(n)
int n;
{
  int i,j,newdistance;
  pose p;

  if(!prev_occupied(node[n].edge,&node[n].p)) {
    if(n!=0) set_occupied(node[n].edge,&node[n].p);
    for(i=0; i<controls.edges; i++) {
      for(j=0; j<controls.number[i]; j++) {
	if (nodetail<MAXNODES) {
          find_new_pose(&p,&node[n].p,&controls.direction[i][j]);
	  if(!out_of_world(&p) && !prev_occupied(i,&p) &&
	     !obs_collision(&p)) {
    	    newdistance = currentdistance + pushcost;
	    if (n != 0) {
  	      if(node[n].edge != i) newdistance+=edgeswitchcost+actionswitchcost;
	      else if(node[n].action != j) newdistance+=actionswitchcost;
	    }
	    if(newdistance<maxcost) {
	      if (sortedtail[newdistance]<0) {
	        sortedhead[newdistance] = sortedtail[newdistance] = nodetail;
	      }
	      else {
	        node[sortedtail[newdistance]].nextsorted = nodetail;
	        sortedtail[newdistance] = nodetail;
	      }
              node[nodetail].action = j;
	      node[nodetail].edge = i;
              node[nodetail].previous = n;
	      node[nodetail].nextsorted = -1;
              node[nodetail].p.x = p.x;
              node[nodetail].p.y = p.y;
              node[nodetail].p.theta = p.theta;
	      nodetail++;
	    }
	  }
	}
      }
    }
  }
}

void perform_search()
{
  int success = FALSE, done = FALSE;

  while(!done) {
    if(in_goal_region(&node[currentnode].p)) {
      success = done = TRUE;
    }
    else {
      expand_node(currentnode);
      if((currentnode=node[currentnode].nextsorted)<0) {
	while(currentnode<0 && currentdistance<maxcost) {
	  currentdistance+=1;
	  currentnode = sortedhead[currentdistance];
	}
	if(currentdistance==maxcost) done = TRUE;
      }
    }
  }
  if (success) report_success();
  else report_failure();
  printf("Total distance searched: %d.\n",currentdistance);
  printf("Number of search nodes created:  %d\n",nodetail);
}

/*************************************************************
*  Main
*************************************************************/

main(argc,argv)
int argc;
char *argv[];
{
  initialize();
  if ((argc == 1) && ((infile = fopen(INFILE,"r")) == NULL)) { 
    printf("Error:  input file %s not found.\n",INFILE); 
    exit(1); 
  }  
  else if (argc == 2) { 
    if ( strcmp(argv[1],"-adept") == 0 ) { 
      Adept = 1; 
      if ((infile = fopen(INFILE,"r")) == NULL) { 
	printf("Error:  input file %s not found.\n",INFILE); 
	exit(1); 
      } 
    } else { 
      if ((infile = fopen(argv[1],"r")) == NULL) { 
	printf("Error:  input file %s not found.\n",argv[1]); 
	exit(1); 
      } 
    }
  }
  else if (argc == 3) { 
    if (strcmp(argv[1],"-adept")==0) { 
      Adept = 1; 
      if ((infile = fopen(argv[2],"r")) == NULL) { 
	printf("Error:  input file %s not found.\n",argv[2]); 
	exit(1);
      } 
    } else {
      printf("Usage:  %s [-adept] [problemfile].\n",argv[0]); 
      exit(1); 
    }
  }
  else if (argc > 3) { 
    printf("Usage:  %s [-adept] [problemfile].\n",argv[0]);
    exit(1); 
  } 
  read_problem_file();
  printf("File read in.\n");
  grow_obstacles();
  check_inputs();
  printf("Beginning search...\n"); 
  perform_search();  
}
