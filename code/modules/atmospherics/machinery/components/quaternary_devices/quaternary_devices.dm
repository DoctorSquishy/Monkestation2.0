/obj/machinery/atmospherics/components/quaternary
	dir = SOUTH
	initialize_directions = SOUTH|NORTH|WEST|EAST
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	device_type = QUATERNARY
	layer = GAS_FILTER_LAYER
	pipe_flags = PIPING_ONE_PER_TURF
	vent_movement = NONE


/obj/machinery/atmospherics/components/quaternary/set_init_directions()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|NORTH|SOUTH|WEST
		if(SOUTH)
			initialize_directions = SOUTH|WEST|NORTH|EAST
		if(EAST)
			initialize_directions = EAST|WEST|SOUTH|NORTH
		if(WEST)
			initialize_directions = WEST|NORTH|EAST|SOUTH


/obj/machinery/atmospherics/components/quaternary/get_node_connects()
	var/node1_connect = turn(dir, -180)
	var/node2_connect = turn(dir, -90)
	var/node3_connect = dir
	var/node4_connect = turn(dir, 90)
	return list(node1_connect, node2_connect, node3_connect, node4_connect)
