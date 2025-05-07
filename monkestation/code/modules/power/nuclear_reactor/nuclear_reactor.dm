#define ICON_SPLIT world.icon_size/3
#define ICON_SPLIT_DOUBLE (world.icon_size/3)*2
#define ICON_SPLIT_TRIPLE world.icon_size

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor
	icon = 'monkestation/icons/obj/machines/reactor/nuclear_reactor.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor"
	name = "reactor vessel"
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

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Initialize(mapload)
	. = ..()
	reactor_core_gasmix = new()
	reactor_core_gasmix.volume = 1000

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/Destroy()
	SSair.stop_processing_machine(src)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/attackby(obj/item/held_obj, mob/user, params)
	var/list/modifiers = params2list(params)
	if(istype(held_obj, /obj/item/crowbar))
		select_rod(modifiers, user)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/select_rod(modifiers, user)
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
	icon_state = "[base_icon_state]"

#undef ICON_SPLIT
