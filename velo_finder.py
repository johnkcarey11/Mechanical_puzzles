import numpy as np

class edge:
    """ class to represent edges of polygons in scenes"""
    def __init__(self, coords, pushable, rot_sep=0.1, safety=1):
        # Initialize the attributes
        self.coords = coords
        self.left_point = self.coords[0]
        self.right_point = self.coords[1]
        self.pushable = pushable         # can this edge have velocities
        self.velos = []
        self.rot_sep = rot_sep           # minimum distance between vertices to find velos from rotation centers
        self.safety = safety             # buffer in calc of rotation centers in STABLE

        # lines for left rotations
        self.fline1 = [0, 0, 0]
        self.fline4 = [0, 0, 0]
        self.eline1 = [0, 0, 0]
        self.eline4 = [0, 0, 0]
        self.left_lines = []

        # lines for right rotations
        self.fline2 = [0, 0, 0]
        self.fline3 = [0, 0, 0]
        self.eline2 = [0, 0, 0]
        self.eline3 = [0, 0, 0]
        self.right_lines = []

        self.R = self.find_rot_mat()       # find the rotation matrix


    def calc_velos(self, coeff_f, vertices,edge_count):
        """Determine the stable pushing velocities of the edge."""
        self.find_flines(vertices,coeff_f,edge_count)
        #print("FLine1: ", self.fline1)
        self.find_elines(vertices)
        self.find_translations()
        #print("Velos: ", self.velos)
        self.left_lines = [self.fline1, self.fline4, self.eline1, self.eline4]
        self.right_lines = [self.fline2, self.fline3, self.eline2, self.eline3]
        self.find_left_rotations()
        self.find_right_rotations()

        #print("Velos: ", self.velos)

    def find_elines(self,vertices):
        """ function to find the lines based on center of mass of slider
        Import to understand STABLE procedure prior to understanding function
        This function finds the lines found in the second step of STABLE

        l and r based on the edge's frame pointing towards the CoM"""

        # coordinates of Pl and Pr
        xl = self.left_point[0]
        yl = self.left_point[1]
        xr = self.right_point[0]
        yr = self.right_point[1]

        # points for bisection lines between Ps and CoM
        blx = xl/2
        bly = yl/2
        brx = xr/2
        bry = yr/2

        # distance from points to center of mass
        Pl = np.linalg.norm(np.array([xl, yl]))
        Pr = np.linalg.norm(np.array([xr, yr]))

        # distances to furthest points from Pl and Pr
        rl = self.find_r(xl, yl, vertices)
        rr = self.find_r(xr, yr, vertices)

        # inverse directions from lines to origin
        L_dir = np.array([yl, -xl])
        R_dir = np.array([-yr, xr])

        dl = self.R@L_dir
        dxl = dl[0]
        dyl = dl[1]

        dr = self.R@R_dir
        dxr = dr[0]
        dyr = dr[1]


        # find the distant points
        pl = self.find_dist_points(Pl, rl, xl, yl)
        pxl = pl[0]
        pyl = pl[1]

        pr = self.find_dist_points(Pr, rr, xr, yr)
        pxr = pr[0]
        pyr = pr[1]

        # bisect lines for left and right points
        self.eline1 = self.eqn_line(dxl, dyl, blx, bly)
        self.eline2 = self.eqn_line(dxr, dyr, brx, bry)

        # distant lines for left and right points
        self.eline3 = self.eqn_line(dxl, dyl, pxl, pyl)
        self.eline4 = self.eqn_line(dxr, dyr, pxr, pyr)

    def find_flines(self,vertices,coeff_frict,edge_count):
        """
        Function to find the lines found in the first step of the STABLE procedure

        l and r based on the edge's frame pointing towards the CoM
        Note: the function currently only handles 3 and 4-sided shapes
        Will need to expand point assignment to expand to more shapes
        """

        # find the inverse of the coeff of friction of the pusher
        alpha = np.arctan(coeff_frict)

        # find the inverse directions from edges of friction cone
        L_dir = np.array([np.cos(alpha), np.sin(alpha)])
        R_dir = np.array([-np.cos(alpha), np.sin(alpha)])

        # inverse directions transformed into the shape's frame
        dL = self.R@L_dir
        dLx = dL[0]
        dLy = dL[1]
        dR = self.R@R_dir
        dRx = dR[0]
        dRy = dR[1]

        """ Note: These next instructions only handle 3 and 4 sided shapes"""
        p1 = self.left_point
        p2 = self.right_point

        # determine which vertice the left point is
        i = 0
        for j in range(len(vertices)):
            if vertices[j] == self.left_point:
                i = j

        # assign points p3 and p4
        if edge_count == 3:
        # P1 and P3 are perp to right slide of friction cone and help with left rotations
        # P2 and P4 are perp to left slide of friction cone and help with right rotations
            p3i = (i+2) % 3
            p3 = vertices[p3i]
            p4 = p3
        elif edge_count == 4:
            p3i = (i + 2) % 4
            p4i = (i + 3) % 4
            p3 = vertices[p3i]
            p4 = vertices[p4i]

        # find the lines using the left friction line
        self.fline1 = self.eqn_line(dRx, dRy, p1[0], p1[0])
        self.fline3 = self.eqn_line(dRx, dRy, p3[0], p3[1])

        # find the lines using the right friction line
        self.fline2 = self.eqn_line(dLx, dLy, p2[0], p2[1])
        self.fline4 = self.eqn_line(dLx, dLy, p4[0], p4[1])

    def find_translations(self):
        "function to find the direction ahead of the frame in the shape's frame"
        trans_in_robot = np.array([0,1])
        trans_in_shape = self.R@trans_in_robot
        translation = [trans_in_shape[0], trans_in_shape[1], 0]
        self.velos.append(translation)

    def find_left_rotations(self):
        """function to find the velos based on the vertices of the polygon formed by the lines
           to the left of the shape in the shape's frame"""
        for i in range(len(self.left_lines)):
            j = i+1

            # find the vertices of the left polygon (intersection points of the left lines)
            while j < (len(self.left_lines)-1):
                vertice = line_intersection(self.left_lines[i], self.left_lines[j])
                if vertice[0] != None:
                    direct = [vertice[1], -vertice[0], 1]

                    # ensure this vertex isn't too close to other vertices
                    if not self.too_close(direct):
                        self.velos.append(direct)
                j+=1


    def find_right_rotations(self):
        """function to find the velos based on the vertices of the polygon formed by the lines
                   to the right of the shape in the shape's frame"""

        for i in range(len(self.right_lines)):
            j = i+1
            # find the vertices of the right polygon (intersection points of the left lines)
            while j < (len(self.right_lines)-1):
                vertice = line_intersection(self.right_lines[i], self.right_lines[j])
                if vertice[0] != None:
                    direct = [-vertice[1], vertice[0], -1]
                    # ensure this vertex isn't too close to other vertices
                    if not self.too_close(direct):
                        self.velos.append(direct)
                j+=1


    def too_close(self, direct):
        """ function to determine if vertex (direct) is too close (based on
            class parameter self.rot_sep) to vertices associated with already found velos"""
        too_close = False
        for d in self.velos:
            dist = (d[0]+direct[0])**2 + (d[1]+direct[1])**2
            #print(dist)
            if dist <= self.rot_sep:
                #print("here")
                too_close = True

        return too_close

    def find_r(self, x, y, verts):
        """ find the variable r used in the STABLE procedure"""

        r = 0
        point = np.array([x, y])
        for vert in verts:
            temp = np.array([vert[0], vert[1]])
            dist = np.linalg.norm(point-temp)
            if dist > r:
                r = dist
        return r

    def find_rot_mat(self):
        """ find the rotation matrix to rotate a point from the frame of the edge to the frame of the shape"""
        # coordinates of Pl and Pr
        xl = self.left_point[0]
        yl = self.left_point[1]
        xr = self.right_point[0]
        yr = self.right_point[1]

        change_y = yr-yl
        change_x = xr-xl

        # angle of rotation between shape frame and edge frame
        theta = np.atan2(change_y, change_x)
        #print("Theta: ", theta)

        # rotation matrix to transform from edge frame to shape frame
        R = np.array([[np.cos(theta), -np.sin(theta)],
                     [np.sin(theta), np.cos(theta)]])

        return R

    def find_dist_points(self, p, r, x, y):
        """ function to find the the distant point used in the second step of STABLE"""
        r2p = r*r/p*self.safety
        vec = np.array([x,y])
        vec_norm = np.linalg.norm(vec)
        dist_x = (-1)*r2p*(x/vec_norm)
        dist_y = (-1) * r2p * (y / vec_norm)
        return dist_x, dist_y

    def eqn_line(self, dx, dy, px, py):
        "finds equation of line of form dx(py) - dy(px) = c"
        a = dx
        b = (-1)*dy
        c = a*py+b*px
        return [a, b, c]


