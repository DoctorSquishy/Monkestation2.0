
/// Explodes
/datum/reactor_meltdown/proc/effect_explosion(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor, avoid)
	var/explosion_power = reactor.explosion_power
	var/power_scaling = reactor.absorbed_gasmix.return_pressure()
	var/turf/reactor_turf = get_turf(reactor)
	//Dear mappers, balance the reactor max explosion radius to 17.5, 37, 39, 41
	explosion(origin = reactor_turf,
		devastation_range = explosion_power * max(power_scaling, 0.205) * 0.5,
		heavy_impact_range = explosion_power * max(power_scaling, 0.205) + 2,
		light_impact_range = explosion_power * max(power_scaling, 0.205) + 4,
		flash_range = explosion_power * max(power_scaling, 0.205) + 6,
		adminlog = TRUE,
		ignorecap = TRUE
	)
	return TRUE

/// Scatters nuclear waste over the event spawns as long as they are at least 30 tiles away from whatever we want to avoid.
/datum/reactor_meltdown/proc/effect_nuclear_waste(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor, avoid)
	new /obj/effect/decal/nuclear_waste(get_turf(reactor))
	var/list/possible_spawns = GLOB.generic_event_spawns.Copy()
	for(var/i in 1 to rand(4,6))
		var/spawn_location
		do
			spawn_location = pick_n_take(possible_spawns)
		while(get_dist(spawn_location, avoid) < 30)
		new /obj/effect/decal/nuclear_waste(get_turf(spawn_location))

/// Irradiates mobs around 20 tiles of the reactor.
/datum/reactor_meltdown/proc/effect_irradiate(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	var/turf/reactor_turf = get_turf(reactor)
	for (var/mob/living/victim in range(DETONATION_RADIATION_RANGE, reactor))
		if(!is_valid_z_level(get_turf(victim), reactor_turf))
			continue
		if(victim.z == 0)
			continue
		SSradiation.irradiate(victim)
	return TRUE

//Fire Nuclear Particles based off of radioactivity and reactor integrity
/datum/reactor_meltdown/proc/effect_nuclear_particles(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	reactor.fire_nuclear_particle()

//Electronics don't like radiation
/datum/reactor_meltdown/proc/effect_emp(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	for(var/obj/machinery/power/apc/apc in GLOB.apcs_list)
		if(prob(40))
			apc.overload_lighting()

// Seems some gas connections are leaking
/datum/reactor_meltdown/proc/effect_gas_leak_small(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	var/turf/reactor_turf = get_turf(reactor)
	reactor.Shake(3, 3, 2 SECONDS)
	playsound(reactor, 'sound/machines/clockcult/steam_whoosh.ogg', 100, TRUE)

	var/datum/gas_mixture/coolant_input = reactor.airs[1]
	var/datum/gas_mixture/moderator_input = reactor.airs[2]
	var/datum/gas_mixture/coolant_output = reactor.airs[3]

	reactor_turf.assume_air(coolant_input*0.1)
	reactor_turf.assume_air(moderator_input*0.1)
	reactor_turf.assume_air(coolant_output*0.1)

// Leak all the gas from the pipes
/datum/reactor_meltdown/proc/effect_gas_leak_all(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	var/turf/reactor_turf = get_turf(reactor)
	reactor.Shake(3, 3, 2 SECONDS)
	playsound(reactor, 'sound/machines/clockcult/steam_whoosh.ogg', 100, TRUE)

	var/datum/gas_mixture/coolant_input = reactor.airs[1]
	var/datum/gas_mixture/moderator_input = reactor.airs[2]
	var/datum/gas_mixture/coolant_output = reactor.airs[3]

	reactor_turf.assume_air(coolant_input)
	reactor_turf.assume_air(moderator_input)
	reactor_turf.assume_air(coolant_output)

/datum/reactor_meltdown/proc/effect_corium_meltthrough(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	var/turf/reactor_turf = get_turf(reactor)
	var/turf/lower_turf = GET_TURF_BELOW(reactor_turf)
	if(lower_turf) // reactor fuel will melt down into the lower levels on multi-z maps like icemeta
		new /obj/structure/reactor_corium(lower_turf)
		var/turf/lowest_turf = GET_TURF_BELOW(lower_turf)
		if(lowest_turf) // WE NEED TO GO DEEPER
			new /obj/structure/reactor_corium(lower_turf)

/// For extreme level nuclear accidents that end the round
/// Set security level to delta, enable maint all access, and turn emergency lights on.
/datum/reactor_meltdown/proc/effect_emergency_state()
	if(SSsecurity_level.get_current_level_as_number() != SEC_LEVEL_DELTA)
		SSsecurity_level.set_level(SEC_LEVEL_DELTA) // skip the announcement and shuttle timer adjustment in set_security_level()
	make_maint_all_access()
	for(var/obj/machinery/light/light_to_break in GLOB.machines)
		if(prob(35))
			light_to_break.set_major_emergency_light()
			continue
		light_to_break.break_light_tube()

/// Spawn an evacuation rift for people to go through. For the extra spicy nuclear accidents.
/datum/reactor_meltdown/proc/effect_evac_rift_start()
	var/obj/cascade_portal/rift = new /obj/cascade_portal(get_turf(pick(GLOB.generic_event_spawns)))
	priority_announce("We have been hit by a sector-wide electromagnetic pulse. All of our systems are heavily damaged, including those \
		required for shuttle navigation. We can only reasonably conclude that a nuclear meltdown is occurring on or near your station.\n\n\
		Evacuation is no longer possible by conventional means; however, we managed to open a rift near the [get_area_name(rift)]. \
		All personnel are hereby required to enter the rift by any means available.\n\n\
		[Gibberish("Retrieval of survivors will be conducted upon recovery of necessary facilities.", FALSE, 5)] \
		[Gibberish("Good luck--", FALSE, 25)]")
	return rift


/// Announce the destruction of the rift and end the round.
/datum/reactor_meltdown/proc/effect_evac_rift_end()
	priority_announce("[Gibberish("The rift has been destroyed, we can no longer help you.", FALSE, 5)]")

	sleep(25 SECONDS)

	priority_announce("Reports indicate formation of crystalline seeds following resonance shift event. \
		Rapid expansion of crystal mass proportional to rising gravitational force. \
		Matter collapse due to gravitational pull foreseeable.",
		"Nanotrasen Star Observation Association")

	sleep(25 SECONDS)

	priority_announce("[Gibberish("All attempts at evacuation have now ceased, and all assets have been retrieved from your sector.\n \
		To the remaining survivors of [station_name()], farewell.", FALSE, 5)]")

	if(SSshuttle.emergency.mode == SHUTTLE_ESCAPE)
		// special message for hijacks
		var/shuttle_msg = "Navigation protocol set to [SSshuttle.emergency.is_hijacked() ? "\[ERROR\]" : "backup route"]. \
			Reorienting bluespace vessel to exit vector. ETA 15 seconds."
		// garble the special message
		if(SSshuttle.emergency.is_hijacked())
			shuttle_msg = Gibberish(shuttle_msg, TRUE, 15)
		minor_announce(shuttle_msg, "Emergency Shuttle", TRUE)
		SSshuttle.emergency.setTimer(15 SECONDS)
		return

	sleep(10 SECONDS)

	SSticker.news_report = SUPERMATTER_CASCADE //PLACEHOLDER
	SSticker.force_ending = TRUE
