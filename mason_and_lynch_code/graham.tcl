proc compare_2nd {alist blist} {
    set a [lindex $alist 1]
    set b [lindex $blist 1]
    if {$a < $b} {return -1}
    if {$a == $b} {return 0}
    return 1
}

proc sort_cc coordlist {
    set l [llength $coordlist]
    for {set i 0} {$i < $l} {incr i 2} {
	set x [lindex $coordlist $i]
	set y [lindex $coordlist [expr $i+1]]
	lappend indexlist [list $i [expr atan2($y,$x)]]
    }
    set indexlist [lsort -command compare_2nd $indexlist]
    foreach j $indexlist {
	set i [lindex $j 0] 
	lappend newlist [lindex $coordlist $i] [lindex $coordlist [expr $i+1]]
    }
    return $newlist
}



proc graham {} {
    global Object_coords new_list start
    set coordlist [flip_y $Object_coords]

    set coordlist [sort_cc $coordlist]
 
    set newlist $coordlist
    set i [max-xcoordinate $coordlist]
    set start $i
    set pred [expr $start - 2]
    if {$pred < 0} {set pred [expr $pred + [llength $newlist]]}
    set j [expr $i + 2]
    set f false
    while {1} {
	set l [llength $newlist]
	if {$i < 0} {set i [expr $i + $l]}
	if {$i >= $l} {set i [expr $i - $l]}
	
	set j [expr $i + 2]
	set k [expr $i + 4]
	if {$j >= $l} {set j [expr $j - $l]}
	if {$k >= $l} {set k [expr $k - $l]}
	if {$j == $start && $f=="true"} break
	set x0 [lindex $newlist $i]
	set y0 [lindex $newlist [expr $i + 1]]
	set x1 [lindex $newlist $j]
	set y1 [lindex $newlist [expr $j + 1]]
	set x2 [lindex $newlist $k]
	set y2 [lindex $newlist [expr $k + 1]]
	set a [list [expr $x1 - $x0] [expr $y1 - $y0]]
	set b [list [expr $x2 - $x1] [expr $y2 - $y1]]
	if {$j == $pred} {set f true}
	if {[cross_product $a $b] < 0} {
	    set newlist [lreplace $newlist $j [expr $j + 1]]
	    if {$start >= $j} {
		incr start -2
	    }
	    if {$pred >= $j} {
		incr pred -2
	    }	    
	    incr i -2
	} else {
	    incr i 2
	}
    }
    set Object_coords [flip_y $newlist]
}

proc redo_object {} {
    global Ob_edge edge_count Object_coords Color
    set l [llength $Object_coords]
    set edge_count [expr $l/2]
    .obedit.field delete edge
    .obedit.field delete object
    unset Ob_edge

    #  since Object_coords is actually flipped....
    if {[lies_to $Object_coords] == "left"} {
	set Object_coords [reverse_coord_list $Object_coords]
    }

    eval .obedit.field create polygon [untransform_list $Object_coords] \
	    -fill $Color(Object) -tags object
    
    for {set i 0} {$i < [expr $l-2]} {incr i 2} {
	set x1 [lindex $Object_coords $i]
	set y1 [lindex $Object_coords [expr $i+1]]
	set x2 [lindex $Object_coords [expr $i+2]]
	set y2 [lindex $Object_coords [expr $i+3]]
	set edge [expr $i/2]
	#    set Ob_edge($edge,id) [eval .obedit.field create line \
	#		[untransform_list [list $x1 $y1 $x2 $y2]] -width 2 -fill black -tags edge]
	set Ob_edge($edge,coords) [list $x1 $y1 $x2 $y2]
	set Ob_edge($edge,pushable) 0
    }   
    set x1 [lindex $Object_coords $i]
    set y1 [lindex $Object_coords [expr $i+1]]
    set x2 [lindex $Object_coords 0]
    set y2 [lindex $Object_coords 1]
    set edge [expr $i/2]
    #   set Ob_edge($edge,id) [eval .obedit.field create line \
    #	    [untransform_list [list $x1 $y1 $x2 $y2]] -width 2 -fill black -tags edge]
    set Ob_edge($edge,coords) [list $x1 $y1 $x2 $y2]
    set Ob_edge($edge,pushable) 0
}

proc use_hull {} {
    if {[.obedit.field find withtag object] == ""} return
    graham
    redo_object
    .obedit.field raise object
    .obedit.field raise crosshairs
}