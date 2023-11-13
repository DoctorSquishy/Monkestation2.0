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
	// How much more waste heat and gasses the reactor generates
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

// TIER 1 GASSES
/datum/reactor_gas/oxygen
	gas_path = /datum/gas/oxygen
	heat_mod = 1
	permeability_mod = 2
	radioactivity_mod = 0.05
	desc ="Slightly increases heat and coolant efficiency. Byproducts: Tritium."

/datum/reactor_gas/oxygen/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/oxygen])
		return
	var/consumed_oxygen = reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] * reactor.waste_multiplier
	if(!consumed_oxygen)
		return
	reactor.moderator_gasmix.assert_gases(/datum/gas/oxygen, /datum/gas/tritium)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] -= consumed_oxygen
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += consumed_oxygen

/datum/reactor_gas/nitrogen
	gas_path = /datum/gas/nitrogen
	heat_mod = -2
	heat_resistance = 1
	permeability_mod = 2
	radioactivity_mod = 0.02
	control_mod = 50
	desc ="Increases the control of criticality (K) and the effectiveness of the control rods. Byproducts: Tritium."

/datum/reactor_gas/nitrogen/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/nitrogen])
		return
	var/consumed_nitrogen = reactor.moderator_gasmix.gases[/datum/gas/nitrogen][MOLES] * reactor.waste_multiplier
	if(!consumed_nitrogen)
		return
	reactor.moderator_gasmix.assert_gases(/datum/gas/nitrogen, /datum/gas/tritium)
	reactor.moderator_gasmix.gases[/datum/gas/nitrogen][MOLES] -= consumed_nitrogen
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += consumed_nitrogen

/datum/reactor_gas/carbon_dioxide
	gas_path = /datum/gas/carbon_dioxide
	heat_mod = -4
	heat_resistance = 3
	radioactivity_mod = 0.08
	control_mod = 100
	desc ="Helps suppress and control reactor reactions in exchange for increased radiation and less heat. Byproducts: Tritium."

/datum/reactor_gas/carbon_dioxide/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/carbon_dioxide])
		return
	var/consumed_carbon_dioxide = reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] * reactor.waste_multiplier
	if(!consumed_carbon_dioxide)
		return
	reactor.moderator_gasmix.assert_gases(/datum/gas/carbon_dioxide, /datum/gas/tritium)
	reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] -= consumed_carbon_dioxide
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += consumed_carbon_dioxide

/datum/reactor_gas/plasma
	gas_path = /datum/gas/plasma
	heat_mod = 2
	radioactivity_mod = 0.06
	desc ="Basic heat output. Byproducts: Tritium."

/datum/reactor_gas/plasma/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/plasma])
		return
	var/consumed_plasma = reactor.moderator_gasmix.gases[/datum/gas/plasma][MOLES] * reactor.waste_multiplier
	if(!consumed_plasma)
		return
	reactor.moderator_gasmix.assert_gases(/datum/gas/plasma, /datum/gas/tritium)
	reactor.moderator_gasmix.gases[/datum/gas/plasma][MOLES] -= consumed_plasma
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += consumed_plasma


// TIER 2 GASSES
/datum/reactor_gas/water_vapor
	gas_path = /datum/gas/water_vapor
	heat_mod = 6
	heat_resistance = 2
	permeability_mod = 20
	desc ="Increases coolant efficiency and heat output. Byproducts: Tritium, Hydrogen, Oxygen."

/datum/reactor_gas/water_vapor/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/water_vapor])
		return
	var/consumed_water_vapor = reactor.moderator_gasmix.gases[/datum/gas/water_vapor][MOLES] * reactor.waste_multiplier
	if(!consumed_water_vapor)
		return
	reactor.moderator_gasmix.assert_gases(/datum/gas/water_vapor,
		/datum/gas/tritium,
		/datum/gas/hydrogen,
		/datum/gas/oxygen
		)
	reactor.moderator_gasmix.gases[/datum/gas/water_vapor][MOLES] -= consumed_water_vapor
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_water_vapor * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/hydrogen][MOLES] += (consumed_water_vapor * 0.55)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] += (consumed_water_vapor * 0.35)

