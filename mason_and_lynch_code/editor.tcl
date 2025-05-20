#!/usr/local/bin/wish -f
# Pushing World Editor v2.5--by Constantinos Nikou
# 
#
# Now only implements obstacles as polygons...NO MORE RECTANGLES (yes!)
# Also with happy select and copy/rotate

# Files to include
# editor.tcl (this file)--initial geometry and button placement.  All event bindings.
#     source this file to run
# buttons.tcl -- all functions that are called by buttons
# globals.tcl -- initialization of global variables
# helpers.tcl -- all silly little helper functions
# start.tcl -- start definitions with functions
# goal.tcl -- same as start.tcl, but for the goal
# path.tcl -- functions to invoke and draw the planner and path, respectively
# objects.tcl -- definition of new objects
# rotation.tcl -- functions to implement rotation

puts "loading globals.tcl"
source globals.tcl
puts "loading helpers.tcl"
source helpers.tcl

. configure  -bg black
wm title . "Pushing World Editor v2.3"


canvas .field -bd 1m -bg #eef -width [m_p $XMAX] -height [m_p $YMAX]
frame .options1 -relief flat -bd 4 -bg gray
frame .options2 -relief flat -bd 4 -bg gray
button .options1.save -text "Save Problem" -command save
button .options1.quit -text "Quit Editor" -command quit
button .options1.reset -text "Reset" -command reset
button .options1.options -text "Options..." -command choose_options
button .options1.load -text "Load Problem" -command load
button .options1.ps  -text "Write Postscript File" -command ps_file
button .options1.new_object -text "New Object" -command new_object
button .options1.flash -text "Show Pushing Edges" -command flash_edges


frame .options2.mode -bg gray 
radiobutton .options2.mode.poly -text "Polygon Mode" -variable Mode \
	-value poly -anchor w -bg #eee
radiobutton .options2.mode.rect -text "Rectangle Mode" -variable Mode \
	-value rect -anchor w -bg #eee
radiobutton .options2.mode.select -text "Select Obstacle" -variable Mode \
	-value select -anchor w -bg #eee

set Mode rect

pack .options2.mode.rect \
	.options2.mode.poly \
	.options2.mode.select -fill x
	
button .options2.kill_path -text "Delete Path" -command {.field delete path}

frame .options2.sg -bg gray
frame .options2.sg.start -bg gray
frame .options2.sg.goal -bg gray

button .options2.sg.start.rotate_start -text "Rotate Start" \
	-command call_start_rotation_window
button .options2.sg.goal.rotate_goal -text "Rotate Goal" -command call_goal_rotation_window

label .options2.sg.start.label -text "Start Position" -fg $Color(Start) -bg gray
label .options2.sg.goal.label -text "Goal Position" -fg $Color(Goal) -bg gray

frame .options2.sg.start.coords -bg gray
label .options2.sg.start.coords.x -textvariable Start(x) -bg #eee
label .options2.sg.start.coords.y -textvariable Start(fake_y) -bg #eee
label .options2.sg.start.coords.theta -textvariable Start(theta) -bg #eee 
pack .options2.sg.start.coords.x .options2.sg.start.coords.y \
	.options2.sg.start.coords.theta -side left
frame .options2.sg.goal.coords -bg gray
label .options2.sg.goal.coords.x -textvariable Goal(x) -bg #eee
label .options2.sg.goal.coords.y -textvariable Goal(fake_y) -bg #eee
label .options2.sg.goal.coords.theta -textvariable Goal(theta) -bg #eee
pack .options2.sg.goal.coords.x .options2.sg.goal.coords.y \
	.options2.sg.goal.coords.theta -side left


frame .options2.here -bg gray
label .options2.here.label1 -text "Current Coordinates" -bg gray
label .options2.here.label3 -text "  (" -bg gray
label .options2.here.label4 -text ")" -bg gray
label .options2.here.label5 -text "," -bg gray
label .options2.here.x -textvariable Here(x) -bg gray
label .options2.here.y -textvariable Here(y) -bg gray

