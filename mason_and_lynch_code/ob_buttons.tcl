proc quit_ob {} {
    destroy .obedit
    catch {destroy .ob_options}
}

proc kill_object {} {
    global None_present Object_coords edge_count Ob_edge obhelp1 obhelp2 obhelp3
    set None_present 1
    set Object_coords {}
    set edge_count 0
    catch {unset Ob_edge}
	
    set obhelp1 "Click to place vertex"
    set obhelp2 "no function"
    set obhelp3 "no function"
    .obedit.field delete object
    .obedit.field delete edge
}

proc redraw_obedit_canvas {} {
    global edge_count Ob_edge Object_coords ObMAX transform_value Ob_snap Color Every
    
    #### REDO CANVAS AND LINES
    .obedit.field delete hashmark
    .obedit.field delete testline
    for {set x 0.0} {$x <= $ObMAX} {set x [expr $x + $Every]} {
	for {set y 0.0} {$y <= $ObMAX} {set y [expr $y + $Every]} {
	    .obedit.field create line \
		    [expr [untransform $x] - 2] [untransform $y] \
		    [expr [untransform $x] + 3] [untransform $y] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [untransform $x] [expr [untransform $y] - 2] \
		    [untransform $x] [expr [untransform $y] + 3] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [expr [untransform -$x] - 2] [untransform $y] \
		    [expr [untransform -$x] + 3] [untransform $y] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [untransform -$x] [expr [untransform $y] - 2] \
		    [untransform -$x] [expr [untransform $y] + 3] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [expr [untransform $x] - 2] [untransform -$y] \
		    [expr [untransform $x] + 3] [untransform -$y] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [untransform $x] [expr [untransform -$y] - 2] \
		    [untransform $x] [expr [untransform -$y] + 3] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [expr [untransform -$x] - 2] [untransform -$y] \
		    [expr [untransform -$x] + 3] [untransform -$y] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	    .obedit.field create line \
		    [untransform -$x] [expr [untransform -$y] - 2] \
		    [untransform -$x] [expr [untransform -$y] + 3] \
		    -fill $Color(ObEdit,GridMark) -tags hashmark
	}
    }
    
    if {[.obedit.field find withtag object] != ""} { 
	update_object $Object_coords
	for {set i 0} {$i < $edge_count} {incr i} {
	    update_edge $i $Ob_edge($i,coords)
	}
    }
}




proc ob_options {} {
    global transform_value Ob_snap tempgrid tempsnap tempsize 
    global ObMAX Every

    set tempgrid $Every
    set tempsnap $Ob_snap
    set tempsize $ObMAX

    toplevel .ob_options -bg gray
    frame .ob_options.entries -bg gray
    
    frame .ob_options.entries.grid -bg gray
    eval entry .ob_options.entries.grid.entry -width 7 -bg white -textvariable tempgrid \
	    -relief sunken -bd 2
    label .ob_options.entries.grid.label -text "Grid Spacing: " -bg gray

    frame .ob_options.entries.snap -bg gray
    eval entry .ob_options.entries.snap.entry -width 7 -bg white -textvariable tempsnap \
	    -relief sunken -bd 2
    label .ob_options.entries.snap.label -text "Snap Spacing: " -bg gray
    
    frame .ob_options.entries.size -bg gray
    eval entry .ob_options.entries.size.entry -width 7 -bg white -textvariable tempsize \
	    -relief sunken -bd 2
    label .ob_options.entries.size.label -text "Area Size: " -bg gray 
    
    pack .ob_options.entries.grid.label -side left
    pack .ob_options.entries.grid.entry -side right
    pack .ob_options.entries.snap.label -side left
    pack .ob_options.entries.snap.entry -side right
    pack .ob_options.entries.size.label -side left
    pack .ob_options.entries.size.entry -side right
    

    pack .ob_options.entries.grid .ob_options.entries.snap \
	    .ob_options.entries.size  -fill x

    frame .ob_options.butts -bg gray
    
    button .ob_options.butts.save -command save_ob_options -text "Save Options" -relief \
	    raised -bd 3 -bg #eee
    button .ob_options.butts.cancel -text "Cancel" -relief raised -bd 3 -bg #eee \
	    -command {destroy .ob_options; catch {unset tempgrid tempsnap tempsize}}
    

    pack .ob_options.butts.save .ob_options.butts.cancel -ipadx 2m -ipady 1m -padx 1m -pady 2m \
	    -side left -fill both

    pack .ob_options.entries .ob_options.butts -fill x

    proc save_ob_options {} {
	global transform_value Ob_snap tempgrid tempsnap tempsize tempmu Color
	global ObMAX Every

	set ObMAX $tempsize
	set Every $tempgrid
	set Ob_snap $tempsnap
	set transform_value [expr 300.0 / $ObMAX]

	set halfpixels 300
	
	redraw_obedit_canvas
	
	.ob_options.butts.cancel invoke
    }	
}

