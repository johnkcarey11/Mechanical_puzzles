# Object Editor for PWE v1.2
#  also by Costa "F. Mack Daddy C" Nikou
#
#  This will supposedly eliminate all the yucky math we humans have to do
#
#  oh, and it will have pretty colors, too
#
source $ColorFile
source obeditglobals.tcl
source helpers.tcl

proc transform pixel {
    global transform_value Ob_snap halfpixels
    set pixel [expr $pixel - $halfpixels]
    return [snap [expr $pixel/$transform_value] $Ob_snap]
}

proc untransform mill {
    global transform_value halfpixels
    set pixel [expr $mill * $transform_value]
    set pixel [expr $pixel + $halfpixels]
}

proc untransform_list millilist {
    foreach c $millilist {
	lappend newlist [untransform $c]
    }
    return $newlist
}

toplevel .obedit -bg black
wm title .obedit "Object Editor v1.2"
canvas .obedit.field -width [expr 2 * $halfpixels + 1] \
	-height [expr 2 * $halfpixels + 1] -bg gray
frame .obedit.options -bg gray
frame .obedit.options.buttons1 -bg gray
frame .obedit.options.buttons2 -bg gray


button .obedit.options.buttons1.anal -text "Run Analysis" -command run_analysis -relief \
	raised -bd 3 -bg #fff
button .obedit.options.buttons1.save -text "Add Object to File" -command save_object -relief \
	raised -bd 3 -bg #fff
button .obedit.options.buttons1.quit -text "Quit" -command quit_ob \
	-relief raised -bd 3 -bg #fff
button .obedit.options.buttons1.options -text Options -command ob_options \
	-relief raised -bd 3 -bg #fff

button .obedit.options.buttons2.kill -text "Clear Object" -command kill_object -relief \
	raised -bd 3 -bg #fff
button .obedit.options.buttons2.hull -text "Use Convex Hull" -command use_hull -relief \
	raised -bd 3 -bg #fff
button .obedit.options.buttons2.linewipe -text "Remove Analysis Lines" \
	-command {.obedit.field delete testline} -relief raised -bd 3 -bg #fff


foreach k {quit save anal options} {
    pack .obedit.options.buttons1.$k -ipadx 5 -ipady 3 -fill x
}

foreach k {hull kill linewipe} {
   pack .obedit.options.buttons2.$k -ipadx 5 -ipady 3 -fill x
}  

frame .obedit.options.here -bg gray
label .obedit.options.here.x -textvariable herex -bg gray
label .obedit.options.here.y -textvariable herey -bg gray
label .obedit.options.here.( -text "(" -bg gray
label .obedit.options.here., -text "," -bg gray
label .obedit.options.here.) -text ")" -bg gray

foreach i { "(" x , y ")" } {
    pack .obedit.options.here.$i -side left -fill both
}

frame .obedit.options.coeff -bg gray
message .obedit.options.coeff.label -text "Friction Coeff:" -justify center -bg gray
entry .obedit.options.coeff.mu -textvariable Mu -relief sunken -bd 3 -bg white \
	-font -adobe-times-medium-r-normal--18-180-75-75-p-94-iso8859-1 \
	-width 4

pack .obedit.options.coeff.label .obedit.options.coeff.mu -side left

frame .obedit.options.name -bg gray
label .obedit.options.name.label -text "Name of Object" -bg gray
entry .obedit.options.name.entry -textvariable Name -relief sunken -width 10 \
	-bg white -font -adobe-times-medium-r-normal--18-180-75-75-p-94-iso8859-1 \
	-bd 3

pack .obedit.options.name.label .obedit.options.name.entry

frame .obedit.options.arrow -bg gray
checkbutton .obedit.options.arrow.b -text "Include arrow" -variable Arrow -relief raised \
	-bd 3 -bg #fff
pack .obedit.options.arrow.b -fill x

