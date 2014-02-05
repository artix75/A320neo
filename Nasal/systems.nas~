# AIRBUS A320 SYSTEMS FILE
##########################

## LIVERY SELECT
################

print("Initializing livery select for " ~ getprop("sim/aero"));
aircraft.livery.init("Aircraft/A330-200/Models/Liveries/" ~ getprop("sim/aero"));

#setlistener("sim/model/livery/texture", func
# {
# var base = getprop("sim/model/livery/texture");
## No more diferences on New Folder Structure. there should be consolidated on model xmls to just use one var
## setprop("sim/model/livery/texture-path[0]", "../Models/" ~ base);
## setprop("sim/model/livery/texture-path[1]", "../../Models/" ~ base);
# setprop("sim/model/livery/texture-path[0]", "../" ~ base);
# setprop("sim/model/livery/texture-path[1]", "../" ~ base);
# }, 1, 1);

#setlistener("/ai/models/multiplayer/sim/model/livery/texture", func
# {
# var base = getprop("/ai/models/multiplayer/sim/model/livery/texture");
## No more diferences on New Folder Structure. there should be consolidated on model xmls to just use one var
## setprop("sim/model/livery/texture-path[0]", "../Models/" ~ base);
## setprop("sim/model/livery/texture-path[1]", "../../Models/" ~ base);
# setprop("/ai/models/multiplayer/sim/model/livery/texture-path[0]", "../" ~ base);
# setprop("/ai/models/multiplayer/sim/model/livery/texture-path[1]", "../" ~ base);
# }, 1, 1);

## LIGHTS
#########

# create all lights
var beacon_switch = props.globals.getNode("controls/switches/beacon", 2);
var beacon = aircraft.light.new("sim/model/lights/beacon", [0.015, 3], "controls/lighting/beacon");

var strobe_switch = props.globals.getNode("controls/switches/strobe", 2);
var strobe = aircraft.light.new("sim/model/lights/strobe", [0.025, 1.5], "controls/lighting/strobe");

## SOUNDS
#########

# seatbelt/no smoking sign triggers
setlistener("controls/switches/seatbelt-sign", func
 {
 props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/seatbelt-sign").setBoolValue(0);
  }, 2);
 });
setlistener("controls/switches/no-smoking-sign", func
 {
 props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(1);

 settimer(func
  {
  props.globals.getNode("sim/sound/no-smoking-sign").setBoolValue(0);
  }, 2);
 });

## WARNING
##########

# Clear Warnings!
var WARNclear = func
	{
		var MCaution = getprop("sim/alarms/master-caution");

		if (!MCaution)
	
			{ 
				#is there any other way to shutdown ALL alarms. like * or so..
				setprop("sim/alarms/AP-Disengage", 0);
				setprop("sim/alarms/stall-warning", 0);
		
			}
	};
setlistener("sim/alarms/master-caution", WARNclear, 1, 0);


# Enable AP disengage warning
var APWarning = func
	{
		var AP = getprop("autopilot/settings/engaged");
		var airspeed = getprop("velocities/airspeed-kt");

		if (!AP and airspeed > 130)
	
			{
				setprop("sim/alarms/master-caution", 1);
				setprop("sim/alarms/AP-Disengage", 1);
		
			}
	};
setlistener("autopilot/settings/engaged", APWarning, 1, 0);




## ENGINES
##########

# APU loop function
var apuLoop = func
 {
 if (props.globals.getNode("engines/apu/on-fire").getBoolValue())
  {
  props.globals.getNode("engines/apu/serviceable").setBoolValue(0);
  }
 if (props.globals.getNode("controls/APU/fire-switch").getBoolValue())
  {
  props.globals.getNode("engines/apu/on-fire").setBoolValue(0);
  }
 if (props.globals.getNode("engines/apu/serviceable").getBoolValue() and (props.globals.getNode("controls/APU/master-switch").getBoolValue() or props.globals.getNode("controls/APU/starter").getBoolValue()))
  {
  if (props.globals.getNode("controls/APU/starter").getBoolValue())
   {
   var rpm = getprop("engines/apu/rpm");
   rpm += getprop("sim/time/delta-realtime-sec") * 7;
   if (rpm >= 100)
    {
    rpm = 100;
    }
   setprop("engines/apu/rpm", rpm);
   }
  if (props.globals.getNode("controls/APU/master-switch").getBoolValue() and getprop("engines/apu/rpm") == 100)
   {
   props.globals.getNode("engines/apu/running").setBoolValue(1);
   }
  }
 else
  {
  props.globals.getNode("engines/apu/running").setBoolValue(0);

  var rpm = getprop("engines/apu/rpm");
  rpm -= getprop("sim/time/delta-realtime-sec") * 5;
  if (rpm < 0)
   {
   rpm = 0;
   }
  setprop("engines/apu/rpm", rpm);
  }

 settimer(apuLoop, 0);
 };
