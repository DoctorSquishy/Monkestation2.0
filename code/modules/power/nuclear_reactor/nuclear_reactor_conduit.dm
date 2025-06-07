/obj/machinery/reactor_conduit
	name = "conduit"
	icon = 'monkestation/icons/obj/machines/reactor/reactor_conduit.dmi'
	icon_state = "conduit_matrod"
	density = FALSE
	critical_machine = TRUE
	max_integrity = 1000
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 0.1
	layer = GAS_PUMP_LAYER

	var/conduit_number
	var/list/adjacent_conduits = list() // Stores conduits with register_adjacent_conduits
	var/obj/item/reactor_rod/rod
	var/turf/conduit_turf
	var/x_pos // 1-3, column in vessel grid
	var/y_pos // 1-3, row in vessel grid
	var/conduit_change = FALSE

	var/neutron_emission = 1
	var/neutron_rate

/obj/machinery/reactor_conduit/Initialize(mapload)
	. = ..()
	conduit_turf = get_turf(src) //Turf of source reactor vessel

/obj/machinery/reactor_conduit/LateInitialize()
	. = ..()

/obj/machinery/reactor_conduit/Destroy()
	return ..()


/obj/machinery/reactor_conduit/attackby(obj/item/weapon, mob/user, params)
	if((user.istate & ISTATE_HARM))
		return ..()

/obj/machinery/reactor_conduit/multitool_act(mob/living/user, obj/item/tool)
	. = ..()
	//DEBUGGING
	for(var/obj/machinery/reactor_conduit/adj_conduit in adjacent_conduits)
		src.balloon_alert_to_viewers("Main Conduit [conduit_number] ")
		adj_conduit.balloon_alert_to_viewers("Adj Conduit [adj_conduit.conduit_number] ")
		user.visible_message(
		span_notice("TEST: [conduit_number]."))

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
		span_notice("[user] pulls up the rod out of reactor conduit [conduit_number]."),
		span_notice("You pull up the rod out of reactor conduit [conduit_number]."),
	)
	tool.play_tool_sound(src)
	reactor.conduits[conduit_number] = FALSE // Set reactor vessels' conduit as empty
	rod = null
	qdel(src)
	update_rod_adjacency_around(conduit_turf, x_pos, y_pos)
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/machinery/reactor_conduit/process(seconds_per_tick)
	neutron_rate = 0
	for(var/obj/machinery/reactor_conduit/adj_conduits in adjacent_conduits)
		neutron_rate += adj_conduits.neutron_emission

// Use to set conduit number and update its name
/obj/machinery/reactor_conduit/proc/set_conduit_number(number)
	conduit_number = number
	name = "rod_[conduit_number]"
	x_pos = ((conduit_number - 1) % 3) + 1
	y_pos = floor((((conduit_number - 1) / 3) + 1))

/obj/machinery/reactor_conduit/proc/register_adjacent_conduits()
	adjacent_conduits = list()
	var/list/deltas = list(
		list(-1, -1), // NW
		list( 0, -1), // N
		list( 1, -1), // NE
		list(-1,  0), // W
		list( 1,  0), // E
		list(-1,  1), // SW
		list( 0,  1), // S
		list( 1,  1)  // SE
	)

	for(var/delta in deltas)
		var/dx = delta[1]
		var/dy = delta[2]
		var/nx = x_pos + dx
		var/ny = y_pos + dy
		var/adj_turf = conduit_turf

		// Determine which directions (if any) are out of bounds
		var/dir = 0
		if(nx < 1 && ny < 1)
			dir = NORTHWEST
		else if(nx > 3 && ny < 1)
			dir = NORTHEAST
		else if(nx < 1 && ny > 3)
			dir = SOUTHWEST
		else if(nx > 3 && ny > 3)
			dir = SOUTHEAST
		else if(nx < 1)
			dir = WEST
		else if(nx > 3)
			dir = EAST
		else if(ny < 1)
			dir = NORTH
		else if(ny > 3)
			dir = SOUTH

		// Step to the correct neighboring turf if necessary
		if(dir)
			adj_turf = get_step(conduit_turf, dir)
			if(!adj_turf) continue

			// Wrap nx/ny to the opposite edge
			if(nx < 1)
				nx = 3
			if(nx > 3)
				nx = 1
			if(ny < 1)
				ny = 3
			if(ny > 3)
				ny = 1

//		message_admins("[src] ([x_pos],[y_pos]) checking ([nx],[ny]) on [adj_turf]")
//		var/found = 0
		// Now look for conduit at (nx, ny) on adj_turf
		for(var/obj/machinery/reactor_conduit/C in adj_turf)
			if(C.x_pos == nx && C.y_pos == ny)
				adjacent_conduits += C
				world << "  -> Found adjacent: [C] ([C.x_pos],[C.y_pos])"
				found = 1
				break // Only one conduit per position
//		if(!found)
//			message_admins( "  -> No adjacent found at ([nx],[ny]) on [adj_turf]")

/obj/machinery/reactor_conduit/proc/update_rod_adjacency_around(conduit_turf, x_pos, y_pos)
	// Update adjacency for all rods in this turf
	for(var/obj/machinery/reactor_conduit/C in conduit_turf)
		C.register_adjacent_conduits()

	// All 8 direction deltas
	var/list/deltas = list(
		list(-1, -1), // NW
		list( 0, -1), // N
		list( 1, -1), // NE
		list(-1,  0), // W
		list( 1,  0), // E
		list(-1,  1), // SW
		list( 0,  1), // S
		list( 1,  1)  // SE
	)

	for(var/delta in deltas)
		var/dx = delta[1]
		var/dy = delta[2]
		var/adj_x = x_pos + dx
		var/adj_y = y_pos + dy

		// Determine which direction (if any) adj_x/adj_y are out of bounds
		var/dir = 0
		if(adj_x < 1 && adj_y < 1)
			dir = NORTHWEST
		else if(adj_x > 3 && adj_y < 1)
			dir = NORTHEAST
		else if(adj_x < 1 && adj_y > 3)
			dir = SOUTHWEST
		else if(adj_x > 3 && adj_y > 3)
			dir = SOUTHEAST
		else if(adj_x < 1)
			dir = WEST
		else if(adj_x > 3)
			dir = EAST
		else if(adj_y < 1)
			dir = NORTH
		else if(adj_y > 3)
			dir = SOUTH

		var/turf/adj_turf = conduit_turf
		if(dir)
			adj_turf = get_step(conduit_turf, dir)
			if(!adj_turf) continue

		// Wrap edge coordinates if necessary
		if(adj_x < 1) adj_x = 3
		if(adj_x > 3) adj_x = 1
		if(adj_y < 1) adj_y = 3
		if(adj_y > 3) adj_y = 1

		// For each rod at this bordering position in the neighbor turf, update adjacency
		for(var/obj/machinery/reactor_conduit/C in adj_turf)
			if(C.x_pos == adj_x && C.y_pos == adj_y)
				C.register_adjacent_conduits()
