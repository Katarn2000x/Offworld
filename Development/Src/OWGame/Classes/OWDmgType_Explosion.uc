/**
 *
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */


/** superclass of damagetypes that cause hit players to burst into flame */
class OWDmgType_Explosion extends OWDamageType
	HideDropDown
	abstract;

/** SpawnHitEffect()
 * Possibly spawn a custom hit effect
 */
 
 /*
static function SpawnHitEffect(Pawn P, float Damage, vector Momentum, name BoneName, vector HitLocation)
{
	local UTEmit_VehicleHit BF;

	if ( Vehicle(P) != None )
	{
		BF = P.spawn(class'UTEmit_VehicleHit',P,, HitLocation, rotator(Momentum));
		BF.AttachTo(P, BoneName);
	}
	else
	{
		Super.SpawnHitEffect(P, Damage, Momentum, BoneName, HitLocation);
	}
}
*/

static function float GetHitEffectDuration(Pawn P, float Damage)
{
	return (P.Health <= 0) ? 5.0 : 5.0 * FClamp(Damage * 0.01, 0.5, 1.0);
}

defaultproperties
{
}
