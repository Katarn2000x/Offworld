/**
 * This is our base projectile class.
 *
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */

class OWProjectile extends UDKProjectile
	abstract;

/** Additional Sounds */
var bool bSuppressSounds;
var SoundCue	AmbientSound;		// The sound that is played looped.
var SoundCue	ExplosionSound;		// The sound that is played when it explodes

/** If true, never cut out ambient sound for perf reasons */
var	bool		bImportantAmbientSound;

/** Effects */

/** This is the effect that is played while in flight */
var ParticleSystemComponent	ProjEffects;

/** Effects Template */
var ParticleSystem ProjFlightTemplate;
var ParticleSystem ProjExplosionTemplate;

/** If true, this explosion effect expects to be orientated differently and have extra data
    passed in via parameters */
var bool bAdvanceExplosionEffect;

/** decal for explosion */
var MaterialInterface ExplosionDecal;
var float DecalWidth, DecalHeight;

/** How long the decal should last before fading out **/
var float DurationOfDecal;

/** MaterialInstance param name for dissolving the decal **/
var name DecalDissolveParamName;

/** This value sets the cap how far away the explosion effect of this projectile can be seen */
var float MaxEffectDistance;

/** used to prevent effects when projectiles are destroyed (see LimitationVolume) */
var bool bSuppressExplosionFX;

/** if True, this projectile will remain alive (but hidden) until the flight effect is done */
var bool bWaitForEffects;

var float TossZ;

/** FIXME TEMP for tweaking global checkradius */
var float GlobalCheckRadiusTweak;

/** If true, attach explosion effect to vehicles */
var bool bAttachExplosionToVehicles;

/** Class of ProjectileLight */
var class<PointLightComponent> ProjectileLightClass;

/** LightComponent for this projectile (spawned only if projectile fired by the local player) */
var PointLightComponent ProjectileLight;

/** Class of ExplosionLight */
var class<UDKExplosionLight> ExplosionLightClass;

/** Max distance to create ExplosionLight */
var float MaxExplosionLightDistance;

/** CreateProjectileLight() called from TickSpecial() once if Instigator is local player
*/
simulated event CreateProjectileLight()
{
	if ( WorldInfo.bDropDetail )
		return;

	ProjectileLight = new(self) ProjectileLightClass;
	AttachComponent(ProjectileLight);
}

/**
 * Explode when the projectile comes to rest on the floor.  It's called from the native physics processing functions.  By default,
 * when we hit the floor, we just explode.
 */
simulated event Landed( vector HitNormal, actor FloorActor )
{
	HitWall(HitNormal, FloorActor, None);
}

simulated function bool CanSplash()
{
	return false;
}


/**
 * When this actor begins its life, play any ambient sounds attached to it
 */
simulated function PostBeginPlay()
{
	local AudioComponent AmbientComponent;

	if (Role == ROLE_Authority)
	{
		// If on console, init wide check
		if ( !bWideCheck )
		{
			CheckRadius *= GlobalCheckRadiusTweak;
		}
		bWideCheck = bWideCheck || ((CheckRadius > 0) && (Instigator != None) && (OWPlayerController(Instigator.Controller) != None) && OWPlayerController(Instigator.Controller).AimingHelp(false));
	}

	Super.PostBeginPlay();

	if ( bDeleteMe || bShuttingDown)
		return;

	// Set its Ambient Sound
	if (AmbientSound != None && WorldInfo.NetMode != NM_DedicatedServer && !bSuppressSounds)
	{
		if ( bImportantAmbientSound || (!WorldInfo.bDropDetail && (WorldInfo.GetDetailMode() != DM_Low)) )
		{
			AmbientComponent = CreateAudioComponent(AmbientSound, true, true);
			if ( AmbientComponent != None )
			{
				AmbientComponent.bShouldRemainActiveIfDropped = true;
			}
		}
	}

	// Spawn any effects needed for flight
	SpawnFlightEffects();

	// shorter lifespan on mobile devices
	if (WorldInfo.IsConsoleBuild(CONSOLE_Mobile) )
	{
		LifeSpan = FMin(LifeSpan, 0.5*default.LifeSpan);
	}
}

simulated event SetInitialState()
{
	bScriptInitialized = true;
	if (Role < ROLE_Authority && AccelRate != 0.f)
	{
		GotoState('WaitingForVelocity');
	}
	else
	{
		GotoState((InitialState != 'None') ? InitialState : 'Auto');
	}
}

/**
 * Initialize the Projectile
 */
