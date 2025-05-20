# Mechanical_puzzles
Code to find and visualizes solutions to mechanical puzzles


This repository contains three python files path_planner, scene_display, and velo_finder. Users only need to interact with path_planner to define and solve mechanical puzzles, as it calls functions from the other two programs.

Before using these programs, users should read Mason and Lynch's Stable Pushing: Mechanics, Controlability, and Planning, as well as John Carey's summary of the planner which builds off of Masona and Lynch's work.

Within path_planner, users should define a puzzle to be solved in a main() function. Several example main functions are commented out in the program for reference. Users must define the following in the main functions to solve puzzles:

slider object
edges included in the slider
vertices of the slider
obstacles
edges to included in the obstacles  - should be different than those used in the slider, even if they are the same shape, since pushing velocities are determined by edge. If the user wants obstacles to be limited to translations, as is currently the case,
the user will need to define unique edges for use in the obstacle. Velocities for the edge (translations only for obstacles) are created within the Edge class when edges are associated with sliders or obstacles in the creation of an object
vertices to include in the obstacles
initial pose for the slider
goal pose for the slider
dimensions of the workspace: min, max, and step size for x, y, and theta
cost variables: max nodes, max node cost, and variables to determine to cost to come of a node
