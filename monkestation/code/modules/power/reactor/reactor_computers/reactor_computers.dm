//Controlling the reactor.
/obj/machinery/computer/reactor
	name = "Reactor Control Console"
	desc = "You should not be able to see this Reactor control console description, please report as issue."
	light_power = 1
	icon_state = "oldcomp"
	icon_screen = "library"
	icon_keyboard = null
	circuit = /obj/item/circuitboard/computer/reactor // we have the technology
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor = null
	var/uid = null
	var/pump_id = null

/obj/machinery/computer/reactor/main
	uid = 1

/obj/machinery/computer/reactor/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/reactor/LateInitialize()
	. = ..()
	link_to_reactor()

/obj/machinery/computer/reactor/proc/link_to_reactor()
	for(var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor_id in GLOB.machines)
		if(reactor_id.uid && reactor_id.uid == uid)
			reactor = reactor_id
			return TRUE
	return FALSE

/obj/machinery/computer/reactor/multitool_act(mob/living/user, obj/item/multitool/I)
	if(isnull(uid) || isnum(uid))
		var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor_id = I.buffer
		if(!istype(reactor_id))
			user.balloon_alert(user, "invalid reactor ID!")
			return TRUE
		reactor = reactor_id
		uid = reactor_id.uid
		user.balloon_alert(user, "linked!")
		return TRUE
	return ..()

/obj/item/circuitboard/computer/reactor
	name = "Reactor Control (Computer Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/computer/reactor

/obj/machinery/computer/reactor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ReactorControls")
		ui.open()

/obj/machinery/computer/reactor/ui_data(mob/user)
	var/list/data = list()
	data["reactor_data"] = list()
	data["reactor_data"] += list(reactor.reactor_ui_data())
	return data

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

/obj/machinery/computer/reactor/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You start [anchored ? "un" : ""]securing [name]..."))
	if(I.use_tool(src, user, 40, volume=75))
		to_chat(user, span_notice("You [anchored ? "un" : ""]secure [name]."))
		set_anchored(!anchored)
		return TRUE
	return FALSE



#define FREQ_REACTOR_CONTROL 1439.69

/obj/machinery/atmospherics/components/binary/pump
	var/pump_id = null
	var/frequency = null

//Preset pumps for mappers. You can also set the id tags yourself.
/obj/machinery/atmospherics/components/binary/pump/reactor_input
	pump_id = "reactor_input"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_output
	pump_id = "reactor_output"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/atmospherics/components/binary/pump/reactor_moderator
	pump_id = "reactor_moderator"
	frequency = FREQ_REACTOR_CONTROL

/obj/machinery/computer/reactor/pump
	name = "Reactor Inlet Valve Computer"
	desc = "A computer which controls valve settings on an advanced gas cooled reactor. Alt click it to remotely set pump pressure."
	icon_screen = "reactor_input"
	pump_id = "reactor_input"
	var/datum/radio_frequency/radio_connection
	var/on = FALSE

/obj/machinery/computer/reactor/pump/AltClick(mob/user)
	. = ..()
	var/newPressure = input(user, "Set new output pressure (kPa)", "Remote pump control", null) as num
	if(!newPressure)
		return
	newPressure = clamp(newPressure, 0, MAX_OUTPUT_PRESSURE) //Number sanitization is not handled in the pumps themselves, only during their ui_act which this doesn't use.
	signal(on, newPressure)

/obj/machinery/computer/reactor/pump/attack_hand(mob/living/user)
	. = ..()
	if(!is_operational)
		return FALSE
	playsound(loc, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
	visible_message(span_notice("[src]'s switch flips [on ? "off" : "on"]."))
	on = !on
	signal(on)

/obj/machinery/computer/reactor/pump/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	radio_connection = SSradio.add_object(src, FREQ_REACTOR_CONTROL,filter = RADIO_ATMOSIA)

/obj/machinery/computer/reactor/pump/proc/signal(power, set_output_pressure=null)
	var/datum/signal/signal
	if(!set_output_pressure) //Yes this is stupid, but technically if you pass through "set_output_pressure" onto the signal, it'll always try and set its output pressure and yeahhh...
		signal = new(list(
			"tag" = pump_id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"sigtype" = "command"
		))
	else
		signal = new(list(
			"tag" = pump_id,
			"frequency" = FREQ_REACTOR_CONTROL,
			"timestamp" = world.time,
			"power" = power,
			"set_output_pressure" = set_output_pressure,
			"sigtype" = "command"
		))
	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

#undef FREQ_REACTOR_CONTROL

//Preset subtypes for mappers
/obj/machinery/computer/reactor/pump/reactor_input
	name = "Reactor inlet valve computer"
	icon_screen = "reactor_input"
	pump_id = "reactor_input"

/obj/machinery/computer/reactor/pump/reactor_output
	name = "Reactor output valve computer"
	icon_screen = "reactor_output"
	pump_id = "reactor_output"

/obj/machinery/computer/reactor/pump/reactor_moderator
	name = "Reactor moderator valve computer"
	icon_screen = "reactor_moderator"
	pump_id = "reactor_moderator"