/datum/reactor_gas/nitrous_oxide
	gas_path = /datum/gas/nitrous_oxide
	heat_mod = -1
	heat_resistance = 5
	permeability_mod = 4
	radioactivity_mod = 0.02
	desc ="Reduces heat ouput, increaes coolant efficiency, and slightly increases temperature limits. Byproducts: Tritium, Nitrogen, Oxygen."

/datum/reactor_gas/nitrous_oxide/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/nitrous_oxide])
		return
	var/consumed_nitrous_oxide = reactor.moderator_gasmix.gases[/datum/gas/nitrous_oxide][MOLES] * reactor.waste_multiplier
	if(!consumed_nitrous_oxide)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/nitrous_oxide,
		/datum/gas/tritium,
		/datum/gas/nitrogen,
		/datum/gas/oxygen
		)
	reactor.moderator_gasmix.gases[/datum/gas/nitrous_oxide][MOLES] -= consumed_nitrous_oxide
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_nitrous_oxide * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/nitrogen][MOLES] += (consumed_nitrous_oxide * 0.35)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] += (consumed_nitrous_oxide * 0.55)

/datum/reactor_gas/tritium
	gas_path = /datum/gas/tritium
	heat_mod = 12
	radioactivity_mod = 0.2
	control_mod = -50
	depletion_mod = 0.08
	desc ="Significantly increases heat and radiation output while making criticality (K) harder to control and depleting fuel rods slightly faster. Byproducts: Plasma, Water Vapor."

/datum/reactor_gas/tritium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/tritium])
		return
	var/consumed_tritium = reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] * reactor.waste_multiplier
	if(!consumed_tritium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/tritium,
		/datum/gas/plasma,
		/datum/gas/water_vapor
		)
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] -= consumed_tritium
	reactor.moderator_gasmix.gases[/datum/gas/plasma][MOLES] += (consumed_tritium * 0.4)
	reactor.moderator_gasmix.gases[/datum/gas/water_vapor][MOLES] += (consumed_tritium * 0.6)


// TIER 3 GASSES
/datum/reactor_gas/bz
	gas_path = /datum/gas/bz
	heat_mod = 5
	heat_resistance = 2
	permeability_mod = 10
	radioactivity_mod = 0.15
	desc ="Increases heat and radiation output, temperature limits, and coolant efficiency. Byproducts: Plasma, Nitrous Oxide."

/datum/reactor_gas/bz/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/bz])
		return
	var/consumed_bz = reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] * reactor.waste_multiplier
	if(!consumed_bz)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/bz,
		/datum/gas/tritium,
		/datum/gas/plasma,
		/datum/gas/nitrous_oxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] -= consumed_bz
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] -= (consumed_bz * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/plasma][MOLES] += (consumed_bz * 0.45)
	reactor.moderator_gasmix.gases[/datum/gas/nitrous_oxide][MOLES] += (consumed_bz * 0.45)

/datum/reactor_gas/hydrogen
	gas_path = /datum/gas/hydrogen
	heat_mod = 10
	heat_resistance = 1
	radioactivity_mod = 0.06
	depletion_mod = 0.3
	desc ="Significantly increases heat output and control rod depletion. Byproducts: Tritium, Helium."

/datum/reactor_gas/hydrogen/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/hydrogen])
		return
	var/consumed_hydrogen = reactor.moderator_gasmix.gases[/datum/gas/hydrogen][MOLES] * reactor.waste_multiplier
	if(!consumed_hydrogen)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/hydrogen,
		/datum/gas/tritium
		)
	reactor.moderator_gasmix.gases[/datum/gas/hydrogen][MOLES] -= consumed_hydrogen
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_hydrogen * 0.8)
	reactor.moderator_gasmix.gases[/datum/gas/helium][MOLES] += (consumed_hydrogen * 0.2) //Hydrogen gains two neutrons from the reaction turning into tritium which decays into helium-3 through magic science.

