// DEFINES FOR NUCLEAR REACTOR

// Index of each node in the list of nodes the reactor has
#define COOLANT_INPUT_GATE 1
#define MODERATOR_INPUT_GATE 2
#define COOLANT_OUTPUT_GATE 3

/// from /obj/machinery/atmospherics/components/trinary/nuclear_reactor/process_atmos(); when the Reactor sounds an audible alarm
#define COMSIG_REACTOR_MELTDOWN_ALARM "reactor_meltdown_alarm"

#define REACTOR_COUNTDOWN_TIME (30 SECONDS)

// Minimum temperature (300K) needed to run normally
#define REACTOR_TEMPERATURE_OPERATING 300
//Critical threshold of Reactor pressure (10000).
#define REACTOR_PRESSURE_CRITICAL 10000
//Higher == Reactor safe operational temperature is higher.
#define REACTOR_HEAT_PENALTY_THRESHOLD 600

#define REACTOR_HEAT_CAPACITY 6000 //How much thermal energy it takes to cool the reactor
#define REACTOR_ROD_HEAT_CAPACITY 400 //How much thermal energy it takes to cool each reactor rod
#define REACTOR_HEAT_EXPONENT 1.5 // The exponent used for the function for K heating
#define REACTOR_HEAT_FACTOR (20 / (REACTOR_HEAT_EXPONENT**2)) //How much heat from K

#define REACTOR_MAX_CRITICALITY 5 //No more criticality than N for now.
#define REACTOR_MAX_FUEL_RODS 10 //Maximum number of fuel rods that can fit in the reactor

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
/// Integrity below [/obj/machinery/power/supermatter_crystal/var/danger_point]. Start showing some dangerous behaviors.
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
/// How much damage is healed through healium gas as a moderator
#define REACTOR_HEALIUM "Healium Healing"
/// How much damage is healed through general repairs on the reactor
#define REACTOR_REPAIRS "Reactor Repairs"

/// How much waste multiplier we get just from existing.
#define REACTOR_WASTE_BASE "Base Waste Multiplier"
/// How much waste multiplier we get because of the gases interacting with the cores.
#define REACTOR_WASTE_GAS "Gas Waste Multiplier"
/// How much waste multiplier we get because of the core temperature reaching higher levels.
#define REACTOR_WASTE_TEMP "Temperature Waste Multiplier"

/// How many kelvins we get before taking damage, Given by god.
#define REACTOR_TEMP_LIMIT_BASE "Base Heat Resistance"
/// How many extra kelvins we get before taking damage, this time from gases.
/// Order matters, depends on base resistance.
#define REACTOR_TEMP_LIMIT_GAS "Gas Heat Resistance"
/// How many extra kelvins we get before taking damage because our moles are low.
/// Order matters, depends on base resistance.
#define REACTOR_TEMP_LIMIT_LOW_MOLES "Low Moles Heat Resistance"
/// For connecting pumps with a control computer
#define RADIO_ATMOSIA "atmosia"