frame .options2.help -bg gray 
frame .options2.help.1 -bg gray
frame .options2.help.2 -bg gray
frame .options2.help.3 -bg gray
label .options2.help.1.label -text "Button 1: " -fg $Color(help) -bg gray
label .options2.help.2.label -text "Button 2: " -fg $Color(help) -bg gray
label .options2.help.3.label -text "Button 3: " -fg $Color(help) -bg gray
label .options2.help.1.help -textvariable help1 -fg $Color(help) -bg gray
label .options2.help.2.help -textvariable help2 -fg $Color(help) -bg gray
label .options2.help.3.help -textvariable help3 -fg $Color(help) -bg gray
label .options2.help.4 -textvariable help4 -fg #020 -bg gray
label .options2.help.5 -textvariable help5 -fg #020 -bg gray

foreach n {1 2 3} {
    pack .options2.help.${n}.label .options2.help.${n}.help
}

pack .options2.help.1  .options2.help.2  .options2.help.3 \
	.options2.help.4 .options2.help.5

frame .options2.planner -bg gray
button .options2.planner.run -text "Run Planner" -relief raised \
	-bd 3m -bg $Color(PlannerButtonbg) -fg $Color(PlannerButtonfg) \
	-command run_planner 
#-activebackground #ffff70007000

if {$write_adept} {
    button .options2.planner.adept -text "Write Adept File" -command write_adept_switch \
	    -anchor w -bg gray -activebackground #eee
} else {
     button .options2.planner.adept -text "Don't Write Adept File" \
	     -command write_adept_switch -anchor w -bg gray -activebackground #eee
}

pack .options2.here.label1 -expand 1
pack .options2.here.label3 .options2.here.x \
	.options2.here.label5 .options2.here.y .options2.here.label4 -side left


pack .options2.sg.start.label .options2.sg.start.coords \
	.options2.sg.start.rotate_start 
pack .options2.sg.goal.label .options2.sg.goal.coords .options2.sg.goal.rotate_goal
pack .options2.sg.start -side left
pack .options2.sg.goal -side right

pack .options2.planner.run -side bottom -fill x -ipady 1c -ipadx 1c
pack .options2.planner.adept -side top -ipady 1m -pady 1m


pack .options1.load \
	.options1.save \
	.options1.ps \
	.options1.reset \
	.options1.options \
	.options1.new_object \
	.options1.flash -fill x -ipady 1m -ipadx 1m -side left
	
pack .options1.quit -fill x -ipady 1m -ipadx 1m -side right

pack .options2.mode .options2.kill_path -ipady 1m -ipadx 3m -side top -fill x

pack .options2.sg \
	.options2.here \
	 -ipadx 1m -pady 2m -side top -fill y

pack .options2.help -pady 1m -side top -fill both -expand 1

pack .options2.planner -fill x -side bottom

pack .options1 -side top -fill x 
pack .field -side left -padx 1m -pady 1m
pack .options2 -side right -pady 1m -expand 1 -fill both -padx 1m


#######################  EVENT BINDINGS #######################

.field bind obstacle <Any-Enter> {
    global Color
    .field itemconfigure current -fill $Color(CurrentObstacle)
    # button 3 erase    
    .field bind obstacle <3> {
        remove_ob [.field find withtag current]
    }
    .field itemconfigure selected -fill $Color(SelectedObstacle)
} 

.field bind obstacle <Any-Leave> {
    global Color
    .field itemconfigure current -fill $Color(Obstacle)
    .field itemconfigure selected -fill $Color(SelectedObstacle)
}

