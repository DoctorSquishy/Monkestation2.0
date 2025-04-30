/obj/effect/decal/nuclear_waste
	name = "Plutonium sludge"
	desc = "A writhing pool of heavily irradiated, spent reactor fuel. A shovel should clear it up! Just sprinkle a little graphite on it, it will be fine. though you probably shouldn't step through this..."
	icon = 'monkestation/icons/obj/machines/reactor/reactor_parts.dmi'
	icon_state = "nuclearwaste"
	alpha = 150
	light_color = LIGHT_COLOR_GREEN
	color = "#ff9eff"
	var/random_icon_states = list("waste1")

/obj/effect/decal/nuclear_waste/Initialize(mapload)
	. = ..()
	for(var/obj/A in get_turf(src))
		if(istype(A, /obj/structure))
			qdel(src) //It is more processing efficient to do this here rather than when searching for available turfs.
	set_light(1)
	START_PROCESSING(SSobj, src)

/obj/effect/decal/nuclear_waste/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/decal/nuclear_waste/process(delta_time)
	if(prob(10)) // woah there, don't overload the radiation subsystem
		radiation_pulse(
			src,
			max_range = 2,
			threshold = RAD_LIGHT_INSULATION,
			chance = URANIUM_IRRADIATION_CHANCE,
			minimum_exposure_time = 1 SECONDS,
			intensity = 1000
		)

/obj/effect/decal/nuclear_waste/epicenter/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = .proc/on_entered,
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/decal/nuclear_waste/proc/on_entered(datum/source, atom/movable/atom_movable)
	SIGNAL_HANDLER
	if(isliving(atom_movable))
		var/mob/living/living_mob = atom_movable
		playsound(loc, 'sound/effects/footstep/gib_step.ogg', HAS_TRAIT(living_mob, TRAIT_LIGHT_STEP) ? 20 : 50, 1)
		radiation_pulse(
			src,
			max_range = 1,
			threshold = RAD_LIGHT_INSULATION,
			chance = URANIUM_IRRADIATION_CHANCE,
			minimum_exposure_time = 0 SECONDS,
			intensity = 200
		)

/obj/effect/decal/nuclear_waste/epicenter/process()
	if(prob(10)) // woah there, don't overload the radiation subsystem
		radiation_pulse(
			src,
			max_range = 1,
			threshold = RAD_LIGHT_INSULATION,
			chance = URANIUM_IRRADIATION_CHANCE,
			minimum_exposure_time = 1 SECONDS,
			intensity = 1000
		)

/obj/effect/decal/nuclear_waste/attackby(obj/item/tool, mob/user)
	if(tool.tool_behaviour == TOOL_SHOVEL)
		radiation_pulse(src, 1000, 5) //MORE RADS
		to_chat(user, "<span class='notice'>You start to clear [src]...</span>")
		if(tool.use_tool(src, user, 50, volume=100))
			to_chat(user, "<span class='notice'>You clear [src].</span>")
			qdel(src)
			return
	. = ..()

/obj/structure/reactor_corium
	name = "radioactive mass"
	desc = "A large mass of molten reactor fuel, sometimes called corium. If you can see it, you're probably close enough to receive a lethal dose of radiation."
	icon = 'monkestation/icons/obj/machines/reactor/reactor.dmi'
	icon_state = "reactor_corium"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	light_color = COLOR_FIRE_LIGHT_RED
	light_on = TRUE
	anchored = TRUE
	density = FALSE
	pixel_x = -32
	pixel_y = -32

	var/process = FALSE

/obj/structure/reactor_corium/Initialize(mapload)
	. = ..()
	if(process)
		START_PROCESSING(SSobj, src)

/obj/structure/reactor_corium/Destroy()
	if(process)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/reactor_corium/process(seconds_per_tick)
	if(prob(20)) // woah there, don't overload the radiation subsystem
		radiation_pulse(
			src,
			max_range = 3,
			threshold = RAD_MEDIUM_INSULATION,
			chance = URANIUM_IRRADIATION_CHANCE,
			minimum_exposure_time = 1 SECONDS,
			intensity = 15000
		)