# engine loop function
var engineLoop = func(engine_no)
 {
 var tree1 = "engines/engine[" ~ engine_no ~ "]/";
 var tree2 = "controls/engines/engine[" ~ engine_no ~ "]/";

 if (props.globals.getNode(tree1 ~ "on-fire").getBoolValue())
  {
  props.globals.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").setBoolValue(0);
  }
 if (props.globals.getNode(tree2 ~ "fire-bottle-discharge").getBoolValue())
  {
  props.globals.getNode(tree1 ~ "on-fire").setBoolValue(0);
  }
 if (props.globals.getNode("sim/failure-manager/engines/engine[" ~ engine_no ~ "]/serviceable").getBoolValue())
  {
  props.globals.getNode(tree2 ~ "cutoff").setBoolValue(props.globals.getNode(tree2 ~ "cutoff-switch").getBoolValue());
  }
 props.globals.getNode(tree2 ~ "starter").setBoolValue(props.globals.getNode(tree2 ~ "starter-switch").getBoolValue());

 if (getprop("controls/engines/engine-start-switch") == 0 or getprop("controls/engines/engine-start-switch") == 2)
  {
  props.globals.getNode(tree2 ~ "starter").setBoolValue(1);
  }

 if (!props.globals.getNode("engines/apu/running").getBoolValue())
  {
  props.globals.getNode(tree2 ~ "starter").setBoolValue(0);
  }

 settimer(func
  {
  engineLoop(engine_no);
  }, 0);
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  engineLoop(0);
  engineLoop(1);
  apuLoop();
  }, 2);
 });

# startup/shutdown functions
var startup = func
 {
 setprop("controls/electric/battery-switch", 1);
 setprop("controls/electric/engine[0]/generator", 1);
 setprop("controls/electric/engine[1]/generator", 1);
 setprop("controls/engines/engine[0]/cutoff-switch", 1);
 setprop("controls/engines/engine[1]/cutoff-switch", 1);
 setprop("controls/fuel/tank[2]/boost-pump", 1);
 setprop("controls/fuel/tank[4]/boost-pump", 1);
 setprop("controls/APU/master-switch", 1);
 setprop("controls/APU/starter", 1);

 var listener1 = setlistener("engines/apu/running", func
  {
  if (props.globals.getNode("engines/apu/running").getBoolValue())
   {
   setprop("controls/engines/engine-start-switch", 2);
   settimer(func
    {
    setprop("controls/engines/engine[0]/cutoff-switch", 0);
    setprop("controls/engines/engine[1]/cutoff-switch", 0);
    }, 2);
   removelistener(listener1);
   }
  }, 0, 0);
 var listener2 = setlistener("engines/engine[0]/running", func
  {
  if (props.globals.getNode("engines/engine[0]/running").getBoolValue())
   {
   settimer(func
    {
    setprop("controls/APU/master-switch", 0);
    setprop("controls/APU/starter", 0);
    setprop("controls/electric/battery-switch", 0);
    }, 2);
   removelistener(listener2);
   }
  }, 0, 0);
 };
var shutdown = func
 {
 setprop("controls/electric/engine[0]/generator", 0);
 setprop("controls/electric/engine[1]/generator", 0);
 setprop("controls/engines/engine[0]/cutoff-switch", 1);
 setprop("controls/engines/engine[1]/cutoff-switch", 1);
 };

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle)
 {
 var run = idle.getBoolValue();
 if (run)
  {
  startup();
  }
 else
  {
  shutdown();
  }
 }, 0, 0);

