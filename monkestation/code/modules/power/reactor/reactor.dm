/obj/machinery/atmospherics/components/trinary/nuclear_reactor
	name = "Advanced Gas-Cooled Nuclear Reactor"
	desc = "A tried and tested design which can output stable power at an acceptably low risk. The moderator can be changed to provide different effects."
	icon = 'monkestation/icons/obj/machines/reactor/reactor.dmi'
	base_icon_state = "reactor"
	icon_state = "reactor_map"
	pixel_x = -32
	pixel_y = -32
	pipe_flags = PIPING_ONE_PER_TURF
	density = FALSE //It burns you if you're stupid enough to walk over it
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	critical_machine = TRUE
	light_color = LIGHT_COLOR_CYAN
	dir = 8

	///The id of our reactor
	var/uid = 1
	///The amount of reactors that have been created this round
	var/static/gl_uid = 1

	///Only main engines can trigger nuclear armageddon, and can spawn stationwide anomalies.
	var/is_main_engine = FALSE

	///The point at which we consider the reactor to be [REACTOR_STATUS_WARNING]
	var/warning_point = 40
	var/warning_channel = RADIO_CHANNEL_ENGINEERING
	///The point at which we consider the reactor to be [REACTOR_STATUS_DANGER]
	///Spawns anomalies when more damaged than this too.
	var/danger_point = 60
	///The point at which we consider the reactor to be [REACTOR_STATUS_EMERGENCY]
	var/emergency_point = 75
	var/emergency_channel = null // Need null to actually broadcast
	///The point at which we delam [REACTOR_STATUS_MELTINGDOWN]
	var/explosion_point = 100
	///Are we exploding?
	var/final_countdown = FALSE
	///A scaling value that affects the severity of explosions
	var/explosion_power = 3
	///Time in 1/10th of seconds since the last sent warning
	var/lastwarning = 0

	/// The moderator gasmix we just recently absorbed for nuclear reactions. moderator_input multiplied by absorption_ratio
	var/datum/gas_mixture/moderator_gasmix
	/// The list of gases mapped against their current comp.
	/// We use this to calculate different values the reactor uses, like power or heat resistance.
	/// Ranges from 0 to 1
	var/list/gas_percentage
	/// How much more waste heat the reactor generates
	var/gas_heat_mod = 0
	// How extra hot the reactor can run before taking damage
	var/gas_heat_resistance = 0
	// Increases the amount of radiation
	var/gas_radioactivity_mod = 0
	// Increases control of criticality K
	var/gas_control_mod = 0
	// Gases ability to transfer heat to coolant
	var/gas_permeability_mod = 0
	// Gases effect on a fuel rod's fuel depletion
	var/gas_depletion_mod = 0

	/// Lose control of this -> Meltdown
	var/temperature = 0
	/// Lose control of this -> Blowout
	var/pressure = 0
	/// Rate of reaction.
	var/K = 0
	/// Control rod desired_k
	var/desired_k = 0
	//Starts off with a lot of control over K. If you flood this thing with plasma, you lose your ability to control K as easily.
	var/control_rod_effectiveness = 0.65
	var/last_user = null
	var/current_desired_k = null

	var/last_coolant_temperature = 0
	var/last_output_temperature = 0
	//For administrative cheating only. Knowing the delta lets you know EXACTLY what to set K at.
	var/last_heat_delta = 0

	//Amount of Fuels_rods in reactor
	var/list/fuel_rods = list()
	/// Default gas_absorption before being randomized slightly
	var/gas_absorption_effectiveness = 0.5
	/// We refer to this one as it's set on init, randomized.
	var/gas_absorption_constant = 0.5

	/// The minimum coolant level: 5 Moles
	var/minimum_coolant_level = 5
	/// Integrity restoration amount general repairs
	var/integrity_restoration = 0
	/// Integrity restoration amount via moderator Healium gas
	var/healium_restoration = 0
	/// External damage that are added to the reactor on next [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos] call.
	/// Reactor will not take damage if it's health is lower than emergency point.
	var/external_damage_immediate = 0
	///The amount of damage we have currently.
	var/damage = 0
	/// The damage we had before this cycle.
	/// Used to check if we are currently taking damage or healing.
	var/damage_archived = 0

	var/list/damage_factors
	/// The temperature at which we start taking damage
	var/temp_limit = T0C + REACTOR_HEAT_PENALTY_THRESHOLD
	var/list/temp_limit_factors
	/// Multiplies our waste gas amount
	var/waste_multiplier = 0
	var/list/waste_multiplier_factors

	/// Slag that reactor. Is this reactor even usable any more?
	var/slagged = FALSE

	///An effect we show to admins and ghosts the percentage of meltdown we're at
	var/obj/effect/countdown/reactor/countdown

	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng

	///Can it be moved?
	var/moveable = FALSE

	/// Disables all methods of taking damage.
	var/disable_damage = FALSE
	/// Disables the calculation of gas effects and production of waste.
	/// Reactor still "breathes" though, still takes gas and spits it out. Nothing is done on them though.
	/// Cleaner code this way. Get rid of if it's too wasteful.
	var/disable_gas = FALSE
	/// Disables power changes.
	var/disable_power_change = FALSE
	/// Disables the REACTOR's proccessing totally when set to REACTOR_PROCESS_DISABLED.
	/// Temporary disables the processing when it's set to REACTOR_PROCESS_TIMESTOP.
	/// Make sure gas_percentage isnt null if this is on REACTOR_PROCESS_DISABLED.
	var/disable_process = REACTOR_PROCESS_DISABLED

	///Do we show this reactor in the CIMS modular program
	var/include_in_cims = TRUE

	//Which channels should it broadcast to?
	var/engi_channel = RADIO_CHANNEL_ENGINEERING
	var/crew_channel = RADIO_CHANNEL_COMMON
	///Has the Reactor hit emergency threshold?
	var/has_hit_emergency = FALSE
	var/evacuation_procedures = FALSE

	/// How we are melting down?
	var/datum/reactor_meltdown/meltdown_strategy
	/// Whether the reactor is forced in a specific meltdown_strategy or not. All truthy values means it's forced.
	/// Only values greater or equal to the current one can change the strat.
	var/meltdown_priority = REACTOR_MELTDOWN_PRIO_NONE

	//Data for graphs
	var/list/pressureData = list()
	var/list/tempCoreData = list()
	var/list/tempInputData = list()
	var/list/tempOutputData = list()

	///Reactor soundloops
	var/datum/looping_sound/reactor_hum/reactor_hum
	var/datum/looping_sound/reactor_meltdown_alarm/meltdown_alarm

	//Grilling soundloop
	var/datum/looping_sound/grill/grill_loop
	var/obj/item/food/grilled_item
	var/grill_time = 0

	///given to connect_loc to listen for something moving over target
	var/static/list/crossed_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(reactor_crossed),
	)

