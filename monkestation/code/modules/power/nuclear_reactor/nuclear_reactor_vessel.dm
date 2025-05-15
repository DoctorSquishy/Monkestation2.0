/obj/machinery/atmospherics/components/quaternary/nuclear_reactor
	icon = 'monkestation/icons/obj/machines/reactor/nuclear_reactor.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor_map"
	name = "reactor vessel"
	desc = "a nuclear reactor core"

	critical_machine = TRUE
	idle_power_usage = 0
	vent_movement = NONE

	pipe_flags = PIPING_ONE_PER_TURF
	anchored = TRUE

	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	density = FALSE

	//Reactor Rod Slots
	var/list/conduits[9]

	/// The gasmix we just recently absorbed for nuclear reactions
	var/datum/gas_mixture/reactor_core_gasmix

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Initialize(mapload)
	. = ..()
	reactor_core_gasmix = new()
	reactor_core_gasmix.volume = 1000
	icon_state = "[base_icon_state]_build_3"

	// Sets up conduit slots for reactor rods to tell if the space is occupied
	for(var/i = 1 to 9)
		conduits[i] = FALSE // Initialize all conduits as inactive

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Destroy()
	SSair.stop_processing_machine(src)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/process_atmos()
	..()
	// Setup Pipe Connections to get gasses
	var/datum/gas_mixture/air1 = airs[1]
	var/datum/gas_mixture/air2 = airs[2]
	var/datum/gas_mixture/air3 = airs[3]
	var/datum/gas_mixture/air4 = airs[4]

	air1.equalize(reactor_core_gasmix)
	air2.equalize(reactor_core_gasmix)
	air3.equalize(reactor_core_gasmix)
	air4.equalize(reactor_core_gasmix)
	update_parents()


/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_icon(updates)
	. = ..()
	icon_state = "[base_icon_state]_build_3"