## GEAR
#######

# prevent retraction of the landing gear when any of the wheels are compressed
setlistener("controls/gear/gear-down", func
 {
 var down = props.globals.getNode("controls/gear/gear-down").getBoolValue();
 if (!down and (getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow")))
  {
  props.globals.getNode("controls/gear/gear-down").setBoolValue(1);
  }
 });

## INSTRUMENTS
##############

var instruments =
 {
 calcBugDeg: func(bug, limit)
  {
  var heading = getprop("orientation/heading-magnetic-deg");
  var bugDeg = 0;

  while (bug < 0)
   {
   bug += 360;
   }
  while (bug > 360)
   {
   bug -= 360;
   }
  if (bug < limit)
   {
   bug += 360;
   }
  if (heading < limit)
   {
   heading += 360;
   }
  # bug is adjusted normally
  if (math.abs(heading - bug) < limit)
   {
   bugDeg = heading - bug;
   }
  elsif (heading - bug < 0)
   {
   # bug is on the far right
   if (math.abs(heading - bug + 360 >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug + 360 < 180))
    {
    bugDeg = limit;
    }
   }
  else
   {
   # bug is on the far right
   if (math.abs(heading - bug >= 180))
    {
    bugDeg = -limit;
    }
   # bug is on the far left
   elsif (math.abs(heading - bug < 180))
    {
    bugDeg = limit;
    }
   }

  return bugDeg;
  },
 loop: func
  {
  instruments.setHSIBugsDeg();
  instruments.setSpeedBugs();
  instruments.setMPProps();
  instruments.calcEGTDegC();

  settimer(instruments.loop, 0);
  },
 # set the rotation of the HSI bugs
 setHSIBugsDeg: func
  {
  setprop("sim/model/A330-200/heading-bug-pfd-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 80));
  setprop("sim/model/A330-200/heading-bug-deg", instruments.calcBugDeg(getprop("autopilot/settings/heading-bug-deg"), 37));
  setprop("sim/model/A330-200/nav1-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[0]/heading-deg"), 37));
  setprop("sim/model/A330-200/nav2-bug-deg", instruments.calcBugDeg(getprop("instrumentation/nav[1]/heading-deg"), 37));
  if (getprop("autopilot/route-manager/route/num") > 0 and getprop("autopilot/route-manager/wp[0]/bearing-deg") != nil)
   {
   setprop("sim/model/A330-200/wp-bearing-deg", instruments.calcBugDeg(getprop("autopilot/route-manager/wp[0]/bearing-deg"), 45));
   }
  },
 setSpeedBugs: func
  {
  setprop("sim/model/A330-200/ias-bug-kt-norm", getprop("autopilot/settings/target-speed-kt") - getprop("velocities/airspeed-kt"));
  setprop("sim/model/A330-200/mach-bug-kt-norm", (getprop("autopilot/settings/target-speed-mach") - getprop("velocities/mach")) * 600);
  },
 setMPProps: func
  {
  var calcMPDistance = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   var distance = nil;
   call(func distance = geo.aircraft_position().distance_to(coords), nil, var err = []);
   if (size(err) or distance == nil)
    {
    return 0;
    }
   else
    {
    return distance;
    }
   };
  var calcMPBearing = func(tree)
   {
   var x = getprop(tree ~ "position/global-x");
   var y = getprop(tree ~ "position/global-y");
   var z = getprop(tree ~ "position/global-z");
   var coords = geo.Coord.new().set_xyz(x, y, z);

   return geo.aircraft_position().course_to(coords);
   };
  if (getprop("ai/models/multiplayer[0]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[0]", calcMPDistance("ai/models/multiplayer[0]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[0]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[0]/"), 45));
   }
  if (getprop("ai/models/multiplayer[1]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[1]", calcMPDistance("ai/models/multiplayer[1]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[1]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[1]/"), 45));
   }
  if (getprop("ai/models/multiplayer[2]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[2]", calcMPDistance("ai/models/multiplayer[2]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[2]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[2]/"), 45));
   }
  if (getprop("ai/models/multiplayer[3]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[3]", calcMPDistance("ai/models/multiplayer[3]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[3]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[3]/"), 45));
   }
  if (getprop("ai/models/multiplayer[4]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[4]", calcMPDistance("ai/models/multiplayer[4]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[4]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[4]/"), 45));
   }
  if (getprop("ai/models/multiplayer[5]/valid"))
   {
   setprop("sim/model/A330-200/multiplayer-distance[5]", calcMPDistance("ai/models/multiplayer[5]/"));
   setprop("sim/model/A330-200/multiplayer-bearing[5]", instruments.calcBugDeg(calcMPBearing("ai/models/multiplayer[5]/"), 45));
   }
  },
 calcEGTDegC: func()
  {
  if (getprop("engines/engine[0]/egt-degf") != nil)
   {
   setprop("engines/engine[0]/egt-degc", (getprop("engines/engine[0]/egt-degf") - 32) * 1.8);
   }
  if (getprop("engines/engine[1]/egt-degf") != nil)
   {
   setprop("engines/engine[1]/egt-degc", (getprop("engines/engine[1]/egt-degf") - 32) * 1.8);
   }
  }
 };
