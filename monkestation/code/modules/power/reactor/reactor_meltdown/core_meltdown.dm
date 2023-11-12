/datum/reactor_meltdown/core_meltdown

/datum/reactor_meltdown/core_meltdown/can_select(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return (reactor.temperature >= reactor.temp_limit)

/datum/reactor_meltdown/core_meltdown/meltdown_progress(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!..())
		return FALSE
	reactor.radio.talk_into(
		reactor,
		"Warning: Reactor core temperature over safe operation level.",
		reactor.damage >= reactor.emergency_point ? reactor.emergency_channel : reactor.warning_channel
	)
	var/list/messages = list(
		"A flash of blue light appeared in your peripherals...",
		"You hear a high-pitched ringing sound.",
		"You feel a warm tingling throughout your body.",
		"A intense sense of dread washes over you.",
	)
	for(var/mob/victim as anything in GLOB.player_list)
		to_chat(victim, span_danger(pick(messages)))

	return TRUE

/datum/reactor_meltdown/core_meltdown/meltdown_now(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	message_admins("Reactor [reactor] at [ADMIN_VERBOSEJMP(reactor)] triggered a reactor core meltdown.")
	reactor.investigate_log("triggered a reactor core meltdown.", INVESTIGATE_ENGINE)
	playsound('monkestation/sound/effects/reactor/meltdown.ogg', 100, extrarange=100, pressure_affected=FALSE, ignore_walls=TRUE)

	effect_irradiate(reactor)
	effect_nuclear_particles(reactor)
	effect_emp(reactor)
	effect_explosion(reactor)
	effect_corium_meltthrough(reactor)

	return ..()

/datum/reactor_meltdown/core_meltdown/examine(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list(span_bolddanger("The reactor's structure is emanating an intense heat and light!"))

/datum/reactor_meltdown/core_meltdown/overlays(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list()

/datum/reactor_meltdown/core_meltdown/lights(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	..()
	reactor.set_light_color(LIGHT_COLOR_INTENSE_RED)
