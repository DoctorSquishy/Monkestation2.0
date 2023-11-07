// DEFINES FOR NUCLEAR REACTOR

// Index of each node in the list of nodes the reactor has
#define COOLANT_INPUT_GATE 1
#define MODERATOR_INPUT_GATE 2
#define COOLANT_OUTPUT_GATE 3

/// from /obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos(); when the Reactor sounds an audible alarm
#define COMSIG_REACTOR_MELTDOWN_ALARM "reactor_meltdown_alarm"

#define REACTOR_COUNTDOWN_TIME (30 SECONDS)

// Minimum temperature (400K) needed to run normally
#define REACTOR_TEMPERATURE_OPERATING 400
//Critical threshold of Reactor pressure (1000).
#define REACTOR_PRESSURE_CRITICAL 10000

#define REACTOR_HEAT_PENALTY_THRESHOLD 100 //Higher == Reactor safe operational temperature is higher.

#define REACTOR_HEAT_CAPACITY 6000 //How much thermal energy it takes to cool the reactor
#define REACTOR_ROD_HEAT_CAPACITY 400 //How much thermal energy it takes to cool each reactor rod
#define REACTOR_HEAT_EXPONENT 1.5 // The exponent used for the function for K heating
#define REACTOR_HEAT_FACTOR (20 / (REACTOR_HEAT_EXPONENT**2)) //How much heat from K

#define REACTOR_MAX_CRITICALITY 5 //No more criticality than N for now.
#define REACTOR_MAX_FUEL_RODS 5 //Maximum number of fuel rods that can fit in the reactor

#define REACTOR_PERMEABILITY_FACTOR 500 // How effective permeability-type moderators are
#define REACTOR_CONTROL_FACTOR 250 // How effective control-type moderators are

/// Means it's not forced, reactor decides itself by checking the [/datum/reactor_meltdown/proc/can_select]
#define REACTOR_MELTDOWN_PRIO_NONE 0
/// Purged when Reactor heals to 100
#define REACTOR_MELTDOWN_PRIO_IN_GAME 1

/// Purge the current forced meltdown and make it zero again (back to normal).
/// Needs to be higher priority than current forced_meltdown though.
#define REACTOR_MELTDOWN_STRATEGY_PURGE null
///Totally disable the processing of the Reactor
#define REACTOR_PROCESS_DISABLED -1
///Totally disable the processing of the Reactor, set when the timestop effect hits the Reactor
#define REACTOR_PROCESS_TIMESTOP 0
///Enable the Reactor to process atmos and internal procs
#define REACTOR_PROCESS_ENABLED 1

// 60 Second warning delay
#define REACTOR_WARNING_DELAY (60 SECONDS)

// These are used by supermatter and supermatter monitor program, mostly for UI updating purposes. Higher should always be worse!
// [/obj/machinery/power/supermatter_crystal/proc/get_status]
/// Unknown status, shouldn't happen but just in case.
#define REACTOR_ERROR -1
/// No or minimal energy
#define REACTOR_INACTIVE 0
/// Normal operation
#define REACTOR_NORMAL 1
/// Ambient temp 80% of the default temp for reactor to take damage
#define REACTOR_NOTIFY 2
/// Integrity below [/obj/machinery/power/supermatter_crystal/var/warning_point]. Start complaining on comms.
#define REACTOR_WARNING 3
/// Integrity below [/obj/machinery/power/supermatter_crystal/var/danger_point]. Start spawning anomalies.
#define REACTOR_DANGER 4
/// Integrity below [/obj/machinery/power/supermatter_crystal/var/emergency_point]. Start complaining to more people.
#define REACTOR_EMERGENCY 5
/// Currently counting down to meltdown. True [/obj/machinery/atmospherics/components/trinary/nuclear_reactor/var/final_countdown]
#define REACTOR_MELTDOWN 6

// These four internal damage factors, heat, power, moles, and heal heat dont depend on each other, but they are interlinked.
// They are going to be scaled to have a maximum damage hardcap of 1.8 per tick.
/// How many damage we take from heat.
#define REACTOR_DAMAGE_HEAT "Heat Damage"
/// How many damage we take from too much internal energy.
#define REACTOR_DAMAGE_PRESSURE "Pressure Damage"
/// How many damage do we take from external factors.
#define REACTOR_DAMAGE_EXTERNAL "External Damage"

/// How much waste multiplier we get just from existing.
#define REACTOR_WASTE_BASE "Base Waste Multiplier"
/// How much waste multiplier we get because of the gases around us.
#define REACTOR_WASTE_GAS "Gas Waste Multiplier"
/// How much waste multiplier we (don't) get because there is a psychologist.
#define REACTOR_WASTE_SOOTHED "Psychologist Waste Multiplier"

/// How many kelvins we get before taking damage, Given by god.
#define REACTOR_TEMP_LIMIT_BASE "Base Heat Resistance"
/// How many extra kelvins we get before taking damage, this time from gases.
/// Order matters, depends on base resistance.
#define REACTOR_TEMP_LIMIT_GAS "Gas Heat Resistance"
/// How many extra kelvins we get before taking damage, this time from psychologist.
#define REACTOR_TEMP_LIMIT_SOOTHED "Psychologist Heat Resistance"
/// How many extra kelvins we get before taking damage because our moles are low.
/// Order matters, depends on base resistance.
#define REACTOR_TEMP_LIMIT_LOW_MOLES "Low Moles Heat Resistance"