/datum/reactor_gas/miasma
	gas_path = /datum/gas/miasma
	heat_mod = 5
	radioactivity_mod = 0.3
	control_mod = -20
	desc ="Increases heat and radiation output. Slightly reduces control of criticality (K). Byproducts: Tritium, Water Vapor, Oxygen, Hydrogen, CO2."

/datum/reactor_gas/miasma/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/miasma])
		return
	var/consumed_miasma = reactor.moderator_gasmix.gases[/datum/gas/miasma][MOLES] * reactor.waste_multiplier
	if(!consumed_miasma)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/miasma,
		/datum/gas/tritium,
		/datum/gas/water_vapor,
		/datum/gas/oxygen,
		/datum/gas/hydrogen,
		/datum/gas/carbon_dioxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/miasma][MOLES] -= consumed_miasma
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_miasma * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/water_vapor][MOLES] += (consumed_miasma * 0.5)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] += (consumed_miasma * 0.2)
	reactor.moderator_gasmix.gases[/datum/gas/hydrogen][MOLES] -= (consumed_miasma * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] -= (consumed_miasma * 0.1)

/datum/reactor_gas/nitrium
	gas_path = /datum/gas/nitrium
	heat_mod = 6
	heat_resistance = 2
	radioactivity_mod = 0.1
	control_mod = -30
	permeability_mod = 20
	depletion_mod = 0.1
	desc ="Increases heat, radiation output, heat resistance, and fuel rod depletion inexchange for reduced control of criticality (K). Byproducts: Tritium, Nitrogen, BZ."

/datum/reactor_gas/nitrium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/nitrium])
		return
	var/consumed_nitrium = reactor.moderator_gasmix.gases[/datum/gas/nitrium][MOLES] * reactor.waste_multiplier
	if(!consumed_nitrium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/nitrium,
		/datum/gas/tritium,
		/datum/gas/nitrogen,
		/datum/gas/bz
		)
	reactor.moderator_gasmix.gases[/datum/gas/nitrium][MOLES] -= consumed_nitrium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_nitrium * 0.6)
	reactor.moderator_gasmix.gases[/datum/gas/nitrogen][MOLES] += (consumed_nitrium * 0.3)
	reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] += (consumed_nitrium * 0.1)

/datum/reactor_gas/pluoxium
	gas_path = /datum/gas/pluoxium
	heat_mod = -2
	heat_resistance = 1
	control_mod = 150
	desc ="Gives a strong control of criticality (K) in exchange for less heat output. Byproducts: Tritium, Oxygen, CO2."

/datum/reactor_gas/pluoxium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/pluoxium])
		return
	var/consumed_pluoxium = reactor.moderator_gasmix.gases[/datum/gas/pluoxium][MOLES] * reactor.waste_multiplier
	if(!consumed_pluoxium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/pluoxium,
		/datum/gas/tritium,
		/datum/gas/oxygen,
		/datum/gas/carbon_dioxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/pluoxium][MOLES] -= consumed_pluoxium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_pluoxium * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/oxygen][MOLES] += (consumed_pluoxium * 0.6)
	reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] += (consumed_pluoxium * 0.3)


// TIER 4 GASSES
/datum/reactor_gas/freon
	gas_path = /datum/gas/freon
	heat_mod = -10
	heat_resistance = 6
	permeability_mod = 40
	desc ="Improves heat resistance and coolant efficiency in exchange for significantly reduced heat output. Byproducts: Tritium, Plasma, CO2, BZ."

/datum/reactor_gas/freon/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/freon])
		return
	var/consumed_freon= reactor.moderator_gasmix.gases[/datum/gas/freon][MOLES] * reactor.waste_multiplier
	if(!consumed_freon)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/freon,
		/datum/gas/tritium,
		/datum/gas/plasma,
		/datum/gas/carbon_dioxide,
		/datum/gas/bz
		)
	reactor.moderator_gasmix.gases[/datum/gas/freon][MOLES] -= consumed_freon
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_freon * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/plasma][MOLES] += (consumed_freon * 0.4)
	reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] += (consumed_freon * 0.2)
	reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] += (consumed_freon * 0.1)

