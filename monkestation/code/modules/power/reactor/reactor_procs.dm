//Start up the reactor, enable reactor hum
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/start_up()
	if(slagged)
		return //Clear that slag and dispose of the waste
	SSair.start_processing_machine(src)
	desired_k = 1
	on = TRUE
	disable_process = REACTOR_PROCESS_ENABLED
	var/startup_sound = pick('monkestation/sound/effects/reactor/startup.ogg', 'monkestation/sound/effects/reactor/startup2.ogg')
	playsound(loc, startup_sound, 70)
	update_parents()
	reactor_loop = new(src, TRUE)

//Shuts off the fuel rods, ambience, etc. Keep in mind that your temperature may still go up!
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/shut_down()
	SSair.stop_processing_machine(src)
	QDEL_NULL(reactor_loop)
	investigate_log("Reactor shutdown at [pressure] kPa and [temperature] K.", INVESTIGATE_ENGINE)
	radio.talk_into(src, "REACTOR SHUTDOWN INITIATED at [pressure] kPa and [temperature] K." , engi_channel)
	K = 0
	desired_k = 0
	temperature = 0
	pressure = 0
	on = FALSE
	disable_process = REACTOR_PROCESS_DISABLED
	update_appearance()

// All the calculate procs should only update variables
// Move the actual real-world effects to [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos]
/**
 * Perform calculation for variables that depend on fuel rod and CRITICALITY (K) level
 * Updates:
 * [/var/K]
 * [/var/gas_radioactivity_mod]
 **/
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_criticality()
	var/fuel_power = 0 //So that you can't magically generate K with your control rods.
	if(!has_fuel())
		shutdown()
	else
		for(var/obj/item/fuel_rod/rod in fuel_rods)
			K += rod.fuel_power
			fuel_power += rod.fuel_power
			rod.deplete(0.035 + gas_depletion_mod)
		gas_radioactivity_mod += fuel_power

	// Firstly, find the difference between the two numbers.
	var/difference = abs(K - desired_k)

	// Then, hit as much of that goal with our cooling per tick as we possibly can.
	difference = clamp(difference, 0, gas_control_mod) //And we can't instantly zap the K to what we want, so let's zap as much of it as we can manage....
	if(difference > fuel_power && desired_k > K)
		investigate_log("Reactor does not have enough fuel to get [difference]. We have [fuel_power] fuel power.", INVESTIGATE_ENGINE)
		difference = fuel_power //Again, to stop you being able to run off of 1 fuel rod.

	// If K isn't what we want it to be, let's try to change that
	if(K != desired_k)
		if(desired_k > K)
			K += difference
		else if(desired_k < K)
			K -= difference
		if(last_user && current_desired_k != desired_k) // Tell admins about it if it's done by a player
			current_desired_k = desired_k
			message_admins("Reactor desired criticality set to [desired_k] by [ADMIN_LOOKUPFLW(last_user)] in [ADMIN_VERBOSEJMP(src)]")
			investigate_log("Reactor desired criticality set to [desired_k] by [key_name(last_user)] at [AREACOORD(src)]", INVESTIGATE_ENGINE)
	// Now, clamp K and heat up the reactor based on it.
	K = clamp(K, 0, REACTOR_MAX_CRITICALITY)

/**
 * Perform calculation for variables that depend on moderator gases.
 * Updates:
 * [/var/list/gas_percentage]
 * [/var/gas_heat_mod]
 * [/var/gas_heat_resistance]
 * [/var/gas_radioactivity_mod]
 * [/var/gas_control_mod]
 * [/var/gas_permeability_mod]
 *
 * Returns: null
 **/
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_moderators()
	if(disable_gas)
		return

	gas_percentage = list()
	gas_heat_mod = 0
	gas_heat_resistance = 0
	gas_radioactivity_mod = 0
	gas_control_mod = 0
	gas_permeability_mod = 0
	gas_depletion_mod = 0

	var/total_moles = absorbed_gasmix.total_moles()

	for (var/gas_path in absorbed_gasmix.gases)
		gas_percentage[gas_path] = absorbed_gasmix.gases[gas_path][MOLES] / total_moles
		var/datum/reactor_gas/reactor_gas = GLOB.reactor_gas_behavior[gas_path]
		if(!reactor_gas)
			continue
		gas_heat_mod += reactor_gas.heat_mod * gas_percentage[gas_path]
		gas_heat_resistance += reactor_gas.heat_resistance * gas_percentage[gas_path]
		gas_radioactivity_mod += reactor_gas.radioactivity_mod * gas_percentage[gas_path]
		gas_control_mod += reactor_gas.control_mod * gas_percentage[gas_path]
		gas_permeability_mod += reactor_gas.permeability_mod * gas_percentage[gas_path]
		gas_depletion_mod += reactor_gas.depletion_mod * gas_percentage[gas_path]