# start the loop 2 seconds after the FDM initializes
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(instruments.loop, 2);
 });

## AUTOPILOT
############

# set the vertical speed setting if the altitude setting is higher/lower than the current altitude
var APVertSpeedSet = func
 {
 var altitude = getprop("instrumentation/altimeter/indicated-altitude-ft");
 var altitudeSetting = getprop("autopilot/settings/target-altitude-ft");
 var vertSpeedSetting = getprop("autopilot/settings/vertical-speed-fpm");

 if (altitude and altitudeSetting and vertSpeedSetting and math.abs(altitude - altitudeSetting) > 100)
  {
  if (altitude > altitudeSetting and vertSpeedSetting >= 0)
   {
   setprop("autopilot/settings/vertical-speed-fpm", -1000);
   }
  elsif (altitude < altitudeSetting and vertSpeedSetting <= 0)
   {
   setprop("autopilot/settings/vertical-speed-fpm", 1800);
   }
  }
 };
setlistener("autopilot/settings/target-altitude-ft", APVertSpeedSet, 1, 0);

## DOORS
########

# create all doors
# front doors
var doorl1 = aircraft.door.new("sim/model/door-positions/doorl1", 2);
var doorr1 = aircraft.door.new("sim/model/door-positions/doorr1", 2);

# middle doors (A321 only)
var doorl2 = aircraft.door.new("sim/model/door-positions/doorl2", 2);
var doorr2 = aircraft.door.new("sim/model/door-positions/doorr2", 2);
var doorl3 = aircraft.door.new("sim/model/door-positions/doorl3", 2);
var doorr3 = aircraft.door.new("sim/model/door-positions/doorr3", 2);

# rear doors
var doorl4 = aircraft.door.new("sim/model/door-positions/doorl4", 2);
var doorr4 = aircraft.door.new("sim/model/door-positions/doorr4", 2);

# cargo holds
var cargobulk = aircraft.door.new("sim/model/door-positions/cargobulk", 2.5);
var cargoaft = aircraft.door.new("sim/model/door-positions/cargoaft", 2.5);
var cargofwd = aircraft.door.new("sim/model/door-positions/cargofwd", 2.5);

# seat armrests in the flight deck
var armrests = aircraft.door.new("sim/model/door-positions/armrests", 2);

# door opener/closer
var triggerDoor = func(door, doorName, doorDesc)
 {
 if (getprop("sim/model/door-positions/" ~ doorName ~ "/position-norm") > 0)
  {
  gui.popupTip("Closing " ~ doorDesc ~ " door");
  door.toggle();
  }
 else
  {
  if (getprop("velocities/groundspeed-kt") > 5)
   {
   gui.popupTip("You cannot open the doors while the aircraft is moving");
   }
  else
   {
   gui.popupTip("Opening " ~ doorDesc ~ " door");
   door.toggle();
   }
  }
 };