/datum/reactor_gas/halon
	gas_path = /datum/gas/halon
	heat_mod = 4
	heat_resistance = 2
	radioactivity_mod = 0.10
	control_mod = 100
	desc ="Gives a better control of criticality (K) and an increase of heat and radiation output. Byproducts: Tritium, Plasma, CO2, BZ."

/datum/reactor_gas/halon/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/halon])
		return
	var/consumed_halon= reactor.moderator_gasmix.gases[/datum/gas/halon][MOLES] * reactor.waste_multiplier
	if(!consumed_halon)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/halon,
		/datum/gas/tritium,
		/datum/gas/carbon_dioxide,
		/datum/gas/nitrous_oxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/halon][MOLES] -= consumed_halon
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_halon * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/carbon_dioxide][MOLES] += (consumed_halon * 0.6)
	reactor.moderator_gasmix.gases[/datum/gas/nitrous_oxide][MOLES] += (consumed_halon * 0.3)

/datum/reactor_gas/helium
	gas_path = /datum/gas/helium
	heat_mod = -6
	heat_resistance = 5
	control_mod = 75
	desc ="Increases heat resistance and control of criticality (K) in exchange for a loss of heat output. Byproducts: Tritium, Proto-Nitrate, BZ."

/datum/reactor_gas/helium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/helium])
		return
	var/consumed_helium= reactor.moderator_gasmix.gases[/datum/gas/helium][MOLES] * reactor.waste_multiplier
	if(!consumed_helium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/helium,
		/datum/gas/tritium,
		/datum/gas/carbon_dioxide,
		/datum/gas/nitrous_oxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/helium][MOLES] -= consumed_helium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_helium * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/proto_nitrate][MOLES] += (consumed_helium * 0.45)
	reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] += (consumed_helium * 0.45)


// TIER 5 GASSES
/datum/reactor_gas/antinoblium
	gas_path = /datum/gas/antinoblium
	heat_mod = 15
	heat_resistance = 10
	permeability_mod = 50
	radioactivity_mod = 0.5
	control_mod = -50
	desc ="Vastly increases coolant efficiency, heat output, and temperature resistance in exchange for a loss of control of criticality (K). Byproducts: Tritium, Hyper-noblium."

/datum/reactor_gas/antinoblium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/antinoblium])
		return
	var/consumed_antinoblium = reactor.moderator_gasmix.gases[/datum/gas/antinoblium][MOLES] * reactor.waste_multiplier
	if(!consumed_antinoblium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/antinoblium,
		/datum/gas/tritium,
		/datum/gas/hypernoblium,
		/datum/gas/nitrous_oxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/antinoblium][MOLES] -= consumed_antinoblium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_antinoblium * 0.2)
	reactor.moderator_gasmix.gases[/datum/gas/hypernoblium][MOLES] += (consumed_antinoblium * 0.8)

/datum/reactor_gas/healium
	gas_path = /datum/gas/healium
	heat_mod = 5
	heat_resistance = 5
	radioactivity_mod = 1
	control_mod = 100
	depletion_mod = 0.2
	desc ="Very effective control gas with the ability heal the reactor in exchange for signicant increase in radiation and fuel rod depletion. Byproducts: Tritium, Freon, BZ."

/datum/reactor_gas/healium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/healium])
		return

	reactor.integrity_restoration = max((2400 - max(TCMB, reactor.temperature))/300) //At 1800K integrity_restoration should be around 1
	var/consumed_healium = reactor.moderator_gasmix.gases[/datum/gas/healium][MOLES] * reactor.waste_multiplier
	if(!consumed_healium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/healium,
		/datum/gas/tritium,
		/datum/gas/hypernoblium,
		/datum/gas/nitrous_oxide
		)
	reactor.moderator_gasmix.gases[/datum/gas/healium][MOLES] -= consumed_healium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_healium * 0.2)
	reactor.moderator_gasmix.gases[/datum/gas/hypernoblium][MOLES] += (consumed_healium * 0.8)

