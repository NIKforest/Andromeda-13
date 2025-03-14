GLOBAL_LIST_EMPTY(ghost_images_default) //this is a list of the default (non-accessorized, non-dir) images of the ghosts themselves
GLOBAL_LIST_EMPTY(ghost_images_simple) //this is a list of all ghost images as the simple white ghost
GLOBAL_LIST_INIT(ghost_verbs, list(
		/mob/dead/observer/proc/dead_tele,
		/mob/dead/observer/proc/open_spawners_menu,
		/mob/dead/observer/proc/view_gas))
GLOBAL_VAR_INIT(observer_default_invisibility, INVISIBILITY_OBSERVER)

/mob/dead/observer
	name = "ghost"
	desc = "It's a g-g-g-g-ghooooost!" //jinkies!
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	layer = GHOST_LAYER
	stat = DEAD
	density = FALSE
	move_resist = INFINITY
	see_invisible = SEE_INVISIBLE_OBSERVER
	see_in_dark = 100
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	invisibility = INVISIBILITY_OBSERVER
	hud_type = /datum/hud/ghost
	movement_type = GROUND | FLYING
	var/can_reenter_corpse
	var/datum/hud/living/carbon/hud = null // hud
	var/bootime = 0
	var/started_as_observer //This variable is set to 1 when you enter the game as an observer.
							//If you died in the game and are a ghsot - this will remain as null.
							//Note that this is not a reliable way to determine if admins started as observers, since they change mobs a lot.
	var/atom/movable/following = null
	var/fun_verbs = 0
	var/image/ghostimage_default = null //this mobs ghost image without accessories and dirs
	var/image/ghostimage_simple = null //this mob with the simple white ghost sprite
	var/ghostvision = 1 //is the ghost able to see things humans can't?
	var/mob/observetarget = null	//The target mob that the ghost is observing. Used as a reference in logout()
	var/ghost_hud_enabled = 1 //did this ghost disable the on-screen HUD?
	var/data_huds_on = 0 //Are data HUDs currently enabled?
	var/health_scan = FALSE //Are health scans currently enabled?
	var/list/datahuds = list(DATA_HUD_SECURITY_ADVANCED, DATA_HUD_MEDICAL_ADVANCED, DATA_HUD_DIAGNOSTIC_ADVANCED) //list of data HUDs shown to ghosts.
	var/ghost_orbit = GHOST_ORBIT_CIRCLE

	//These variables store hair data if the ghost originates from a species with head and/or facial hair.
	var/hair_style
	var/hair_color
	var/mutable_appearance/hair_overlay
	var/facial_hair_style
	var/facial_hair_color
	var/mutable_appearance/facial_hair_overlay

	var/updatedir = 1						//Do we have to update our dir as the ghost moves around?
	var/lastsetting = null	//Stores the last setting that ghost_others was set to, for a little more efficiency when we update ghost images. Null means no update is necessary

	//We store copies of the ghost display preferences locally so they can be referred to even if no client is connected.
	//If there's a bug with changing your ghost settings, it's probably related to this.
	var/ghost_accs = GHOST_ACCS_DEFAULT_OPTION
	var/ghost_others = GHOST_OTHERS_DEFAULT_OPTION
	// Used for displaying in ghost chat, without changing the actual name
	// of the mob
	var/deadchat_name
	var/datum/orbit_menu/orbit_menu
	var/datum/spawners_menu/spawners_menu
	var/lastclienttime = 0 //BLUEMOON ADD фиксируем время выхода игрока

/mob/dead/observer/Initialize(mapload, mob/body)
	set_invisibility(GLOB.observer_default_invisibility)

	add_verb(src, GLOB.ghost_verbs)

	if(icon_state in GLOB.ghost_forms_with_directions_list)
		ghostimage_default = image(src.icon,src,src.icon_state + "_nodir")
	else
		ghostimage_default = image(src.icon,src,src.icon_state)
	ghostimage_default.override = TRUE
	GLOB.ghost_images_default |= ghostimage_default

	ghostimage_simple = image(src.icon,src,"ghost_nodir")
	ghostimage_simple.override = TRUE
	GLOB.ghost_images_simple |= ghostimage_simple

	updateallghostimages()

	if(body)
		gender = body.gender
		if(body.mind && body.mind.name)
			name = body.mind.name
		else
			if(body.real_name)
				name = body.real_name
			else
				name = random_unique_name(gender)

		mind = body.mind	//we don't transfer the mind but we keep a reference to it.

		suiciding = body.suiciding // Transfer whether they committed suicide.

		if(ishuman(body))
			var/mob/living/carbon/human/body_human = body
			if(HAIR in body_human.dna.species.species_traits)
				hair_style = body_human.hair_style
				hair_color = brighten_color(body_human.hair_color)
			if(FACEHAIR in body_human.dna.species.species_traits)
				facial_hair_style = body_human.facial_hair_style
				facial_hair_color = brighten_color(body_human.facial_hair_color)

	update_icon()

	if(!isturf(loc))
		var/turf/T
		var/list/turfs = get_area_turfs(/area/shuttle/arrival)
		if(turfs.len)
			T = pick(turfs)
		else
			T = SSmapping.get_station_center()

		forceMove(T)

	if(!name)							//To prevent nameless ghosts
		name = random_unique_name(gender)
	real_name = name

	if(!fun_verbs)
		remove_verb(src, /mob/dead/observer/verb/boo)
		remove_verb(src, /mob/dead/observer/verb/possess)

	animate(src, pixel_z = 2, time = 10, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_z = -4, time = 10, loop = -1, flags = ANIMATION_RELATIVE)

	add_to_dead_mob_list()

	for(var/v in GLOB.active_alternate_appearances)
		if(!v)
			continue
		var/datum/atom_hud/alternate_appearance/AA = v
		AA.onNewMob(src)

	. = ..()
	AddElement(/datum/element/ghost_role_eligibility)
	grant_all_languages()
	show_data_huds()
	data_huds_on = 1

