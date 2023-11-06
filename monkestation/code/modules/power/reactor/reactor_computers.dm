#define FREQ_REACTOR_CONTROL 1439.69


//Controlling the reactor.
/obj/machinery/computer/reactor
	name = "Reactor control console"
	desc = "You should not be able to see this Reactor control console description, please report as issue."
	light_power = 1
	icon_state = "oldcomp"
	icon_screen = "library"
	icon_keyboard = null
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor = null
	var/id = "default_reactor_for_mappers"

/obj/machinery/computer/reactor/Initialize(mapload, obj/item/circuitboard/item_circuitboard)
	. = ..()
	addtimer(CALLBACK(src, .proc/link_to_reactor), 10 SECONDS)

/obj/machinery/computer/reactor/proc/link_to_reactor()
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor_id in GLOB.machines)
		if(reactor_id.uid && reactor_id.uid == id)
			reactor = reactor_id
			return TRUE
	return FALSE

/obj/machinery/computer/reactor/control_rods
	name = "Control rod management computer"
	desc = "A computer which can remotely raise / lower the control rods of a reactor."
	icon_screen = "reactor_rods"

/obj/machinery/computer/reactor/control_rods/attack_hand(mob/living/user)
	. = ..()
	ui_interact(user)

/obj/machinery/computer/reactor/control_rods/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/reactor/control_rods/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorControlRods")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/reactor/control_rods/ui_act(action, params)
	if(..())
		return
	if(!reactor)
		return
	if(action == "input")
		var/input = text2num(params["target"])
		reactor.desired_k = clamp(input, 0, 3)

/obj/machinery/computer/reactor/control_rods/ui_data(mob/user)
	var/list/data = list()
	data["control_rods"] = 0
	data["k"] = 0
	data["desiredK"] = 0
	if(reactor)
		data["k"] = reactor.K
		data["desiredK"] = reactor.desired_k
		data["control_rods"] = 100 - (reactor.desired_k / 3 * 100) //Rod insertion is extrapolated as a function of the percentage of K
	return data

/obj/machinery/computer/reactor/stats
	name = "Reactor Statistics Console"
	desc = "A console for monitoring the statistics of a nuclear reactor."
	icon_screen = "reactor_stats"
	var/next_stat_interval = 0
	var/list/pressureData = list()
	var/list/powerData = list()
	var/list/tempInputData = list()
	var/list/tempOutputdata = list()

/obj/machinery/computer/reactor/stats/attack_hand(mob/living/user)
	. = ..()
	ui_interact(user)

/obj/machinery/computer/reactor/stats/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/computer/reactor/stats/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorStats")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/reactor/stats/process()
	if(world.time >= next_stat_interval)
		next_stat_interval = world.time + 1 SECONDS //You only get a slow tick.
		pressureData += (reactor) ? reactor.pressure : 0
		if(pressureData.len > 100) //Only lets you track over a certain timeframe.
			pressureData.Cut(1, 2)
		tempInputData += (reactor) ? reactor.last_coolant_temperature : 0 //We scale up the figure for a consistent:tm: scale
		if(tempInputData.len > 100) //Only lets you track over a certain timeframe.
			tempInputData.Cut(1, 2)
		tempOutputdata += (reactor) ? reactor.last_output_temperature : 0 //We scale up the figure for a consistent:tm: scale
		if(tempOutputdata.len > 100) //Only lets you track over a certain timeframe.
			tempOutputdata.Cut(1, 2)

/obj/machinery/computer/reactor/stats/ui_data(mob/user)
	var/list/data = list()
	data["powerData"] = powerData
	data["pressureData"] = pressureData
	data["tempInputData"] = tempInputData
	data["tempOutputdata"] = tempOutputdata
	data["coolantInput"] = reactor ? reactor.last_coolant_temperature : 0
	data["coolantOutput"] = reactor ? reactor.last_output_temperature : 0
	data["reactorPressure"] = reactor ? reactor.pressure : 0
	data["pressureMax"] = REACTOR_PRESSURE_CRITICAL
	data["temperatureMax"] = reactor.temp_limit
	return data

//Preset pumps for mappers. You can also set the id tags yourself.
/obj/machinery/atmospherics/components/binary/pump/reactor_input
	var/id = "reactor_input"
	var/frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_output
	var/id = "reactor_output"
	var/frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_moderator
	var/id = "reactor_moderator"
	var/frequency = FREQ_REACTOR_CONTROL

