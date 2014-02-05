var root = getprop("/sim/aircraft-dir");

# Company Routes Database (Database/Company/routes.xml)

io.read_properties(root ~ "/Database/Company/routes.xml", "/database/co_routes");

# Terminal Procedures Database (SIDs/STARs/IAPs) (Database/Procedures/icao.xml)

# GPS Navaids Database (Database/Navaids/navdata.xml)
