""" Program to find solutions for user defined mechanical puzzles

    Users define the following puzzle specifications in the main function:
        Object, its start pose, vertices, and edges
        The goal pose and threshold (both have x, y, and theta component)
        Dimensions of the workspace (x and y limits and steps sizes)
        Obstacles, their start poses, vertices, and edges
        Arclength
        Cost parameters: cost multiples for rotations and obstacle moves
        Max nodes and max node cost

    See numerous example main functions defined at the bottom of the program.
    The main function should call the look_for_route function, which will either
    return the found path or "no path found". The plot_scene function will produce an
    animation of the route from the start pose to the goal pose if a path is found
"""


import numpy as np
from velo_finder import edge
from velo_finder import Slider
from velo_finder import Obstacle
import heapq
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
from matplotlib.animation import FuncAnimation
from scene_display import plot_scene
import os

##################### classes used in program #######################


class PriorityQueue:
    """ Implementation of a priority queue"""
    def __init__(self):
        self.heap = []

    def push(self, node):
        heapq.heappush(self.heap, node)

    def pop(self):
        return heapq.heappop(self.heap)

    def is_empty(self):
        return len(self.heap) == 0

    def peek(self):
        return self.heap[0] if not self.is_empty() else None


class Node:
    """class used for nodes in A* search for route

    Each iteration of Node will have a pose for the object and poses for each of the obstacles
    """


    def __init__(self, pose):
        self.pose = pose
        self.act_to_reach = None  # variable is not used in program
        self.parent = None
        self.cost = 0
        self.cost_to_come = 0
        self.title = ""
        self.ob_poses = []

    def __lt__(self, other):
        return self.cost < other.cost

##################### collision functions #######################

def collision_free(shape, pose, obstacles, o_poses, shape_and_ob=False):
    """ Evaluates if a given shape at a pose is in collision with a set of obstacles

    Inputs:
        shape:          instance of the class Shape or Obstacle
        pose:           1x3 vector (x,y,theta) representing shape's location
        obstacles:      nx1 list of instances from the class Obstacle
        obstacle_poses: nx3 array of pose vectors associated with obstacles
    Output:
        boolean of whether shape and obstacles are in collision
    """
    # evaluate intersection points edge by edge
    for edge in shape.edges:
        trans_verts = np.zeros((2,2))

        # find the vertices of the edge in the world frame
        for i in range(2):
            vert = np.array([edge.coords[i][0], edge.coords[i][1], 1])
            trans_vert = robot2global(vert, pose)
            trans_verts[0,i] = trans_vert[0]
            trans_verts[1,i] = trans_vert[1]

        # find the min and max of the vertices in x and y in world frame
        x_min = np.min(trans_verts[0, :])
        x_max = np.max(trans_verts[0, :])
        y_min = np.min(trans_verts[1, :])
        y_max = np.max(trans_verts[1, :])


        # find the equation of the line made by the edge in the world frame
        line = lineBetweenPoints(trans_verts[:,0], trans_verts[:,1])

        # evaluate if each obstacle's edges are in collision with the object's edges
        for j, obstacle in enumerate(obstacles):
            ob_pose = o_poses[j]

            for o_edge in obstacle.edges:
                ob_verts = np.zeros((2,2))

                # find the vertices of the edge in the world frame
                for k in range(2):
                    o_vert = np.array([o_edge.coords[k][0], o_edge.coords[k][1], 1])
                    ob_vert = robot2global(o_vert, ob_pose)
                    ob_verts[0,k] = ob_vert[0]
                    ob_verts[1,k] = ob_vert[1]

                # find the min and max of the vertices in x and y in world frame
                ob_x_min = np.min(ob_verts[0, :])
                ob_x_max = np.max(ob_verts[0, :])
                ob_y_min = np.min(ob_verts[1, :])
                ob_y_max = np.max(ob_verts[1, :])

                # find the equation of the line made by the edge in the world frame
                ob_line = lineBetweenPoints(ob_verts[:, 0], ob_verts[:, 1])

                # skip if both lines are vertical or horizontal
                if (line[0] == 0 and ob_line[0] == 0) or (line[1] == 0 and ob_line[1] == 0):
                    continue
                else:
                    # find the intersection point between the lines
                    intersect = line_intersection(line, ob_line)
                    x = intersect[0]
                    y = intersect[1]
                    if x is None:
                        continue

                    # check if the intersection point is within the limits of the edge
                    elif x_min <= x <= x_max and ob_x_min <= x <= ob_x_max and y_min <= y <= y_max and ob_y_min <= y <= ob_y_max:
                        return False
    return True


