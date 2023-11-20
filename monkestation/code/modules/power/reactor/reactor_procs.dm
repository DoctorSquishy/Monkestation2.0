//Start up the reactor, enable reactor hum
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/start_up()
	if(slagged)
		return //Clear that slag and dispose of the waste
	SSair.start_processing_machine(src)
	desired_k = 1
	on = TRUE
	set_light(10)
	disable_process = REACTOR_PROCESS_ENABLED
	var/startup_sound = pick('monkestation/sound/effects/reactor/startup.ogg', 'monkestation/sound/effects/reactor/startup2.ogg')
	playsound(loc, startup_sound, 70)
	update_parents()
	reactor_hum = new(src, TRUE)
	update_appearance()

//Shuts off the fuel rods, ambience, etc. Keep in mind that your temperature may still go up!
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/shut_down()
	K = 0
	desired_k = 0
	temperature = 0
	pressure = 0
	set_meltdown(REACTOR_MELTDOWN_PRIO_NONE, REACTOR_MELTDOWN_STRATEGY_PURGE)
	SSair.stop_processing_machine(src)
	if(reactor_hum)
		QDEL_NULL(reactor_hum)
	if(meltdown_alarm)
		QDEL_NULL(meltdown_alarm)
	if(fuel_rods.len <= 1)
		playsound(src, 'monkestation/sound/effects/reactor/switch.ogg', 100, TRUE)
		radio.talk_into(src, "Insufficient Fuel Rod Count. Unable to reach sustainable fission chain reaction. REACTOR SHUTDOWN INITIATED." , engi_channel)
	else
		radio.talk_into(src, "REACTOR SHUTDOWN INITIATED at [pressure] kPa and [temperature] K." , engi_channel)
	investigate_log("Reactor shutdown at [pressure] kPa and [temperature] K.", INVESTIGATE_ENGINE)
	on = FALSE
	disable_process = REACTOR_PROCESS_DISABLED
	update_appearance()