/mob/dead/observer/get_status_tab_items()
	. = ..()
	. += ""
	//Add coords to status panel
	. += "X:[src.x] Y:[src.y] Z:[src.z]"

/mob/dead/observer/get_photo_description(obj/item/camera/camera)
	if(!invisibility || camera.see_ghosts)
		return "You can also see a g-g-g-g-ghooooost!"

/mob/dead/observer/narsie_act()
	var/old_color = color
	color = "#960000"
	animate(src, color = old_color, time = 10, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 10)

/mob/dead/observer/ratvar_act()
	var/old_color = color
	color = "#FAE48C"
	animate(src, color = old_color, time = 10, flags = ANIMATION_PARALLEL)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 10)

/mob/dead/observer/Destroy()
	//BLUEMOON ADD проверяем клиента на все болячки и ссылаем его в лобби при наличии его в госте или удаляем сикей, чтобы при заходе его отправило в лобби (fix undeleting ghosts)
	if(client)
		transfer_to_lobby()
	if(ckey)
		ckey = null
	//BLUEMOON ADD END
	if(data_huds_on)
		remove_data_huds()
	GLOB.ghost_images_default -= ghostimage_default
	QDEL_NULL(ghostimage_default)

	GLOB.ghost_images_simple -= ghostimage_simple
	QDEL_NULL(ghostimage_simple)

	updateallghostimages()

	QDEL_NULL(orbit_menu)
	QDEL_NULL(spawners_menu)
	return ..()

/*
 * This proc will update the icon of the ghost itself, with hair overlays, as well as the ghost image.
 * Please call update_icon(icon_state) from now on when you want to update the icon_state of the ghost,
 * or you might end up with hair on a sprite that's not supposed to get it.
 * Hair will always update its dir, so if your sprite has no dirs the haircut will go all over the place.
 * |- Ricotez
 */
/mob/dead/observer/update_icon(updates=ALL, new_form=null)
	. = ..()
	if(client) //We update our preferences in case they changed right before update_icon was called.
		ghost_accs = client.prefs.ghost_accs
		ghost_others = client.prefs.ghost_others

	if(hair_overlay)
		cut_overlay(hair_overlay)
		hair_overlay = null

	if(facial_hair_overlay)
		cut_overlay(facial_hair_overlay)
		facial_hair_overlay = null


	if(new_form)
		icon_state = new_form
		if(icon_state in GLOB.ghost_forms_with_directions_list)
			ghostimage_default.icon_state = new_form + "_nodir" //if this icon has dirs, the default ghostimage must use its nodir version or clients with the preference set to default sprites only will see the dirs
		else
			ghostimage_default.icon_state = new_form

	if(ghost_accs >= GHOST_ACCS_DIR && (icon_state in GLOB.ghost_forms_with_directions_list)) //if this icon has dirs AND the client wants to show them, we make sure we update the dir on movement
		updatedir = 1
	else
		updatedir = 0	//stop updating the dir in case we want to show accessories with dirs on a ghost sprite without dirs
		setDir(2 		)//reset the dir to its default so the sprites all properly align up

	if(ghost_accs == GHOST_ACCS_FULL && (icon_state in GLOB.ghost_forms_with_accessories_list)) //check if this form supports accessories and if the client wants to show them
		var/datum/sprite_accessory/S
		if(facial_hair_style)
			S = GLOB.facial_hair_styles_list[facial_hair_style]
			if(S)
				facial_hair_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
				if(facial_hair_color)
					facial_hair_overlay.color = "#" + facial_hair_color
				facial_hair_overlay.alpha = 200
				add_overlay(facial_hair_overlay)
		if(hair_style)
			S = GLOB.hair_styles_list[hair_style]
			if(S)
				hair_overlay = mutable_appearance(S.icon, "[S.icon_state]", -HAIR_LAYER)
				if(hair_color)
					hair_overlay.color = "#" + hair_color
				hair_overlay.alpha = 200
				add_overlay(hair_overlay)

/*
 * Increase the brightness of a color by calculating the average distance between the R, G and B values,
 * and maximum brightness, then adding 30% of that average to R, G and B.
 *
 * I'll make this proc global and move it to its own file in a future update. |- Ricotez
 */
