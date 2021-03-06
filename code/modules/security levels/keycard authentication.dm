/obj/machinery/keycard_auth
	name = "Keycard Authentication Device"
	desc = "This device is used to trigger emergency functions."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "auth_off"
	var/active = 0 //This gets set to 1 on all devices except the one where the initial request was made.
	var/event = ""
	var/screen = 1
	var/confirmed = 0 //This variable is set by the device that confirms the request.
	var/confirm_delay = 20 //(2 seconds)
	var/busy = 0 //Busy when waiting for authentication or an event request has been sent from this device.
	var/obj/machinery/keycard_auth/event_source
	var/mob/event_triggered_by
	var/mob/event_confirmed_by
	//1 = select event
	//2 = authenticate
	anchored = 1.0
	use_power = 1
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = ENVIRON

/obj/machinery/keycard_auth/attack_ai(var/mob/user)
	user << "The AI is not to interact with these devices."
	return

/obj/machinery/keycard_auth/attackby(var/obj/item/W, var/mob/user)
	if(stat & (NOPOWER|BROKEN))
		user << "This device is not powered."
		return
	if(istype(W,/obj/item/card/id))
		var/obj/item/card/id/ID = W
		visible_message("<span class='notice'>\The [src] swipes \the [W] through \the [src].</span>")
		if(access_keycard_auth in ID.access)
			if(active == 1)
				//This is not the device that made the initial request. It is the device confirming the request.
				if(event_source)
					event_source.confirmed = 1
					event_source.event_confirmed_by = usr
			else if(screen == 2)
				if(using_map.single_card_authentication)
					confirmed = 0
					log_game("[key_name(usr)] triggered event [event]")
					message_admins("[key_name(usr)] triggered event [event]", 1)
					trigger_event(event)
					reset()
				else
					event_triggered_by = usr
					broadcast_request() //This is the device making the initial event request. It needs to broadcast to other devices

//icon_state gets set everwhere besides here, that needs to be fixed sometime
/obj/machinery/keycard_auth/update_icon()
	if(stat &NOPOWER)
		icon_state = "auth_off"

/obj/machinery/keycard_auth/attack_hand(var/mob/user)
	if(user.stat || stat & (NOPOWER|BROKEN))
		user << "This device is not powered."
		return
	if(!user.IsAdvancedToolUser())
		return 0
	if(busy)
		user << "This device is busy."
		return

	user.set_machine(src)

	var/dat = "<h1>Keycard Authentication Device</h1>"

	dat += "This device is used to trigger some high security events. It requires the simultaneous swipe of two high-level ID cards."
	dat += "<br><hr><br>"

	if(screen == 1)
		dat += "Select an event to trigger:<ul>"
		dat += "<li><A href='?src=\ref[src];triggerevent=Red alert'>Red alert</A></li>"
		if(!config.ert_admin_call_only)
			dat += "<li><A href='?src=\ref[src];triggerevent=Distress Beacon'>Distress Beacon</A></li>"
		dat += "<li><A href='?src=\ref[src];triggerevent=Emergency Jump'>Emergency Jump</A></li>"
		dat += "<li><A href='?src=\ref[src];triggerevent=Grant Emergency Maintenance Access'>Grant Emergency Maintenance Access</A></li>"
		dat += "<li><A href='?src=\ref[src];triggerevent=Revoke Emergency Maintenance Access'>Revoke Emergency Maintenance Access</A></li>"
		dat += "</ul>"
		user << browse(dat, "window=keycard_auth;size=500x250")
	if(screen == 2)
		dat += "Please swipe your card to authorize the following event: <b>[event]</b>"
		dat += "<p><A href='?src=\ref[src];reset=1'>Back</A>"
		user << browse(dat, "window=keycard_auth;size=500x250")
	return


/obj/machinery/keycard_auth/Topic(href, href_list)
	..()
	if(busy)
		usr << "This device is busy."
		return
	if(usr.stat || stat & (BROKEN|NOPOWER))
		usr << "This device is without power."
		return
	if(href_list["triggerevent"])
		event = href_list["triggerevent"]
		screen = 2
	if(href_list["reset"])
		reset()

	updateUsrDialog()
	add_fingerprint(usr)
	return

/obj/machinery/keycard_auth/proc/reset()
	active = 0
	event = ""
	screen = 1
	confirmed = 0
	event_source = null
	icon_state = "auth_off"
	event_triggered_by = null
	event_confirmed_by = null

/obj/machinery/keycard_auth/proc/broadcast_request()
	icon_state = "auth_on"
	for(var/obj/machinery/keycard_auth/KA in world)
		if(KA == src) continue
		KA.reset()
		spawn()
			KA.receive_request(src)

	sleep(confirm_delay)
	if(confirmed)
		confirmed = 0
		trigger_event(event)
		log_game("[key_name(event_triggered_by)] triggered and [key_name(event_confirmed_by)] confirmed event [event]")
		message_admins("[key_name(event_triggered_by)] triggered and [key_name(event_confirmed_by)] confirmed event [event]", 1)
	reset()

/obj/machinery/keycard_auth/proc/receive_request(var/obj/machinery/keycard_auth/source)
	if(stat & (BROKEN|NOPOWER))
		return
	event_source = source
	busy = 1
	active = 1
	icon_state = "auth_on"

	sleep(confirm_delay)

	event_source = null
	icon_state = "auth_off"
	active = 0
	busy = 0

/obj/machinery/keycard_auth/proc/trigger_event()
	switch(event)
		if("Emergency Jump")
			evacuation_controller.call_evacuation(usr, TRUE)
		if("Red alert")
			set_security_level(SEC_LEVEL_RED)
			feedback_inc("alert_keycard_auth_red",1)
		if("Grant Emergency Maintenance Access")
			make_maint_all_access()
			feedback_inc("alert_keycard_auth_maintGrant",1)
		if("Revoke Emergency Maintenance Access")
			revoke_maint_all_access()
			feedback_inc("alert_keycard_auth_maintRevoke",1)
		if("Distress Beacon")
			if(!activate_distress_beacon())
				usr << "<span class='warning'>Long-range scanning indicates there is nobody out here to help you.</span>"
			feedback_inc("alert_keycard_auth_ert",1)

/obj/machinery/keycard_auth/proc/is_ert_blocked()
	if(config.ert_admin_call_only) return 1
	return ticker.mode && ticker.mode.ert_disabled

var/global/maint_all_access = 0

/proc/make_maint_all_access()
	maint_all_access = 1
	world << "<font size=4 color='red'>Attention!</font>"
	world << "<font color='red'>The maintenance access requirement has been revoked on all airlocks.</font>"

/proc/revoke_maint_all_access()
	maint_all_access = 0
	world << "<font size=4 color='red'>Attention!</font>"
	world << "<font color='red'>The maintenance access requirement has been readded on all maintenance airlocks.</font>"

/obj/machinery/door/airlock/allowed(mob/M)
	if(maint_all_access && src.check_access_list(list(access_maint_tunnels)))
		return 1
	return ..(M)
