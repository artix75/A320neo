var mcdu_tree = "/instrumentation/mcdu/";
var lr_tree = mcdu_tree~ "lat_rev/";

var lat_rev = {

	revise : func (id) {
	
		setprop(mcdu_tree~ "page", "lat_rev");
		
		setprop(lr_tree~ "name", getprop(rm_route~ "route/wp[" ~ id ~ "]/id"));
		
		setprop(lr_tree~ "id", id);
		
		var wp_lat = getprop(rm_route~ "route/wp[" ~ id ~ "]/latitude-deg");
		
		var wp_lon = getprop(rm_route~ "route/wp[" ~ id ~ "]/longitude-deg");
		
		var wp_pos_str = me.pos_str(wp_lat, wp_lon);
		
		setprop(lr_tree~ "pos-string", wp_pos_str);
		
		if (id == 0)
			setprop(lr_tree~ "dep", 1);
		else
			setprop(lr_tree~ "dep", 0);
	
		setprop(lr_tree~ "arr", 0);
	
	},
	
	revise_dest : func {
	
		setprop(mcdu_tree~ "page", "lat_rev");
		
		setprop(lr_tree~ "name", getprop(rm_route~ "destination/airport"));
		
		var num = getprop(rm_route~ "route/num");
		
		var last_id = num - 1;
		
		var wp_lat = getprop(rm_route~ "route/wp[" ~ last_id ~ "]/latitude-deg");
		
		var wp_lon = getprop(rm_route~ "route/wp[" ~ last_id ~ "]/longitude-deg");
		
		var wp_pos_str = me.pos_str(wp_lat, wp_lon);
		
		setprop(lr_tree~ "pos-string", wp_pos_str);
		
		setprop(lr_tree~ "arr", 1);
		
		setprop(lr_tree~ "dep", 0);
	
	},
	
	pos_str : func (wp_lat, wp_lon) {
	
		var wp_lat_abs = math.abs(wp_lat);
		
		var wp_lon_abs = math.abs(wp_lon);
		
		var wp_lat_l = "";
		
		var wp_lon_l = "";
		
		if (wp_lat >= 0)
			wp_lat_l = "N";
		else
			wp_lat_l = "S";
			
		if (wp_lon >= 0)
			wp_lon_l = "E";
		else
			wp_lon_l = "W";
			
		var wp_lat_int = int(wp_lat_abs);
		
		var wp_lon_int = int(wp_lon_abs);
		
		var wp_lat_dec = int(int(wp_lat_abs * 100000) - (wp_lat_int * 100000));
		
		var wp_lon_dec = int(int(wp_lon_abs * 100000) - (wp_lon_int * 100000));
		
		var wp_pos_str = wp_lat_int ~ "*" ~ wp_lat_dec ~ wp_lat_l ~ "/" ~ wp_lon_int ~ "*" ~ wp_lon_dec ~ wp_lon_l;
		
		return wp_pos_str;
	
	},
	
	new_dest : func (id, name) {
	
		setprop(rm_route~ "input", "@INSERT" ~ (id + 1) ~ ":" ~ name);
		
		setprop(rm_route~ "destination/airport", name);
	
	},
	
	next_wp : func (id, name) {
	
		setprop(rm_route~ "input", "@INSERT" ~ (id + 1) ~ ":" ~ name);
		
		setprop(rm_route~ "route/wp[" ~ (id + 1) ~ "]/ias-mach", 0);
	
	},
	
	rm_wp : func (id) {
	
		setprop(rm_route~ "input", "@DELETE" ~ id);
	
	}
	
	# Holding is managed separately
 
};
