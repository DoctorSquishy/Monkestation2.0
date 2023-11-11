/**
 * Adjusts the health of a simple mob by a set amount
 *
 * Arguments:
 * * amount The amount that will be used to adjust the mob's health
 * * updating_health If the mob's health should be immediately updated to the new value
 * * forced If we should force update the adjustment of the mob's health no matter the restrictions, like GODMODE
 */
/mob/living/basic/proc/adjust_health(amount, updating_health = TRUE, forced = FALSE)
	. = FALSE
	if(!forced && (status_flags & GODMODE))
		return 0
	. = bruteloss // bruteloss value before applying damage
	bruteloss = round(clamp(bruteloss + amount, 0, maxHealth * 2), DAMAGE_PRECISION)
	if(updating_health)
		updatehealth()
	return . - bruteloss

/mob/living/basic/get_damage_mod(damage_type)
	var/modifier = ..()
	if (damage_type in damage_coeff)
		return modifier * damage_coeff[damage_type]
	return modifier

/mob/living/basic/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && (status_flags & GODMODE))
		return 0
	if(on_damage_adjustment(BRUTE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return 0
	if(forced)
		. = adjust_health(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[BRUTE])
		. = adjust_health(amount * damage_coeff[BRUTE] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/basic/adjustFireLoss(amount, updating_health = TRUE, forced = FALSE, required_bodytype)
	if(!forced && (status_flags & GODMODE))
		return 0
	if(on_damage_adjustment(BURN, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return 0
	if(forced)
		. = adjust_health(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[BURN])
		. = adjust_health(amount * damage_coeff[BURN] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/basic/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype, required_respiration_type)
	if(!forced && (status_flags & GODMODE))
		return 0
	if(on_damage_adjustment(OXY, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return 0
	if(forced)
		. = adjust_health(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[OXY])
		. = adjust_health(amount * damage_coeff[OXY] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/basic/adjustToxLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype)
	if(!forced && (status_flags & GODMODE))
		return 0
	if(on_damage_adjustment(TOX, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return 0
	if(forced)
		. = adjust_health(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[TOX])
		. = adjust_health(amount * damage_coeff[TOX] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/basic/adjustCloneLoss(amount, updating_health = TRUE, forced = FALSE, required_biotype)
	if(on_damage_adjustment(CLONE, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return 0
	if(forced)
		. = adjust_health(amount * CONFIG_GET(number/damage_multiplier), updating_health, forced)
	else if(damage_coeff[CLONE])
		. = adjust_health(amount * damage_coeff[CLONE] * CONFIG_GET(number/damage_multiplier), updating_health, forced)

/mob/living/basic/pre_stamina_change(diff as num, forced)
	return diff * damage_coeff[STAMINA]