bind .field <1> {
    global New_Started prevX prevY All_Obs Ob_List 
    global guide_line Mode help1 help2 Color MaxObstacles
    set too_many_obstacles [expr [llength $All_Obs] >= $MaxObstacles]
    if {$Mode == "rect"} {
	if {$too_many_obstacles} {
	    dialog "Sorry, there is a maximum of $MaxObstacles obstacles" 1
	    return;
	}
	global rborder
	set prevX [p_m %x]
	set prevY [p_m %y] 
	set help1 "Release to create obstacle"
	set rborder [eval .field create polygon \
		[m_p_list [list $prevX $prevY $prevX $prevY $prevX $prevY $prevX $prevY]] \
		-fill $Color(Obstacle) -tags obstacle]
	lappend All_Obs $rborder
	set Ob_List($rborder) [list $prevX $prevY $prevX $prevY $prevX $prevY $prevX $prevY ]
    } elseif {$Mode == "poly"} {
	if {$New_Started == 0} {
	    if {$too_many_obstacles} {
		dialog "Sorry, there is a maximum of $MaxObstacles obstacles" 1
		return;
	    }
	    set New_Started 1   ;#begin new creation
	    set help1 "Click again to place vertex"
	    set help2 "Click to close and create obstacle"
	    set prevX [p_m %x]
	    set prevY [p_m %y]
	    lappend Ob_List(temp) $prevX $prevY
	    eval .field create rectangle \
		[m_p [expr [p_m %x]-.5]] [m_p [expr [p_m %y]-.5]] \
		[m_p [expr [p_m %x]+.5]] [m_p [expr [p_m %y] + .5]] \
		-outline black -fill red -tags line
	    set guide_line [eval .field create line \
		    [m_p_list [list $prevX $prevY $prevX $prevY]] -tags line]
	} else {
	    .field create line \
		    [m_p [p_m %x]] [m_p [p_m %y]] \
		    [m_p $prevX] [m_p $prevY] -tags line -width 2
	    eval  .field create rectangle \
		    [m_p [expr [p_m %x]-.5]] [m_p [expr [p_m %y] - .5]] \
		    [m_p [expr [p_m %x] +.5]] [m_p [expr [p_m %y] + .5]] \
		    -outline black -fill red -tags line
	    lappend Ob_List(temp) [p_m %x] [p_m %y]
	    set prevX [p_m %x]
	    set prevY [p_m %y]
	}
    }
}

.field bind obstacle <1> {
    global Color
    if {$Mode == "select"} {
	.field itemconfigure selected -fill $Color(Obstacle)
	.field dtag selected selected  ;# takes away old tag
	.field addtag selected withtag current
	.field itemconfigure selected -fill $Color(SelectedObstacle)
    }
}

## when you first click <1>, a line follows you around

bind .field <Motion> {
    global New_Started prevX prevY guide_line Mode Here YMAX help2 help1
    set Here(x) [expr 1.0 * [p_m %x]]
    set Here(y) [expr 1.0* $YMAX - [p_m %y]]
    if {$Mode != "rect"} {
	if {$New_Started} {
	    eval .field coords $guide_line \
		    [m_p_list [list $prevX $prevY [p_m %x] [p_m %y]]]
	}
    }
}

bind .field <B1-Motion> {
    global prevX prevY Mode rborder XMAX YMAX Here
    set X [p_m %x]
    set Y [p_m %y]

    set Here(x) $X
    set Here(y) [expr $YMAX - $Y]
    
    if {$Mode == "rect"} {
	if {$X < 0} {set X 0}
	if {$X > $XMAX} {set X $XMAX}
	if {$Y < 0} {set Y 0}
	if {$Y > $YMAX} {set Y $YMAX}
	update_obstacle $rborder [list $prevX $prevY  $prevX $Y  $X $Y  $X $prevY] 
    }
}

bind .field <ButtonRelease-1> {
    global rborder Mode help1
    if {$Mode == "rect"} {
	set help1 "Click and drag to create rectangle"
	if {![legal_coords [.field coords $rborder]]} {
	    remove_ob $rborder
	} 
    }
}


bind .field <2> { 
    global All_Obs New_Started prevX prevY Ob_List help1 help2 Color
    .field raise current
    .field raise arrow
    .field raise start
    .field raise goal
    if {!$New_Started} { 
	# this has to do with the movement
        global curX curY
        set curX [p_m %x]
	set curY [p_m %y]
	set Ob_List(temp) {}
    } else {
	global All_Obs New_Started origX origY Ob_List
	set help1 "Click to place the first vertex"
	set help2 "Click and drag to move object"
	lappend Ob_List(temp) [p_m %x] [p_m %y]
	set New_Started 0
	if {[expr [llength $Ob_List(temp)]/2] > $MaxVertices} {
	    set Ob_List(temp) {}
	    .field delete line
	    dialog "Sorry, obstacles may have only up to $MaxVertices vertices" 1
	    return
	}
	if {[expr [llength $Ob_List(temp)]/2] <= 2} {
	    set Ob_List(temp) {}
	    .field delete line
	    dialog "Sorry, polygons must have at least 3 sides" 1
	    return
	}  
	
	if {[legal_coords $Ob_List(temp)]} {
	    set new_poly [eval .field create polygon [m_p_list $Ob_List(temp)] \
		    -fill $Color(Obstacle) -tags obstacle]
	    set Ob_List($new_poly) $Ob_List(temp)
	    lappend All_Obs $new_poly
	}
	set Ob_List(temp) {}
	.field delete line
    }
}