/mob/proc/brighten_color(input_color)
	var/r_val
	var/b_val
	var/g_val
	var/color_format = length(input_color)
	if(color_format != length_char(input_color))
		return FALSE
	if(color_format == 3)
		r_val = hex2num(copytext(input_color, 1, 2)) * 16
		g_val = hex2num(copytext(input_color, 2, 3)) * 16
		b_val = hex2num(copytext(input_color, 3, 0)) * 16
	else if(color_format == 6)
		r_val = hex2num(copytext(input_color, 1, 3))
		g_val = hex2num(copytext(input_color, 3, 5))
		b_val = hex2num(copytext(input_color, 5, 7))
	else
		return FALSE //If the color format is not 3 or 6, you're using an unexpected way to represent a color.

	r_val += (255 - r_val) * 0.4
	if(r_val > 255)
		r_val = 255
	g_val += (255 - g_val) * 0.4
	if(g_val > 255)
		g_val = 255
	b_val += (255 - b_val) * 0.4
	if(b_val > 255)
		b_val = 255

	return copytext(rgb(r_val, g_val, b_val), 2)

/*
Transfer_mind is there to check if mob is being deleted/not going to have a body.
Works together with spawning an observer, noted above.
*/

/mob/proc/ghostize(can_reenter_corpse = TRUE, special = FALSE, penalize = FALSE, voluntary = FALSE, cryo = FALSE)
	var/sig_flags = SEND_SIGNAL(src, COMSIG_MOB_GHOSTIZE, can_reenter_corpse, special, penalize)
	penalize = !(sig_flags & COMPONENT_DO_NOT_PENALIZE_GHOSTING) && (suiciding || penalize) // suicide squad.
	voluntary_ghosted = voluntary
	if(!key || key[1] == "@" || (sig_flags & COMPONENT_BLOCK_GHOSTING))
		return //mob has no key, is an aghost or some component hijacked.
	stop_sound_channel(CHANNEL_HEARTBEAT) //Stop heartbeat sounds because You Are A Ghost Now
	var/mob/dead/observer/ghost = new(get_turf(src), src)	// Transfer safety to observer spawning proc.
	SStgui.on_transfer(src, ghost) // Transfer NanoUIs.
	ghost.can_reenter_corpse = can_reenter_corpse || (sig_flags & COMPONENT_FREE_GHOSTING)
	if (client && client.prefs && client.prefs.auto_ooc)
		if (!(client.prefs.chat_toggles & CHAT_OOC))
			client.prefs.chat_toggles ^= CHAT_OOC
	if(ckey && penalize)
		var/datum/preferences/P = GLOB.preferences_datums[ckey]
		if(P)
			P.respawn_restrictions_active = TRUE
			P.respawn_time_of_death = world.time
			P.respawn_did_cryo = cryo
	transfer_ckey(ghost, FALSE)
	ghost.client?.init_verbs()
	if(penalize)
		var/penalty = CONFIG_GET(number/suicide_reenter_round_timer) MINUTES
		var/roundstart_quit_limit = CONFIG_GET(number/roundstart_suicide_time_limit) MINUTES
		if(world.time < roundstart_quit_limit) //add up the time difference to their antag rolling penalty if they quit before half a (ingame) hour even passed.
			penalty += roundstart_quit_limit - world.time
		if(penalty)
			penalty += world.realtime
			if(SSautotransfer.can_fire && SSautotransfer.maxvotes)
				var/maximumRoundEnd = SSautotransfer.starttime + SSautotransfer.voteinterval * SSautotransfer.maxvotes
				if(penalty - SSshuttle.realtimeofstart > maximumRoundEnd + SSshuttle.emergencyCallTime + SSshuttle.emergencyDockTime + SSshuttle.emergencyEscapeTime)
					penalty = CANT_REENTER_ROUND
			if(!(ghost.ckey in GLOB.client_ghost_timeouts))
				GLOB.client_ghost_timeouts += ghost.ckey
				GLOB.client_ghost_timeouts[ghost.ckey] = 0
			else if(GLOB.client_ghost_timeouts[ghost.ckey] == CANT_REENTER_ROUND)
				return
			GLOB.client_ghost_timeouts[ghost.ckey] = max(GLOB.client_ghost_timeouts[ghost.ckey],penalty)
	// needs to be done AFTER the ckey transfer, too
	return ghost

/*
This is the proc mobs get to turn into a ghost. Forked from ghostize due to compatibility issues.
*/

