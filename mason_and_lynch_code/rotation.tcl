proc d_r degrees {
    set radians [expr $degrees*3.14159/180]
    return $radians
}

proc r_d radians {
    set degrees [expr $radians*180/3.14159]
    return $degrees
}

proc rotate_by_degrees {xy_list theta} {
    set rads [d_r $theta]
    for {set i 0} {$i < [llength $xy_list]} {incr i 2} {
	set x [lindex $xy_list $i]
	set y [lindex $xy_list [expr $i+1]]
	set newx [expr $x*cos($rads) - $y*sin($rads)]
	set newy [expr $x*sin($rads) + $y*cos($rads)]
	lappend newlist $newx $newy
    } 
    return $newlist
}

