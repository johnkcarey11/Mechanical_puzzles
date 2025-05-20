###############  MISCELLANEOUS HELPER FUNCTIONS  #################




proc snap {coord snap_amt} {
     set t1 [expr $coord / $snap_amt]
    set t2 [expr round($t1)]
    return [expr $t2 * $snap_amt]
} 


proc snap_list {coord_list snap_amt} {
    foreach c $coord_list {
	lappend newlist [snap $c $snap_amt]
    }
    return $newlist
}

proc p_m pixels {
    global OPTIONS PMConversion
    set real_coord [expr $pixels / $PMConversion]
    return [snap $real_coord $OPTIONS(grid)]
}

#for no snapping
proc real_p_m pixels {
    global OPTIONS PMConversion
    set real_coord [expr $pixels / $PMConversion]
    return $real_coord 
}


proc m_p millis {
    global PMConversion
    set pixels [expr $millis * $PMConversion] 
    return $pixels
}

proc m_p_list millilist {
    foreach c $millilist {
	lappend newlist [m_p $c]
    }
    return $newlist
}

proc p_m_list plist {
    foreach c $plist {
	lappend newlist [p_m $c]
    }
    return $newlist
}

proc real_p_m_list plist {
    foreach c $plist {
	lappend newlist [real_p_m $c]
    }
    return $newlist
}


proc set_array {array1 array2} {
    upvar 1 $array1 a1
    upvar 1 $array2 a2
    foreach index [array names a2] {
	if {$a2($index) == ""} continue;
	set a1($index) $a2($index) 
    }
}
 

proc extract {x_or_y coord_list} {
    if {$x_or_y == "x"} {set index 0} else {set index 1}
    for {} {$index < [llength $coord_list]} {incr index 2} {
	lappend gooduns [lindex $coord_list $index]
    }
    return $gooduns
}

proc zip {list1 list2} {
    for {set i 0} {$i < [llength $list1]} {incr i} {
	lappend newlist [lindex $list1 $i] [lindex $list2 $i]
    }
    return $newlist
}


proc list_sum coordlist {
    set sum 0.0
    foreach k $coordlist {
	set sum [expr $sum + $k]
    }
    return $sum
}


# to find the center in a range of coordinates
proc list_center coordlist {
    set sum [list_sum $coordlist]
    return [expr $sum / [llength $coordlist]]
}


proc list_incr {l diff} {
    for {set i 0}  {$i < [llength $l]} {incr i} {
	set x [expr $diff + [lindex $l $i]]
	lappend newlist $x
    }
    return $newlist
}

proc reverse_list clist {
    set revlist {}
    for {set i [llength $clist]} {$i > 0} {incr i -1} {
	lappend revlist [lindex $clist [expr $i-1]]
    }
    return $revlist
}

proc reverse_coord_list clist {
    set revlist {}
    for {set i [llength $clist]} {$i > 1} {incr i -2} {
	lappend revlist [lindex $clist [expr $i-2]] [lindex $clist [expr $i-1]]
    }
    return $revlist
}

## makes all ints floats, while keeping all floats floats using the miracle of the identity
proc floatify clist {
    foreach mem $clist {
	lappend newlist [expr 1.0 * $mem]
    }
    return $newlist
}

#max in list
proc max l {
    set m [lindex $l 0]
    for {set i 1} {$i < [llength $l]} {incr i} {
	if {$m < [lindex $l $i]} {set m [lindex $l $i]}
    }
    return $m
}

#min in list
proc min l {
    set m [lindex $l 0]
    for {set i 1} {$i < [llength $l]} {incr i} {
	if {$m > [lindex $l $i]} {set m [lindex $l $i]}
    }
    return $m
}

## returns the LIST INDEX of the greatest x coordinate in the list
proc max-xcoordinate clist {
    set maxindex 0
    for {set i 0} {$i < [llength $clist]} {incr i 2} {
	if {[lindex $clist $maxindex] < [lindex $clist $i]} {
	    set maxindex $i
	}
    }
    # this part checks that the greatest index isn't in between two other ones
    if {$maxindex == 0 && \
	    [lindex $clist 0] == [lindex $clist 2] && \
	    [lindex $clist 0] == [lindex $clist [expr [llength $clist] -2]] } {
	set maxindex 2
    }
    return $maxindex
}

## lies_to will return "left" if the polygon's coords are listed "counter-clockwise"
## returns right if "clock-wise"

proc lies_to clist {
    set maxx [max-xcoordinate $clist]
    set clength [llength $clist]
    set x [lindex $clist $maxx]
    set y [lindex $clist [expr $maxx + 1]]
    if {$maxx == 0} {
	set xp [lindex $clist [expr $clength - 2]]
	set yp [lindex $clist [expr $clength - 1]]
    } else {
	set xp [lindex $clist [expr $maxx - 2]]
	set yp [lindex $clist [expr $maxx - 1]]
    }
    if {$maxx == [expr $clength - 2]} {
	set xn [lindex $clist 0]
	set yn [lindex $clist 1]
    } else {
	set xn [lindex $clist [expr $maxx + 2]]
	set yn [lindex $clist [expr $maxx + 3]]
    }
 
    set vx1 [expr $x - $xp]
    set vy1 [expr $y - $yp]
    set vx2 [expr $xn - $x]
    set vy2 [expr $yn - $y]
    if {[cross_product [list $vx1 $vy1] [list $vx2 $vy2]] > 0} {
	return "left"
    } else {
	return "right"
    }
}
   