/datum/reactor_gas/hypernoblium
	gas_path = /datum/gas/hypernoblium
	heat_mod = -15
	radioactivity_mod = 10
	control_mod = 50
	desc ="Significantly reduces heat output in exhange for an insane amount of radiation output. Byproducts: Tritium, Nitrogen, BZ."

/datum/reactor_gas/hypernoblium/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/hypernoblium])
		return
	var/consumed_hypernoblium = reactor.moderator_gasmix.gases[/datum/gas/hypernoblium][MOLES] * reactor.waste_multiplier
	if(!consumed_hypernoblium)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/hypernoblium,
		/datum/gas/tritium,
		/datum/gas/nitrogen,
		/datum/gas/bz
		)
	reactor.moderator_gasmix.gases[/datum/gas/hypernoblium][MOLES] -= consumed_hypernoblium
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_hypernoblium * 0.4)
	reactor.moderator_gasmix.gases[/datum/gas/nitrogen][MOLES] += (consumed_hypernoblium * 0.3)
	reactor.moderator_gasmix.gases[/datum/gas/bz][MOLES] += (consumed_hypernoblium * 0.3)

/datum/reactor_gas/proto_nitrate
	gas_path = /datum/gas/proto_nitrate
	heat_mod = 5
	radioactivity_mod = 10
	control_mod = -150
	depletion_mod = 0.3
	permeability_mod = 50
	desc ="Reactions go fast! Deplete the hell out of those fuel rods if you can control it that is. Byproducts: Tritium, Pluoxium, Hydrogen."

/datum/reactor_gas/proto_nitrate/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/proto_nitrate])
		return
	var/consumed_proto_nitrate = reactor.moderator_gasmix.gases[/datum/gas/proto_nitrate][MOLES] * reactor.waste_multiplier
	if(!consumed_proto_nitrate)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/proto_nitrate,
		/datum/gas/tritium,
		/datum/gas/pluoxium,
		/datum/gas/hydrogen
		)
	reactor.moderator_gasmix.gases[/datum/gas/proto_nitrate][MOLES] -= consumed_proto_nitrate
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_proto_nitrate * 0.4)
	reactor.moderator_gasmix.gases[/datum/gas/pluoxium][MOLES] += (consumed_proto_nitrate * 0.2)
	reactor.moderator_gasmix.gases[/datum/gas/hydrogen][MOLES] += (consumed_proto_nitrate * 0.4)

/datum/reactor_gas/zauker
	gas_path = /datum/gas/zauker
	heat_mod = 66.6
	heat_resistance = 66.6
	radioactivity_mod = 6.66
	control_mod = -66.6
	permeability_mod = 6.66
	depletion_mod = 0.666
	desc = "Hope your ready for a divine journey through hell. Byproducts: Tritium, Hyper-Noblium, Nitrium."

/datum/reactor_gas/zauker/extra_effects(obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor)
	if(!reactor.gas_percentage[/datum/gas/zauker])
		return
	var/consumed_zauker = reactor.moderator_gasmix.gases[/datum/gas/zauker][MOLES] * reactor.waste_multiplier
	if(!consumed_zauker)
		return
	reactor.moderator_gasmix.assert_gases(
		/datum/gas/proto_nitrate,
		/datum/gas/tritium,
		/datum/gas/hypernoblium,
		/datum/gas/nitrium
		)
	reactor.moderator_gasmix.gases[/datum/gas/zauker][MOLES] -= consumed_zauker
	reactor.moderator_gasmix.gases[/datum/gas/tritium][MOLES] += (consumed_zauker * 0.5)
	reactor.moderator_gasmix.gases[/datum/gas/hypernoblium][MOLES] += (consumed_zauker * 0.1)
	reactor.moderator_gasmix.gases[/datum/gas/nitrium][MOLES] += (consumed_zauker * 0.4)
