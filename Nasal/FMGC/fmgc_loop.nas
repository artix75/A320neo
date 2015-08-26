var fmgc = "/flight-management/control/";
var settings = "/flight-management/settings/";
var fcu = "/flight-management/fcu-values/";
var fmgc_val = "/flight-management/fmgc-values/";
var fmfd = "/flight-management/fd/";
var servo = "/servo-control/";
var flight_modes = "/flight-management/flight-modes/";
var lmodes = flight_modes ~ "lateral/";
var vmodes = flight_modes ~ "vertical/";
var common_modes = flight_modes ~ "common/";
var athr_modes = flight_modes ~ "athr/";
var radio = "/flight-management/freq/";
var actrte = "/autopilot/route-manager/route/";

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.016774532925;
var NM2FT = 6076.11549;
var FT2NM = 0.000164579;
var KTS2FPS = 1.68780986;

setprop("/flight-management/text/qnh", "QNH");

setprop(settings~ "gps-accur", "LOW");

setprop("/flight-management/end-flight", 0);
setprop('/instrumentation/texts/pfd-fmgc-empty-box', '       I');
setprop('/instrumentation/texts/pfd-fmgc-empty-box-2lines', "       .\n       .");
setprop('/instrumentation/texts/sep-string', 'I');

var fmgc_loop = {
    alpha_floor_mode: 0,
    spd_profile: {
        CLB: [290, 0.68],
        CRZ: [320, 0.78],
        DES: [280, 0.68]
    },
    minimum_speeds: [150, 150, 135, 130, 120],
    init : func {
        me.UPDATE_INTERVAL = 0.1;
        me.loopid = 0;

        me.current_wp = 0;
    
        me.fixed_thrust = 0;
        me.capture_alt_at = 0;
        me.capture_alt_target = -9999;
    
        me.ver_managed = 0;
        me.top_desc = -9999;
    
        me.rwy_mode = 0;
        me.ref_crz_alt = 0;
        me.crz_fl = 0;
        me.fcu_alt = 0;
        me.use_true_north = 1;
    
        if (getprop('/flight-management/skip-init')){
            setprop('/flight-management/skip-init', 0);
            me.reset();
        }
    
        setprop("/flight-management/current-wp", me.current_wp);
        setprop("/flight-management/control/qnh-mode", 'inhg');

        # ALT SELECT MODE

        setprop(fmgc~ "alt-sel-mode", "100"); # AVAIL MODES : 100 1000

        # AUTO-THROTTLE

        setprop(fmgc~ "spd-mode", "ias"); # AVAIL MODES : ias mach
        setprop(fmgc~ "spd-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set

        setprop(fmgc~ "a-thr/ias", 0);
        setprop(fmgc~ "a-thr/mach", 0);

        setprop(fmgc~ "fmgc/ias", 0);
        setprop(fmgc~ "fmgc/mach", 0);

        setprop(fmgc~ "spd-with-pitch", 0);
        setprop(settings~ 'spd-pitch-min', 0);
        setprop(settings~ 'spd-pitch-max', 0);

        # AUTOPILOT (LATERAL)

        setprop(fmgc~ "lat-mode", "hdg"); # AVAIL MODES : hdg nav1
        setprop(fmgc~ "lat-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set

        # AUTOPILOT (VERTICAL)

        setprop(fmgc~ "ver-mode", "alt"); # AVAIL MODES : alt (vs/fpa) ils
        setprop(fmgc~ "ver-sub", "vs"); # AVAIL MODES : vs fpa
        setprop(fmgc~ "ver-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set

        # AUTOPILOT (MASTER)

        setprop(fmgc~ "ap1-master", "off");
        setprop(fmgc~ "ap2-master", "off");
        setprop(fmgc~ "a-thrust", "off");
        me.a_thr = 'off';
        me.last_thrust = 0;

        # Rate/Load Factor Configuration

        setprop(settings~ "pitch-norm", 0.1);
        setprop(settings~ "roll-norm", 0.2);

        # Terminal Procedure

        setprop("/flight-management/procedures/active", "off"); # AVAIL MODES : off sid star iap

        # Set Flight Control Unit Initial Values

        setprop(fcu~ "ias", 250);
        setprop(fcu~ "mach", 0.78);

        setprop(fcu~ "alt", 10000);
        setprop(fcu~ "fcu-alt", 10000);
        setprop(fcu~ "vs", 1800);
        setprop(fcu~ "fpa", 5);

        setprop(fcu~ "hdg", 0);
        setprop('autopilot/settings/heading-bug-deg', 0);

        setprop(fmgc_val~ "ias", 250);
        setprop(fmgc_val~ "mach", 0.78);

        # Servo Control Settings

        setprop(servo~ "aileron", 0);
        setprop(servo~ "aileron-nav1", 0);
        setprop(servo~ "target-bank", 0);

        setprop(servo~ "elevator-vs", 0);
        setprop(servo~ "elevator-gs", 0);
        setprop(servo~ "elevator-fpa", 0);
        setprop(servo~ "elevator", 0);
        setprop(servo~ "target-pitch", 0);

        setprop(fmfd~ "aileron", 0);
        setprop(fmfd~ "aileron-nav1", 0);
        setprop(fmfd~ "target-bank", 0);

        setprop(fmfd ~ "target-vs", 0);
        setprop(fmfd ~ "target-fpa", 0);
        setprop(fmfd ~ "pitch-vs", 0);
        setprop(fmfd ~ "pitch-fpa", 0);
        setprop(fmfd ~ "pitch-gs", 0);
        setprop('instrumentation/pfd/fd_pitch', 0);
        setprop(radio~ 'ils-cat', '');
        setprop('instrumentation/pfd/athr-alert-box', 0);
        setprop(fmgc~ 'capture-leg', 0);
        setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/trans-alt'));
    
        me.descent_started = 0;
        me.decel_point = 0;
        me.top_desc = 0;
    
        me.alpha_floor_mode = 0;
        me.thrust_lock = 0;
        me.thrust_lock_reason = '';
        me.thrust_lock_value = 0;
        me.toga_trk = nil;
        me.rwy_trk = nil;
        me.green_dot_spd = 155;
        me.non_precision_app = 0;
        me.app_cat = 0;

        me.dest_airport = '';
        me.dest_rwy = '';
        me.destination = nil;
        me.approach_runway = nil;
        me.approach_ils = nil;
        me.destination_wp_info = nil;

        me.active_athr_mode = '';
        me.armed_athr_mode = '';
        me.active_lat_mode = '';
        me.armed_lat_mode = '';
        me.active_ver_mode = '';
        me.armed_ver_mode = '';
        me.active_common_mode = '';
        me.armed_common_mode = '';
        me.max_throttle = 0;
        me.airborne = 0;
        me.toga_on_ground = 0;
        me.missed_approach_planned = 0;
        me.missed_approach_idx = -1;
        me.missed_approach = 0;
        me.decel_point = 0;
        me.capturing_leg = 0;
        # Radio
    
        setprop(radio~ 'autotuned', 0);
        me.autotune = {
            airport: '',
            #vor: '',
            rwy: '',
            frq: ''
        };

        me.vne = getprop('limits/vne');
        me.time = systime();
        me.reset();
    },
    update : func {
        if(RouteManager.sequencing) {
            me.wp = nil;
            return;
        };
        me.time = systime();
        var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
        var ias = getprop("/velocities/airspeed-kt");
        var mach = getprop("/velocities/mach");
        var vmode_vs_fps = getprop('/velocities/vertical-speed-fps');
        setprop("/instrumentation/pfd/vs-100", vmode_vs_fps * 0.6);
        
        me.altitude = altitude;
        me.ias = ias;
        me.mach = mach;
        me.vs_fps = vmode_vs_fps;
        
        #me.phase = me.flight_phase();

        me.get_settings();
        me.get_current_state();
        me.check_flight_modes();

        me.lvlch_check();

        me.knob_sum();

        me.hdg_disp();

        me.fcu_lights();
        
        me.update_fcu();

        setprop("flight-management/procedures/active", procedure.check());
        setprop("autopilot/route-manager/real-remaining-nm", me.remaining_nm);
        setprop("autopilot/route-manager/real-distance-nm", me.fp_distance);
        
        setprop(fcu~ "alt-100", me.alt_100());
        setprop(fcu~ "alt-disp", me.target_alt_disp());
        var follow_cstr = (
            me.follow_alt_cstr and (
                me.armed_ver_mode == 'ALT' or 
                me.armed_ver_secondary_mode == 'ALT'
            )
        );
        setprop(fmgc~ "follow-alt-cstr", follow_cstr);
        setprop(fmgc~ "is-alt-constraint", me.follow_alt_cstr);
        setprop(settings~ 'min-elevator-ctrl', 
                (ias >= 300 and vmode_vs_fps < -1 ? -0.05 : -0.15));
        var flaps = me.flaps;
        var stall_spd = me.stall_spd;
        
        var ver_alert = 0;

        me.top_desc = me.calc_td();
        RouteManager.top_of_descent = me.top_desc;
        me.calc_tc();
        me.decel_point = me.calc_decel_point();
        me.calc_speed_change();
        me.calc_level_off();
        var decel_point = me.decel_point;
        var flplan_active = me.flplan_active;
        
        # NAV1 Auto-tuning
        
        me.autotune_ils();
        me.autotune_navaids();
        
        var athrEngaged = (me.a_thr == 'eng');
        var athrArmed = (me.a_thr == 'armed');

        # SET OFF IF NOT USED

        if (me.lat_ctrl != "fmgc")
            setprop("/flight-management/hold/init", 0);

        # Turn off rudder control when AP is off

        if ((me.ap1 == "off") and (me.ap2 == "off")) {
            setprop("/autoland/rudder", 0);
            setprop("/autoland/active", 0);
            setprop("/autoland/phase", "disengaged")
        }

        if ((me.spd_ctrl == "off") or (me.a_thr != "eng")) {

            setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);

            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);

        }

        if ((me.lat_ctrl == "off") or ((me.ap1 == "off") and (me.ap2 == "off"))) {

            setprop(servo~ "aileron", 0);
            setprop(servo~ "aileron-nav1", 0);
            setprop(servo~ "target-bank", 0);

        }

        if ((me.ver_ctrl == "off") or ((me.ap1 == "off") and (me.ap2 == "off"))) {

            setprop(servo~ "elevator-vs", 0);
            setprop(servo~ "elevator-fpa", 0);
            setprop(servo~ "elevator-gs", 0);
            setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);

        }

        # MANUAL SELECT MODE ===================================================

        ## AUTO-THROTTLE -------------------------------------------------------

        if ((me.spd_ctrl == "man-set") and (athrEngaged)) {

            if (me.spd_mode == "ias") {

                setprop(fmgc~ "a-thr/ias", 1);
                setprop(fmgc~ "a-thr/mach", 0);

                setprop(fmgc~ "fmgc/ias", 0);
                setprop(fmgc~ "fmgc/mach", 0);

            } else {

                setprop(fmgc~ "a-thr/ias", 0);
                setprop(fmgc~ "a-thr/mach", 1);

                setprop(fmgc~ "fmgc/ias", 0);
                setprop(fmgc~ "fmgc/mach", 0);

            }

        }

        var apEngaged = me.ap_engaged and me.airborne;
        var fdEngaged = me.fd_engaged;

        #if(!me.airborne)
        #    apEngaged = 0;
        #me.ap_engaged = apEngaged;
        #me.fd_engaged = fdEngaged;
        var vmode = me.active_ver_mode;
        var lmode = me.active_lat_mode;
        var common_mode = me.active_common_mode;
        var app_phase = (vmode == 'G/S' or 
                         vmode == 'G/S*' or 
                         vmode == 'FINAL' or 
                         common_mode == 'LAND' or 
                         common_mode == 'FLARE' or 
                         common_mode == 'FINAL APP');
        
        if(app_phase and me.phase != 'APP'){
            me.phase = 'APP';
            setprop('flight-management/phase', 'APP');
        }
        var ver_managed = me.ver_managed;
        #print("FMGC Loop: AP Eng -> " ~ apEngaged);
        var vs_fps = me.vs_fps;
        var ver_sub = me.ver_sub;
        var fpa_mode = (ver_sub == 'fpa');
        if (!fdEngaged) {
            setprop(fmfd ~ "aileron", 0);
            setprop(fmfd ~ "aileron-nav1", 0);
            setprop(fmfd ~ "target-bank", 0);
            setprop(fmfd ~ "target-vs", vs_fps);
            setprop(fmfd ~ "target-fpa", me.fpa_angle);
            setprop(fmfd ~ "pitch-vs", 0);
            setprop(fmfd ~ "pitch-fpa", 0);
            setprop(fmfd ~ "pitch-gs", 0);
        }
        var thr_lock = me.thrust_lock;
        var thr_lock_val = me.thrust_lock_value;
        if(me.fixed_thrust and me.airborne){
            var min = 0;
            var max = 0;
            var thr_l = 0;
            var thr_r = 0;
            var retard = getprop("/autoland/retard");
            if(!me.alpha_floor_mode){
                if(me.true_vertical_phase == 'CLB' and !retard){
                    min = 0.2;
                    max = 15;
                    thr_l = getprop('controls/engines/engine[0]/max-athr-thrust');
                    thr_r = getprop('controls/engines/engine[1]/max-athr-thrust');
                } 
                elsif(me.true_vertical_phase == 'DES'){
                    min = -15;
                    max = -0.05;#-0.2;
                    #thr_l = 0;
                    #thr_r = 0;
                };
                if(apEngaged or fdEngaged){
                    if (!retard){
                        setprop(settings~ 'spd-pitch-min', min);
                        setprop(settings~ 'spd-pitch-max', max);
                        setprop(fmgc~ "spd-with-pitch", me.speed_with_pitch);
                    } else {
                        #print("Retard...");
                        setprop(fmgc~ "spd-with-pitch", 0);
                        setprop(settings~ 'spd-pitch-min', 0);
                        setprop(settings~ 'spd-pitch-max', 0);
                    }
                    if(athrEngaged){
                        if(thr_lock){
                            thr_l = thr_lock_val;
                            thr_r = thr_lock_val;
                        }
                        #print("Throttle: " ~ thr_l);
                        me.update_throttle(thr_l, thr_r);
                    } elsif(thr_lock){
                        me.update_throttle(thr_lock_val, thr_lock_val);
                    }
                } else {
                    setprop(fmgc~ "spd-with-pitch", 0);
                    setprop(settings~ 'spd-pitch-min', 0);
                    setprop(settings~ 'spd-pitch-max', 0);
                    if(thr_lock or athrEngaged){
                        me.update_throttle(thr_lock_val, thr_lock_val);
                    }
                }
            } else {
                setprop(settings~ 'spd-pitch-min', 0);
                setprop(settings~ 'spd-pitch-max', 0);
                setprop(fmgc~ "spd-with-pitch", 1);
                athrEngaged = 1;
                setprop(fmgc~ "a-thrust", 'eng');
                me.update_throttle(1, 1);
            }
        } else {
            setprop(fmgc~ "spd-with-pitch", 0);
            setprop(settings~ 'spd-pitch-min', 0);
            setprop(settings~ 'spd-pitch-max', 0);
            if(!me.airborne and thr_lock){
                me.update_throttle(thr_lock_val, thr_lock_val);
            }
        }
        me.speed_with_pitch = getprop(fmgc~ "spd-with-pitch");
        if(!me.speed_with_pitch)
            setprop('/autopilot/settings/target-pitch-deg', 0);
        else {
            setprop(fmfd ~ "target-vs", 0);
            setprop(fmfd ~ "target-fpa", 0);
            setprop(fmfd ~ "pitch-vs", 0);
            setprop(fmfd ~ "pitch-fpa", 0);
            setprop(fmfd ~ "pitch-gs", 0);
        }
        var max_rudder = (me.airborne ? 1 : 0.2);
        setprop(settings~ 'min-rudder', -max_rudder);
        setprop(settings~ 'max-rudder', max_rudder);
        var rm_sequencing = RouteManager.sequencing;
        if (apEngaged or fdEngaged) {

            ## LATERAL CONTROL -----------------------------------------------------
            var hdgtrk_mode = (lmode == "HDG" or lmode == "TRACK");
            if (hdgtrk_mode or me.toga_trk != nil or me.rwy_trk != nil or rm_sequencing) {

                # Find Heading Deflection
                var true_north = me.use_true_north;
                var fixed_track = me.toga_trk != nil ? me.toga_trk : me.rwy_trk;
                var bug = fixed_track != nil ? fixed_track : getprop(fcu~ "hdg");
                #print("HDG: bug -> " ~ bug);
                var heading_type = ((lmode == 'HDG' and fixed_track == nil) ? 'heading' : 'track');
                var bank = -1 * defl(bug, 20, true_north, heading_type);
                #print("HDG: bank -> " ~ bank);

                var deflection = defl(bug, 180, true_north, heading_type);
                #print("HDG: defl -> " ~ deflection);

                if(apEngaged){
                    setprop(servo~  "aileron", 1);
                    setprop(servo~ "aileron-nav1", 0);

                    if (math.abs(deflection) <= 0.25)#TODO: change to 0.25
                        setprop(servo~ "target-bank", 0);
                    else
                        setprop(servo~ "target-bank", bank);
                }
                setprop(fmfd~ "aileron", 1);
                setprop(fmfd~ "aileron-nav1", 0);
                if (math.abs(deflection) <= 0.25)#TODO: change to 0.25
                    setprop(fmfd~ "target-bank", 0);
                else
                    setprop(fmfd~ "target-bank", bank);

            } elsif (me.active_lat_mode == "LOC" or 
                     me.active_lat_mode == "LOC*" or 
                     me.active_lat_mode == "RWY" or 
                     me.active_common_mode == "LAND" or 
                     me.active_common_mode == "FLARE" or 
                     me.active_common_mode == "ROLL OUT"
                    ) {

                var nav1_error = getprop("/autopilot/internal/nav1-track-error-deg");

                var agl = me.agl;

                var bank = limit(nav1_error, 30);

                if (agl < 55) {

                    bank = 0; # Level the wings for AUTOLAND

                    setprop(servo~ "target-rudder", bank);	

                }


                if(apEngaged){
                    setprop(servo~ "aileron", 0);

                    setprop(servo~ "aileron-nav1", 1); 
                    setprop(servo~ "target-bank", bank);
                }
                if(fdEngaged){
                    setprop(fmfd~ "aileron", 0);

                    setprop(fmfd~ "aileron-nav1", me.airborne); 	

                    if(me.airborne)
                        setprop(fmfd~ "target-bank", bank);
                    else {
                        var trgt_rudder = getprop(fmfd~'target-rudder');
                        var fd_bank = (me.ias >= 10 ? trgt_rudder : 0);
                        setprop('/instrumentation/pfd/fd_bank', fd_bank);
                    }
                        
                }

            } # else, this is handed over from fcu to fmgc

            ## VERTICAL CONTROL ----------------------------------------------------

            var vs_setting = me.vs_setting;

            var fpa_setting = me.fpa_setting;

            if(app_phase or (!me.airborne and me.ver_mode == 'ils')){
                # Main stuff are done on the PIDs
                var npa = me.non_precision_app;
                if(!npa)
                    autoland.phase_check();

                var agl = me.agl;
                
                if(npa){
                    var final_vs = me.calc_final_vs();
                    if(final_vs != nil){
                        setprop("/servo-control/target-vs", final_vs);
                    }
                    var dh = me.dh;
                    if(agl < dh){
                        setprop(fmgc~ "ap1-master", 'off');
                        setprop(fmgc~ "ap2-master", 'off');
                        apEngaged = 0;
                    }
                }
                var early_desc = getprop("/autoland/early-descent") - 250;
                if(apEngaged){
                    if (agl > early_desc and !npa) {
                        setprop(servo~ "elevator-gs", 1);
                        setprop(servo~ "elevator-vs", 0);
                        setprop(servo~ "elevator-fpa", 0);
                    } else {
                        setprop(servo~ "elevator-gs", 0);
                        setprop(servo~ "elevator-vs", 1);
                        setprop(servo~ "elevator-fpa", 0);
                    }
                    setprop(servo~ "elevator", 0);
                }
                var update_fd_pitch = (me.airborne and !apEngaged);
                if(fdEngaged){
                    if (agl > early_desc and !npa) {
                        setprop(fmfd ~ "pitch-vs", 0);
                        setprop(fmfd ~ "pitch-fpa", 0);
                        setprop(fmfd ~ "pitch-gs", update_fd_pitch);
                    } else {
                        setprop(fmfd ~ "target-vs", 
                                getprop("/servo-control/target-vs"));
                        setprop(fmfd ~ "pitch-vs", update_fd_pitch);
                        setprop(fmfd ~ "pitch-fpa", 0);
                        setprop(fmfd ~ "pitch-gs", 0);
                    }
                    if(fpa_mode){
                        var fpa = 0;
                        if(npa or me.gs_dev < 0.15){
                            fpa = me.calc_final_fpa() or 0;
                            if(agl > early_desc and !npa) fpa += me.gs_dev;
                        }
                        setprop(fmfd ~ "target-fpa", fpa);
                    }
                }

            } else {
                if(!ver_managed){
                    var vs_ref = 3000; 
                    var fpa_ref = 15;
                    var is_alt_mode = (substr(vmode, 0, 3) == 'ALT');
                    #TODO: FPA standard settings
                    var vsfpa_mode = 0; 
                    if(vmode == 'VS' or vmode == 'FPA' or rm_sequencing){
                        vs_ref = vs_setting; 
                        fpa_ref = fpa_setting;
                        vsfpa_mode = 1; 
                    } else {
                        if(me.true_vertical_phase == 'DES'){
                            vs_ref *= -1;
                            fpa_ref *= -1;
                        }
                    }
                    # V/S mode or ALT mode or OP CLB/DES
                    if (ver_sub == "vs" or is_alt_mode or !vsfpa_mode) {

                        var target = getprop(fcu~ "alt");

                        var trgt_vs = 0;

                        if (((altitude - target) * vs_ref) > 0) {

                            trgt_vs = limit((target - altitude) * 2, 200);

                        } else {

                            trgt_vs = limit2((target - altitude) * 2, vs_ref);

                        }
                        if(vsfpa_mode){
                            if(trgt_vs > 200 and me.ias <= (me.stall_spd + 10)){
                                ver_alert = 1;
                                trgt_vs = 200;
                            }
                            elsif(trgt_vs < -200 and me.vmax and me.ias >= me.vmax){
                                ver_alert = 1;
                                trgt_vs = -200;
                            } 
                        }
                        var vs = trgt_vs / 60;
                        if(apEngaged){
                            setprop(servo~ "target-vs", vs);
                            setprop(servo~ "elevator-vs", 1);
                            setprop(servo~ "elevator-fpa", 0);
                            setprop(servo~ "elevator", 0);
                            setprop(servo~ "elevator-gs", 0);
                        }
                        if(fdEngaged){
                            setprop(fmfd ~ "target-vs", vs);
                            setprop(fmfd ~ "pitch-vs", me.airborne and !apEngaged);
                            setprop(fmfd ~ "pitch-fpa", 0);
                            setprop(fmfd ~ "pitch-gs", 0);
                            var target_fpa = 0;
                            if(fpa_mode){
                                if (((altitude - target) * fpa_ref) > 0) {

                                    target_fpa = limit((target - altitude) / 200, 1);

                                } else {

                                    target_fpa = limit2((target - altitude) / 200, fpa_ref);

                                }
                            }
                            setprop(fmfd ~ "target-fpa", target_fpa);
                        }
                    } else {

                        #var target_alt = getprop(fcu~ "alt");

                        #var trgt_fpa = limit2((target_alt - altitude) * 2, fpa_setting);
                        if(apEngaged){
                            setprop(servo~ "target-fpa", fpa_setting);

                            setprop(servo~ "elevator-vs", 0);
                            setprop(servo~ "elevator-fpa", 1);
                            setprop(servo~ "elevator", 0);

                            setprop(servo~ "elevator-gs", 0);
                        }
                        setprop(fmfd ~ "target-fpa", fpa_setting);
                        setprop(fmfd ~ "target-pitch", fpa_setting);
                        setprop(fmfd ~ "pitch-vs", 0);
                        setprop(fmfd ~ "pitch-fpa", 1);
                        setprop(fmfd ~ "pitch-gs", 0);
                    }
                }
            }

        } # End of AP1 Master Check

        # FMGC CONTROL MODE ====================================================
        var remaining = me.remaining_nm;
        var vmin = me.minimum_selectable_speed;
        var toga_flx_mode = (athrArmed and me.speed_with_pitch);
        if ((me.spd_ctrl == "fmgc") and (athrEngaged or toga_flx_mode or 
                                         !me.airborne)) {
            var cur_wp = me.current_wp;
            #var ias = getprop("/velocities/airspeed-kt");

            ## AUTO-THROTTLE -------------------------------------------------------

            var agl = me.agl;
            var spd = getprop(fmgc_val~ "target-spd");
            if (app_phase and (agl < 3000)) { 
                setprop(fmgc~ "fmgc/ias", 1);
                setprop(fmgc~ "fmgc/mach", 0);

                setprop(fmgc~ "a-thr/ias", 0);
                setprop(fmgc~ "a-thr/mach", 0);
                setprop(fmgc~ "spd-mode", 'ias');
                #autoland.phase_check() called before in case of appr, sets target spd
                #var spd = getprop(fmgc_val~ "target-spd");
                
                #if (spd != nil) {
                #    if (spd > 1) {
                #        setprop("instrumentation/pfd/target-spd", spd);
                #    }
                #} 
            }
            elsif(!me.airborne){
                if(me.v2_spd){
                    spd = me.v2_spd;
                } else {
                    me.spd_ctrl == 'man-set';
                    setprop(fmgc ~ 'spd-ctrl', 'man-set');
                    spd = getprop(fcu ~ 'ias');
                }
            } else {
                var srs = 0;
                var phase = me.phase;
                if(vmode == 'SRS' and me.srs_spd > 0){
                    spd = me.srs_spd;
                    #setprop(fmgc_val~ "target-spd", spd);
                    srs = 1;
                }
                elsif(me.exped_mode){
                    #setprop(fmgc_val~ "target-spd", me.calc_exped_spd());
                    spd = me.calc_exped_spd();
                }
                elsif (!app_phase and flplan_active and !toga_flx_mode) {

                    var wp_spd = nil;
                    if(me.wp != nil and !rm_sequencing)
                        wp_spd = me.wp.speed_cstr;

                    if (wp_spd == nil or wp_spd <= 0) {
                        var is_descending = vmode_vs_fps <= -8 or ((me.fcu_alt - altitude) < -200); #((phase == 'DES' and (me.fcu_alt - altitude) < -200);
                        if(remaining < decel_point or phase == 'APP'){
                            spd = autoland.spd_manage(getprop("/fdm/jsbsim/inertia/weight-lbs"));
                            if(phase != 'G/A' and phase != 'APP'){
                                setprop('flight-management/phase', 'APP');
                                me.phase = 'APP';
                            }
                        } else {
                            if (altitude <= (is_descending ? 10500 : 10000)){
                                spd = 250;
                            }
                            else{
                                if(is_descending){ #TODO: this fails with new fixed-thrust DES, use true ver mode instead
                                    if(altitude < me.mach_trans_alt)
                                        spd = 280;
                                    else
                                        spd = 0.68;
                                    #spd = 280;
                                } else{
                                    if(altitude < me.mach_trans_alt)
                                        spd = me.spd_profile[phase][0];
                                    elsif(altitude < 36000)
                                        spd = me.spd_profile[phase][1];
                                    else
                                        spd = 0.86;
                                }
                            }
                        }

                    } else {
                        spd = wp_spd;
                    }
                    if(ias >= (me.vne - 20))
                        spd = me.vne - 20;
                    #setprop(fmgc_val~ "target-spd", spd);

                }

                # Performance and Automatic Calculated speeds from the PERF page on the mCDU are managed separately
                #if(!srs and !me.exped_mode)
                #    manage_speeds(me.descent_started, (remaining < decel_point), vmin, me.vmax);

            }

            setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);

            #var spd = getprop(fmgc_val~ "target-spd");
            #if(!pfd_spd) pfd_spd = spd;
            var pfd_spd = spd;
            if(!me.exped_mode){
                var vmax = me.vmax;
                if(vmax and spd > 1 and vmax > 1 and spd > vmax)
                    spd = vmax;
                elsif(vmax and spd <=1 and vmax <= 1 and spd > vmax)
                spd = vmax;
            }
            if(spd > 1 and spd < vmin)
                spd = vmin;
            if (me.spd_ctrl == 'fmgc') {
                setprop(fmgc_val~ "target-spd", spd);

                if (spd < 1) {
                    #TODO: change SPEED/MACH indication on PFD
                    setprop(fmgc~ "fmgc/ias", 0);
                    setprop(fmgc~ "fmgc/mach", 1);
                    setprop(fmgc~ "spd-mode", 'mach');
                } else {
                    setprop(fmgc~ "fmgc/ias", 1);
                    setprop(fmgc~ "fmgc/mach", 0);
                    setprop("instrumentation/pfd/target-spd", pfd_spd);
                    setprop(fmgc~ "spd-mode", 'ias');
                }
            }
        } else {
            var fcu_ias = getprop(fcu ~ 'ias');
            if(me.exped_mode){
                var exped_spd = me.calc_exped_spd();
                setprop(fcu~ "ias", exped_spd);
                if (exped_spd < 1) {
                    setprop(fmgc~ "spd-mode", 'mach');
                } else {
                    setprop(fmgc~ "spd-mode", 'ias');
                }
                fcu_ias = exped_spd;
            } else {
                if(fcu_ias < vmin){
                    setprop(fcu~ "ias", vmin);
                    fcu_ias = vmin;
                }
            }
            setprop("instrumentation/pfd/target-spd", fcu_ias);
        }

        var lmode = me.active_lat_mode;
        if (apEngaged or fdEngaged) {

            ## LATERAL CONTROL -----------------------------------------------------
            
            var nav_mode = (lmode == 'NAV' or 
                            lmode == 'APP NAV' or 
                            common_mode == 'FINAL APP');

            if (nav_mode and !rm_sequencing) {

                # If A procedure's NOT being flown, we'll fly the active F-PLN (unless it's a hold pattern)
                var remaining = me.remaining_nm;

                if (1) { #getprop("/flight-management/procedures/active") == "off") {

                    if (((getprop("/flight-management/hold/wp_id") == getprop("/flight-management/current-wp")) or (getprop("/flight-management/hold/init") == 1)) and (getprop("/flight-management/hold/wp_id") != 0)) {

                        if (getprop("/flight-management/hold/init") != 1) {

                            hold_pattern.init();

                        } else {

                            var true_north = me.use_true_north;
                            if (getprop("/flight-management/hold/phase") == 5) {

                                hold_pattern.entry();

                            } else {

                                hold_pattern.transit();

                            }	

                            # Now, fly the actual hold

                            var bug = getprop("/flight-management/hold/fly/course");

                            var bank = -1 * defl(bug, 30, true_north);

                            var deflection = defl(bug, 180, true_north);

                            if(apEngaged){
                                setprop(servo~  "aileron", 1);
                                setprop(servo~ "aileron-nav1", 0);

                                if (math.abs(deflection) <= 1)
                                    setprop(servo~ "target-bank", 0);
                                else
                                    setprop(servo~ "target-bank", bank);
                            }
                            setprop(fmfd~ "aileron", 1);
                            setprop(fmfd~ "aileron-nav1", 0);

                            if (math.abs(deflection) <= 1)
                                setprop(fmfd~ "target-bank", 0);
                            else
                                setprop(fmfd~ "target-bank", bank);

                        }

                    } else {

                        setprop("/flight-management/hold/init", 0);

                        #var bug = getprop("/autopilot/internal/true-heading-error-deg");
                        var f = me.flightplan;
                        var geocoord = me.aircraft_pos;
                        var dest_wp_info = RouteManager.getDestinationWP();#me.destination_wp;
                        if(dest_wp_info == nil){
                            dest_wp_info = {
                                index: me.wp_count - 1
                            };
                        }
                        var cur_wp = me.current_wp;
                        var remain = me.remaining_nm;
                        var referenceCourse = f.pathGeod(dest_wp_info.index, -remain);
                        var wp = me.wp;
                        if(wp == nil){
                            wp = {
                                fly_type: ''
                            };
                        }
                        setprop('autopilot/route-manager/debug/point[0]/id', 'REF');
                        setprop('autopilot/route-manager/debug/point[0]/lat', referenceCourse.lat);
                        setprop('autopilot/route-manager/debug/point[0]/lon', referenceCourse.lon);
                        var courseCoord = geo.Coord.new().set_latlon(referenceCourse.lat, referenceCourse.lon);
                        var CourseError = (geocoord.distance_to(courseCoord) / 1852) + 1;
                        var change_wp = abs(getprop("autopilot/route-manager/wp/bearing-deg") - 
                                            getprop('orientation/heading-deg'));
                        if(change_wp > 180) change_wp = (360 - change_wp);
                        CourseError += (change_wp / 20);
                        var CourseErrorOffset = (-remain + CourseError);
                        if(wp.fly_type == 'flyOver'){
                            var wp_offset = -(me.total_fp_distance - wp.distance_along_route);
                            if(CourseErrorOffset > wp_offset)
                                CourseErrorOffset = wp_offset;
                        }
                        var targetCourse = f.pathGeod(dest_wp_info.index, CourseErrorOffset);
                        #setprop('autopilot/route-manager/debug/point[1]/id', 'TRGT');
                        #setprop('autopilot/route-manager/debug/point[1]/lat', targetCourse.lat);
                        #setprop('autopilot/route-manager/debug/point[1]/lon', targetCourse.lon);
                        courseCoord = geo.Coord.new().set_latlon(targetCourse.lat, targetCourse.lon);
                        
                        if(0 and cur_wp < me.last_wp_idx){ #DISABLED
                            var err = CourseError - (change_wp / 20);
                            var offs = (-remain + err);
                            change_wp = abs(
                                getprop("autopilot/route-manager/route/wp["~(cur_wp + 1)~"]/leg-bearing-true-deg") -
                                getprop("autopilot/route-manager/route/wp["~ cur_wp ~"]/leg-bearing-true-deg")
                                );
                            if(change_wp > 180) change_wp = (360 - change_wp);
                            var nextWpTargetCourse = f.pathGeod(dest_wp_info.index, (offs + (change_wp / 20)));
                            #setprop('autopilot/route-manager/debug/point[2]/id', 'NEXT');
                            #setprop('autopilot/route-manager/debug/point[2]/lat', nextWpTargetCourse.lat);
                            #setprop('autopilot/route-manager/debug/point[2]/lon', nextWpTargetCourse.lon);
                        }
                        
                        CourseError = (geocoord.course_to(courseCoord) - me.hdg_trk);
                        if(CourseError < -180) CourseError += 360;
                        elsif(CourseError > 180) CourseError -= 360;

                        var accuracy = getprop(settings~ "gps-accur");

                        var bank = 0; 

                        if (1 or accuracy == "HIGH")
                            bank = limit(CourseError, 25);
                        else
                            bank = limit(CourseError, 15);

                        if(apEngaged){
                            setprop(servo~  "aileron", 1);

                            setprop(servo~ "aileron-nav1", 0);

                            setprop(servo~ "target-bank", bank);
                        }
                        setprop(fmfd~ "aileron", 1);

                        setprop(fmfd~ "aileron-nav1", 0);

                        setprop(fmfd~ "target-bank", bank);
                        #setprop('autopilot/route-manager/debug/active', 1);
                        #setprop('autopilot/route-manager/debug/num', 3);
                        #setprop('autopilot/route-manager/debug/update_t', systime());
                    }

                    # Else, fly the respective procedures

                } else {

                    if (getprop("/flight-management/procedures/active") == "sid") {

                        procedure.fly_sid();

                        var bug = getprop("/flight-management/procedures/sid/course");

                        var bank = -1 * defl(bug, 25, me.use_true_north);					

                        if(apEngaged){
                            setprop(servo~  "aileron", 1);

                            setprop(servo~ "aileron-nav1", 0);

                            setprop(servo~ "target-bank", bank);
                        }
                        setprop(fmfd~ "aileron", 1);

                        setprop(fmfd~ "aileron-nav1", 0);

                        setprop(fmfd~ "target-bank", bank);

                    } elsif (getprop("/flight-management/procedures/active") == "star") {

                        procedure.fly_star();

                        var bug = getprop("/flight-management/procedures/star/course");

                        var bank = -1 * defl(bug, 25, me.use_true_north);	
                        if(apEngaged){

                            setprop(servo~  "aileron", 1);

                            setprop(servo~ "aileron-nav1", 0);

                            setprop(servo~ "target-bank", bank);
                        }
                        setprop(fmfd~ "aileron", 1);

                        setprop(fmfd~ "aileron-nav1", 0);

                        setprop(fmfd~ "target-bank", bank);

                    } else {

                        procedure.fly_iap();

                        var bug = getprop("/flight-management/procedures/iap/course");

                        var bank = -1 * defl(bug, 28, me.use_true_north);		

                        if(apEngaged){

                            setprop(servo~  "aileron", 1);

                            setprop(servo~ "aileron-nav1", 0);

                            setprop(servo~ "target-bank", bank);
                        }
                        setprop(fmfd~ "aileron", 1);

                        setprop(fmfd~ "aileron-nav1", 0);

                        setprop(fmfd~ "target-bank", bank);
                    }

                }

            }

            ## VERTICAL CONTROL ----------------------------------------------------

            if (ver_managed and !me.non_precision_app and !rm_sequencing) {
                var target_alt = me.real_target_alt;
                var alt_diff = me.real_target_alt - altitude;

                var final_vs = 0;
                var abs_diff = math.abs(alt_diff);

                var max_vs = 0; #TODO: is it right?
                var max_fpa = 0;
                if(target_alt > altitude){
                    max_vs = 2400;
                    max_fpa = 15;
                }
                elsif(target_alt < altitude){
                    max_vs = -2400;
                    max_fpa = -15;
                }
                if (((altitude - target_alt) * max_vs) > 0) {
                    final_vs = limit((target_alt - altitude) * 2, 200);
                } else {
                    final_vs = limit2((target_alt - altitude) * 2, max_vs);
                } 
                final_vs = final_vs / 60.0;
                
                setprop(fmgc_val ~ 'vnav-final-vs', final_vs);
                if(apEngaged){
                    setprop(servo~ "target-vs", final_vs);
                    setprop(servo~ "elevator-vs", 1);
                    setprop(servo~ "elevator-fpa", 0);
                    setprop(servo~ "elevator", 0);
                    setprop(servo~ "elevator-gs", 0);
                }
                if(fdEngaged){
                    setprop(fmfd ~ "target-vs", final_vs);
                    setprop(fmfd ~ "pitch-vs", me.airborne and !apEngaged);
                    setprop(fmfd ~ "pitch-fpa", 0);
                    setprop(fmfd ~ "pitch-gs", 0);
                    var target_fpa = 0;
                    if(fpa_mode){
                        if (((altitude - target_alt) * max_fpa) > 0) {

                            target_fpa = limit((target_alt - altitude) / 200, 1);

                        } else {

                            target_fpa = limit2((target_alt - altitude) / 200, max_fpa);

                        }
                    }
                    setprop(fmfd ~ "target-fpa", target_fpa);
                }
            }

        } # End of AP1 MASTER CHECK
        var fd_pitch = 0;
        if(me.speed_with_pitch){
            if(fpa_mode and apEngaged){
                fd_pitch = me.fpa_angle; 
                setprop(fmfd~ 'target-fpa', fd_pitch);
            } else {
                fd_pitch = getprop('/autopilot/settings/target-pitch-deg'); 
                setprop(fmfd~ 'target-pitch', getprop('/orientation/pitch-deg'));
            }
        }
        else{
            if(!apEngaged or vmode == 'FPA')
                fd_pitch = getprop(fmfd~ 'target-pitch');
            else {
                if(fpa_mode){
                    fd_pitch = getprop('/flight-management/fd/target-fpa');
                } else {
                    fd_pitch = getprop('/orientation/pitch-deg');
                }
                setprop(fmfd~ 'target-pitch', fd_pitch);
            }     
        }  
        if(fd_pitch == nil or !me.airborne) fd_pitch = 0;
        setprop('instrumentation/pfd/fd_pitch', fd_pitch);
        setprop('instrumentation/pfd/ver-alert-box', ver_alert and me.airborne);
        var dh = (me.dh or 200) - 50; 
        var app_phase = (me.phase == 'APP');
        var app_cat = me.app_cat;
        var agl = me.agl;
        var disengage_ap =  me.airborne and 
                            !me.toga_trk and 
                            app_phase and 
                            apEngaged and 
                            app_cat < 3 and 
                            agl < dh and 
                            agl > 30; #TODO: avoid AP disengagement on GoAround: TOGA dinegages ATHR > CAT 2 > AP disengage
                                      #TODO: check also autoland?

        if (disengage_ap){
            setprop(fmgc~ "ap1-master", "off");
            setprop(fmgc~ "ap2-master", "off");
        }
    },
    get_settings : func {

        var last_athr = me.a_thr;
        var last_dest_arpt = me.dest_airport;
        var last_dest_rwy = me.dest_rwy;
        var last_throttle = me.max_throttle;
        me.aircraft_pos = geo.aircraft_position();
        me.spd_mode = getprop(fmgc~ "spd-mode");
        me.spd_ctrl = getprop(fmgc~ "spd-ctrl");

        me.lat_mode = getprop(fmgc~ "lat-mode");
        me.lat_ctrl = getprop(fmgc~ "lat-ctrl");

        me.ver_mode = getprop(fmgc~ "ver-mode");
        me.ver_ctrl = getprop(fmgc~ "ver-ctrl");

        me.ver_sub = getprop(fmgc~ "ver-sub");

        me.ap1 = getprop(fmgc~ "ap1-master");
        me.ap2 = getprop(fmgc~ "ap2-master");
        me.a_thr = getprop(fmgc~ "a-thrust");
        me.throttle = getprop('/controls/engines/engine[0]/throttle');
        me.throttle_r = getprop('/controls/engines/engine[1]/throttle');
        me.max_throttle = (me.throttle_r > me.throttle ? me.throttle_r : me.throttle);
        
        me.vs_setting = getprop(fcu~ "vs");

        me.fpa_setting = getprop(fcu~ "fpa");
        me.crz_fl = getprop("/flight-management/crz_fl");
        if(!me.crz_fl)
            me.crz_fl = int(getprop("autopilot/route-manager/cruise/altitude-ft") / 100);
        me.fcu_alt = getprop(fcu~'alt');
        if(me.airborne and me.fcu_alt > (me.crz_fl * 100)){
            me.crz_fl = int(me.fcu_alt / 100);
            setprop("/flight-management/crz_fl", me.crz_fl);
            setprop("autopilot/route-manager/cruise/altitude-ft", me.fcu_alt);
        }
        me.v2_spd = getprop('/instrumentation/fmc/vspeeds/V2');
        me.vsfpa_mode = getprop(fmgc~'vsfpa-mode');
        me.flaps = getprop("/controls/flight/flaps");
        me.acc_alt = getprop(settings~ 'acc-alt');
        me.thr_red = getprop(settings~ 'thr-red');
        #me.trans_alt = getprop('/instrumentation/fmc/trans-alt');
        me.mach_trans_alt = getprop('/instrumentation/fmc/mach-trans-alt');
        me.flex_to_temp = getprop('/instrumentation/fmc/flex-to-temp');
        me.exped_mode = getprop(fmgc~ 'exped-mode');
        me.ils_frq = getprop(radio~ "ils");
        me.dest_airport = getprop("/autopilot/route-manager/destination/airport");
        me.dest_rwy = getprop("/autopilot/route-manager/destination/runway");
        me.dep_airport = getprop("/autopilot/route-manager/departure/airport");
        me.dep_rwy = getprop("/autopilot/route-manager/departure/runway");
        me.dh = getprop('/instrumentation/mk-viii/inputs/arinc429/decision-height') or 200;
        me.use_true_north = (abs(getprop("position/latitude-deg")) > 82.0);
        setprop('instrumentation/efis/mfd/true-north', me.use_true_north);
        setprop('instrumentation/efis[1]/mfd/true-north', me.use_true_north);
        
        if (me.a_thr == 'eng') {
            me.last_thrust = me.max_throttle;
            if (me.thrust_lock and me.thrust_lock_reason == 'THR'){
                setprop('flight-management/thrust-lock', 0);
                setprop('flight-management/thrust-lock-reason', '');
            }
        } else {
            var was_engaged = (last_athr == 'eng');
            var idle = (me.max_throttle == 0);
            if (was_engaged and !me.thrust_lock and me.a_thr != 'armed' and !idle){
                me.thrust_lock_value = me.last_thrust;
                setprop('flight-management/thrust-lock', 1);
                setprop('flight-management/thrust-lock-reason', 'THR');
            }
            elsif(was_engaged and me.thrust_lock){
                if(me.thrust_lock_reason == 'TOGA'){
                    setprop('flight-management/thrust-lock', 0);
                    setprop('flight-management/thrust-lock-reason', '');
                    me.thrust_lock = 0;
                    me.thrust_lock_reason = '';
                }
            }
        }
        var dest_changed = 0;
        if(last_dest_arpt != me.dest_airport){
            var apt = airportinfo(me.dest_airport);
            me.destination = apt;
            dest_changed = 1;
        }
        if(dest_changed or last_dest_rwy != me.dest_rwy){
            if(me.destination != nil){
                var rwy = me.destination.runways[me.dest_rwy];
                me.approach_runway = rwy;
                if(rwy != nil)
                    me.approach_ils = rwy.ils;
                else
                    me.approach_ils = nil;
            } else {
                me.approach_runway = nil;
                me.approach_ils = nil;
            }
            me.destination_wp_info = nil;
        }
        if(last_throttle < 1 and me.max_throttle == 1){
            me.toga_on_ground = !me.airborne;
        }
        elsif(me.max_throttle < 1)
            me.toga_on_ground = 0;
        me.landing_flaps = getprop(settings~ 'ldg-conf-flaps') or 4;
        me.appr_vls = me.minimum_speeds[me.landing_flaps] + 15;
        setprop(fmgc_val ~ 'appr-vls', me.appr_vls);
    },
    calc_stall_speed: func(){
        var flaps = me.flaps;
        var stall_spd = 0;
        var retract_flaps_spd = 0;
        if(flaps <= 0.29){
            stall_spd = me.minimum_speeds[0];
        }
        elsif(flaps == 0.596){
            retract_flaps_spd = 155;
            stall_spd = me.minimum_speeds[2];
        }
        elsif(flaps >= 0.74 and flaps <= 0.75){
            retract_flaps_spd = 140;
            stall_spd = me.minimum_speeds[3];   
        }
        elsif(flaps > 0.75){
            retract_flaps_spd = 135;
            stall_spd = me.minimum_speeds[4];   
        }
        setprop(fmgc_val ~ 'stall-speed', stall_spd);
        setprop(fmgc_val ~ 'ind-stall-speed', stall_spd - 125);
        setprop('instrumentation/pfd/min-flaps-retract-speed', 
                retract_flaps_spd);
        me.stall_spd = stall_spd;
    },
    calc_required_fpa: func(alt, target_alt, distance){
        var d = target_alt - alt;
        return RAD2DEG * math.atan2((d * FT2NM), distance);
    },
    get_current_state : func(){
        me.flplan_active = getprop("/autopilot/route-manager/active");
        me.flightplan = flightplan();
        me.agl = getprop("/position/altitude-agl-ft");
        me.groundspeed = getprop("/velocities/groundspeed-kt");
        me.current_wp = getprop("autopilot/route-manager/current-wp");
        me.wp_count = getprop(actrte~"num");
        me.remaining_nm = RouteManager.getRemainingNM();#getprop("autopilot/route-manager/distance-remaining-nm");
        #me.remaining_total_nm = me.remaining_nm;
        me.total_fp_distance = RouteManager.total_distance_nm;
        me.fp_distance = RouteManager.distance_nm;
        me.last_wp_idx = me.wp_count - 1;
        me.missed_approach_planned = RouteManager.missed_approach_planned;
        me.missed_approach = RouteManager.missed_approach_active;
        #me.destination_wp = RouteManager.getDestinationWP();
        
        me.airborne = !getprop("/gear/gear[0]/wow") and 
                      !getprop("/gear/gear[1]/wow") and 
                      !getprop("/gear/gear[2]/wow");
        me.nav_in_range = getprop('instrumentation/nav/in-range');
        me.gs_in_range = getprop('instrumentation/nav/gs-in-range');
        me.autoland_phase = getprop('/autoland/phase');
        me.vs_fpm = int(0.6 * me.vs_fps) * 100;
        me.ap_engaged = ((me.ap1 == "eng") or (me.ap2 == "eng"));
        me.fd_engaged = getprop("flight-management/control/fd");
        me.vmax = me.calc_vmax();
        me.gs_dev = getprop('instrumentation/nav/gs-needle-deflection-norm');
        me.loc_dev = getprop('instrumentation/nav/heading-needle-deflection-norm');
        me.phase = me.flight_phase();
        if(me.phase == 'G/A'){
            me.acc_alt = getprop(settings~ 'ga-acc-alt');
            me.thr_red = getprop(settings~ 'ga-thr-red');
        }
        
        me.throttle_pos = getprop('/controls/engines/engine[0]/throttle-pos');
        me.throttle_r_pos = getprop('/controls/engines/engine[1]/throttle-pos');
        me.max_throttle_pos = (me.throttle_r_pos > me.throttle_pos ? me.throttle_r_pos : me.throttle_pos);
        me.fpa_angle = (getprop('velocities/glideslope') * 180) / math.pi;
        me.eng1_running = getprop('engines/engine/running');
        me.eng2_running = getprop('engines/engine[1]/running');
        me.engines_running = (me.eng1_running and me.eng2_running);
        me.calc_stall_speed();
        me.is_stalling = (me.ias < me.stall_spd and 
                          me.airborne and 
                          !(me.phase == 'APP' and me.agl < 50));
        me.thrust_lock = getprop('flight-management/thrust-lock');
        me.thrust_lock_reason = getprop('flight-management/thrust-lock-reason');
        me.green_dot_spd = me.stall_spd + 15;
        me.minimum_selectable_speed = me.green_dot_spd;
        setprop('instrumentation/fmc/vls', me.minimum_selectable_speed);
        setprop(fmgc_val ~ 'fpa-angle', me.fpa_angle);
        setprop('instrumentation/pfd/green-dot-speed', me.green_dot_spd);
        if(me.flplan_active and me.wp_count > 0 and !RouteManager.sequencing){
            me.wp = me.flightplan.getWP();
        } else {
            me.wp = nil;
        }
        if(me.current_wp != nil and me.current_wp)
            me.from_wp = me.current_wp - 1;
        else 
            me.from_wp = -1;
        if(me.from_wp >= 0 and me.from_wp < me.wp_count){
            var from_id = getprop(actrte~'wp[' ~ me.from_wp ~ ']/id');
            me.flying_discontinuity = RouteManager.hasDiscontinuity(from_id);
            if(me.flying_discontinuity){
                if(me.lat_ctrl == 'fmgc'){
                    setprop(fmgc~ 'capture-leg', 1);
                }
            }
        } else {
            me.flying_discontinuity = 0;
        }
        if(!me.use_true_north){
            me.heading = getprop("orientation/heading-magnetic-deg");
            me.track = getprop("orientation/track-magnetic-deg");
        } else {
            me.heading = getprop("orientation/heading-deg");
            me.track = getprop("orientation/track-deg");
        }
        me.hdg_trk = (me.ver_sub == 'vs' ? me.heading : me.track);
        me.xtrk_error = getprop('instrumentation/gps/wp/wp[1]/course-error-nm') or 0;
        me.capturing_leg = getprop(fmgc~ 'capture-leg');
        if(me.capturing_leg){
            if(math.abs(me.xtrk_error) <= 1 and !me.flying_discontinuity){
                me.capturing_leg = 0;
                setprop(fmgc~ 'capture-leg', 0);
            }
        }
    },
    check_flight_modes : func{
        var flplan_active = me.flplan_active;
        var final_app_actv = 0;
        var current_wp = me.current_wp;
        me.active_athr_mode = '';
        me.armed_athr_mode = '';
        me.active_lat_mode = '';
        me.armed_lat_mode = '';
        me.active_ver_mode = '';
        me.armed_ver_mode = '';
        me.armed_ver_secondary_mode = '';
        me.display_ver_secondary_mode = 0;
        me.active_common_mode = '';
        me.armed_common_mode = '';
        me.athr_msg = '';
        me.athr_alert = '';
        #me.accel_alt = 1500;
        me.srs_spd = 0;
        if(me.alpha_floor_mode){
            me.alpha_floor_mode = (me.ias < me.stall_spd + 20);
            if(!me.alpha_floor_mode){
                me.thrust_lock = 1;
                me.thrust_lock_value = 1;
                me.thrust_lock_reason = 'TOGA';
                setprop('flight-management/thrust-lock', 1);
                setprop('flight-management/thrust-lock-reason', 'TOGA');
            }
        }
        var after_td = 0;
        if(me.v2_spd > 0)
            me.srs_spd = me.v2_spd + 10; 
        var throttle = me.max_throttle_pos;
        var toga = (throttle == 1);
        var flex_mct = (throttle >= thrust_levers.detents.FLEX and throttle < 1);
        
        # Basic Lateral Mode
        var lmode = '';
        var loc_mode = (me.lat_mode == "nav1");
        var lat_sel_mode = (me.ver_sub == 'fpa' ? 'TRACK' : 'HDG');
        if (me.lat_ctrl == "man-set") {
            if (me.lat_mode == "hdg") {
                lmode = lat_sel_mode;
            } 
            elsif(loc_mode){
                lmode = 'LOC';
            }
        }
        elsif(me.lat_ctrl == "fmgc"){
            lmode = 'NAV';
        }
        
        #Basic Vertical Mode
        var vmode = '';
        var vmode_sfx = '';
        var fcu_alt = me.fcu_alt;
        var vs_fpm = me.vs_fpm;
        var phase = me.phase;
        
        var ver_fmgc = me.ver_ctrl == 'fmgc';
        var try_vnav = (flplan_active and ver_fmgc and (me.lat_ctrl == 'fmgc' or 
                                                        me.lat_mode == 'nav1'));
        
        var trgt_alt = fcu_alt;
        var follow_alt_cstr = 0;
        var alt_cstr = -9999;
        var remaining = me.remaining_nm;
        if(flplan_active){ 
            if(remaining <= me.top_desc){
                after_td = 1;
            }
            #me.phase = phase;
        }
        
        if(try_vnav){
            follow_alt_cstr = 1;

            alt_cstr = getprop("/autopilot/route-manager/route/wp[" ~ current_wp ~ "]/altitude-ft");
            
            #setprop(fmgc_val ~ 'vnav-phase', phase); #TODO: seems to be unused

            if (alt_cstr == nil or alt_cstr <= 0){
                setprop(fmgc_val ~ 'vnav-target-alt', fcu_alt);
                follow_alt_cstr = 0;
            } else {
                if((phase == 'CLB' and fcu_alt < alt_cstr) or 
                   (phase == 'G/A' and fcu_alt < alt_cstr) or 
                   (phase == 'DES' and fcu_alt > alt_cstr) or 
                   (phase == 'APP' and fcu_alt > alt_cstr)){
                    setprop(fmgc_val ~ 'vnav-target-alt', fcu_alt);
                    follow_alt_cstr = 0;
                } else {
                    setprop(fmgc_val ~ 'vnav-target-alt', alt_cstr);
                }
            }
            if(follow_alt_cstr)
                trgt_alt = alt_cstr;
        }
        var altitude = me.altitude;
        var raw_alt_diff = trgt_alt - altitude;
        var alt_diff = math.abs(raw_alt_diff);
        
        var vphase = '';
        var vmode_main = '';
        var crz_alt = me.crz_fl * 100; # TODO: maybe it's better to use route-manager crz alt
        me.true_vertical_phase = '';
        if(raw_alt_diff > 0)
            me.true_vertical_phase = 'CLB';
        elsif(raw_alt_diff < 0)
            me.true_vertical_phase = 'DES';
        if(phase == 'CLB' or phase == 'DES')
            vphase = phase;
        elsif(phase == 'T/O')
            vphase = 'CLB';
        elsif(phase == 'G/A')
            vphase = 'CLB';
        elsif(phase == 'APP')
            vphase = 'DES';
        
        var is_capturing_alt = 0;
        if(alt_diff <= 100){
            vmode_main = 'ALT';
            me.capture_alt_at = 0;
        } else {
            if(crz_alt and phase == 'CRZ'){
                if((crz_alt - trgt_alt) > 10)
                    vmode_main = 'DES';
                elsif((trgt_alt - crz_alt) > 10)
                    vmode_main = 'CLB';
                else{
                    vmode_main = 'ALT';
                    is_capturing_alt = 1;
                }      
            }
            else{
                if(trgt_alt != me.capture_alt_target){
                    me.capture_alt_target = trgt_alt;
                    me.capture_alt_at = 0;
                }
                var capture_alt_at = me.capture_alt_at;
                if(capture_alt_at == 0)
                    capture_alt_at = (vs_fpm != 0 ? trgt_alt - (vs_fpm / 2) : trgt_alt);
                var capture_alt_rng = math.abs(trgt_alt - capture_alt_at);
                if(alt_diff < capture_alt_rng){
                    vmode_main = 'ALT';
                    me.capture_alt_at = capture_alt_at;
                    is_capturing_alt = 1;
                } else {
                    if(me.toga_trk or me.missed_approach)
                        vmode_main = me.true_vertical_phase;
                    else
                        vmode_main = vphase; #TODO: why? shouldn't be always true vertical phase??
                }
            }  
        }
        if (is_capturing_alt and crz_alt == trgt_alt and phase != 'CRZ'){
            setprop('flight-management/phase', 'CRZ');
            me.ref_crz_alt = crz_alt;
        }
        if(vmode_main == 'ALT'){
            vmode_main = me.get_alt_mode(trgt_alt, alt_cstr, crz_alt, is_capturing_alt);
            setprop(fmgc~ 'exped-mode', 0);
            me.exped_mode = 0;
        }
        var appr_pressed = (me.ver_mode == 'ils');
        if(me.ver_ctrl == "man-set" or !flplan_active or appr_pressed){
            if(me.ver_mode == 'alt'){
                #vmode = vmode_main;
                vmode = me.get_selected_vmode(vmode_main, 
                                              vphase, 
                                              raw_alt_diff);
                    
            }
            elsif(appr_pressed){
                if(me.ils_frq and getprop(radio~ 'ils-mode')){
                    vmode = 'G/S';
                } elsif(flplan_active and me.dest_rwy != '') { #TODO: check for non-ILS destination? maybe not
                    vmode = 'FINAL';
                    lmode = 'APP NAV';
                    #final_app_actv
                }
            }
        }
        elsif(ver_fmgc){
            vmode = vmode_main;
        }
        
        if(!me.airborne){
            me.active_lat_mode = '';
            me.armed_lat_mode = lmode;
            if(me.rwy_mode)
                me.active_lat_mode = 'RWY';
            if(me.autoland_phase == 'rollout')
                me.active_common_mode = 'ROLL OUT'; #TODO: should this be active also without autoland?
               
            if(me.srs_spd > 0 and (toga or flex_mct))
                me.active_ver_mode = 'SRS';
            #TODO: GO AROUND SHOULD ENGAGE ON THE GROUND TOO IF TIME ON GROUND IS < 30sec
            var touchdown_t = 0;
            if(phase == 'LANDED')
                touchdown_t = getprop('autopilot/route-manager/destination/touchdown-time') or 0;
            var touchdown_elapsed_s = me.time - touchdown_t;
            if(toga and me.flaps > 0 and 
               ((touchdown_elapsed_s < 30) or me.toga_trk != nil)){
                me.engage_go_around(lat_sel_mode);
            } else {
                if(me.toga_trk != nil)
                    me.set_current_vsfpa();
                me.toga_trk = nil;
            }
            me.armed_ver_mode = vmode;
        } else {
            
            #LATERAL
            var no_terrain_loaded = (me.agl == 0 and phase != 'T/O'); # FIX AGL 0 WHEN TERRAIN IS NOT LOADED
            if(me.agl > 30 or no_terrain_loaded){
                if(lmode == 'LOC'){ #TODO: LOC * (capture) 
                    if(me.nav_in_range){
                        me.active_lat_mode = lmode;
                        me.armed_lat_mode = ''; #TODO: it seems there's not VOR LOC support
                        if(math.abs(me.loc_dev) > 0.09) 
                            me.active_lat_mode = 'LOC*';
                    } else {
                        me.active_lat_mode = lat_sel_mode;
                        me.armed_lat_mode = lmode;
                    }
                }
                elsif(lmode == 'NAV'){
                    var on_rwy = (me.current_wp <= 1 and 
                                  me.remaining_nm > me.fp_distance and 
                                  me.flplan_active);
                    if(on_rwy){
                        var dp_rwy = me.flightplan.departure_runway;
                        if(dp_rwy != nil){
                            on_rwy = 1;
                            if(me.rwy_trk == nil)
                                me.rwy_trk = me.track;
                        } else {
                            on_rwy = 0;
                        }
                    }
                    if(flplan_active and !me.capturing_leg and !on_rwy){ #TODO: support gps leg course error
                        me.active_lat_mode = lmode;
                        me.armed_lat_mode = (loc_mode ? 'LOC' : '');
                    } else {
                        me.active_lat_mode = (!on_rwy ? lat_sel_mode : 'RWY TRK');
                        me.armed_lat_mode = lmode;
                    }
                } else {
                    me.active_lat_mode = lmode;
                    me.armed_lat_mode = '';
                    me.rwy_trk = nil;
                }
                if(loc_mode){ #TODO: check for NPA?
                    if(me.active_lat_mode != 'LOC' and 
                       me.active_lat_mode != 'LOC*' and 
                       me.nav_in_range){
                        me.active_lat_mode = 'LOC';
                        me.armed_lat_mode = '';
                        setprop(fmgc~ 'lat-ctrl', 'man-set');
                        me.lat_ctrl = 'man-set';
                    }
                }
            } else {
                me.active_lat_mode = (me.rwy_mode? 'RWY' : '');  #TODO: support RWY TRK
                me.armed_lat_mode = lmode;
            }
            if(toga and me.flaps > 0 and me.agl < me.acc_alt and 
               (!me.toga_on_ground or me.toga_trk != nil)){
                me.engage_go_around(lat_sel_mode);
            } else {
                if(me.toga_trk != nil)
                    me.set_current_vsfpa();
                me.toga_trk = nil;
            }
            
            #VERTICAL
            
            if((me.agl < me.acc_alt and me.agl > 0 and 
                me.srs_spd > 0 and me.phase == 'T/O' and !appr_pressed) or 
               me.toga_trk != nil){
                me.active_ver_mode = 'SRS';
                me.armed_ver_mode = vmode;
                if(me.vmax > me.srs_spd)
                    me.vmax = me.srs_spd;
            } else {
                if(vmode == 'G/S'){
                    if(me.gs_in_range){
                        if(me.ver_ctrl != 'man-set'){
                            setprop(fmgc~ "ver-ctrl", 'man-set');
                            me.ver_ctrl = 'man-set';
                        }
                        var flare = (me.autoland_phase == 'flare');
                        var below_early_des = (me.agl < getprop('autoland/early-descent')); #TODO: below_early_des > instance variable
                        if(flare){
                            me.active_common_mode = 'FLARE';
                            me.armed_common_mode = 'ROLL OUT';
                        }
                        elsif(below_early_des){
                            me.active_common_mode = 'LAND';
                            me.armed_common_mode = 'FLARE';
                        } else {
                            if(math.abs(me.gs_dev) > 0.05)
                                vmode = 'G/S*';
                            me.active_ver_mode = vmode;
                            me.armed_common_mode = 'LAND'; 
                        }
                        me.armed_ver_secondary_mode = '';
                    } else {
                        if(ver_fmgc and !me.capturing_leg) {
                            me.active_ver_mode = vmode_main;
                            var armed_vmode_2 = me.get_armed_ver_mode(fcu_alt,
                                                                      trgt_alt,
                                                                      alt_cstr,
                                                                      crz_alt,
                                                                      is_capturing_alt);
                            me.armed_ver_secondary_mode = armed_vmode_2;
                        } else {
                            me.active_ver_mode = me.get_selected_vmode(vmode_main, 
                                                                       vphase,
                                                                       raw_alt_diff);
                        }
                        me.armed_ver_mode = vmode;
                    }
                }
                elsif(vmode == 'FINAL') { #TODO: final disarms at DH - 50
                    var dest_wp = RouteManager.getDestinationWP();#me.destination_wp;
                    if(dest_wp != nil){
                        var dest_idx = dest_wp.index;
                        if(dest_idx != current_wp){
                            if(ver_fmgc) {
                                me.active_ver_mode = vmode_main;
                                var armed_vmode_2 = me.get_armed_ver_mode(fcu_alt,
                                                                          trgt_alt,
                                                                          alt_cstr,
                                                                          crz_alt,
                                                                          is_capturing_alt);
                                me.armed_ver_secondary_mode = armed_vmode_2;
                            } else {
                                me.active_ver_mode = me.get_selected_vmode(vmode_main, 
                                                                           vphase,
                                                                           raw_alt_diff);
                            }
                        } else{
                            me.active_ver_mode = vmode;
                            me.armed_ver_mode = '';
                            me.non_precision_app = 1;
                            me.armed_ver_secondary_mode = '';
                        }
                    } else {
                        me.revert_to_vsfpa(vmode);
                    }
                } else {
                    me.active_ver_mode = vmode;
                    me.armed_ver_mode = me.get_armed_ver_mode(fcu_alt,
                                                              trgt_alt,
                                                              alt_cstr,
                                                              crz_alt,
                                                              is_capturing_alt);
                }
            }
            # Check if fcu alt contrasts with CLB or DES modes
            # Reverses to VS/FPA mode if there's contrast
            vmode_sfx = substr(me.active_ver_mode, -3, 3);
            var clbdes = (vmode_sfx == 'CLB' or vmode_sfx == 'DES');
            var tvp = me.true_vertical_phase;
            if(clbdes and vmode_sfx != tvp and tvp != ''){
                me.revert_to_vsfpa(vmode);
            }
        }
        #ATHR 
        var fixed_thrust = 0;
        me.speed_with_pitch = me.pitch_controls_speed(me.active_ver_mode);
        if(me.a_thr == 'eng'){
            var spd_mode = '';
            if(me.spd_mode == "ias"){
                spd_mode = 'SPEED';
            } else {
                spd_mode = 'MACH';
            }
            if(!me.ap_engaged and !me.fd_engaged){
                me.active_athr_mode = spd_mode;
                me.speed_with_pitch = 0;
            } else {
                me.active_athr_mode = me.get_athr_mode(me.active_ver_mode, spd_mode);
                if(me.active_athr_mode != spd_mode)
                    fixed_thrust = 1;
            }
            me.armed_athr_mode = '';
        } else {
            me.active_athr_mode = '';
            var above_clb = (throttle > thrust_levers.detents.CLB);
            if(toga){
                me.armed_athr_mode = "MAN\nTOGA";
            } else {
                if(flex_mct){
                    if(me.flex_to_temp > -100)
                        me.armed_athr_mode = "MAN\nFLX";
                    else 
                        me.armed_athr_mode = "MAN\nMCT";
                } else {
                    me.armed_athr_mode = (me.a_thr == 'armed' and above_clb) ? "MAN\nTHR" : '';
                }
            }
            fixed_thrust = toga or flex_mct or above_clb;
            if(above_clb and me.agl > me.thr_red)
                me.thrust_levers_alert();
        }
        if(me.is_stalling or me.alpha_floor_mode){
            fixed_thrust = 1;
            me.speed_with_pitch = 1;
            me.active_athr_mode = 'A. FLOOR';
            me.alpha_floor_mode = 1;
        } 
        elsif(me.thrust_lock){
            fixed_thrust = 1;
            var lock_reason = me.thrust_lock_reason;
            if(lock_reason == 'TOGA'){
                me.active_athr_mode = 'TOGA LK';
            } else {
                me.athr_alert =  me.thrust_lock_reason~ ' LK';   
            }
        }
        me.fixed_thrust = fixed_thrust;
        # FMA Message: displays DECELERATE after T/D until descent does not start
        if(after_td){
            vmode = me.active_ver_mode;
            if(!me.descent_started and 
               (vmode_sfx == 'DES' or (me.vsfpa_mode and me.vs_fps < -100))){
               me.descent_started = 1;
            }
            if(!me.descent_started)
                setprop('/flight-management/flight-modes/message', 'DECELERATE');
            else{
                if(getprop('/flight-management/flight-modes/message') == 'DECELERATE')
                    setprop('/flight-management/flight-modes/message', '');
            }
        }
        if (me.active_lat_mode == 'APP NAV' and 
            me.active_ver_mode == 'FINAL'){
            me.active_common_mode = 'FINAL APP';
        }
        if(me.active_common_mode != ''){
            me.active_lat_mode = '';
            me.active_ver_mode = '';
            if(me.active_common_mode == 'ROLL OUT'){
                me.armed_lat_mode = '';
                me.armed_ver_mode = '';
            }
        }
        if(me.armed_common_mode != ''){
            me.armed_lat_mode = '';
            me.armed_ver_mode = '';
        }
        
        if(!me.ap_engaged and !me.fd_engaged){
            me.active_lat_mode = '';
            me.active_ver_mode = '';
            me.armed_lat_mode = '';
            me.armed_ver_mode = '';
            me.active_common_mode = '';
            me.armed_common_mode = '';
            me.armed_ver_secondary_mode = '';
        }
        
        if(me.rwy_trk != nil and me.active_lat_mode != 'RWY TRK')
            me.rwy_trk = nil;
        
        setprop(athr_modes~'active', me.active_athr_mode);
        setprop(athr_modes~'armed', me.armed_athr_mode);
        setprop(vmodes~'active', me.active_ver_mode);
        setprop(vmodes~'armed', me.armed_ver_mode);
        setprop(vmodes~'armed[1]', me.armed_ver_secondary_mode);
        setprop(vmodes~'display-secondary-armed', me.display_ver_secondary_mode);
        setprop(lmodes~'active', me.active_lat_mode);
        setprop(lmodes~'armed', me.armed_lat_mode);
        setprop(common_modes~'active', me.active_common_mode);
        setprop(common_modes~'armed', me.armed_common_mode);
        setprop(athr_modes~ 'msg', me.athr_msg);
        setprop(athr_modes~ 'alert', me.athr_alert);
        me.update_pfd_fma();
        #setprop(fmgc ~'fixed-thrust', fixed_thrust);
        me.ver_managed = (me.ver_ctrl == 'fmgc' and 
                          me.flplan_active and 
                          !me.capturing_leg and 
                          (me.lat_ctrl == 'fmgc' or me.lat_mode == 'nav1') and 
                          !me.vsfpa_mode and 
                          me.active_ver_mode != 'SRS');
        me.real_target_alt = trgt_alt;
        me.follow_alt_cstr = follow_alt_cstr;
        me.alt_cstr = alt_cstr;
        
    },
    get_athr_mode: func(vmode, spd_mode){
        if(me.vmax and !me.ap_engaged and me.fd_engaged){
            if(((me.vmax < 1 and me.mach > me.vmax) or 
                (me.vmax > 1 and me.ias > me.vmax)))
                return spd_mode;
        }
        var retard = getprop("/autoland/retard");
        if(me.speed_with_pitch or retard){
            var thr_mode = 'THR';
            if(me.max_throttle_pos < 0.6 and !me.thrust_lock and !retard){
                thr_mode = 'THR LVR';
                me.thrust_levers_alert();
            } else {
                var vphase = me.true_vertical_phase;
                if(vphase == 'CLB' and !retard)
                    thr_mode = thr_mode~ ' CLB';
                else 
                    thr_mode = thr_mode~ ' IDLE';
            }
            return thr_mode;
        }
        return spd_mode;
    },
    pitch_controls_speed: func(vmode){
        return (
            vmode == 'SRS' or 
            vmode == 'CLB' or 
            vmode == 'DES' or 
            vmode == 'OP CLB' or 
            vmode == 'OP DES' or 
            vmode == 'EXP CLB' or 
            vmode == 'EXP DES'
        );
    },
    get_alt_mode: func(trgt_alt, alt_cstr, crz_alt, capturing){
        var mode = 'ALT';
        if(trgt_alt == crz_alt)
            mode ~= ' CRZ';
        elsif(trgt_alt == alt_cstr)
            mode ~= ' CST';
        if(capturing)
            mode ~= '*';
        return mode;
    },
    thrust_levers_alert: func(){
        var msg = 'LVR CLB';
        if(!me.engines_running)
            msg = 'LVR MCT';
        me.athr_msg = msg;
    },
    calc_vmax: func(){
        var vmax = 0;
        var exp_mode = me.exped_mode;
        var flaps = me.flaps;
        var extend_flaps_spd = 0;
        if(flaps > 0.745)
            vmax = 184;
        elsif(flaps == 0.745){
            extend_flaps_spd = 184;
            vmax = 190;
        }
        elsif(flaps == 0.596){
            extend_flaps_spd = 190;
            vmax = 200;
        }
        elsif(flaps == 0.29){
            extend_flaps_spd = 200;
            vmax = 215;
        } else {
            var alt = me.altitude;
            if(!exp_mode){
                if(alt < 10000)
                    vmax = 254;
                elsif(alt < me.mach_trans_alt)
                    vmax = 324;
                else 
                    vmax = 0.78;
            } else {
                vmax = 340;
            }
        }
        setprop('instrumentation/pfd/max-flaps-extend-speed',
                extend_flaps_spd);
        return vmax;
    },
    calc_exped_spd: func(){
        var true_phase = me.true_vertical_phase;
        if(true_phase == 'CLB'){
            return me.green_dot_spd;
        } else {
            var alt = me.altitude;
            if(alt > me.mach_trans_alt){
                return 0.8;
            } else {
                return 330;
            }
        }
    },
    get_vsfpa_mode: func(vmode){
        var sub = me.ver_sub;
        if(sub == 'vs'){
            vmode = 'VS';#~me.vs_setting;
        } else {
            vmode = 'FPA';#~me.fpa_setting;
        }
        return vmode;
    },
    get_selected_vmode: func(vmode, vphase, raw_alt_diff){
        if(vmode == vphase){
            if(me.vsfpa_mode){
                vmode = me.get_vsfpa_mode(vmode);
            } 
            else {
                if(raw_alt_diff < -10)
                    vmode = 'DES';
                if(vmode == '') vmode = me.true_vertical_phase;
                if(!me.exped_mode)
                    vmode = 'OP '~vmode;
                else
                    vmode = 'EXP '~vmode;
            } 
        }
        return vmode;
    },
    get_armed_ver_mode: func(fcu_alt, trgt_alt, alt_cstr, crz_alt, is_capturing_alt){
        var vmode = me.active_ver_mode;
        var armed_ver_mode = '';
        var is_alt_mode = (substr(vmode, 0, 3) == 'ALT');
        if(is_alt_mode and !is_capturing_alt){
            if(vmode == 'ALT CST'){ # ALT CST automatically arms DES/CLB
                if(fcu_alt > alt_cstr)
                    armed_ver_mode = 'CLB';
                else 
                    armed_ver_mode = 'DES';
            } else {
                var tmp_fcu_alt = getprop(fcu~ 'fcu-alt');
                var ver_armed = '';
                var clbdes_armed = 0;
                if ((tmp_fcu_alt - fcu_alt) < -250){
                    ver_armed = 'DES';
                    clbdes_armed = 1;
                }
                elsif ((tmp_fcu_alt - fcu_alt) >250){
                    ver_armed = 'CLB';
                    clbdes_armed = 1;
                }
                #if (!ver_fmgc and clbdes_armed)
                #    ver_armed = 'OP '~ ver_armed;
                armed_ver_mode = ver_armed;
                #if (clbdes_armed)
                #    me.revert_to_vsfpa(vmode);
            }
        } elsif (is_alt_mode and is_capturing_alt) {
            armed_ver_mode = '';
        } else { #NO ALT MODE: armed mode is ALT
            armed_ver_mode = me.get_alt_mode(trgt_alt, alt_cstr, crz_alt, 0); 
            if(armed_ver_mode != 'ALT CRZ'){
                armed_ver_mode = 'ALT';
            }
        }
        return armed_ver_mode;
    },
    engage_go_around: func(lat_mode){
        me.active_lat_mode = 'GA TRK';
        me.armed_lat_mode = lat_mode; #TODO: arm HDG/TRK?
        if(me.toga_trk == nil)
            me.toga_trk = me.track;
        me.lat_mode = 'hdg';
        setprop(fmgc~ "lat-mode", 'hdg');
        me.lat_ctrl = 'man-set';
        setprop(fmgc~ "lat-ctrl", 'man-set');

        me.ver_mode = 'alt';
        setprop(fmgc~ "ver-mode", 'alt');
        me.ver_ctrl = 'man-set';
        setprop(fmgc~ "ver-ctrl", 'man-set');
        me.spd_ctrl = 'fmgc';
        setprop(fmgc~ "spd-ctrl", 'fmgc');
        setprop("/autoland/active", 0);
        setprop("/autoland/retard", 0);
        setprop("/autoland/phase", '');
        setprop("/autoland/rudder", 0);
    },
    lvlch_check : func {

        if ((me.ap1 == "eng") or (me.ap2 == "eng")) {

            var vs_fps = me.vs_fps;

            if (math.abs(vs_fps) > 8)
                setprop("/flight-management/fcu/level_ch", 1);
            else
                setprop("/flight-management/fcu/level_ch", 0);

        } else
            setprop("/flight-management/fcu/level_ch", 0);

    },

    knob_sum : func {
        #var disp_hdg = getprop('/flight-management/fcu/display-hdg');
        var disp_vs = getprop('/flight-management/fcu/display-vs');
        if(me.spd_ctrl != 'fmgc'){ #or disp_hdg){
            var ias = getprop(fcu~ "ias");

            var mach = getprop(fcu~ "mach");

            setprop(fcu~ "spd-knob", ias + (100 * mach));
        }
        if (me.vsfpa_mode or disp_vs){
            var vs = getprop(fcu~ "vs");

            var fpa = getprop(fcu~ "fpa");

            setprop(fcu~ "vs-knob", fpa + (vs/100));
        }

    },
    hdg_disp : func {

        var hdg = int(getprop(fcu~ "hdg"));

        if (hdg < 10)
            setprop(fcu~ "hdg-disp", "00" ~ hdg);
        elsif (hdg < 100)
            setprop(fcu~ "hdg-disp", "0" ~ hdg);
        else
            setprop(fcu~ "hdg-disp", "" ~ hdg);

    },
    update_fcu: func(){
        if(me.lat_ctrl == 'fmgc' or me.lat_mode == 'nav1'){
            var disp_hdg = getprop('/flight-management/fcu/display-hdg');
            if(!disp_hdg and !me.capturing_leg)
                me.set_current_hdgtrk();
        }
        if(me.spd_ctrl == 'fmgc' and me.airborne){
            if(!getprop('/flight-management/fcu/display-spd'))
                me.set_current_spd();
        }
    },
    update_pfd_fma: func(){
        var armed_vmode_l = '';
        var armed_vmode_r = '';
        var armed_vmode = '';
        var armed_vmode_1 = me.armed_ver_mode;
        var armed_vmode_2 = me.armed_ver_secondary_mode;
        var left_modes = ['ALT', 'CLB', 'DES'];
        var right_modes = ['G/S', 'FINAL'];
        var left = 0;
        var right = 0;
        foreach(var mode; left_modes){
            if(armed_vmode_1 == mode or armed_vmode_2 == mode){
                armed_vmode_l = mode;
                left = 1;
                break;
            }
        }
        foreach(var mode; right_modes){
            if(armed_vmode_1 == mode or armed_vmode_2 == mode){
                armed_vmode_r = mode;
                right = 1;
                break;
            }
        }
        if(!left and !right)
            armed_vmode = armed_vmode_1;
        setprop('instrumentation/pfd/ver-armed-mode', armed_vmode);
        setprop('instrumentation/pfd/ver-armed-mode-l', armed_vmode_l);
        setprop('instrumentation/pfd/ver-armed-mode-r', armed_vmode_r);
    },
    fcu_lights : func {

        if (me.lat_mode == "nav1")
            setprop(fmgc~ "fcu/nav1", 1);
        else
            setprop(fmgc~ "fcu/nav1", 0);

        if (me.ver_mode == "ils")
            setprop(fmgc~ "fcu/ils", 1);
        else
            setprop(fmgc~ "fcu/ils", 0);

        if (me.a_thr == "eng" or me.a_thr == "armed")
            setprop(fmgc~ "fcu/a-thrust", 1);
        else
            setprop(fmgc~ "fcu/a-thrust", 0);

        if (me.ap1 == "eng")
            setprop(fmgc~ "fcu/ap1", 1);
        else
            setprop(fmgc~ "fcu/ap1", 0);

        if (me.ap2 == "eng")
            setprop(fmgc~ "fcu/ap2", 1);
        else
            setprop(fmgc~ "fcu/ap2", 0);

    },
    target_alt_disp: func(){
        var alt = getprop(fcu~ 'fcu-alt');
        var is_std = (getprop('flight-management/text/qnh') == 'STD');
        if (is_std)
            return 'FL'~ int(alt/100);
        return ''~ alt;
    },
    alt_100 : func {

        var alt = me.altitude;

        return int(alt/100);

    },

    flight_phase : func {

        var phase = getprop("/flight-management/phase");
        var ias = me.ias;
        var crz_fl = me.crz_fl;
        var fcu_alt = me.fcu_alt;
        var alt = me.altitude;
        var acc_alt = me.acc_alt or 1500;

        if ((phase == "T/O")) {
            me.check_next_phase_speed('CLB');
            if(!getprop("/gear/gear[2]/wow") and ias > 70){
                if(me.agl > acc_alt)
                    setprop("/flight-management/phase", "CLB");
            }
            elsif(ias > 75)
                setprop('instrumentation/mcdu/prog/phase', 'TAKEOFF');
            setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/trans-alt'));
        } elsif (phase == "CLB") {
            me.manage_phase_speed('CLB');
            me.check_next_phase_speed('CRZ');
            if (crz_fl != 0) {
                var crz_alt = (crz_fl * 100);
                if (alt >= (crz_alt - 500)){
                    setprop("/flight-management/phase", "CRZ");
                    me.ref_crz_alt = crz_alt;
                }
            } else {
                if (alt > me.mach_trans_alt and alt >= (fcu_alt - 500)){
                    setprop("/flight-management/phase", "CRZ");
                    me.ref_crz_alt = alt;
                }
            }
            setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/trans-alt'));
        } elsif (phase == "CRZ") {
            me.manage_phase_speed('CRZ');
            me.check_next_phase_speed('');
            if (crz_fl != 0) {
                var crz_alt = (crz_fl * 100);
                if(crz_alt > (me.ref_crz_alt + 500)){
                    setprop("/flight-management/phase", "CLB");
                    return 'CLB';
                }
                elsif (fcu_alt < (crz_alt - 500)){
                    var dest_wp = RouteManager.getDestinationWP();#me.destination_wp; # TODO: check here for sequencing
                    #if(RouteManager.sequencing) dest_wp = nil;
                    if(dest_wp != nil and (me.remaining_nm <= 200)){
                        setprop("/flight-management/phase", "DES");
                    }
                    elsif(me.remaining_nm < me.top_desc){
                        setprop("/flight-management/phase", "DES");
                    } else {
                        var first_cstr = RouteManager.first_descent_constraint;
                        var max_alt = (20000 > first_cstr ? 20000 : first_cstr);
                        if(fcu_alt < max_alt)
                            setprop("/flight-management/phase", "DES");
                        else{
                            me.crz_fl = int(fcu_alt / 100);
                            setprop("/flight-management/crz_fl", me.crz_fl);
                            setprop("autopilot/route-manager/cruise/altitude-ft", fcu_alt);
                        }
                    }
                }
            } else {
                var ref_alt = me.ref_crz_alt;
                if(!ref_alt) ref_alt = me.mach_trans_alt;
                if (fcu_alt < ref_alt)
                    setprop("/flight-management/phase", "DES");

            }
            setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/trans-alt'));
        } elsif ((phase == "DES") and (getprop("/flight-management/control/ver-mode") == "ils")) {

            setprop("/flight-management/phase", "APP");
            var app_type = '';
            if(me.approach_ils != nil)
                app_type = 'ILS APP';
            elsif(me.flplan_active)
                app_type = 'RNAV APP';
                
            setprop('/instrumentation/nd/app-mode', app_type);
            setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/appr-trans-alt'));

        } elsif ((phase == "APP")) {
            if(getprop("/gear/gear/wow"))
                setprop("/flight-management/phase", "LANDED");
            elsif(me.toga_trk)
                setprop("/flight-management/phase", "G/A");
            setprop(fmgc_val~ 'trans-alt', getprop('/instrumentation/fmc/appr-trans-alt'));
        } elsif (phase == "LANDED" ) {
            if(ias <= 70){
                setprop("/flight-management/phase", "T/O");
                setprop('/instrumentation/nd/app-mode', '');
                setprop("/autoland/retard", 0);

                new_flight();

                me.current_wp = 0;
            }
            elsif(me.toga_trk)
                setprop("/flight-management/phase", "G/A");
        }
        return getprop("/flight-management/phase");
    },
    manage_phase_speed: func(phase){
        var phase_name = {
            'CLB': 'climb',
            'CRZ': 'cruise',
            'DES': 'descent'
        }[phase];
        var spd_ctrl = me.spd_ctrl;
        if(phase_name != nil){
            var spd_manager = '/flight-management/spd-manager/';
            var mode = getprop(spd_manager ~ phase_name ~'/mode');
            if(mode == 'SELECTED'){
                spd_ctrl = 'man-set';
                setprop(fmgc~ 'spd-ctrl', spd_ctrl);
                me.spd_ctrl = spd_ctrl;
                var spd = getprop(spd_manager ~ phase_name ~'/spd1');
                if(!spd) return;
                setprop(fcu~ 'ias', spd);
                if(spd < 1)
                    setprop(fmgc~ 'spd-mode', 'mach');
                else
                    setprop(fmgc~ 'spd-mode', 'ias');
            }
            elsif(mode == 'MANAGED') {
                if(spd_ctrl == 'man-set'){
                    #TODO: display FMA message alert
                }
            }
        }
    },
    check_next_phase_speed: func(phase){
        var phase_name = {
            'CLB': 'climb',
            'CRZ': 'cruise',
            'DES': 'descent'
        }[phase];
        var spd_ctrl = me.spd_ctrl;
        if(phase_name != nil){
            var spd_manager = '/flight-management/spd-manager/';
            var mode = getprop(spd_manager ~ phase_name ~'/mode');
            if(mode == 'SELECTED'){
                var spd = getprop(spd_manager ~ phase_name ~'/spd1');
                if(!spd) {
                    setprop('instrumentation/pfd/presel-spd', '');
                    return;
                };
                var spd_mode = '';
                if(spd < 1)
                    spd_mode = 'MACH';
                else
                    spd_mode = 'SPEED';
                var msg = spd_mode~ ' SEL: '~ spd;
                setprop('instrumentation/pfd/presel-spd', msg);
            }
            elsif(mode == 'MANAGED') {
                setprop('instrumentation/pfd/presel-spd', '');
            }
        } else {
            setprop('instrumentation/pfd/presel-spd', '');
        }
    },
    calc_td: func {
        var td_offset_prop = 'flight-management/vnav/tc-offset-nm';
        if(RouteManager.sequencing) return getprop(td_offset_prop) or 0;
        var tdNode = "/autopilot/route-manager/vnav/td";
        var top_of_descent = 36;

        if (me.flplan_active){
            var cruise_alt = getprop("autopilot/route-manager/cruise/altitude-ft");
            var destination_elevation = getprop("/autopilot/route-manager/destination/field-elevation-ft");
            if(cruise_alt > 10000) {
                top_of_descent += 21;
                if(cruise_alt > 29000)
                {
                    top_of_descent += 41.8;
                    if(cruise_alt > 36000)
                    {
                        top_of_descent += 28;
                        top_of_descent += (cruise_alt - 36000) / 1000 * 3.8;
                    }
                    else
                    {
                        top_of_descent += (cruise_alt - 29000) / 1000 * 4;
                    }
                }
                else
                {
                    top_of_descent += (cruise_alt - 10000) / 1000 * 2.2;
                }
                top_of_descent += 6.7;
            } else {
                top_of_descent += (cruise_alt - 3000) / 1000 * 3;
            }
            top_of_descent -= (destination_elevation / 1000 * 3);
            var cur_td = getprop(td_offset_prop);
            if(cur_td == nil) cur_td = 0;
            if(math.abs(top_of_descent - cur_td) > 1){
                setprop(td_offset_prop, top_of_descent);
                var remaining = me.remaining_nm;
                var td_dist = remaining - top_of_descent;
                setprop('flight-management/vnav/td-dist-nm', td_dist);
                if(td_dist > 0){
                    setprop('flight-management/vnav/td-eta', 
                            me.calc_eta(td_dist));
                } else {
                    setprop('flight-management/vnav/td-eta', 0);
                }
            }

            #print("TD: " ~ top_of_descent);
            var f= me.flightplan; 
            #                   var topClimb = f.pathGeod(0, 100);
            var dest_wp = RouteManager.getDestinationWP();#me.destination_wp;
            var idx = (dest_wp != nil ? dest_wp.index : -1);
            var topDescent = f.pathGeod(idx, -top_of_descent);
            setprop(tdNode ~ "/latitude-deg", topDescent.lat); 
            setprop(tdNode ~ "/longitude-deg", topDescent.lon); 
            if(me.armed_ver_mode == "DES")
                setprop(tdNode ~ "/vnav-armed", 1);
            else
                setprop(tdNode ~ "/vnav-armed", 0);
        } else {
            var node = props.globals.getNode(tdNode);
            if(node != nil) props.globals.getNode(tdNode).remove(); 
        }
        return top_of_descent;
    },
    calc_tc: func {
        if(RouteManager.sequencing) return;
        var tcNode = "/autopilot/route-manager/vnav/tc";
        var tc_offset_prop = 'flight-management/vnav/tc-offset-nm';
        var phase = me.phase;
        var vspd_fps = me.vs_fps;
        if(vspd_fps == 0) return;
        if (me.flplan_active and me.airborne and 
            (phase == 'CLB' or 
             (phase == 'CRZ' and vspd_fps >= -0.8))){
            var vs_fpm = me.vs_fpm;
            if(vs_fpm == 0) return;
            var cruise_alt = getprop("autopilot/route-manager/cruise/altitude-ft");
            var altitude = me.altitude;
            var d = cruise_alt - altitude;
            if(d > 100){
                
                var trans_alt = cruise_alt - (vs_fpm / 2);
                var before_trans_nm = me.nm2level(altitude, trans_alt, vs_fpm);
                var after_trans_nm = me.nm2level(trans_alt, cruise_alt, vs_fpm / 4);
                if(before_trans_nm < 1 or 
                   (d <= 500 and before_trans_nm >= 1) or 
                    d < 250) 
                    return;
                var nm = before_trans_nm + after_trans_nm;
                #print("NM: "~nm);
                #print('-----');
                var remaining = me.remaining_nm;
                var ac_pos = me.fp_distance - remaining;
                nm = nm + ac_pos;
                var cur_tc = getprop(tc_offset_prop);
                if(cur_tc == nil) cur_tc = 0;
                if(math.abs(nm - cur_tc) > 1){
                    setprop(tc_offset_prop, nm);
                    var tc_dist = nm - ac_pos;
                    setprop('flight-management/vnav/tc-dist-nm', tc_dist);
                    if(tc_dist > 0){
                        setprop('flight-management/vnav/tc-eta', 
                                me.calc_eta(tc_dist));
                    } else {
                        setprop('flight-management/vnav/tc-eta', 0);
                    }
                } 
                var f= me.flightplan; 
                #print("TC: " ~ nm);
                var topClimb = f.pathGeod(0, nm);
                setprop(tcNode ~ "/latitude-deg", topClimb.lat); 
                setprop(tcNode ~ "/longitude-deg", topClimb.lon); 
            } else {
                var node = props.globals.getNode(tcNode);
                if(node != nil) node.remove();
                setprop(tc_offset_prop, 0);
            }
        } else {
            var node = props.globals.getNode(tcNode);
            if(node != nil) node.remove();
            setprop(tc_offset_prop, 0);
        }

    },
    calc_level_off: func {
        if(RouteManager.sequencing) return;
        var edProp = "/autopilot/route-manager/vnav/ed"; #END OF DESCENT
        var ecProp = "/autopilot/route-manager/vnav/ec"; #END OF CLIMB
        var scProp = "/autopilot/route-manager/vnav/sc"; #START OF CLIMB
        var sdProp = "/autopilot/route-manager/vnav/sd"; #START OF DESCENT
        var remnode = func(ndpath){
            var node = props.globals.getNode(ndpath);
            if(node != nil) node.remove();
        };
        var trgt_alt = 0;
        var fcu_alt = me.fcu_alt;
        if (me.flplan_active and me.airborne and me.ver_mode != 'ils'){
            var f= me.flightplan; 
            var vs_fpm = me.vs_fpm;
            if(vs_fpm == 0) return;
            var vnav_actv = 0;
            if(me.follow_alt_cstr){
                trgt_alt = getprop(fmgc_val ~ 'vnav-target-alt');
                vnav_actv = 1;
            } else {
                trgt_alt = fcu_alt;
            }
            if(trgt_alt == nil){
                remnode(edProp);
                remnode(ecProp);
                remnode(scProp); 
                remnode(sdProp); 
                setprop('instrumentation/efis/nd/current-sc', 0);
                setprop('instrumentation/efis/nd/current-sd', 0);
                setprop('instrumentation/efis/nd/current-ec', 0);
                setprop('instrumentation/efis/nd/current-ed', 0);
                return;
            }
            var altitude = me.altitude;
            var d = 0;
            var prop = '';
            var deact_prop = '';
            var climbing = 0;
            if(altitude > trgt_alt){
                d = altitude - trgt_alt;
                prop = 'ed';
                deact_prop = 'ec';
            } else {
                climbing = 1;
                var cruise_alt = getprop("autopilot/route-manager/cruise/altitude-ft");
                if(cruise_alt == trgt_alt){
                    #print('SAME ALT');
                    remnode(ecProp);
                    if(getprop('instrumentation/efis/nd/current-ec') != 0)
                        setprop('instrumentation/efis/nd/current-ec', 0);
                    return;
                }
                d = trgt_alt - altitude;
                prop = 'ec';
                deact_prop = 'ed';
            }
            if(d > 100){
                var min = d / math.abs(vs_fpm);
                var ground_speed_kt = me.groundspeed;
                var nm_min = ground_speed_kt / 60;
                var nm = nm_min * min;
                var remaining = me.remaining_nm;
                nm = nm + (me.fp_distance - remaining);
                #if(d > 500)
                #    nm += 8;
                #else 
                #    nm += (8 * (d / 500));
                var node = "/autopilot/route-manager/vnav/" ~ prop;
                var lo_raw_prop = 'instrumentation/efis/nd/current-'~prop;
                var cur_lo = getprop(lo_raw_prop);
                if(cur_lo == nil) cur_lo = 0;
                if(math.abs(nm - cur_lo) > 0.5){
                    setprop(lo_raw_prop, nm);
                    setprop('/autopilot/route-manager/vnav/level-off-alt',nm);
                }
                
                #print("TC: " ~ nm);
                var point = f.pathGeod(0, nm);

                var deact_node = "/autopilot/route-manager/vnav/" ~ deact_prop;
                setprop(node ~ "/latitude-deg", point.lat); 
                setprop(node ~ "/longitude-deg", point.lon);
                if(prop == 'ed' or prop == 'ec')
                    setprop(node ~ "/alt-cstr", me.follow_alt_cstr);
                remnode(deact_node); 
            } else {
                remnode(edProp);
                remnode(ecProp); 
                if(getprop('instrumentation/efis/nd/current-ec') != 0)
                    setprop('instrumentation/efis/nd/current-ec', 0);
                if(getprop('instrumentation/efis/nd/current-ed') != 0)
                    setprop('instrumentation/efis/nd/current-ed', 0);
            }
            if(trgt_alt and trgt_alt != fcu_alt){
                var cur_wp = me.current_wp;
                var continue_at = nil;
                var numwp = me.wp_count;
                for(i = cur_wp + 1; i < numwp; i = i + 1){
                    if(i == 1) continue;
                    var wp = f.getWP(i);
                    var alt_cstr = wp.alt_cstr;
                    if(alt_cstr < 0) alt_cstr = 0;
                    if(climbing){
                        if((alt_cstr and alt_cstr > trgt_alt) or 
                           (!alt_cstr and fcu_alt > trgt_alt)){
                            continue_at = f.getWP(i - 1);
                            break;
                        }
                    } else {
                        if((alt_cstr and alt_cstr < trgt_alt) or 
                           (!alt_cstr and fcu_alt < trgt_alt)){
                            continue_at = f.getWP(i - 1);
                            break;
                        }
                    }
                }
                if(continue_at != nil){
                    var cprops = [sdProp, scProp];
                    #var fl_modes = ['DES', 'CLB'];
                    var act_prop = cprops[climbing];
                    var deact_prop = cprops[!climbing];
                    #var armed = me.armed_ver_mode == fl_modes[climbing];
                    remnode(deact_prop);
                    #var cnode = "/autopilot/route-manager/vnav/" ~ act_prop;
                    var dnm = continue_at.distance_along_route;
                    var point = f.pathGeod(0, dnm + 1.2);
                    setprop(act_prop ~ "/latitude-deg", point.lat); 
                    setprop(act_prop ~ "/longitude-deg", point.lon);
                    setprop(act_prop ~ "/vnav-armed", 1);
                } else {
                    remnode(scProp);
                    remnode(sdProp);
                }
            }
        } else {
            remnode(edProp);
            remnode(ecProp); 
            remnode(sdProp);
            remnode(scProp); 
            if(getprop('instrumentation/efis/nd/current-ec') != 0)
                setprop('instrumentation/efis/nd/current-ec', 0);
            if(getprop('instrumentation/efis/nd/current-ed') != 0)
                setprop('instrumentation/efis/nd/current-ed', 0);
            if(getprop('instrumentation/efis/nd/current-sc') != 0)
                setprop('instrumentation/efis/nd/current-sc', 0);
            if(getprop('instrumentation/efis/nd/current-sd') != 0)
                setprop('instrumentation/efis/nd/current-sd', 0);
        }

    },
    calc_decel_point: func{
        if(RouteManager.sequencing) return me.decel_point;
        var decelNode = "/instrumentation/nd/symbols/decel";
        if (getprop("/autopilot/route-manager/active")){
            var f= me.flightplan; 
            var numwp = me.wp_count;
            var i = 0;
            var first_approach_wp = nil;
            for(i = 0; i < numwp; i = i + 1){
                var wp = f.getWP(i);
                if(wp != nil){
                    var role = wp.wp_role;
                    if(role == 'approach'){
                        first_approach_wp = wp;
                        break;
                    }
                }
            }
            if(first_approach_wp != nil){
                var dist = wp.distance_along_route;
                var totdist = me.fp_distance;
                dist = totdist - dist;
                var nm = dist + 11;
                var dest_wp = RouteManager.getDestinationWP();#me.destination_wp;
                var idx = (dest_wp != nil ? dest_wp.index : -1);
                var decelPoint = f.pathGeod(idx, -nm);
                setprop(decelNode ~ "/latitude-deg", decelPoint.lat); 
                setprop(decelNode ~ "/longitude-deg", decelPoint.lon); 
                var ac_dist = me.remaining_nm - nm;
                if(ac_dist > 0){
                    setprop('flight-management/vnav/decel-dist-nm', ac_dist);
                    setprop('flight-management/vnav/decel-eta', me.calc_eta(ac_dist));
                }
                return nm;
            } else {
                setprop(decelNode, '');
            }
#            var dest_wp = RouteManager.getDestinationWP();#me.destination_wp;
#            if(dest_wp != nil){
#                var nm = 9.5;
#                var appr_wp = nil;
#                var dst_idx = dest_wp.index;
#                var totdist = me.fp_distance;
#                var elev = getprop('autopilot/route-manager/destination/field-elevation-ft');
#                for(var i = dst_idx; i > 1; i -= 1){
#                    var wp = f.getWP(i);
#                    if(wp != nil){
#                        var dist = wp.distance_along_route;
#                        dist = totdist - dist;
#                        if(dist < nm) continue;
#                        var alt_cstr = wp.alt_cstr;
#                        if(alt_cstr == nil or alt_cstr <= 0) continue;
#                        alt_cstr = alt_cstr - elev;
#                        if(alt_cstr >= 1900 and alt_cstr <= 2300)
#                            nm = dist + 2;
#                        elsif(alt_cstr > 2300) break;
#                    }
#                }
#                var decelPoint = f.pathGeod(dst_idx, -nm);
#                setprop(decelNode ~ "/latitude-deg", decelPoint.lat); 
#                setprop(decelNode ~ "/longitude-deg", decelPoint.lon); 
#                var ac_dist = me.remaining_nm - nm;
#                if(ac_dist > 0){
#                    setprop('flight-management/vnav/decel-dist-nm', ac_dist);
#                    setprop('flight-management/vnav/decel-eta', me.calc_eta(ac_dist));
#                }
#                return nm;
#            } else {
#                setprop(decelNode, '');
#            }
        } else {
            setprop(decelNode, '');
        }
        return 0;
    },
    calc_speed_change: func(){
        if(RouteManager.sequencing) return;
        var spdChangeNode = "/autopilot/route-manager/spd/spd-change-point";
        var spd_change_raw = 'instrumentation/efis/nd/spd-change-raw';
        if (!getprop("/autopilot/route-manager/active") or getprop("/gear/gear[2]/wow"))
            return 0;
        if ((me.spd_ctrl != "fmgc") or (me.a_thr != "eng")) 
            return 0;
        var phase = getprop("/flight-management/phase"); # TODO: USE TRUE VERTICAL PHASE?
        var trgt_alt = 0;
        if(me.ver_ctrl == "fmgc"){
            if(phase == 'CLB')
                trgt_alt = getprop("autopilot/route-manager/cruise/altitude-ft");
            else
                trgt_alt = getprop(fmgc_val ~ 'vnav-target-alt');
        } else {
            trgt_alt = me.fcu_alt;
        }
        var altitude = me.altitude;
        var vs_fpm = me.vs_fpm;
        if(vs_fpm == 0) return;
        var spd_cange_count = 0;
        var f= me.flightplan; 
        foreach(var alt; [10000, me.mach_trans_alt]){
            var alt_100 = alt / 100;
            var node_path = spdChangeNode ~ '-' ~ alt_100;
            var node_raw_path = spd_change_raw ~ '-' ~ alt_100;
            var cond = 0;
            if(phase == 'CLB'){
                cond = ((altitude < alt) and trgt_alt >= alt);
            }                                                
            elsif(phase == 'DES'){
                cond = ((altitude > alt)  and trgt_alt <= alt);
            }      
            if(cond){
                var d = 0;
                if(phase == 'CLB')
                    d = alt - altitude;
                elsif(phase == 'DES')
                    d = altitude - alt;
                if(d > 100){
                    var min = d / math.abs(vs_fpm);
                    var ground_speed_kt = me.groundspeed;
                    var nm_min = ground_speed_kt / 60;
                    var nm = nm_min * min;
                    var remaining = me.remaining_nm;
                    nm = nm + (me.fp_distance - remaining);
                    if(d > 500 and alt == trgt_alt)
                        nm += 8;
                    elsif(d <= 500 and alt == trgt_alt)
                        nm += (8 * (d / 500));
                    else 
                        nm += 1;
                    var cur_raw = getprop(node_raw_path);
                    if(cur_raw == nil) cur_raw = 0;
                    if(math.abs(nm - cur_raw) >= 1){
                        setprop(node_raw_path, nm);
                    } 
                    #print("TC: " ~ nm);
                    var point = f.pathGeod(0, nm);
                    setprop(node_path ~ "/latitude-deg", point.lat); 
                    setprop(node_path ~ "/longitude-deg", point.lon); 
                } else {
                    var node = props.globals.getNode(node_path);
                    if(node != nil) node.remove();
                    setprop(node_raw_path, 0);
                }
            }
        }
        var wp = (!RouteManager.sequencing ? f.getWP() : nil);
        var node_path = spdChangeNode ~ '-wp';
        var node_raw_path = spd_change_raw ~ '-wp';
        if(wp != nil){
            var cstr = wp.speed_cstr;
            var wp_dist = wp.distance_along_route;
            if(cstr != nil and cstr > 0){
                var nm = wp_dist - 1;
                var cur_raw = getprop(node_raw_path);
                if(cur_raw == nil) cur_raw = 0;
                if(math.abs(nm - cur_raw) >= 1){
                    setprop(node_raw_path, nm);
                } 
                var point = f.pathGeod(0, nm);
                setprop(node_path ~ "/latitude-deg", point.lat); 
                setprop(node_path ~ "/longitude-deg", point.lon); 
            } else {
                var node = props.globals.getNode(node_path);
                if(node != nil) node.remove();
                setprop(node_raw_path, 0);
            }
        } else {
            var node = props.globals.getNode(node_path);
            if(node != nil) node.remove();
            setprop(node_raw_path, 0);
        }
    },
    nm2level: func(from_alt, to_alt, vs_fpm){
        if(vs_fpm == 0) return 0;
        var d = to_alt - from_alt;
        var min = d / vs_fpm;
        var ground_speed_kt = me.groundspeed;
        var nm_min = ground_speed_kt / 60;
        var nm = nm_min * min;
        return nm;
    },
    calc_eta: func(dist){
        if(dist == nil or dist <= 0) return 0;
        var groundspeed = me.groundspeed;
        if(groundspeed < 50) return 0;
        var eta_s = (dist / groundspeed * 3600);
        var gmt = getprop("instrumentation/clock/indicated-sec");
        gmt += (eta_s + 30);
        var gmt_hour = int(gmt / 3600);
        if(gmt_hour > 24)
        {
            gmt_hour -= 24;
            gmt -= 24 * 3600;
        }
        return gmt_hour * 100 + int((gmt - gmt_hour * 3600) / 60);
    },
    calc_point_bearing: func(nm, offset = 0){
        var rt = 'autopilot/route-manager/route/';
        var n = getprop(rt~'num');
        if(n == nil or n == 0) return 0;
        var bearing = 0;
        if(offset < 0){
            var totdist = me.fp_distance;
            nm = totdist - nm;
        }
        var idx = 0;
        for(idx = 0; idx < n; idx += 1){
            var wp = rt~'wp['~idx~']';
            var dist = getprop(wp~'/distance-along-route-nm');
            if(dist >= nm){
                break;
            }
            bearing = getprop(wp~'/leg-bearing-true-deg');
        }
        return bearing;
    },
    update_throttle: func(thr_l, thr_r){
        var cur_thr_l = me.throttle;
        var cur_thr_r = me.throttle_r;
        if(thr_l != cur_thr_l){
            var d = math.abs(thr_l - cur_thr_l);
            if(d > 0.3)
                interpolate('controls/engines/engine/throttle', thr_l, 3);
            else 
                setprop('controls/engines/engine/throttle', thr_l);
        }
        if(thr_r != cur_thr_r){
            var d = math.abs(thr_r - cur_thr_r);
            if(d > 0.3)
                interpolate('controls/engines/engine[1]/throttle', thr_r, 3);
            else 
                setprop('controls/engines/engine[1]/throttle', thr_r);
        }
    },
    autotune_ils: func(){
        if(RouteManager.sequencing) return;
        me.autotuned_ils = getprop(radio~'autotuned');
        var dest_airport = me.dest_airport;
        var dest_rwy = me.dest_rwy;
        var dep_airport = me.dep_airport;
        var dep_rwy = me.dep_rwy;
        var ils_frq = me.ils_frq;
        var flplan_active = me.flplan_active;
        var airborne = me.airborne;
        if (flplan_active and (!ils_frq or me.autotuned_ils)){
            if(!airborne){
                if (dep_airport != '' and dep_rwy != ''){
                    var dist = getprop("/autopilot/route-manager/route/wp/distance-nm");
                    var not_tuned = (me.autotune.airport != dep_airport or 
                                     me.autotune.rwy != dep_rwy);
                    if(dist != nil and dist < 10 and not_tuned){
                        var apt_info = airportinfo(dep_airport);
                        var rwy = apt_info.runways[dep_rwy];
                        var rwy_ils = nil;
                        if(rwy != nil)
                            rwy_ils = rwy.ils;
                        if(rwy_ils != nil){
                            var frq = rwy_ils.frequency / 100;
                            var crs = rwy_ils.course;
                            setprop(radio~ "ils", frq);
                            setprop(radio~ "ils-crs", int(crs));
                            me.autotune.airport = dep_airport;
                            me.autotune.rwy = dep_rwy;
                            me.autotune.frq = frq;
                            setprop(radio~'autotuned', 1);
                        }
                    }
                }
            } 
            elsif (dest_airport != '' and dest_rwy != ''){
                var not_tuned = (me.autotune.airport != dest_airport or 
                                 me.autotune.rwy != dest_rwy);
                if(not_tuned){
                    var apt_info = airportinfo(dest_airport);
                    var rwy = apt_info.runways[dest_rwy];
                    var rwy_ils = me.approach_ils;
                    if(rwy_ils != nil){
                        var dist = me.remaining_nm;
                        if(dist <= 50){
                            var frq = rwy_ils.frequency / 100;
                            var crs = rwy_ils.course;
                            setprop("/flight-management/freq/ils", frq);
                            setprop("/flight-management/freq/ils-crs", int(crs));
                            if (getprop(radio~ "ils-mode")) {
                                mcdu.rad_nav.switch_nav1(1);
                            }
                            me.autotune.airport = dest_airport;
                            me.autotune.rwy = dest_rwy;
                            me.autotune.frq = frq;
                            setprop(radio~'autotuned', 1);
                        }
                    }
                }
            }
        }
        if(!me.autotuned_ils){
            me.autotune.airport = '';
            me.autotune.rwy = '';
            me.autotune.frq = '';
            #me.autotune.vor = '';
        }

        if (flplan_active and (!airborne or (me.agl > 0 and me.agl < 30)) and dep_airport != ''){
            var dist = getprop("/autopilot/route-manager/route/wp/distance-nm");
            if (dist != nil and dist < 10 and ils_frq != nil){
                var apt_info = airportinfo(dep_airport);
                var rwy_ils = apt_info.runways[dep_rwy].ils;
                if(rwy_ils != nil and ils_frq != nil){
                    var frq = rwy_ils.frequency / 100;
                    #print('RWY ILS: ' ~ rfq ~ ', ILS: ' ~ ils_frq);
                    if (frq == ils_frq){
                        setprop(radio~ "ils-mode", 1);
                        mcdu.rad_nav.switch_nav1(1);
                        var in_range = getprop('instrumentation/nav/in-range');
                        if (in_range) me.rwy_mode = 1;
                    }
                }
            } else {
                me.rwy_mode = 0;
            }
        }
    },
    autotune_navaids: func(){
        var vor1_frq = getprop(radio~ 'vor1');
        me.autotuned_vor1 = getprop(radio~'autotuned-vor') or 0;
        var adf1_id = getprop(radio~ 'adf1-id');
        me.autotuned_adf1 = getprop(radio~'autotuned-adf') or 0;
        var cur_wp = (me.flplan_active ? me.current_wp : 0);
        var wp_id = (cur_wp > 0 ? getprop(actrte~ 'wp['~cur_wp~']/id') : nil);
        var wp_lat = 0;
        var wp_lon = 0;
        if(wp_id != nil){
            wp_lat = getprop(actrte~ 'wp['~cur_wp~']/latitude-deg');
            wp_lon = getprop(actrte~ 'wp['~cur_wp~']/longitude-deg');
        }
        if(vor1_frq == nil or !vor1_frq or me.autotuned_vor1){
            var vor_data = me.autotune['vor'];
            if(vor_data == nil){
                vor_data = {};
                me.autotune['vor'] = vor_data;
            }
            var last_upd_t = vor_data['last_time'];
            var cur_wp_chk = vor_data['current_wp'];
            if(last_upd_t == nil) last_upd_t = 0;
            var wp_changed = (wp_id != nil and wp_id != cur_wp_chk);
            var vor = nil;
            if(wp_changed){
                var found = navinfo(wp_lat, wp_lon, 'vor', wp_id);
                if(size(found)) vor = found[0];
            }
            if(vor == nil and (me.time - last_upd_t) > 120){
                var vors = findNavaidsWithinRange(40, 'vor');
                if(size(vors)) vor = vors[0];
            }
            if(vor != nil){
                var radial = 0;
                if(wp_id != nil and wp_id == vor.id){
                    radial = getprop(actrte~ 'wp['~cur_wp~']/leg-bearing-true-deg') or 0;
                    vor_data['current_wp'] = wp_id;
                } else {
                    var vor_pos = geo.Coord.new();
                    vor_pos.set_latlon(vor.lat, vor.lon);
                    radial = me.aircraft_pos.course_to(vor_pos);
                }
                radial = int(radial);
                vor_data.last_time = me.time;
                vor_data.station = vor;
                var frq = vor.frequency / 100;
                setprop(radio~ 'vor1', frq);
                setprop(radio~ 'vor1-id', vor.id);
                setprop(radio~ 'vor1-crs', radial);
                setprop(radio~'autotuned-vor', 1);
                if(!getprop(radio~ "ils-mode")){
                    mcdu.rad_nav.switch_nav1(0);
                }
                me.autotuned_vor1 = 1;
            }
        }
        if(adf1_id == nil or adf1_id == '' or me.autotuned_adf1){
            var ndb_data = me.autotune['ndb'];
            if(ndb_data == nil){
                ndb_data = {};
                me.autotune['ndb'] = ndb_data;
            }
            var last_upd_t = ndb_data['last_time'];
            var cur_wp_chk = ndb_data['current_wp'];
            if(last_upd_t == nil) last_upd_t = 0;
            var wp_changed = (wp_id != nil and wp_id != cur_wp_chk);
            var ndb = nil;
            if(wp_changed){
                var found = navinfo(wp_lat, wp_lon, 'ndb', wp_id);
                if(size(found)) ndb = found[0];
            }
            if(ndb == nil and (me.time - last_upd_t) > 120){
                var ndbs = findNavaidsWithinRange(40, 'ndb');
                if(size(ndbs)) ndb = ndbs[0];
            }
            if(ndb != nil){
                if(wp_id != nil and wp_id == ndb.id){
                    ndb_data['current_wp'] = wp_id;
                }
                ndb_data.last_time = me.time;
                ndb_data.station = ndb;
                var frq = int(ndb.frequency / 100);
                setprop("/instrumentation/adf[0]/frequencies/selected-khz", frq);
                setprop(radio~ 'adf1-id', ndb.id);
                setprop(radio~'autotuned-adf', 1);
                me.autotuned_adf1 = 1;
            }
        }
    }, 
    get_destination_wp: func(){
        if(RouteManager.sequencing) {
            me.destination_wp_info = nil;
            return nil;
        };
        var wp_info = me.destination_wp_info;
        if(wp_info != nil)
            return wp_info;
        var f= me.flightplan; 
        var numwp = me.wp_count;
        var lastidx = numwp - 1;
        wp_info = nil;
        for(var i = lastidx; i >= 0; i = i - 1){
            var wp = f.getWP(i);
            if(wp != nil){
                var role = wp.wp_role;
                var type = wp.wp_type;
                if(role == 'approach' and type == 'runway'){
                    wp_info = {
                        index: wp.index,
                        distance_along_route: wp.distance_along_route,
                        id: wp.id
                    };
                    break;
                }
            }
        }
        me.destination_wp_info = wp_info;
        return wp_info;
    },
    calc_final_vs: func(){
        if(RouteManager.sequencing) return nil;
        var eta_seconds = getprop('autopilot/route-manager/wp/eta-seconds');
        if(eta_seconds != nil and eta_seconds != '' and eta_seconds){
            var alt = me.altitude;
            var dest_alt = getprop('autopilot/route-manager/destination/field-elevation-ft');
            var diff = dest_alt - alt;
            var vs_fps = diff / eta_seconds;
            return vs_fps;
        }
        return nil;
    },
    calc_final_fpa: func(){
        if(RouteManager.sequencing) return nil;
        var alt = me.altitude;
        var dest_alt = getprop('autopilot/route-manager/destination/field-elevation-ft');
        var diff = dest_alt - alt;
        var wp = RouteManager.getDestinationWP();#me.destination_wp;
        if(wp == nil) return nil;
        var distance = getprop('autopilot/route-manager/route/wp['~wp.index~']/distance-nm');
        return me.calc_required_fpa(alt, dest_alt, distance);
    },
    set_current_hdgtrk: func(){
        setprop(fcu~ 'hdg', int(me.hdg_trk));
    },
    set_current_spd: func(){
        setprop(fcu~ 'ias', me.ias);
        setprop(fcu~ 'mach', me.mach);
    },
    set_current_vsfpa: func(){
        var sub = me.ver_sub;
        var prop = '';
        var current = 0;
        if(sub == 'vs'){
            prop = 'vs';
            current = me.vs_fpm;
        } else {
            prop = 'fpa';
            current = int(me.fpa_angle);
        }
        setprop(fcu~ prop, current);
    },
    revert_to_vsfpa: func(vmode){
        if (me.vsfpa_mode) return;
        me.vsfpa_mode = 1;
        setprop(fmgc~'vsfpa-mode', 1);
        setprop(fmgc~ "ver-ctrl", "man-set");
        me.set_current_vsfpa();
        me.active_ver_mode = me.get_vsfpa_mode(vmode);
    },
    reset : func {
        me.loopid += 1;
        me._loop_(me.loopid);
    },
    _loop_ : func(id) {
        id == me.loopid or return;
        utils.catch(func me.update());
        settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
    }

};

