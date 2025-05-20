
proc get_trans e {
    global Ob_edge Mu Zero_Vector
    set trans {}
    set coordlist [flip_y $Ob_edge($e,coords)]
    
    set xa [lindex $coordlist 0]
    set ya [lindex $coordlist 1]
    set xb [lindex $coordlist 2]
    set yb [lindex $coordlist 3]
    set k [vector_diff [list $xb $yb] [list $xa $ya]]
    set n [unit_normal $k]
    set t [normalize $k]
    set fl [normalize [vector_diff $n [vector_scalar_mult $t $Mu]]]
    set fr [normalize [vector_sum $n [vector_scalar_mult $t $Mu]]]
    set el [normalize [list [expr 0 - $xb] [expr 0 - $yb]]]
    set er [normalize [list [expr 0 - $xa] [expr 0 -$ya]]]
    if {[fuzzy_equals [dot_product $el $er] 1.0]} {
	return $trans
    }

    set Ob_edge($e,friction,fl) $fl
    set Ob_edge($e,friction,fr) $fr
    set Ob_edge($e,edge,el) $el
    set Ob_edge($e,edge,er) $er
    
    if {[dot_product $el $n] < 0} {
	set temp $el
	set el [vector_diff $Zero_Vector $er]
	set er [vector_diff $Zero_Vector $temp]
    }
    set flangle [expr atan2([lindex $fl 1],[lindex $fl 0])]
    set frangle [expr atan2([lindex $fr 1],[lindex $fr 0])]
    set elangle [expr atan2([lindex $el 1],[lindex $el 0])]
    set erangle [expr atan2([lindex $er 1],[lindex $er 0])]

    set leftedge {}
    set rightedge {}
    if {[angle_in_range $flangle $elangle $erangle]} {
	set leftedge [list [lindex $fl 0] [lindex $fl 1] 0.0]
    } elseif {[angle_in_range $elangle $flangle $frangle]} {
	set leftedge [list [lindex $el 0] [lindex $el 1] 0.0]
    }
    if {[angle_in_range $frangle $elangle $erangle]} {
	set rightedge [list [lindex $fr 0] [lindex $fr 1] 0.0]
    } elseif {[angle_in_range $erangle $flangle $frangle]} {
	set rightedge [list [lindex $er 0] [lindex $er 1] 0.0]
    }
    if {[expr [string compare $leftedge $rightedge]]} {
	lappend trans $leftedge
	lappend trans $rightedge
    } else {
	lappend trans $leftedge
    }
    return $trans
}

proc set_friction_lines_for_edge e {
    global Ob_edge edge_count
    
    if {$Ob_edge($e,translations) == {}} {
	return
    }
    set cur_coords [flip_y $Ob_edge($e,coords)]
    set max_point_fl [list [lindex $cur_coords 0] [lindex $cur_coords 1]]
    set min_point_fl $max_point_fl
    set max_point_fr $max_point_fl
    set min_point_fr $max_point_fl
    set fl $Ob_edge($e,friction,fl)
    set fr $Ob_edge($e,friction,fr)
    set flx [lindex $fl 0]
    set fly [lindex $fl 1]
    set frx [lindex $fr 0]
    set fry [lindex $fr 1]

    for {set i 0} {$i < $edge_count} {incr i} {
	set cur_coords [flip_y $Ob_edge($i,coords)]
	set cur_point [list [lindex $cur_coords 0] [lindex $cur_coords 1]]
	set cur_dot_fl [dot_product $cur_point $fl]
	set cur_dot_fr [dot_product $cur_point $fr]
	
	if {$cur_dot_fl > [dot_product $max_point_fl $fl]} { set max_point_fl $cur_point }
	if {$cur_dot_fl < [dot_product $min_point_fl $fl]} { set min_point_fl $cur_point }
	if {$cur_dot_fr > [dot_product $max_point_fr $fr]} { set max_point_fr $cur_point }
	if {$cur_dot_fr < [dot_product $min_point_fr $fr]} { set min_point_fr $cur_point }
		
    }
    
    # lines will be stored as lists of {a b c}
    
    set Ob_edge($e,line,1) [list $flx $fly [expr 0 - $flx*[lindex $min_point_fl 0] - $fly * \
	    [lindex $min_point_fl 1]]]
    set Ob_edge($e,line,2) [list $flx $fly [expr 0 - $flx*[lindex $max_point_fl 0] - $fly * \
	    [lindex $max_point_fl 1]]]
    set Ob_edge($e,line,3) [list $frx $fry [expr 0 - $frx*[lindex $min_point_fr 0] - $fry * \
	    [lindex $min_point_fr 1]]]
    set Ob_edge($e,line,4) [list $frx $fry [expr 0 - $frx*[lindex $max_point_fr 0] - $fry * \
	    [lindex $max_point_fr 1]]]
}

