#define ICON_SPLIT world.icon_size/3
#define ICON_SPLIT_DOUBLE (world.icon_size/3)*2
#define ICON_SPLIT_TRIPLE world.icon_size
#define REACTOR_PROCESS_ENABLED

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor
	icon = 'monkestation/icons/obj/machines/reactor/nuclear_reactor.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor"
	name = "Reactor Core"
	desc = "a nuclear reactor core"

	critical_machine = TRUE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	vent_movement = NONE

	pipe_flags = PIPING_ONE_PER_TURF
	anchored = TRUE

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	layer = GAS_FILTER_LAYER
	density = FALSE
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	light_color = LIGHT_COLOR_CYAN

	/// The gasmix we just recently absorbed for nuclear reactions
	var/datum/gas_mixture/reactor_core_gasmix

	/// The list of gases mapped against their current comp.
	/// We use this to calculate different values the reactor uses, like power or heat resistance.
	/// Ranges from 0 to 1
	var/list/gas_percentage
	/// How much more waste heat the reactor generates
	var/gas_heat_mod = 0
	// Increases the amount of radiation
	var/gas_radioactivity_mod = 0
	// Increases control of criticality K
	var/gas_control_mod = 0
	// Gases ability to transfer heat to coolant
	var/gas_permeability_mod = 0
	// Gases effect on a fuel rod's fuel depletion
	var/gas_depletion_mod = 0

	//Amount of Fuels_rods in reactor
	var/list/fuel_rods = list()

	/// Disables the REACTOR's proccessing when set to REACTOR_PROCESS_DISABLED.
	/// Temporary disables the processing when it's set to REACTOR_PROCESS_TIMESTOP.
	/// Make sure gas_percentage isnt null if this is on REACTOR_PROCESS_DISABLED.
//	var/disable_process = REACTOR_PROCESS_ENABLED

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Initialize(mapload)
	. = ..()
	// Reactor Core starts with air from the local environment
	var/turf/local_turf = loc
	var/datum/gas_mixture/env = local_turf.return_air()
	reactor_core_gasmix = env?.remove_ratio(0.1) || new()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/LateInitialize()
	. = ..()
	// Reactor Core starts with air from the local environment
	var/turf/local_turf = loc
	var/datum/gas_mixture/env = local_turf.return_air()
	reactor_core_gasmix = env?.remove_ratio(0.1) || new()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Destroy()
	SSair.stop_processing_machine(src)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/attackby(obj/item/held_obj, mob/user, params)

	var/list/modifiers = params2list(params)
	var/icon_x = text2num(modifiers[ICON_X])
	var/icon_y = text2num(modifiers[ICON_Y])

	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT) // less than 10  less than 10
		to_chat(user, span_warning("Bottom Left"))
		return
	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT_DOUBLE) // less than 10 less than 20
		to_chat(user, span_warning("Middle Left"))
		return
	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT_TRIPLE) // less than 10 less than 30
		to_chat(user, span_warning("Top Left"))
		return

	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT)
		to_chat(user, span_warning("Bottom Middle"))
		return
	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT_DOUBLE)
		to_chat(user, span_warning("Middle Middle"))
		return
	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT_TRIPLE)
		to_chat(user, span_warning("Middle Top"))
		return

	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT)
		to_chat(user, span_warning("Bottom Right"))
		return
	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT_DOUBLE)
		to_chat(user, span_warning("Middle Right"))
		return
	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT_TRIPLE)
		to_chat(user, span_warning("Top Right"))
		return
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/process_atmos()
	..()
//	if(disable_process != REACTOR_PROCESS_ENABLED)
//		return

	// Setup Pipe Connections to get gasses
	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/datum/gas_mixture/air3 = airs[3]
	var/datum/gas_mixture/air4 = airs[4]

	//Equalizes each node with the reactor, next process it will equalize with waste gases and heat.
	air1.equalize(reactor_core_gasmix)
	air2.equalize(reactor_core_gasmix)
	air3.equalize(reactor_core_gasmix)
	air4.equalize(reactor_core_gasmix)
	update_parents()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_icon(updates)
	. = ..()
	icon_state = "[base_icon_state]"

#undef ICON_SPLIT