def lineBetweenPoints(p1, p2):
    """ returns an equation between two points in the form ay + bx = c"""

    x1 = p1[0]
    y1 = p1[1]
    x2 = p2[0]
    y2 = p2[1]
    if x1 == x2:
        return [0, 1, x1]
    elif y1 == y2:
        return [1, 0, y1]
    else:
        m = (y2-y1)/(x2-x1)
        c = y1 - m*x1
        a = 1
        b = -1*m
        return [a, b, c]

def line_intersection(l1, l2):
    """ returns the intersection point for lines defined as ay + bx = c """
    a = l1[0]
    b = l1[1]
    c = l1[2]
    d = l2[0]
    f = l2[1]
    g = l2[2]
    deno = a * f - d * b
    if deno == 0:
        x = None
        y = None

    elif a == 0:
        x = c / b
        y = (g - f * x) / d
    elif d == 0:
        x = g / f
        y = (c - b * x) / a
    elif b == 0:
        y = c / a
        x = (g - d * y) / f
    elif f == 0:
        y = g / d
        x = (c - a * y) / b
    else:
        x = (g * a - d * c) / (a * f - d * b)
        y = (c - b * x) / a
    return x, y

##################### dynamics functions #######################

def calc_controls(velo, arclength):
    """function to find the controls needed to update the pose based on a given velo and arclength

    ***adapted from Mason and Lynch's code***

    """
    omega = velo[2]
    vx=velo[0]
    vy=velo[1]

    if omega == 0:
        r = arclength
        dtheta = 0
        alpha = np.atan2(vy,vx)
        return (r, alpha, dtheta)
    else:
        rx = -vy/omega
        ry = vx/omega
        base_r = np.array([rx, ry])
        d = np.linalg.norm(base_r)
        dtheta = arclength/d

    # calc the end ang
    end_ang = dtheta + np.atan2(-ry,-rx)

    # calc finalx and final y
    finalx = rx+d*(np.cos(end_ang))
    finaly = ry + d * (np.sin(end_ang))

    # calc r for control
    final_r = np.array([finalx, finaly])
    r = np.linalg.norm(final_r)

    # calc alpha for control
    alpha = np.atan2(finaly, finalx)
    alpha_d = np.rad2deg(alpha)

    return (r, alpha, dtheta)

def calc_new_pose(pose, control):
    """ function to find the new pose resulting from a pose and control

    ***adapted from Mason and Lynch's code***

    """
    trans_angle = pose[2] + control[1]
    x = pose[0] + control[0]*np.cos(trans_angle)
    y = pose[1] + control[0] * np.sin(trans_angle)
    theta = pose[2] + control[2]
    return np.array([x,y,theta])


##################### simple functions for loop execution #######################

def in_goal_region(pose, goal_pose, goal_errs):
    """ evaluates if a given pose is within the goal threshold of the goal pose"""


    if goal_pose[0]-goal_errs[0] <= pose[0] and  pose[0] <= goal_pose[0]+goal_errs[0]:
        if goal_pose[1] - goal_errs[1] <= pose[1] and pose[1] <= goal_pose[1]+goal_errs[1]:
            if goal_pose[2] - goal_errs[2] <= pose[2] and pose[2] <= goal_pose[2]+goal_errs[2]:
                return True
    return False

