proc quit {} {
    destroy .
    catch {destroy .options}
    catch {destroy .rotate_start}
    catch {destroy .rotate_goal}
    catch {destroy .file_to_save}
    catch {destroy .file_to_load}
    catch {destroy .ps_file}
    catch {destroy .new_object}
    catch {destroy .rotate}
    catch {destroy .animate}
}

proc reset {} {
    global All_Obs OPTIONS XMAX YMAX Ob_List Object Start Goal Mode write_adept
    global help1 help2 help3 help4 help5 Color
    global $Object
    .field delete obstacle
    .field delete start
    .field delete goal
    .field delete path
    catch {destroy .animate}
    catch {destroy .options2.animate}
    set Mode rect ;#ability to create rects easily...
    set help1 "Click and drag to create rectangle"
    set help2 "Click and drag to move object"
    set help3 "Click to kill obstacle"
    set help4 ""
    set help5 ""
    set write_adept 1
    write_adept_switch
    
    set New_Started 0
    set Ob_List(temp) {}
    set All_Obs {}
    set guide_line -1
    
    source start.tcl
    source goal.tcl
    
}

proc save {} {
    global All_Obs OPTIONS XMAX YMAX Ob_List Object Start Goal planner_call
    eval global $Object filename get_out path_too PathOut
    set oldfile $filename
   
    set get_out 1
    set path_too 0
    
    proc print_edge_info fid {
	global Object
	eval global $Object
	eval set numedges \$${Object}(numedges)
	puts $fid $numedges
	for {set i 1} {$i <= $numedges} {incr i} {
	    eval set numcontrols \$${Object}(edge,$i,numcontrols)
	    puts $fid $numcontrols
	    if {$numcontrols == 0} continue
	    for {set j 1} {$j <= $numcontrols} {incr j} {
		eval puts $fid \$${Object}(edge,$i,$j)
	    }
	}
    }

    proc prompt_filename {} {
	global filename get_out plan_too
	
	toplevel .file_to_save
	wm title .file_to_save "Save File..."
	wm geometry .file_to_save +500+400
	set get_out 1
	frame .file_to_save.stuff
	frame .file_to_save.butts
	label .file_to_save.stuff.label -text "File to save: "
	button .file_to_save.butts.ok -relief raised -text "Save" \
		-command {global get_out; destroy .file_to_save; set get_out 0}
	button .file_to_save.butts.cancel -relief raised -text "Cancel" \
		-command {global get_out; destroy .file_to_save; set get_out 1}
	entry .file_to_save.stuff.entry -width 21 -bg white -bd 2 -relief sunken \
		-textvariable filename
	checkbutton .file_to_save.pathtoo -text "Save path also"  -variable path_too \
		-relief raised -bd 3
	pack .file_to_save.stuff.label .file_to_save.stuff.entry -side left
	pack .file_to_save.butts.ok .file_to_save.butts.cancel -padx 5m -side left
	pack .file_to_save.stuff .file_to_save.pathtoo .file_to_save.butts -pady 3m -padx 2m
	bind .file_to_save.stuff.entry <Return> \
		{global get_out; destroy .file_to_save; set get_out 0}
	tkwait window .file_to_save
	return $get_out
    }
    
    if {!$planner_call} {
	prompt_filename
	if {$get_out} return
	set f [open $filename w]
    } else {
	set f [open "planner.tmp" w]
    }

 
     
    # world size    
    puts $f [floatify [list 0 $XMAX 0 $YMAX]]
    
    # number of robot polygons
    eval puts $f \$${Object}(robot_polys)
    # number of vertices in each poly, then vertices
    eval set templist \$${Object}(init_coords)
    eval puts $f [expr [llength $templist] /2]
    puts $f [floatify $templist]
    
    # number of obstacles
    puts $f [llength $All_Obs]

    foreach i $All_Obs {
	set clist [floatify $Ob_List($i)]
	set num_vertices [expr [llength $clist] /2]
	puts $f $num_vertices
	if {[lies_to $clist] != "left"} {
	    puts $f [fakeify $clist]
	} else {
	    puts $f [fakeify [reverse_coord_list $clist]]
	}
    } 
    # start, goal and error coords
    puts $f [floatify [list $Start(x) $Start(fake_y) [d_r $Start(theta)]]]
    puts $f [floatify [list $Goal(x) $Goal(fake_y) [d_r $Goal(theta)]]]

    puts $f [floatify [list $OPTIONS(errx) $OPTIONS(erry) [d_r $OPTIONS(errtheta)]]]

    #arclength
    puts $f [floatify $OPTIONS(arclength)]

    print_edge_info $f

    # size of call which only one path can enter (xcell, ycell, thetacell)
    puts $f [floatify [list $OPTIONS(xcell) $OPTIONS(ycell) [d_r $OPTIONS(thetacell)]]]

    # Cost values
    puts $f "$OPTIONS(push) $OPTIONS(actionswitch) $OPTIONS(edgeswitch) $OPTIONS(max)"
    puts $f $Object    

    # dump to file
    flush $f                           
    close $f
    
    if {$path_too} {
	set body_ext [split $filename .]
	set body [lindex $body_ext 0]
	set ext [lindex $body_ext 1]
	exec cp $PathOut ${body}.path
    }

    if {!$planner_call} {
	if {$path_too} {
	    set msg "Files saved as $filename and ${body}.path"
	} else {
	    set msg "File saved as $filename"
	}
	dialog $msg 1
    }
}