/**
 * Calculate at which temperature the reactor starts taking damage.
 * heat limit is given by: (T0C+40) * (1 + gas heat res + psy_coeff)
 *
 * Description of each factors can be found in the defines.
 *
 * Updates:
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/temp_limit]
 *
 * Returns: The factors that have influenced the calculation. list[FACTOR_DEFINE] = number
 */
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_temp_limit()
	var/list/additive_temp_limit = list()
	additive_temp_limit[REACTOR_TEMP_LIMIT_BASE] = T0C + REACTOR_HEAT_PENALTY_THRESHOLD
	additive_temp_limit[REACTOR_TEMP_LIMIT_GAS] = gas_heat_resistance * (T0C + REACTOR_HEAT_PENALTY_THRESHOLD)
	additive_temp_limit[REACTOR_TEMP_LIMIT_SOOTHED] = psy_coeff * 45
	additive_temp_limit[REACTOR_TEMP_LIMIT_LOW_MOLES] =  clamp(2 - absorbed_gasmix.total_moles() / 100, 0, 1) * (T0C + REACTOR_HEAT_PENALTY_THRESHOLD)

	temp_limit = 0
	for (var/resistance_type in additive_temp_limit)
		temp_limit += additive_temp_limit[resistance_type]
	temp_limit = max(temp_limit, TCMB)

	return additive_temp_limit

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_reactor_temp()
	var/datum/gas_mixture/coolant_input = airs[1]
	var/datum/gas_mixture/coolant_output = airs[3]
	if(has_fuel())
		temperature += REACTOR_HEAT_FACTOR * has_fuel() * ((REACTOR_HEAT_EXPONENT**K) - 1) // heating from K has to be exponential to make higher K more dangerous
	var/input_moles = coolant_input.total_moles() //Firstly. Do we have enough moles of coolant?
	if(input_moles >= minimum_coolant_level)
		last_coolant_temperature = coolant_input.return_temperature()
		//Important thing to remember, once you slot in the fuel rods, this thing will not stop making heat, at least, not unless you can live to be thousands of years old which is when the spent fuel finally depletes fully.
		var/heat_delta = (last_coolant_temperature - temperature) * gas_permeability_mod //Take in the gas as a cooled input, cool the reactor a bit. The optimum, 100% balanced reaction sits at K=1, coolant input temp of 200K / -73 celsius.
		var/coolant_heat_factor = coolant_input.heat_capacity() / (coolant_input.heat_capacity() + REACTOR_HEAT_CAPACITY + (REACTOR_ROD_HEAT_CAPACITY * has_fuel())) //What percent of the total heat capacity is in the coolant
		last_heat_delta = heat_delta
		temperature += heat_delta * coolant_heat_factor + gas_heat_mod
		//Heat the coolant output gas that we just had pass through us.
		var/coolant_heat_transfer = (last_coolant_temperature - (heat_delta * (1 - coolant_heat_factor)))
		coolant_input.temperature_share(sharer_temperature = coolant_heat_transfer)
		coolant_output.merge(coolant_input) //And now, shove the input into the output.
	last_output_temperature = coolant_output.return_temperature()

/**
 * Perform calculation for the damage taken or healed.
 * Description of each factors can be found in the defines.
 *
 * Updates:
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/damage]
 *
 * Returns: The factors that have influenced the calculation. list[FACTOR_DEFINE] = number
 */
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_damage()
	if(disable_damage)
		return

	var/list/additive_damage = list()

	// We dont let external factors deal more damage than the emergency point.
	// Only cares about the damage before this proc is run. We ignore soon-to-be-applied damage.
	additive_damage[REACTOR_DAMAGE_HEAT] = external_damage_immediate * clamp((emergency_point - damage) / emergency_point, 0, 1)
	external_damage_immediate = 0

	additive_damage[REACTOR_DAMAGE_HEAT] = clamp((temperature - temp_limit) / 24000, 0, 0.15)
	additive_damage[REACTOR_DAMAGE_PRESSURE] = clamp(pressure/300, 0, 0.1)

	var/total_damage = 0
	for (var/damage_type in additive_damage)
		total_damage += additive_damage[damage_type]

	damage += total_damage
	damage = max(damage, 0)
	return additive_damage

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/collect_data()
	kpaData += pressure
	if(kpaData.len > 100) //Only lets you track over a certain timeframe.
		kpaData.Cut(1, 2)
	tempCoreData += temperature //We scale up the figure for a consistent:tm: scale
	if(tempCoreData.len > 100) //Only lets you track over a certain timeframe.
		tempCoreData.Cut(1, 2)
	tempInputData += last_coolant_temperature //We scale up the figure for a consistent:tm: scale
	if(tempInputData.len > 100) //Only lets you track over a certain timeframe.
		tempInputData.Cut(1, 2)
	tempOutputData += last_output_temperature //We scale up the figure for a consistent:tm: scale
	if(tempOutputData.len > 100) //Only lets you track over a certain timeframe.
		tempOutputData.Cut(1, 2)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/has_fuel()
	return length(fuel_rods)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_fuel_power()
	var/total_fuel_power = 0
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		total_fuel_power += rod.fuel_power
	return total_fuel_power

