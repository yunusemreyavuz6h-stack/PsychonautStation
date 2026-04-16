/obj/item/kinetic_hammer
	parent = /obj/item/kinetic_crusher
	name = "proto-kinetic hammer"
	desc = "A proto-kinetic hammer designed to smash and detonate marked threats with blunt force instead of sharp strikes. It trades bleeding and armor penetration for raw impact and collision damage."
	icon = 'icons/obj/mining.dmi'
	icon_state = "crusher"
	base_icon_state = "crusher"
	inhand_icon_state = "crusher0"
	icon_angle = -45
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	resistance_flags = FIRE_PROOF
	force = 0
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	throwforce = 5
	throw_speed = 4
	armour_penetration = 0
	custom_materials = list(/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT*1.15, /datum/material/glass=HALF_SHEET_MATERIAL_AMOUNT*2.075)
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	attack_verb_continuous = list("smashes", "crushes", "cleaves", "chops", "pulps")
	attack_verb_simple = list("smash", "crush", "cleave", "chop", "pulp")
	sharpness = NONE
	actions_types = list(/datum/action/item_action/toggle_light)
	action_slots = ALL
	obj_flags = UNIQUE_RENAME
	light_system = OVERLAY_LIGHT
	light_range = 5
	light_power = 1.2
	light_color = "#ffff66"
	light_on = FALSE
	var/toggle_light_sound = 'sound/items/weapons/empty.ogg'
	var/fire_kinetic_blast_sound = 'sound/items/weapons/plasma_cutter.ogg'
	var/projectile_recharge_sound = 'sound/items/weapons/kinetic_reload.ogg'
	var/backstab_sound = 'sound/items/weapons/kinetic_accel.ogg'
	var/list/obj/item/crusher_trophy/trophies = list()
	var/charged = TRUE
	var/charge_time = 1.5 SECONDS
	var/charge_timer
	var/detonation_damage = 125
	var/backstab_bonus = 0
	var/projectile_icon = 'icons/obj/weapons/guns/projectiles.dmi'
	var/projectile_icon_state = "pulse1"
	var/force_wielded = 25
	var/last_projectile_pb = FALSE

/obj/item/kinetic_hammer/afterattack(mob/living/target, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!isliving(target))
		return
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		crusher_trophy.on_melee_hit(target, user)
	if(QDELETED(target))
		return
	var/datum/status_effect/crusher_mark/mark = target.has_status_effect(/datum/status_effect/crusher_mark)
	if(!mark)
		return
	if(!target.remove_status_effect(mark))
		return
	var/datum/status_effect/crusher_damage/crusher_damage_effect = target.has_status_effect(/datum/status_effect/crusher_damage) || target.apply_status_effect(/datum/status_effect/crusher_damage)
	var/target_health = target.health
	var/combined_damage = detonation_damage
	for(var/obj/item/crusher_trophy/crusher_trophy as anything in trophies)
		combined_damage += crusher_trophy.on_mark_detonation(target, user)
	if(QDELETED(target))
		return
	if(!QDELETED(crusher_damage_effect))
		crusher_damage_effect.total_damage += target_health - target.health
	new /obj/effect/temp_visual/kinetic_blast(get_turf(target))
	var/extra_collision_damage = push_marked_target(target, user, 3)
	if(extra_collision_damage)
		combined_damage += extra_collision_damage
	if(!QDELETED(crusher_damage_effect))
		crusher_damage_effect.total_damage += combined_damage
	var/def_check = target.getarmor(type = BOMB)
	SEND_SIGNAL(user, COMSIG_LIVING_CRUSHER_DETONATE, target, src, FALSE)
	target.apply_damage(combined_damage, BRUTE, blocked = def_check)

/obj/item/kinetic_hammer/proc/push_marked_target(mob/living/target, mob/living/user, distance = 3)
	var/extra_damage = 0
	var/push_dir = get_dir(user, target)
	for(var/i in 1 to distance)
		var/turf/next_turf = get_step(target, push_dir)
		if(!isturf(next_turf))
			break
		if(!target.Move(next_turf, push_dir))
			if(iswallturf(next_turf) || ismineralturf(next_turf))
				extra_damage += 20
			break
		if(QDELETED(target))
			break
	return extra_damage
