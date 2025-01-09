/obj/machinery/atmospherics/components/quaternary
	icon = 'icons/obj/atmospherics/components/trinary_devices.dmi'
	dir = SOUTH
	use_power = IDLE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	device_type = QUATERNARY
	layer = GAS_FILTER_LAYER
	pipe_flags = PIPING_ONE_PER_TURF
	vent_movement = NONE

/obj/machinery/atmospherics/components/quaternary/set_init_directions(init_dir)
	if(init_dir)
		initialize_directions = init_dir
	else
		initialize_directions = ALL_CARDINALS