/mob/living/verb/ghost()
	set category = "OOC"
	set name = "Ghost"
	set desc = "Relinquish your life and enter the land of the dead."

	var/penalty = CONFIG_GET(number/suicide_reenter_round_timer) MINUTES
	var/roundstart_quit_limit = CONFIG_GET(number/roundstart_suicide_time_limit) MINUTES
	if(world.time < roundstart_quit_limit)
		penalty += roundstart_quit_limit - world.time
	if(SSautotransfer.can_fire && SSautotransfer.maxvotes)
		var/maximumRoundEnd = SSautotransfer.starttime + SSautotransfer.voteinterval * SSautotransfer.maxvotes
		if(penalty - SSshuttle.realtimeofstart > maximumRoundEnd + SSshuttle.emergencyCallTime + SSshuttle.emergencyDockTime + SSshuttle.emergencyEscapeTime)
			penalty = CANT_REENTER_ROUND

	var/sig_flags = SEND_SIGNAL(src, COMSIG_MOB_GHOSTIZE, (stat == DEAD) ? TRUE : FALSE, FALSE, (stat == DEAD)? penalty : 0, (stat == DEAD)? TRUE : FALSE)

	if(sig_flags & COMPONENT_BLOCK_GHOSTING)
		return

	if(sig_flags & COMPONENT_DO_NOT_PENALIZE_GHOSTING)
		penalty = 0

	if(stat != DEAD)
		succumb()
	if(stat == DEAD || sig_flags & COMPONENT_FREE_GHOSTING)
		ghostize(1)
	else
		var/response = alert(src, "Are you -sure- you want to ghost?\n(You are alive. If you ghost whilst alive you won't be able to re-enter this round [penalty ? "or play ghost roles [penalty == CANT_REENTER_ROUND ? "until the round is over" : "for the next [DisplayTimeText(penalty)]"]" : ""]! You can't change your mind so choose wisely!!)","Are you sure you want to ghost?","Ghost","Stay in body")
		if(response != "Ghost")
			return	//didn't want to ghost after-all
		if(istype(loc, /obj/machinery/cryopod))
			var/obj/machinery/cryopod/C = loc
			C.despawn_occupant()
		else
			suicide_log(TRUE)
			ghostize(FALSE, penalize = TRUE, voluntary = TRUE) //FALSE parameter is so we can never re-enter our body, "Charlie, you can never come baaaack~" :3


/mob/camera/verb/ghost()
	set category = "OOC"
	set name = "Ghost"
	set desc = "Relinquish your life and enter the land of the dead."

	var/sig_flags = SEND_SIGNAL(src, COMSIG_MOB_GHOSTIZE, FALSE, FALSE)

	if(sig_flags & COMPONENT_BLOCK_GHOSTING)
		return

	var/penalty = CONFIG_GET(number/suicide_reenter_round_timer) MINUTES
	var/roundstart_quit_limit = CONFIG_GET(number/roundstart_suicide_time_limit) MINUTES
	if(world.time < roundstart_quit_limit)
		penalty += roundstart_quit_limit - world.time
	if(SSautotransfer.can_fire && SSautotransfer.maxvotes)
		var/maximumRoundEnd = SSautotransfer.starttime + SSautotransfer.voteinterval * SSautotransfer.maxvotes
		if(penalty - SSshuttle.realtimeofstart > maximumRoundEnd + SSshuttle.emergencyCallTime + SSshuttle.emergencyDockTime + SSshuttle.emergencyEscapeTime)
			penalty = CANT_REENTER_ROUND

	if(sig_flags & COMPONENT_DO_NOT_PENALIZE_GHOSTING)
		penalty = 0

	if(sig_flags & COMPONENT_FREE_GHOSTING)
		ghostize(1)
	else
		var/response = alert(src, "Are you -sure- you want to ghost?\n(You are alive. If you ghost whilst alive you won't be able to re-enter this round [penalty ? "or play ghost roles [penalty == CANT_REENTER_ROUND ? "until the round is over" : "for the next [DisplayTimeText(penalty)]"]" : ""]! You can't change your mind so choose wisely!!)","Are you sure you want to ghost?","Ghost","Stay in body")
		if(response != "Ghost")
			return
		ghostize(0, penalize = TRUE)

/mob/dead/observer/Move(NewLoc, direct)
	if (SEND_SIGNAL(src, COMSIG_MOVABLE_PRE_MOVE, NewLoc) & COMPONENT_MOVABLE_BLOCK_PRE_MOVE)
		return
	if(updatedir)
		setDir(direct)//only update dir if we actually need it, so overlays won't spin on base sprites that don't have directions of their own
	var/oldloc = loc

	if(NewLoc)
		forceMove(NewLoc)
	else
		forceMove(get_turf(src))  //Get out of closets and such as a ghost
		if((direct & NORTH) && y < world.maxy)
			y++
		else if((direct & SOUTH) && y > 1)
			y--
		if((direct & EAST) && x < world.maxx)
			x++
		else if((direct & WEST) && x > 1)
			x--

	Moved(oldloc, direct)

/mob/dead/observer/verb/reenter_corpse()
	set category = "Ghost"
	set name = "Re-enter Corpse"
	if(!client)
		return
	if(!mind || QDELETED(mind.current))
		to_chat(src, "<span class='warning'>You have no body.</span>")
		return
	if(!can_reenter_corpse)
		to_chat(src, "<span class='warning'>You cannot re-enter your body.</span>")
		return
	if(mind.current.key && mind.current.key[1] != "@")	//makes sure we don't accidentally kick any clients
		to_chat(usr, "<span class='warning'>Another consciousness is in your body...It is resisting you.</span>")
		return
	client.view_size.setDefault(getScreenSize(client.prefs.widescreenpref))//Let's reset so people can't become allseeing gods
	transfer_ckey(mind.current, FALSE)
	SStgui.on_transfer(src, mind.current) // Transfer NanoUIs.
	mind.current.client.init_verbs()
	return TRUE