frame .obedit.options.help -bg gray
label .obedit.options.help.label1 -text "Button 1:" -bg gray -fg $Color(help)
label .obedit.options.help.label2 -text "Button 2:" -bg gray -fg $Color(help)
label .obedit.options.help.label3 -text "Button 3:" -bg gray -fg $Color(help)
message .obedit.options.help.m1 -textvariable obhelp1 -bg gray -width 150 -justify center \
	-fg $Color(help)
message .obedit.options.help.m2 -textvariable obhelp2 -bg gray -width 150 -justify center  \
	-fg $Color(help)
message .obedit.options.help.m3 -textvariable obhelp3 -bg gray -width 150 -justify center  \
	-fg $Color(help)

pack .obedit.options.help.label1 .obedit.options.help.m1 -fill x
pack .obedit.options.help.label2 .obedit.options.help.m2 -fill x
pack .obedit.options.help.label3 .obedit.options.help.m3 -fill x

pack .obedit.options.buttons1 
pack .obedit.options.here -pady 3
pack .obedit.options.coeff -pady 4
pack .obedit.options.name -pady 2
pack .obedit.options.arrow -pady 4
pack .obedit.options.help -pady 2  -expand 1
pack .obedit.options.buttons2 -side bottom 
pack .obedit.field .obedit.options -side left -padx 1m -fill both

bind .obedit.options.coeff.mu <Any-Return> {
    if {[.obedit.options.coeff.mu get] == ""} {set Mu 0.25}
    .obedit.options.coeff.mu select clear
}
bind .obedit.options.name.entry <Any-Return> {
    if {[.obedit.options.name.entry get] == ""} {set Name Polygon}
    .obedit.options.name.entry select clear
}



.obedit.field create line 0 300 600 300 \
	-fill $Color(ObEdit,GridMark) -tags \
	crosshairs
.obedit.field create line 300 0 300 600 \
	-fill $Color(ObEdit,GridMark) -tags \
	crosshairs


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

############################
##  For reference...because of the stupid Xwindows coordinate system of y increasing down
##  we have to save Object_coords (list of object's coordinates) with the Y coords flipped
##  over.  Anytime we need to calculate stuff in the Cartesian type of space, we need
##  to flip the y coordinates using the flip_y procedure.


bind .obedit.field <1> {
    global Color px py Object_coords guide_line edge_count Ob_edge None_present
    global obhelp1 obhelp2 obhelp3
    if {$None_present} {
	if {$New_Started == 0} {
	    set Object_coords {}
	    set edge_count 0
	    catch {unset Ob_edge}
	    
	    set New_Started 1
	    set obhelp1 "Click to place \nanother vertex"
	    set obhelp2 "Click to place \nFINAL vertex"
	    set obhelp3 ""
	    
	    set px [transform %x]
	    set py [transform %y]
	    set firstx $px
	    set firsty $py
	    lappend Object_coords $px $py
	    eval .obedit.field create rectangle \
		    [expr [untransform [transform %x]] - 3] \
		    [expr [untransform [transform %y]] - 3] \
		    [expr [untransform [transform %x]] + 3] \
		    [expr [untransform [transform %y]] + 3] \
		    -outline black -fill yellow -tags line
	    set first_line [eval .obedit.field create line \
		    [untransform_list [list $px $py $px $py]] -tags line]
	    set last_line [eval .obedit.field create line \
		    [untransform_list [list $px $py $px $py]] -tags line]
	} else {
	    .obedit.field create line \
		    [untransform $px] [untransform $py] \
		    [untransform [transform %x]] [untransform [transform %y]] \
		    -tags line -width 2
	    .obedit.field coords $first_line \
		    [untransform [transform %x]] [untransform [transform %y]] \
		    [untransform $firstx] [untransform $firsty]
	    .obedit.field coords $last_line \
		    [untransform [transform %x]] [untransform [transform %y]] \
		    [untransform $px] [untransform $py]
	    eval .obedit.field create rectangle \
		    [expr [untransform [transform %x]] - 3] \
		    [expr [untransform [transform %y]] - 3] \
		    [expr [untransform [transform %x]] + 3] \
		    [expr [untransform [transform %y]] + 3] \
		    -outline black -fill yellow -tags line
	    lappend Object_coords [transform %x] [transform %y]
	    set Ob_edge($edge_count,coords) [list $px $py [transform %x] [transform %y]]
	    set Ob_edge($edge_count,pushable) 0
	    incr edge_count
	    set px [transform %x]
	    set py [transform %y]
	}
    }
}


