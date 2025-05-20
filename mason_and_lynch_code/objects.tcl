global Possible_Objects
set Possible_Objects {}

global Square
lappend Possible_Objects Square
set Square(init_coords) [list -13.0 -13.0  13.0 -13.0  13.0 13.0  -13.0 13.0]
set Square(0degrees) [list 0 0 0 -10]
set Square(robot_polys) 1
set Square(numedges) 4
set Square(edge,1,numcontrols) 5
set Square(edge,1,1) [list 0.0 1.0 0.0]
set Square(edge,1,2) [list -1.0 2.0 0.0] 
set Square(edge,1,3) [list 1.0 2.0 0.0]
set Square(edge,1,4) [list 0.0 39.0 1.0]
set Square(edge,1,5) [list 0.0 39.0 -1.0]
set Square(edge,2,numcontrols) 0
set Square(edge,3,numcontrols) 5
set Square(edge,3,1) [list 0.0 -1.0 0.0]
set Square(edge,3,2) [list -1.0 -2.0 0.0]
set Square(edge,3,3) [list 1.0 -2.0 0.0]
set Square(edge,3,4) [list 0.0 -39.0 1.0]
set Square(edge,3,5) [list 0.0 -39.0 -1.0]
set Square(edge,4,numcontrols) 0

global Pentagon
lappend Possible_Objects Pentagon
set Pentagon(init_coords) [list -10.0 -10.0  0.0 -10.0  10.0 0.0  10.0 10.0  -10.0 10.0]
set Pentagon(0degrees) [list 0 0 0 0]
set Pentagon(robot_polys) 1
set Pentagon(numedges) 5
set Pentagon(edge,1,numcontrols) 4
set Pentagon(edge,1,1) [list 0.0 1.0 0.0]
set Pentagon(edge,1,2) [list 1.0 2.0 0.0]
set Pentagon(edge,1,3) [list 5.0 40.0 -1.0]
set Pentagon(edge,1,4) [list 20.0 70.0 1.0]
set Pentagon(edge,2,numcontrols) 0
set Pentagon(edge,3,numcontrols) 0
set Pentagon(edge,4,numcontrols) 4
set Pentagon(edge,4,1) [list -1.0 -2.0 0.0]
set Pentagon(edge,4,2) [list 1.0 -2.0 0.0]
set Pentagon(edge,4,3) [list 2.5 -25.0 1.0]
set Pentagon(edge,4,4) [list 0.0 -30.0 -1.0]
set Pentagon(edge,5,numcontrols) 0

global Bolt
lappend Possible_Objects Bolt
set Bolt(init_coords) [list -5.0 -8.0  14.0 -4.0  14.0 4.0  -5.0 8.0  -10.0 8.0  -10.0 -8.0]
set Bolt(0degrees) [list 0 0 0 0]
set Bolt(robot_polys) 1
set Bolt(numedges) 6
set Bolt(edge,1,numcontrols) 5
set Bolt(edge,1,1) [list -0.79 1.0 0.0]
set Bolt(edge,1,2) [list 0.26 1.0 0.0] 
set Bolt(edge,1,3) [list -3.5 25.4 1.0 ]
set Bolt(edge,1,4) [list -8.5 29.7 -1.0 ]
set Bolt(edge,1,5) [list 5.6 53.0 -1.0 ]
set Bolt(edge,2,numcontrols) 0
set Bolt(edge,3,numcontrols) 5
set Bolt(edge,3,1) [list -0.79 -1.0 0.0]
set Bolt(edge,3,2) [list 0.26 -1.0 0.0  ]
set Bolt(edge,3,3) [list -3.5 -25.4 -1.0]
set Bolt(edge,3,4) [list -8.5 -29.7 1.0]
set Bolt(edge,3,5) [list 5.6 -53.0 1.0]
set Bolt(edge,4,numcontrols) 0
set Bolt(edge,5,numcontrols) 0
set Bolt(edge,6,numcontrols) 0

global Car
lappend Possible_Objects Car
set Car(init_coords) [list -10.0 -15.0  10.0 -15.0  10.0 15.0 -10.0 15.0]
set Car(0degrees) [list 0 0 0 -10.0]
set Car(robot_polys) 1
set Car(numedges) 4
set Car(edge,1,numcontrols) 3
set Car(edge,1,1) [list 0.0 1.0 0.0]
set Car(edge,1,2) [list -5.0 40.0 1.0] 
set Car(edge,1,3) [list 5.0 40.0 -1.0 ]
set Car(edge,2,numcontrols) 0
set Car(edge,3,numcontrols) 3
set Car(edge,3,1) [list 0.0 -1.0 0.0]
set Car(edge,3,2) [list 5.0 -40.0 -1.0] 
set Car(edge,3,3) [list -5.0 -40.0 1.0]
set Car(edge,4,numcontrols) 0

