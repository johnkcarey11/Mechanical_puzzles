set XMAX 180  ;# in millimeters
set YMAX 180
set PMConversion 3.54 ;# conversion factor from 3.54 pixels to 1 mills

#  These are all related.
set Mode rect ;#can be rect, poly (or select if implemented)
set help1 "Click and drag to create rectangle"
set help2 "Click and drag to move object"
set help3 "Click to kill obstacle"
set help4 ""
set help5 ""

set OPTIONS(grid) 2
set OPTIONS(errx) 3.0
set OPTIONS(erry) 3.0
set OPTIONS(errtheta) 2.0
set OPTIONS(push) 0
set OPTIONS(actionswitch) 1
set OPTIONS(edgeswitch) 1
set OPTIONS(max) 1000
set OPTIONS(arclength) 6.0
set OPTIONS(xcell) 3.0
set OPTIONS(ycell) 3.0
set OPTIONS(thetacell) 2.0
set New_Started 0
set Ob_List(temp) {}
set ColorFile editcolors.tcl

set MaxObstacles 20
set MaxVertices 10

set All_Obs {}
set guide_line -1
set planner_call 0
set filename "push.problem"
set write_adept 0
set printer "marble"
set printname "problem.ps"
set get_out 1
set printit 0
set Object "Square"
set PathOut "push.path"

source $ColorFile
source objects.tcl

foreach ob $Possible_Objects {
    eval set init \$${ob}(init_coords)
    set ${ob}(edgecoords) {}
    for {set e 1} {[expr $e < ([llength $init]/2)]} {incr e} {
	if {[expr \$${ob}(edge,$e,numcontrols) != 0]} {
	    set i [expr ($e - 1)*2]
	    set x1 [lindex $init $i]
	    set y1 [lindex $init [expr $i+1]]
	    set x2 [lindex $init [expr $i+2]]
	    set y2 [lindex $init [expr $i+3]]
	    lappend ${ob}(edgecoords) [list $x1 $y1 $x2 $y2]
	} else {lappend ${ob}(edgecoords) no_coords }
    }
    if {[expr \$${ob}(edge,$e,numcontrols) != 0]} {
	set i [expr ($e - 1)*2]
	set x1 [lindex $init $i]
	set y1 [lindex $init [expr $i+1]]
	set x2 [lindex $init 0]
	set y2 [lindex $init 1]
	lappend ${ob}(edgecoords) [list $x1 $y1 $x2 $y2]
    } else {lappend ${ob}(edgecoords) no_coords }
}

