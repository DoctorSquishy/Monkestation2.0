/datum/reactor_material
	// Path of the [/datum/material] involved
	var/material_path
	var/name = "Reactor_Material"
	var/id = "material"

	// <0: emits, 0: none
	var/neutron_emission = 0
	// 1.0 = full absorption, 0 = none
	var/neutron_absorption = 0
	// >0: slows neutrons, <0: speeds up
	var/moderation = 0
	// % U-235 for uranium, and other enrichment materials
	var/enrichment = 0

	// Can accumulate Wigner energy
	var/wigner_accum = FALSE
	// If 0, cannot anneal
	var/anneal_temperature = 0

	///Fission products made from reactor
	var/list/products

/datum/reactor_material/Uranium
	material_path = /datum/material/uranium
	id = "uranium"
	name = "Uranium"
	neutron_emission = 0.5
	neutron_absorption = 0.2
	moderation = 0
	enrichment = 0.05

	wigner_accum = FALSE
	anneal_temperature = 0
