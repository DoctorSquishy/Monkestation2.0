/obj/machinery/atmospherics/components/quaternary/nuclear_reactor
	icon = 'monkestation/icons/obj/machines/reactor/nuclear_reactor.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor_map"
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

	/// Disables the REACTOR's proccessing totally when set to REACTOR_PROCESS_DISABLED.
	/// Temporary disables the processing when it's set to REACTOR_PROCESS_TIMESTOP.
	/// Make sure gas_percentage isnt null if this is on REACTOR_PROCESS_DISABLED.
	var/disable_process = REACTOR_PROCESS_DISABLED

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Initialize(mapload)
	. = ..()
	// Reactor Core starts with air from the local environment
	var/turf/local_turf = loc
	var/datum/gas_mixture/env = local_turf.return_air()
	reactor_core_gasmix = env?.remove_ratio(0.25) || new()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Destroy()
	SSair.stop_processing_machine(src)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/process_atmos(seconds_per_tick)
	..()
	if(disable_process != REACTOR_PROCESS_ENABLED)
		return

	// Setup Pipe Connections to get gasses
	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/datum/gas_mixture/air3 = airs[3]
	var/datum/gas_mixture/air4 = airs[4]

	//Equalizes each node with the reactor, next process it will equalize with waste gases and heat.
	if(air1.temperature)
		air1.equalize(reactor_core_gasmix)
	if(air2.temperature)
		air2.equalize(reactor_core_gasmix)
	if(air3.temperature)
		air3.equalize(reactor_core_gasmix)
	if(air4.temperature)
		air4.equalize(reactor_core_gasmix)
	update_parents()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_icon(updates)
	. = ..()
	icon_state = "[base_icon_state]"
