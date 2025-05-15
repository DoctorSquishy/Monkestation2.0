/obj/machinery/reactor_conduit
	name = "conduit"
	icon = 'monkestation/icons/obj/machines/reactor/reactor_conduit.dmi'
	icon_state = "conduit_matrod"
	density = FALSE
	critical_machine = TRUE
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 0.1
	layer = GAS_PUMP_LAYER

	var/id = 0
	var/obj/item/reactor_rod/rod


/obj/machinery/reactor_conduit/Initialize(mapload)
	. = ..()


/obj/machinery/reactor_conduit/LateInitialize()
	. = ..()


/obj/machinery/reactor_conduit/Destroy()
	return ..()

/obj/machinery/reactor_conduit/proc/conduit_id(id)
	name = "rod_[id]"


//transfer heat from rods and other stats
/obj/machinery/reactor_conduit/process(seconds_per_tick)