/obj/machinery/computer/reactor/pump
	name = "Reactor inlet valve computer"
	desc = "A computer which controls valve settings on an advanced gas cooled reactor. Alt click it to remotely set pump pressure."
	icon_screen = "reactor_input"
	id = "reactor_input"
	var/datum/radio_frequency/radio_connection
	var/on = FALSE

/obj/machinery/computer/reactor/pump/AltClick(mob/user)
	. = ..()
	var/newPressure = input(user, "Set new output pressure (kPa)", "Remote pump control", null) as num
	if(!newPressure)
		return
	//Number sanitization is not handled in the pumps themselves, only during their ui_act which this doesn't use.
	newPressure = clamp(newPressure, 0, MAX_OUTPUT_PRESSURE)
	signal(on, newPressure) //Number sanitization is handled on the actual pumps themselves.

/obj/machinery/computer/reactor/attack_robot(mob/user)
	. = ..()
	attack_hand(user)

/obj/machinery/computer/reactor/attack_ai(mob/user)
	. = ..()
	attack_hand(user)

/obj/machinery/computer/reactor/pump/attack_hand(mob/living/user)
	. = ..()
	if(!is_operational)
		return FALSE
	playsound(loc, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
	visible_message("<span class='notice'>[src]'s switch flips [on ? "off" : "on"].</span>")
	on = !on
	signal(on)

/obj/machinery/computer/reactor/pump/Initialize(mapload, obj/item/circuitboard/item_circuitboard)
	. = ..()
	radio_connection = SSradio.add_object(src, FREQ_REACTOR_CONTROL,filter=RADIO_CHANNEL_ENGINEERING)

/obj/machinery/computer/reactor/pump/proc/signal(power, set_output_pressure=null)
	var/datum/signal/signal
	if(!set_output_pressure) //Yes this is stupid, but technically if you pass through "set_output_pressure" onto the signal, it'll always try and set its output pressure and yeahhh...
		signal = new(list(
			"tag" = id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"sigtype" = "command"
		))
	else
		signal = new(list(
			"tag" = id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"set_output_pressure" = set_output_pressure,
			"sigtype" = "command"
		))
	radio_connection.post_signal(src, signal, filter=RADIO_CHANNEL_ENGINEERING)

//Preset subtypes for mappers
/obj/machinery/computer/reactor/pump/reactor_input
	name = "Reactor inlet valve computer"
	icon_screen = "reactor_input"
	id = "reactor_input"

/obj/machinery/computer/reactor/pump/reactor_output
	name = "Reactor output valve computer"
	icon_screen = "reactor_output"
	id = "reactor_output"

/obj/machinery/computer/reactor/pump/reactor_moderator
	name = "Reactor moderator valve computer"
	icon_screen = "reactor_moderator"
	id = "reactor_moderator"

//Monitoring programs
/datum/computer_file/program/reactor_monitor
	filename = "reactormonitor"
	filedesc = "Nuclear Reactor Monitoring"
	category = PROGRAM_CATEGORY_ENGI
	ui_header = "smmon_0.gif"
	program_icon_state = "smmon_0"
	extended_desc = "This program connects to specially calibrated sensors to provide information on the status of nuclear reactors."
	requires_ntnet = TRUE
	transfer_access = list(ACCESS_CONSTRUCTION)
	size = 5
	tgui_id = "NtosReactorStats"
	program_icon = "radiation"
	alert_able = TRUE
	var/active = TRUE //Easy process throttle
	var/next_stat_interval = 0
	var/list/pressureData = list()
	var/list/powerData = list()
	var/list/tempInputData = list()
	var/list/tempOutputdata = list()
	var/last_status = REACTOR_INACTIVE
	/// List of reactors that we are going to send the data of
	var/list/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactors = list()
	/// The reactor which will send a notification to us if it's meltingdown
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/focused_reactor

/datum/computer_file/program/reactor_monitor/on_start(mob/living/user)
	. = ..()
	refresh()

/// Apparently destroy calls this [/datum/computer_file/Destroy]. Here just to clean our references.
/datum/computer_file/program/reactor_monitor/kill_program(forced = FALSE)
	for(var/reactor in reactors)
		clear_reactor(reactor)
	return ..()

/// Refreshes list of active reactors
/datum/computer_file/program/reactor_monitor/proc/refresh()
	for(var/reactor in reactors)
		clear_reactor(reactor)
	var/turf/user_turf = get_turf(computer.ui_host())
	if(!user_turf)
		return
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactors in GLOB.machines)
		//Exclude Syndicate owned, meltdowns, not within coverage, not on a tile.
		if (!reactors.include_in_cims || !isturf(reactors.loc) || !(is_station_level(reactors.z) || is_mining_level(reactors.z) || reactors.z == user_turf.z))
			continue
		reactors += reactors
		RegisterSignal(reactors, COMSIG_PARENT_QDELETING, PROC_REF(clear_reactor))

