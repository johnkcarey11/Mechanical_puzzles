#draws one step of path

proc draw_border {x y theta edge} {
    global Start YMAX Color
    
    set tempcoords $Start(init_coords)
    set tempcoords [rotate_by_degrees $tempcoords [expr - [r_d $theta]]]
    set length [llength $tempcoords]
    for {set i 0} {$i < [expr $length -3]} {incr i 2} {
	if {[expr $i/2] == $edge && $edge != -1} {
	    set color $Color(PushEdge); set width 3
	} else {
	    set color $Color(Path); set width 1
	}
	set x1 [expr $x + [lindex $tempcoords $i]]
	set y1 [expr $YMAX - $y + [lindex $tempcoords [expr $i+1]]]
	set x2 [expr $x + [lindex $tempcoords [expr $i+2]]]
	set y2 [expr $YMAX - $y + [lindex $tempcoords [expr $i+3]]]
	set coords [list [m_p $x1] [m_p $y1] [m_p $x2] [m_p $y2]]
	eval .field create line $coords -fill $color -tags path -width $width
    }
    if {[expr $i/2] == $edge && $edge != -1} {
	set color $Color(PushEdge); set width 3
    } else {
	set color $Color(Path); set width 1
    }
    set x1 [expr $x + [lindex $tempcoords $i]]
    set y1 [expr $YMAX - $y + [lindex $tempcoords [expr $i+1]]]
    set x2 [expr $x + [lindex $tempcoords 0]]
    set y2 [expr $YMAX - $y + [lindex $tempcoords 1]]
    set coords [list [m_p $x1] [m_p $y1] [m_p $x2] [m_p $y2]]
    eval .field create line $coords -fill $color -tags path -width $width
    
}

proc draw_path filename {
    global PATH_LIST
    set PATH_LIST {}
    if {[file exists $filename] == 0} {
	error "Error in draw_path:  File $filename doesn't exist"
    }
    set f [open $filename]
    set sassafras -1
    while {[gets $f next_line] != -1} {
	draw_border [lindex $next_line 0] [lindex $next_line 1] [lindex $next_line 2] $sassafras
	set sassafras [lindex $next_line 3]
	lappend PATH_LIST $next_line
    }
    set PATH_LIST [reverse_list $PATH_LIST]
}

proc animate {} {
    global PATH_LIST Tempo Frame PlayDir Stop_enabled Start Color
    
    set PlayDir 1
    set Tempo 50
    set Frame 0
    set Stop_enabled 1
    toplevel .animate
    wm title .animate "Planner Animation"
    frame .animate.butts
    frame .animate.other
    button .animate.done -relief raised -bd 3 -command done -text "Done"
    scale .animate.speed -from 1 -to 10 -command setTempo -label "Playback Speed" \
	    -orient horizontal -length 6c
    button .animate.butts.play -relief raised -bd 3 -command play -text Play
    button .animate.butts.frame_adv -relief raised -bd 3 -command frame_adv -text "Frame Adv"
    button .animate.butts.rewind -relief raised -bd 3 -command rewind -text Rew
    button .animate.butts.stop -relief raised -bd 3 -command stop -text Stop
    button .animate.butts.ffwd -relief raised -bd 3 -command ffwd -text F-Fwd
    button .animate.other.chdir -relief raised -bd 3 -command change_direction \
	    -text "Change Playback direction ->"

    pack .animate.butts.play .animate.butts.frame_adv .animate.butts.rewind \
	    .animate.butts.stop .animate.butts.ffwd -side left -ipady 2 -ipadx 1
    pack .animate.other.chdir -side left -ipadx 1 -ipady 2
    pack .animate.butts .animate.speed .animate.other .animate.done

      eval .field create polygon [m_p_list $Start(actual_coords)]  \
	    -fill $Color(Animate) -tags frame


    proc setTempo value {
	global Tempo
	set Tempo $value
    }

    proc done {} {
	destroy .animate
	.field delete frame
	focus .
    }

    proc change_direction {} {
	global PlayDir
	set PlayDir [expr -$PlayDir]
	if {$PlayDir == 1} {
	    set txt "Change Playback Direction ->"
	} else {
	    set txt "Change Playback Direction <-"
	}
	.animate.other.chdir configure -text $txt
    }

    proc stop {} {
	global Stop_enabled 
	set Stop_enabled 1
	update
    }

    proc rewind {} {
	global Frame Start
	set Frame 0
	eval ".field coords frame [m_p_list $Start(actual_coords)]"
	update
    }

    proc ffwd {} {
	global Frame Goal PATH_LIST
	set Frame [expr [llength $PATH_LIST] -1]
	eval ".field coords frame [m_p_list $Goal(actual_coords)]"
	update
    }

    proc play {} {
	global Stop_enabled PATH_LIST Tempo Frame PlayDir Start YMAX
	set l [llength $PATH_LIST]
	set nowcoords $Start(init_coords)
	set Stop_enabled 0
	
	for {} {$Frame > -1 && $Frame < $l && !$Stop_enabled} \
		{incr Frame $PlayDir} {
	    update
	    after [expr 100 * 1/$Tempo]
	    set nowcoords $Start(init_coords)
	    set current [lindex $PATH_LIST $Frame]
	    set nowx [lindex $current 0]
	    set nowy [expr $YMAX - [lindex $current 1]]
	    set nowtheta [r_d [lindex $current 2]]
	    set nowedge [lindex $current 3]
	    
	    set nowcoords [rotate_by_degrees $nowcoords [expr -$nowtheta]]
	    set newxs [list_incr [extract x $nowcoords] $nowx]
	    set newys [list_incr [extract y $nowcoords] $nowy]
	    set nowcoords [zip $newxs $newys]
	    set nowcoords [m_p_list $nowcoords]
	    eval ".field coords frame $nowcoords"
	}
	if {$Frame >= $l} {set Frame [expr $l -1]}
	if {$Frame < 0} {set Frame 0}

	set Stop_enabled 1
    }

    proc frame_adv {} {
	global Stop_enabled PATH_LIST Tempo Frame PlayDir Start YMAX
	set l [llength $PATH_LIST]
	set nowcoords $Start(init_coords)
		
	incr Frame $PlayDir
	if {$Frame < 0} {set Frame 0; return}
	if {$Frame > [expr $l -1]} {set Frame [expr $l -1]; return}
	set nowcoords $Start(init_coords)
	set current [lindex $PATH_LIST $Frame]
	set nowx [lindex $current 0]
	set nowy [expr $YMAX - [lindex $current 1]]
	set nowtheta [r_d [lindex $current 2]]
	set nowedge [lindex $current 3]
	
	set nowcoords [rotate_by_degrees $nowcoords [expr -$nowtheta]]
	set newxs [list_incr [extract x $nowcoords] $nowx]
	set newys [list_incr [extract y $nowcoords] $nowy]
	set nowcoords [zip $newxs $newys]
	set nowcoords [m_p_list $nowcoords]
	eval ".field coords frame $nowcoords"
    }
    grab .animate
    tkwait window .animate
}

    