class Obstacle:
    """Class to define obstacles """
    def __init__(self, vertices, edge_count, edges, moveable=False):
        # Initialize the attributes
        self.vertices = vertices  # List or other structure holding vertices
        self.edge_count = edge_count  # Number of edges
        self.edges = edges  # List or set of edges that can be pushed
        self.max_rad = 0    # distance from center of obstacle to vertex that is furthest away
        self.moveable = moveable   # whether obstacle can be moved to help slider reach goal pose

        for vert in self.vertices:
            vect = np.array([vert[0], vert[1]])
            rad = np.linalg.norm(vect)
            if rad > self.max_rad:
                self.max_rad = rad

        for e in self.edges:
            if e.pushable and e.velos == []:
                #print("Here")
                e.find_translations()

class Slider:
    def __init__(self, coeff_friction, vertices, edge_count, edges, safety=1.0):
        # Initialize the attributes
        self.coeff_F = coeff_friction  # Coefficient of friction
        self.vertices = vertices  # List or other structure holding vertices
        self.edge_count = edge_count  # Number of edges
        self.edges = edges  # List or set of edges that can be pushed
        self.safety = safety # buffer for the r^2/p distance calculation (in STABLE)
        self.max_rad = 0

        for e in self.edges:
            if e.pushable:
                #print("Here")
                e.calc_velos(self.coeff_F, self.vertices, self.edge_count)

        for vert in self.vertices:
            vect = np.array([vert[0], vert[1]])
            rad = np.linalg.norm(vect)
            if rad > self.max_rad:
                self.max_rad = rad

    def update_friction(self, new_coeff):
        """Update the coefficient of friction."""
        self.coeff_friction = new_coeff

def line_intersection(l1, l2):
    """find the intersection point of two lines"""
    a = l1[0]
    b = l1[1]
    c = l1[2]
    d = l2[0]
    f = l2[1]
    g = l2[2]
    deno = a*f - d*b
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




# # Example usage:
# slider = Slider(coeff_friction=0.8,
#                 vertices=[(0, 0), (1, 0), (1, 1), (0, 1)],
#                 edge_count=4,
#                 pushable_edges=[(0, 1), (1, 2)],
#                 unpushable_edges=[(2, 3)])
#
# print(slider)

# def main():
#
#     #print(2.75//0.5)
#
#
#
#
# if __name__ == '__main__':
#     main()