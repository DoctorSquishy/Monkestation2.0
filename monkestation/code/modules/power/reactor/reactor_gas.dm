/proc/init_reactor_gas()
	var/list/gas_list = list()
	for (var/reactor_gas_path in subtypesof(/datum/reactor_gas))
		var/datum/reactor_gas/reactor_gas = new reactor_gas_path
		gas_list[reactor_gas.gas_path] = reactor_gas
	return gas_list

/// Return a list info of the reactor gases.
/// Can only run after init_reactor_gas
/proc/reactor_gas_data()
	var/list/data = list()
	for (var/gas_path in GLOB.reactor_gas_behavior)
		var/datum/reactor_gas/reactor_gas = GLOB.reactor_gas_behavior[gas_path]
		var/list/singular_gas_data = list()
		singular_gas_data["desc"] = reactor_gas.desc

		// Positive is true if more of the amount is a good thing.
		var/list/numeric_data = list()
		if(reactor_gas.heat_mod)
			numeric_data += list(list(
				"name" = "Core Heat Gain",
				"amount" = reactor_gas.heat_mod,
				"positive" = TRUE,
			))
		if(reactor_gas.heat_resistance)
			numeric_data += list(list(
				"name" = "Core Thermal Resistance",
				"amount" = reactor_gas.heat_resistance,
				"positive" = FALSE,
			))
		if(reactor_gas.radioactivity_mod)
			numeric_data += list(list(
				"name" = "Radioactivity",
				"amount" = reactor_gas.radioactivity_mod,
				"positive" = TRUE,
			))
		if(reactor_gas.control_mod)
			numeric_data += list(list(
				"name" = "Control Mod",
				"amount" = reactor_gas.control_mod,
				"positive" = TRUE,
			))
		if(reactor_gas.permeability_mod)
			numeric_data += list(list(
				"name" = "Core Temperature Permeability",
				"amount" = reactor_gas.permeability_mod,
				"positive" = TRUE,
			))
		if(reactor_gas.depletion_mod)
			numeric_data += list(list(
				"name" = "Waste Fuel",
				"amount" = reactor_gas.depletion_mod,
				"positive" = TRUE,
			))
		singular_gas_data["numeric_data"] = numeric_data
		data[gas_path] = singular_gas_data
	return data

// Assoc of reactor_gas_behavior[/datum/gas (path)] = datum/reactor_gas (instance)
GLOBAL_LIST_INIT(reactor_gas_behavior, init_reactor_gas())

// Contains effects of gases when absorbed by the reactor.
// If the gas has no effects you do not need to add another reactor_gas subtype,
// We already guard for nulls in [/obj/machinery/power/supermatter_crystal/proc/calculate_gases]
/datum/reactor_gas
	// Path of the [/datum/gas] involved with this interaction
	var/gas_path
	// How much more waste heat the reactor generates
	var/heat_mod = 0
	// How extra hot the reactor can run before taking damage
	var/heat_resistance = 0
	// Gases ability to transfer heat to coolant
	var/permeability_mod = 0
	// Increases the amount of radiation
	var/radioactivity_mod = 0
	// Increases control of criticality K
	var/control_mod = 0
	// Increases Fuel Rod Depletion
	var/depletion_mod = 0

	/// Give a short description of the gas if needed. If the gas have extra effects describe it here.
	var/desc

/datum/reactor_gas/proc/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	return

/datum/reactor_gas/oxygen
	gas_path = /datum/gas/oxygen
	heat_mod = 1
	heat_resistance = 1
	permeability_mod = 1
	radioactivity_mod = 1
	control_mod = 1
	depletion_mod = 1
	desc ="Oxygen EFFECT"

/datum/reactor_gas/oxygen/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/oxygen])
		return
	var/waste_production = 0.1 * reactor.waste_multiplier
	var/consumed_oxygen = reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] * waste_production
	if(!consumed_oxygen)
		return
	ASSERT_GAS(/datum/gas/oxygen, reactor.moderator_gasmix)
	ASSERT_GAS(/datum/gas/tritium, reactor.moderator_gasmix)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] -= consumed_oxygen
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += consumed_oxygen

/datum/reactor_gas/nitrogen
	gas_path = /datum/gas/nitrogen
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/carbon_dioxide
	gas_path = /datum/gas/carbon_dioxide
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/plasma
	gas_path = /datum/gas/plasma
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/water_vapor
	gas_path = /datum/gas/water_vapor
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/hypernoblium
	gas_path = /datum/gas/hypernoblium
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/nitrous_oxide
	gas_path = /datum/gas/nitrous_oxide
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/tritium
	gas_path = /datum/gas/tritium
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/bz
	gas_path = /datum/gas/bz
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/pluoxium
	gas_path = /datum/gas/pluoxium
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/miasma
	gas_path = /datum/gas/miasma
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/freon
	gas_path = /datum/gas/freon
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/hydrogen
	gas_path = /datum/gas/hydrogen
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/healium
	gas_path = /datum/gas/healium
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/proto_nitrate
	gas_path = /datum/gas/proto_nitrate
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/zauker
	gas_path = /datum/gas/zauker
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"

/datum/reactor_gas/antinoblium
	gas_path = /datum/gas/antinoblium
	heat_mod = 0
	heat_resistance = 0
	permeability_mod = 0
	radioactivity_mod = 0
	control_mod = 0
	depletion_mod = 0
	desc ="Oxygen EFFECT"
