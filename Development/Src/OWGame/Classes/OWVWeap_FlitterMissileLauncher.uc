/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWVWeap_FlitterMissileLauncher extends OWVehicleWeapon
	HideDropDown;
	
	
defaultproperties
{
	FiringStatesArray(0)=WeaponFiring
		
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_None
	
	WeaponProjectiles(0)=class'OWProj_Round'
	
	WeaponFireSnd[0]=SoundCue'A_Vehicle_Cicada.SoundCues.A_Vehicle_Cicada_Fire'
	
	FireInterval(0)=+0.25

	ShotCost(0)=0
	ShotCost(1)=0
	
	ShouldFireOnRelease(0)=0
	ShouldFireOnRelease(1)=0	
	
	//VehicleClass=class'OWVPawn_Flitter_Content'
	
	FireTriggerTags=(FlitterWeapon01,FlitterWeapon02)
}
