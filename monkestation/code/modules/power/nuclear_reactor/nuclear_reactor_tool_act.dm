/// Reactor vessel

#define ICON_SPLIT world.icon_size/3
#define ICON_SPLIT_DOUBLE (world.icon_size/3)*2
#define ICON_SPLIT_TRIPLE world.icon_size

#define TOP_LEFT 1
#define TOP_MIDDLE 2
#define TOP_RIGHT 3
#define MIDDLE_LEFT 4
#define MIDDLE_MIDDLE 5
#define MIDDLE_RIGHT 6
#define BOTTOM_LEFT 7
#define BOTTOM_MIDDLE 8
#define BOTTOM_RIGHT 9

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/attackby(obj/item/held_obj, mob/user, params)
	var/list/modifiers = params2list(params)
	if(istype(held_obj, /obj/item/reactor_rod))
		rod_act(held_obj, user, modifiers)
	return ..()

/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/MouseDrop_T(obj/item/held_obj, mob/living/user, params)
	var/list/modifiers = params2list(params)
	if(user.incapacitated())
		return
	if(!ISADVANCEDTOOLUSER(user))
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return
	if(istype(held_obj, /obj/item/reactor_rod))
		rod_act(held_obj, user, modifiers)

//Insert or extract reactor rod
/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/rod_act(obj/item/held_obj, mob/user, modifiers)
	if(!istype(held_obj, /obj/item/reactor_rod))
		return
	var/rod_choice = select_rod(modifiers, user) //Returns a number 1-9
	//Define a mapping of positions for each rod_choice
	var/list/rod_positions = list(
		TOP_LEFT = list(0, 0),
		TOP_MIDDLE = list(10, 0),
		TOP_RIGHT = list(20, 0),
		MIDDLE_LEFT = list(0, -10),
		MIDDLE_MIDDLE = list(10, -10),
		MIDDLE_RIGHT = list(20, -10),
		BOTTOM_LEFT = list(0, -20),
		BOTTOM_MIDDLE = list(10, -20),
		BOTTOM_RIGHT = list(20, -20)
	)
	//Check if the conduit is already occupied
	if(conduits[rod_choice])
		to_chat(user, span_warning("A rod is already occupying this conduit."))
		return // Stop further execution if the rod is already inserted

	//Check if the conduit_[rod_choice] is true; if not, create a new conduit
	var/obj/machinery/reactor_conduit/conduit = new /obj/machinery/reactor_conduit(src.loc)
	conduit.conduit_num = rod_choice
	conduit.conduit_id(rod_choice)

	//Fetch the predefined position for the rod_choice and offset the icon
	var/icon_x = rod_positions[rod_choice][1] // X-offset
	var/icon_y = rod_positions[rod_choice][2] // Y-offset
	conduit.pixel_x = icon_x
	conduit.pixel_y = icon_y

	//Places rod into new conduit
	conduit.rod = held_obj
	held_obj.forceMove(conduit.rod)

	//Mark this conduit as occupied in conduits list
	conduits[rod_choice] = TRUE // Register conduit as active
	to_chat(user, span_notice("Rod successfully inserted into conduit [rod_choice]."))
	return


/obj/machinery/atmospherics/components/quaternary/nuclear_reactor/proc/select_rod(modifiers, user)
	var/icon_x = text2num(modifiers[ICON_X])
	var/icon_y = text2num(modifiers[ICON_Y])

	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT) // less than 10  less than 10
		to_chat(user, span_warning("Bottom Left"))
		return BOTTOM_LEFT
	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT_DOUBLE) // less than 10 less than 20
		to_chat(user, span_warning("Middle Left"))
		return MIDDLE_LEFT
	if(icon_x < ICON_SPLIT && icon_y < ICON_SPLIT_TRIPLE) // less than 10 less than 30
		to_chat(user, span_warning("Top Left"))
		return TOP_LEFT

	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT)
		to_chat(user, span_warning("Bottom Middle"))
		return BOTTOM_MIDDLE
	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT_DOUBLE)
		to_chat(user, span_warning("Middle Middle"))
		return MIDDLE_MIDDLE
	if(icon_x < ICON_SPLIT_DOUBLE && icon_y < ICON_SPLIT_TRIPLE)
		to_chat(user, span_warning("Middle Top"))
		return TOP_MIDDLE

	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT)
		to_chat(user, span_warning("Bottom Right"))
		return BOTTOM_RIGHT
	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT_DOUBLE)
		to_chat(user, span_warning("Middle Right"))
		return MIDDLE_RIGHT
	if(icon_x < ICON_SPLIT_TRIPLE && icon_y < ICON_SPLIT_TRIPLE)
		to_chat(user, span_warning("Top Right"))
		return TOP_RIGHT


#undef BOTTOM_LEFT
#undef MIDDLE_LEFT
#undef TOP_LEFT
#undef BOTTOM_MIDDLE
#undef MIDDLE_MIDDLE
#undef TOP_MIDDLE
#undef BOTTOM_RIGHT
#undef MIDDLE_RIGHT
#undef TOP_RIGHT

#undef ICON_SPLIT
#undef ICON_SPLIT_DOUBLE
#undef ICON_SPLIT_TRIPLE