//Normal Nuclear Reactor as main engine
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/engine
	is_main_engine = TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/Initialize(mapload)
	. = ..()
	icon_state = "reactor_off"
	gas_percentage = list()
	moderator_gasmix = new()
	uid = gl_uid++
	gas_absorption_effectiveness = rand(4, 6)/10 //All reactors are slightly different. This will result in you having to figure out what the balance is for K.
	gas_absorption_constant = gas_absorption_effectiveness //And set this up for the rest of the round.
	set_meltdown(REACTOR_MELTDOWN_PRIO_NONE, /datum/reactor_meltdown/core_meltdown)
	countdown = new(src)
	countdown.start()

	radio = new(src)
	radio.keyslot = new radio_key
	radio.set_listening(FALSE)
	radio.recalculateChannels()

	SSpoints_of_interest.make_point_of_interest(src)
	investigate_log("has been created.", INVESTIGATE_ENGINE)

	RegisterSignal(src, COMSIG_ATOM_BSA_BEAM, PROC_REF(force_meltdown))
	RegisterSignal(src, COMSIG_ATOM_TIMESTOP_FREEZE, PROC_REF(time_frozen))
	RegisterSignal(src, COMSIG_ATOM_TIMESTOP_UNFREEZE, PROC_REF(time_unfrozen))
	if(!moveable)
		move_resist = MOVE_FORCE_OVERPOWERING // Avoid being moved by statues or other memes

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/Destroy()
	SSair.stop_processing_machine(src)
	color = null
	radio_key = null
	grilled_item = null
	QDEL_NULL(radio)
	if(countdown)
		QDEL_NULL(countdown)
	if(reactor_hum)
		QDEL_NULL(reactor_hum)
	if(meltdown_alarm)
		QDEL_NULL(meltdown_alarm)
	if(grill_loop)
		QDEL_NULL(grill_loop)
	return ..()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/examine(mob/user)
	. = ..()
	if(Adjacent(src, user) || isobserver(user))
		var/msg
		if(slagged)
			msg = span_boldwarning("The reactor is destroyed. Its core lies exposed!")
		else
			msg = span_warning("The reactor looks operational.")
		switch(get_integrity_percent())
			if(0 to 10)
				msg = span_boldwarning("[src]'s seals are dangerously warped and you can see cracks all over the reactor vessel!")
			if(10 to 40)
				msg = span_boldwarning("[src]'s seals are heavily warped and cracked!")
			if(40 to 60)
				msg = span_warning("[src]'s seals are holding, but barely. You can see some micro-fractures forming in the reactor vessel.")
			if(60 to 80)
				msg = span_warning("[src]'s seals are in-tact, but slightly worn. There are no visible cracks in the reactor vessel.")
			if(80 to 90)
				msg = span_notice("[src]'s seals are in good shape, and there are no visible cracks in the reactor vessel.")
			if(95 to 100)
				msg = span_notice("[src]'s seals look factory new, and the reactor's in excellent shape.")
		. += msg

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/attackby(obj/item/held_obj, mob/user, params)
	if(istype(held_obj, /obj/item/fuel_rod))
		return try_insert_fuel(held_obj, user)
	if(istype(held_obj, /obj/item/sealant))
		if(slagged)
			to_chat(user, span_warning("The reactor has been critically damaged!"))
			return FALSE
		if(temperature > REACTOR_TEMPERATURE_OPERATING)
			to_chat(user, span_warning("You cannot repair [src] while the core temperature is above [REACTOR_TEMPERATURE_OPERATING] kelvin."))
			return FALSE
		if(get_integrity_percent() >= 100)
			to_chat(user, span_warning("[src]'s seals are already in-tact, repairing them further would require a new set of seals."))
			return FALSE
		if(get_integrity_percent() <= 60) //Heavily damaged.
			to_chat(user, span_warning("[src]'s reactor vessel is cracked and worn, you need to repair the cracks with a welder before you can repair the seals."))
			return FALSE
		while(do_after(user, 5 SECONDS, target=src))
			playsound(src, 'sound/effects/spray2.ogg', 50, 1, -6)
			integrity_restoration += 10
			integrity_restoration = clamp(integrity_restoration, 0, initial(integrity_restoration))
			update_appearance()
			if(get_integrity_percent() >= 100) // Check if it's done
				to_chat(user, span_warning("[src]'s seals are already in-tact, repairing them further would require a new set of seals."))
				return FALSE
			user.visible_message(span_warning("[user] applies sealant to some of [src]'s worn out seals."), span_notice("You apply sealant to some of [src]'s worn out seals."))
		return TRUE
	return ..()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/MouseDrop_T(atom/A, mob/living/user)
	if(user.incapacitated())
		return
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return
	if(istype(A, /obj/item/fuel_rod))
		try_insert_fuel(A, user)

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/crowbar_act(mob/living/user, obj/item/tool)
	if(slagged)
		to_chat(user, span_warning("The fuel rods have melted into a radioactive lump."))
	var/removal_time = 5 SECONDS
	if(temperature > REACTOR_TEMPERATURE_OPERATING)
		if(istype(tool, /obj/item/crowbar/power)) // Snatch the reactor from the jaws of death!
			removal_time *= 2
		else
			to_chat(user, span_warning("You can't remove fuel rods while the reactor is operating above [REACTOR_TEMPERATURE_OPERATING] kelvin!"))
			return TRUE
	if(!has_fuel())
		to_chat(user, span_notice("The reactor has no fuel rods!"))
		return TRUE

	var/obj/item/fuel_rod/rod = tgui_input_list(usr, "Select a fuel rod to remove", "Fuel Rods", fuel_rods)
	if(rod && istype(rod) && tool.use_tool(src, user, removal_time))
		if(temperature > REACTOR_TEMPERATURE_OPERATING)
			rod_removal_gas()
		user.rad_act(rod.fuel_power * 1000)
		playsound(src, 'monkestation/sound/effects/reactor/switch2.ogg', 100, TRUE)
		playsound(src, 'monkestation/sound/effects/reactor/crane_1.wav', 100, TRUE)
		var/obj/effect/fuel_rod/eject/rod_effect = new(get_turf(src))
		rod.moveToNullspace()
		fuel_rods.Remove(rod)
		sleep(3 SECONDS)
		if(!user.put_in_hands(rod))
			rod.forceMove(user.loc)
		playsound(src, 'monkestation/sound/effects/reactor/crane_return.ogg', 100, TRUE)
		playsound(src, pick('monkestation/sound/effects/reactor/switch.ogg','monkestation/sound/effects/reactor/switch2.ogg','monkestation/sound/effects/reactor/switch3.ogg'), 100, FALSE)
		sleep(5 SECONDS)
		qdel(rod_effect)
	return TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/welder_act(mob/living/user, obj/item/tool)
	if(slagged)
		to_chat(user, span_warning("The reactor has been critically damaged"))
		return TRUE
	if(temperature > REACTOR_TEMPERATURE_OPERATING)
		to_chat(user, span_warning("You can't repair [src] while it is running at above [REACTOR_TEMPERATURE_OPERATING] kelvin."))
		return TRUE
	if(get_integrity() > 50)
		to_chat(user, span_warning("[src] is free from cracks. Further repairs must be carried out with flexi-seal sealant."))
		return TRUE
	while(tool.use_tool(src, user, 2 SECONDS, volume=40))
		integrity_restoration += 20
		calculate_damage()
		if(get_integrity() > 50)
			to_chat(user, span_warning("[src] is free from cracks. Further repairs must be carried out with flexi-seal sealant."))
			return TRUE
		to_chat(user, span_notice("You weld together some of [src]'s cracks. This'll do for now."))
	return TRUE

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(istype(tool))
		to_chat(user, "<span class='notice'>You add \the [src]'s ID into the multitool's buffer.</span>")
		tool.buffer = src
		return TRUE

