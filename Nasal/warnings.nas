var memo = {
	msg: "",
	color: "",
	disp: 0,
	condition: func() { },
	new: func(arg1, arg2) {
	
		var t = {parents:[memo]};
		
		t.msg = arg1;
		t.color = arg2;
		
		return t;
	
	}
};

var warning = {
	msg: "",
	aural: "chime",
	light: "caution",
	prop: "",
	condition: func() { },
	disp: 0,
	new: func(arg1, arg2, arg3, arg4) {
		
		var t = {parents:[warning]};
		
		t.msg = arg1;
		t.aural = arg2;
		t.light = arg3;
		t.prop = "/warnings/"~arg4~"/";
		setprop(t.prop~"active", 0);
		
		return t;
	
	},
	sound: func() {
	
		setprop("/sim/sound/warnings/"~me.aural, 0);
		settimer(func() {setprop("/sim/sound/warnings/"~me.aural, 1)}, 0.5);
	
	},
	warnlight: func() {
	
		setprop("/warnings/master-"~me.light~"-light", 1);
	
	},
	trigger: func() {

		if(getprop(me.prop~"active") != 1) {
		
			me.sound();
			me.warnlight();
			setprop(me.prop~"active", 1);
			me.disp = 1;
			print("[ECAM] " ~ me.msg);
		
		}
	
	},
	deactivate: func() {
	
		setprop(me.prop~"active", 0);
		me.disp = 0;
	
	}
};

