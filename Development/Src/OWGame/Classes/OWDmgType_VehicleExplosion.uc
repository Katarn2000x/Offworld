/**
 *
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */


class OWDmgType_VehicleExplosion extends OWDamageType
	abstract;

defaultproperties
{
    KillStatsName=KILLS_VEHICLEEXPLOSION
	DeathStatsName=DEATHS_VEHICLEEXPLOSION
	SuicideStatsName=SUICIDES_VEHICLEEXPLOSION
	GibPerterbation=0.15
	bThrowRagdoll=true
	KDamageImpulse=1000.0
}