//Adds the finishing touches to grilled objects
/obj/machinery/grill/Exited(atom/movable/gone, direction)
	if(gone == grilled_item)
		finish_grill()
		grilled_item = null
	return ..()

//Processes the temperature effects from standing on top of the reactor such as grilling
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process(seconds_per_tick)
	// Meltdown this, blowout that, I just wanna grill for god's sake!
	for(var/atom/movable/atom_on_reactor in orange(1, src))
		if(isliving(atom_on_reactor))
			var/mob/living/living_mob = atom_on_reactor
			if(temperature > living_mob.bodytemperature)
				living_mob.adjust_bodytemperature(clamp(temperature, BODYTEMP_COOLING_MAX, BODYTEMP_HEATING_MAX)) //If you're on fire, you heat up!

		if(IS_EDIBLE(atom_on_reactor) && temperature >= REACTOR_TEMPERATURE_OPERATING)
			grilled_item = atom_on_reactor
			RegisterSignal(grilled_item, COMSIG_ITEM_GRILLED, PROC_REF(grill_completed))
			reactor_grilling(grilled_item)
			return

///Processes reactor gasses and the effects
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos(seconds_per_tick)
	..()
	// PRELIMINARIES
	if(disable_process != REACTOR_PROCESS_ENABLED || !on )
		return

	update_parents() //Make absolutely sure that pipe connections are updated
	/// Set pipe inputs and outputs
	var/datum/gas_mixture/coolant_input = airs[COOLANT_INPUT_GATE]
	var/datum/gas_mixture/moderator_input = airs[MODERATOR_INPUT_GATE]
	var/datum/gas_mixture/coolant_output = airs[COOLANT_OUTPUT_GATE]

	gas_radioactivity_mod = 1 + get_fuel_power() //Set fuel rod ambient radiation
	gas_absorption_effectiveness = gas_absorption_constant

	// MODERATOR GASSES
	if(moderator_input > 0)
		moderator_gasmix = moderator_input?.remove_ratio(gas_absorption_constant) || new()
		moderator_gasmix.volume = (moderator_input?.volume || CELL_VOLUME) * gas_absorption_constant // To match the pressure
		calculate_moderators() //updates moderator variables
	waste_multiplier_factors = calculate_waste_multiplier()
	var/control_bonus = gas_control_mod
	control_rod_effectiveness = initial(control_rod_effectiveness) + control_bonus
	gas_absorption_effectiveness = clamp(gas_absorption_constant + gas_permeability_mod, 0, 1)

	// CRITICALITY (K)
	calculate_criticality()

	// DAMAGE PROCESSING
	temp_limit_factors = calculate_temp_limit()
	damage_archived = damage
	damage_factors = calculate_damage()
	if(damage == 0) // Clear any in game forced delams if on full health
		set_meltdown(REACTOR_MELTDOWN_PRIO_IN_GAME, REACTOR_MELTDOWN_STRATEGY_PURGE)
	else
		set_meltdown(REACTOR_MELTDOWN_PRIO_NONE, REACTOR_MELTDOWN_STRATEGY_PURGE) // This one cant clear any forced meltdowns
	meltdown_strategy.meltdown_progress(src)
	if(damage > explosion_point && !final_countdown)
		count_down()

	// WASTE GASSES + EXTRA EFFECTS
	// Extra effects should always fire after the compositions are all finished
	// Handles Waste Gas and Extra Effects such as with Healium repairing reactor integrity
	for (var/gas_path in moderator_gasmix.gases)
		var/datum/reactor_gas/reactor_gas = GLOB.reactor_gas_behavior[gas_path]
		reactor_gas?.extra_effects(src)
	moderator_gasmix.temperature += (waste_multiplier * K)
	moderator_gasmix.garbage_collect() //recommended after using assert_gasses in extra effects

	// REACTOR TEMPERATURE
	calculate_reactor_temp()

	// Higher Pressured inputs means faster flow, basically limited to your pipe setup for output
	moderator_gasmix.pump_gas_to(coolant_output, moderator_gasmix.return_pressure())
	coolant_input.pump_gas_to(coolant_output, coolant_input.return_pressure())

	last_output_temperature = coolant_output.return_temperature()
	pressure = coolant_output.return_pressure()

	// RADIATION
	var/particle_chance = min(gas_radioactivity_mod, 1000)
	while(particle_chance >= 100)
		fire_nuclear_particle()
		particle_chance -= 100
	if(prob(particle_chance))
		fire_nuclear_particle()
	emit_radiation(seconds_per_tick)

	// EXTRA BEHAVIOUR
	collect_data()
	processing_sound()
	update_appearance()
	meltdown_strategy.lights(src)
	return TRUE

