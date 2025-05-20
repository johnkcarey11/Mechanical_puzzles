### this file will do all the line stuff

#takes two points, and gives the slope
proc get_slope {x1 y1 x2 y2} {
    if {[expr $x2 - $x1] != 0]} {
	return [expr ($y2-$y1)/($x2-$x1)]
    } else {
	return "infinity"
    }
}

proc slope_normal m {
    if {$m == 0} {
	return "infinity"
    } 
    if {$m == "infinity"} {
	return 0.0
    }
    return [expr -1/$m]
}


proc point_slope_draw_line {x0 y0 m color} {
    global ObMAX
    if {$m == "infinity"} {
	eval .obedit.field create line [untransform_list [list $x0 -$ObMAX $x0 $ObMAX]] \
		-fill $color -tags testline
    } else {
	set ymin [expr $m * (-$ObMAX - $x0) + $y0]
	set ymax [expr $m * ($ObMAX - $x0) + $y0]
	eval .obedit.field create line [untransform_list [list -$ObMAX -$ymin $ObMAX -$ymax]] \
		-fill $color -tags testline
    }
}

proc abc_draw_line {a b c color} {
    if {$b == 0} {
	point_slope_draw_line [expr 0 - $c / $a] 0 infinity $color
    } else {
	set m [expr 0 - $a / $b]
	set y0 [expr 0 - $c / $b]
	point_slope_draw_line 0 $y0 $m $color
    }
}


# implements vectors as lists
proc normalize vector {
    set x [lindex $vector 0]
    set y [lindex $vector 1]
    set norm [expr hypot($x,$y)]
    return [list [expr $x / $norm] [expr $y / $norm]]
}

proc unit_normal v {
    set n [normal [lindex $v 0] [lindex $v 1]]
    return [normalize $n]
}

proc vector_sum {a b} {
    set aa [expr [lindex $a 0] + [lindex $b 0]]
    set bb [expr [lindex $a 1] + [lindex $b 1]]
    return [list $aa $bb]
}

proc vector_diff {a b} {
    set aa [expr [lindex $a 0] - [lindex $b 0]]
    set bb [expr [lindex $a 1] - [lindex $b 1]]
    return [list $aa $bb]
}

proc vector_scalar_mult {vect scal} {
    set x [expr [lindex $vect 0] * $scal]
    set y [expr [lindex $vect 1] * $scal]
    return [list $x $y]
}

proc fuzzy_equals {x y} {
    global FUZZY
    return [expr abs([expr $x - $y]) <= $FUZZY]
}

proc fuzzy_less_than_or_equal {x y} {
    global FUZZY
    return [expr $x <= ($y + $FUZZY)]
}

proc fuzzy_greater_than_or_equal {x y} {
    global FUZZY
    return [expr $x >= ($y - $FUZZY)]
}

proc vector_magnitude a {
    return [expr hypot([lindex $a 0],[lindex $a 1])]
}

proc angle_in_range {test left right} {
    if {$right > $left} {
	return [expr ($right <= $test) || ($test <= $left)]
    } else {
	return [expr ($right <= $test) && ($test <= $left)]
    }
}

#################################

proc test_friction edge {
    global Ob_edge edge_count Color
    if {$Ob_edge($edge,translations) == {}} {
	return
    }
    set_friction_lines_for_edge $edge
    set l1 [concat $Ob_edge($edge,line,1) [list $Color(fricline)]]
    set l2 [concat $Ob_edge($edge,line,2) [list $Color(fricline)]]
    set l3 [concat $Ob_edge($edge,line,3) [list $Color(fricline)]]
    set l4 [concat $Ob_edge($edge,line,4) [list $Color(fricline)]]
    
    eval abc_draw_line $l1  
    eval abc_draw_line $l2
    eval abc_draw_line $l3
    eval abc_draw_line $l4
}

proc test_edge edge {
    global Ob_edge edge_count Color
    if {$Ob_edge($edge,translations) == {}} {
	return
    }
    set_edge_lines_for_edge $edge 
    set l5 [concat $Ob_edge($edge,line,5) [list $Color(edgeline)]]
    set l6 [concat $Ob_edge($edge,line,6) [list $Color(edgeline)]]
    set l7 [concat $Ob_edge($edge,line,7) [list $Color(edgeline)]]
    set l8 [concat $Ob_edge($edge,line,8) [list $Color(edgeline)]]
    
    eval abc_draw_line $l5  
    eval abc_draw_line $l6
    eval abc_draw_line $l7
    eval abc_draw_line $l8
}
