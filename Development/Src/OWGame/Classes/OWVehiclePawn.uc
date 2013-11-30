/**
 * Conceptual merge of the Pawn and Vehicle concepts. Contains code that every pawn in Offworld should have.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class OWVehiclePawn extends UDKVehicle
    abstract
    notplaceable;

/** Array of all engines attached to the vehicle which should contribute to physics. */
var array<OWEngine> Engines;

/** Array of all couples attached to the vehicle which should contribute to physics. */
var array<OWCouple> Couples;

/** The pawn's light environment */
var DynamicLightEnvironmentComponent LightEnvironment;

/** The sensitivity factor applied to linear axial input (The three basic movement axis). */
var const float LinearInputFactor;

/** The sensitivity factor applied to rotional axial input (The three basic rotational axis). */
var const float RotationalInputFactor;

/** Whether the driver can see his own mesh. */
var bool bVehicleVisableToDriver;

/** The user desired Linear Acceleration direction as defined by SetInputs. */
var vector LinearInput;

/** The user desired Rotational acceleration direction as defined by SetInputs. */
var vector RotationalInput;

/** The maximum distance out where a fire effect will be spawned */
var float MaxFireEffectDistance;


/** set after attaching vehicle effects, as this is delayed slightly to allow time for team info to be set */
var bool bInitializedVehicleEffects;

/** The health ratio threshold at which the vehicle will begin smoking */
var float DamageSmokeThreshold;

var int TotalBarrels;
var int LastBarrelIndex;

/** Templates used for explosions */
var ParticleSystem ExplosionTemplate;
var array<DistanceBasedParticleTemplate> BigExplosionTemplates;
/** Secondary explosions from vehicles.  (usually just dust when they are impacting something) **/
var ParticleSystem SecondaryExplosion;

/**
 * How long to wait after the InitialVehicleExplosion before doing the Secondary VehicleExplosion (if it already has not happened)
 * (e.g. due to the vehicle falling from the air and hitting the ground and doing it's secondary explosion that way).
 **/
var float TimeTilSecondaryVehicleExplosion;

/**
 * This is a reference to the Emitter we spawn on death.  We need to keep a ref to it (briefly) so we can
 * turn off the particle system when the vehicle decided to burnout.
 **/
var Emitter DeathExplosion;

/** sound for dying explosion */
var SoundCue ExplosionSound;

/** Damage/Radius/Momentum parameters for dying explosions */
var float ExplosionDamage, ExplosionRadius, ExplosionMomentum;

/** If vehicle dies in the air, this is how much spin is given to it. */
var float ExplosionInAirAngVel;

/** socket to attach big explosion to (if 'None' it won't be attached at all) */
var name BigExplosionSocket;

/** Class of ExplosionLight */
var class<UDKExplosionLight> ExplosionLightClass;

/** Max distance to create ExplosionLight */
var float	MaxExplosionLightDistance;

/** Stop death camera using OldCameraPosition if true */
var bool bStopDeathCamera;

/** OldCameraPosition saved when dead for use if fall below killz */
var vector OldCameraPosition;

var vector DeathCamLocation;


var SkeletalMeshComponent SVehicleMeshRef;
var UDKSkeletalMeshComponent CockpitMesh;

/** FOV to use when driving this vehicle */
var float DefaultFOV;

/**
 * Pawn starts firing!
 * Called from PlayerController::StartFiring
 * Network: Local Player
 *
 * @param    FireModeNum        fire mode number
 */
