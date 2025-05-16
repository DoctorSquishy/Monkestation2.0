/obj/machinery/reactor_conduit
	name = "conduit"
	icon = 'monkestation/icons/obj/machines/reactor/reactor_conduit.dmi'
	icon_state = "conduit_matrod"
	density = FALSE
	critical_machine = TRUE
	max_integrity = 1000
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 0.1
	layer = GAS_PUMP_LAYER

	var/conduit_num
	var/obj/item/reactor_rod/rod


/obj/machinery/reactor_conduit/Initialize(mapload)
	. = ..()


/obj/machinery/reactor_conduit/LateInitialize()
	. = ..()


/obj/machinery/reactor_conduit/Destroy()
	return ..()

/obj/machinery/reactor_conduit/proc/conduit_id(conduit_num)
	conduit_num = conduit_num
	name = "rod_[conduit_num]"

/obj/machinery/reactor_conduit/attackby(obj/item/weapon, mob/user, params)
	if((user.istate & ISTATE_HARM))
		return ..()

/obj/machinery/reactor_conduit/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	var/removal_time = 2 SECONDS
	user.balloon_alert_to_viewers("pulling up reactor rod")
	tool.use_tool(src, user, removal_time)
	rod.add_fingerprint(user)
	var/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/reactor = locate(/obj/machinery/atmospherics/components/quaternary/nuclear_reactor) in get_turf(src)
	if(Adjacent(user) && !issilicon(user))
		user.put_in_hands(rod)
	else
		rod.forceMove(drop_location())
	user.visible_message(
		span_notice("[user] pulls up the rod out of reactor conduit [conduit_num]."),
		span_notice("You pull up the rod out of reactor conduit [conduit_num]."),
	)
	tool.play_tool_sound(src)
	reactor.conduits[conduit_num] = FALSE // Register reactor conduit as empty
	rod = null
	qdel(src)
	return TOOL_ACT_TOOLTYPE_SUCCESS

//transfer heat from rods and other stats
/obj/machinery/reactor_conduit/process(seconds_per_tick)
