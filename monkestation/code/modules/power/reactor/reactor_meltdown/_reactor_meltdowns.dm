/// Follows same pattern as Supermatter for consitency
/// Priority is top to bottom.
GLOBAL_LIST_INIT(reactor_meltdown_list, list(
	/datum/reactor_meltdown/core_meltdown = new /datum/reactor_meltdown/core_meltdown,
	/datum/reactor_meltdown/blowout = new /datum/reactor_meltdown/blowout
))

/// Logic holder for reactor meltdown
/// Selected by [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/set_meltdown]
/datum/reactor_meltdown

/// Whether we are eligible for this meltdown or not. TRUE if valid, FALSE if not.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/set_meltdown]
/datum/reactor_meltdown/proc/can_select(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return FALSE

#define ROUNDCOUNT_ENGINE_JUST_EXPLODED 0
/// Called when the count down has been finished, do the nasty work
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/countdown]
/datum/reactor_meltdown/proc/meltdown_now(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if (reactor.is_main_engine)
		SSpersistence.rounds_since_engine_exploded = ROUNDCOUNT_ENGINE_JUST_EXPLODED
		for (var/obj/structure/sign/delamination_counter/sign as anything in GLOB.map_delamination_counters)
			sign.update_count(ROUNDCOUNT_ENGINE_JUST_EXPLODED)
	qdel(reactor)
#undef ROUNDCOUNT_ENGINE_JUST_EXPLODED

/// Whatever we're supposed to do when a meltdown is currently in progress.
/// Mostly just to tell people how useless engi is, and play some alarm sounds.
/// Returns TRUE if we just told people a meltdown is going on. FALSE if its healing or we didnt say anything.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/process_atmos]
/datum/reactor_meltdown/proc/meltdown_progress(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(reactor.damage <= reactor.warning_point) // Damage is too low, lets not
		return FALSE

	if (reactor.damage >= reactor.emergency_point && reactor.damage_archived < reactor.emergency_point)
		reactor.investigate_log("has entered the emergency point.", INVESTIGATE_ENGINE)
		message_admins("[reactor] has entered the emergency point [ADMIN_VERBOSEJMP(reactor)].")

	if((REALTIMEOFDAY - reactor.lastwarning) < REACTOR_WARNING_DELAY)
		return FALSE
	reactor.lastwarning = REALTIMEOFDAY

	switch(reactor.get_status())
		if(REACTOR_MELTDOWN)
			playsound(reactor, 'monkestation/sound/effects/reactor/reactor_alert_3.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
			if(!reactor.meltdown_alarm)
				reactor.meltdown_alarm = new(reactor, TRUE)
		if(REACTOR_EMERGENCY)
			playsound(reactor, 'sound/machines/engine_alert2.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
			if(reactor.meltdown_alarm)
				QDEL_NULL(reactor.meltdown_alarm)
		if(REACTOR_DANGER)
			playsound(reactor, 'sound/machines/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
			playsound(reactor, 'monkestation/sound/effects/reactor/reactor_alert_2.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
			if(reactor.meltdown_alarm)
				QDEL_NULL(reactor.meltdown_alarm)
		if(REACTOR_WARNING)
			playsound(reactor, 'sound/machines/terminal_alert.ogg', 75)
			playsound(reactor, 'monkestation/sound/effects/reactor/reactor_alert_1.ogg', 75)
			if(reactor.meltdown_alarm)
				QDEL_NULL(reactor.meltdown_alarm)
	if(reactor.damage < reactor.damage_archived) // Healing
		reactor.radio.talk_into(reactor,"Reactor returning to safe operating parameters. Integrity: [round(reactor.get_integrity_percent(), 0.01)]%", reactor.damage_archived >= reactor.emergency_point ? reactor.emergency_channel : reactor.warning_channel)
		return FALSE

	if(reactor.damage >= reactor.emergency_point) // Taking damage, in emergency
		reactor.radio.talk_into(reactor, "REACTOR MELTDOWN IMMINENT Integrity: [round(reactor.get_integrity_percent(), 0.01)]%", reactor.emergency_channel)
		reactor.lastwarning = REALTIMEOFDAY - (REACTOR_WARNING_DELAY / 2) // Cut the time to next announcement in half.
	else // Taking damage, in warning
		reactor.radio.talk_into(reactor, "Danger! Reactor structural integrity faltering! Integrity: [round(reactor.get_integrity_percent(), 0.01)]%", reactor.warning_channel)

	SEND_SIGNAL(reactor, COMSIG_REACTOR_MELTDOWN_ALARM)
	return TRUE

/// Called when a reactor switches it's strategy from another one to us.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/set_meltdown]
/datum/reactor_meltdown/proc/on_select(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return

/// Called when a reactor switches it's strategy from us to something else.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/set_meltdown]
/datum/reactor_meltdown/proc/on_deselect(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return

/// Added to an examine return value.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/examine]
/datum/reactor_meltdown/proc/examine(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list()

/// Add whatever overlay to the reactor.
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_overlays]
/datum/reactor_meltdown/proc/overlays(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return list()

// Change how reactor lights and color
/// [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/process_atmos]
/datum/reactor_meltdown/proc/lights(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	reactor.set_light(
		l_outer_range = ROUND_UP(clamp(reactor.temperature / 500, 4, 10)),
		l_power = ROUND_UP(clamp(reactor.temperature / 1000, 1, 5)),
		l_color = reactor.gas_heat_mod > 0.8 ? LIGHT_COLOR_ORANGE : LIGHT_COLOR_CYAN,
		l_on = reactor.temperature > REACTOR_TEMPERATURE_OPERATING
	)

/// Returns a set of messages to be spouted during meltdowns
/// First message is start of count down, second message is quitting of count down (if reactor healed), third is 5 second intervals
/datum/reactor_meltdown/proc/count_down_messages(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	var/list/messages = list()
	messages += "REACTOR MELTDOWN IMMINENT. The reactor integrity has reached critical failure point. Engaging EPIS systems. Please engage SCARM protocols"
	messages += "Reactor returning to safe operating parameters. EPIS systems have been disengaged."
	messages += "remain before meltdown."
	return messages