def within_bounds(pose, x_min, x_max, y_min, y_max,max_rad):
    """evaluated if object is within the config space of the problem
    Inputs:
        pose:       pose of the shape
        max_rad:    longest distance from center of object to a vertex of the shape
        all others: x,y limits of the config space
    Outputs:
        boolean of whether object is within bounds of config space

    """
    if x_min < (pose[0]-max_rad) and (pose[0]+max_rad) < x_max:
        if y_min < (pose[1]-max_rad) and (pose[1]+max_rad) < y_max:
            return True
    return False

def robot2global(point, pose):
    """Converts a point from the body frame of a shape to the frame of the config space"""

    tx = pose[0]
    ty = pose[1]
    theta = pose[2]
    T = np.array([[np.cos(theta), -np.sin(theta), tx],
                  [np.sin(theta), np.cos(theta), ty],
                    [0, 0, 1]])
    x_r = np.array([point[0], point[1], 1])
    x_w = T@x_r
    return x_w[0], x_w[1]

def calc_dist(goal_pose, new_pose):
    " Calculated the Euclidean distance points two points"

    curr_x_diff = goal_pose[0] - new_pose[0]
    curr_y_diff = goal_pose[1] - new_pose[1]
    curr_dist = np.linalg.norm([curr_x_diff, curr_y_diff])
    return curr_dist