//Insert fuel rod manually into reactor
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/try_insert_fuel(obj/item/fuel_rod/rod, mob/user)
	if(!istype(rod))
		return FALSE
	if(slagged)
		to_chat(user, span_warning("The reactor has been critically damaged"))
		return FALSE
	if(temperature > REACTOR_TEMPERATURE_OPERATING)
		to_chat(user, span_warning("You cannot insert fuel into [src] with the core temperature above [REACTOR_TEMPERATURE_OPERATING] kelvin."))
		return FALSE
	if(fuel_rods.len >= REACTOR_MAX_FUEL_RODS)
		to_chat(user, span_warning("[src] is already at maximum fuel load."))
		return FALSE
	to_chat(user, span_notice("You engage the crane switch to begin inserting [rod] into [src]..."))
	radiation_pulse(src, temperature)
	playsound(src, 'monkestation/sound/effects/reactor/switch2.ogg', 100, TRUE)
	playsound(src, 'monkestation/sound/effects/reactor/crane_1.wav', 100, TRUE)
	var/obj/effect/fuel_rod/insert/rod_effect = new(get_turf(src))
	if(do_after(user, 3 SECONDS, target=src))
		fuel_rods += rod
		rod.forceMove(src)
		radiation_pulse(src, temperature) //Wear protective equipment when even breathing near a reactor!
		investigate_log("Rod added to reactor by [key_name(user)] at [AREACOORD(src)]", INVESTIGATE_ENGINE)
		playsound(src, 'monkestation/sound/effects/reactor/crane_return.ogg', 100, TRUE)
		playsound(src, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
		sleep(5 SECONDS)
		qdel(rod_effect)
	return TRUE

//Remove fuel rod
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/try_eject_fuel(obj/item/fuel_rod/rod, mob/user)
	if(!rod)
		return FALSE
	playsound(src, 'monkestation/sound/effects/reactor/switch2.ogg', 100, TRUE)
	playsound(src, 'monkestation/sound/effects/reactor/crane_1.wav', 100, TRUE)
	var/obj/effect/fuel_rod/eject/rod_effect = new(get_turf(src))
	rod.moveToNullspace()
	fuel_rods.Remove(rod)
	sleep(3 SECONDS)
	rod.forceMove(get_turf(src))
	playsound(src, 'monkestation/sound/effects/reactor/crane_return.ogg', 100, TRUE)
	playsound(src, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
	sleep(5 SECONDS)
	qdel(rod_effect)

// High pressure rod removal is dangerous
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/rod_removal_gas(mob/user)
	var/datum/gas_mixture/coolant_input = airs[COOLANT_INPUT_GATE]
	var/datum/gas_mixture/moderator_input = airs[MODERATOR_INPUT_GATE]
	var/datum/gas_mixture/coolant_output = airs[COOLANT_OUTPUT_GATE]
	var/datum/gas_mixture/reactor_env = src.return_air()
	var/pressure_difference = (coolant_input.return_pressure() + moderator_input.return_pressure() + coolant_output.return_pressure()) - reactor_env.return_pressure()
	if(pressure_difference > 2 * ONE_ATMOSPHERE)
		src.Shake(1, 1, 2 SECONDS)
		playsound(src, 'sound/machines/clockcult/steam_whoosh.ogg', 100, TRUE)
		unsafe_pressure_release(user, pressure_difference)
		air_update_turf(FALSE, FALSE)

// All the calculate procs should only update variables
// Move the actual real-world effects to [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos]
/**
 * Perform calculation for variables that depend on moderator gases.
 * Updates:
 * [/var/list/gas_percentage]
 * [/var/gas_heat_mod]
 * [/var/gas_heat_resistance]
 * [/var/gas_radioactivity_mod]
 * [/var/gas_control_mod]
 * [/var/gas_permeability_mod]
 * [/var/gas_depletion_mod]
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

	var/total_moles = moderator_gasmix.total_moles()

	for (var/gas_path in moderator_gasmix.gases)
		gas_percentage[gas_path] = moderator_gasmix.gases[gas_path][MOLES] / total_moles
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
 * Perform calculation for the waste multiplier.
 * This number affects the temperature and waste gas production
 *
 * Description of each factors can be found in the defines.
 *
 * Updates:
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/waste_multiplier]
 *
 * Returns: The factors that have influenced the calculation. list[FACTOR_DEFINE] = number
 */
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_waste_multiplier()
	waste_multiplier = 0
	if(disable_gas)
		return

	var/additive_waste_multiplier = list()
	additive_waste_multiplier[REACTOR_WASTE_BASE] = 0.05
	additive_waste_multiplier[REACTOR_WASTE_GAS] = gas_heat_mod

	for (var/waste_type in additive_waste_multiplier)
		waste_multiplier += additive_waste_multiplier[waste_type]
	waste_multiplier = clamp(waste_multiplier, 0.05, INFINITY)
	return additive_waste_multiplier

/**
 * Perform calculation for variables that depend on fuel rod and CRITICALITY (K) level
 * Updates:
 * [/var/K]
 * [/var/gas_radioactivity_mod]
 **/
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_criticality()
	var/fuel_power = 0 //So that you can't magically generate K with your control rods.
	K += gas_heat_mod
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		K += rod.fuel_power
		fuel_power += rod.fuel_power
		rod.deplete(0.015 + gas_depletion_mod)
	gas_radioactivity_mod += fuel_power

	// Firstly, find the difference between the two numbers.
	var/difference = abs(K - desired_k)

	// Then, hit as much of that goal with our cooling per tick as we possibly can.
	difference = clamp(difference, 0, control_rod_effectiveness) //And we can't instantly zap the K to what we want, so let's zap as much of it as we can manage....
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
 * Calculate at which temperature the reactor starts taking damage.
 * heat limit is given by: (T0C+40) * (1 + gas heat res)
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

	temp_limit = 0
	for (var/resistance_type in additive_temp_limit)
		temp_limit += additive_temp_limit[resistance_type]
	temp_limit = max(temp_limit, TCMB)

	return additive_temp_limit

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_reactor_temp()
	var/datum/gas_mixture/coolant_input = airs[COOLANT_INPUT_GATE]
	if(has_fuel())
		temperature += REACTOR_HEAT_FACTOR * has_fuel() * ((REACTOR_HEAT_EXPONENT**K) - 1) // heating from K has to be exponential to make higher K more dangerous
	var/moderator_moles = moderator_gasmix.total_moles()
	if(moderator_moles >= minimum_coolant_level) // Add some influence from the moderator inputs
		temperature +=  (moderator_gasmix.return_temperature() * 0.25) // 25% as effective than the coolant inputs
	var/input_moles = coolant_input.total_moles() //Firstly. Do we have enough moles of coolant?
	if(input_moles >= minimum_coolant_level)
		last_coolant_temperature = coolant_input.return_temperature()
		//Important thing to remember, once you slot in the fuel rods, this thing will not stop making heat, at least, not unless you can live to be thousands of years old which is when the spent fuel finally depletes fully.
		var/heat_delta = (last_coolant_temperature - temperature) * gas_absorption_effectiveness //Take in the gas as a cooled input, cool the reactor a bit. The optimum, 100% balanced reaction sits at K=1, coolant input temp of 200K / -73 celsius.
		var/coolant_heat_factor = coolant_input.heat_capacity() / (coolant_input.heat_capacity() + REACTOR_HEAT_CAPACITY + (REACTOR_ROD_HEAT_CAPACITY * has_fuel())) //What percent of the total heat capacity is in the coolant
		last_heat_delta = heat_delta
		temperature += heat_delta * coolant_heat_factor
		//Heat the coolant output gas that we just had pass through us.
		var/coolant_heat_transfer = (last_coolant_temperature - (heat_delta * (1 - coolant_heat_factor)))
		coolant_input.temperature = coolant_heat_transfer

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
	additive_damage[REACTOR_DAMAGE_EXTERNAL] = external_damage_immediate * clamp((emergency_point - damage) / emergency_point, 0, 1)
	external_damage_immediate = 0

	additive_damage[REACTOR_DAMAGE_HEAT] = clamp((temperature - temp_limit) / 24000, 0, 0.15)
	additive_damage[REACTOR_DAMAGE_PRESSURE] = clamp((pressure - REACTOR_PRESSURE_CRITICAL)/10000, 0, 0.1)
	additive_damage[REACTOR_HEALIUM] -= healium_restoration
	additive_damage[REACTOR_REPAIRS] -= integrity_restoration

	var/total_damage = 0
	for (var/damage_type in additive_damage)
		total_damage += additive_damage[damage_type]

	damage += total_damage
	damage = max(damage, 0)
	return additive_damage

/**
 * Collects Reactor statistical data for graphs on the tgui interface
 *
 * Updates:
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/list/pressureData]
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/list/tempCoreData]
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/list/tempInputData]
 * [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/list/tempOutputData]
 *
 * Returns: pressure and core, input, and output temperature data lists
 *//obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/collect_data()
	pressureData += pressure
	if(pressureData.len > 100) //Only lets you track over a certain timeframe.
		pressureData.Cut(1, 2)
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
	if(!temperature || !pressure || !temp_limit || !damage)
		return REACTOR_ERROR
	if(final_countdown)
		return REACTOR_MELTDOWN
	if(damage >= emergency_point)
		return REACTOR_EMERGENCY
	if(damage >= danger_point)
		return REACTOR_DANGER
	if(damage >= warning_point || temperature > temp_limit)
		return REACTOR_WARNING
	if(temperature > temp_limit * 0.8 || pressure > REACTOR_PRESSURE_CRITICAL * 0.8)
		return REACTOR_NOTIFY
	if(temperature > REACTOR_TEMPERATURE_OPERATING)
		return REACTOR_NORMAL
	return REACTOR_INACTIVE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_integrity_percent()
	var/integrity = damage / explosion_point
	integrity = 100 - (integrity * 100)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/get_temperature_percent()
	var/temperature_percent = temperature / temp_limit
	temperature_percent = (temperature_percent * 100)
	temperature_percent = temperature_percent < 0 ? 0 : temperature_percent
	return temperature_percent

// Any heat past this number will be clamped down
#define MAX_ACCEPTED_HEAT_OUTPUT 5000

// At the highest heat output, assuming no integrity changes, the threshold will be 0.
#define THRESHOLD_EQUATION_SLOPE (-1 / MAX_ACCEPTED_HEAT_OUTPUT)
#define CHANCE_EQUATION_SLOPE (RADIATION_CHANCE_AT_ZERO_INTEGRITY - RADIATION_CHANCE_AT_FULL_INTEGRITY)

// The higher this number, the faster low integrity will drop threshold
#define INTEGRITY_EXPONENTIAL_DEGREE 2
#define RADIATION_CHANCE_AT_FULL_INTEGRITY 0.05
#define RADIATION_CHANCE_AT_ZERO_INTEGRITY 0.5

//Calculates radiation levels that emit from the reactor
//Emits low radiation under normal operating conditions with full integrity
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/emit_radiation(seconds_per_tick)
	// As heat goes up, rads go up.
	var/power_factor = min(temperature, MAX_ACCEPTED_HEAT_OUTPUT)

	var/integrity = 1 - CLAMP01(damage / explosion_point)

	// At the "normal" output (with max integrity), this is 0.7, which is enough to be stopped
	// by the walls or the radation shutters.
	// As integrity does down, rads go up
	var/threshold
	switch(integrity)
		if(0)
			threshold = power_factor ? 0 : 1
		if(1)
			threshold = (THRESHOLD_EQUATION_SLOPE * power_factor + 1)
		else
			threshold = (THRESHOLD_EQUATION_SLOPE * power_factor + 1) ** ((1 / integrity) ** INTEGRITY_EXPONENTIAL_DEGREE)

	// Calculating chance is done entirely on integrity, so that actively damaged reactors feel more dangerous
	var/chance = (CHANCE_EQUATION_SLOPE * (1 - integrity)) + RADIATION_CHANCE_AT_FULL_INTEGRITY
	var/rad_intensity = (gas_radioactivity_mod*K*temperature*has_fuel()/(REACTOR_MAX_CRITICALITY*REACTOR_MAX_FUEL_RODS))
	var/rad_range = (rad_intensity/4)
	radiation_pulse(
		src,
		max_range = rad_range,
		threshold = threshold,
		chance = chance * 100,
		intensity = rad_intensity
	)

	//Emit Rad Particles
	if(integrity < 0.95) //
		var/particle_chance = min(gas_radioactivity_mod, 1000)
		while(particle_chance >= 200)
			fire_nuclear_particle()
			particle_chance -= 200
		if(prob(particle_chance))
			fire_nuclear_particle()

#undef MAX_ACCEPTED_HEAT_OUTPUT
#undef THRESHOLD_EQUATION_SLOPE
#undef INTEGRITY_EXPONENTIAL_DEGREE
#undef RADIATION_CHANCE_AT_FULL_INTEGRITY
#undef RADIATION_CHANCE_AT_ZERO_INTEGRITY

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

// Sets the reactor's ambient humming sound strength based on temperature and pressure
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/processing_sound()
	if(temperature > REACTOR_TEMPERATURE_OPERATING)
		var/temperature_effect = (temperature / temp_limit) * 20
		var/pressure_effect = (pressure / REACTOR_PRESSURE_CRITICAL) * 20
		reactor_hum.volume = clamp((temperature_effect + pressure_effect), 5, 90)

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
	data["waste_multiplier"] = waste_multiplier
	data["waste_multiplier_factors"] = list()
	for (var/factor in waste_multiplier_factors)
		var/amount = round(waste_multiplier_factors[factor], 0.01)
		if(!amount)
			continue
		data["waste_multiplier_factors"] += list(list(
			"name" = factor,
			"amount" = amount
		))
	data["pressureData"] = pressureData
	data["tempCoreData"] = tempCoreData
	data["tempInputData"] = tempInputData
	data["tempOutputData"] = tempOutputData
	data["coreTemp"] = round(temperature)
	data["coolantInput"] = round(last_coolant_temperature)
	data["coolantOutput"] = round(last_output_temperature)
	data["pressure"] = pressure
	data["pressureMax"] = REACTOR_PRESSURE_CRITICAL
	data["active"] = on
	data["shutdownTemp"] = REACTOR_TEMPERATURE_OPERATING

	data["rods"] = list()
	var/list/rod_data = list()
	var/index
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		index += (rod in fuel_rods)
		rod_data = list(list(
			"name" = rod.name,
			"depletion" = rod.depletion,
			"depletion_threshold" = rod.depletion_threshold,
			"rod_index" = index,
			))
		data["rods"] += rod_data

	data["absorbed_ratio"] = gas_absorption_constant
	var/list/formatted_gas_percentage = list()
	for (var/datum/gas/gas_path as anything in subtypesof(/datum/gas))
		formatted_gas_percentage[gas_path] = gas_percentage?[gas_path] || 0
	data["gas_composition"] = formatted_gas_percentage
	data["gas_temperature"] = moderator_gasmix.temperature
	data["gas_total_moles"] = moderator_gasmix.total_moles()
	return data