proc legal_coords coordlist {
    set length [llength $coordlist]
    if {[expr fmod($length,2) != 0]} {
	error "Error in legal_coords:  coordlist has odd number of members"
    }
    for {set i 0} {$i < [expr $length -2]} {incr i 2} {
	if {[expr [lindex $coordlist $i] == [lindex $coordlist [expr $i+2]] \
		&& [lindex $coordlist [expr $i+1]] == [lindex $coordlist [expr $i+3]]]} {
	    return 0
	}
    }
    return 1
}

proc dialog {m wait} {
    toplevel .dialog
    wm title .dialog "Message"
    wm geometry .dialog -0-0
    message .dialog.msg -text $m -width 4i
    button .dialog.b -text "OK" -relief groove \
	    -command {destroy .dialog}
    pack .dialog.msg -side top -pady 5m
    pack .dialog.b -ipadx 3m -ipady 3m -side bottom
    set topcoords [wm geometry .]
    regsub -all x $topcoords " " topcoords
    regsub -all {\+} $topcoords " " topcoords
    regsub -all {\-} $topcoords " " topcoords
    set a [lindex $topcoords 0]
    set b [lindex $topcoords 1]
    set c [lindex $topcoords 2]
    set d [lindex $topcoords 3]
    update idletasks
    set topcoords [wm geometry .dialog]
    regsub -all x $topcoords " " topcoords
    regsub -all {\+} $topcoords " " topcoords
    regsub -all {\-} $topcoords " " topcoords
    set w [lindex $topcoords 0]
    set x [lindex $topcoords 1]
    set y [expr ($c + $a/2) - $w/2]
    set z [expr ($d + $b/2) - $x/2]
    wm geometry .dialog +${y}+${z}

    grab .dialog
    if {$wait} {tkwait window .dialog}
}

proc dot_product {u v} {
    set a [lindex $u 0]
    set b [lindex $u 1]
    set c [lindex $v 0]
    set d [lindex $v 1]
    return [expr $a * $c + $b * $d]
}

proc cross_product {u v} {
    set a [lindex $u 0]
    set b [lindex $u 1]
    set c [lindex $v 0]
    set d [lindex $v 1]
    return [expr $a * $d - $b * $c ]
}



########### OBSTACLE RELEVANT HELPER FUNCTIONS ############   
         ## helpers that use global variables  ##

# Globals for Obstacles
# All_Obs (list of all obstacles)
# New_Started
# Ob_List() (Array of lists giving coordinates for each Obstacle)

#This will take a maximum value (XMAX or YMAX) and figure out the conversion as well as
#the cell sizes
proc convert {} {
    global XMAX YMAX OPTIONS PMConversion
    if {$XMAX > $YMAX} {set max $XMAX} else {set max $YMAX}
    set PMConversion [expr 180 * 3.54 / $max]
}



proc remove_ob {ob} {
    global All_Obs
    .field delete $ob

    # Removal from list of all obstacles
    set index [lsearch $All_Obs $ob]
    if {$index > -1} {
	set All_Obs [lreplace $All_Obs $index $index]  ;#removes from list
    }
}

#uses cute string substitution (X_orY must be "X" or "Y") (l is a list of coords)
proc in_bounds {l X_or_Y} {
    eval "global ${X_or_Y}MAX"
    for {set i 0} {$i < [llength $l]} {incr i} {
	set x [lindex $l $i]
	eval "if { $x < 0 || $x > \$${X_or_Y}MAX} {return 0}"
    }
    return 1
}

proc update_obstacle {ob coord_list} {
    global Ob_List
    eval .field coords $ob [m_p_list $coord_list]
    set Ob_List($ob) $coord_list
}


## fakeify will take a coordinate list in the y-axis is down mode, and change it to
# the "fake" mode where y+ is up
proc fakeify coordlist {
    global YMAX
    for {set index 0} {$index < [llength $coordlist]} {incr index 2} {
	lappend newlist [lindex $coordlist $index] \
		[expr $YMAX - [lindex $coordlist [expr $index + 1]]]
    }
    return $newlist
}

proc flip_y coordlist {
    for {set index 0} {$index < [llength $coordlist]} {incr index 2} {
	lappend newlist [lindex $coordlist $index] \
		[expr 0 - [lindex $coordlist [expr $index + 1]]]
    }
    return $newlist
}  

proc is_rectangle ob_id {
    global Ob_List
    return [expr {[llength $Ob_List($ob_id)] == 4}]
}

#this will redraw all start, goal, obstacles (no paths, that's silly)
#assumes that all globals are up to date
proc redraw_canvas {} {
    global XMAX YMAX All_Obs Ob_List
    .options2.kill_path invoke
    .field configure -height [m_p $YMAX] -width [m_p $XMAX] 
    update_start
    update_goal
    foreach ob $All_Obs {
	update_obstacle $ob $Ob_List($ob)
    }
}
    