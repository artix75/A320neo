##
# storage container for all ND instances 
var nd_display = {};

#canvas.NDStyles.Airbus = {
var airbusSt = {
	font_mapper: func(family, weight) {
    	if( family == "Liberation Sans" and weight == "normal" )
    		return "LiberationFonts/LiberationSans-Regular.ttf";
	},

    # where all the symbols are stored
	# TODO: SVG elements should be renamed to use boeing/airbus prefix
	# aircraft developers should all be editing the same ND.svg image
	# the code can deal with the differences now
	svg_filename: "Nasal/canvas/map/boeingND.svg",
    ##
	## this loads and configures existing layers (currently, *.layer files in Nasal/canvas/map)
	##

	layers: [
    	{ 
            name:'fixes', 
            disabled:1, 
            update_on:['toggle_range','toggle_waypoints'],
     		predicate: func(nd, layer) {
     			# print("Running fixes predicate");
     			var visible=nd.get_switch('toggle_waypoints') and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']) and (nd.rangeNm() <= 40);
     			if (visible) {
     				# print("fixes update requested!");
     				trigger_update( layer );
    			}
    			layer._view.setVisible(visible);
    		}, # end of layer update predicate
    	}, # end of fixes layer
    	{ 
        	name:'FIX', 
        	isMapStructure:1, 
        	update_on:['toggle_range','toggle_waypoints'],
    		# FIXME: this is a really ugly place for controller code
			predicate: func(nd, layer) {
    			# print("Running vor layer predicate");
    			# toggle visibility here
                var visible=nd.get_switch('toggle_waypoints') and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']) and (nd.rangeNm() <= 40);
    			layer.group.setVisible( nd.get_switch('toggle_waypoints') );
    			if (visible) {
        			#print("Updating MapStructure ND layer: FIX");
        			# (Hopefully) smart update
        			layer.update();
    			}
			}, # end of layer update predicate
		}, # end of FIX layer
		# Should redraw every 10 seconds
		{ 
            name:'storms', 
            update_on:['toggle_range','toggle_weather','toggle_display_mode'],
    		predicate: func(nd, layer) {
        		# print("Running fixes predicate");
        		var visible=nd.get_switch('toggle_weather') and nd.get_switch('toggle_display_mode') != "PLAN";
        		if (visible) {
            		#print("storms update requested!");
            		trigger_update( layer );
        		}
        		layer._view.setVisible(visible);
    		}, # end of layer update predicate
		}, # end of storms layer
		{ 
            name:'airplaneSymbol', 
            update_on:['toggle_display_mode'], 
    		predicate: func(nd, layer) {
        		var visible = nd.get_switch('toggle_display_mode') == "PLAN";
        		if (visible) {
            		trigger_update( layer );
        		} 
                layer._view.setVisible(visible);
    		},
		},
    	{ 
            name:'airports-nd', 
            update_on:['toggle_range','toggle_airports','toggle_display_mode'],
        	predicate: func(nd, layer) {
            	# print("Running airports-nd predicate");
                var visible = nd.get_switch('toggle_airports') and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']);
            	if (visible) {
                	trigger_update( layer ); # clear & redraw
            	}
            	layer._view.setVisible( visible );
        	}, # end of layer update predicate
    	}, # end of airports layer

    	# Should distinct between low and high altitude navaids. Hiding above 40 NM for now, to prevent clutter/lag.
    	{ 
            name:'vor', 
            disabled:1, 
            update_on:['toggle_range','toggle_vor','toggle_display_mode'],
        	predicate: func(nd, layer) {
            	# print("Running vor layer predicate");
                var visible = nd.get_switch('toggle_vor') and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']) and (nd.rangeNm() <= 40);
            	if(visible) {
                	trigger_update( layer ); # clear & redraw
            	}
            	layer._view.setVisible( nd.get_switch('toggle_vor') );
        	}, # end of layer update predicate
    	}, # end of VOR layer
    	{ 
            name:'VOR', 
            isMapStructure:1, 
            update_on:['toggle_range','toggle_vor','toggle_display_mode'],
        	# FIXME: this is a really ugly place for controller code
    		predicate: func(nd, layer) {
        		# print("Running vor layer predicate");
        		# toggle visibility here
                var visible = nd.get_switch('toggle_vor') and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']) and (nd.rangeNm() <= 40);
        		layer.group.setVisible( visible );
        		if (visible) {
            		#print("Updating MapStructure ND layer: VOR");
            		# (Hopefully) smart update
            		layer.update();
        		}
    		}, # end of layer update predicate
    	}, # end of VOR layer

        # Should distinct between low and high altitude navaids. Hiding above 40 NM for now, to prevent clutter/lag.
        { name:'dme', disabled:1, update_on:['toggle_range','toggle_stations'],
            predicate: func(nd, layer) {
                var visible = nd.get_switch('toggle_stations') and nd.in_mode('toggle_display_mode', ['MAP']) and (nd.rangeNm() <= 40);
                if(visible) {
                    trigger_update( layer ); # clear & redraw
                }
                layer._view.setVisible( nd.get_switch('toggle_stations') );
            }, # end of layer update predicate
        }, # end of DME layers
        { name:'DME', isMapStructure:1, update_on:['toggle_range','toggle_stations'],
            # FIXME: this is a really ugly place for controller code
        predicate: func(nd, layer) {
            var visible = nd.get_switch('toggle_stations') and nd.in_mode('toggle_display_mode', ['MAP']) and (nd.rangeNm() <= 40);
            # print("Running vor layer predicate");
            # toggle visibility here
            layer.group.setVisible( visible );
            if (visible) {
                #print("Updating MapStructure ND layer: DME");
                # (Hopefully) smart update
                layer.update();
            }
        }, # end of layer update predicate
        }, # end of DME layer

        { 
            name:'mp-traffic', 
            update_on:['toggle_range','toggle_traffic'],
            predicate: func(nd, layer) {
                var visible = nd.get_switch('toggle_traffic');
                layer._view.setVisible( visible );
                if (visible) {
                    trigger_update( layer ); # clear & redraw
                }
            }, # end of layer update predicate
        }, # end of traffic  layer
        { 
            name:'TFC', 
            disabled:1, 
            isMapStructure:1, 
            update_on:['toggle_range','toggle_traffic'],
            predicate: func(nd, layer) {
                var visible = nd.get_switch('toggle_traffic');
                layer.group.setVisible( visible );
                if (visible) {
                    #print("Updating MapStructure ND layer: TFC");
                    layer.update();
                }
            }, # end of layer update predicate
        }, # end of traffic  layer

    	{ 
            name:'runway-nd', 
            update_on:['toggle_range','toggle_display_mode'],
        	predicate: func(nd, layer) {
            	var visible = (nd.rangeNm() <= 40) and getprop("autopilot/route-manager/active") and nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN']) ;
            if (visible)
                trigger_update( layer ); # clear & redraw
                layer._view.setVisible( visible );
            }, # end of layer update predicate
        }, # end of airports-nd layer

    	{ 
            name:'route', 
            update_on:['toggle_range','toggle_display_mode'],
            predicate: func(nd, layer) {
                var visible= (nd.in_mode('toggle_display_mode', ['NAV', 'ARC','PLAN']));
                if (visible)
                    trigger_update( layer ); # clear & redraw
                    layer._view.setVisible( visible );
            }, # end of layer update predicate
        }, # end of route layer

    ## add other layers here, layer names must match the registered names as used in *.layer files for now
    ## this will all change once we're using Philosopher's MapStructure framework

    ], # end of vector with configured layers

    # This is where SVG elements are configured by providing "behavior" hashes, i.e. for animations

    # to animate each SVG symbol, specify behavior via callbacks (predicate, and true/false implementation)
    # SVG identifier, callback  etc
    # TODO: update_on([]), update_mode (update() vs. timers/listeners)
    # TODO: support putting symbols on specific layers
    features: [
        {
            # TODO: taOnly doesn't need to use getprop polling in update(), use a listener instead!
            id: 'taOnly', # the SVG ID
            impl: { # implementation hash
            	init: func(nd, symbol), # for updateCenter stuff, called during initialization in the ctor
            	predicate: func(nd) getprop("instrumentation/tcas/inputs/mode") == 2, # the condition
            	is_true:   func(nd) nd.symbols.taOnly.show(), 			# if true, run this
            	is_false:  func(nd) nd.symbols.taOnly.hide(), 			# if false, run this
        	}, # end of taOnly  behavior/callbacks
        }, # end of taOnly
        {
        	id: 'tas',
        	impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.aircraft_source.get_spd() > 100,
                is_true: func(nd) {
                    nd.symbols.tas.setText(sprintf("%3.0f",getprop("/velocities/airspeed-kt") ));
                    nd.symbols.tas.show();
                },
                is_false: func(nd) nd.symbols.tas.hide(),
        	},
        },
        {
        	id: 'tasLbl',
        	impl: {
        		init: func(nd,symbol),
        		predicate: func(nd) nd.aircraft_source.get_spd() > 100,
        		is_true: func(nd) nd.symbols.tasLbl.show(),
        		is_false: func(nd) nd.symbols.tasLbl.hide(),
        	},
        },
        {
        	id: 'ilsFreq',
        	impl: {
        		init: func(nd,symbol),
        		predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS']),
            	is_true: func(nd) {
                	nd.symbols.ilsFreq.show();
                	if(getprop("instrumentation/nav/in-range"))
                    	nd.symbols.ilsFreq.setText(getprop("instrumentation/nav/nav-id"));
                	else
                    	nd.symbols.ilsFreq.setText(getprop("instrumentation/nav/frequencies/selected-mhz-fmt"));
            	},
                is_false: func(nd) nd.symbols.ilsFreq.hide(),
			},
		},
       {
        	id: 'ilsLbl',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS']),
                is_true: func(nd) {
                   		nd.symbols.ilsLbl.show();
                },
                is_false: func(nd) nd.symbols.ilsLbl.hide(),
            },
       },
       {
            id: 'wpActiveId',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) getprop("/autopilot/route-manager/wp/id") != nil and getprop("autopilot/route-manager/active"),
                is_true: func(nd) {
                    nd.symbols.wpActiveId.setText(getprop("/autopilot/route-manager/wp/id"));
                    nd.symbols.wpActiveId.show();
                },
                is_false: func(nd) nd.symbols.wpActiveId.hide(),
            }, # of wpActiveId.impl
       }, # of wpActiveId
       {
            id: 'wpActiveDist',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) getprop("/autopilot/route-manager/wp/dist") != nil and getprop("autopilot/route-manager/active"),
                is_true: func(nd) {
                	nd.symbols.wpActiveDist.setText(sprintf("%3.01f",getprop("/autopilot/route-manager/wp/dist")));
                	nd.symbols.wpActiveDist.show();
                },
                is_false: func(nd) nd.symbols.wpActiveDist.hide(),
        	},
       },
       {
            id: 'wpActiveDistLbl',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) getprop("/autopilot/route-manager/wp/dist") != nil and getprop("autopilot/route-manager/active"),
                is_true: func(nd) {
                    nd.symbols.wpActiveDistLbl.show();
                    if(getprop("/autopilot/route-manager/wp/dist") > 1000)
                        nd.symbols.wpActiveDistLbl.setText("   NM");
                },
                is_false: func(nd) nd.symbols.wpActiveDistLbl.hide(),
            },
       },
       {
            id: 'eta',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) getprop("autopilot/route-manager/wp/eta") != nil and getprop("autopilot/route-manager/active"),
                is_true: func(nd) {
                    var etaSec = getprop("/sim/time/utc/day-seconds")+getprop("autopilot/route-manager/wp/eta-seconds");
                    var h = math.floor(etaSec/3600);
                    etaSec=etaSec-3600*h;
                    var m = math.floor(etaSec/60);
                    etaSec=etaSec-60*m;
                    var s = etaSec/10;
                    if (h>24) h=h-24;
                    nd.symbols.eta.setText(sprintf("%02.0f%02.0f.%01.0fz",h,m,s));
                    nd.symbols.eta.show();
                },
                is_false: func(nd) nd.symbols.eta.hide(),
            },  # of eta.impl
       }, # of eta
       {
            id: 'gsGroup',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS']),
                is_true: func(nd) {
                    if(nd.get_switch('toggle_centered'))
                        nd.symbols.gsGroup.setTranslation(0,0);
                    else
                        nd.symbols.gsGroup.setTranslation(0,150);
                    nd.symbols.gsGroup.show();
                },
                is_false: func(nd) nd.symbols.gsGroup.hide(),
            },
        },
        {
            id:'hdg',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','NAV', 'ARC','VOR']),
                is_true: func(nd) {
                    var hdgText = "";
                    if(nd.in_mode('toggle_display_mode', ['NAV', 'ARC'])) {
                        if(nd.get_switch('toggle_true_north'))
                            hdgText = nd.aircraft_source.get_trk_tru();
                        else
                            hdgText = nd.aircraft_source.get_trk_mag();
                    } else {
                        if(nd.get_switch('toggle_true_north'))
                            hdgText = nd.aircraft_source.get_hdg_tru();
                        else
                            hdgText = nd.aircraft_source.get_hdg_mag();
                    }
                    nd.symbols.hdg.setText(sprintf("%03.0f", hdgText+0.5));
                },
                is_false: NOTHING,
            },
        },
        {
            id:'hdgGroup',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','NAV','ARC','VOR']),
                is_true: func(nd) {
                    nd.symbols.hdgGroup.show();
                    if(nd.get_switch('toggle_centered'))
                        nd.symbols.hdgGroup.setTranslation(0,100);
                    else
                        nd.symbols.hdgGroup.setTranslation(0,0);
                },
                is_false: func(nd) nd.symbols.hdgGroup.hide(),
            },
        },
        {
        	id:'gs',
            impl: {
                init: func(nd,symbol),
                common: func(nd) nd.symbols.gs.setText(sprintf("%3.0f",nd.aircraft_source.get_gnd_spd() )),
                predicate: func(nd) nd.aircraft_source.get_gnd_spd() >= 30,
                is_true: func(nd) {
                    nd.symbols.gs.setFontSize(36);
                },
                is_false: func(nd) nd.symbols.gs.setFontSize(52),
            },
        },
        {
            id:'rangeArcs',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) ((nd.in_mode('toggle_display_mode', ['ILS','VOR']) and nd.get_switch('toggle_weather')) or nd.get_switch('toggle_display_mode') == "ARC"),
                is_true: func(nd) nd.symbols.rangeArcs.show(),
                is_false: func(nd) nd.symbols.rangeArcs.hide(),
            }, # of rangeArcs.impl
        }, # of rangeArcs
        {
            id:'rangePln1',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.get_switch('toggle_display_mode') == "PLAN",
                is_true: func(nd) { 
                    nd.symbols.rangePln1.show();
                    nd.symbols.rangePln1.setText(sprintf("%3.0f",nd.rangeNm()));
                },
                is_false: func(nd) nd.symbols.rangePln1.hide(),
            },
        },
        {
            id:'rangePln2',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.get_switch('toggle_display_mode') == "PLAN",
                is_true: func(nd) { 
                    nd.symbols.rangePln2.show();
                    nd.symbols.rangePln2.setText(sprintf("%3.0f",nd.rangeNm()/2));
                },
            	is_false: func(nd) nd.symbols.rangePln2.hide(),
            },
        },
        {
            id:'rangePln3',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.get_switch('toggle_display_mode') == "PLAN",
                is_true: func(nd) { 
                    nd.symbols.rangePln3.show();
                    nd.symbols.rangePln3.setText(sprintf("%3.0f",nd.rangeNm()/2));
                },
                is_false: func(nd) nd.symbols.rangePln3.hide(),
            },
        }, 
        {
            id:'rangePln4',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.get_switch('toggle_display_mode') == "PLAN",
                is_true: func(nd) { 
                    nd.symbols.rangePln4.show();
                    nd.symbols.rangePln4.setText(sprintf("%3.0f",nd.rangeNm()));
                },
                is_false: func(nd) nd.symbols.rangePln4.hide(),
            },
        },
        {
            id:'crsLbl',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','VOR']),
                is_true: func(nd) nd.symbols.crsLbl.show(),
                is_false: func(nd) nd.symbols.crsLbl.hide(),
            },
        },
        {
            id:'crs',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','VOR']),
                is_true: func(nd) {
                    nd.symbols.crs.show();
                    if(getprop("instrumentation/nav/radials/selected-deg") != nil)
                        nd.symbols.crs.setText(sprintf("%03.0f",getprop("instrumentation/nav/radials/selected-deg")));
                },
                is_false: func(nd) nd.symbols.crs.hide(),
            },
        },
        {
            id:'dmeLbl',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','VOR']),
                is_true: func(nd) nd.symbols.dmeLbl.show(),
                is_false: func(nd) nd.symbols.dmeLbl.hide(),
            },
        },
        {
            id:'dme',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS','VOR']),
                is_true: func(nd) {
                    nd.symbols.dme.show();
                    if(getprop("instrumentation/dme/in-range"))
                        nd.symbols.dme.setText(sprintf("%3.1f",getprop("instrumentation/nav/nav-distance")*0.000539));
                },
                is_false: func(nd) nd.symbols.dme.hide(),
            },
        },
        {
            id:'trkInd2',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (nd.in_mode('toggle_display_mode', ['ILS','VOR'])),
                is_true: func(nd) {
                    nd.symbols.trkInd2.show();
                    nd.symbols.trkInd2.setRotation((nd.aircraft_source.get_trk_tru()-nd.aircraft_source.get_hdg_tru())*D2R);
                },
                is_false: func(nd) nd.symbols.trkInd2.hide(),
            },
        },
        {
            id:'vorCrsPtr',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (nd.in_mode('toggle_display_mode', ['ILS','VOR'])),
                is_true: func(nd) {
                    nd.symbols.vorCrsPtr.show();
                    nd.symbols.vorCrsPtr.setRotation((getprop("instrumentation/nav/radials/selected-deg")-nd.aircraft_source.get_hdg_tru())*D2R);
                },
                is_false: func(nd) nd.symbols.vorCrsPtr.hide(),
            },
        },
        {
            id:'vorCrsPtr2',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (nd.in_mode('toggle_display_mode', ['ILS','VOR'])),
                is_true: func(nd) {
                    nd.symbols.vorCrsPtr2.show();
                    nd.symbols.vorCrsPtr2.setRotation((getprop("instrumentation/nav/radials/selected-deg")-nd.aircraft_source.get_hdg_tru())*D2R);
                },
                is_false: func(nd) nd.symbols.vorCrsPtr2.hide(),
            },
        },
        {
            id: 'gsDiamond',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) nd.in_mode('toggle_display_mode', ['ILS']),
                is_true: func(nd) {
                    if(getprop("instrumentation/nav/gs-needle-deflection-norm") != nil)
                        nd.symbols.gsDiamond.setTranslation(-getprop("instrumentation/nav/gs-needle-deflection-norm")*150,0);
                },
                is_false: func(nd) nd.symbols.gsGroup.hide(),
            },
        },
        {
            id:'locPtr',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (nd.in_mode('toggle_display_mode', ['ILS','VOR']) and !nd.get_switch('toggle_centered') and getprop("instrumentation/nav/in-range")),
                is_true: func(nd) {
                    nd.symbols.locPtr.show();
                    var deflection = getprop("instrumentation/nav/heading-needle-deflection-norm");
                    nd.symbols.locPtr.setTranslation(deflection*150,0);
                },
                is_false: func(nd) nd.symbols.locPtr.hide(),
            },
        },
        {
            id:'locPtr2',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (nd.in_mode('toggle_display_mode', ['ILS','VOR']) and nd.get_switch('toggle_centered') and getprop("instrumentation/nav/in-range")),
                is_true: func(nd) {
                    nd.symbols.locPtr2.show();
                    var deflection = getprop("instrumentation/nav/heading-needle-deflection-norm");
                    nd.symbols.locPtr2.setTranslation(deflection*150,0);
                },
                is_false: func(nd) nd.symbols.locPtr2.hide(),
            },
        },
        {
            id:'wind',
            impl: {
                init: func(nd,symbol),
                predicate: ALWAYS,
                is_true: func(nd) {
                    var windDir = getprop("environment/wind-from-heading-deg");
                    if(!nd.get_switch('toggle_true_north'))
                        windDir = windDir + getprop("environment/magnetic-variation-deg");
                    nd.symbols.wind.setText(sprintf("%03.0f / %02.0f",windDir,getprop("environment/wind-speed-kt")));
                },
                is_false: NOTHING,
            },
        },
        {
            id:'windArrow',
            impl: {
                init: func(nd,symbol),
                predicate: func(nd) (!(nd.in_mode('toggle_display_mode', ['PLAN']) and (nd.get_switch('toggle_display_type') == "LCD")) and nd.aircraft_source.get_spd() > 100),
                is_true: func(nd) {
                    nd.symbols.windArrow.show();
                    var windArrowRot = getprop("environment/wind-from-heading-deg");
                    if(nd.in_mode('toggle_display_mode', ['NAV','ARC','PLAN'])) {
                        if(nd.get_switch('toggle_true_north'))
                            windArrowRot = windArrowRot - nd.aircraft_source.get_trk_tru();
                        else
                            windArrowRot = windArrowRot - nd.aircraft_source.get_trk_mag();
                    } else {
                        if(nd.get_switch('toggle_true_north'))
                            windArrowRot = windArrowRot - nd.aircraft_source.get_hdg_tru();
                        else
                            windArrowRot = windArrowRot - nd.aircraft_source.get_hdg_mag();
                    }
                    nd.symbols.windArrow.setRotation(windArrowRot*D2R);
                },
                is_false: func(nd) nd.symbols.windArrow.hide(),
            },
        },
    ], # end of vector with features
}

