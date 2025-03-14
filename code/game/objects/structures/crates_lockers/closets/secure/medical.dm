/obj/structure/closet/secure_closet/medical1
	name = "медецинский шкаф"
	desc = "Доверху набитый медицинским хламом."
	icon_state = "med"
	req_access = list(ACCESS_MEDICAL)

/obj/structure/closet/secure_closet/medical1/PopulateContents()
	..()
	new /obj/item/reagent_containers/glass/beaker(src)
	new /obj/item/reagent_containers/glass/beaker(src)
	new /obj/item/reagent_containers/dropper(src)
	new /obj/item/reagent_containers/dropper(src)
	new /obj/item/storage/belt/medical(src)
	new /obj/item/storage/box/syringes(src)
	new /obj/item/reagent_containers/glass/bottle/toxin(src)
	new /obj/item/reagent_containers/glass/bottle/morphine(src)
	new /obj/item/reagent_containers/glass/bottle/morphine(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/glass/bottle/epinephrine(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/glass/bottle/charcoal(src)
	new /obj/item/storage/box/rxglasses(src)

/obj/structure/closet/secure_closet/medical2
	name = "шкаф с анестезией"
	desc = "Used to knock people out."
	req_access = list(ACCESS_SURGERY)

/obj/structure/closet/secure_closet/medical2/PopulateContents()
	..()
	for(var/i in 1 to 3)
		new /obj/item/tank/internals/anesthetic(src)
	for(var/i in 1 to 3)
		new /obj/item/clothing/mask/breath/medical(src)

/obj/structure/closet/secure_closet/medical3
	name = "шкаф врача"
	req_access = list(ACCESS_SURGERY)
	icon_state = "med_secure"

/obj/structure/closet/secure_closet/medical3/PopulateContents()
	..()
	new /obj/item/radio/headset/headset_med(src)
	new /obj/item/defibrillator/loaded(src)
	new /obj/item/clothing/gloves/color/latex/nitrile(src)
	new /obj/item/storage/belt/medical(src)
	new /obj/item/clothing/glasses/hud/health(src)
	new /obj/item/roller/heavy(src) // BLUEMOON - HEAVY_QUIRKS - ADD - каталка для сверхтяжей
	return

/obj/structure/closet/secure_closet/paramedic
    name = "шкаф парамедика"
    req_access = list(ACCESS_MEDICAL)
    icon_state = "emt_secure"

/obj/structure/closet/secure_closet/paramedic/PopulateContents()
    ..()
    new /obj/item/clothing/suit/toggle/labcoat/paramedic(src)
    new /obj/item/clothing/under/rank/medical/paramedic(src)
    new /obj/item/clothing/under/rank/medical/paramedic/skirt(src)
    new /obj/item/radio/headset/headset_med(src)
    new /obj/item/defibrillator/loaded(src)
    new /obj/item/clothing/gloves/color/latex/nitrile(src)
    new /obj/item/storage/belt/medical(src)
    new /obj/item/clothing/glasses/hud/health(src)
    new /obj/item/pinpointer/crew(src)
    new /obj/item/sensor_device(src)
    return

/obj/structure/closet/secure_closet/CMO
	name = "\proper шкаф главного врача"
	req_access = list(ACCESS_CMO)
	icon_state = "cmo"

/obj/structure/closet/secure_closet/CMO/PopulateContents()
	..()
	new /obj/item/cartridge/cmo(src)
	new /obj/item/radio/headset/heads/cmo(src)
	new /obj/item/megaphone/command(src)
	new /obj/item/defibrillator/compact/loaded(src)
	new /obj/item/storage/belt/medical(src)
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/assembly/flash/handheld(src)
	new /obj/item/storage/hypospraykit/cmo(src)
	new /obj/item/autosurgeon/cmo(src)
	new /obj/item/door_remote/chief_medical_officer(src)
	new /obj/item/clothing/neck/petcollar(src)
	new /obj/item/pet_carrier(src)
	new /obj/item/storage/belt/medical/surgery_belt_adv/cmo(src)
	new /obj/item/wallframe/defib_mount(src)
	new /obj/item/circuitboard/machine/techfab/department/medical(src)
	new /obj/item/storage/photo_album/CMO(src)
	new	/obj/item/storage/lockbox/medal/medical(src)
	new /obj/item/mod/construction/armor/rescue(src)
	new /obj/item/mod/module/health_analyzer(src)
	new /obj/item/storage/garment_case/CMO(src) //BLUEMOON add

/obj/structure/closet/secure_closet/animal
	name = "animal control"
	req_access = list(ACCESS_SURGERY)

/obj/structure/closet/secure_closet/animal/PopulateContents()
	..()
	new /obj/item/assembly/signaler(src)
	for(var/i in 1 to 3)
		new /obj/item/electropack(src)

/obj/structure/closet/secure_closet/chemical
	name = "шкаф химика"
	desc = "Храните здесь опасные химикаты. А что это за синий лёд?"
	icon_door = "chemical"

/obj/structure/closet/secure_closet/chemical/PopulateContents()
	..()
	new /obj/item/storage/box/pillbottles(src)
	new /obj/item/storage/box/pillbottles(src)
	new /obj/item/storage/box/medsprays(src)
	new /obj/item/storage/box/medsprays(src)