/mob/dead/observer/verb/stay_dead()
	set category = "Ghost"
	set name = "Do Not Resuscitate"
	if(!client)
		return
	if(!can_reenter_corpse)
		to_chat(usr, "<span class='warning'>You're already stuck out of your body!</span>")
		return FALSE

	var/response = alert(src, "Are you sure you want to prevent (almost) all means of resuscitation? This cannot be undone. THIS WILL ALSO STOP YOU FROM RESPAWNING!!!","Are you sure you want to stay dead and never respawn?","Да","Нет")

	if(response != "Да")
		return

	can_reenter_corpse = FALSE
	client.prefs?.dnr_triggered = TRUE
	to_chat(src, "You can no longer be brought back into your body or respawn.")
	return TRUE

/mob/dead/observer/proc/notify_cloning(var/message, var/sound, var/atom/source, flashwindow = TRUE)
	if(flashwindow)
		window_flash(client)
	if(message)
		to_chat(src, "<span class='ghostalert'>[message]</span>")
		if(source)
			var/atom/movable/screen/alert/A = throw_alert("[REF(source)]_notify_cloning", /atom/movable/screen/alert/notify_cloning)
			if(A)
				if(client && client.prefs && client.prefs.UI_style)
					A.icon = ui_style2icon(client.prefs.UI_style)
				A.desc = message
				var/old_layer = source.layer
				var/old_plane = source.plane
				source.layer = FLOAT_LAYER
				source.plane = FLOAT_PLANE
				A.add_overlay(source)
				source.layer = old_layer
				source.plane = old_plane
	to_chat(src, "<span class='ghostalert'><a href=?src=[REF(src)];reenter=1>(Click to re-enter)</a></span>")
	if(sound)
		SEND_SOUND(src, sound(sound))

/mob/dead/observer/proc/dead_tele()
	set category = "Ghost"
	set name = "Teleport"
	set desc= "Teleport to a location"
	if(!isobserver(usr))
		to_chat(usr, "Not when you're not dead!")
		return
	var/list/filtered = list()
	for(var/V in GLOB.sortedAreas)
		var/area/A = V
		if(!A.hidden)
			filtered += A
	var/area/thearea  = input("Area to jump to", "BOOYEA") as null|anything in filtered

	if(!thearea)
		return

	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		L+=T

	if(!L || !L.len)
		to_chat(usr, "No area available.")
		return
	usr.forceMove(pick(L))

/mob/dead/observer/proc/view_gas()
	set category = "Ghost"
	set name = "View Gases"
	set desc= "View the atmospheric conditions in a location"

	var/turf/loc = get_turf(src)
	show_air_status_to(loc, usr)

/mob/dead/observer/verb/follow()
	set category = "Ghost"
	set name = "Orbit" // "Haunt"
	set desc = "Follow and orbit a mob."

	if(!orbit_menu)
		orbit_menu = new(src)

	orbit_menu.ui_interact(src)

// This is the ghost's follow verb with an argument
/mob/dead/observer/proc/ManualFollow(atom/movable/target)
	if (!istype(target))
		return

	var/icon/I = icon(target.icon,target.icon_state,target.dir)

	var/orbitsize = (I.Width()+I.Height())*0.5
	orbitsize -= (orbitsize/world.icon_size)*(world.icon_size*0.25)

	var/rot_seg

	switch(ghost_orbit)
		if(GHOST_ORBIT_TRIANGLE)
			rot_seg = 3
		if(GHOST_ORBIT_SQUARE)
			rot_seg = 4
		if(GHOST_ORBIT_PENTAGON)
			rot_seg = 5
		if(GHOST_ORBIT_HEXAGON)
			rot_seg = 6
		else //Circular
			rot_seg = 36 //360/10 bby, smooth enough aproximation of a circle

	orbit(target,orbitsize, FALSE, 20, rot_seg)

/mob/dead/observer/orbit()
	setDir(2)//reset dir so the right directional sprites show up
	return ..()

/mob/dead/observer/stop_orbit(datum/component/orbiter/orbits)
	. = ..()
	//restart our floating animation after orbit is done.
	pixel_z = 0
	animate(src, pixel_z = 2, time = 10, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_z = -4, time = 10, loop = -1, flags = ANIMATION_RELATIVE)

/mob/dead/observer/verb/jumptomob() //Moves the ghost instead of just changing the ghosts's eye -Nodrak
	set category = "Ghost"
	set name = "Jump to Mob"
	set desc = "Teleport to a mob"

	if(isobserver(usr)) //Make sure they're an observer!


		var/list/dest = list() //List of possible destinations (mobs)
		var/target = null	   //Chosen target.

		dest += getpois(mobs_only = TRUE) //Fill list, prompt user with list
		target = input("Please, select a player!", "Jump to Mob", null, null) as null|anything in dest

		if (!target)//Make sure we actually have a target
			return
		else
			var/mob/M = dest[target] //Destination mob
			var/mob/A = src			 //Source mob
			var/turf/T = get_turf(M) //Turf of the destination mob

			if(T && isturf(T))	//Make sure the turf exists, then move the source to that destination.
				A.forceMove(T)
			else
				to_chat(A, "This mob is not located in the game world.")

