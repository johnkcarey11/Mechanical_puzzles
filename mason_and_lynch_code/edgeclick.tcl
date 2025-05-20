proc normal {x y} {
    return [list [expr 0.0 - $y] $x]
}

proc distance_to_edge {edge xp yp} {
    global Ob_edge
    set coords $Ob_edge($edge,coords)
    
    set xa [lindex $coords 0]
    set ya [expr 0 - [lindex $coords 1]]
    set xb [lindex $coords 2]
    set yb [expr 0 - [lindex $coords 3]]
    
    set a [list [expr $xp - $xa] [expr $yp - $ya]]
    set b [list [expr $xp - $xb] [expr $yp - $yb]]
    set c [vector_diff $b $a]
    

    set oogabooga [expr [dot_product $c $a] * [dot_product $c $b]]
    if {$oogabooga < 0} {
	set u [unit_normal $c]
	set dist [dot_product $a $u]
	return [expr abs($dist)]
    } else {
	set dista [vector_magnitude $a]
	set distb [vector_magnitude $b]
	return [min [list $dista $distb]]
    }
}

bind .obedit.field <3> {
    global edge_count Object_coords Color Ob_edge None_present
    if {$None_present} return
    set closest 0
    set distance 9999.9
    set x [transform %x]
    set y [expr 0 - [transform %y]]
    for {set i 0} {$i < $edge_count} {incr i} {
	set newdistance [distance_to_edge $i $x $y]
	if {$distance > $newdistance} {
	    set closest $i
	    set distance $newdistance
	}
    }
    if {!$Ob_edge($closest,pushable)} {
	set Ob_edge($closest,id) [eval .obedit.field create line \
		[untransform_list $Ob_edge($closest,coords)] \
		-tags edge -width 4 -fill $Color(pushable)]
	.obedit.field itemconfigure $Ob_edge($closest,id) -fill $Color(pushable) -width 4
	set Ob_edge($closest,pushable) 1
    } else {
	.obedit.field delete $Ob_edge($closest,id)
	set Ob_edge($closest,pushable) 0
    }
    update idletasks
}