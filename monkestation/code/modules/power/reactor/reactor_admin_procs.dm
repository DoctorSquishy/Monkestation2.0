//Admin procs to mess with the reaction environment.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/debug_startup()
	for(var/insert_fuel_rods = 0;insert_fuel_rods < 5;insert_fuel_rods++)
		fuel_rods += new /obj/item/fuel_rod(src)
	message_admins("Reactor started up by admins in [ADMIN_VERBOSEJMP(src)]")
	start_up()

//Admin procs to mess with the reaction environment.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/debug_shutdown()
	for(var/insert_fuel_rods = 0;insert_fuel_rods < 5;insert_fuel_rods++)
		fuel_rods += new /obj/item/fuel_rod(src)
	message_admins("Reactor shutdown by admins in [ADMIN_VERBOSEJMP(src)]")
	shutdown()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/deplete()
	for(var/obj/item/fuel_rod/item_fuel_rod in fuel_rods)
		item_fuel_rod.depletion = 100