var state_loop = {
       init : func {
            me.UPDATE_INTERVAL = 0.5;
            me.loopid = 0;
        
            setprop("/warnings/master-warning-state", 0);
            setprop("/warnings/master-caution-state", 0);
            setprop("/warnings/master-warning-light", 0);
            setprop("/warnings/master-caution-light", 0);

            me.ws = "/warnings/master-warning-state";
            me.cs = "/warnings/master-caution-state";
            me.wl = "/warnings/master-warning-light";
            me.cl = "/warnings/master-caution-light";
  
            me.reset();
        },
    	update : func {
    	
            if ((getprop(me.ws) == 0) and (getprop(me.wl) == 1)) {
                    setprop(me.ws, 1);
            } else {
                    setprop(me.ws, 0);
            }
            
            if ((getprop(me.cs) == 0) and (getprop(me.cl) == 1)) {
                    setprop(me.cs, 1);
            } else {
                    setprop(me.cs, 0);
            }
    	
	},

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

var warning_system = {
       init : func {
            me.UPDATE_INTERVAL = 1;
            me.spdbrkcount = 0;
            me.loopid = 0;
           
            setprop("/warnings/master-warning-light", 0);
            setprop("/warnings/master-caution-light", 0);
            
            # Create Warnings #########################
            
            ## APU
            
            apu_emer = warning.new("APU EMER SHUT DOWN", "chime", "caution", "apu-emer");
            apu_emer.condition = func() {
                return getprop("/engines/apu/on-fire");
            };
            
            ## Flight Controls
            
            var stall = warning.new("STALL", "crc", "warning", "stall");
            stall.condition = func() {
                var flaps = getprop("/controls/flight/flaps");
                var ias = getprop("/velocities/airspeed-kt");
                return ((getprop("/position/altitude-ft") > 400) and (((ias <= 150) and (flaps <=0.29 )) or ((ias <= 135) and (flaps == 0.529)) or ((ias <= 120) and (flaps >= 74))));
            };
            
            var spdbrk_stillout = warning.new("SPD BRK STILL OUT", "chime", "caution", "spdbrk-still");
            spdbrk_stillout.condition = func() {
                return (warning_system.spdbrkcount > 50);
            };
            
            var to_cfg_flaps = warning.new("TO CONFIG...FLAPS", "crc", "warning", "to-flaps");
            to_cfg_flaps.condition = func() {
                    var weight = getprop("/fdm/jsbsim/inertia/weight-lbs");
                    var flaps = getprop("/controls/flight/flaps");
                    return ((getprop("/controls/engines/engine/throttle") > 0.95) and (getprop("/position/altitude-agl-ft") < 400) and (((weight > 380000) and (weight < 440001) and (flaps < 0.25)) or ((weight > 440000) and (flaps < 0.5))));
            };
            
            var to_cfg_pbrk = warning.new("PARKING BRAKE SET", "crc", "warning", "to-spdbrk");
            to_cfg_pbrk.condition = func() {
                    return ((getprop("/controls/engines/engine/throttle") > 0.95) and (getprop("/controls/parking-brake") != 0));
            };
			
            var to_cfg_spdbrk = warning.new("RETRACT SPD BRK", "crc", "warning", "to-spdbrk");
            to_cfg_spdbrk.condition = func() {
                    return ((getprop("/controls/engines/engine/throttle") > 0.95) and (getprop("/controls/flight/speedbrake") != 0));
            };
			
            var to_cfg_ptrim = warning.new("CHECK PITCH TRIM", "crc", "warning", "to-ptrim");
            to_cfg_ptrim.condition = func() {
                    return ((getprop("/controls/engines/engine/throttle") > 0.95) and (getprop("/position/altitude-agl-ft") < 400) and ((getprop("/controls/flight/elevator-trim") > 0.6) or (getprop("/controls/flight/elevator-trim") < -0.6)) );
            };
			
            var to_cfg_rtrim = warning.new("CHECK RUD TRIM", "crc", "warning", "to-rtrim");
            to_cfg_rtrim.condition = func() {
                    return ((getprop("/controls/engines/engine/throttle") > 0.95) and (getprop("/position/altitude-agl-ft") < 400) and ((getprop("/controls/flight/rudder-trim") > 0.5) or (getprop("/controls/flight/rudder-trim") < -0.5)) );
            };
			
            var elv_fault = warning.new("L+R ELEV FAULT", "crc", "warning", "elev-fault");
            elv_fault.condition = func() {
                    return (getprop("/velocities/airspeed-kt") > 30) and (getprop("/sim/failure-manager/controls/flight/elevator/serviceable") == 0);
            };
            
            var ail_fault = warning.new("L+R AIL FAULT", "crc", "warning", "ail-fault");
            ail_fault.condition = func() {
                    return (getprop("/velocities/airspeed-kt") > 30) and (getprop("/sim/failure-manager/controls/flight/aileron/serviceable") == 0);
            };
            
            var rud_fault = warning.new("RUDDER FAULT", "crc", "warning", "rud-fault");
            rud_fault.condition = func() {
                    return (getprop("/velocities/airspeed-kt") > 30) and (getprop("/sim/failure-manager/controls/flight/rudder/serviceable") == 0);
            };
            
            var spdbrk_fault = warning.new("L+R SPD BRK FAULT", "chime", "caution", "spdbrk-fault");
            spdbrk_fault.condition = func() {
                    return (getprop("/sim/failure-manager/controls/flight/speedbrake/serviceable") == 0);
            };
            
            var flaps_fault = warning.new("L+R FLAPS FAULT", "chime", "caution", "flaps-fault");
            flaps_fault.condition = func() {
                    return (getprop("/sim/failure-manager/controls/flight/flaps/serviceable") == 0);
            };
            
            var direct_law = warning.new("DIRECT LAW", "chime", "caution", "dir-law");
            direct_law.condition = func() {
                    return (getprop("/fbw/active-law") == "DIRECT LAW");
            };
            
            var altn_law = warning.new("ALTN LAW", "chime", "caution", "altn-law");
            altn_law.condition = func() {
                    return (getprop("/fbw/active-law") == "ALTERNATE LAW");
            };
            
            var abn_law = warning.new("ABNORMAL ALTN LAW", "chime", "caution", "abn-law");
            abn_law.condition = func() {
                    return (getprop("/fbw/active-law") == "ABNORMAL ALTERNATE LAW");
            };
                
            ## Power Plant
            
            var engd_fail = warning.new("ENG DUAL FAILURE", "crc", "warning", "engd-fail");
            engd_fail.condition = func() {
                    return ((getprop("/sim/failure-manager/engines/engine/serviceable") == 0) and ((getprop("/sim/failure-manager/engines/engine[1]/serviceable") == 0)));
            };
            
            var eng1_fail = warning.new("ENG 1 FAILURE", "chime", "caution", "eng1-fail");
            eng1_fail.condition = func() {
                    return ((getprop("/sim/failure-manager/engines/engine/serviceable") == 0) and ((getprop("/sim/failure-manager/engines/engine[1]/serviceable") == 1)));
            };
            
            var eng2_fail = warning.new("ENG 2 FAILURE", "chime", "caution", "eng2-fail");
            eng2_fail.condition = func() {
                    return ((getprop("/sim/failure-manager/engines/engine/serviceable") == 1) and ((getprop("/sim/failure-manager/engines/engine[1]/serviceable") == 0)));
            };
            
            var engd_oilp = warning.new("ENG 1+2 OIL LO PR", "crc", "warning", "engd-oil");
            engd_oilp.condition = func() {
                    return (getprop("/velocities/airspeed-kt") > 30) and (((getprop("/engines/engine/oil-pressure-psi") < 13) and (getprop("/controls/engines/engine/cutoff-switch") != 1)) and (((getprop("/engines/engine[1]/oil-pressure-psi") < 13) and (getprop("/controls/engines/engine/cutoff-switch") != 1))));
            };
            
            var eng1_oilp = warning.new("ENG 1 OIL LO PR", "chime", "caution", "eng1-oil");
            eng1_oilp.condition = func() {
                    return (((getprop("/engines/engine/oil-pressure-psi") < 13) and (getprop("/controls/engines/engine/cutoff-switch") != 1)) and (((getprop("/engines/engine[1]/oil-pressure-psi") >= 13) or (getprop("/controls/engines/engine/cutoff-switch") == 1))));
            };
            
            var eng2_oilp = warning.new("ENG 2 OIL LO PR", "chime", "caution", "eng2-oil");
            eng2_oilp.condition = func() {
                    return (((getprop("/engines/engine/oil-pressure-psi") >= 13) or (getprop("/controls/engines/engine/cutoff-switch") == 1)) and (((getprop("/engines/engine[1]/oil-pressure-psi") < 13) and (getprop("/controls/engines/engine/cutoff-switch") != 1))));
            };
            
            var engd_shut = warning.new("ENG 1+2 SHUT DOWN", "chime", "caution", "engd-shut");
            engd_shut.condition = func() {
                    return ((getprop("/position/altitude-agl-ft") >= 400) and (getprop("/controls/engines/engine/cutoff-switch") == 1) and ((getprop("/controls/engines/engine[1]/cutoff-switch") == 1)));
            };
            
            var eng1_shut = warning.new("ENG 1 SHUT DOWN", "chime", "caution", "eng1-shut");
            eng1_shut.condition = func() {
                    return ((getprop("/position/altitude-agl-ft") >= 400) and (getprop("/controls/engines/engine/cutoff-switch") == 1) and ((getprop("/controls/engines/engine[1]/cutoff-switch") == 0)));
            };
            
            var eng2_shut = warning.new("ENG 2 SHUT DOWN", "chime", "caution", "eng2-shut");
            eng2_shut.condition = func() {
                    return ((getprop("/position/altitude-agl-ft") >= 400) and (getprop("/controls/engines/engine/cutoff-switch") == 0) and ((getprop("/controls/engines/engine[1]/cutoff-switch") == 1)));
            };
            
            ## Hydraulics
            
            var hydall = warning.new("HYD SYS LO PR", "crc", "warning", "hydall");
            hydall.condition = func() {
                    return (getprop("/velocities/airspeed-kt") > 30) and ((getprop("/hydraulics/blue/pressure-psi") < 1000) and (getprop("/hydraulics/yellow/pressure-psi") < 1000) and (getprop("/hydraulics/green/pressure-psi") < 1000))
            };
            
            var hydby = warning.new("B+Y SYS LO PR", "crc", "warning", "hydby");
            hydby.condition = func() {
                    return ((getprop("/hydraulics/blue/pressure-psi") < 1000) and (getprop("/hydraulics/yellow/pressure-psi") < 1000) and (getprop("/hydraulics/green/pressure-psi") >= 1400))
            };
            
            var hydbg = warning.new("B+G SYS LO PR", "crc", "warning", "hydbg");
            hydbg.condition = func() {
                    return ((getprop("/hydraulics/blue/pressure-psi") < 1000) and (getprop("/hydraulics/yellow/pressure-psi") >= 1400) and (getprop("/hydraulics/green/pressure-psi") < 1000))
            };
            
            var hydgy = warning.new("Y+G SYS LO PR", "crc", "warning", "hydgy");
            hydgy.condition = func() {
                return (1 == 0);
                    #return ((getprop("/hydraulics/blue/pressure-psi") > 1400) and (getprop("/hydraulics/yellow/pressure-psi") < 1000) and (getprop("/hydraulics/green/pressure-psi") < 1000))
            };
            
            var hydb_lopr = warning.new("B SYS LO PR", "chime", "caution", "hydb-lopr");
            hydb_lopr.condition = func() {
                    return ((getprop("/hydraulics/blue/pressure-psi") < 1000) and (getprop("/hydraulics/yellow/pressure-psi") >= 1400) and (getprop("/hydraulics/green/pressure-psi") >= 1400))
            };
            
            var hydy_lopr = warning.new("Y SYS LO PR", "chime", "caution", "hydy-lopr");
            hydy_lopr.condition = func() {
                    return ((getprop("/hydraulics/blue/pressure-psi") >= 1400) and (getprop("/hydraulics/yellow/pressure-psi") < 1000) and (getprop("/hydraulics/green/pressure-psi") >= 1400))
            };
            
            var hydg_lopr = warning.new("G SYS LO PR", "chime", "caution", "hydg-lopr");
            hydg_lopr.condition = func() {
                    return ((getprop("/hydraulics/blue/pressure-psi") >= 1400) and (getprop("/hydraulics/yellow/pressure-psi") >= 1400) and (getprop("/hydraulics/green/pressure-psi") < 1000))
            };
            
            var ptu_fault = warning.new("PTU FAULT", "chime", "caution", "ptu-fault");
            ptu_fault.condition = func() {
                    return ((getprop("hydraulics/control/ptu") == 0) and (math.abs(getprop("/hydraulics/yellow/pressure-psi") - getprop("/hydraulics/green/pressure-psi")) > 500));
            }		
            
            ## Fuel
            
            var fuel_1lo = warning.new("L WING TK LO LVL", "chime", "caution", "fuel1lo");
            fuel_1lo.condition = func() {
                    return ((getprop("/consumables/fuel/tank[2]/level-kg") < 2200) and (getprop("/consumables/fuel/tank[4]/level-kg") >= 2200));
            };
            
            var fuel_2lo = warning.new("R WING TK LO LVL", "chime", "caution", "fuel2lo");
            fuel_2lo.condition = func() {
                    return ((getprop("/consumables/fuel/tank[2]/level-kg") >= 2200) and (getprop("/consumables/fuel/tank[4]/level-kg") < 2200));
            };
            
            var fuel_clo = warning.new("CTR TK LO LVL", "chime", "caution", "fuelclo");
            fuel_clo.condition = func() {
                    return (getprop("/consumables/fuel/tank[3]/level-kg") < 2200);
            };
            
            var fuel_wlo = warning.new("L+R WING TK LO LVL", "crc", "caution", "fuello");
            fuel_wlo.condition = func() {
                    return ((getprop("/consumables/fuel/tank[2]/level-kg") < 2200) and (getprop("/consumables/fuel/tank[4]/level-kg") < 2200));
            };
            
            var fuel_bal = warning.new("X-FEED FAULT", "chime", "caution", "fuelbal");
            fuel_bal.condition = func() {
                    return ((getprop("controls/fuel/x-feed") != 1) and (math.abs(getprop("/consumables/fuel/tank[2]/level-kg") - getprop("/consumables/fuel/tank[4]/level-kg")) > 1000));
            }			
            
            
            ## Electric
            
            var apugen_fault = warning.new("APU GEN FAULT", "chime", "caution", "apugen-fault");
            apugen_fault.condition = func() {
                    return ((getprop("/controls/electric/APU-generator") == 1) and (getprop("/engines/apu/rpm") < 95));
            };
            
            var gen1_fault = warning.new("GEN 1 FAULT", "chime", "caution", "gen1-fault");
            gen1_fault.condition = func() {
                    return (((getprop("/controls/electric/engine/generator") == 1) and (getprop("/controls/engines/engine/cutoff"))) and ((getprop("/controls/electric/engine[1]/generator") != 1) or (getprop("/controls/engines/engine[1]/cutoff")!= 1)));
            };
            
            var gen2_fault = warning.new("GEN 2 FAULT", "chime", "caution", "gen2-fault");
            gen2_fault.condition = func() {
                    return (((getprop("/controls/electric/engine/generator") != 1) or (getprop("/controls/engines/engine/cutoff") != 1)) and ((getprop("/controls/electric/engine[1]/generator") == 1) and (getprop("/controls/engines/engine[1]/cutoff"))));
            };
            
            var emer_conf = warning.new("EMER CONFIG", "crc", "warning", "emer-conf");
            emer_conf.condition = func() {
                    return (getprop("/position/altitude-agl-ft") > 400) and (((getprop("/controls/electric/engine/generator") == 1) and (getprop("/controls/engines/engine/cutoff"))) and ((getprop("/controls/electric/engine[1]/generator") == 1) and (getprop("/controls/engines/engine[1]/cutoff"))));
            }
            
            ## FMGC
            
            var ap_off = warning.new("AP 1+2 OFF", "ap_disc", "caution", "ap-off");
            ap_off.condition = func() {
                    return ((getprop("/flight-management/control/ap1-master") == "off") and (getprop("/flight-management/control/ap2-master") == "off") and (((getprop("/position/altitude-agl-ft") > 400) and (getprop("/velocities/vertical-speed-fps") < -5)) or ((getprop("/position/altitude-agl-ft") > 10000) and (getprop("/velocities/vertical-speed-fps") > 5))));
            };
            
            var athr_off = warning.new("A/THR OFF", "chime", "caution", "athr-off");
            athr_off.condition = func() {
                    return ((getprop("/flight-management/a-thrust") == "off") and (getprop("/position/altitude-agl-ft") > 400));
            };			

            # All warnings into a hash for easier use
            
            me.warnings = [stall, spdbrk_stillout, apu_emer, to_cfg_pbrk, to_cfg_flaps, to_cfg_spdbrk, to_cfg_ptrim, to_cfg_rtrim, elv_fault, ail_fault, rud_fault, spdbrk_fault, flaps_fault, direct_law, altn_law, abn_law , engd_fail, eng1_fail, eng2_fail, engd_oilp, eng1_oilp, eng2_oilp, engd_shut, eng1_shut, eng2_shut, hydall, hydby, hydbg, hydgy, hydb_lopr, hydy_lopr, hydg_lopr, ptu_fault, fuel_1lo, fuel_2lo, fuel_clo, fuel_wlo, fuel_bal, apugen_fault, gen1_fault, gen2_fault, emer_conf, ap_off, athr_off];
    
            ############################################
            
            # Create MEMO Displays
            
            var apu_avail = memo.new("APU AVAIL", "green");
            apu_avail.condition = func() {
                return (getprop("/engines/apu/rpm") > 95);
            };
            
            var spdbrk_a = memo.new("SPEED BRK", "amber");
            spdbrk_a.condition = func() {
                return ((warning_system.spdbrkcount > 50) and ((getprop("/controls/flight/speedbrake") != 0) and (getprop("/velocities/vertical-speed-fps") > -2)));
            };
            
            var spdbrk_g = memo.new("SPEED BRK", "green");
            spdbrk_g.condition = func() {
                return ((getprop("/controls/flight/speedbrake") != 0) and ((warning_system.spdbrkcount <= 50) or (getprop("/velocities/vertical-speed-fps") <= -2)));
            };
            
            var rat_a = memo.new("RAT OUT", "amber");
            rat_a.condition = func() {
                return ((getprop("position/altitude-agl-ft") < 1500) and (getprop("velocities/vertical-speed-fps") > 5) and (getprop("hydraulics/control/rat-unlck") == 1));
            };
            
            var rat_g = memo.new("RAT OUT", "green");
            rat_a.condition = func() {
                return (((getprop("position/altitude-agl-ft") >= 1500) or (getprop("velocities/vertical-speed-fps") <= 5)) and (getprop("hydraulics/control/rat-unlck") == 1));
            };
            
            var hyd_ptu = memo.new("HYD PTU", "green");
            hyd_ptu.condition = func() {
                return (getprop("/hydraulics/controls/ptu") == 1);
            };
            
            var fob_low = memo.new("FOB BELOW 3T", "amber");
            fob_low.condition = func() {
                return (getprop("/consumables/fuel/total-fuel-kg") < 2200);
            };
            
            var xfeed = memo.new("FUEL X FEED", "green");
            xfeed.condition = func() {
                return (getprop("controls/fuel/x-feed"));
            };
            
            var refuel = memo.new("REFUELG", "green");
            refuel.condition = func() {
                return (getprop("services/fuel-truck/connect") == 1);
            };
            
            var gnd_splrs = memo.new("GND SPLRS ARMED", "green");
            gnd_splrs.condition = func() {
                return (getprop("/controls/flight/ground-spoilers-armed") == 1);
            };
            
            var fuel_jett = memo.new("FUEL JETTISON", "green");
            fuel_jett.condition = func() {
                return (getprop("/controls/fuel-dump/active"));
            };

            var park_memo = memo.new("PARK BRK", "green");
            park_memo.condition = func() {
                return (getprop("/controls/gear/brake-parking") != 0);
            }
            
            # All MEMO items into a hash for easier use (in order of display priority)
            
            me.memos = [fuel_jett, apu_avail, spdbrk_a, rat_a, fob_low, spdbrk_g, rat_g, gnd_splrs, xfeed, hyd_ptu, refuel, park_memo];           
            
            ############################################
            
            me.reset();
    },
    updateMEMO : func {
		
        me.disp_memo = [];
        me.memo_color = [];
        
        foreach(var mem; me.memos) {
            if (mem.disp == 1) {
                append(me.disp_memo, mem.msg);
                append(me.memo_color, mem.color);
            }
        }
        
        for (var n=0; n<6; n+=1) {
            if (size(me.disp_memo) > n) {
                setprop("warnings/ecam/memo["~n~"]/msg", me.disp_memo[n]);
                setprop("warnings/ecam/memo["~n~"]/color", me.memo_color[n]);
            } else {
                setprop("warnings/ecam/memo["~n~"]/msg", "");
            }
        }
        var rev_thrust_warn = 'warnings/ecam/rev-thr/msg';
        if(getprop("engines/engine/reversed")){
            setprop(rev_thrust_warn,'REV');
        } else {
            setprop(rev_thrust_warn,'');
        }
    },
    
    updateECAM : func {
    
            me.disp_warnings = [];
            me.warn_index = [];
            me.warn_type = [];

            var n = 0;

            foreach(var warn; me.warnings) {
                if ((getprop(warn.prop~"active") == 1) and (warn.disp == 1)) {
                    append(me.disp_warnings, warn.msg);
                    append(me.warn_index, n);
                    append(me.warn_type, warn.light);
                }
                n+=1;
            }
            
            for(var n=0; n<12; n+=1) {
                if (size(me.disp_warnings) > n) {
                    setprop("warnings/ecam/warn["~n~"]/msg", me.disp_warnings[n]);
                    setprop("warnings/ecam/warn["~n~"]/index", me.warn_index[n]);
                    setprop("warnings/ecam/warn["~n~"]/type", me.warn_type[n]);
                } else {
                    setprop("warnings/ecam/warn["~n~"]/msg", "");
                }
            }
    
    },
    clr : func {
        var index = getprop("warnings/ecam/warn[0]/index");
        
        me.warnings[index].disp = 0;
        me.warnings[index].hide = 1;
    },
    rcl : func {
        foreach(var warn; me.warnings) {
        
                if (getprop(warn.prop~"active") == 1) {
                        warn.disp = 1;
                }
        
        }
    },
    update : func {
    	
                # Speed Brake update
                
                if (getprop("/controls/flight/speedbrake") != 0) {
                        me.spdbrkcount += 1;
                } else {
                        me.spdbrkcount = 0;
                }

                # Check for warnings
                
                foreach(var warn; me.warnings) {
                
                        var conditionMet = warn.condition();
                
                        if (conditionMet) {
                                warn.trigger();
                        } else {
                                warn.deactivate();
                        }
                
                }
                
                # Check for memo displays
                
                foreach(var mem; me.memos) {
                    var conditionMet = mem.condition();
            
                    if (conditionMet) {
                            mem.disp = 1;
                    } else {
                            mem.disp = 0;
                    }
                }
                
                me.updateECAM();
                me.updateMEMO();
    	
	},

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

setlistener("sim/signals/fdm-initialized", func {
    state_loop.init();
});

setlistener("sim/signals/fdm-initialized", func {
    warning_system.init();
});