/// Encodes the current state of the reactor
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_status()
	if(!absorbed_gasmix)
		return REACTOR_ERROR
	if(final_countdown)
		return REACTOR_MELTDOWN
	if(damage >= emergency_point)
		return REACTOR_EMERGENCY
	if(damage >= danger_point)
		return REACTOR_DANGER
	if(damage >= warning_point)
		return REACTOR_WARNING
	if(absorbed_gasmix.temperature > temp_limit * 0.8 || absorbed_gasmix.volume > pressure_limit * 0.8)
		return REACTOR_NOTIFY
	if(absorbed_gasmix.temperature < temp_limit * 0.8 || absorbed_gasmix.volume < pressure_limit * 0.8)
		return REACTOR_NORMAL
	return REACTOR_INACTIVE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_integrity_percent()
	var/integrity = damage / explosion_point
	integrity = 100 - (integrity * 100)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_temperature_percent()
	var/temperature_percent = absorbed_gasmix.temperature / temp_limit
	temperature_percent = 100 - (temperature_percent * 100)
	temperature_percent = temperature_percent < 0 ? 0 : temperature_percent
	return temperature_percent

//Calculates radiation levels that emit from the reactor
//Emits low radiation under normal operating conditions with full integrity
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/emit_radiation(delta_time)
	// At the "normal" output (with max integrity), this is 0.7, which is enough to be stopped
	// by the walls or the radation shutters.
	// As integrity does down, rads go up
	var/threshold = get_integrity_percent()
	var/rad_chance_full_integrity = 0.03
	var/rad_chance_zero_integrity = 0.4
	var/chance_equation_slope = rad_chance_zero_integrity - rad_chance_full_integrity
	// Calculating chance is done entirely on integrity, so that actively damaged reactors feel more dangerous
	var/chance = (chance_equation_slope * threshold) + rad_chance_full_integrity

	radiation_pulse(
		src,
		(K*temperature*gas_radioactivity_mod*has_fuel()/(REACTOR_MAX_CRITICALITY*REACTOR_MAX_FUEL_RODS)),
		threshold = threshold,
		chance = chance * 100,
	)
/**
 * Count down, spout some messages, and then execute the meltdown itself.
 * We guard for last second meltdown strat changes here, mostly because some have diff messages.
 *
 * By last second changes, we mean that it's possible for say, a blowout meltdown to
 * just meltdown normally if at the absolute last second it loses pressure and switches to default one.
 * Even after countdown is already in progress.
 */
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/count_down()
	set waitfor = FALSE

	if(final_countdown) // We're already doing it go away
		stack_trace("[src] told to meltdown again while it's already melting down.")
		return

	final_countdown = TRUE

	var/datum/reactor_meltdown/last_meltdown_strategy = meltdown_strategy
	var/list/count_down_messages = meltdown_strategy.count_down_messages()

	radio.talk_into(
		src,
		count_down_messages[1],
		emergency_channel
	)

	for(var/i in REACTOR_COUNTDOWN_TIME to 0 step -10)
		if(last_meltdown_strategy != meltdown_strategy)
			count_down_messages = meltdown_strategy.count_down_messages()
			last_meltdown_strategy = meltdown_strategy

		var/message
		var/healed = FALSE

		if(damage < explosion_point) // Cutting it a bit close there engineers
			message = count_down_messages[2]
			healed = TRUE
		else if((i % 50) != 0 && i > 50) // A message once every 5 seconds until the final 5 seconds which count down individualy
			sleep(1 SECONDS)
			continue
		else if(i > 50)
			message = "[DisplayTimeText(i, TRUE)] [count_down_messages[3]]"
		else
			message = "[i*0.1]..."

		radio.talk_into(src, message, emergency_channel)

		if(healed)
			final_countdown = FALSE
			return // meltdown averted
		sleep(1 SECONDS)

	meltdown_strategy.meltdown_now(src)

