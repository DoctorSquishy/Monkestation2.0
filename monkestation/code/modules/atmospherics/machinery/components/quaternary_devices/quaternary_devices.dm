/obj/machinery/atmospherics/components/quaternary
	icon = 'icons/obj/atmospherics/components/trinary_devices.dmi'
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	initialize_directions = ALL_CARDINALS
	device_type = QUATERNARY
	layer = GAS_FILTER_LAYER
	pipe_flags = PIPING_ONE_PER_TURF
	vent_movement = NONE

/obj/machinery/atmospherics/components/quaternary/set_init_directions(init_dir)
	initialize_directions = initial(initialize_directions)

/obj/machinery/atmospherics/components/quaternary/get_node_connects()
	var/node1_connect = turn(dir, -180)
	var/node2_connect = turn(dir, -90)
	var/node3_connect = dir
	var/node4_connect = turn(dir, 90)
	return list(node1_connect, node2_connect, node3_connect, node4_connect)