var update_ap_fma_msg = func(){
    var ap1 = getprop(fmgc~ 'ap1-master');
    var ap2 = getprop(fmgc~ 'ap2-master');
    var athr = getprop(fmgc~ "a-thrust");
    var ap1Eng = (ap1 == 'eng');
    var ap2Eng = (ap2 == 'eng');
    var msg = 'AP ';
    if(ap1Eng)
        msg ~= '1';
    if(ap2Eng)
        msg ~= '2';
    var phase = getprop('/flight-management/phase');
    var ils_cat = 0;
    var nav_id = getprop('instrumentation/nav/nav-id');
    var ils_mode = getprop(radio~ "ils-mode");
    if (phase == 'APP' and nav_id != nil and ils_mode){
        if (ap1 == 'eng' or ap2 == 'eng'){
            ils_cat = (athr == 'eng' ? 3 : 2);       
        } else {
            ils_cat = 1;
        }
        fmgc_loop.app_cat = ils_cat;
    }
    if (ils_cat)
        ils_cat = 'CAT '~ ils_cat;
    else 
        ils_cat = '';
    setprop(radio~ 'ils-cat', ils_cat);
    var appr_mode = '';
    if(ils_cat != ''){
        if(ils_cat == 'CAT 3' and msg == 'AP 12'){
            appr_mode = 'DUAL';
        } else {
            appr_mode = 'SINGLE';
        }
    }
    setprop('/instrumentation/pfd/ils-appr-mode', appr_mode);
    setprop('/instrumentation/texts/ap-status', msg);
};