/**
 * Sets the meltdown of our reactor.
 *
 * Arguments:
 * * priority: Truthy values means a forced meltdown. If current forced_meltdown is higher than priority we dont run.
 * Set to a number higher than [REACTOR_DELAM_PRIO_IN_GAME] to fully force an admin meltdown.
 * * meltdown_path: Typepath of a [/datum/reactor_meltdown]. [REACTOR_DELAM_STRATEGY_PURGE] means reset and put prio back to zero.
 *
 * Returns: Not used for anything, just returns true on succesful set, manual and automatic. Helps admins check stuffs.
 */
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/set_meltdown(priority = REACTOR_MELTDOWN_PRIO_NONE, manual_meltdown_path = REACTOR_MELTDOWN_STRATEGY_PURGE)
	if(priority < meltdown_priority)
		return FALSE
	var/datum/reactor_meltdown/new_meltdown = null

	if(manual_meltdown_path == REACTOR_MELTDOWN_STRATEGY_PURGE)
		for (var/meltdown_path in GLOB.reactor_meltdown_list)
			var/datum/reactor_meltdown/meltdown = GLOB.reactor_meltdown_list[meltdown_path]
			if(!meltdown.can_select(src))
				continue
			if(meltdown == meltdown_strategy)
				return FALSE
			new_meltdown = meltdown
			break
		meltdown_priority = REACTOR_MELTDOWN_PRIO_NONE
	else
		new_meltdown= GLOB.reactor_meltdown_list[manual_meltdown_path]
		meltdown_priority = priority

	if(!new_meltdown)
		return FALSE
	meltdown_strategy?.on_deselect(src)
	meltdown_strategy = new_meltdown
	meltdown_strategy.on_select(src)
	return TRUE


//Timestop Effects
////Freezes current reactor processes from a time stop
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/time_frozen()
	SIGNAL_HANDLER
	if(disable_process != REACTOR_PROCESS_ENABLED)
		return
	disable_process = REACTOR_PROCESS_TIMESTOP

////Resumes current reactor processes from a time stop
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/time_unfrozen()
	SIGNAL_HANDLER
	if(disable_process != REACTOR_PROCESS_TIMESTOP)
		return
	disable_process = REACTOR_PROCESS_ENABLED

//Force Meltdown state
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/force_meltdown()
	SIGNAL_HANDLER
	investigate_log("was forcefully put into meltdown state", INVESTIGATE_ENGINE)
	INVOKE_ASYNC(meltdown_strategy, TYPE_PROC_REF(/datum/reactor_meltdown, meltdown_now), src)

//The dangers of crossing a spicy reactor
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/reactor_crossed(atom/movable/atom_movable, oldloc)
	if(!isliving(atom_movable))
		return
	if(isliving(atom_movable) && temperature > T0C)
		var/mob/living/living_mob = atom_movable
		living_mob.adjust_bodytemperature(clamp(temperature, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX)) //If you're on fire, you heat up!


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


/// Returns data that are exclusively about this reactor
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/reactor_ui_data()
	var/list/data = list()
	data["uid"] = uid
	data["area_name"] = get_area_name(src)
	data["control_rods"] = 100 - (100 * desired_k / REACTOR_MAX_CRITICALITY)
	data["k"] = K
	data["desiredK"] = desired_k
	data["integrity"] = get_integrity_percent()
	data["integrity_factors"] = list()
	for (var/factor in damage_factors) //Vessel integrity
		var/amount = round(damage_factors[factor], 0.01)
		if(!amount)
			continue
		data["integrity_factors"] += list(list(
			"name" = factor,
			"amount" = amount * -1
		))
	data["temp_limit"] = temp_limit
	data["temp_limit_factors"] = list()
	for (var/factor in temp_limit_factors)
		var/amount = round(temp_limit_factors[factor], 0.01)
		if(!amount)
			continue
		data["temp_limit_factors"] += list(list(
			"name" = factor,
			"amount" = amount
		))
	data["kpaData"] = kpaData
	data["tempCoreData"] = tempCoreData
	data["tempInputData"] = tempInputData
	data["tempOutputData"] = tempOutputData
	data["coreTemp"] = round(temperature)
	data["coolantInput"] = round(last_coolant_temperature)
	data["coolantOutput"] = round(last_output_temperature)
	data["kpa"] = pressure
	data["active"] = on
	data["shutdownTemp"] = REACTOR_TEMPERATURE_OPERATING
	var/list/rod_data = list()
	var/cur_index = 0
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		cur_index++
		rod_data.Add(
			list(
				"name" = rod.name,
				"depletion" = rod.depletion,
				"rod_index" = cur_index
			)
		)
	data["rods"] = rod_data

	data["absorbed_ratio"] = absorption_ratio
	var/list/formatted_gas_percentage = list()
	for (var/datum/gas/gas_path as anything in subtypesof(/datum/gas))
		formatted_gas_percentage[gas_path] = gas_percentage?[gas_path] || 0
	data["gas_composition"] = formatted_gas_percentage
	data["gas_temperature"] = absorbed_gasmix.temperature
	data["gas_total_moles"] = absorbed_gasmix.total_moles()
	return data
