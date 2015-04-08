var DISP_SEC_FPLN = 'instrumentation/mcdu/sec-f-pln/disp';

var A330RouteDriver = {
	parents: [canvas.RouteDriver],
	new: func(){
		var m = {
			parents: [A330RouteDriver],
			plan_wp_info: nil,
			updating: 0
		};
		m.init();
		return m;
	},
	init: func(){
		me.route_manager = fmgc.RouteManager.init();
		me.fplan_types = [];
		me.plans = {};
		me.update();
	},
	update: func(){
		if(!getprop('autopilot/route-manager/route/num'))
			return;
		me.updating = 1;
		if(me.route_manager.sequencing) return;
		var phase = getprop('/flight-management/phase');
		me.fplan_types = [];
		me.plans = me.route_manager.allFlightPlans();
		me.alternates = me.route_manager.alternates;
		append(me.fplan_types, 'current');
		if(me.route_manager.getAlternateRoute() != nil){
			if(!getprop("/instrumentation/mcdu/f-pln/enabling-altn"))
				append(me.fplan_types, 'alternate_current');
		}
		if(me.plans['temporary'] != nil) append(me.fplan_types, 'temporary');
		if(me.plans['secondary'] != nil and getprop(DISP_SEC_FPLN)) {
			append(me.fplan_types, 'secondary');
			if(me.route_manager.getAlternateRoute('secondary') != nil)
				append(me.fplan_types, 'alternate_secondary');
		}
		if(me.route_manager.missed_approach_planned){
			if(phase != 'G/A')
				append(me.fplan_types, 'missed');
		}
		me.phase = phase;
		me.updating = 0;
	},
	getNumberOfFlightPlans: func(){
		if(me.route_manager.sequencing or me.updating) return 0;
		size(me.fplan_types);
	},
	getFlightPlanType: func(fpNum){
		if(me.route_manager.sequencing or me.updating) return nil;
		if(fpNum >= me.getNumberOfFlightPlans()) return nil;
		me.fplan_types[fpNum];
	},
	getFlightPlan: func(fpNum){
		if(me.route_manager.sequencing or me.updating) return nil;
		var type = me.getFlightPlanType(fpNum);
		if(type == nil) return nil;
		if(type != 'missed'){
			me.getFlightPlanByType(type);
		} else {
			var srcPlan = me.plans.current;
			var fp = srcPlan.clone();
			#fp.cleanPlan();
			while(fp.getPlanSize())
				fp.deleteWP(0);
			var missed_appr = me.route_manager.missed_approach;
			var idx = me.route_manager.destination_idx;
			var size = srcPlan.getPlanSize();
			for(var i = idx; i < size; i += 1){
				var wp = srcPlan.getWP(i);
				fp.appendWP(wp);
			}
			fp;
		}
	},
	getFlightPlanByType: func(type){
		if(me.route_manager.sequencing or me.updating) return nil;
		if(find('alternate_', type) == 0)
			me.alternates[split('_', type)[1]];
		else 
			me.plans[type];
	},
	getPlanSize: func(fpNum){
		if(me.route_manager.sequencing or me.updating) return 0;
		var type = me.getFlightPlanType(fpNum);
		if(type == nil) return 0;
		if(type == 'missed'){
			var missed_approach = me.route_manager.missed_approach;
			missed_approach.wp_count;
		} 
		elsif(type == 'current'){
			if(me.phase == 'G/A')
				me.route_manager.total_wp_count;
			else
				me.route_manager.wp_count;
		} else {
			var fp = me.getFlightPlanByType(type);
			(fp != nil ? fp.getPlanSize() : 0);
		}
	},
	getWP: func(fpNum, idx){
		if(me.route_manager.sequencing or me.updating) return nil;
		var type = me.getFlightPlanType(fpNum);
		if(type == nil) return 0;
		if(type != 'missed'){
			var fp = me.getFlightPlanByType(type);
			(fp != nil ? fp.getWP(idx) : nil);
		} else {
			var fp = me.plans['current'];
			var missed_approach = me.route_manager.missed_approach;
			var offset = missed_approach.first_wp.index;
			fp.getWP(offset + idx);
		}
	},
	getPlanModeWP: func(idx){
		if(me.route_manager.sequencing or me.updating) return me.plan_wp_info;
		var wp = mcdu.f_pln.get_wp(idx);
		if(wp != nil){
			me.plan_wp_info = {
				id: wp.id,
				wp_lat: wp.wp_lat,
				wp_lon: wp.wp_lon
			};
		}
		return wp;
	},
	getListeners: func(){
		var rm = fmgc.RouteManager;
		[
			me.route_manager.getSignal(rm.SIGNAL_FP_COPY),
			me.route_manager.getSignal(rm.SIGNAL_FP_CREATED),
			me.route_manager.getSignal(rm.SIGNAL_FP_DEL),
			me.route_manager.getSignal(rm.SIGNAL_FP_EDIT),
			DISP_SEC_FPLN
		]
	},
	shouldUpdate: func(){
		!me.route_manager.sequencing and !me.updating;
	},
	hasDiscontinuity: func(fpNum, wptID){
		if(me.route_manager.sequencing) return 0;
		var type = me.getFlightPlanType(fpNum);
		me.route_manager.hasDiscontinuity(wptID, type);
	}
};