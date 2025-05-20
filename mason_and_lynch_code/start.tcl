source rotation.tcl

eval set Start(init_coords) \$${Object}(init_coords)
set Start(theta) 0
## This step puts it in the correct frame
set Start(init_coords) [flip_y $Start(init_coords)]

eval set Start(0degrees) \$${Object}(0degrees)
set Start(rotated_coords) $Start(init_coords)


## this puts Start at an offset of 30 x 30 mm from the top corner
set Start(x) 30
set Start(y) 30

set Start(orient) $Start(0degrees)

set Start(line_id) [eval .field create line [m_p_list $Start(0degrees)] \
	-arrow last -fill $Color(StartArrow) -tags start]
.field addtag arrow withtag $Start(line_id)

set Start(poly_id) [eval .field create polygon [m_p_list $Start(init_coords)]  \
	-fill $Color(Start) -tags start]
.field raise arrow

# array names Start => {init_coords  rotated_coords actual_coords theta poly_id} 
# The way this works is:
# init_coords contains the coordinates relative to the center of mass
# rotated_coords will be the coordinates rotated, but still relative to the Center o' mass
# actual_coords will have the coordinates that is the actual placement on the world

## from rotation.tcl
## proc d_r degrees 
## proc r_d radians 
## proc rotate_by_degrees {xy_list theta} -- returns rotated a list of coords by theta degrees

# rotate_start ASSUMES THAT Start(init_coords) IS CORRECT!!! (sets rotated_coords)
proc rotate_start {} {
    global Start
    set Start(rotated_coords) [rotate_by_degrees $Start(init_coords) [expr -($Start(theta))]]
    set Start(orient) [rotate_by_degrees $Start(0degrees) [expr -($Start(theta))]]
}

# shift_start ASSUMES THAT Start(rotated_coords) IS CORRECT!! (sets actual_coords)
proc shift_start {} {
    global Start YMAX
    set newxs [list_incr [extract x $Start(rotated_coords)] $Start(x)]
    set newys [list_incr [extract y $Start(rotated_coords)] $Start(y)]
    set arrowxs [list_incr [extract x $Start(orient)] $Start(x)]
    set arrowys [list_incr [extract y $Start(orient)] $Start(y)]
    set Start(actual_coords) [zip $newxs $newys]
    set Start(final_orient) [zip $arrowxs $arrowys]
    set Start(fake_y) [expr $YMAX - $Start(y)]
}

# redraw_start ASSUMES THAT ALL COORDINATE LISTS ARE CORRECT!!
proc redraw_start {} {
    global Start
    eval ".field coords $Start(poly_id) [m_p_list $Start(actual_coords)]"
    eval ".field coords $Start(line_id) [m_p_list $Start(final_orient)]"  
}

proc update_start {} {
    global Start
    rotate_start
    shift_start
    redraw_start
}

.field bind start <2> { 
    global All_Obs New_Started prevX prevY Ob_List
    .field raise arrow
    .field raise start
    # this has to do with the movement
    global curX curY
    set curX [p_m %x]
    set curY [p_m %y]
}


# this assumes that Start(actual_coords) is up to date
.field bind start <B2-Motion> {
    global Start
    .field raise start
    
    set Here(x) [p_m %x]
    set Here(y) [expr $YMAX - [p_m %y]]
  
    set dx [expr [p_m %x]-$curX]
    set dy [expr [p_m %y]-$curY]
    set newx [expr $Start(x) + $dx]
    set newy [expr $Start(y) + $dy]
    if {![in_bounds $newx X]} {set newx $Start(x)}
    if {![in_bounds $newy Y]} {set newy $Start(y)}
    set Start(x) $newx 
    set Start(y) $newy
    shift_start
    redraw_start
    set curX [p_m %x] 
    set curY [p_m %y]
}

update_start

proc call_start_rotation_window {} {
    global Start
    toplevel .rotate_start
    wm title .rotate_start "Start Rotation"
    scale .rotate_start.start -from 0 -to 360 -length 400 -label "Start Rotation Angle" \
	    -orient horizontal -command do_rotate_s
    button .rotate_start.done -text "Done" -relief raised -bd 3 -command {destroy .rotate_start}
    pack .rotate_start.start -side top -pady 2m
    pack .rotate_start.done -side bottom -ipadx 3m -ipady 1m

    .rotate_start.start set $Start(theta)

    proc do_rotate_s dummy {
	global Start
	set Start(theta) [.rotate_start.start get]
	update_start
    }
}
