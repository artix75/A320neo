var terr = "/instrumentation/terrain-map/";

var row = 0;

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.016774532925;

var get_elevation = func (lat, lon) {

	var info = geodinfo(lat, lon);
	if (info != nil) {var elevation = info[0] * 3.2808399;}
	else {var elevation = -1.0; }

	return elevation;
};

var set_elev_prop = func (row, col, elev) {

	setprop(terr~ "terrain/row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", elev);

};

var get_elev_prop = func (row, col) {

	return getprop(terr~ "terrain/row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft");

};


# There're 29 rows and columns on the terrain map, the nasal script gets elevations for around a fourth of the points (that includes the edges) and interpolates the rest

var terrain_map = func {

	var heading = getprop("/orientation/heading-deg");
	
	var range = getprop("/instrumentation/nd[1]/range");
	
	if (row == 0) {
	
		for (var col = 1; col <= 29; col += 2) {
		
			set_elev_prop(row, col, get_elev(row, col, range, heading));
		
		}
		
		for (var col = 2; col < 29; col += 2) {
		
			set_elev_prop(row, col, interpolate_col(row, col));
		
		}
	
		row = 2;
	
	} else {
	
		for (var col = 1; col <= 29; col += 2) {
		
			set_elev_prop(row, col, get_elev(row, col, range, heading));
		
		}
		
		for (var col = 2; col < 29; col += 2) {
		
			set_elev_prop(row, col, interpolate_col(row, col));
		
		}
		
		for (var col = 1; col <= 29; col += 1) {
		
			set_elev_prop(row - 1, col, interpolate_row(row - 1, col));
		
		}
	
		row += 2;
	
	}

	if (row > 29) {
	
		row = 0;
	
	}

};

var get_elev = func (row, col, range, hdg) {

	var x = (col - 14) * (range / 14);
	var y = (row - 14) * (range / 14);
	
	var pos = geo.aircraft_position();
	
	pos.apply_course_distance(hdg, (y * 1852));
	
	pos.apply_course_distance((hdg + 90), (x * 1852));
	
	return get_elevation(pos.lat(), pos.lon());

};

var interpolate_col = func (row, col) {

	var last_elev = get_elev_prop(row, col - 1);
	
	var next_elev = get_elev_prop(row, col + 1);
	
	if (last_elev != nil and next_elev != nil)
	
		return (last_elev + next_elev) / 2;
		
	else
	
		return 0;

};

var interpolate_row = func (row, col) {

	var last_elev = get_elev_prop(row - 1, col);
	
	var next_elev = get_elev_prop(row + 1, col);
	
	if (last_elev != nil and next_elev != nil)
	
		return (last_elev + next_elev) / 2;
		
	else
	
		return 0;

};

