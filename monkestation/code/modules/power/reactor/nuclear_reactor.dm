/obj/machinery/atmospherics/components/quaternary/nuclear_reactor
	icon = 'icons/obj/atmospherics/components/trinary_devices.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor_map"

	name = ""
	desc = ""

	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	layer = GAS_FILTER_LAYER
	vent_movement = NONE
	pipe_flags = PIPING_ONE_PER_TURF
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	critical_machine = TRUE
	light_color = LIGHT_COLOR_CYAN
	dir = 8