/mob/dead/observer/verb/change_view_range()
	set category = "Ghost"
	set name = "View Range"
	set desc = "Change your view range."

	var/max_view = client.prefs.unlock_content ? GHOST_MAX_VIEW_RANGE_MEMBER : GHOST_MAX_VIEW_RANGE_DEFAULT
	if(client.view_size.getView() == client.view_size.default)
		var/list/views = list()
		for(var/i in 7 to max_view)
			views |= i
		var/new_view = input("Choose your new view", "Modify view range", 0) as null|anything in views
		if(new_view)
			client.view_size.setTo(clamp(new_view, 7, max_view) - 7)
	else
		client.view_size.resetToDefault()

/mob/dead/observer/verb/add_view_range(input as num)
	set name = "Add View Range"
	set hidden = TRUE
	var/max_view = client.prefs.unlock_content ? GHOST_MAX_VIEW_RANGE_MEMBER : GHOST_MAX_VIEW_RANGE_DEFAULT
	if(input)
		client.rescale_view(input, 15, (max_view*2)+1)

/mob/dead/observer/verb/boo()
	set category = "Ghost"
	set name = "Boo!"
	set desc= "Scare your crew members because of boredom!"

	if(bootime > world.time)
		return
	var/obj/machinery/light/L = locate(/obj/machinery/light) in view(1, src)
	if(L)
		L.flicker()
		bootime = world.time + 600
		return
	//Maybe in the future we can add more <i>spooky</i> code here!
	return


/mob/dead/observer/memory()
	set hidden = 1
	to_chat(src, "<span class='danger'>You are dead! You have no mind to store memory!</span>")

/mob/dead/observer/add_memory()
	set hidden = 1
	to_chat(src, "<span class='danger'>You are dead! You have no mind to store memory!</span>")

/mob/dead/observer/verb/toggle_ghostsee()
	set name = "Toggle Ghost Vision"
	set desc = "Toggles your ability to see things only ghosts can see, like other ghosts"
	set category = "Ghost"
	ghostvision = !(ghostvision)
	update_sight()
	to_chat(usr, "You [(ghostvision?"now":"no longer")] have ghost vision.")