simulated function StartFire(byte FireModeNum)
{
    `Log("Attempted to start fire from vehicle, firemodenum: " $FireModeNum);
    
    if( bNoWeaponFIring )
    {
        `Log("There's no weapon firing");
        return;
    }
    if( Weapon == None)
    {
        `Log("self.Weapon is: " $self.Weapon);
    
    }
    if( Weapon != None )
    {
        `Log("Calling Weapon.StartFire()");
        Weapon.StartFire(FireModeNum);
    }
    `Log("Reached  the end of the function");
}

simulated event PostBeginPlay()
{
	local OWEngine Engine;
	local OWCouple Couple;
    local PlayerController PC;
    super.PostBeginPlay();
    
    if (Role == ROLE_Authority)
    {    
        if( !bDeleteMe && OWGame(WorldInfo.Game) != None)
        {
            //OWGame(WorldInfo.Game).RegisterVehicle(self);
        }
        
        //setup the seats array
        InitializeSeats();    
        `log("Set up them seats");
    }
    else if (Seats.length > 0)
    {
        Seats[0].SeatPawn = self;
        `log("Set the seat pawn to the vehicle itself");
    }
        
    //VehicleEvent('Created');
    InitializeTurrets();        // Setup the turrets
	
	foreach Engines(Engine)
	{
		`Log("We have engine: " $Engine);
	}
	foreach Couples(Couple)
	{
		`Log("We have couple: " $Couple);
	}
	
}

/**
 * Create all of the vehicle weapons
 */
function InitializeSeats()
{
    local int i;
    if (Seats.Length==0)
    {
        `log("WARNING: Vehicle ("$self$") **MUST** have at least one seat defined");
        destroy();
        return;
    }

    for(i=0;i<Seats.Length;i++)
    {
        // Seat 0 = Driver Seat.  It doesn't get a WeaponPawn
        
        if (i>0)
        {
            /*********************** This Shit is for gunners that aren't drivers, don't need yet *************************
            
               Seats[i].SeatPawn = Spawn(class'UTWeaponPawn');
               Seats[i].SeatPawn.SetBase(self);
            Seats[i].Gun = UTVehicleWeapon(Seats[i].SeatPawn.InvManager.CreateInventory(Seats[i].GunClass));
            Seats[i].Gun.SetBase(self);
            Seats[i].SeatPawn.EyeHeight = Seats[i].SeatPawn.BaseEyeheight;
            UTWeaponPawn(Seats[i].SeatPawn).MyVehicleWeapon = UTVehicleWeapon(Seats[i].Gun);
            UTWeaponPawn(Seats[i].SeatPawn).MyVehicle = self;
               UTWeaponPawn(Seats[i].SeatPawn).MySeatIndex = i;

               if ( Seats[i].ViewPitchMin != 0.0f )
               {
                UTWeaponPawn(Seats[i].SeatPawn).ViewPitchMin = Seats[i].ViewPitchMin;
            }
            else
               {
                UTWeaponPawn(Seats[i].SeatPawn).ViewPitchMin = ViewPitchMin;
            }


               if ( Seats[i].ViewPitchMax != 0.0f )
               {
                UTWeaponPawn(Seats[i].SeatPawn).ViewPitchMax = Seats[i].ViewPitchMax;
            }
            else
               {
                UTWeaponPawn(Seats[i].SeatPawn).ViewPitchMax = ViewPitchMax;
            }
            ***************************************************************************************/
        }
        
        else
        {
            Seats[i].SeatPawn = self;
            Seats[i].Gun = OWVehicleWeapon(InvManager.CreateInventory(Seats[i].GunClass));
            Seats[i].Gun.SetBase(self);
            
            `Log("Set the SeatPawn, Gun is created in invmanager, base is set");
        }

        Seats[i].SeatPawn.DriverDamageMult = Seats[i].DriverDamageMult;
        Seats[i].SeatPawn.bDriverIsVisible = Seats[i].bSeatVisible;

        if (Seats[i].Gun!=none)
        {
            `Log("There is a gun");
            OWVehicleWeapon(Seats[i].Gun).SeatIndex = i;
            OWVehicleWeapon(Seats[i].Gun).MyVehicle = self;
            `Log("Set the gun's seatindex and the reference to myvehicle");
    
        }

        // Cache the names used to access various variables
        
       }
}

simulated function InitializeTurrets()
{
    local int Seat, i;
    local OWSkelControl_TurretConstrained Turret;
    local vector PivotLoc, MuzzleLoc;

    if (Mesh == None)
    {
        `warn("No Mesh for" @ self);
    }
    else
    {
        for (Seat = 0; Seat < Seats.Length; Seat++)
        {
            for (i = 0; i < Seats[Seat].TurretControls.Length; i++)
            {
                Turret = OWSkelControl_TurretConstrained( Mesh.FindSkelControl(Seats[Seat].TurretControls[i]) );
                if ( Turret != none )
                {
                    Turret.AssociatedSeatIndex = Seat;
                    Seats[Seat].TurretControllers[i] = Turret;

                    // Initialize turrets to vehicle rotation.
                    Turret.InitTurret(Rotation, Mesh);
                }
                else
                {
                    `warn("Failed to find skeletal controller named" @ Seats[Seat].TurretControls[i] @ "(Seat "$Seat$") for" @ self @ "in AnimTree" @ Mesh.AnimTreeTemplate);
                }
            }

            if(Role == ROLE_Authority)
            {
                SeatWeaponRotation(Seat, Rotation, FALSE);
            }

            // Calculate Z distance between weapon pivot and muzzle
            PivotLoc = GetSeatPivotPoint(Seat);
            GetBarrelLocationAndRotation(Seat, MuzzleLoc);

            Seats[Seat].PivotFireOffsetZ = MuzzleLoc.Z - PivotLoc.Z;
        }
    }
}

/**
 * An interface for causing various events on the vehicle.
 */
simulated function VehicleEvent(name EventTag)
{
    // Cause/kill any effects
    TriggerVehicleEffect(EventTag);

    // Play any animations
    //PlayVehicleAnimation(EventTag);

    PlayVehicleSound(EventTag);
}


/************************************************************************************
 * Effects
 ***********************************************************************************/

simulated function CreateVehicleEffect(int EffectIndex)
{
    VehicleEffects[EffectIndex].EffectRef = new(self) class'OWParticleSystemComponent';
    if (VehicleEffects[EffectIndex].EffectStartTag != 'BeginPlay')
    {
        VehicleEffects[EffectIndex].EffectRef.bAutoActivate = false;
    }

    // if we have a blue particle system and we are on the blue team
    if (VehicleEffects[EffectIndex].EffectTemplate_Blue != None && GetTeamNum() == 1)
    {
        VehicleEffects[EffectIndex].EffectRef.SetTemplate(VehicleEffects[EffectIndex].EffectTemplate_Blue);
    }
    // use the default template which will be red or some neutral color
    else
    {
        VehicleEffects[EffectIndex].EffectRef.SetTemplate(VehicleEffects[EffectIndex].EffectTemplate);
    }

    Mesh.AttachComponentToSocket(VehicleEffects[EffectIndex].EffectRef, VehicleEffects[EffectIndex].EffectSocket);
}

/**
 * Initialize the effects system.  Create all the needed PSCs and set their templates
 */
simulated function InitializeEffects()
{
    if (WorldInfo.NetMode != NM_DedicatedServer && !bInitializedVehicleEffects)
    {
        bInitializedVehicleEffects = true;
        TriggerVehicleEffect('BeginPlay');
    }
}

/**
 * Whenever a vehicle effect is triggered, this function is called (after activation) to allow for the
 * setting of any parameters associated with the effect.
 *
 * @param    TriggerName        The effect tag that describes the effect that was activated
 * @param    PSC                The Particle System component associated with the effect
 */
simulated function SetVehicleEffectParms(name TriggerName, ParticleSystemComponent PSC)
{
    local float Pct;

    if (TriggerName == 'DamageSmoke')
    {
        Pct = float(Health) / float(HealthMax);
        PSC.SetFloatParameter('smokeamount', (Pct < DamageSmokeThreshold) ? (1.0 - Pct) : 0.0);
        PSC.SetFloatParameter('fireamount', (Pct < FireDamageThreshold) ? (1.0 - Pct) : 0.0);
    }
}
/**
 * Trigger or untrigger a vehicle effect
 *
 * @param    EventTag    The tag that describes the effect
 *
 */
simulated function TriggerVehicleEffect(name EventTag)
{
    local int i;

    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        for (i = 0; i < VehicleEffects.length; i++)
        {
            if (VehicleEffects[i].EffectStartTag == EventTag)
            {
                if ( !VehicleEffects[i].bHighDetailOnly || (WorldInfo.GetDetailMode() == DM_High) )
                {
                    if (VehicleEffects[i].EffectRef == None)
                    {
                        CreateVehicleEffect(i);
                    }
                    if (VehicleEffects[i].bRestartRunning)
                    {
                        VehicleEffects[i].EffectRef.KillParticlesForced();
                        VehicleEffects[i].EffectRef.ActivateSystem();
                    }
                    else if (!VehicleEffects[i].EffectRef.bIsActive)
                    {
                        VehicleEffects[i].EffectRef.ActivateSystem();
                    }

                    SetVehicleEffectParms(EventTag, VehicleEffects[i].EffectRef);
                }
            }
            else if (VehicleEffects[i].EffectRef != None && VehicleEffects[i].EffectEndTag == EventTag)
            {
                VehicleEffects[i].EffectRef.DeActivateSystem();
            }
        }
    }
}

/**
 * These two functions needs to be subclassed in each weapon
 */
simulated function VehicleAdjustFlashCount(int SeatIndex, byte FireModeNum, optional bool bClear)
{
    if (bClear)
    {
        SeatFlashCount( SeatIndex, 0 );
        VehicleWeaponStoppedFiring( false, SeatIndex );
    }
    else
    {
        SeatFiringMode(SeatIndex,FireModeNum);
        SeatFlashCount( SeatIndex, SeatFlashCount(SeatIndex,,true)+1 );
        VehicleWeaponFired( false, vect(0,0,0), SeatIndex );
        Seats[SeatIndex].BarrelIndex++;
    }

    bForceNetUpdate = TRUE;    // Force replication
}

simulated function VehicleAdjustFlashLocation(int SeatIndex, byte FireModeNum, vector NewLocation, optional bool bClear)
{
    if (bClear)
    {
        SeatFlashLocation( SeatIndex, Vect(0,0,0) );
        VehicleWeaponStoppedFiring( false, SeatIndex );
    }
    else
    {
        // Make sure 2 consecutive flash locations are different, for replication
        if( NewLocation == SeatFlashLocation(SeatIndex,,true) )
        {
            NewLocation += vect(0,0,1);
        }

        // If we are aiming at the origin, aim slightly up since we use 0,0,0 to denote
        // not firing.
        if( NewLocation == vect(0,0,0) )
        {
            NewLocation = vect(0,0,1);
        }

        SeatFiringMode(SeatIndex,FireModeNum);
        SeatFlashLocation( SeatIndex, NewLocation );
        VehicleWeaponFired( false, NewLocation, SeatIndex );
        Seats[SeatIndex].BarrelIndex++;
    }


    bForceNetUpdate = TRUE;    // Force replication
}

simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation)
{
    VehicleWeaponFired(bViaReplication, HitLocation, 0);
}

/**
 * Vehicle will want to override WeaponFired and pass off the effects to the proper Seat
 */
simulated function VehicleWeaponFired( bool bViaReplication, vector HitLocation, int SeatIndex )
{
    // Trigger any vehicle Firing Effects
    if ( WorldInfo.NetMode != NM_DedicatedServer )
    {
        VehicleWeaponFireEffects(HitLocation, SeatIndex);

        if (Role == ROLE_Authority || bViaReplication)
        {
            //VehicleWeaponImpactEffects(HitLocation, SeatIndex);
        }

        if (SeatIndex == 0)
        {
            Seats[SeatIndex].Gun = OWVehicleWeapon(Weapon);
        }
        if (Seats[SeatIndex].Gun != None)
        {
            //OWVehicleWeapon(Seats[SeatIndex].Gun).ShakeView();
        }
        if ( EffectIsRelevant(Location,false,MaxFireEffectDistance) )
        {
            CauseMuzzleFlashLight(SeatIndex);
        }
    }
}
simulated function WeaponStoppedFiring(Weapon InWeapon, bool bViaReplication)
{
    VehicleWeaponStoppedFiring(bViaReplication, 0);
}

simulated function VehicleWeaponStoppedFiring( bool bViaReplication, int SeatIndex )
{
    local name StopName;

    // Trigger any vehicle Firing Effects
    if ( WorldInfo.NetMode != NM_DedicatedServer )
    {
        if (Role == ROLE_Authority || bViaReplication)
        {
            StopName = Name( "STOP_"$class<OWVehicleWeapon>(Seats[SeatIndex].GunClass).static.GetFireTriggerTag( GetBarrelIndex(SeatIndex) , SeatFiringMode(SeatIndex,,true) ) );
            VehicleEvent( StopName );
        }
    }
}

/**
 * This function should be subclassed and manage the different effects
 */
simulated function VehicleWeaponFireEffects(vector HitLocation, int SeatIndex)
{
    VehicleEvent( class<OWVehicleWeapon>(Seats[SeatIndex].GunClass).static.GetFireTriggerTag( GetBarrelIndex(SeatIndex), SeatFiringMode(SeatIndex,,true) ) );
}
/**
 * Trigger or untrigger a vehicle sound
 *
 * @param    EventTag    The tag that describes the effect
 *
 */
simulated function PlayVehicleSound(name SoundTag)
{
    local int i;
	
	`Log("Should be playing vehicle sound");
    for(i=0;i<VehicleSounds.Length;++i)
    {
        if(VehicleSounds[i].SoundEndTag == SoundTag)
        {
            if(VehicleSounds[i].SoundRef != none)
            {
                VehicleSounds[i].SoundRef.Stop();
                VehicleSounds[i].SoundRef = none;
            }
        }
        if(VehicleSounds[i].SoundStartTag == SoundTag)
        {
            if(VehicleSounds[i].SoundRef == none)
            {
                VehicleSounds[i].SoundRef = CreateAudioComponent(VehicleSounds[i].SoundTemplate, false, true);
            }
            if(VehicleSounds[i].SoundRef != none && (!VehicleSounds[i].SoundRef.bWasPlaying || VehicleSounds[i].SoundRef.bFinished))
            {
                VehicleSounds[i].SoundRef.Play();
            }
        }
    }
}

simulated function IncrementBarrelIndex()
{
	
	LastBarrelIndex++;
	if( LastBarrelIndex > (TotalBarrels - 1))
	{
		LastBarrelIndex=0;
	}
	`Log("Increment Barrel Index Called " $LastBarrelIndex);
}

simulated function ResetBarrelIndex(int SeatIndex)
{

	TotalBarrels = (Seats[SeatIndex].GunSocket.Length);
	LastBarrelIndex=0;
		`Log("Reset Barrel Index called, TotalBarrels: " $TotalBarrels);
}

simulated function int GetOWBarrelIndex(int SeatIndex)
{

	if( Seats[SeatIndex].GunSocket.Length > 0)
	{	
		return LastBarrelIndex;
	}
		`Log("Get OW Barrel Index called: " $LastBarrelIndex);
}

simulated event GetBarrelLocationAndRotation(int SeatIndex, out vector SocketLocation, optional out rotator SocketRotation)
{
    if (Seats[SeatIndex].GunSocket.Length>0)
    {
        Mesh.GetSocketWorldLocationAndRotation(Seats[SeatIndex].GunSocket[GetOWBarrelIndex(SeatIndex)], SocketLocation, SocketRotation);
    }
    else
    {
        SocketLocation = Location;
        SocketRotation = Rotation;
    }
}

simulated function Vector GetPhysicalFireStartLoc(OWWeapon ForWeapon)
{
    local OWVehicleWeapon VWeap;
    
    `Log("I'm attempting to get the physical fire start location of the vehicle weapon");

    VWeap = OWVehicleWeapon(ForWeapon);
    if ( VWeap != none )
    {
        return GetEffectLocation(VWeap.SeatIndex);
    }
    else
        return location;
}

simulated function vector GetEffectLocation(int SeatIndex)
{
    local vector SocketLocation;
    
    `Log("I'm attempting to get the effect location");

    if ( Seats[SeatIndex].GunSocket.Length == 0 )
        return Location;

    GetBarrelLocationAndRotation(SeatIndex,SocketLocation);
    return SocketLocation;
}

function rotator GetWeaponAim(OWVehicleWeapon VWeapon)
{
    local vector SocketLocation, CameraLocation, RealAimPoint, DesiredAimPoint, HitLocation, HitRotation, DirA, DirB;
    local rotator CameraRotation, SocketRotation, ControllerAim, AdjustedAim;
    local float DiffAngle, MaxAdjust;
    local Controller C;
    local PlayerController PC;
    local Quat Q;
    
    `Log("I'm attempting to get the weapon's aim");
    
    if(VWeapon != None)
    {
        C = Seats[VWeapon.SeatIndex].SeatPawn.Controller;
        
        PC = PlayerController(C);
        if(PC != None)
        {
            PC.GetPlayerViewPoint(CameraLocation, CameraRotation);   
            DesiredAimPoint = CameraLocation + Vector(CameraRotation) * VWeapon.GetTraceRange();
            if (Trace(HitLocation, HitRotation, DesiredAimPoint, CameraLocation) != None)
            {
                DesiredAimPoint = HitLocation;
            }     
        }
        else if( C != None)
        {
            DesiredAimPoint = C.GetFocalPoint();  
        }
        
        if( Seats[VWeapon.SeatIndex].GunSocket.Length>0)
        {
            GetBarrelLocationAndRotation(VWeapon.SeatIndex, SocketLocation, SocketRotation);
            if(VWeapon.bIgnoreSocketPitchRotation || ((DesiredAimPoint.Z - Location.Z)<0 && VWeapon.bIgnoreDownwardPitch))
            {
                SocketRotation.Pitch = Rotator(DesiredAimPoint - Location).Pitch;
            }
        }
        else
        {
            SocketLocation = Location;
            SocketRotation = Rotator(DesiredAimPoint - Location);
        }    
    
        RealAimPoint = SocketLocation + Vector(SocketRotation) * VWeapon.GetTraceRange();
        DirA = normal(DesiredAimPoint - SocketLocation);
        DirB = normal(RealAimPoint - SocketLocation);
        DiffAngle = ( DirA dot DirB );
        MaxAdjust = VWeapon.GetMaxFinalAimAdjustment();
        if ( DiffAngle >= MaxAdjust )
        {
            // bit of a hack here to make bot aiming and single player autoaim work
            ControllerAim = (C != None) ? C.Rotation : Rotation;
            AdjustedAim = VWeapon.GetAdjustedAim(SocketLocation);
            if (AdjustedAim == VWeapon.Instigator.GetBaseAimRotation() || AdjustedAim == ControllerAim)
            {
                // no adjustment
                return rotator(DesiredAimPoint - SocketLocation);
            }
            else
            {
                // FIXME: AdjustedAim.Pitch = Instigator.LimitPitch(AdjustedAim.Pitch);
                return AdjustedAim;
            }
        }
        else
        {
            Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), ACos(MaxAdjust));
            return Rotator( QuatRotateVector(Q,DirB));
        }
    }
    else
    {
        return Rotation;
    }

}

simulated function bool OverrideBeginFire(byte FireModeNum);
simulated function bool OverrideEndFire(byte FireModeNum);

/**
 * Causes the muzzle flashlight to turn on and setup a time to
 * turn it back off again.
 */
simulated function CauseMuzzleFlashLight(int SeatIndex)
{
    // must have valid gunsocket
    if (Seats[SeatIndex].GunSocket.Length == 0 || bDeadVehicle)
        return;

    // only enable muzzleflash light if performance is high enough
    if ( !WorldInfo.bDropDetail || (Seats[SeatIndex].SeatPawn != None && PlayerController(Seats[SeatIndex].SeatPawn.Controller) != None && Seats[SeatIndex].SeatPawn.IsLocallyControlled()) )
    {
        if ( Seats[SeatIndex].MuzzleFlashLight == None )
        {
            if ( Seats[SeatIndex].MuzzleFlashLightClass != None )
            {
                Seats[SeatIndex].MuzzleFlashLight = new(Outer) Seats[SeatIndex].MuzzleFlashLightClass;
            }
        }
        else
        {
            Seats[SeatIndex].MuzzleFlashLight.ResetLight();
        }

        // FIXMESTEVE: OFFSET!

        if ( Seats[SeatIndex].MuzzleFlashLight != none )
        {
            Mesh.DetachComponent(Seats[SeatIndex].MuzzleFlashLight);
            Mesh.AttachComponentToSocket(Seats[SeatIndex].MuzzleFlashLight, Seats[SeatIndex].GunSocket[GetBarrelIndex(SeatIndex)]);
        }
    }
}

simulated function bool CalcCamera(float DeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV)
{
    local vector out_CamStart;

    VehicleCalcCamera(DeltaTime, 0, out_CamLoc, out_CamRot, out_CamStart);
    return true;
}

simulated function VehicleCalcCamera(float DeltaTime, int SeatIndex, out vector out_CamLoc, out rotator out_CamRot, out vector CamStart, optional bool bPivotOnly)
{
    Mesh.GetSocketWorldLocationAndRotation(Seats[SeatIndex].CameraTag, out_CamLoc, out_CamRot);
}

simulated function SetUpThirdPersonView()
{
	SVehicleMeshRef.SetHidden(false);
	CockpitMesh.SetHidden(true);
}

simulated function SetUpFirstPersonView()
{
	CockpitMesh.SetHidden(false);
	SVehicleMeshRef.SetHidden(true);
}

/** Driver will never leave... Ever... MUAHAHAHAHAHA */
event bool DriverLeave( bool bForceLeave )
{
	return Super.DriverLeave(bForceLeave);
}


simulated function DrivingStatusChanged()
{
	Super.DrivingStatusChanged();
	if(!bDriving)
	{
		//puts the brakes on when the driver gets out
		
		LinearInput.X = 0;
		LinearInput.Y = 0;
		LinearInput.Z = 0;
		
		RotationalInput.X = 0;
		RotationalInput.Y = 0;
		RotationalInput.Z = 0;
	}
}

function bool DriverEnter(Pawn P)
{
    local OWPlayerController PC;
    
    P.StopFiring();
    
	SetUpFirstPersonView();
	
    if(Seats[0].Gun != none)
    {
        `Log("Set the Current Weapon to " $Seats[0].Gun);
        InvManager.SetCurrentWeapon(Seats[0].Gun);
		ResetBarrelIndex(0);
        `Log("The actual weapon is set to " $self.Weapon);
    }
    
    Instigator = self;
    
    if( !Super.DriverEnter(P) )
        return false;
        
    //SetSeatStoragePawn(0,P);
    return true;
}
    
    
    
/** Sets our force vector */
simulated function SetInputsOW(vector RawLinearInput, vector RawRotationalInput)
{	
	local vector AdjustedLinearInput, AdjustedRotationalInput;

    //RawLinearInput     /= LinearInputFactor;
    //RawRotationalInput     /= RotationalInputFactor;
	AdjustedLinearInput = RawLinearInput / LinearInputFactor;
	AdjustedRotationalInput = RawRotationalInput / RotationalInputFactor;
	
    LinearInput.X = FClamp(AdjustedLinearInput.X, -1.0f, 1.0f);
    LinearInput.Y = FClamp(AdjustedLinearInput.Y, -1.0f, 1.0f);
    LinearInput.Z = FClamp(AdjustedLinearinput.Z, -1.0f, 1.0f);
    
    RotationalInput.X = FClamp(AdjustedRotationalInput.X, -1.0f, 1.0f);
    RotationalInput.Y = FClamp(AdjustedRotationalInput.Y, -1.0f, 1.0f);
    RotationalInput.Z = FClamp(AdjustedRotationalInput.Z, -1.0f, 1.0f);
}

event Tick(float DeltaTime)
{
    super.tick(DeltaTime);
    HandlePhysics(DeltaTime);
}

function HandlePhysics(float DeltaTime)
{
    local OWEngine Engine;
    local OWCouple Couple;
    local vector Force;
    local vector Torque;
    local vector CarryVector;
    	
    // Apply Throttle
    foreach Engines(Engine)
    {
        CarryVector.Y = 0.f;
        CarryVector.Z = 0.f;
        Engine.Throttle = FClamp(Engine.Throttle, -1.0f, 1.0f);
        Engine.Thrust += Engine.Throttle * Engine.Yank * DeltaTime;
        Engine.Thrust = FClamp(Engine.Thrust, Engine.MinThrust, Engine.MaxThrust);
        CarryVector.X = Engine.Thrust;
        
        CarryVector = TransformVectorByRotation(Engine.Rotation, CarryVector);
        Force += CarryVector;
        Torque += Engine.Position cross CarryVector;
    }
    
    foreach Couples(Couple)
    {
        CarryVector.Y = 0.f;
        CarryVector.Z = 0.f;
        Couple.Throttle = FClamp(Couple.Throttle, -1.0f, 1.0f);
        Couple.Torque += Couple.Throttle * Couple.Power * DeltaTime;
        Couple.Torque = FClamp(Couple.Torque, Couple.MinTorque, Couple.MaxTorque);
        CarryVector.X = Couple.Torque;
        
        Torque += TransformVectorByRotation(Couple.Rotation, CarryVector);
    }
    
    AddForce(TransformVectorByRotation(Rotation, Force ) );
    AddTorque(TransformVectorByRotation(Rotation, Torque) );
}


function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local OWPlayerReplicationInfo OWPRI;
	local int i;
	
	`Log("The pawn has run Died");
	if( Super(Vehicle).Died(Killer, DamageType, HitLocation) )
	{
		KillerController = Killer;
		HitDamageType = DamageType; //these are replicated to other clients
		TakeHitLocation = HitLocation;
		
		OWPRI = OWPlayerReplicationInfo(PlayerReplicationInfo);
		
		if( OWPRI != None )
		{
			//OWPRI.StopDrivingStat(GetVehicleDrivingStatName());
		}
		
		BlowupVehicle();
		
		HandleDeadVehicleDriver();
		
		for ( i = 1; i < Seats.Length; i++)
		{
			if(Seats[i].SeatPawn != None)
			{
				OWPRI = OWPlayerReplicationInfo(Seats[i].SeatPawn.PlayerReplicationInfo);
				if( OWPRI != None)
				{
					//OWPRI.StopDrivingStat(UDKVehicleBase(Seats[i].SeatPawn).GetVehicleDrivingStatName());
				}
				//Kill the weaponpawn with the appropriate killer, etc for kill credit and death messages
				Seats[i].SeatPawn.Died(Killer, DamageType, HitLocation);
			}
		}
		return true;
	}
	return false;
}

function HandleDeadVehicleDriver()
{
	local Pawn OldDriver;
	local OWVehiclePawn Vehicle;
	if(Driver != None)
	{
		Vehicle = self;
		Driver.StopDriving(self);
		Driver.DrivenVehicle = self;
		
		OldDriver = Driver;
		Driver = None;
		`Log("Old driver is " $OldDriver);
		OldDriver.DrivenVehicle = None;
		OldDriver.Destroy();	
	}
}

