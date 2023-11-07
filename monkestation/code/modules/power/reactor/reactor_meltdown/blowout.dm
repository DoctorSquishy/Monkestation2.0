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

	effect_gas_leak_small(reactor)

	return TRUE

/datum/reactor_meltdown/blowout/meltdown_now(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	message_admins("Reactor [reactor] at [ADMIN_VERBOSEJMP(reactor)] triggered a nuclear reactor blowout.")
	reactor.investigate_log("triggered a nuclear reactor blowout.", INVESTIGATE_ENGINE)
	playsound(src, 'monkestation/sound/effects/reactor/explode.ogg', 80, FALSE, 50, 50, falloff_distance = 30)
	effect_irradiate(reactor)
	effect_nuclear_particles(reactor)
	effect_emp(reactor)
	effect_explosion(reactor)
	effect_corium_meltthrough(reactor)
	effect_gas_leak_all(reactor)
	return ..()

/datum/reactor_meltdown/core_meltdown/overlays(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list()
