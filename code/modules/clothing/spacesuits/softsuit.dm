	//NASA Voidsuit
/obj/item/clothing/head/helmet/space/nasavoid
	name = "NASA Void Helmet"
	desc = "An old, NASA CentCom branch designed, dark red space suit helmet."
	icon_state = "void"
	inhand_icon_state = "void_helmet"

/obj/item/clothing/suit/space/nasavoid
	name = "NASA Voidsuit"
	icon_state = "void"
	inhand_icon_state = "void_suit"
	desc = "An old, NASA CentCom branch designed, dark red space suit."
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/multitool)

/obj/item/clothing/head/helmet/space/nasavoid/old
	name = "Engineering Void Helmet"
	desc = "A CentCom engineering dark red space suit helmet. While old and dusty, it still gets the job done."
	icon_state = "void"

/obj/item/clothing/suit/space/nasavoid/old
	name = "Engineering Voidsuit"
	icon_state = "void"
	inhand_icon_state = "void_suit"
	desc = "A CentCom engineering dark red space suit. Age has degraded the suit making it difficult to move around in."
	slowdown = 4
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/multitool)

	//EVA suit
/obj/item/clothing/suit/space/eva
	name = "EVA suit"
	icon_state = "space"
	inhand_icon_state = "s_suit"
	desc = "A lightweight space suit with the basic ability to protect the wearer from the vacuum of space during emergencies."
	armor_type = /datum/armor/space_eva

/obj/item/clothing/head/helmet/space/eva
	name = "EVA helmet"
	icon_state = "space"
	inhand_icon_state = "space_helmet"
	desc = "A lightweight space helmet with the basic ability to protect the wearer from the vacuum of space during emergencies."
	flash_protect = FLASH_PROTECTION_NONE
	armor_type = /datum/armor/space_eva

/datum/armor/space_eva
	bio = 100
	fire = 50
	acid = 65

/obj/item/clothing/head/helmet/space/eva/examine(mob/user)
	. = ..()
	. += span_notice("You can start constructing a critter sized mecha with a [span_bold("cyborg leg")].")

/obj/item/clothing/head/helmet/space/eva/attackby(obj/item/attacked_with, mob/user, params)
	. = ..()
	if(.)
		return
	if(!istype(attacked_with, /obj/item/bodypart/leg/left/robot) && !istype(attacked_with, /obj/item/bodypart/leg/right/robot))
		return
	if(ismob(loc))
		user.balloon_alert(user, "drop the helmet first!")
		return
	user.balloon_alert(user, "leg attached")
	new /obj/item/bot_assembly/vim(loc)
	qdel(attacked_with)
	qdel(src)

	//Emergency suit with many MONKESTATION EDITS to make it crappy
/obj/item/clothing/head/helmet/space/fragile
	name = "emergency space helmet"
	desc = "A bulky, air-tight helmet meant to protect the user during emergency situations. It doesn't look very durable."
	var/torn = FALSE
	icon_state = "syndicate-helm-orange"
	inhand_icon_state = "syndicate-helm-orange" //resprite?
	armor_type = /datum/armor/space_fragile
	strip_delay = 65
	flash_protect = FLASH_PROTECTION_NONE //no free flash protect

//now to make it crap against facehuggers :)
/obj/item/clothing/head/helmet/space/fragile/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!torn && prob(10))
		to_chat(owner, span_warning("[src] tears from the damage, snapping the visor plate!"))
		clothing_flags &= ~STOPSPRESSUREDAMAGE
		clothing_flags &= ~HEADINTERNALS
		flags_cover &= ~HEADCOVERSEYES      //there has to be a better way to do this but i'm stupid
		flags_cover &= ~HEADCOVERSMOUTH
		flags_cover &= ~PEPPERPROOF
		name = "torn emergency space helmet"
		desc = "A bulky, air-tight helmet meant to protect the user during emergency situations, at least until someone snapped the visor plate."
		torn = TRUE
		playsound(loc, 'sound/weapons/slashmiss.ogg', 50, TRUE)
		playsound(loc, 'sound/effects/snap.ogg', 50, TRUE)


/obj/item/clothing/suit/space/fragile
	name = "emergency space suit"
	desc = "A bulky, air-tight suit meant to protect the user during emergency situations. It doesn't look very durable."
	var/torn = FALSE
	icon_state = "syndicate-orange"
	inhand_icon_state = "syndicate-orange"
	slowdown = 2
	armor_type = /datum/armor/space_fragile
	strip_delay = 65
	cell = /obj/item/stock_parts/cell/crap //might wanna actually increase this to a better cell, currently it runs out in a minute of use

/datum/armor/space_fragile
	melee = 5

/obj/item/clothing/suit/space/fragile/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(!torn && prob(10))
		to_chat(owner, span_warning("[src] tears from the damage, breaking the air-tight seal!"))
		clothing_flags &= ~STOPSPRESSUREDAMAGE
		name = "torn emergency space suit"
		desc = "A bulky suit meant to protect the user during emergency situations, at least until someone tore a hole in the suit."
		torn = TRUE
		playsound(loc, 'sound/weapons/slashmiss.ogg', 50, TRUE)
		playsound(loc, 'sound/effects/refill.ogg', 50, TRUE)
		playsound(loc, 'sound/effects/alert.ogg', 20, TRUE) //scare them