var turn_off_ap = func(ap){
    var lmode = fmgc_loop.active_lat_mode;
    var vmode = fmgc_loop.active_lat_mode;
    var cmode = fmgc_loop.active_common_mode;
    if(lmode == 'LOC' or lmode == 'LOC*' or 
       vmode == 'G/S' or vmode == 'G/S*' or 
       cmode == 'LAND' or cmode == 'ROLL OUT' or cmode == 'FLARE'){
        return;
    }
    ap = fmgc~ 'ap'~ap~'-master';
    setprop(ap, 'off');
} 

setlistener("sim/signals/fdm-initialized", func{
    fmgc_loop.init();
    print("Flight Management and Guidance Computer Initialized");
});

setlistener(athr_modes~'active', func(){
    var mode = athr_modes~'active';
    var box_node = 'instrumentation/pfd/athr-active-box';
    var athr_mode = getprop(mode);
    if(athr_mode != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 5);
    } else {
        setprop(box_node, 0);
    }
    var alert = (athr_mode == 'TOGA LK' or athr_mode == 'A. FLOOR');
    setprop('instrumentation/pfd/athr-alert-box', alert);
}, 0, 0);

setlistener(athr_modes~'armed', func(){
    var mode = athr_modes~'armed';
    var box_node = 'instrumentation/pfd/athr-armed-box';
    var current = getprop(mode);
    if(current != ''){
        setprop(box_node, 1);
        #settimer(func(){
        #    setprop(box_node, 0);     
        #}, 5);
    } else {
        setprop(box_node, 0);
    }
    setprop('instrumentation/pfd/flx-indication', (current == "MAN\nFLX"));
}, 0, 0);

