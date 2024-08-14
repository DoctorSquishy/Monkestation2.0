/datum/reactor_meltdown/blowout

/datum/reactor_meltdown/blowout/can_select(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return (reactor.pressure >= REACTOR_PRESSURE_CRITICAL)


/datum/reactor_meltdown/blowout/meltdown_progress(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!..())
		return FALSE
	reactor.radio.talk_into(
		reactor,
		"WARNING: Reactor vessel pressure over safe operation point.",
		reactor.damage >= reactor.emergency_point ? reactor.emergency_channel : reactor.warning_channel
	)
	if(prob(1))
		effect_gas_leak_small(reactor)

	return TRUE

/datum/reactor_meltdown/blowout/meltdown_now(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	message_admins("Reactor [reactor] at [ADMIN_VERBOSEJMP(reactor)] triggered a nuclear reactor blowout.")
	reactor.investigate_log("triggered a nuclear reactor blowout.", INVESTIGATE_ENGINE)
	var/obj/effect/meltdown/blowout/blowout_effect = new(get_turf(reactor))
	playsound(reactor, 'sound/machines/airlock_alien_prying.ogg', 150, TRUE)
	sleep(4 SECONDS)
	playsound(reactor, 'monkestation/sound/effects/reactor/desert_shot.ogg', 80, TRUE, 50, 50, falloff_distance = 30)
	sleep(1 SECONDS)
	playsound(reactor, 'monkestation/sound/effects/reactor/desert_shot.ogg', 80, TRUE, 50, 50, falloff_distance = 30)
	effect_gas_leak_small(reactor)
	sleep(3 SECONDS)
	playsound(reactor, 'monkestation/sound/effects/reactor/explode.ogg', 80, FALSE, 50, 50, falloff_distance = 30)
	qdel(blowout_effect)
	reactor.slagged = TRUE
	effect_gas_leak_all(reactor)
	effect_irradiate(reactor)
	effect_nuclear_particles(reactor)
	effect_explosion(reactor)
	effect_emp(reactor)
	effect_corium_meltthrough(reactor)
	return ..()

/datum/reactor_meltdown/core_meltdown/overlays(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list()

/obj/effect/meltdown/blowout
	name = "Blowout"
	layer = ABOVE_OBJ_LAYER
	icon = 'monkestation/icons/obj/machines/reactor/reactor.dmi'
	icon_state = "meltdown_blowout"
	pixel_x = -32
	pixel_y = -32