/mob/dead/observer/verb/toggle_darkness()
	set name = "Toggle Darkness"
	set category = "Ghost"
	switch(lighting_alpha)
		if (LIGHTING_PLANE_ALPHA_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
		else
			lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE

	update_sight()

/mob/dead/observer/update_sight()
	if(client)
		ghost_others = client.prefs.ghost_others //A quick update just in case this setting was changed right before calling the proc

	if (!ghostvision)
		see_invisible = SEE_INVISIBLE_LIVING
	else
		see_invisible = SEE_INVISIBLE_OBSERVER


	updateghostimages()
	..()

/proc/updateallghostimages()
	listclearnulls(GLOB.ghost_images_default)
	listclearnulls(GLOB.ghost_images_simple)

	for (var/mob/dead/observer/O in GLOB.player_list)
		O.updateghostimages()

/mob/dead/observer/proc/updateghostimages()
	if (!client)
		return

	if(lastsetting)
		switch(lastsetting) //checks the setting we last came from, for a little efficiency so we don't try to delete images from the client that it doesn't have anyway
			if(GHOST_OTHERS_DEFAULT_SPRITE)
				client.images -= GLOB.ghost_images_default
			if(GHOST_OTHERS_SIMPLE)
				client.images -= GLOB.ghost_images_simple
	lastsetting = client.prefs.ghost_others
	if(!ghostvision)
		return
	if(client.prefs.ghost_others != GHOST_OTHERS_THEIR_SETTING)
		switch(client.prefs.ghost_others)
			if(GHOST_OTHERS_DEFAULT_SPRITE)
				client.images |= (GLOB.ghost_images_default-ghostimage_default)
			if(GHOST_OTHERS_SIMPLE)
				client.images |= (GLOB.ghost_images_simple-ghostimage_simple)

/mob/dead/observer/verb/possess()
	set category = "Ghost"
	set name = "Possess!"
	set desc= "Take over the body of a mindless creature!"

	if(!can_reenter_round())
		return FALSE

	var/list/possessible = list()
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(istype(L,/mob/living/carbon/human/dummy) || !get_turf(L)) //Haha no.
			continue
		if(!(L in GLOB.player_list) && !L.mind)
			possessible += L

	var/mob/living/target = input("Your new life begins today!", "Possess Mob", null, null) as null|anything in possessible

	if(!target)
		return FALSE

	if(ismegafauna(target))
		to_chat(src, "<span class='warning'>This creature is too powerful for you to possess!</span>")
		return FALSE

	if(can_reenter_corpse && mind && mind.current)
		if(alert(src, "Your soul is still tied to your former life as [mind.current.name], if you go forward there is no going back to that life. Are you sure you wish to continue?", "Move On", "Yes", "No") == "No")
			return FALSE
	if(target.key)
		to_chat(src, "<span class='warning'>Someone has taken this body while you were choosing!</span>")
		return FALSE

	transfer_ckey(target, FALSE)
	target.AddElement(/datum/element/ghost_role_eligibility, penalize_on_ghost = FALSE, free_ghosting = TRUE)
	target.faction = list("neutral")
	return TRUE

//this is a mob verb instead of atom for performance reasons
//see /mob/verb/examinate() in mob.dm for more info
//overridden here and in /mob/living for different point span classes and sanity checks
/mob/dead/observer/pointed(atom/A as mob|obj|turf in fov_view())
	if(!..())
		return FALSE
	usr.visible_message("<span class='deadsay'><b>[src]</b> points to [A].</span>")
	return TRUE

/mob/dead/observer/verb/view_manifest()
	set name = "View Crew Manifest"
	set category = "Ghost"

	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	if(!GLOB.crew_manifest_tgui)
		GLOB.crew_manifest_tgui = new /datum/crew_manifest(src)

	GLOB.crew_manifest_tgui.ui_interact(src)

//this is called when a ghost is drag clicked to something.
/mob/dead/observer/MouseDrop(atom/over)
	if(!usr || !over)
		return
	if (isobserver(usr) && usr.client.holder && (isliving(over) || iscameramob(over)) )
		if (usr.client.holder.cmd_ghost_drag(src,over))
			return

	return ..()

/mob/dead/observer/Topic(href, href_list)
	..()
	if(usr == src)
		if(href_list["follow"])
			var/atom/movable/target = locate(href_list["follow"])
			if(istype(target) && (target != src))
				ManualFollow(target)
				return
		if(href_list["x"] && href_list["y"] && href_list["z"])
			var/tx = text2num(href_list["x"])
			var/ty = text2num(href_list["y"])
			var/tz = text2num(href_list["z"])
			var/turf/target = locate(tx, ty, tz)
			if(istype(target))
				forceMove(target)
				return
		if(href_list["reenter"])
			reenter_corpse()
			return

//We don't want to update the current var
//But we will still carry a mind.
/mob/dead/observer/mind_initialize()
	return

/mob/dead/observer/proc/show_data_huds()
	for(var/hudtype in datahuds)
		var/datum/atom_hud/H = GLOB.huds[hudtype]
		H.add_hud_to(src)

/mob/dead/observer/proc/remove_data_huds()
	for(var/hudtype in datahuds)
		var/datum/atom_hud/H = GLOB.huds[hudtype]
		H.remove_hud_from(src)

/mob/dead/observer/verb/toggle_data_huds()
	set name = "Toggle Sec/Med/Diag HUD"
	set desc = "Toggles whether you see medical/security/diagnostic HUDs"
	set category = "Ghost"

	if(data_huds_on) //remove old huds
		remove_data_huds()
		to_chat(src, "<span class='notice'>Data HUDs disabled.</span>")
		data_huds_on = 0
	else
		show_data_huds()
		to_chat(src, "<span class='notice'>Data HUDs enabled.</span>")
		data_huds_on = 1

/mob/dead/observer/verb/toggle_health_scan()
	set name = "Toggle Health Scan"
	set desc = "Toggles whether you health-scan living beings on click"
	set category = "Ghost"

	if(health_scan) //remove old huds
		to_chat(src, "<span class='notice'>Health scan disabled.</span>")
		health_scan = FALSE
	else
		to_chat(src, "<span class='notice'>Health scan enabled.</span>")
		health_scan = TRUE

/mob/dead/observer/verb/restore_ghost_appearance()
	set name = "Restore Ghost Character"
	set desc = "Sets your deadchat name and ghost appearance to your \
		roundstart character."
	set category = "Ghost"

	set_ghost_appearance()
	if(client && client.prefs)
		deadchat_name = client.prefs.real_name

/mob/dead/observer/proc/set_ghost_appearance()
	if((!client) || (!client.prefs))
		return

	if(client.prefs.be_random_name)
		client.prefs.real_name = random_unique_name(gender)
	if(client.prefs.be_random_body)
		client.prefs.random_character(gender)

	if(HAIR in client.prefs.pref_species.species_traits)
		hair_style = client.prefs.hair_style
		hair_color = brighten_color(client.prefs.hair_color)
	if(FACEHAIR in client.prefs.pref_species.species_traits)
		facial_hair_style = client.prefs.facial_hair_style
		facial_hair_color = brighten_color(client.prefs.facial_hair_color)

	update_icon()

/mob/dead/observer/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE)
	return IsAdminGhost(usr)

/mob/dead/observer/is_literate()
	return TRUE

/mob/dead/observer/vv_edit_var(var_name, var_value)
	. = ..()
	switch(var_name)
		if(NAMEOF(src, icon))
			ghostimage_default.icon = icon
			ghostimage_simple.icon = icon
		if(NAMEOF(src, icon_state))
			ghostimage_default.icon_state = icon_state
			ghostimage_simple.icon_state = icon_state
		if(NAMEOF(src, fun_verbs))
			if(fun_verbs)
				add_verb(src, /mob/dead/observer/verb/boo)
				add_verb(src, /mob/dead/observer/verb/possess)
			else
				remove_verb(src, /mob/dead/observer/verb/boo)
				remove_verb(src, /mob/dead/observer/verb/possess)