bind .obedit.field <2> { 
    global New_Started px py Object_coords firstx firsty edge_count None_present
    if {$New_Started} {
	set New_Started 0
	if {$edge_count < 1} {
	    set $edge_count 0
	    catch {unset Ob_edge}
	    set Object_coords {}
	    dialog "Object must have at least 3 sides" 1
	    .obedit.field delete line
	    set None_present 1
	} else {
	    set None_present 0
	    lappend Object_coords [transform %x] [transform %y]
	    set Ob_edge($edge_count,coords) [list $px $py [transform %x] [transform %y]]
	    set Ob_edge($edge_count,pushable) 0
	    incr edge_count
	    set Ob_edge($edge_count,coords) [list [transform %x] [transform %y] $firstx $firsty]
	    set Ob_edge($edge_count,pushable) 0
	    incr edge_count 
	    
	    if {![legal_coords $Object_coords]} {
		set $edge_count 0
		catch {unset Ob_edge}
		set Object_coords {}
		dialog "Two vertices may not have identical coordinates" 1
		.obedit.field delete line
		set None_present 1
	    } else {
		redo_object
		set obhelp1 "no function"
		set obhelp2 "Click and hold \nto move object"
		set obhelp3 "Click edge to \n(un)mark as pushable"
		
		.obedit.field delete line
		.obedit.field raise crosshairs
	    } 
	}
    } else {
	set px [transform %x]
	set py [transform %y]
    }
}

bind .obedit.field <Any-Motion> {
    global New_Started px py guide_line
    set herex [transform %x]
    set herey [expr 0 - [transform %y]]
    
    if {$New_Started} {
	eval .obedit.field coords $first_line \
		[untransform_list [list $firstx $firsty [transform %x] [transform %y]]]
  	eval .obedit.field coords $last_line \
		[untransform_list [list $px $py [transform %x] [transform %y]]]
    }
}

.obedit.field bind object <B2-Motion> {
    global Object_coords herex herey px py edge_count Ob_edge
    set herex [transform %x]
    set herey [transform %y]
    
    set dx [expr $herex - $px]
    set dy [expr $herey - $py]
    set newxs [list_incr [extract x $Object_coords] $dx]
    set newys [list_incr [extract y $Object_coords] $dy]
    update_object [zip $newxs $newys]
    for {set i 0} {$i < $edge_count} {incr i} {
	    set newxs [list_incr [extract x $Ob_edge($i,coords)] $dx]
	    set newys [list_incr [extract y $Ob_edge($i,coords)] $dy]
	    update_edge $i [zip $newxs $newys]
    }
    set px [transform %x] 
    set py [transform %y]
}

proc update_object coords {
    global Object_coords
    eval .obedit.field coords object [untransform_list $coords]
    set Object_coords $coords
}

proc update_edge {edge coords} {
    global Ob_edge
    set Ob_edge($edge,coords) $coords
    if {$Ob_edge($edge,pushable)} {
	eval .obedit.field coords $Ob_edge($edge,id) [untransform_list $coords]
    }
}



puts "sourcing edgeclick.tcl"
source edgeclick.tcl
puts "sourcing graham.tcl"
source graham.tcl
puts "sourcing ob_buttons.tcl"
source ob_buttons.tcl
puts "sourcing linedraw.tcl"
source linedraw.tcl
puts "sourcing analysis.tcl"
source analysis.tcl