# here coordlist is a list {x y x y x y...}
proc find_r coordlist {
    set l [llength $coordlist]
    set r 0.0
    for {set i 0} {$i < $l} {incr i 2} {
	set this_one [list [lindex $coordlist $i] [lindex $coordlist [expr $i+1]]]
	set this_dist [vector_magnitude $this_one]
	if {$this_dist > $r} {set r $this_dist}
    }
    return $r
}


proc set_edge_lines_for_edge edge {
    global Ob_edge Object_coords SAFETY
    if {$Ob_edge($edge,translations) == {}} return
    set cur_coords [flip_y $Ob_edge($edge,coords)]
 
    set xa [lindex $cur_coords 0]
    set ya [lindex $cur_coords 1]
    set xb [lindex $cur_coords 2]
    set yb [lindex $cur_coords 3]  
    set k [vector_diff [list $xb $yb] [list $xa $ya]]
    set n [unit_normal $k]
    set a [list $xa $ya]
    set b [list $xb $yb]
    # el is from point B to C, er is from A to C

    set el $Ob_edge($edge,edge,el)
    set er $Ob_edge($edge,edge,er)
    set elx [lindex $el 0]
    set ely [lindex $el 1]
    set erx [lindex $er 0]
    set ery [lindex $er 1]

    if {[dot_product $er $n] >= 0} {
	set d 1
    } else {
	set d -1
    }

    set prx [expr $xa / 2.0]
    set pry [expr $ya / 2.0]
    set plx [expr $xb / 2.0]
    set ply [expr $yb / 2.0]

  
    set r [find_r [flip_y $Object_coords]]
   
    set Pr [vector_magnitude $a]
    set Pl [vector_magnitude $b]

  
    set r2Pr [vector_scalar_mult $er [expr ($r * $r / $Pr) * $SAFETY]]
    set r2Pl [vector_scalar_mult $el [expr ($r * $r / $Pl) * $SAFETY]]


    if {$d == 1} {
	set Ob_edge($edge,line,5) [list [expr $d * $erx] [expr $d * $ery] \
		[expr $d * (0 - $erx * $prx - $ery * $pry)]]
	set Ob_edge($edge,line,7) [list [expr $d * $elx] [expr $d * $ely] \
		[expr $d * (0 - $elx * $plx - $ely * $ply)]]
	
	set prx [lindex $r2Pr 0]
	set pry [lindex $r2Pr 1]
	set plx [lindex $r2Pl 0]
	set ply [lindex $r2Pl 1]
  
	set Ob_edge($edge,line,6) [list [expr $d * $erx] [expr $d * $ery] \
		[expr $d * (0 - $erx * $prx - $ery * $pry)]]
	set Ob_edge($edge,line,8) [list [expr $d * $elx] [expr $d * $ely] \
		[expr $d * (0 - $elx * $plx - $ely * $ply)]]
	
    } else {
	set Ob_edge($edge,line,8) [list [expr $d * $erx] [expr $d * $ery] \
		[expr $d * (0 - $erx * $prx - $ery * $pry)]]
	set Ob_edge($edge,line,6) [list [expr $d * $elx] [expr $d * $ely] \
		[expr $d * (0 - $elx * $plx - $ely * $ply)]]

	set prx [lindex $r2Pr 0]
	set pry [lindex $r2Pr 1]
	set plx [lindex $r2Pl 0]
	set ply [lindex $r2Pl 1]

	set Ob_edge($edge,line,7) [list [expr $d * $erx] [expr $d * $ery] \
		[expr $d * (0 - $erx * $prx - $ery * $pry)]]
	set Ob_edge($edge,line,5) [list [expr $d * $elx] [expr $d * $ely] \
		[expr $d * (0 - $elx * $plx - $ely * $ply)]]
	
    }
}

