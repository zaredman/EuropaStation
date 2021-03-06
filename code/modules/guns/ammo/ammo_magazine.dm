//An item that holds casings and can be used to put them inside guns
/obj/item/ammo_magazine
	name = "cartridge"
	desc = "An ammunition cartridge for some kind of gun. Presumably contains some kind of bullet, and probably does not contain any kind of candy."
	icon_state = "pistol_mag"
	icon = 'icons/obj/gun_components/ammo.dmi'
	slot_flags = SLOT_BELT
	item_state = "syringe_kit"
	matter = list(MATERIAL_STEEL = 500, MATERIAL_PLASTIC = 100)
	throwforce = 5
	w_class = 2
	throw_speed = 4
	throw_range = 10

	var/list/stored_ammo = list()
	var/decl/weapon_caliber/caliber = /decl/weapon_caliber/pistol_357
	var/max_ammo = 7
	var/ammo_type = /obj/item/ammo_casing //ammo type that is initially loaded
	var/initial_ammo = null
	var/mag_type = MAGAZINE
	var/weapon_type

/obj/item/ammo_magazine/New()
	..()

	if(isnull(initial_ammo))
		initial_ammo = max_ammo

	if(ammo_type)
		var/obj/item/ammo_casing/bullet = ammo_type
		caliber = initial(bullet.caliber)
		if(initial_ammo)
			for(var/i = 1 to initial_ammo)
				stored_ammo += new ammo_type(src)

	caliber = get_caliber_from_path(caliber)
	if(caliber.magazine_name)
		name = "[caliber.magazine_name] ([caliber.name])"
	else
		name = "[initial(name)] ([caliber.name])"
	update_icon()

/obj/item/ammo_casing/Destroy()
	caliber = null
	. = ..()

/obj/item/ammo_magazine/attackby(var/obj/item/W, var/mob/user)
	if(istype(W, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/C = W
		if(C.caliber.projectile_size != caliber.projectile_size)
			to_chat(user, "<span class='warning'>[C] does not fit into [src].</span>")
			return
		if(stored_ammo.len >= max_ammo)
			to_chat(user, "<span class='warning'>[src] is full!</span>")
			return
		user.unEquip(C)
		C.forceMove(src)
		stored_ammo.Insert(1, C) //add to the head of the list
		update_icon()

/obj/item/ammo_magazine/attack_self(mob/user)
	if(!stored_ammo.len)
		to_chat(user, "<span class='notice'>[src] is already empty!</span>")
		return
	to_chat(user, "<span class='notice'>You empty [src].</span>")
	for(var/obj/item/ammo_casing/C in stored_ammo)
		C.forceMove(user.loc)
		C.set_dir(pick(cardinal))
	stored_ammo.Cut()
	update_icon()

/obj/item/ammo_magazine/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>There [(stored_ammo.len == 1)? "is" : "are"] [stored_ammo.len] round\s left.</span>")

// Predefined
/obj/item/ammo_magazine/assault
	name = "assault rifle magazine"
	icon_state = "assault_mag"
	ammo_type = /obj/item/ammo_casing/rifle_small
	max_ammo = 30
	weapon_type = GUN_ASSAULT

/obj/item/ammo_magazine/assault/large
	ammo_type = /obj/item/ammo_casing/rifle_large

/obj/item/ammo_magazine/pistol
	name = "pistol magazine"
	ammo_type = /obj/item/ammo_casing/pistol_small
	weapon_type = GUN_PISTOL

/obj/item/ammo_magazine/pistol/medium
	ammo_type = /obj/item/ammo_casing/pistol_medium
/obj/item/ammo_magazine/pistol/large
	ammo_type = /obj/item/ammo_casing/pistol_large
/obj/item/ammo_magazine/pistol/a38
	ammo_type = /obj/item/ammo_casing/a38
/obj/item/ammo_magazine/pistol/a45
	ammo_type = /obj/item/ammo_casing/a45

/obj/item/ammo_magazine/submachine
	name = "submachine gun magazine"
	icon_state = "submachine_mag"
	ammo_type = /obj/item/ammo_casing/pistol_small
	max_ammo = 30
	color = COLOR_GUNMETAL
	weapon_type = GUN_SMG

/obj/item/ammo_magazine/submachine/medium
	ammo_type = /obj/item/ammo_casing/pistol_medium
/obj/item/ammo_magazine/submachine/large
	ammo_type = /obj/item/ammo_casing/pistol_large
/obj/item/ammo_magazine/submachine/a38
	ammo_type = /obj/item/ammo_casing/a38
/obj/item/ammo_magazine/submachine/a45
	ammo_type = /obj/item/ammo_casing/a45

/obj/item/ammo_magazine/autocannon
	name = "ammunition belt"
	icon_state = "cannon_belt"
	ammo_type = /obj/item/ammo_casing/gyrojet
	weapon_type = GUN_CANNON
	max_ammo = 30

// Empty mags.
/obj/item/ammo_magazine/assault/empty
	initial_ammo = 0
/obj/item/ammo_magazine/assault/large/empty
	initial_ammo = 0
/obj/item/ammo_magazine/pistol/empty
	initial_ammo = 0
/obj/item/ammo_magazine/pistol/medium/empty
	initial_ammo = 0
/obj/item/ammo_magazine/pistol/large/empty
	initial_ammo = 0
/obj/item/ammo_magazine/pistol/a38/empty
	initial_ammo = 0
/obj/item/ammo_magazine/pistol/a45/empty
	initial_ammo = 0
/obj/item/ammo_magazine/submachine/empty
	initial_ammo = 0
/obj/item/ammo_magazine/submachine/medium/empty
	initial_ammo = 0
/obj/item/ammo_magazine/submachine/large/empty
	initial_ammo = 0
/obj/item/ammo_magazine/submachine/a38/empty
	initial_ammo = 0
/obj/item/ammo_magazine/submachine/a45/empty
	initial_ammo = 0
/obj/item/ammo_magazine/autocannon/empty
	initial_ammo = 0
/obj/item/ammo_magazine/speedloader/empty
	initial_ammo = 0
/obj/item/ammo_magazine/speedloader/a38/empty
	initial_ammo = 0
/obj/item/ammo_magazine/speedloader/a45/empty
	initial_ammo = 0
/obj/item/ammo_magazine/speedloader/a50/empty
	initial_ammo = 0
/obj/item/ammo_magazine/speedloader/caps/empty
	initial_ammo = 0