proc choose_options {} {
    global OPTIONS temp All_Obs XMAX YMAX oldXMAX oldYMAX
    
    toplevel .options
    wm title .options "Options"
    set_array temp OPTIONS
    
    set oldXMAX $XMAX
    set oldYMAX $YMAX
      
    ## BUTTONS TO SAVE OR CANCEL

    frame .options.save_or_cancel -bd 2m 
    button .options.save_or_cancel.save -relief raised -bd 1.5m \
	    -text "Save Options" \
	    -command save_options 
    
    button .options.save_or_cancel.cancel -relief raised -bd 1.5m \
	    -text "Never mind..." -command cancel_options
        
    ## GRID ENTRY
    
    frame .options.grid
    label .options.grid.label -text "Grid Spacing (in millimeters): " 
    entry .options.grid.entry -textvariable temp(grid) -width 7 -relief sunken \
	    -bd 2 -bg white
    
    ## COSTS ENTRY
    
    frame .options.costs
    foreach type {push actionswitch edgeswitch max} {
	frame .options.costs.${type}
	entry .options.costs.${type}.entry -width 7 -relief sunken -bd 2 \
		-textvariable temp($type) -bg white
    }
    label .options.costs.push.label -text "Cost per push: " 
    label .options.costs.actionswitch.label -text "Cost per Action Switch: "
    label .options.costs.edgeswitch.label -text "Cost per Edge Switch: "
    label .options.costs.max.label -text "Maximum cost Allowed: "

    frame .options.divider -relief groove -bd 2
    
      ## ERROR ENTRY

    frame .options.divider.err
    frame .options.divider.err.entries
    entry .options.divider.err.entries.entryx -width 7 -relief sunken -bd 2 \
	    -textvariable temp(errx)  -bg white
    entry .options.divider.err.entries.entryy -width 7 -relief sunken -bd 2 \
	    -textvariable temp(erry) -bg white
    entry .options.divider.err.entries.entrytheta -width 7 -relief sunken -bd 2 \
	    -textvariable temp(errtheta) -bg white
    
    label .options.divider.err.label -text "Permissible Error (x,y,theta)"
    

    button .options.divider.refresh -relief raised -bd 5 -command use_defaults \
	    -text "Use Default Cell sizes" -bg #eee -activebackground #fff
    message .options.divider.warning1 -justify center \
	    -text "Only for ADVANCED Users..." -width 3.5i
    message .options.divider.warning2 -justify left -text \
	    "Use of default cell size is recommended after changing \
	    X or Y dimensions" -width 3.5i

    frame .options.divider.cells
    frame .options.divider.cells.entries
    entry .options.divider.cells.entries.entryx -width 7 -relief sunken -bd 2 \
	    -textvariable temp(xcell)  -bg white
    entry .options.divider.cells.entries.entryy -width 7 -relief sunken -bd 2 \
	    -textvariable temp(ycell) -bg white
    entry .options.divider.cells.entries.entrytheta -width 7 -relief sunken -bd 2 \
	    -textvariable temp(thetacell) -bg white
    
    label .options.divider.cells.label -text "Cell size (x,y,theta)"
    
    frame .options.divider.arc
    label .options.divider.arc.label -text "Step Length: "
    entry .options.divider.arc.entry -textvariable temp(arclength) \
	    -width 7 -relief sunken -bd 2 -bg white

    frame .options.xmax
    frame .options.ymax
    
    label .options.xmax.label -text "X dimension (in mm): "
    label .options.ymax.label -text "Y dimension (in mm): "
    entry .options.xmax.entry -textvariable XMAX -width 7 -relief sunken -bd 2 -bg white
    entry .options.ymax.entry -textvariable YMAX -width 7 -relief sunken -bd 2 -bg white
    

    
    
    ## PACKING CALLS

    foreach type {push actionswitch edgeswitch max} {
	pack .options.costs.${type}.label -side left
	pack .options.costs.${type}.entry -side right
    }
     
    pack .options.save_or_cancel.save .options.save_or_cancel.cancel \
	    -side left -padx 7m -ipadx 3m -fill x -pady 4m -ipady 1m

    
    pack .options.divider.err.entries.entryx .options.divider.err.entries.entryy \
	    .options.divider.err.entries.entrytheta  -side left
    pack .options.divider.err.label  -side left
    pack .options.divider.err.entries -side right
    
    pack .options.costs.push .options.costs.actionswitch \
	       .options.costs.edgeswitch .options.costs.max -fill x
    pack .options.grid.label -side left
    pack .options.grid.entry -side right

    pack .options.xmax.label -side left
    pack .options.ymax.label -side left
    pack .options.xmax.entry -side right
    pack .options.ymax.entry -side right
  
    pack .options.divider.cells.entries.entryx .options.divider.cells.entries.entryy \
	    .options.divider.cells.entries.entrytheta  -side left
    pack .options.divider.cells.label -side left
    pack .options.divider.cells.entries -side right

    pack .options.divider.arc.label -side left

    pack .options.divider.arc.entry -side right

    pack .options.divider.warning1 .options.divider.warning2 .options.divider.refresh \
	    .options.divider.err .options.divider.arc .options.divider.cells -fill x

    pack .options.costs .options.grid .options.xmax .options.ymax \
	  .options.divider .options.save_or_cancel -side top -fill x

    proc use_defaults {} {
	global XMAX YMAX temp
	if {$XMAX > $YMAX} {set max $XMAX} else {set max $YMAX}
	
	set temp(xcell) [expr $max / 60.0]
	set temp(ycell) $temp(xcell)
	set temp(arclength) [expr 2 * $temp(xcell)]
	set temp(errx) $temp(xcell)
	set temp(erry) $temp(ycell)
	set temp(errtheta) 2.0
	set temp(thetacell) 2.0
    }

 
    proc save_options {} {
	global temp OPTIONS All_Obs oldXMAX oldYMAX XMAX YMAX Start
	set redraw 0

	#save stuff here!!!
	if {$oldXMAX != $XMAX || $oldYMAX != $YMAX} {set redraw 1}
	set_array OPTIONS temp
	if {$redraw} {
	    .options1.reset invoke
	    convert; redraw_canvas}
	
	destroy .options
	focus 
    }
    
    proc cancel_options {} {
	destroy .options
	focus 
    }
    grab .options
    tkwait window .options
    unset oldXMAX oldYMAX temp
}