global Doohicky25
lappend Possible_Objects Doohicky25
set Doohicky25(init_coords) [list -11.0 -10.0 -8.0 -12.0 10.0 -12.0 10.0 -10.0 6.0 9.0 -8.0 9.0]
set Doohicky25(0degrees) [list 0 0 0 -5.29412 ]
set Doohicky25(robot_polys) 1
set Doohicky25(numedges) 6
set Doohicky25(edge,1,numcontrols) 0
set Doohicky25(edge,2,numcontrols) 4
set Doohicky25(edge,2,1) [list -0.242535 0.970139 0.0]
set Doohicky25(edge,2,2) [list 0.242535 0.970139 0.0]
set Doohicky25(edge,2,3) [list -1.49999 49.9998 1.0]
set Doohicky25(edge,2,4) [list 1.99997 50.0 -1.0]
set Doohicky25(edge,3,numcontrols) 0
set Doohicky25(edge,4,numcontrols) 4
set Doohicky25(edge,4,1) [list -0.899372 -0.437195 0.0]
set Doohicky25(edge,4,2) [list -0.999301 0.0374739 0.0]
set Doohicky25(edge,4,3) [list -50.2492 -8.56565 1.0]
set Doohicky25(edge,4,4) [list -40.1061 -9.12104 -1.0]
set Doohicky25(edge,5,numcontrols) 4
set Doohicky25(edge,5,1) [list 0.242535 -0.970139 0.0]
set Doohicky25(edge,5,2) [list -0.242535 -0.970139 0.0]
set Doohicky25(edge,5,3) [list -1.99997 -50.0 1.0]
set Doohicky25(edge,5,4) [list 1.49999 -49.9998 -1.0]
set Doohicky25(edge,6,numcontrols) 4
set Doohicky25(edge,6,1) [list 0.9961 0.0882631 0.0]
set Doohicky25(edge,6,2) [list 0.92044 -0.390872 0.0]
set Doohicky25(edge,6,3) [list 40.7895 -5.49961 1.0]
set Doohicky25(edge,6,4) [list 52.5692 -7.22797 -1.0]



global Viper
lappend Possible_Objects Viper
set Viper(init_coords) [list -10.0 15.0 5.0 0.0 -10.0 -15.0 20.0 0.0]
set Viper(0degrees) [list 0 0 0 0]
set Viper(robot_polys) 1
set Viper(numedges) 4
set Viper(edge,1,numcontrols) 0
set Viper(edge,2,numcontrols) 0
set Viper(edge,3,numcontrols) 4
set Viper(edge,3,1) [list -0.65079 0.759254 0.0]
set Viper(edge,3,2) [list -0.21693 0.976183 0.0]
set Viper(edge,3,3) [list -25.4999 57.2499 1.0]
set Viper(edge,3,4) [list -29.25 54.1249 -1.0]
set Viper(edge,4,numcontrols) 4
set Viper(edge,4,1) [list -0.21693 -0.976183 0.0]
set Viper(edge,4,2) [list -0.65079 -0.759254 0.0]
set Viper(edge,4,3) [list -29.25 -54.1249 1.0]
set Viper(edge,4,4) [list -25.4999 -57.2499 -1.0]


global Polygon
lappend Possible_Objects Polygon
set Polygon(init_coords) [list -4.0 12.0 -15.0 1.0 -5.0 -9.0 7.0 -1.0 14.0 -6.0 16.0 6.0]
set Polygon(0degrees) [list 0 0 0 -7.05882 ]
set Polygon(robot_polys) 1
set Polygon(numedges) 6
set Polygon(edge,1,numcontrols) 0
set Polygon(edge,2,numcontrols) 0
set Polygon(edge,3,numcontrols) 6
set Polygon(edge,3,1) [list -0.989949 0.141421 0.0]
set Polygon(edge,3,2) [list 0.485644 0.87416 0.0]
set Polygon(edge,3,3) [list 202.998 375.997 1.0]
set Polygon(edge,3,4) [list 11.0754 40.132 1.0]
set Polygon(edge,3,5) [list -24.8659 13.6417 -1.0]
set Polygon(edge,3,6) [list -49.2001 10.6 -1.0]
set Polygon(edge,4,numcontrols) 0
set Polygon(edge,5,numcontrols) 0
set Polygon(edge,6,numcontrols) 5
set Polygon(edge,6,1) [list 0.316228 -0.948684 0.0]
set Polygon(edge,6,2) [list -0.93633 -0.351124 0.0]
set Polygon(edge,6,3) [list -39.3781 -23.8918 1.0]
set Polygon(edge,6,4) [list -17.6301 -20.1096 1.0]
set Polygon(edge,6,5) [list -0.518525 -18.4444 -1.0]
