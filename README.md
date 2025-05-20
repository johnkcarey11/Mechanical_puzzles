# Mechanical_puzzles
Code to find and visualizes solutions to mechanical puzzles


This repository contains three python files path_planner, scene_display, and velo_finder. Users only need to interact with path_planner to define and solve mechanical puzzles, as it calls functions from the other two programs.

Before using these programs, users should read Mason and Lynch's Stable Pushing: Mechanics, Controlability, and Planning, as well as John Carey's summary of the planner which builds off of Masona and Lynch's work.

Within path_planner, users should define a puzzle to be solved in a main() function. Several example main functions are commented out in the program for reference.

One key thing to note is that edges should be defined separately for the slider and obstacles. Velocities are associated with specific edges. If a users wants to have obstacles only move from translations, as is the case in the current implementation, the edges of the slider and obstacles must be defined separately. The initialization of a slider or obstacle object (if movable) calls functions within the Edge class to find velocities. The example main functions show clearly how different edges should be used for the slider and obstacles.