###
# entry point, this will set up all ND instances

setlistener("sim/signals/fdm-initialized", func() {

##
# configure aircraft specific cockpit/ND switches here
# these are to be found in the property branch you specify 
# via the NavDisplay.new() call
# the backend code in navdisplay.mfd should NEVER contain any aircraft-specific
# properties, or it will break other aircraft using different properties
# instead, make up an identifier (hash key) and map it to the property used 
# in your aircraft, relative to your ND root in the backend code, only ever 
# refer to the handle/key instead via the me.get_switch('toggle_range') method
# which would internally look up the matching aircraft property, e.g. '/instrumentation/efis'/inputs/range-nm'
#
# note: it is NOT sufficient to just add new switches here, the backend code in navdisplay.mfd also
# needs to know what to do with them !
# refer to incomplete symbol implementations to learn how they work (e.g. WXR, STA)

      var myCockpit_switches = {
	# symbolic alias : relative property (as used in bindings), initial value, type
	'toggle_range': 	{path: '/inputs/range-nm', value:40, type:'INT'},
	'toggle_weather': 	{path: '/inputs/wxr', value:0, type:'BOOL'},
	'toggle_airports': 	{path: '/inputs/arpt', value:0, type:'BOOL'},
	'toggle_stations': 	{path: '/inputs/sta', value:0, type:'BOOL'},
	'toggle_waypoints': 	{path: '/inputs/wpt', value:0, type:'BOOL'},
	'toggle_position': 	{path: '/inputs/pos', value:0, type:'BOOL'},
	'toggle_data': 		{path: '/inputs/data',value:0, type:'BOOL'},
	'toggle_terrain': 	{path: '/inputs/terr',value:0, type:'BOOL'},
	'toggle_traffic': 		{path: '/inputs/tfc',value:0, type:'BOOL'},
	'toggle_centered': 		{path: '/inputs/nd-centered',value:0, type:'BOOL'},
	'toggle_lh_vor_adf':	{path: '/inputs/lh-vor-adf',value:0, type:'INT'},
	'toggle_rh_vor_adf':	{path: '/inputs/rh-vor-adf',value:0, type:'INT'},
	'toggle_display_mode': 	{path: '/nd/display-mode', value:'NAV', type:'STRING'},
	'toggle_display_type': 	{path: '/mfd/display-type', value:'LCD', type:'STRING'},
	'toggle_true_north': 	{path: '/mfd/true-north', value:0, type:'BOOL'},
	# add new switches here
      };


	# get a handle to the NavDisplay in canvas namespace (for now), see $FG_ROOT/Nasal/canvas/map/navdisplay.mfd
	var ND = canvas.NavDisplay;

	## TODO: We want to support multiple independent ND instances here!
	# foreach(var pilot; var pilots = [ {name:'cpt', path:'instrumentation/efis',
	#				     name:'fo',  path:'instrumentation[1]/efis']) {


	##
	# set up a  new ND instance, under 'instrumentation/efis' and use the 
	# myCockpit_switches hash to map control properties
    var NDCpt = ND.new("instrumentation/efis", myCockpit_switches, 'Airbus');
	
	nd_display.main = canvas.new({
		"name": "ND",
		"size": [1024, 1024],
		"view": [1024, 1024],
		"mipmapping": 1
	});

	nd_display.main.addPlacement({"node": "ND.screen"});
	var group = nd_display.main.createGroup();
	NDCpt.newMFD(group);
	NDCpt.update();

		
	print("ND Canvas Initialized!");

}); # fdm-initialized listener callback


var showNd = func() {
	# The optional second arguments enables creating a window decoration
	var dlg = canvas.Window.new([400, 400], "dialog");
	dlg.setCanvas( nd_display["main"] );
}


