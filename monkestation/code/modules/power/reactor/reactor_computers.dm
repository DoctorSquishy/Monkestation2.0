//Controlling the reactor.
/obj/machinery/computer/reactor
	name = "Reactor control console"
	desc = "You should not be able to see this Reactor control console description, please report as issue."
	light_power = 1
	icon_state = "oldcomp"
	icon_screen = "library"
	icon_keyboard = null
	circuit = /obj/item/circuitboard/computer/reactor // we have the technology
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor = null
	var/id = null

/obj/machinery/computer/reactor/Initialize(mapload, obj/item/circuitboard/item_circuitboard)
	. = ..()
	addtimer(CALLBACK(src, .proc/link_to_reactor), 10 SECONDS)

/obj/machinery/computer/reactor/proc/link_to_reactor()
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor_id in GLOB.machines)
		if(reactor_id.uid && reactor_id.uid == id)
			reactor = reactor_id
			return TRUE
	return FALSE

/obj/machinery/computer/reactor/multitool_act(mob/living/user, obj/item/multitool/I)
	if(isnull(id) || isnum(id))
		var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/N = I.buffer
		if(!istype(N))
			user.balloon_alert(user, "invalid reactor ID!")
			return TRUE
		reactor = N
		id = N.uid
		user.balloon_alert(user, "linked!")
		return TRUE
	return ..()

/obj/machinery/computer/reactor/preset
	id = "default_reactor_for_lazy_mappers"

/obj/machinery/computer/reactor/syndie_base
	id = "syndie_base_reactor"

/obj/item/circuitboard/computer/reactor
	name = "Reactor Control (Computer Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/computer/reactor

/obj/machinery/computer/reactor/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/reactor/LateInitialize()
	. = ..()
	link_to_reactor()

/obj/machinery/computer/reactor/attack_hand(mob/living/user)
	. = ..()
	ui_interact(user)

/obj/machinery/computer/reactor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorComputer")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/computer/reactor/ui_act(action, params)
	if(..())
		return
	if(!reactor)
		return
	switch(action)
		if("power")
			if(reactor.on)
				if(reactor.K <= 0 && reactor.temperature <= REACTOR_TEMPERATURE_OPERATING)
					reactor.shut_down()
			else if(reactor.fuel_rods.len)
				reactor.start_up()
				message_admins("Reactor started up by [ADMIN_LOOKUPFLW(usr)] in [ADMIN_VERBOSEJMP(src)]")
				investigate_log("Reactor started by [key_name(usr)] at [AREACOORD(src)]", INVESTIGATE_ENGINE)
		if("input")
			var/input = text2num(params["target"])
			reactor.last_user = usr
			reactor.desired_k = reactor.on ? clamp(input, 0, REACTOR_MAX_CRITICALITY) : 0
		if("eject")
			if(reactor?.temperature > REACTOR_TEMPERATURE_OPERATING)
				return
			if(reactor?.slagged)
				return
			var/rod_index = text2num(params["rod_index"])
			if(rod_index < 1 || rod_index > reactor.fuel_rods.len)
				return
			var/obj/item/fuel_rod/rod = reactor.fuel_rods[rod_index]
			if(!rod)
				return
			playsound(src, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
			playsound(reactor, 'monkestation/sound/effects/reactor/crane_1.wav', 100, FALSE)
			rod.forceMove(get_turf(reactor))
			reactor.fuel_rods.Remove(rod)

/obj/machinery/computer/reactor/ui_data(mob/user)
	var/list/data = list()
	data["control_rods"] = 0
	data["k"] = 0
	data["desiredK"] = 0
	if(reactor)
		data["k"] = reactor.K
		data["desiredK"] = reactor.desired_k
		data["control_rods"] = 100 - (100 * reactor.desired_k / REACTOR_MAX_CRITICALITY) //Rod insertion is extrapolated as a function of the percentage of K
		data["integrity"] = reactor.get_integrity()
	data["pressureData"] = reactor.pressureData
	data["tempCoreData"] = reactor.tempCoreData
	data["tempInputData"] =  reactor.tempInputData
	data["tempOutputData"] = reactor.tempOutputData
	data["coreTemp"] = round(reactor.temperature)
	data["coolantInput"] = reactor ? round(reactor.last_coolant_temperature) : T20C
	data["coolantOutput"] = reactor ? round(reactor.last_output_temperature) : T20C
	data["kpa"] = reactor ? reactor.pressure : 0
	data["active"] = reactor ? reactor.on : FALSE
	data["shutdownTemp"] = REACTOR_TEMPERATURE_OPERATING
	var/list/rod_data = list()
	if(reactor)
		var/cur_index = 0
		for(var/obj/item/fuel_rod/rod in reactor.fuel_rods)
			cur_index++
			rod_data.Add(
				list(
					"name" = rod.name,
					"depletion" = rod.depletion,
					"rod_index" = cur_index
				)
			)
	data["rods"] = rod_data
	return data

/obj/machinery/computer/reactor/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You start [anchored ? "un" : ""]securing [name]..."))
	if(I.use_tool(src, user, 40, volume=75))
		to_chat(user, span_notice("You [anchored ? "un" : ""]secure [name]."))
		set_anchored(!anchored)
		return TRUE
	return FALSE


#define FREQ_REACTOR_CONTROL 1439.69

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

#undef FREQ_REACTOR_CONTROL


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
	for(var/rbmk in reactors)
		clear_reactor(rbmk)
	return ..()

/// Refreshes list of active reactors
/datum/computer_file/program/reactor_monitor/proc/refresh()
	for(var/rbmk in reactors)
		clear_reactor(rbmk)
	var/turf/user_turf = get_turf(computer.ui_host())
	if(!user_turf)
		return
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor in GLOB.machines)
		//Exclude Syndicate owned, meltdowns, not within coverage, not on a tile.
		if (!reactor.include_in_cims || !isturf(reactor.loc) || !(is_station_level(reactor.z) || is_mining_level(reactor.z) || reactor.z == user_turf.z))
			continue
		reactors += reactor
		RegisterSignal(reactor, COMSIG_PARENT_QDELETING, PROC_REF(clear_reactor))

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
