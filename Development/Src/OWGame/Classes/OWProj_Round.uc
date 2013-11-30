/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWProj_Round extends OWProjectile;

defaultproperties
{
	ProjFlightTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketTrail'
	ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
	DecalWidth=128.0
	DecalHeight=128.0
	speed=4000.0
	MaxSpeed=10000.0
	AccelRate=1500.0;
	Damage=100.0
	DamageRadius=220.0
	MomentumTransfer=85000
	MyDamageType=class'OWDmgType_Explosion'
	LifeSpan=8.0
	AmbientSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Travel_Cue'
	ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	RotationRate=(Roll=50000)
	bCollideWorld=true
	CheckRadius=42.0
	bCheckProjectileLight=true
	ProjectileLightClass=class'OWRocketLight'
	ExplosionLightClass=class'OWRocketExplosionLight'

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
}
