##################################
## AIRBUS FLY-BY-WIRE SYSTEM    ##
##################################
## Written by Narendran and Jon ##
##################################

# FLIGHT CONTROL LAWS -
## Normal Law
## Alternate Law
## Abnormal Alternate Law
## Direct Law
## Mechanical Backup

# CONSTANTS

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.0174532925;

# PATHS

var fcs = "/fdm/jsbsim/fcs/";
var input = "/controls/flight/";
var deg = "/orientation/";

var fbw_loop = {	
	init : func { 
		me.UPDATE_INTERVAL = 0.001; 
		me.loopid = 0; 

		# fbw.reset();

		## Initialize Control Surfaces

		setprop("/fdm/jsbsim/fcs/aileron-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/rudder-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/elevator-fbw-output", 0);
		
		## Flight envelope

		setprop("/limits/fbw/max-bank-soft", '33' );
		setprop("/limits/fbw/max-bank-hard", '67' );	
		setprop("/limits/fbw/max-roll-speed", '0.261799387'); # max 0.261799387 rad_sec, 15 deg_sec
		setprop("/limits/fbw/alpha-prot", '19');
		setprop("/limits/fbw/alpha-floor", '25');
		setprop("/limits/fbw/alpha-max", '30');
		setprop("/limits/fbw/alpha-min", '-15');

		setprop("/fbw/pitch-limit",30);
		setprop("/fbw/bank-limit",33);
		setprop("/fbw/bank-manual", 67);
		
		setprop("/fbw/max-pitch-rate", 15);
		setprop("/fbw/max-roll-rate", 15);
		
		setprop("/fbw/active-law", "NORMAL LAW");
		setprop("/fbw/flight-phase", "Ground Mode");
		
		# This should be moved to 'failures.nas' but as I haven't written it yet, we'll just keep the systems working fine at all times. (0 - all working | 1 - moderate failures | 2 - major failures | 3 - elec/hyd failure)
		
		setprop("/systems/condition", 0);
				
		# Servo Control Modes (0 - direct | 1 - fbw)
		# Servo Protection Modes (0 - off | 1 - protect)
		# Servo Working (0 - not working/use mech backup | 1 - working)
		
		props.globals.initNode("/fbw/stable/elevator", 0);
		props.globals.initNode("/fbw/stable/aileron", 0);
		
		# The Stabilizer (Trimmers) are used to maintain pitch and/or bank angle when the control stick is brought to the center. The active fbw controls "try" to maintain 0 pitch-rate/roll-rate/1g but if by any chance (for example during turbulence) the attitude's changed, the stabilizer can get it back to the original attitude
		
		# Stabilizer works ONLY in NORMAL LAW Flight Mode

		me.reset(); 
	},  #Init Function end


	get_state : func{
		#me.law = "NORMAL LAW";
		me.condition = getprop("/systems/condition");
		me.pitch = getprop("/orientation/pitch-deg");
		me.bank = getprop("/orientation/roll-deg");
		me.phase = getprop("/fbw/flight-phase");
		me.agl = getprop("/position/altitude-agl-ft");

		me.law = getprop("/fbw/active-law");
		me.mode = getprop("/fbw/flight-phase");
		me.pitch_limit = getprop("/fbw/pitch-limit");
		me.bank_limit = getprop("/fbw/bank-limit");
		me.manual_bank = getprop("/fbw/bank-manual");
		
		me.stick_pitch = getprop(input~ "elevator");
		me.stick_roll = getprop(input~ "aileron");
        if(fmgc.fmgc_loop.alpha_floor_mode)
            me.pitch_limit = 0;

	}, 
	get_alpha_prot : func{
		if (me.pitch <=  me.alpha_min) return 'alpha_min';
		else if (me.pitch >= me.alpha_prot and me.pitch < me.alpha_floor) return 'alpha_prot';
		else if (me.pitch >= me.alpha_floor and me.pitch < me.alpha_max) return 'alpha_floor';
		else if (me.pitch >= me.alpha_max) return 'alpha_max';
	},

	#get_aircraft : func {

	#},
	airbus_law : func {

		# Decide which law to use according to system condition
		
		if (me.condition == 1)
			me.law = "ALTERNATE LAW";
		elsif (me.condition == 2)
			me.law = "DIRECT LAW";
		elsif (me.condition == 3)
			me.law = "MECH BACKUP";
			
		## Check for abnormal attitude


		
		if ((me.pitch >= 60) or (me.pitch <= -30) or (math.abs(me.bank) >= 80))
			me.law = "ABNORMAL ALTERNATE LAW";
			
		setprop("/fbw/active-law", me.law);

	},
	flight_phase : func {

		# Find out the current flight phase (Ground/Flight/Flare)
		
				
		if (me.agl > 35)
			setprop("/fbw/flight-phase", "Flight Mode");
			
	#	if ((me.phase == "Flight Mode") and (me.agl <= 50))
	#		setprop("/fbw/flight-phase", "Flare Mode");
			
		if (getprop("/gear/gear/wow"))
			setprop("/fbw/flight-phase", "Ground Mode");

	},
	law_normal : func {
		# Protection
		
		if ((me.pitch > me.pitch_limit) or (me.pitch < -0.5 * me.pitch_limit) or (math.abs(me.bank) > me.bank_limit)) {
		
			setprop("/fbw/control/aileron", 0);
			setprop("/fbw/control/elevator", 0);
			
			setprop("/fbw/protect-mode", 1);
            setprop("/fbw/stable/elevator", 0);
            setprop("/fbw/stable/aileron", 0);
		
		} else {
		
            setprop("/fbw/protect-mode", 0);

			# Ground Mode
	
			if (me.mode == "Ground Mode") {
		
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
		
			# Flight Mode
		
			} elsif (me.mode == "Flight Mode") {
			
				setprop("/fbw/control/elevator", 1);
				setprop("/fbw/control/aileron", 1);
			
				if ((math.abs(me.stick_pitch) >= 0.02) or (me.mode == "Ground Mode") or (me.law != "NORMAL LAW") or (getprop("/flight-management/control/ap1-master") == "eng") or (getprop("/flight-management/control/ap2-master") == "eng")) {
				
					# setprop("/fbw/control/elevator", 1);
					setprop("/fbw/stable/elevator", 0);
				
				} else {
				
					if (getprop("/fbw/stable/elevator") != 1) {
					
						setprop("/fbw/stable/pitch-deg", me.pitch);
						
						# setprop("/fbw/control/elevator", 0);
						setprop("/fbw/stable/elevator", 1);
					
					} 
					
				}
				
				if ((math.abs(me.stick_roll) >= 0.02) or (getprop("/flight-management/control/ap1-master") == "eng") or (getprop("/flight-management/control/ap2-master") == "eng")) {
				
					# setprop("/fbw/control/aileron", 1);
					setprop("/fbw/stable/aileron", 0);
					
				} else {
				
					if (getprop("/fbw/stable/aileron") == 0) {
					
						setprop("/fbw/stable/bank-deg", me.bank);
						
						# setprop("/fbw/control/aileron", 0);
						setprop("/fbw/stable/aileron", 1);
					
					}
									
				}
			
			# Flare Mode
			
			} else {
			
				# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
				
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
			
			}
		
		}
	},
	law_direct : func {
		setprop("/fbw/control/aileron", 0);
		setprop("/fbw/control/elevator", 0);
	},
	law_alternate : func {
		## Flight Envelope Protection is NOT offered
	
		# Ground Mode
		if (me.mode == "Ground Mode") {
		
			setprop("/fbw/control/aileron", 0);
			setprop("/fbw/control/elevator", 0);

		# Flight Mode
		} elsif (me.mode == "Flight Mode") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
			
			} else {
		
				setprop("/fbw/control/aileron", 1);
				setprop("/fbw/control/elevator", 1);
		
			}


		# Flare Mode
		} else {
		
			# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
			
			setprop("/fbw/control/aileron", 0);
			setprop("/fbw/control/elevator", 0);
		}
	
	},
	law_abnormal_alternate : func {

		# Ground Mode
		if (me.mode == "Ground Mode") {
		
			setprop("/fbw/control/elevator", 0);
	

		# Flight Mode
		} elsif (me.mode == "Flight Mode") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				setprop("/fbw/control/elevator", 0);
			
			} else {
		
				setprop("/fbw/control/elevator", 1);
		
			}
		}
					
		setprop("/fbw/control/aileron", 0);
	},
	
	neutralize_trim : func(stab) {
	
		var trim_prop = "/controls/flight/" ~ stab ~ "-trim";
		
		var trim = getprop(trim_prop);
		
		if (trim > 0.005)
			setprop(trim_prop, trim - 0.01);
		elsif (trim < -0.005)
			setprop(trim_prop, trim + 0.01);
	
	},

	update : func {

		# Update vars from property tree
		me.get_state();

		# Decide which law to use according to system condition
		me.airbus_law();
		
		# Find out the current flight phase (Ground/Flight/Flare)
		me.flight_phase();

		# Bring Stabilizers to 0 gradually when stabilizer mode is turned off
                #print("FBW UPD");
		
		if ((getprop("/fbw/stable/elevator") != 1) and (me.mode == "Flight Mode") and (me.law == "NORMAL LAW"))
			me.neutralize_trim("elevator");
			
		if (getprop("/fbw/stable/aileron") != 1)
			me.neutralize_trim("aileron");

		########################### PRECAUTIONS #############################

		# Reset Stabilizers when out of NORMAL LAW Flight Mode
		
		if ((me.law != "NORMAL LAW") or (me.mode != "Flight Mode")) {
		
			setprop("/controls/flight/aileron-trim", 0);
		
		}
		
		#if ((me.law != "NORMAL LAW") or (me.mode != "Flight Mode")) {
		
		#	setprop("/controls/flight/elevator-trim", 0);
		
		#}
		
		#####################################################################

		if (me.law == "NORMAL LAW") me.law_normal();
		elsif (me.law == "ALTERNATE LAW") me.law_alternate();
		elsif (me.law == "ABNORMAL ALTERNATE LAW") me.law_abnormal_alternate();
		elsif (me.law == "DIRECT LAW") law_direct();
		elsif (me.law == "MECHANICAL BACKUP") law_mechanical_backup();
				


		# Load Limit and Flight Envelope Protection
		if (getprop("/fbw/protect-mode")) {
		
			 # PITCH AXIS
			 
			 if ((me.pitch > me.pitch_limit) and (me.stick_pitch <= 0)) {
			 
			 	setprop("/fbw/target-pitch", me.pitch_limit);
				setprop("/fbw/pitch-hold", 1);
			 
			 } elsif ((me.pitch < -0.5 * me.pitch_limit) and (me.stick_pitch >= 0)) {
			 
			 	setprop("/fbw/target-pitch", -0.5 * me.pitch_limit);
				setprop("/fbw/pitch-hold", 1);
			 
			 } else
			 	
			 	setprop("/fbw/pitch-hold", 0);
			 
			 # ROLL AXIS 
			 
			 if ((me.stick_roll >= 0.5) and (me.bank > me.manual_bank)) {
			 
			 	setprop("/fbw/target-bank", me.manual_bank);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((me.stick_roll <= -0.5) and (me.bank < -1 * me.manual_bank)) {
			 
			 	setprop("/fbw/target-bank", -1 * me.manual_bank);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((me.stick_roll < 0.5) and (me.stick_roll >= 0) and (me.bank > me.bank_limit)) {
			 
			 	setprop("/fbw/target-bank", me.bank_limit);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((me.stick_roll > -0.5) and (me.stick_roll <= 0) and (me.bank < -1 * me.bank_limit)) {
			 
			 	setprop("/fbw/target-bank", -1 * me.bank_limit);
				setprop("/fbw/bank-hold", 1);
			 
			 } else
			 
			 	setprop("/fbw/bank-hold", 0);
		
		} else {
            setprop("/fbw/pitch-hold", 0);
        }
		
#####################################################################

		# DIRECT Servo Control (just simple copying)
		
		if (getprop("/fbw/control/aileron") == 0)
				
			setprop("/fdm/jsbsim/fcs/aileron-fbw-output", getprop("/controls/flight/aileron"));
			
		if (getprop("/fbw/control/elevator") == 0)
		
			setprop("/fdm/jsbsim/fcs/elevator-fbw-output", getprop("/controls/flight/elevator"));
		
#####################################################################

		# FLY-BY-WIRE Servo Control

		# Convert Stick Position into target G-Force
		
		## Pitch Rate Control
		
		me.pitch_gforce = (me.stick_pitch * -1.75) + 1;
		
		me.pitch_rate = (me.stick_pitch * -1 * getprop("/fbw/max-pitch-rate"));
		
		## Roll Rate Control
		
		me.roll_rate = (me.stick_roll * getprop("/fbw/max-roll-rate"));
		
		## Set G-forces to properties for xml to read
		
		setprop("/fbw/target-pitch-gforce", me.pitch_gforce);
		setprop("/fbw/target-roll-rate", me.roll_rate);
		setprop("/fbw/target-pitch-rate", me.pitch_rate);
		
		if (getprop("/fbw/control/elevator")) {
		
			# Load Factor over 210 kts
		
		# LOAD FACTOR COMMENTED OUT FOR TESTING
		#	
		#	if (getprop("/velocities/airspeed-kt") > 210) {
		#		
		#		setprop("/fbw/elevator/pitch-rate", 0);
		#		setprop("/fbw/elevator/load-factor", 1);
		#		
		#	} else {
		#	
				setprop("/fbw/elevator/pitch-rate", 1);
				setprop("/fbw/elevator/load-factor", 0);
			
		#	}
		
		}

	}, # Update Fuction end

	reset : func {
		me.loopid += 1;
		me._loop_(me.loopid);
	},

	_loop_ : func(id) {
		id == me.loopid or return;
		me.update();
		settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
	}

};
###
# END fwb_loop var
###

fbw_loop.init();
print("Airbus Fly-by-wire Initialized");