function Init(vector Direction)
{
	local vector StartingVector;
	local float StartingSpeed;
	
	// Get the velocity of the pawn who launched the projectile
	if(Instigator != None)
	{
		StartingVector.X = Instigator.Velocity.X;
		StartingVector.Y = Instigator.Velocity.Y;
		StartingVector.Z = Instigator.Velocity.Z;
		StartingSpeed = VSize(StartingVector);
	}
	
	// Set the rotation of the projectile to face the direction of the launcher
	SetRotation(rotator(Direction));
	
	//If the speed of the pawn who launched the projectile exceeds the initial speed of the projectile, tone that shit down
	//Then add the velocity of the pawn who launched to the projectile
	if( StartingSpeed > Speed)
	{
		Velocity = (Speed * Direction) + Normal(StartingVector) * (Speed-0.1);
	}
	else Velocity = (Speed * Direction) + StartingVector;
	
	//Add gravity
	Velocity.Z += TossZ;
	
	//Accelerate the projectile in the direction of launch
	Acceleration = AccelRate * Normal(Direction);
	
	/*
	SetRotation(rotator(Direction));
	
	Velocity = Speed * Direction;
	Velocity.Z += TossZ;
	Acceleration = AccelRate * Normal(Velocity);
	*/
}

/**
 *
 */
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (DamageRadius > 0.0)
	{
		Explode( HitLocation, HitNormal );
	}
	else
	{
		Other.TakeDamage(Damage,InstigatorController,HitLocation,MomentumTransfer * Normal(Velocity), MyDamageType,, self);
		Shutdown();
	}
}


/**
 * Explode this Projectile
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (Damage>0 && DamageRadius>0)
	{
		if ( Role == ROLE_Authority )
			MakeNoise(1.0);
		if ( !bShuttingDown )
		{
			ProjectileHurtRadius(HitLocation, HitNormal );
		}
	}
	SpawnExplosionEffects(HitLocation, HitNormal);

	ShutDown();
}


/**
 * Spawns any effects needed for the flight of this projectile
 */
simulated function SpawnFlightEffects()
{
	if (WorldInfo.NetMode != NM_DedicatedServer && ProjFlightTemplate != None)
	{
		ProjEffects = WorldInfo.MyEmitterPool.SpawnEmitterCustomLifetime(ProjFlightTemplate);
		ProjEffects.SetAbsolute(false, false, false);
		ProjEffects.SetLODLevel(WorldInfo.bDropDetail ? 1 : 0);
		ProjEffects.OnSystemFinished = MyOnParticleSystemFinished;
		ProjEffects.bUpdateComponentInTick = true;
		AttachComponent(ProjEffects);
	}
}

/** sets any additional particle parameters on the explosion effect required by subclasses */
simulated function SetExplosionEffectParameters(ParticleSystemComponent ProjExplosion);

/**
 * Spawn Explosion Effects
 */
simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local vector LightLoc, LightHitLocation, LightHitNormal;
	local vector Direction;
	local ParticleSystemComponent ProjExplosion;
	local Actor EffectAttachActor;
	local MaterialInstanceTimeVarying MITV_Decal;

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		if (ProjectileLight != None)
		{
			DetachComponent(ProjectileLight);
			ProjectileLight = None;
		}
		if (ProjExplosionTemplate != None && EffectIsRelevant(Location, false, MaxEffectDistance))
		{
			EffectAttachActor = (bAttachExplosionToVehicles /*|| OWVehiclePawn(ImpactedActor) == None)*/) ? ImpactedActor : None;
			if (!bAdvanceExplosionEffect)
			{
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(HitNormal), EffectAttachActor);
			}
			else
			{
				Direction = normal(Velocity - 2.0 * HitNormal * (Velocity dot HitNormal)) * Vect(1,1,0);
				ProjExplosion = WorldInfo.MyEmitterPool.SpawnEmitter(ProjExplosionTemplate, HitLocation, rotator(Direction), EffectAttachActor);
				ProjExplosion.SetVectorParameter('Velocity',Direction);
				ProjExplosion.SetVectorParameter('HitNormal',HitNormal);
			}
			SetExplosionEffectParameters(ProjExplosion);

			if ( !WorldInfo.bDropDetail && ((ExplosionLightClass != None) || (ExplosionDecal != none)) && ShouldSpawnExplosionLight(HitLocation, HitNormal) )
			{
				if ( ExplosionLightClass != None )
				{
					if (Trace(LightHitLocation, LightHitNormal, HitLocation + (0.25 * ExplosionLightClass.default.TimeShift[0].Radius * HitNormal), HitLocation, false) == None)
					{
						LightLoc = HitLocation + (0.25 * ExplosionLightClass.default.TimeShift[0].Radius * (vect(1,0,0) >> ProjExplosion.Rotation));
					}
					else
					{
						LightLoc = HitLocation + (0.5 * VSize(HitLocation - LightHitLocation) * (vect(1,0,0) >> ProjExplosion.Rotation));
					}

					UDKEmitterPool(WorldInfo.MyEmitterPool).SpawnExplosionLight(ExplosionLightClass, LightLoc, EffectAttachActor);
				}

				// this code is mostly duplicated in:  UTGib, UTProjectile, UTVehicle, UTWeaponAttachment be aware when updating
				if (ExplosionDecal != None && Pawn(ImpactedActor) == None )
				{
					if( MaterialInstanceTimeVarying(ExplosionDecal) != none )
					{
						// hack, since they don't show up on terrain anyway
						if ( Terrain(ImpactedActor) == None )
						{
						MITV_Decal = new(self) class'MaterialInstanceTimeVarying';
						MITV_Decal.SetParent( ExplosionDecal );

						WorldInfo.MyDecalManager.SpawnDecal(MITV_Decal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 10.0, FALSE );
						//here we need to see if we are an MITV and then set the burn out times to occur
						MITV_Decal.SetScalarStartTime( DecalDissolveParamName, DurationOfDecal );
					}
					}
					else
					{
						WorldInfo.MyDecalManager.SpawnDecal( ExplosionDecal, HitLocation, rotator(-HitNormal), DecalWidth, DecalHeight, 10.0, true );
					}
				}
			}
		}

		if (ExplosionSound != None && !bSuppressSounds)
		{
			PlaySound(ExplosionSound, true);
		}

		bSuppressExplosionFX = true; // so we don't get called again
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

