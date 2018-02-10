var/image/contamination_overlay = image('icons/effects/contamination.dmi')

/pl_control
	var/PHORON_DMG = 3
	var/PHORON_DMG_NAME = "Toxins Damage Amount"
	var/PHORON_DMG_DESC = "Self Descriptive"

	var/CLOTH_CONTAMINATION = 1
	var/CLOTH_CONTAMINATION_NAME = "Cloth Contamination"
	var/CLOTH_CONTAMINATION_DESC = "If this is on, toxins do damage by getting into cloth."

	var/PHORONGUARD_ONLY = 0
	var/PHORONGUARD_ONLY_NAME = "\"ToxinGuard Only\""
	var/PHORONGUARD_ONLY_DESC = "If this is on, only biosuits and spacesuits protect against contamination and ill effects."

	var/GENETIC_CORRUPTION = 0
	var/GENETIC_CORRUPTION_NAME = "Genetic Corruption Chance"
	var/GENETIC_CORRUPTION_DESC = "Chance of genetic corruption as well as toxic damage, X in 10,000."

	var/SKIN_BURNS = 0
	var/SKIN_BURNS_DESC = "Toxins have an effect similar to mustard gas on the un-suited."
	var/SKIN_BURNS_NAME = "Skin Burns"

	var/EYE_BURNS = 1
	var/EYE_BURNS_NAME = "Eye Burns"
	var/EYE_BURNS_DESC = "Toxins burn the eyes of anyone not wearing eye protection."

	var/CONTAMINATION_LOSS = 0.02
	var/CONTAMINATION_LOSS_NAME = "Contamination Loss"
	var/CONTAMINATION_LOSS_DESC = "How much toxin damage is dealt from contaminated clothing" //Per tick?  ASK ARYN

	var/PHORON_HALLUCINATION = 0
	var/PHORON_HALLUCINATION_NAME = "Toxin Hallucination"
	var/PHORON_HALLUCINATION_DESC = "Does being in toxins cause you to hallucinate?"

	var/N2O_HALLUCINATION = 1
	var/N2O_HALLUCINATION_NAME = "N2O Hallucination"
	var/N2O_HALLUCINATION_DESC = "Does being in sleeping gas cause you to hallucinate?"


obj/var/contaminated = 0


/obj/item/proc/can_contaminate()
	//Clothing and backpacks can be contaminated.
	if(flags & PHORONGUARD) return 0
	else if(istype(src,/obj/item/storage/backpack)) return 0 //Cannot be washed :(
	else if(istype(src,/obj/item/clothing)) return 1

/obj/item/proc/contaminate()
	//Do a contamination overlay? Temporary measure to keep contamination less deadly than it was.
	if(!contaminated)
		contaminated = 1
		overlays += contamination_overlay

/obj/item/proc/decontaminate()
	contaminated = 0
	overlays -= contamination_overlay

/mob/proc/contaminate()

/mob/living/carbon/human/contaminate()
	//See if anything can be contaminated.

	if(!pl_suit_protected())
		suit_contamination()

	if(!pl_head_protected())
		if(prob(1)) suit_contamination() //Phoron can sometimes get through such an open suit.

//Cannot wash backpacks currently.
//	if(istype(back,/obj/item/storage/backpack))
//		back.contaminate()

/mob/proc/pl_effects()

/mob/living/carbon/human/pl_effects()
	//Handles all the bad things phoron can do.

	//Contamination
	if(vsc.plc.CLOTH_CONTAMINATION) contaminate()

	//Anything else requires them to not be dead.
	if(stat >= 2)
		return

	//Burn skin if exposed.
	if(vsc.plc.SKIN_BURNS)
		if(!pl_head_protected() || !pl_suit_protected())
			burn_skin(0.75)
			if(prob(20)) src << "<span class='danger'>Your skin burns!</span>"
			updatehealth()

	//Burn eyes if exposed.
	if(vsc.plc.EYE_BURNS)
		if(!head)
			if(!wear_mask)
				burn_eyes()
			else
				if(!(wear_mask.body_parts_covered & EYES))
					burn_eyes()
		else
			if(!(head.body_parts_covered & EYES))
				if(!wear_mask)
					burn_eyes()
				else
					if(!(wear_mask.body_parts_covered & EYES))
						burn_eyes()

/mob/living/carbon/human/proc/burn_eyes()
	var/obj/item/organ/internal/eyes/E = internal_organs_by_name[BP_EYES]
	if(E)
		if(prob(20)) src << "<span class='danger'>Your eyes burn!</span>"
		E.damage += 2.5
		eye_blurry = min(eye_blurry+1.5,50)
		if (prob(max(0,E.damage - 15) + 1) &&!eye_blind)
			src << "<span class='danger'>You are blinded!</span>"
			eye_blind += 20

/mob/living/carbon/human/proc/pl_head_protected()
	//Checks if the head is adequately sealed.
	if(head)
		if(vsc.plc.PHORONGUARD_ONLY)
			if(head.flags & PHORONGUARD)
				return 1
		else if(head.body_parts_covered & EYES)
			return 1
	return 0

/mob/living/carbon/human/proc/pl_suit_protected()
	//Checks if the suit is adequately sealed.
	var/coverage = 0
	for(var/obj/item/protection in list(wear_suit, gloves, shoes))
		if(!protection)
			continue
		if(vsc.plc.PHORONGUARD_ONLY && !(protection.flags & PHORONGUARD))
			return 0
		coverage |= protection.body_parts_covered

	if(vsc.plc.PHORONGUARD_ONLY)
		return 1

	return BIT_TEST_ALL(coverage, UPPER_TORSO|LOWER_TORSO|LEGS|FEET|ARMS|HANDS)

/mob/living/carbon/human/proc/suit_contamination()
	//Runs over the things that can be contaminated and does so.
	if(w_uniform) w_uniform.contaminate()
	if(shoes) shoes.contaminate()
	if(gloves) gloves.contaminate()


turf/Entered(obj/item/I)
	. = ..()
	//Items that are in phoron, but not on a mob, can still be contaminated.
	if(istype(I) && vsc.plc.CLOTH_CONTAMINATION && I.can_contaminate())
		var/datum/gas_mixture/env = return_air(1)
		if(!env)
			return
		for(var/g in env.gas)
			if(gas_data && gas_data.flags && (gas_data.flags[g] & XGM_GAS_CONTAMINANT) && env.gas[g] > gas_data.overlay_limit[g] + 1)
				I.contaminate()
				break