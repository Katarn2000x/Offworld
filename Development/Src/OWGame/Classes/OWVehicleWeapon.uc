/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWVehicleWeapon extends OWWeapon
    dependson(OWVehiclePawn)
    abstract;
    
/** Holds a link in to the Seats array in MyVehicle that represents this weapon */
var int SeatIndex;

/** Holds a link to the parent vehicle */
var RepNotify OWVehiclePawn    MyVehicle;

/** Triggers that should be activated when a weapon fires */
var array<name>    FireTriggerTags, AltFireTriggerTags;

/** This value is used to cap the maximum amount of "automatic" adjustment that will be made to a shot
    so that it will travel at the crosshair.  If the angle between the barrel aim and the player aim is
    less than this angle, it will be adjusted to fire at the crosshair.  The value is in radians */
var float MaxFinalAimAdjustment;

/**
 * If the weapon is attached to a socket that doesn't pitch with
 * player view, and should fire at the aimed pitch, then this should be enabled.
 */
var bool bIgnoreSocketPitchRotation;

/**
 * Same as above, but only allows for downward direction, for vehicles with 'bomber' like behavior.
 */
var bool bIgnoreDownwardPitch;

var bool bPlaySoundFromSocket;

replication
{
    if (bNetInitial && bNetOwner)
        SeatIndex, MyVehicle;
}

simulated static function Name GetFireTriggerTag(int BarrelIndex, int FireMode)
{
    if (FireMode==0)
    {
        if (default.FireTriggerTags.Length > BarrelIndex)
        {
            return default.FireTriggerTags[BarrelIndex];
        }
    }
    else
    {
        if (default.AltFireTriggerTags.Length > BarrelIndex)
        {
            return default.AltFireTriggerTags[BarrelIndex];
        }
    }
    return '';
}

/**
 * Called on the LocalPlayer, Fire sends the shoot request to the server (ServerStartFire)
 * and them simulates the firing effects locally.
 * Call path: PlayerController::StartFire -> Pawn::StartFire -> InventoryManager::StartFire
 * Network: LocalPlayer
 */
simulated function StartFire(byte FireModeNum)
{
    `Log("Attempted to start fire on vehicle weapon");
    super.StartFire( FireModeNum );
}

/** returns the location and rotation that the weapon's fire starts at */
simulated function GetFireStartLocationAndRotation(out vector StartLocation, out rotator StartRotation)
{
    `Log("I'm attempting to get the fire start location and rotation of the weapon");
    if ( MyVehicle == None )
    {
        return;
    }
    if ( MyVehicle.Seats[SeatIndex].GunSocket.Length>0 )
    {
        MyVehicle.GetBarrelLocationAndRotation(SeatIndex, StartLocation, StartRotation);
    }
    else
    {
        StartLocation = MyVehicle.Location;
        StartRotation = MyVehicle.Rotation;
    }
}



simulated function AttachWeaponTo( SkeletalMeshComponent MeshCpnt, optional Name SocketName );
simulated function DetachWeapon();

simulated function Vector GetPhysicalFireStartLoc(optional vector AimDir)
{
    `Log("I'm attempting to get the physical fire start loc of the weapon");
    if ( MyVehicle != none )
        return MyVehicle.GetPhysicalFireStartLoc(self);
    else
        return Location;
}

simulated function Rotator GetAdjustedAim( vector StartFireLoc )
{
    `Log("I'm attempting to get the adjusted aim of the vehicle weapon");
    // Start the chain, see Pawn.GetAdjustedAimFor()
    // @note we don't add in spread here because UTVehicle::GetWeaponAim() assumes
    // that a return value of Instigator.Rotation or Instigator.Controller.Rotation means 'no adjustment', which spread interferes with
    return Instigator.GetAdjustedAimFor( Self, StartFireLoc );
}

/**
 * Create the projectile, but also increment the flash count for remote client effects.
 */
simulated function Projectile ProjectileFire()
{
    local Projectile SpawnedProjectile;
    
    `Log("I'm attempting to fire the weapon");

    IncrementFlashCount();
	MyVehicle.IncrementBarrelIndex();

    if (Role==ROLE_Authority)
    {
        SpawnedProjectile = Spawn(GetProjectileClass(),,, MyVehicle.GetPhysicalFireStartLoc(self));

        if ( SpawnedProjectile != None )
        {
            SpawnedProjectile.Init( vector(AddSpread(MyVehicle.GetWeaponAim(self))) );
        }
    }
    return SpawnedProjectile;
}

simulated function WeaponPlaySound( SoundCue Sound, optional float NoiseLoudness )
{
    local int Barrel;
    local name Pivot;
    local vector Loc;
    local rotator Rot;
    
    `Log("I'm attempting to play the weapon sound");
    
    if(bPlaySoundFromSocket && MyVehicle != none && MyVehicle.Mesh != none)
    {
        if( Sound == None || Instigator == None )
        {
            return;
        }
        Barrel = MyVehicle.GetBarrelIndex(SeatIndex);
        Pivot = MyVehicle.Seats[SeatIndex].GunSocket[Barrel];
        MyVehicle.Mesh.GetSocketWorldLocationAndRotation(Pivot, Loc, Rot);
        Instigator.PlaySound(Sound, false, true,false,Loc);
    }
    else super.WeaponPlaySound(Sound,NoiseLoudness);
}

simulated function float GetMaxFinalAimAdjustment()
{
    return MaxFinalAimAdjustment;
}

simulated function BeginFire(byte FireModeNum)
{    
    local OWVehiclePawn V;
    `Log("I'm attempting to beginfire");

    // allow the vehicle to override the call
    V = OWVehiclePawn(Instigator);
    if (V == None || (!V.bIsDisabled && !V.OverrideBeginFire(FireModeNum)))
    {
        Super.BeginFire(FireModeNum);
    }
}

simulated function EndFire(byte FireModeNum)
{
    local OWVehiclePawn V;
    `Log("I'm attempting to endfire");
    // allow the vehicle to override the call
    V = OWVehiclePawn(Instigator);
	
    if (V == None || !V.OverrideEndFire(FireModeNum))
    {
        `Log("I'm calling the superclass of endfire");
        Super.EndFire(FireModeNum);
    }
}
/*
simulated state WeaponEquipping
{
	simulated event BeginState( Name PreviousStateName)
	{
		super.BeginState ( PreviousStateName );
		MyVehicle.ResetBarrelIndex(SeatIndex);	
	}
}
*/

defaultproperties
{
    TickGroup=TG_PostAsyncWork
    InventoryGroup=100
    GroupWeight=0.5
    
    ShotCost[0]=0
    ShotCost[1]=0

    // ~ 5 Degrees
    MaxFinalAimAdjustment=0.995

    //AimError=600
    bIgnoreSocketPitchRotation = false
}
