eval set Goal(init_coords) \$${Object}(init_coords)
set Goal(init_coords) [flip_y $Goal(init_coords)]
eval set Goal(0degrees) \$${Object}(0degrees)
set Goal(rotated_coords) $Goal(init_coords)
set Goal(theta) 0
## this puts Start at an offset of 30 x 30 mm from the top corner
set Goal(x) [expr $XMAX - 30]
set Goal(y) [expr $YMAX - 30]

set Goal(orient) $Start(0degrees)

set Goal(line_id) [eval .field create line [m_p_list $Goal(0degrees)] \
	-arrow last -fill $Color(GoalArrow) -tags goal]
.field addtag arrow withtag $Goal(line_id)
set Goal(poly_id) [eval .field create polygon [m_p_list $Goal(init_coords)]  \
	-fill $Color(Goal) -tags goal]
.field raise arrow

# array names Goal => {init_coords  rotated_coords actual_coords theta poly_id} 
# The way this works is:
# init_coords contains the coordinates relative to the center of mass
# rotated_coords will be the coordinates rotated, but still relative to the Center o' mass
# actual_coords will have the coordinates that is the actual placement on the world

## from rotation.tcl
## proc d_r degrees 
## proc r_d radians 
## proc rotate_by_degrees {xy_list theta} -- returns rotated a list of coords by theta degrees

## returns a list of sums of corresponding elements
proc list_add {list1 list2} {
    set len [llength $list1]
    for {set i 0} {$i < $len} {incr i} {
	lappend sumlist [expr [lindex $list1 $i] + [lindex $list2 $i]]
    }
    return $sumlist
}

# rotate_goal ASSUMES THAT Goal(init_coords) IS CORRECT!!! (sets rotated_coords)
proc rotate_goal {} {
    global Goal
    set Goal(rotated_coords) [rotate_by_degrees $Goal(init_coords) [expr -($Goal(theta))]]
    set Goal(orient) [rotate_by_degrees $Goal(0degrees) [expr -($Goal(theta))]]
}

# shift_goal ASSUMES THAT Goal(rotated_coords) IS CORRECT!! (sets actual_coords)
proc shift_goal {} {
    global Goal YMAX
    set newxs [list_incr [extract x $Goal(rotated_coords)] $Goal(x)]
    set newys [list_incr [extract y $Goal(rotated_coords)] $Goal(y)]
    set arrowxs [list_incr [extract x $Goal(orient)] $Goal(x)]
    set arrowys [list_incr [extract y $Goal(orient)] $Goal(y)]
    set Goal(actual_coords) [zip $newxs $newys]
    set Goal(final_orient) [zip $arrowxs $arrowys]
    set Goal(fake_y) [expr $YMAX - $Goal(y)]
}

# redraw_goal ASSUMES THAT ALL COORDINATE LISTS ARE CORRECT!!
proc redraw_goal {} {
    global Goal
    eval ".field coords $Goal(poly_id) [m_p_list $Goal(actual_coords)]"
    eval ".field coords $Goal(line_id) [m_p_list $Goal(final_orient)]"  
}

proc update_goal {} {
    global Goal
    rotate_goal
    shift_goal
    redraw_goal
}

.field bind goal <2> { 
    global All_Obs New_Started prevX prevY Ob_List
    .field raise arrow
    .field raise goal
    # this has to do with the movement
    global curX curY
    set curX [p_m %x]
    set curY [p_m %y]
}


# this assumes that Goal(actual_coords) is up to date
.field bind goal <B2-Motion> {
    global Goal
    .field raise goal
    
    set Here(x) [p_m %x]
    set Here(y) [expr $YMAX - [p_m %y]]
    
    set dx [expr [p_m %x]-$curX]
    set dy [expr [p_m %y]-$curY]
    set newx [expr $Goal(x) + $dx]
    set newy [expr $Goal(y) + $dy]
    if {![in_bounds $newx X]} {set newx $Goal(x)}
    if {![in_bounds $newy Y]} {set newy $Goal(y)}
    set Goal(x) $newx 
    set Goal(y) $newy
    shift_goal
    redraw_goal
    set curX [p_m %x] 
    set curY [p_m %y]
}

update_goal


proc call_goal_rotation_window {} {
    global Goal
    toplevel .rotate_goal
    wm title .rotate_goal "Goal Rotation"
    scale .rotate_goal.goal -from 0 -to 360 -length 400 -label "Goal Rotation Angle" \
	    -orient horizontal -command do_rotate_g
    button .rotate_goal.done -text "Done" -relief raised -bd 3 -command {destroy .rotate_goal}
    pack  .rotate_goal.goal -side top -pady 2m
    pack .rotate_goal.done -ipadx 3m -ipady 1m -side bottom
    
    .rotate_goal.goal set $Goal(theta)
    
    proc do_rotate_g dummy {
	global Goal
	set Goal(theta) [.rotate_goal.goal get]
	update_goal
    }
}

