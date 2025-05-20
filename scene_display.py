""" A  set of functions to animate the output of the puzzle path planner program
"""


import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from matplotlib.animation import FuncAnimation
import os

# Helper to create a matplotlib polygon patch
def create_polygon(polygon_points, color='blue', alpha=1.0, linestyle='-'):
    return Polygon(polygon_points, closed=True, edgecolor=color, facecolor=color, alpha=alpha, linestyle=linestyle)

# Main function to plot and animate the scene
def plot_scene(start_pose, goal_pose, object_poses, obstacle_poses, dims, node_count,interval=1000):
    fig, ax = plt.subplots()
    ax.set_aspect('equal')
    smaller = max(dims[0], dims[2])
    larger = max(dims[1], dims[3])
    n = len(object_poses)
    outline = [[dims[0], dims[2]], [dims[1], dims[2]], [dims[1], dims[3]], [dims[0], dims[3]]]

    # Fix the axes of the display to a square using the min and max of the config-space axes
    ax.set_xlim(smaller, larger)
    ax.set_ylim(smaller, larger)

    # Draw static start and goal poses
    start_patch = create_polygon(start_pose, color='green', alpha=1)
    goal_patch = create_polygon(goal_pose, color='red', alpha=1)
    outline_patch = create_polygon(outline, color='black', alpha=0.1)
    ax.add_patch(start_patch)
    ax.add_patch(goal_patch)
    ax.add_patch(outline_patch)

    # Initialize main object
    obj_patch = create_polygon(object_poses[0], color='blue', alpha=1)
    ax.add_patch(obj_patch)

    # Make sure all frames have same number of obstacles
    num_obstacles = len(obstacle_poses[0])
    assert all(len(obstacles) == num_obstacles for obstacles in obstacle_poses), \
        "Each frame must have the same number of obstacles"

    # Initialize obstacle patches
    obstacle_patches = []
    for obs_poly in obstacle_poses[0]:
        patch = create_polygon(obs_poly, color='black', alpha=1)
        ax.add_patch(patch)
        obstacle_patches.append(patch)

    # Animation update function
    def update(frame):
        obj_patch.set_xy(object_poses[frame])
        for patch, new_pose in zip(obstacle_patches, obstacle_poses[frame]):
            patch.set_xy(new_pose)
        return [obj_patch] + obstacle_patches

    # Animate
    ani = FuncAnimation(fig, update, frames=len(object_poses), interval=interval, blit=True)
    label_text = "Nodes Searched: " + str(node_count) + " Steps to Reach Goal: " + str(n)

    # Save a gif of the annimation to the desktop
    # Note to future users: update the code with the file path to your desktop
    ani.save('C:\\Users\\johnk\\OneDrive\\Desktop\\scene_animation.gif', writer="pillow", fps=2)

    # Display the animation
    plt.title(label_text)
    plt.show()

#
# # --------------------------
# # Example usage:
#
# # Static start and goal polygon (e.g., a square)
# start_pose = [[-1, -1], [1, -1], [1, 1], [-1, 1]]
# goal_pose  = [[3, 3], [5, 3], [5, 5], [3, 5]]
#
# # Object poses across 5 frames (moves from start to goal)
# object_poses = [
#     [[-1, -1], [1, -1], [1, 1], [-1, 1]],
#     [[0, 0], [2, 0], [2, 2], [0, 2]],
#     [[1, 1], [3, 1], [3, 3], [1, 3]],
#     [[2, 2], [4, 2], [4, 4], [2, 4]],
#     [[3, 3], [5, 3], [5, 5], [3, 5]],
# ]
#
# # Two obstacles, each moving differently
# obstacle_poses = [
#     [  # Frame 0
#         [[4, -1], [6, -1], [6, 1], [4, 1]],
#         [[-4, -1], [-2, -1], [-2, 1], [-4, 1]],
#     ],
#     [  # Frame 1
#         [[3, 0], [5, 0], [5, 2], [3, 2]],
#         [[-3, 0], [-1, 0], [-1, 2], [-3, 2]],
#     ],
#     [  # Frame 2
#         [[2, 1], [4, 1], [4, 3], [2, 3]],
#         [[-2, 1], [0, 1], [0, 3], [-2, 3]],
#     ],
#     [  # Frame 3
#         [[1, 2], [3, 2], [3, 4], [1, 4]],
#         [[-1, 2], [1, 2], [1, 4], [-1, 4]],
#     ],
#     [  # Frame 4
#         [[0, 3], [2, 3], [2, 5], [0, 5]],
#         [[0, 3], [2, 3], [2, 5], [0, 5]],
#     ],
# ]
#
# # Call the function
# plot_scene(start_pose, goal_pose, object_poses, obstacle_poses)