proc load {} {
    global All_Obs OPTIONS XMAX YMAX Ob_List Object Start Goal filename get_out path_too PathOut
        
    set get_out 1
    set path_too 0
    
    catch {destroy .options2.animate}
    proc prompt_filename {} {
	global filename get_out path_too

		
	toplevel .file_to_load
	wm title .file_to_load "Load File..."
	wm geometry .file_to_load +500+400
	
	frame .file_to_load.stuff
	frame .file_to_load.butts
	label .file_to_load.stuff.label -text "File to load: "
	button .file_to_load.butts.ok -relief raised -text "Load" \
		-command {global get_out; destroy .file_to_load; set get_out 0;focus .}
	button .file_to_load.butts.cancel -relief raised -text "Cancel" \
		-command {global get_out; destroy .file_to_load; set get_out 1; focus .}
	entry .file_to_load.stuff.entry -width 21 -bg white -bd 2 -relief sunken \
		-textvariable filename
	checkbutton .file_to_load.pathtoo -text "Load path also" -variable path_too \
		-relief raised -bd 3
	pack .file_to_load.stuff.label .file_to_load.stuff.entry -side left
	pack .file_to_load.butts.ok .file_to_load.butts.cancel -padx 5m -side left
	pack .file_to_load.stuff .file_to_load.pathtoo .file_to_load.butts -pady 3m -padx 2m
	bind .file_to_load.stuff.entry <Return> \
		{global get_out; destroy .file_to_load; set get_out 0}
	tkwait window .file_to_load
	return $get_out
    }
    
    prompt_filename
    
    if {$get_out} return  ;#Cancel

    set f [open $filename]
    
    gets $f data

    set XMAX [lindex $data 1]
    set YMAX [lindex $data 3]
    ## ignore robotpolys (for now)
    gets $f data  

    ## now ignore all polys
    for {set i 1} {$i <= $data} {incr i} {
	gets $f data2;#grab numverts ; 
	gets $f data2;#grab verts ; 
    }
    ## OBSTACLE STORAGE ##
    .field delete obstacle

    gets $f numobs
    set All_Obs {}
    for {set i 1} {$i <= $numobs} {incr i} {
	if {$numobs == 0} continue
	gets $f d2 ;#grab num verts
	gets $f clist
	set obnum [eval .field create polygon [m_p_list [fakeify $clist]] \
		-fill blue -tags obstacle]
	lappend All_Obs $obnum
	set Ob_List($obnum) [fakeify $clist]
    }
    
    gets $f data
    set Start(x) [lindex $data 0]
    set Start(y) [expr $YMAX - [lindex $data 1]]
    set Start(theta) [r_d [lindex $data 2]]
    gets $f data
    set Goal(x) [lindex $data 0]
    set Goal(y) [expr $YMAX - [lindex $data 1]]
    set Goal(theta) [r_d [lindex $data 2]]
    gets $f data
    set OPTIONS(errx) [lindex $data 0]
    set OPTIONS(erry) [lindex $data 1]
    set OPTIONS(errtheta) [r_d [lindex $data 2]]
   
    gets $f OPTIONS(arclength)
    
    #next is the Edge push info, but that's a specific of the object
    #so we'll just throw it away
    gets $f numedges
    for {set edge 1} {$edge <= $numedges} {incr edge} {
	gets $f numcontrols
	if {$numcontrols == 0} continue
	for {set v 1} {$v <= $numcontrols} {incr v} {
	    gets $f d
	}
    }
    gets $f data
    set OPTIONS(xcell) [lindex $data 0]
    set OPTIONS(ycell) [lindex $data 1]
    set OPTIONS(thetacell) [r_d [lindex $data 2]]

    gets $f data
    set OPTIONS(push) [lindex $data 0]
    set OPTIONS(actionswitch) [lindex $data 1]
    set OPTIONS(edgeswitch) [lindex $data 2]
    set OPTIONS(max) [lindex $data 3]
    gets $f Object
    global $Object
    
    #place Start and goal
    source objects.tcl
    
    .field delete start
    .field delete goal
    
    eval set Start(init_coords) \$${Object}(init_coords)
    set Start(init_coords) [flip_y $Start(init_coords)]
    eval set Start(0degrees) \$${Object}(0degrees)
    
    set Start(line_id) [eval .field create line [m_p_list $Start(0degrees)] \
	    -arrow last -fill white -tags start]
    .field addtag arrow withtag $Start(line_id)
    
    set Start(poly_id) [eval .field create polygon [m_p_list $Start(init_coords)]  \
	    -fill red -tags start]
    .field raise arrow
    
     
    eval set Goal(init_coords) \$${Object}(init_coords)
    set Goal(init_coords) [flip_y $Goal(init_coords)]
    eval set Goal(0degrees) \$${Object}(0degrees)
    
    set Goal(line_id) [eval .field create line [m_p_list $Goal(0degrees)] \
	    -arrow last -fill #222 -tags goal]
    .field addtag arrow withtag $Goal(line_id)
    
    set Goal(poly_id) [eval .field create polygon [m_p_list $Goal(init_coords)]  \
	    -fill #1f1 -tags goal]
    .field raise arrow
    
    convert
    redraw_canvas

    if {$path_too} {
	set body_ext [split $filename .]
	set body [lindex $body_ext 0]
	set ext [lindex $body_ext 1]
	draw_path ${body}.path
	exec cp ${body}.path $PathOut
	button .options2.animate -relief raised -bd 3 -command animate -text Animate!
	pack .options2.animate -side bottom
    }

    focus .
}
    
proc ps_file {} {
    global get_out printname XMAX YMAX printer printname printit
    
    proc prompt_filename {} {
	global printname get_out printer printit 
	
	toplevel .ps_file
	wm title .ps_file "Print Canvas..."
	wm geometry .ps_file +500+400
	set get_out 1
	frame .ps_file.stuff
	frame .ps_file.stuff.f 
	frame .ps_file.stuff.p 
	frame .ps_file.butts
	
	label .ps_file.stuff.p.plabel -text "Printer:"
	label .ps_file.stuff.f.flabel -text "PS filename:"
	button .ps_file.butts.ok -relief raised -text "Save PS file" \
		-command {global get_out; destroy .ps_file; set get_out 0; set printit 0}
	button .ps_file.butts.cancel -relief raised -text "Cancel" \
		-command {global get_out; destroy .ps_file; set get_out 1; focus }
	button .ps_file.butts.print -relief raised -text "Save and Print" \
		-command {global get_out; destroy .ps_file; set get_out 0;set printit 1}
	entry .ps_file.stuff.f.file -width 21 -bg white -bd 2 -relief sunken \
		-textvariable printname
	entry .ps_file.stuff.p.printer -width 21 -bg white -bd 2 -relief sunken \
		-textvariable printer
	pack .ps_file.stuff.f.flabel .ps_file.stuff.f.file -side left
	pack .ps_file.stuff.p.plabel .ps_file.stuff.p.printer -side left
	pack .ps_file.butts.ok .ps_file.butts.print .ps_file.butts.cancel -padx 3m -side left
	pack .ps_file.stuff.f .ps_file.stuff.p
	pack .ps_file.stuff .ps_file.butts -pady 3m -padx 2m
	
	tkwait window .ps_file
    }
    prompt_filename
    
    
    if {$get_out} return
    
    .field create rectangle 0 0 [m_p $XMAX] [m_p $YMAX] -tags print_border
    .field create oval [m_p 1] [m_p [expr $YMAX - 1]] \
	    [m_p 3] [m_p [expr $YMAX - 3]] -tags print_border -width 1m
    .field itemconfigure obstacle -fill black
    .field postscript -file $printname -pageheight ${YMAX}m -pagewidth ${XMAX}m \
	    -colormode gray
    if {$printit} {
	catch {exec lpr -P$printer $printname}; \
		dialog "Printing $printname to \nprinter $printer." 1
    } else {
	dialog "Writing PS file $printname" 1
    }
    .field itemconfigure obstacle -fill blue
    .field delete print_border
    focus .
}	    

proc run_planner {} {
    global planner_call write_adept PathOut
    set planner_call 1  ;# planner_call is a flag so we just save to push.problem
    catch {destroy .options2.animate}
    save   ;# write to push.problem
    if {$write_adept} {
	catch {exec pplanner -adept planner.tmp} information
    } else {
	catch {exec pplanner planner.tmp} information
    }
    set nopath [expr [string match *Sorry* $information] || \
	    [string match *Error* $information]]
    if {!$nopath} {
	draw_path $PathOut
	button .options2.animate -relief raised -bd 3 -command animate -text Animate!
	pack .options2.animate -side bottom
    }
    dialog $information 0
    set planner_call 0  ;# planner_done
}
    
proc new_object {} {
    global Possible_Objects Object Start Goal
    toplevel .new_object -bg gray 
    listbox .new_object.listbox -bg #eee -relief sunken -bd 2
    tk_listboxSingleSelect .new_object.listbox
    foreach ob $Possible_Objects {
	.new_object.listbox insert end $ob
    }
    frame .new_object.b -bg gray
    button .new_object.b.ok -text OK \
	    -command {set_new_object [.new_object.listbox get \
	    [.new_object.listbox curselection]]} -bg #eee
    button .new_object.b.create -text "Create New Object" \
	    -bg #eee -command {source obedit.tcl; tkwait window .obedit}
    
    button .new_object.b.cancel -text Cancel -command {destroy .new_object} -bg #eee
    pack .new_object.b.create -side top
    pack .new_object.b.ok .new_object.b.cancel -side left -padx 4m -pady 2m
    pack .new_object.listbox .new_object.b
    
    proc set_new_object obname {
	global Object Start Goal
	global $obname
	set Object $obname
	.field delete start
	.field delete goal
	.field delete arrow
	
	eval set Start(init_coords) \$${Object}(init_coords)
	set Start(init_coords) [flip_y $Start(init_coords)]
	eval set Start(0degrees) \$${Object}(0degrees)
	set Start(line_id) [eval .field create line [m_p_list $Start(0degrees)] \
		-arrow last -fill white -tags start]
	.field addtag arrow withtag $Start(line_id)
	set Start(poly_id) [eval .field create polygon [m_p_list $Start(init_coords)]  \
		-fill red -tags start]
	
	eval set Goal(init_coords) \$${Object}(init_coords)
	set Goal(init_coords) [flip_y $Goal(init_coords)]
	eval set Goal(0degrees) \$${Object}(0degrees)
		
	set Goal(line_id) [eval .field create line [m_p_list $Goal(0degrees)] \
		-arrow last -fill #222 -tags goal]
	.field addtag arrow withtag $Goal(line_id)
	set Goal(poly_id) [eval .field create polygon [m_p_list $Goal(init_coords)]  \
		-fill #1f1 -tags goal]
	.field raise arrow
	
	update_start
	update_goal
	destroy .new_object
    }
    focus .
}

proc write_adept_switch {} {
    global write_adept
    set write_adept [expr {!$write_adept}]
    if {$write_adept} {
	.options2.planner.adept configure -text "Write Adept File"
    } else {
	.options2.planner.adept configure -text "Don't Write Adept File"
    }
    focus .
}

proc flash_edges {} {
    global Start Object
    global $Object
        
    eval set coordlistlist \$${Object}(edgecoords)
    foreach coordlist $coordlistlist {
	if {$coordlist == "no_coords"} continue
	set coordlist [flip_y $coordlist]
	set coordlist [rotate_by_degrees $coordlist [expr -$Start(theta)]]
	set x1 [expr $Start(x) + [lindex $coordlist 0]]
	set y1 [expr $Start(y) + [lindex $coordlist 1]]
	set x2 [expr $Start(x) + [lindex $coordlist 2]]
	set y2 [expr $Start(y) + [lindex $coordlist 3]]
	set coords [list [m_p $x1] [m_p $y1] [m_p $x2] [m_p $y2]]
	eval .field create line $coords -tags flash -width 3 -fill white
    }
    for {set i 0} {$i < 10} {incr i} {
	after 60
	.field itemconfigure flash -fill black
	update idletasks
	after 60
	.field itemconfigure flash -fill white
	update idletasks
    }
    .field delete flash
}
    
    
    