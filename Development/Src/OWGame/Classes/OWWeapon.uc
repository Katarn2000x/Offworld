/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWWeapon extends UDKWeapon
	dependson(OWPlayerController)
	config(Weapon)
	abstract;
	
/*********************************************************************************************
 Inventory Grouping/etc.
********************************************************************************************* */

/** The weapon/inventory set, 0-9. */
var byte InventoryGroup;

/** position within inventory group. (used by prevweapon and nextweapon) */
var float GroupWeight;

/** The final inventory weight.  It's calculated in PostBeginPlay() */
var float InventoryWeight;
	
/** Max ammo count */
var int MaxAmmoCount;

/** Holds the amount of ammo used for a given shot */
var array<int> ShotCost;
	
var bool bSuppressSounds;
	
/** Sound to play when the weapon is fired */
var(Sounds)	array<SoundCue>	WeaponFireSnd;

var array<name> EffectSockets;

/** Holds the name of the socket to attach a muzzle flash too */
var name					MuzzleFlashSocket;




simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'AmmoCount' )
	{
		if ( !HasAnyAmmo() )
		{
			WeaponEmpty();
		}
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/**
 * Each Weapon needs to have a unique InventoryWeight in order for weapon switching to
 * work correctly.  This function calculates that weight using the various inventory values
 */
simulated function CalcInventoryWeight()
{
	InventoryWeight = ((InventoryGroup+1) * 1000) + (GroupWeight * 100);
	if ( Priority < 0 )
	{
		Priority = InventoryWeight;
	}
}

/**
 * returns true if this weapon is currently lower priority than InWeapon
 * used to determine whether to switch to InWeapon
 * this is the server check, so don't check clientside settings (like weapon priority) here
 */
simulated function bool ShouldSwitchTo(OWWeapon InWeapon)
{
	// if we should, but can't right now, tell InventoryManager to try again later
	if (IsFiring() || DenyClientWeaponSet())
	{
		//OWInventoryManager(InvManager).RetrySwitchTo(InWeapon);
		return false;
	}
	else
	{
		return true;
	}
}

/**
 * This function handles playing sounds for weapons.  How it plays the sound depends on the following:
 *
 * If we are a listen server, then this sound is played and replicated as normal
 * If we are a remote client, but locally controlled (ie: we are on the client) we play the sound and don't replicate it
 * If we are a dedicated server, play the sound and replicate it to everyone BUT the owner (he will play it locally).
 *
 *
 * @param	SoundCue	- The Source Cue to play
 */
simulated function WeaponPlaySound(SoundCue Sound, optional float NoiseLoudness)
{
	// if we are a listen server, just play the sound.  It will play locally
	// and be replicated to all other clients.
	if( Sound != None && Instigator != None && !bSuppressSounds  )
	{
		Instigator.PlaySound(Sound, false, true);
	}
}

/**
 * Tells the weapon to play a firing sound (uses CurrentFireMode)
 */
simulated function PlayFiringSound()
{
	if (CurrentFireMode<WeaponFireSnd.Length)
	{
		// play weapon fire sound
		if ( WeaponFireSnd[CurrentFireMode] != None )
		{
			MakeNoise(1.0);
			WeaponPlaySound( WeaponFireSnd[CurrentFireMode] );
		}
	}
}


/*********************************************************************************************
 * Ammunition / Inventory
 *********************************************************************************************/

//fire ammunition - play firing sound and consume ammo
simulated function FireAmmunition()
{
	// if this is the local player, play the firing effects
	PlayFiringSound();

	Super.FireAmmunition();
	
	//OWInventoryManager(InvManager).OwnerEvent('FiredWeapon');
}
//Consume the ammunition
function ConsumeAmmo( byte FireModeNum )
{
	AddAmmo(-ShotCost[FireModeNum]);
}

/**
 * This function is used to add ammo back to a weapon.  It's called from the Inventory Manager
 */
function int AddAmmo( int Amount )
{
	AmmoCount = Clamp(AmmoCount + Amount,0,MaxAmmoCount);

	return AmmoCount;
}

/*********************************************************************************************
 * State WeaponFiring
 * This is the default Firing State.  It's performed on both the client and the server.
 *********************************************************************************************/

defaultproperties
{
	
	bSuppressSounds=false

	MaxAmmoCount=100
	
	EffectSockets(0)=MuzzleFlashSocket
	EffectSockets(1)=MuzzleFlashSocket
	
	MuzzleFlashSocket=MuzzleFlashSocket
	
	ShotCost(0)=1
	ShotCost(1)=1
	
	FiringStatesArray(0)=WeaponFiring
	FiringStatesArray(1)=WeaponFiring

	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_Projectile

	WeaponProjectiles(0)=none
	WeaponProjectiles(1)=none
	
	FireInterval(0)=+1.0
	FireInterval(1)=+1.0
	
	Spread(0)=0.0
	Spread(1)=0.0
	
	//ProjectileSpawnOffset=2.0;
}
