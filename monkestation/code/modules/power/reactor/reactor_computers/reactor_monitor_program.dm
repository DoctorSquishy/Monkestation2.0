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
	tgui_id = "NtosReactor"
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