proc run_analysis {} {
    global Object_coords Ob_edge edge_count Name Possible_Objects
    .obedit.field delete testline
    do_selected_edges
}

proc save_object {} {
    global Object_coords edge_count Ob_edge Name Possible_Objects Arrow

    if {[lsearch -exact $Possible_Objects $Name] != -1} {
	dialog "That object already exists in database" 1
	return
    }

    proc get_arrow_length {} {
	global Object_coords
	set coords [flip_y $Object_coords]
	set coords [extract y $coords]
	set maxe [max $coords]
	return [expr $maxe/1.7]
    }

    proc get_numcontrols edge {
	global Ob_edge
	return [expr [llength $Ob_edge($edge,translations)] + \
		[llength $Ob_edge($edge,leftrotations)] + \
		[llength $Ob_edge($edge,rightrotations)]]
    }

    set f [open "objects.tcl" a]

    puts $f "\n\nglobal $Name"

    puts $f "lappend Possible_Objects $Name"
    puts -nonewline $f "set $Name"
    puts $f "(init_coords) \[list [flip_y $Object_coords]\]"

    puts -nonewline $f "set $Name"
    if {$Arrow} {
	puts $f "(0degrees) \[list 0 0 0 [expr 0 - [get_arrow_length]] \]"
    } else {
	puts $f "(0degrees) \[list 0 0 0 0\]"
    }
    puts -nonewline $f "set $Name"
    puts $f "(robot_polys) 1"

    puts -nonewline $f "set $Name"
    puts $f "(numedges) $edge_count"
    
    for {set i 0} {$i < $edge_count} {incr i} {
	set e [expr $i + 1]
	
	if {$Ob_edge($i,pushable)} {
	    set numcontrols [get_numcontrols $i]
	} else {
	    set numcontrols 0
	}
	
	puts -nonewline $f "set $Name"
	puts $f "(edge,${e},numcontrols) $numcontrols"
	
	if {$numcontrols == 0} continue
	set controllist [concat $Ob_edge($i,translations) $Ob_edge($i,leftrotations) \
		$Ob_edge($i,rightrotations)]
	for {set j 1} {$j <= $numcontrols} {incr j} {
	    puts -nonewline $f "set $Name"
	    puts $f "(edge,${e},${j}) \[list [lindex $controllist [expr $j-1]]\]"
	}
    }
    close $f
    
    .new_object.listbox delete 0 end
    source objects.tcl
    foreach ob $Possible_Objects {
	.new_object.listbox insert end $ob
    }
    
    foreach ob $Possible_Objects {
	eval set init \$${ob}(init_coords)
	set ${ob}(edgecoords) {}
	for {set e 1} {[expr $e < ([llength $init]/2)]} {incr e} {
	    if {[expr \$${ob}(edge,$e,numcontrols) != 0]} {
		set i [expr ($e - 1)*2]
		set x1 [lindex $init $i]
		set y1 [lindex $init [expr $i+1]]
		set x2 [lindex $init [expr $i+2]]
		set y2 [lindex $init [expr $i+3]]
		lappend ${ob}(edgecoords) [list $x1 $y1 $x2 $y2]
	    } else {lappend ${ob}(edgecoords) no_coords }
	}
	if {[expr \$${ob}(edge,$e,numcontrols) != 0]} {
	    set i [expr ($e - 1)*2]
	    set x1 [lindex $init $i]
	    set y1 [lindex $init [expr $i+1]]
	    set x2 [lindex $init 0]
	    set y2 [lindex $init 1]
	    lappend ${ob}(edgecoords) [list $x1 $y1 $x2 $y2]
	} else {lappend ${ob}(edgecoords) no_coords }
    }
    update idletasks
}    