///Grilling Procs
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/reactor_grilling(seconds_per_tick)
	if(SPT_PROB(0.5, seconds_per_tick))
		var/datum/effect_system/fluid_spread/smoke/bad/smoke = new
		smoke.set_up(1, holder = src, location = loc)
		smoke.start()
	if(grilled_item)
		SEND_SIGNAL(grilled_item, COMSIG_ITEM_GRILL_PROCESS, src, seconds_per_tick)
		grill_time += seconds_per_tick
		grilled_item.reagents.add_reagent(/datum/reagent/consumable/char, 0.5 * seconds_per_tick)
		grilled_item.AddComponent(/datum/component/sizzle)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/finish_grilling()
	if(grilled_item)
		if(grill_time >= 20)
			grilled_item.AddElement(/datum/element/grilled_item, grill_time)
		UnregisterSignal(grilled_item, COMSIG_ITEM_GRILLED)
		switch(get_temperature_percent())
			if(10 to 60)
				grilled_item.name = "grilled [initial(grilled_item.name)]"
				grilled_item.desc = "[initial(grilled_item.desc)] It's been grilled over a nuclear reactor."
			if(60 to 80)
				grilled_item.name = "heavily grilled [initial(grilled_item.name)]"
				grilled_item.desc = "[initial(grilled_item.desc)] It's been heavily grilled through the magic of nuclear fission."
			if(80 to 100)
				grilled_item.name = "\improper Three-Mile Nuclear-Grilled [initial(grilled_item.name)]"
				grilled_item.desc = "A [initial(grilled_item.name)]. It's been put on top of a nuclear reactor running at extreme power by some badass engineer."
			if(100 to INFINITY)
				grilled_item.name = "\improper Ultimate Meltdown Grilled [initial(grilled_item.name)]"
				grilled_item.desc = "A [initial(grilled_item.name)]. A grill this perfect is a rare technique only known by a few engineers who know how to perform a 'controlled' meltdown whilst also having the time to throw food on a reactor. I'll bet it tastes amazing."
	grill_time = 0
	grill_loop.stop()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/grill_completed(obj/item/source, atom/grilled_result)
	SIGNAL_HANDLER
	grilled_item = grilled_result