setlistener(lmodes~'active', func(){
    var mode = lmodes~'active';
    var box_node = 'instrumentation/pfd/lat-active-box';
    if(getprop(mode) != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 5);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener(vmodes~'active', func(){
    var mode = vmodes~'active';
    var box_node = 'instrumentation/pfd/ver-active-box';
    if(getprop(mode) != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 5);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener(common_modes~'active', func(){
    var mode = common_modes~'active';
    var box_node = 'instrumentation/pfd/common-active-box';
    if(getprop(mode) != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 5);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);


setlistener('/flight-management/flight-modes/message', func(){
    var msg = getprop('/flight-management/flight-modes/message');
    var box_node = 'instrumentation/pfd/msg-alert-box';
    if(msg != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener('/instrumentation/pfd/ils-appr-mode', func(){
    var mode = getprop('/instrumentation/pfd/ils-appr-mode');
    var box_node = 'instrumentation/pfd/ils-appr-mode-box';
    if(mode != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
},0,0);

setlistener(radio~ 'ils-cat', func(node){
    var cat = node.getValue();
    var box_node = 'instrumentation/pfd/ils-cat-box';
    if(cat != nil and cat != ''){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener('/instrumentation/texts/ap-status', func(node){
    var status = node.getValue();
    var box_node = 'instrumentation/pfd/ap-status-box';
    if(status != nil and status != '' and status != 'AP '){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener("flight-management/control/fd", func(node){
    var engaged = node.getValue();
    var box_node = 'instrumentation/pfd/fd-status-box';
    if(engaged){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener(fmgc~ "lat-ctrl", func(){
    var lat_ctrl = getprop(fmgc~ "lat-ctrl");
    var capture_leg = 0;
    if(lat_ctrl == 'fmgc'){
        var fp_actv = getprop("/autopilot/route-manager/active");
        if(!fp_actv){
            lat_ctrl = 'man-set';#TODO: set?
        } else {
            var xtrk_err = getprop('instrumentation/gps/wp/wp[1]/course-error-nm') or 0;
            if(math.abs(xtrk_err) > 1){
                capture_leg = 1;
            }
        }
    }
    var lat_mode = getprop(fmgc~ "lat-mode");
    if(lat_ctrl == 'man-set' and lat_mode != 'nav1')
        setprop(fmgc~ "ver-ctrl", "man-set");
    setprop(fmgc~ 'capture-leg', capture_leg);
}, 0, 0);

setlistener(fmgc~ "ver-ctrl", func(){
    var lat_ctrl = getprop(fmgc~ "lat-ctrl");
    var ver_ctrl = getprop(fmgc~ "ver-ctrl");
    var lat_mode = getprop(fmgc~ "lat-mode");
    var is_fmgc = (ver_ctrl == 'fmgc');
    if(lat_ctrl == 'man-set' and lat_mode != 'nav1' and is_fmgc)
        setprop(fmgc~ "ver-ctrl", "man-set");
    if(is_fmgc){
        setprop(fmgc~ 'exped-mode', 0);
    }
}, 0, 0);

setlistener(fmgc~ "ver-mode", func(n){
    var mode = n.getValue();
    if(mode == 'ils'){
        setprop(fmgc~ 'exped-mode', 0);
    }
}, 0, 0);

setlistener(fmgc~ "vsfpa-mode", func(n){
    var actv = n.getBoolValue();
    if(actv){
        setprop(fmgc~ 'exped-mode', 0);
    }
}, 0, 0);

setlistener(fmgc~ 'ap1-master', func(ap){
    update_ap_fma_msg();
    if(ap.getValue() == 'eng')
        turn_off_ap(2);
}, 0, 0);

setlistener(fmgc~ 'ap2-master', func(ap){
    update_ap_fma_msg();
    if(ap.getValue() == 'eng')
        turn_off_ap(1);
}, 0, 0);

setlistener(fmgc~ "a-thrust", func(){
    update_ap_fma_msg();
    var display_box = 0;
    var status = getprop(fmgc~ "a-thrust");
    if(status == 'eng'){
        setprop('instrumentation/pfd/flx-indication', 0);
        setprop('instrumentation/pfd/athr-armed-box', 0);
        display_box = 1;
    } 
    elsif(status == 'armed'){
        display_box = 1;
    }
    var box_node = 'instrumentation/pfd/athr-status-box';
    if(display_box){
        setprop(box_node, 1);
        settimer(func(){
            setprop(box_node, 0);     
        }, 10);
    } else {
        setprop(box_node, 0);
    }
}, 0, 0);

setlistener(radio~ "ils-mode", func(){
    update_ap_fma_msg();
}, 0, 0);

setlistener('instrumentation/nav/nav-id', func(){
    update_ap_fma_msg();
}, 0, 0);

setlistener('/flight-management/phase',func(){
    update_ap_fma_msg();
},0,0);

setlistener('/instrumentation/efis/minimums-mode-text', func(){
    var mode = getprop('/instrumentation/efis/minimums-mode-text');
    if(mode == 'RADIO')
        mode = 'DH';
    else
        mode = 'MDA';
    setprop('/instrumentation/pfd/minimums-mode', mode);
});

setlistener(fmgc~ 'exped-mode', func(n){
    var actv = n.getBoolValue();
    if(actv){
        setprop(fmgc~ 'ver-mode', 'alt');
        setprop(fmgc~ 'ver-ctrl', 'man-set');
    }
});

setlistener('autopilot/route-manager/signals/edited', func(){
    fmgc_loop.flightplan = flightplan();
    fmgc_loop.destination_wp_info = nil;
});