/**
 * Call this function to blow up the vehicle
 */
simulated function BlowupVehicle()
{
	local int i;
	
	if(bDriving)
	{
		VehicleEvent('EngineStop');
	}
	
	bCanBeBaseForPawns = false;
	GotoState('DyingVehicle');
	AddVelocity(TearOffMomentum, TakeHitLocation, HitDamageType);
	bDeadVehicle = true;
	bStayUpright = false;
	
}

simulated state DyingVehicle
{
	
	simulated function PlayWeaponSwitch(Weapon OldWeapon, Weapon NewWeapon) {}
	simulated function PlayNextAnimation(){}
	singular event BaseChange(){}
	event Landed(vector HitNormal, Actor FloorActor){}
	
	function bool Died(Controller Killer, Class<DamageType> damageType, vector HitLocation);
	simulated event PostRenderFor(PlayerController PC, Canvas Canvas, vector CameraPosition, vector CameraDir) {}
	simulated function BlowupVehicle() {}
	simulated function CheckDamageSmoke();
	
	simulated function BeginState(name PreviousStateName)
	{
		local int i;
		`Log("Entered vehicle dying state");
		SetUpThirdPersonView();
		DeathCamLocation = Location; 
		StopVehicleSounds();
		
		//make sure smoke/fire are on
		DamageSmokeThreshold = 0.0; //VehicleEvent('DamageSmoke');
		CheckDamageSmoke();
		//fully destroy morph targets
		/*
		for ( i = 0; i < DamageMorphTargets.length; i++ )
		{
			DamageMorphTargets[i].Health = 0;
			if(DamageMorphTargets[i].MorphNode != None)
			{
				DamageMorphTargets[i].MorphNode.SetNodeWeight(1.0);			
			}
		}
		*/
		UpdateDamageMaterial();
		//ClientHealth = Min(ClientHealth, 0);
		
		LastCollisionSoundTime = WorldInfo.TimeSeconds;
		DoVehicleExplosion(false);
		
		if( TimeTilSecondaryVehicleExplosion > 0.0f )
		{
			SetTimer ( TimeTilSecondaryVehicleExplosion, FALSE, 'SecondaryVehicleExplosion' );
		}
		
		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			//PerformDeathEffects();
		}
		//SetBurnOut();
		
		if(Controller != None)
		{
			if(Controller.bIsPlayer)
			{
				DetachFromController();
			}
			else
			{
				Controller.Destroy();
			}
		}
		
		for(i = 0; i < Attached.length; i++)
		{
			if(Attached[i]!= None)
			{
				Attached[i].PawnBaseDied();
			}
		}
		
		/*
		simulated function PerformDeathEffects()
		{
			if(bHasTurretExplosion)
			{
				TurretExplosion();
			}
		
		}
		*/
	}
	
	/**
	*	Calculate camera view point, when viewing this pawn.
	*
	* @param	fDeltaTime	delta time seconds since last update
	* @param	out_CamLoc	Camera Location
	* @param	out_CamRot	Camera Rotation
	* @param	out_FOV		Field of View
	*
	* @return	true if Pawn should provide the camera point of view.
	*/
	simulated function VehicleCalcCamera(float fDeltaTime, int SeatIndex, out vector out_CamLoc, out rotator out_CamRot, out vector CamStart, optional bool bPivotOnly)
	{
		out_CamLoc = DeathCamLocation;
		out_CamRot = rotator(CamStart - Location);
		/*
 		Global.VehicleCalcCamera(fDeltaTime, SeatIndex, out_CamLoc, out_CamRot, CamStart, bPivotOnly);
		bStopDeathCamera = bStopDeathCamera || (out_CamLoc.Z < WorldInfo.KillZ);
		if ( bStopDeathCamera && (OldCameraPosition != vect(0,0,0)) )
		{
			// Don't allow camera to go below killz, by re-using old camera position once dead vehicle falls below killz
		   	out_CamLoc = OldCameraPosition;
			out_CamRot = rotator(CamStart - out_CamLoc);
		}
		OldCameraPosition = out_CamLoc;
		*/
		
		
	}
	
	/** spawn an explosion effect and damage nearby actors */
	simulated function DoVehicleExplosion(bool bDoingSecondaryExplosion)
	{
		//local UTPlayerController UTPC;
		local float Dist, ShakeScale, MinViewDist;
		local ParticleSystem Template;
		local SkelControlListHead LH;
		local SkelControlBase NextSkelControl;
		//local UTSkelControl_Damage DamSkelControl;
		local vector BoneLocation;
		local bool bIsVisible;

		if ( WorldInfo.NetMode != NM_DedicatedServer )
		{
			if ( bDoingSecondaryExplosion )
			{
				// already checked visibility
				bIsVisible = true;
			}
			else
			{
				// viewshakes and visibility check
				/*
				MinViewDist = 10000.0;
				foreach LocalPlayerControllers(class'OWPlayerController', UTPC)
				{
					Dist = VSize(Location - OWPC.ViewTarget.Location);
					if (OWPC == KillerController)
					{
						bIsVisible = true;
						Dist *= 0.25;
					}
					MinViewDist = FMin(Dist, MinViewDist);
					if (Dist < OuterExplosionShakeRadius)
					{
						bIsVisible = true;
						if (DeathExplosionShake != None)
						{
							ShakeScale = 1.0;
							if (Dist > InnerExplosionShakeRadius)
							{
								ShakeScale -= (Dist - InnerExplosionShakeRadius) / (OuterExplosionShakeRadius - InnerExplosionShakeRadius);
							}
							OWPC.PlayCameraAnim(DeathExplosionShake, ShakeScale);
						}
					}
				}
				
				bIsVisible = bIsVisible || (WorldInfo.TimeSeconds - LastRenderTime < 3.0);
				*/
			}

			// determine which explosion to use
			if ( bIsVisible )
			{
				if( !bDoingSecondaryExplosion )
				{
					if( BigExplosionTemplates.length > 0 )
					{
						Template = class'OWEmitter'.static.GetTemplateForDistance(BigExplosionTemplates, Location, WorldInfo);
					}
				}
				else
				{
					Template = SecondaryExplosion;
				}

				PlayVehicleExplosionEffect( Template, !bDoingSecondaryExplosion );
			}

			if (ExplosionSound != None)
			{
				PlaySound(ExplosionSound, true);
			}
			/*
			// this will break only pieces that are marked for OnDeath
			if( MinViewDist < 6000.0 && Mesh != none && AnimTree(Mesh.Animations) != none)
			{
				// look at the first SkelControler for each bone
				foreach AnimTree(Mesh.Animations).SkelControlLists(LH)
				{
					// then look down the list of the nodes that may exist
					NextSkelControl = LH.ControlHead;
					while (NextSkelControl != None)
					{
						DamSkelControl = UTSkelControl_Damage(NextSkelControl);
						if( DamSkelControl != none)
						{
							if( DamSkelControl.bOnDeathUseForSecondaryExplosion == bDoingSecondaryExplosion )
							{
								BoneLocation = Mesh.GetBoneLocation(LH.BoneName);
								DamSkelControl.BreakApartOnDeath(BoneLocation, bIsVisible);
							}
						}

						NextSkelControl = NextSkelControl.NextControl;
					}
				}
			}
			*/
		}
		HurtRadius(ExplosionDamage, ExplosionRadius, class'OWDmgType_VehicleExplosion', ExplosionMomentum, Location,, GetCollisionDamageInstigator());
		AddVelocity((ExplosionMomentum / Mass) * vect(0,0,1), Location, class'OWDmgType_VehicleExplosion');

		// If in air, add some anglar spin.
		if(Role == ROLE_Authority && !bVehicleOnGround)
		{
			Mesh.SetRBAngularVelocity(VRand() * ExplosionInAirAngVel, TRUE);
		}
	}

	/** This will spawn the actual explosion particle system.  It could be a fiery death or just dust when the vehicle hits the ground **/
	simulated function PlayVehicleExplosionEffect( ParticleSystem TheExplosionTemplate, bool bSpawnLight )
	{
		local UDKExplosionLight L;

		if (TheExplosionTemplate != None)
		{
			DeathExplosion = Spawn(class'OWEmitter', self);
			if (BigExplosionSocket != 'None')
			{
				DeathExplosion.SetBase(self,, Mesh, BigExplosionSocket);
			}
			DeathExplosion.SetTemplate(TheExplosionTemplate, true);
			DeathExplosion.ParticleSystemComponent.SetFloatParameter('Velocity', VSize(Velocity) / GroundSpeed);

			if (bSpawnLight && ExplosionLightClass != None && !WorldInfo.bDropDetail && ShouldSpawnExplosionLight(Location, vect(0,0,1)))
			{
				L = new(DeathExplosion) ExplosionLightClass;
				DeathExplosion.AttachComponent(L);
			}
		}
	}
	
	/** This does the secondary explosion of the vehicle (e.g. from reserve fuel tanks finally blowing / ammo blowing up )**/
	simulated function SecondaryVehicleExplosion()
	{
		// here we need to check to see if we are a vehicle which is falling down from the sky!
		// if we are then we want to push the actual burn out til after we have hit the ground (and don secondary explosion)
		if( Velocity.Z < -100.0f )
		{
			SetTimer( 1.0f, false, 'SecondaryVehicleExplosion' );
			LifeSpan += 1.0f;

			return;
		}
		// we are just going to have vehicles do a "secondary explosion" of dust and rock based on RigidBodyCollision
		//PerformSecondaryVehicleExplosion();
	}

	simulated event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData Collision, int ContactIndex )
	{
		Super.RigidBodyCollision(HitComponent, OtherComponent, Collision, ContactIndex);

		if( IsTimerActive( 'SecondaryVehicleExplosion' ) )
		{
			ClearTimer( 'SecondaryVehicleExplosion' );
			PerformSecondaryVehicleExplosion();
		}
	}	
	
	simulated function PerformSecondaryVehicleExplosion()
	{
		local OWPlayerController OWPC;
		local bool bIsVisible;

		Mesh.SetNotifyRigidBodyCollision( FALSE );

		// only actually do secondary explosion if being rendered
		if ( WorldInfo.TimeSeconds - LastRenderTime < 0.1f )
		{
			foreach LocalPlayerControllers(class'OWPlayerController', OWPC)
			{
				if ( oWPC.ViewTarget != None )
				{
					bIsVisible = (OWPC == KillerController) || (VSizeSq(OWPC.ViewTarget.Location - Location) < 25000000.0);
					break;
				}
			}
		}
		if ( bIsVisible )
		{
			DoVehicleExplosion(true);
		}
	}
	
}

simulated function CheckDamageSmoke()
{
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		VehicleEvent((float(Health) / float(HealthMax) < DamageSmokeThreshold) ? 'DamageSmoke' : 'NoDamageSmoke');
	}
}

simulated function StopVehicleSounds()
{
	local int seatIdx;
	Super.StopVehicleSounds();
	for(seatIdx=0;seatIdx < Seats.Length; ++seatIdx)
	{
		if(Seats[seatIdx].SeatMotionAudio != none)
		{
			Seats[seatIdx].SeatMotionAudio.Stop();
		}
	}
}

/** ShouldSpawnExplosionLight()
Decide whether or not to create an explosion light for this explosion
*/
simulated function bool ShouldSpawnExplosionLight(vector HitLocation, vector HitNormal)
{
	local PlayerController P;
	local float Dist;

	// decide whether to spawn explosion light
	ForEach LocalPlayerControllers(class'PlayerController', P)
	{
		Dist = VSize(P.ViewTarget.Location - Location);
		if ( (P.Pawn == Instigator) || (Dist < ExplosionLightClass.Default.Radius) || ((Dist < MaxExplosionLightDistance) && ((vector(P.Rotation) dot (Location - P.ViewTarget.Location)) > 0)) )
		{
			return true;
		}
	}
	return false;
}

simulated event FellOutOfWorld(class<DamageType> dmgType)
{
    super.FellOutOfWorld(DmgType);
    bStopDeathCamera = true;
}

/**
 * Called when the vehicle is destroyed.  Clean up the seats/effects/etc
 */
simulated function Destroyed()
{
	local OWVehiclePawn V, Prev;
	local int i;
	local PlayerController PC;
	
	`Log("Vehicle was destroyed");
	for( i=1; i<Seats.Length; i++)
	{
		if ( Seats[i].SeatPawn != None )
		{
			if( Seats[i].SeatPawn.Controller != None )
			{
				`Warn(self @ "destroying seat" @ i @ "still controlled by" @ Seats[i].SeatPawn.Controller @ Seats[i].SeatPawn.Controller.GetHumanReadableName());
			}
			Seats[i].SeatPawn.Destroy();
		}
		/*
		if(Seats[i].SeatMovementEffect != None)
		{
			SetMovementEffect(i, false);
		}
		*/
	}
	/*
	if(  ParentFactory != None )
		ParentFactory.VehicleDestroyed( self ); //Notify parent factory of death
	*/
	
	/*
	if( OWGame(WorldInfo.Game) != None )
	{
		if( OWGame(WorldInfo.Game).VehicleList == Self );
			OWGame(WorldInfo.Game).VehicleList = NextVehicle;
		else
		{
			Prev = OWGame(WorldInfo.Game).VehicleList;
			if ( Prev != None )
			{
				for ( V = OWGame(WorldInfo.Game).VehicleList.NextVehicle; !=None; V=V.NextVehicle );
				{
					if ( V == self );
					{
						Prev.NextVehicle = NextVehicle;
						break;
					}
					else
						Prev = V;
				}
			}
		}
	}
	*/
	
	//SetTexturesToBeResident ( FALSE );
	super.Destroyed();
	
	// remove the local HUD's post-rendered list
	ForEach LocalPlayerControllers(class'PlayerController', PC)
		if ( PC.MyHUD != None )
			PC.MyHUD.RemovePostRenderedActor(self);
}

defaultproperties
{
    bAlwaysRelevant=true
    bAttachDriver=false

    Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        bSynthesizeSHLight=true
        bUseBooleanEnvironmentShadowing=FALSE
    End Object
    LightEnvironment=MyLightEnvironment
    Components.Add(MyLightEnvironment)
    
    Begin Object Name=SVehicleMesh
        bCastDynamicShadow=true
        LightEnvironment=MyLightEnvironment
        bOverrideAttachmentOwnerVisibility=true
        bAcceptsDynamicDecals=FALSE
        bPerBoneMotionBlur=true
    End Object
	SVehicleMeshRef = SVehicleMesh
	
	Begin Object Class=UDKSkeletalMeshComponent Name=Cockpit
		DepthPriorityGroup=SDPG_Foreground
		Animations=None
		PhysicsAsset=None
		bAcceptsDynamicDecals=FALSE
		bSyncActorLocationToRootRigidBody=false
		CastShadow=false
		bOnlyOwnerSee=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bOverrideAttachmentOwnerVisibility=true
		TickGroup=TG_DuringASyncWork
	End Object
	CockpitMesh = Cockpit;
	Components.Add(Cockpit)

    Begin Object Name=CollisionCylinder
        BlockNonZeroExtent=false
        BlockZeroExtent=false
        BlockActors=false
        BlockRigidBody=false
        CollideActors=false
    End Object
    
	ExplosionDamage=100.0
	ExplosionRadius=300.0
	ExplosionMomentum=60000
	ExplosionInAirAngVel=1.5
	ExplosionLightClass=class'OWGame.OWRocketExplosionLight'
	MaxExplosionLightDistance=+4000.0
	TimeTilSecondaryVehicleExplosion=2.0f
	
	ExplosionTemplate=ParticleSystem'FX_VehicleExplosions.Effects.P_FX_GeneralExplosion'
	BigExplosionTemplates[0]=(Template=ParticleSystem'FX_VehicleExplosions.Effects.P_FX_VehicleDeathExplosion')
	SecondaryExplosion=ParticleSystem'Envy_Effects.VH_Deaths.P_VH_Death_Dust_Secondary'
	
    DamageSmokeThreshold=0.65
    FireDamageThreshold=0.40
    MaxImpactEffectDistance=6000.0
    MaxFireEffectDistance=7000.0
    
    DestroyOnPenetrationThreshold=50.0
    DestroyOnPenetrationDuration=1.0
	
	bEjectKilledBodies=false
	
	BaseEyeheight=30
	Eyeheight=30
	
	DefaultFOV=85
    
    InventoryManagerClass=class'OWInventoryManager'
    
    Physics=PHYS_RigidBody
    
    LinearInputFactor=1
    RotationalInputFactor=100
        
    MaxSpeed=10000
	
	LastBarrelIndex=0
	TotalBarrels=0
    
}