/**
 * Clean up
 */
simulated function Shutdown()
{
	local vector HitLocation, HitNormal;

	bShuttingDown=true;
	HitNormal = normal(Velocity * -1);
	Trace(HitLocation,HitNormal,(Location + (HitNormal*-32)), Location + (HitNormal*32),true,vect(0,0,0));

	SetPhysics(PHYS_None);

	if (ProjEffects!=None)
	{
		ProjEffects.DeactivateSystem();
	}

	if (WorldInfo.NetMode != NM_DedicatedServer && !bSuppressExplosionFX)
	{
		SpawnExplosionEffects(Location, HitNormal);
	}

	HideProjectile();
	SetCollision(false,false);

	// If we have to wait for effects, tweak the death conditions

	if (bWaitForEffects)
	{
		if (bNetTemporary)
		{
			if ( WorldInfo.NetMode == NM_DedicatedServer )
			{
				// We are on a dedicated server and not replicating anything nor do we have effects so destroy right away
				Destroy();
			}
			else
			{
				// We can't die right away but make sure we don't replicate to anyone
				RemoteRole = ROLE_None;
				// make sure we leave enough lifetime for the effect to play
				LifeSpan = FMax(LifeSpan, 2.0);
			}
		}
		else
		{
			bTearOff = true;
			if (WorldInfo.NetMode == NM_DedicatedServer)
			{
				LifeSpan = 0.15;
			}
			else
			{
				// make sure we leave enough lifetime for the effect to play
				LifeSpan = FMax(LifeSpan, 2.0);
			}
		}
	}
	else
	{
		Destroy();
	}
}

// If this actor

event TornOff()
{
	ShutDown();
	Super.TornOff();
}

/**
 * Hide any meshes/etc.
 */
simulated function HideProjectile()
{
	local MeshComponent ComponentIt;
	foreach ComponentList(class'MeshComponent',ComponentIt)
	{
		ComponentIt.SetHidden(true);
	}
}

simulated function Destroyed()
{
	// Final Failsafe check for explosion effect
	if (WorldInfo.NetMode != NM_DedicatedServer && !bSuppressExplosionFX)
	{
		SpawnExplosionEffects(Location, vector(Rotation) * -1);
	}

	if (ProjEffects != None)
	{
		DetachComponent(ProjEffects);
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(ProjEffects);
		ProjEffects = None;
	}

	super.Destroyed();
}

simulated function MyOnParticleSystemFinished(ParticleSystemComponent PSC)
{
	if (PSC == ProjEffects)
	{
		if (bWaitForEffects)
		{
			if (bShuttingDown)
			{
				// it is not safe to destroy the actor here because other threads are doing stuff, so do it next tick
				LifeSpan = 0.01;
			}
			else
			{
				bWaitForEffects = false;
			}
		}
		// clear component and return to pool
		DetachComponent(ProjEffects);
		WorldInfo.MyEmitterPool.OnParticleSystemFinished(ProjEffects);
		ProjEffects = None;
	}
}


defaultproperties
{
	DamageRadius=+0.0
	TossZ=0.0
	bWaitForEffects=false
	MaxEffectDistance=+10000.0
	MaxExplosionLightDistance=+4000.0
	CheckRadius=0.0
	bBlockedByInstigator=false
	TerminalVelocity=3500.0
	bCollideComplex=true
	bSwitchToZeroCollision=true
	CustomGravityScaling=1.0
	bAttachExplosionToVehicles=true

	bShuttingDown=false

	DurationOfDecal=24.0
	DecalDissolveParamName="DissolveAmount"

	GlobalCheckRadiusTweak=0.5
}