def look_for_route(init_pose, shape, obstacles, dimensions, goal_pose, goal_errs, cost_details, arclength, o_poses):
    """ function which executes A*-based search for an object from a start pose to a goal pose

    Inputs:
        init_pose       initial pose of the shape to move to goal pose
        shape           instance of the slider class
        obstacles       array of instances of obstacle class
        dimensions      1x9 array containing min, max, and step size for x, y, and theta
        goal_pose       goal pose for the shape object (a slider)
        goal_errors     threshold to goal pose to terminate function (x,y, and theta thresholds)
        cost_details    1x5 array with max allowed path cost, max node count, cost multiple for rotations,
                        threshold (as a percentage) for distance to goal when rot multiplier no longer applies
                        to path cost, and cost multiplier for moving obstacles
        arclength       distance object and obstacles move on translations and translations plus rotations
        o_poses         initial poses for obstacles
    Output
        if path is found, returns last node in path near goal pose and the count of nodes added to OPEN in the search
        if path not found, returns None
    """


    x_min = dimensions[0]
    x_max = dimensions[1]
    x_step = dimensions[2]
    x_diff = x_max-x_min
    y_min = dimensions[3]
    y_max = dimensions[4]
    y_step = dimensions[5]
    y_diff = y_max - y_min
    a_min = dimensions[6]
    a_max = dimensions[7]
    a_step = dimensions[8]
    a_vals = np.arange(a_min + (a_step / 2), a_max, a_step)
    max_dist = np.linalg.norm([x_diff, y_diff])

    # calculate the x,y values for discretization (used to check if nodes already visited)
    x_vals = np.arange(x_min + (x_step / 2), x_max, x_step)
    y_vals = np.arange(y_min + (y_step / 2), y_max, y_step)

    # list out the cost details
    max_cost = cost_details[0]
    max_nodes = cost_details[1]
    rot_mult = cost_details[2]
    huer_thres = cost_details[3]
    ob_mult = cost_details[4]

    # initialize Open and Closed for A*
    Open = PriorityQueue()
    Open_nodes = {}
    Closed = {}

    # initialize the first node and find the title
    q_init = Node(init_pose)
    x_ind = int(init_pose[0] // x_step)
    nearest_x = x_vals[x_ind]
    y_ind = int(init_pose[1] // y_step)
    nearest_y = y_vals[y_ind]
    t_ind = int(init_pose[2] // a_step)
    nearest_t = a_vals[t_ind]
    pose_title = str(nearest_x) + "," + str(nearest_y) + "," + str(nearest_t)
    q_init.title = pose_title
    q_init.ob_poses = o_poses[:]

    node_count = 1

    # add the first node into the Open PQ
    Open.push(q_init)

    while not Open.is_empty() and node_count < max_nodes:

        # remove the lowest cost config from Open
        q = Open.pop()
        #print("Pose: ", q.pose)
        #print("Ob Poses: ", q.ob_poses)

        # check if lowest-cost fig is in goal region
        if in_goal_region(q.pose, goal_pose, goal_errs):
            print("Node Count: ", node_count)
            return q, node_count
        else:
            dist_to_goal = calc_dist(goal_pose, q.pose)
            Closed[q.title] = 1 # add the node to closed

            # evaluate the new nodes achievable from each edge
            for e in shape.edges:
                if e.pushable:

                    # evaluate each pure translation and translation+rotation
                    for velo in e.velos:
                        control = calc_controls(velo, arclength)
                        new_pose = calc_new_pose(q.pose, control)

                        # correct the angle to be within 2pi
                        new_angle = new_pose[2] % 2*np.pi
                        new_pose[2] = new_angle

                        # cost to come for trans+rot away from goal pose
                        if velo[2] != 0 and dist_to_goal > max_dist*huer_thres:
                            cost_to_come = int(q.cost_to_come + arclength*rot_mult)
                        else:
                            # cost to come for pure translations or trans+rot within thres of goal
                            cost_to_come = int(q.cost_to_come + arclength)

                        # calculate the estimate of the cost to go using Euclidean distance as the heuristic
                        h = int(calc_dist(goal_pose, new_pose))

                        # check if the new pose is within the configuration space
                        if within_bounds(new_pose, x_min, x_max, y_min, y_max,shape.max_rad) and cost_to_come < max_cost:

                            x_ind = int(new_pose[0] // x_step)
                            nearest_x = x_vals[x_ind]
                            y_ind = int(new_pose[1] // y_step)
                            nearest_y = y_vals[y_ind]
                            t_ind = int(new_pose[2] // a_step)
                            nearest_t = a_vals[t_ind]

                            # determine the new pose using the discritized new pose
                            new_pose_title = str(nearest_x) + "," + str(nearest_y) + "," + str(nearest_t)
                            for pose in q.ob_poses:
                                x_ind = int(pose[0] // x_step)
                                nearest_x = x_vals[x_ind]
                                y_ind = int(pose[1] // y_step)
                                nearest_y = y_vals[y_ind]
                                t_ind = int(pose[2] // a_step)
                                nearest_t = a_vals[t_ind]
                                # add the discrete obstacle poses to the new pose title
                                new_pose_title = new_pose_title + str(nearest_x) + "," + str(nearest_y) + "," + str(nearest_t)

                            #
                            if new_pose_title not in Closed and (new_pose_title not in Open_nodes or Open_nodes[new_pose_title] > (h + cost_to_come)):

                                if collision_free(shape, new_pose, obstacles, q.ob_poses,True):

                                    # populate the variable values for the new node and add to the Open PQ
                                    q_new = Node(new_pose)
                                    node_count += 1
                                    if node_count % 10000 == 0:
                                        print("node Count: ", node_count)
                                    q_new.parent = q
                                    q_new.cost_to_come = cost_to_come
                                    q_new.cost = cost_to_come + h
                                    q_new.ob_poses = q.ob_poses[:]
                                    Open.push(q_new)
                                    Open_nodes[new_pose_title] = q.cost

            #####################################################################################
            # search of edges where obstacles move instead of the slider
            # code follows very similar logic to above edge searches

            for j, ob in enumerate(obstacles):
                if ob.moveable:
                    for e in ob.edges:
                        if e.pushable:
                            #print("Ob Velos: ",e.velos)
                            for velo in e.velos:
                                control = calc_controls(velo, arclength)
                                ob_pose = q.ob_poses[j]
                                new_pose = calc_new_pose(ob_pose, control)
                                new_angle = new_pose[2] % 2*np.pi
                                new_pose[2] = new_angle

                                # calculate the cost to come
                                cost_to_come = int(q.cost_to_come + arclength*ob_mult)

                                h = int(calc_dist(goal_pose, q.pose))

                                if within_bounds(new_pose, x_min, x_max, y_min, y_max,ob.max_rad)==True and cost_to_come < max_cost:

                                    x_ind = int(q.pose[0] // x_step)
                                    nearest_x = x_vals[x_ind]
                                    y_ind = int(q.pose[1] // y_step)
                                    nearest_y = y_vals[y_ind]
                                    t_ind = int(q.pose[2] // a_step)
                                    nearest_t = a_vals[t_ind]
                                    new_pose_title = str(nearest_x) + "," + str(nearest_y) + "," + str(nearest_t) + ","

                                    temp_ob_poses = q.ob_poses[:]
                                    temp_ob_poses[j] = new_pose

                                    for pose in temp_ob_poses:
                                        x_ind = int(pose[0] // x_step)
                                        nearest_x = x_vals[x_ind]
                                        y_ind = int(pose[1] // y_step)
                                        nearest_y = y_vals[y_ind]
                                        t_ind = int(pose[2] // a_step)
                                        nearest_t = a_vals[t_ind]
                                        new_pose_title = new_pose_title + str(nearest_x) + "," + str(
                                            nearest_y) + "," + str(nearest_t)

                                    if new_pose_title not in Closed and (new_pose_title not in Open_nodes or Open_nodes[new_pose_title] > (h + cost_to_come)):

                                        temp_obs = obstacles[0:j]+obstacles[j+1:]
                                        temp_poses = temp_ob_poses[0:j]+temp_ob_poses[j+1:]

                                        if collision_free(shape, q.pose, [ob], [new_pose]) and collision_free(ob, new_pose, temp_obs, temp_poses):

                                            q_new = Node(q.pose)
                                            q_new.parent = q
                                            q_new.cost_to_come = cost_to_come
                                            q_new.cost = cost_to_come + h
                                            q_new.ob_poses = temp_ob_poses

                                            Open.push(q_new)
                                            Open_nodes[new_pose_title] = q.cost

                                            node_count += 1
                                            if node_count % 10000 == 0:
                                                print("node Count: ", node_count)

    if Open.is_empty():
        print("Empty Queue")

    # return q, node_count
    return None



def find_global_vertices(object, pose):
    """function to find the vertices of an object (slider/obstacle) in the world frame"""
    global_verts = []
    for vert in object.vertices:
        new_vert = robot2global(vert, pose)
        global_verts.append(new_vert)
    return global_verts


def print_path(results, shape1, obstacles, init_pose, goal_pose, dims):
    """ function to setup inputs and call plot_scene function to animate the found path
        Inputs
            results     last node in path to goal pose
            shape1      instance of slider class
            obstacles   an array of instances of obstacle class
            init_pose   initial pose of the slider object
            goal pose   goal pose of the slider object
            dims        1x4 array containing the min and max for workspace for x and y

        Outputs
            If results is None, function will print no path found
            Otherwise, extract each step in the path, as well as the associated obstacle poses
            from results, adapt the output to meet the structure required by plot_scene, and call plot_scene

    """

    if results == None:
        print("No path found")
        return

    # walk from last pose to the first pose, extracting slider and obstacle poses
    else:
        print("Path Found")
        q = results[0]
        node_count = results[1]
        steps = []
        obstacle_poses = []
        while q.parent != None:
            steps.append(q.pose)
            obstacle_poses.append(q.ob_poses)
            q = q.parent

        steps.append(q.pose)
        obstacle_poses.append(q.ob_poses)

        n = len(steps)
        print("Num Steps: ", n)
        count = 0

    # find the vertices of the slider at the initial and final poses in the world frame
    init_verts = find_global_vertices(shape1, init_pose)
    goal_verts = find_global_vertices(shape1, goal_pose)
    object_verts = []
    obstacle_verts = []

    # for each step in the path, find the vertices of the slider and each obstacle in the world frame
    for i in range(n):
        verts = find_global_vertices(shape1, steps[-1-i])
        object_verts.append(verts)

        temp_obs_verts = []
        for j, ob in enumerate(obstacles):
            pose = obstacle_poses[-1-i][j]
            verts = find_global_vertices(ob, pose)
            temp_obs_verts.append(verts)
        obstacle_verts.append(temp_obs_verts)

    # create, display, and save gif on animation of path to goal pose
    plot_scene(init_verts, goal_verts, object_verts, obstacle_verts, dims,node_count)

# # Situation 1: One obstacle in a shoot-like path
# def main():
#
#     # enter desired grid coordinates
#     x_min= -0.2
#     x_max = 1.2
#     x_step = 0.1
#     y_min = 0
#     y_max = 4
#     y_step = 0.1
#     a_min = 0
#     a_max = np.pi*2
#     a_step = np.pi/32
#
#     dimensions = (x_min, x_max, x_step, y_min, y_max, y_step, a_min, a_max, a_step)
#     dims = (x_min, x_max, y_min, y_max)
#
#     # enter cost details
#     max_nodes = 2000000
#     max_cost = 50000
#     rot_mult = 10
#     huer_thres = 0.1
#     ob_mult = 100
#     cost_details = [max_cost, max_nodes, rot_mult, huer_thres, ob_mult]
#     arclength = 0.5
#
#     # enter initial and goal conditions
#     goal_pose = [0.5, 2, 0]
#     goal_errors = [0.1, 0.1, np.pi/16]
#     init_pose = [0.5, 0.5, 0]
#     pose2 = [0.5, 1.5, 0]
#
#
#     edge1 = edge([(-0.4, -0.4), (0.4,-0.4)], True)
#     edge2 = edge([(0.4, -0.4), (0.4, 0.4)], False)
#     edge3 = edge([(0.4, 0.4), (-0.4, 0.4)], False)
#     edge4 = edge([(-0.4, 0.4), (-0.4, -0.4)], False)
#     edges = [edge1, edge2, edge3, edge4]
#
#     edge5 = edge([(-0.4, -0.4), (0.4, -0.4)], True)
#     edge6 = edge([(0.4, -0.4), (0.4, 0.4)], False)
#     edge7 = edge([(0.4, 0.4), (-0.4, 0.4)], False)
#     edge8 = edge([(-0.4, 0.4), (-0.4, -0.4)], False)
#     ob_edges = [edge5, edge6, edge7, edge8]
#
#     vertices = [(-0.4, -0.4), (0.4,-0.4), (0.4, 0.4), (-0.4, 0.4)]
#
#     shape1 = Slider(0.4, vertices, 4, edges)
#     obj2 = Obstacle(vertices, 4, ob_edges, True)
#
#     obstacles = [obj2]
#     obstacle_poses = [pose2]
#
#     # will return the final node, which will be linked to all other relevant nodes
#     results = look_for_route(init_pose, shape1, obstacles, dimensions, goal_pose, goal_errors, cost_details, arclength, obstacle_poses)
#
#     print_path(results, shape1, obstacles, init_pose, goal_pose, dims)


# # # sitation 2: two obstacles in wider shoot-like path
def main():

    # enter desired grid coordinates
    x_min= -0.2
    x_max = 2.2
    x_step = 0.1
    y_min = -0.2
    y_max = 3.2
    y_step = 0.1
    a_min = 0
    a_max = np.pi*2
    a_step = np.pi/32

    # package dimension variables for look_for_path and print_path
    dimensions = (x_min, x_max, x_step, y_min, y_max, y_step, a_min, a_max, a_step)
    dims = (x_min, x_max, y_min, y_max)

    # enter cost details
    max_nodes = 2000000
    max_cost = 50000
    rot_mult = 10      # cost of executing translations + rotations
    huer_thres = 0.1   # dist (as % of radius of workspace) within goal to remove extra cost for rotations
    ob_mult = 2        # cost of moving obstacles
    cost_details = [max_cost, max_nodes, rot_mult, huer_thres, ob_mult]
    arclength = 0.5    # distance to move each step and cost of translations only

    # enter initial and goal conditions
    goal_pose = [0.5, 2.5, 0]
    goal_errors = [0.1, 0.1, np.pi/16]
    init_pose = [1.5, 0.5, 0]
    pose2 = [0.5, 1.5, 0]
    pose3 = [0.5, 2.5, 0]
    pose4 = [1.5, 1.5, 0]
    pose5 = [0.5, 0.5, 0]

    # edges for slider
    edge1 = edge([(-0.4, -0.4), (0.4,-0.4)], True)
    edge2 = edge([(0.4, -0.4), (0.4, 0.4)], True)
    edge3 = edge([(0.4, 0.4), (-0.4, 0.4)], True)
    edge4 = edge([(-0.4, 0.4), (-0.4, -0.4)], True)
    edges = [edge1, edge2, edge3, edge4]

    # edges for obstacles. Use diff edges for obstacles because edges get velocities assigned to them
    # want translations and trans+rot for slider
    # want only translations for obstacles
    edge5 = edge([(-0.4, -0.4), (0.4, -0.4)], True)
    edge6 = edge([(0.4, -0.4), (0.4, 0.4)], True)
    edge7 = edge([(0.4, 0.4), (-0.4, 0.4)], True)
    edge8 = edge([(-0.4, 0.4), (-0.4, -0.4)], True)
    ob_edges = [edge5, edge6, edge7, edge8]

    vertices = [(-0.4, -0.4), (0.4,-0.4), (0.4, 0.4), (-0.4, 0.4)]

    shape1 = Slider(0.4, vertices, 4, edges)



    obj2 = Obstacle(vertices, 4, ob_edges, True)
    obj3 = Obstacle(vertices, 4, ob_edges, True)
    obj4 = Obstacle(vertices, 4, ob_edges, True)
    obj5 = Obstacle(vertices, 4, ob_edges, True)

    obstacles = [obj2, obj3, obj4, obj5]
    obstacle_poses = [pose2,pose3,pose4, pose5]


    # will return the final node, which will be linked to all other relevant nodes
    results = look_for_route(init_pose, shape1, obstacles, dimensions, goal_pose, goal_errors, cost_details, arclength, obstacle_poses)

    print_path(results, shape1, obstacles, init_pose, goal_pose, dims)
#
# def main():
#
#     # enter desired grid coordinates
#     x_min= -0.2
#     x_max = 8.2
#     x_step = 0.1
#     y_min = -0.2
#     y_max = 7.2
#     y_step = 0.1
#     a_min = 0
#     a_max = np.pi*2
#     a_step = np.pi/32
#
#     dimensions = (x_min, x_max, x_step, y_min, y_max, y_step, a_min, a_max, a_step)
#     dims = (x_min, x_max, y_min, y_max)
#
#     # enter cost details
#     max_nodes = 2000000
#     max_cost = 50000
#     rot_mult = 10
#     huer_thres = 0.1
#     ob_mult = 2
#     cost_details = [max_cost, max_nodes, rot_mult, huer_thres, ob_mult]
#     arclength = 0.1
#
#     # enter initial and goal conditions
#     goal_pose = [6, 6, np.pi/4]
#     goal_errors = [0.1, 0.1, np.pi/24]
#     init_pose = [1, 1, 0]
#
#
#     edge1 = edge([(-0.5, -0.25), (0.5,-0.25)], True)
#     edge2 = edge([(0.5, -0.25), (0.5, 0.5)], True)
#     edge3 = edge([(0.5, 0.5), (0.25, 0.5)], True)
#     edge4 = edge([(0.25, 0.5), (0.25, 0.15)], False)
#     edge5 = edge([(0.25, 0.15), (-0.25, 0.15)], False)
#     edge6 = edge([(-0.25, 0.15), (-0.25, 0.5)], False)
#     edge7 = edge([(-0.25, 0.5), (-0.5, 0.5)], False)
#     edge8 = edge([(-0.5, 0.5), (-0.5, -0.25)], True)
#     edges = [edge1, edge2, edge3, edge4, edge5, edge6, edge7, edge8]
#
#     vertices = [(-0.5, -0.25), (0.5,-0.25), (0.5, 0.5), (0.25, 0.5), (0.25, 0.15), (-0.25, 0.15), (-0.25, 0.5), (-0.5, 0.5)]
#
#     shape1 = Slider(0.4, vertices, 4, edges)
#
#     # define edges and poses for obstacles
#     edge9 = edge([(-0.4, -0.25), (0.4, -0.25)], True)
#     edge10 = edge([(0.4, -0.25), (0.4, 0.25)], True)
#     edge11 = edge([(0.4, 0.25), (-0.4, 0.25)], True)
#     edge12 = edge([(-0.4, 0.25), (-0.4, -0.25)], True)
#     ob_edges = [edge9, edge10, edge11, edge12]
#     ob_verts = [(-0.4, -0.25), (0.4, -0.25), (0.4, 0.25), (-0.4, 0.25)]
#
#     edgea = edge([(-0.5, -0.25), (0.5,-0.25)], False)
#     edgeb = edge([(0.5, -0.25), (0.5, 0.5)], False)
#     edgec = edge([(0.5, 0.5), (0.3, 0.5)], False)
#     edged = edge([(0.3, 0.5), (0.3, 0.1)], False)
#     edgee = edge([(0.3, 0.1), (-0.3, 0.1)], False)
#     edgef = edge([(-0.3, 0.1), (-0.3, 0.5)], False)
#     edgeg = edge([(-0.3, 0.5), (-0.5, 0.5)], False)
#     edgeh = edge([(-0.5, 0.5), (-0.5, -0.25)], False)
#     edges2 = [edgea, edgeb, edgec, edged, edgee, edgef, edgeg, edgeh]
#     vertices2 = [(-0.5, -0.25), (0.5, -0.25), (0.5, 0.5), (0.3, 0.5), (0.3, 0.1), (-0.3, 0.1), (-0.3, 0.5),
#                 (-0.5, 0.5)]
#
#     pose2 = [1,4,0]
#     pose3 = [2, 4, 0]
#     pose4 = [3.5, 4, 0]
#     pose5 = [5, 4, 0]
#     pose6 = [6.4, 4, 0]
#     pose8 = [7.5, 4, 0]
#     pose9 = [5.25, 6.25, (5/4)*np.pi]
#
#     obj2 = Obstacle(ob_verts, 4, ob_edges, False)
#     obj3 = Obstacle(ob_verts, 4, ob_edges, False)
#     obj4 = Obstacle(ob_verts, 4, ob_edges, False)
#     obj5 = Obstacle(ob_verts, 4, ob_edges, True)
#     obj6 = Obstacle(ob_verts, 4, ob_edges, False)
#     obj8 = Obstacle(ob_verts, 4, ob_edges, False)
#     obj9 = Obstacle(vertices2, 8, edges2, False)
#
#
#     obstacles = [obj2,obj3,obj4,obj5,obj8, obj6,obj9]
#     obstacle_poses = [pose2,pose3,pose4,pose5,pose8,pose6,pose9]
#     # obstacles = [obj9]
#     # obstacle_poses = [pose9]
#
#     # will return the final node, which will be linked to all other relevant nodes
#     results = look_for_route(init_pose, shape1, obstacles, dimensions, goal_pose, goal_errors, cost_details, arclength,
#                              obstacle_poses)
#
#     # q = results[0]
#     # while q.parent != None:
#     #     print(q.pose)
#     #     q = q.parent
#     #
#     # print(q.pose)
#
#     print_path(results, shape1, obstacles, init_pose, goal_pose, dims)


if __name__ == '__main__':
    main()
