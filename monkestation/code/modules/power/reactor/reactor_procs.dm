/*
/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/get_fuel_power()
	var/total_fuel_power = 0
	for(var/obj/item/fuel_rod/rod in fuel_rods)
		total_fuel_power += rod.fuel_power
	return total_fuel_power

// All the calculate procs should only update variables
// Move actual real-world effects to [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos]
/**
 * Perform calculation for variables that depend on core gases.
 * Updates:
 * [/var/list/gas_percentage]
 * [/var/gas_heat_mod]
 * [/var/gas_radioactivity_mod]
 * [/var/gas_control_mod]
 * [/var/gas_permeability_mod]
 * [/var/gas_depletion_mod]
 *
 * Returns: null
 **/
/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/calculate_gas_modifiers()
	gas_percentage = list()
	gas_heat_mod = 0
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
/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/calculate_waste_multiplier()
	waste_multiplier = 0
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
/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/calculate_criticality()
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

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/calculate_reactor_temp()
	if(has_fuel())
		temperature += REACTOR_HEAT_FACTOR * has_fuel() * ((REACTOR_HEAT_EXPONENT**K) - 1) // heating from K has to be exponential to make higher K more dangerous
	var/reactor_moles = reactor_core_gasmix.total_moles()
	if(reactor_moles >= minimum_coolant_level)
		temperature +=  (reactor_core_gasmix.return_temperature() * 0.25) // 25% as effective than the coolant inputs
		last_core_temperature = reactor_core_gasmix.return_temperature()
		//Important thing to remember, once you slot in the fuel rods, this thing will not stop making heat, at least, not unless you can live to be thousands of years old which is when the spent fuel finally depletes fully.
		var/heat_delta = (last_core_temperature - temperature) * gas_absorption_effectiveness //Take in the gas as a cooled input, cool the reactor a bit. The optimum, 100% balanced reaction sits at K=1, coolant input temp of 200K / -73 celsius.
		var/coolant_heat_factor = coolant_input.heat_capacity() / (coolant_input.heat_capacity() + REACTOR_HEAT_CAPACITY + (REACTOR_ROD_HEAT_CAPACITY * has_fuel())) //What percent of the total heat capacity is in the coolant
		last_heat_delta = heat_delta
		temperature += heat_delta * coolant_heat_factor
		//Heat the coolant output gas that we just had pass through us.
		var/coolant_heat_transfer = (last_core_temperature - (heat_delta * (1 - coolant_heat_factor)))
		reactor_core_gasmix.temperature = coolant_heat_transfer
*/