// ReactorMonitor UI for ghosts only. Inherited attack_ghost will call this.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/ui_interact(mob/user, datum/tgui/ui)
	if(!isobserver(user))
		return FALSE
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "Reactor")
		ui.open()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/ui_static_data(mob/user)
	var/list/data = list()
	data["reactor_gas_metadata"] = reactor_gas_data()
	return data

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/ui_data(mob/user)
	var/list/data = list()
	data["reactor_data"] = list(reactor_ui_data())
	return data

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_overlays()
	. = ..()
	switch(get_integrity_percent())
		if(0 to 20)
			. += mutable_appearance(icon = icon, icon_state ="[base_icon_state]_damaged_4")
		if(20 to 40)
			. += mutable_appearance(icon = icon, icon_state ="[base_icon_state]_damaged_3")
		if(40 to 60)
			. += mutable_appearance(icon = icon, icon_state ="[base_icon_state]_damaged_2")
		if(60 to 80)
			. += mutable_appearance(icon = icon, icon_state ="[base_icon_state]_damaged_1")
	return .

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/update_icon(updates)
	. = ..()
	icon_state = "[base_icon_state]_off"
	switch(get_temperature_percent())
		if(10 to 60)
			icon_state = "[base_icon_state]_on"
		if(60 to 75)
			icon_state = "[base_icon_state]_hot"
		if(75 to 90)
			icon_state = "[base_icon_state]_veryhot"
		if(90 to 100)
			icon_state = "[base_icon_state]_overheat"
		if(100 to INFINITY)
			icon_state = "[base_icon_state]_meltdown"
	if(!has_fuel() || !on)
		icon_state = "[base_icon_state]_off"
	if(slagged)
		icon_state = "[base_icon_state]_slagged"

/obj/effect/countdown/reactor
	name = "reactor damage"
	text_size = 1
	color = "#81FF14"

/obj/effect/countdown/reactor/get_value()
	var/obj/machinery/atmospherics/components/trinary/nuclear_reactor/reactor = attached_to
	if(!istype(reactor))
		return
	return "<div align='center' valign='middle' style='position:relative; top:0px; left:0px'>[round(reactor.get_integrity_percent())]%</div>"