.field bind obstacle <B2-Motion> {
    global Ob_List
    set ob [.field find withtag current]
    set Here(x) [p_m %x]
    set Here(y) [expr $YMAX - [p_m %y]]
    
    set dx [expr [p_m %x]-$curX]
    set dy [expr [p_m %y]-$curY]
    set newxs [list_incr [extract x $Ob_List($ob)] $dx]
    set newys [list_incr [extract y $Ob_List($ob)] $dy]
#    if {![in_bounds $newxs X]} {set newxs  [extract x $Ob_List($ob)]}
#    if {![in_bounds $newys Y]} {set newys  [extract y $Ob_List($ob)]}
    update_obstacle $ob [zip $newxs $newys]
    set curX [p_m %x] 
    set curY [p_m %y]
}

bind .options2.mode.rect <1> {
    global Mode New_Started Mode Color
    set Mode rect
    set help1 "Click and drag to create rectangle"
    set help2 "Click and drag to move object"
    set help4 ""
    set help5 ""
    .field itemconfigure selected -fill $Color(Obstacle)
    .field dtag selected selected
}


bind .options2.mode.poly <1> {
    global Mode New_Started Mode help1 help2 Color
    set Mode poly
    set help1 "Click to place the first vertex"
    set help2 "Click and drag to move object"
    set help4 ""
    set help5 ""
    .field itemconfigure selected -fill $Color(Obstacle)
    .field dtag selected selected
}


bind .options2.mode.select <1> {
    global Mode New_Started help1 help4 help5
    set Mode select
    set help1 "Click to select obstacle"
    set help4 "Press \"C\" to copy selected"
    set help5 "Press \"R\" to rotate selected"
}


#### COPY OBSTACLE  #####
bind all <Any-c> {
    global Ob_List All_Obs OPTIONS Color
    set thisone [.field find withtag selected]
    if {$thisone != ""} {
	set newcoords [list_incr [real_p_m_list [.field coords $thisone]] $OPTIONS(grid)]
	set newpixels [m_p_list $newcoords]
	set rborder [eval .field create polygon \
		$newpixels -fill $Color(Obstacle) -tags obstacle]
	lappend All_Obs $rborder
	set Ob_List($rborder) $newcoords
    }
}

bind all <Any-r> {
    global Ob_list
    set thisone [.field find withtag selected]
    if {$thisone != ""} {
	set coords [.field coords $thisone]
	set xs [extract x $coords]
	set ys [extract y $coords]
	set midx [list_center $xs]
	set midy [list_center $ys]
	set centcoords [zip [list_incr $xs [expr -$midx]] [list_incr $ys [expr -$midy]]]
    

	proc call_rotation_window {ob cent mx my} {
	    global Ob_List 
	    toplevel .rotate
	    wm title .rotate "Obstacle Rotation"
	    scale .rotate.scale -from 0 -to 360 -length 400 -label "Rotation Angle" \
		    -orient horizontal -command "do_rotate $ob [list $cent] $mx $my"
	    button .rotate.done -text "Done" -relief raised -bd 3 -command \
		    {destroy .rotate}
	    pack .rotate.scale -side top -pady 2m
	    pack .rotate.done -side bottom -ipadx 3m -ipady 1m
	    
	    proc do_rotate {ob2 coords x2 y2 value} {
		global Ob_List
		set rot_list [rotate_by_degrees $coords [expr -$value]]
		set rxs [extract x $rot_list]
		set rys [extract y $rot_list]
		set finally [zip [list_incr $rxs $x2] [list_incr $rys $y2]]
		update_obstacle $ob2 [real_p_m_list $finally]
	    }
	}
	call_rotation_window $thisone $centcoords $midx $midy
    }
}

puts "sourcing buttons.tcl"
source buttons.tcl
puts "sourcing start.tcl"
source start.tcl
puts "sourcing goal.tcl"
source goal.tcl
puts "sourcing path.tcl"
source "path.tcl"

focus .
focus default .