/datum/computer_file/program/reactor_monitor/ui_static_data(mob/user)
	var/list/data = list()
	data["gas_metadata"] = reactor_gas_data()
	return data

/datum/computer_file/program/reactor_monitor/ui_data(mob/user)
	var/list/data = list()
	data["reactor_data"] = list()
	for (var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor as anything in reactors)
		data["reactor_data"] += list(reactor.reactor_ui_data())
	data["focus_uid"] = focused_reactor?.uid
	return data

/datum/computer_file/program/reactor_monitor/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("PRG_refresh")
			refresh()
			return TRUE
		if("PRG_focus")
			for (var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor in reactors)
				if(reactor.uid == params["focus_uid"])
					if(focused_reactor == reactor)
						unfocus_reactor(reactor)
					else
						focus_reactor(reactor)
					return TRUE
		if("power")
			if(focused_reactor.on)
				if(focused_reactor.K <= 0 && focused_reactor.temperature <= REACTOR_TEMPERATURE_OPERATING)
					focused_reactor.shut_down()
			else if(focused_reactor.fuel_rods.len)
				focused_reactor.start_up()
		if("input")
			var/input = text2num(params["target"])
			focused_reactor.last_user = usr
			focused_reactor.desired_k = focused_reactor.on ? clamp(input, 0, REACTOR_MAX_CRITICALITY) : 0
		if("eject")
			if(focused_reactor?.temperature > REACTOR_TEMPERATURE_OPERATING)
				return
			if(focused_reactor?.slagged)
				return
			var/rod_index = text2num(params["rod_index"])
			if(rod_index < 1 || rod_index > focused_reactor.fuel_rods.len)
				return
			var/obj/item/fuel_rod/rod = focused_reactor.fuel_rods[rod_index]
			if(!rod)
				return
			playsound(src, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
			playsound(focused_reactor, 'monkestation/sound/effects/reactor/crane_1.wav', 100, FALSE)
			rod.forceMove(get_turf(focused_reactor))
			focused_reactor.fuel_rods.Remove(rod)

/// Sends an Reactor warning alert to the computer if our focused reactor is reaching critical levels
/// [var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/focused_reactor].
/datum/computer_file/program/reactor_monitor/proc/send_alert()
	SIGNAL_HANDLER
	if(!computer.get_ntnet_status())
		return
	computer.alert_call(src, "Reactor meltdown in progress!")
	alert_pending = TRUE

/datum/computer_file/program/reactor_monitor/proc/clear_reactor(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	SIGNAL_HANDLER
	reactors -= reactor
	if(focused_reactor == reactor)
		unfocus_reactor()
	UnregisterSignal(reactor, COMSIG_PARENT_QDELETING)

/datum/computer_file/program/reactor_monitor/proc/focus_reactor(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(reactor == focused_reactor)
		return
	if(focused_reactor)
		unfocus_reactor()
	RegisterSignal(reactor, COMSIG_REACTOR_MELTDOWN_ALARM, PROC_REF(send_alert))
	focused_reactor = reactor

/datum/computer_file/program/reactor_monitor/proc/unfocus_reactor()
	if(!focused_reactor)
		return
	UnregisterSignal(focused_reactor, COMSIG_REACTOR_MELTDOWN_ALARM)
	focused_reactor = null

/datum/computer_file/program/reactor_monitor/proc/get_status()
	. = REACTOR_INACTIVE
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor in reactors)
		. = max(., reactor.get_status())

/datum/computer_file/program/reactor_monitor/process_tick()
	..()
	var/new_status = get_status()
	if(last_status != new_status)
		last_status = new_status
		ui_header = "smmon_[last_status].gif"
		program_icon_state = "smmon_[last_status]"
		if(istype(computer))
			computer.update_appearance()

#undef FREQ_REACTOR_CONTROL
