var defl = func(bug = 0, limit = 0, use_true_north = 0, heading_type = 'heading') {
    var heading = 0;
    if(!use_true_north)
        heading = getprop("orientation/"~heading_type~"-magnetic-deg");
    else 
        heading = getprop("orientation/"~heading_type~"-deg");
    var bugDeg = 0;

    while (bug < 0)
        bug += 360;
    while (bug > 360)
        bug -= 360;
    if (bug < limit)
        bug += 360;
    if (heading < limit)
        heading += 360;
    # bug is adjusted normally
    if (math.abs(heading - bug) < limit)
    {
        bugDeg = heading - bug;
    }
    elsif (heading - bug < 0)
    {
        # bug is on the far right
        if (math.abs(heading - bug + 360 >= 180))
            bugDeg = -limit;
        # bug is on the far left
        elsif (math.abs(heading - bug + 360 < 180))
            bugDeg = limit;
    }
    else
    {
        # bug is on the far right
        if (math.abs(heading - bug >= 180))
            bugDeg = -limit;
        # bug is on the far left
        elsif (math.abs(heading - bug < 180))
            bugDeg = limit;
    }

    return bugDeg;
}
    
var limit = func (defl, limit) {

	if (math.abs(defl) <= limit)
		return defl;
		
	elsif (defl < -1 * limit)
		return -1 * limit;
		
	else
		return limit;

}

var limit2 = func (value, limit) {

	if ((value >= 0) and (limit >= 0)) {
	
		if (value <= limit)
			return value;
		else
			return limit;
	
	} elsif ((value < 0) and (limit < 0)) {
	
		if (value >= limit)
			return value;
		else
			return limit;
	
	} else
		return 0;

}