proc plug_into_line {line xy} {
    set x [lindex $xy 0]
    set y [lindex $xy 1]
    set a [lindex $line 0]
    set b [lindex $line 1]
    set c [lindex $line 2]
    return [expr ($a * $x) + ($b * $y) + $c]
}

proc line_intersection {line1 line2} {
    set a1 [lindex $line1 0]
    set b1 [lindex $line1 1]
    set c1 [lindex $line1 2]
    set a2 [lindex $line2 0]
    set b2 [lindex $line2 1]
    set c2 [lindex $line2 2]
    set denom [expr 0.0 - $a2*$b1 + $a1*$b2]
    if {$denom == 0.0} {
	return 0
    }
    set x [expr (0 - $b2*$c1 + $b1*$c2)/$denom]
    set y [expr ($a2*$c1 - $a1*$c2)/$denom]
    return [list $x $y]
}



proc left_rotations edge {
    global Ob_edge
      if {$Ob_edge($edge,translations) == {}} {
	  return {}
    }
    set rotations {}
    set i23 [line_intersection $Ob_edge($edge,line,2) $Ob_edge($edge,line,3)]
    set i58 [line_intersection $Ob_edge($edge,line,5) $Ob_edge($edge,line,8)]
    set i28 [line_intersection $Ob_edge($edge,line,2) $Ob_edge($edge,line,8)]
    set i25 [line_intersection $Ob_edge($edge,line,2) $Ob_edge($edge,line,5)]
    set i35 [line_intersection $Ob_edge($edge,line,3) $Ob_edge($edge,line,5)]
    set i38 [line_intersection $Ob_edge($edge,line,3) $Ob_edge($edge,line,8)]

    foreach sect {i23 i58 i28 i25 i35 i38} {
        eval set intersection \$$sect
        if {$intersection != 0} {
	    if {[fuzzy_greater_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,2) $intersection] 0.0 ] && \
		    [fuzzy_less_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,3) $intersection] 0.0 ] && \
		    [fuzzy_less_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,5) $intersection] 0.0 ] && \
		    [fuzzy_greater_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,8) $intersection] 0.0 ]} {
		set x [lindex $intersection 1]
		set y [expr 0.0 - [lindex $intersection 0]]
		if {[not_close_to_previous $x $y 1.0 $rotations]} {
	            lappend rotations [list $x $y 1.0]
		}
	    }
	}
    }
    return $rotations
}

proc right_rotations edge {
    global Ob_edge
    if {$Ob_edge($edge,translations) == {}} {
	return {}
    }
    set rotations {}
    set i14 [line_intersection $Ob_edge($edge,line,1) $Ob_edge($edge,line,4)]
    set i67 [line_intersection $Ob_edge($edge,line,6) $Ob_edge($edge,line,7)]
    set i16 [line_intersection $Ob_edge($edge,line,1) $Ob_edge($edge,line,6)]
    set i17 [line_intersection $Ob_edge($edge,line,1) $Ob_edge($edge,line,7)]
    set i46 [line_intersection $Ob_edge($edge,line,4) $Ob_edge($edge,line,6)]
    set i47 [line_intersection $Ob_edge($edge,line,4) $Ob_edge($edge,line,7)]

    foreach sect {i14 i67 i16 i17 i46 i47} {
        eval set intersection \$$sect
        if {$intersection != 0} {
	    if {[fuzzy_greater_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,4) $intersection] 0.0 ] && \
		    [fuzzy_less_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,1) $intersection] 0.0 ] && \
		    [fuzzy_less_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,7) $intersection] 0.0 ] && \
		    [fuzzy_greater_than_or_equal \
		    [plug_into_line $Ob_edge($edge,line,6) $intersection] 0.0 ]} {
		set x [expr 0.0 - [lindex $intersection 1]]
		set y [lindex $intersection 0]
		if {[not_close_to_previous $x $y -1.0 $rotations]} {
	            lappend rotations [list $x $y -1.0]
		}
	    }
	}
    }
    return $rotations
}