/mob/dead/observer/reset_perspective(atom/A)
	if(client)
		if(ismob(client.eye) && (client.eye != src))
			var/mob/target = client.eye
			observetarget = null
			if(target.observers)
				target.observers -= src
				UNSETEMPTY(target.observers)
	if(..())
		if(hud_used)
			client.clear_screen()
			hud_used.show_hud(hud_used.hud_version)

/mob/dead/observer/verb/observe()
	set name = "Observe"
	set category = "OOC"

	var/list/creatures = getpois()

	reset_perspective(null)

	var/eye_name = null

	eye_name = input("Please, select a player!", "Observe", null, null) as null|anything in creatures

	if (!eye_name)
		return

	do_observe(creatures[eye_name])

/mob/dead/observer/proc/do_observe(mob/mob_eye)
	//Istype so we filter out points of interest that are not mobs
	if(client && mob_eye && istype(mob_eye))
		client.eye = mob_eye
		if(mob_eye.hud_used)
			client.clear_screen()
			LAZYINITLIST(mob_eye.observers)
			mob_eye.observers |= src
			mob_eye.hud_used.show_hud(mob_eye.hud_used.hud_version, src)
			observetarget = mob_eye
			mob_eye.investigate_log("was observed by [src] as a ghost.", INVESTIGATE_GHOST)

/mob/dead/observer/verb/register_pai_candidate()
	set category = "Ghost"
	set name = "pAI Setup"
	set desc = "Upload a fragment of your personality to the global pAI databanks"

	register_pai()

/mob/dead/observer/proc/register_pai()
	if(isobserver(src))
		SSpai.recruitWindow(src)
	else
		to_chat(usr, "Can't become a pAI candidate while not dead!")

/* So long, Mafia mode, disabled for now
/mob/dead/observer/verb/mafia_game_signup()
	set category = "Ghost"
	set name = "Signup for Mafia"
	set desc = "Sign up for a game of Mafia to pass the time while dead."
	mafia_signup()
*/

/mob/dead/observer/verb/mafia_game_signup()
	set category = "Ghost"
	set name = "Signup for Mafia"
	set desc = "Sign up for a game of Mafia to pass the time while dead."
	mafia_signup()

/mob/dead/observer/proc/mafia_signup()
	if(!client)
		return
	if(!isobserver(src))
		to_chat(usr, "<span class='warning'>You must be a ghost to join mafia!</span>")
		return
	var/datum/mafia_controller/game = GLOB.mafia_game //this needs to change if you want multiple mafia games up at once.
	if(!game)
		game = create_mafia_game("mafia")
	game.ui_interact(usr)

/mob/dead/observer/CtrlShiftClick(mob/user)
	if(isobserver(user) && check_rights(R_SPAWN))
		change_mob_type( /mob/living/carbon/human , null, null, TRUE) //always delmob, ghosts shouldn't be left lingering
	else
		return ..()

/mob/dead/observer/examine(mob/user)
	. = ..()
	if(!invisibility)
		. += "It seems extremely obvious."

/mob/dead/observer/proc/set_invisibility(value)
	invisibility = value
	if(!value)
		set_light(1, 2)
	else
		set_light(0, 0)

// Ghosts have no momentum, being massless ectoplasm
/mob/dead/observer/Process_Spacemove(movement_dir)
	return TRUE

/mob/dead/observer/vv_edit_var(var_name, var_value)
	. = ..()
	if(var_name == NAMEOF(src, invisibility))
		set_invisibility(invisibility) // updates light

/proc/set_observer_default_invisibility(amount, message=null)
	for(var/mob/dead/observer/G in GLOB.player_list)
		G.set_invisibility(amount)
		if(message)
			to_chat(G, message)
	GLOB.observer_default_invisibility = amount

/mob/dead/observer/proc/open_spawners_menu()
	set name = "Spawners Menu"
	set desc = "See all currently available spawners"
	set category = "Ghost"
	if(!spawners_menu)
		spawners_menu = new(src)

	spawners_menu.ui_interact(src)

/mob/dead/observer/verb/game_info()
	set name = "Game info"
	set desc = "Shows various info relating to the game mode, antagonists etc."
	set category = "Ghost"
	if(!started_as_observer && can_reenter_corpse)
		to_chat(src, "You cannot see this info unless you are an observer or you've chosen Do Not Resuscitate!")
		return
	var/list/stuff = list("[SSticker.mode.name]")
	stuff += "Antagonists:\n"
	for(var/datum/antagonist/A in GLOB.antagonists)
		if(A.owner)
			stuff += "[A.owner] the [A.name]"
	var/ghost_info = SSticker.mode.ghost_info()
	if(ghost_info)
		stuff += ghost_info
	to_chat(src,stuff.Join("\n"))

/mob/proc/can_admin_interact()
	return FALSE

/mob/dead/observer/can_admin_interact()
	return check_rights(R_ADMIN, 0)