proc not_close_to_previous {x y omega rotlist} {
    global FuzzyDist MaxRCDist
    set origin [list 0.0 0.0 0.0]
    set rotdist [rot_center_distance [list $x $y $omega] $origin]
    if {$rotdist > $MaxRCDist} {
	return 0
    }
    foreach rot $rotlist {
	set rotdist [rot_center_distance [list $x $y $omega] $rot]
	if {$rotdist < $FuzzyDist} {
	    return 0
	}
    }
    return 1
}

proc rot_center_distance {rot1 rot2} {
    set rotdist [expr sqrt(pow([expr [lindex $rot1 0]-[lindex $rot2 0]],2.0) + pow([expr [lindex $rot1 1]-[lindex $rot2 1]],2.0))]
    return $rotdist
}

proc do_selected_edges {} {
    global Ob_edge edge_count Object_coords Mu
    set pushed_edge_count 0
    set mess {}
    set translist {}
    if {!($Mu>=0.0)} {
	set mess [concat $mess {Friction coefficient must be a nonnegative value!} {\n}]
	eval dialog \"$mess\" 0
	return
    }
    for {set i 0} {$i < $edge_count} {incr i} {
	if {$Ob_edge($i,pushable)} {
	    incr pushed_edge_count
	    set Ob_edge($i,translations) [get_trans $i]
	    set_friction_lines_for_edge $i
	    set_edge_lines_for_edge $i
	    set Ob_edge($i,leftrotations) [left_rotations $i]
	    set Ob_edge($i,rightrotations) [right_rotations $i]
	    
	    test_friction $i
	    test_edge $i
	    set mess [concat $mess [list Edge ${i}:] {\n}]
	    set mess [concat $mess {Translations: } $Ob_edge($i,translations) {\n}]
	    set translist [concat $translist $Ob_edge($i,translations)]
	    set mess [concat $mess {Rotations: } $Ob_edge($i,leftrotations) {\n}]
	    set mess [concat $mess $Ob_edge($i,rightrotations) {\n\n}]
	}
    }
    if {$pushed_edge_count == 0} {
	set mess [concat $mess {Must select pushing edge(s)!} {\n}]
    } else {
	if {[locally_controllable $translist]} {
	    set mess [concat $mess {Object is small-time locally controllable!}]
	} else {
	    set mess [concat $mess {Object is not small-time locally controllable!}]
	}
    }
    eval dialog \"$mess\" 0
}

proc locally_controllable {translist} {
    global Mu
    set edges_marked 0
    for {set i 0} {$i < [llength $translist]} {incr i} {
	if {[lindex $translist $i] == {}} continue
	incr edges_marked
	set gtr 0
	set less 0
	for {set j 0} {$j < [llength $translist]} {incr j} {
	    if {[lindex $translist $j] == {}} continue
	    set v1 [lindex $translist $i]
	    set v2 [lindex $translist $j]
	    set a [lindex $v1 0]
	    set b [lindex $v1 1]
	    set c [lindex $v2 0]
	    set d [lindex $v2 1]
	    set crossprod [expr $a * $d - $b * $c]
	    if {$crossprod > 0} {
		set gtr 1
	    } elseif {$crossprod <0} {
		set less 1
	    }
	}
	if {($gtr == 0) || ($less == 0)} {
	    return 0
	}
    }
    if {$edges_marked > 0} {
	if {$Mu>0.0} {
	    return 1
	}
    }
    return 0
}

