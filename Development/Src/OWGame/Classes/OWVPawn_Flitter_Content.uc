class OWVPawn_Flitter_Content extends OWVPawn_Flitter;

DefaultProperties
{
	Begin Object Name=CollisionCylinder
		CollisionHeight=+35.0 // original 70
		CollisionRadius=+140.0 // original 240
		Translation=(X=-40.0,Y=0.0,Z=40.0)
	End Object

	Begin Object Name=SVehicleMesh
		SkeletalMesh=SkeletalMesh'OW_flitter.Flitter'
		AnimTreeTemplate=AnimTree'OW_flitter.AT_flitter'
		PhysicsAsset=PhysicsAsset'OW_flitter.flitter_Physics'
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		bCastDynamicShadow=true
		//AnimSets.Add(AnimSet'VH_Cicada.Anims.VH_Cicada_Anims')
		bOverrideAttachmentOwnerVisibility=true
	End Object
	
	Begin Object Name=Cockpit
		//AbsoluteTranslation=false
		//AbsoluteRotation=true
		//AbsoluteScale=true
		FOV=75
		SkeletalMesh=SkeletalMesh'OW_flitter.flittercockpit'
	End Object
	Components.Add(Cockpit)
	
	DrawScale=1 // original 1.3

	Health=500

	Seats.Empty

	Seats(0)={(	GunClass=class'OWVWeap_FlitterMissileLauncher',
				GunSocket=(Gun_Socket_01,Gun_Socket_02),
				CameraTag=Camera,
				TurretControls=(LauncherA,LauncherB),
				CameraOffset=0, 
				CameraBaseOffset=(Z=0.0),
				SeatIconPos=(X=0.48,Y=0.25),
				WeaponEffects=((SocketName=Gun_Socket_01,Offset=(X=-80),Scale3D=(X=12.0,Y=15.0,Z=15.0)),(SocketName=Gun_Socket_02,Offset=(X=-80),Scale3D=(X=12.0,Y=15.0,Z=15.0))))
				MuzzleFlashLightClass=class'OWRocketMuzzleFlashLight',
				}

	VehicleEffects.Empty
	
	VehicleEffects(0)=(EffectStartTag=FlitterWeapon01,EffectTemplate=ParticleSystem'VH_Manta.Effects.PS_Manta_Gun_MuzzleFlash',EffectSocket=Gun_Socket_01)
	VehicleEffects(1)=(EffectStartTag=FlitterWeapon02,EffectTemplate=ParticleSystem'VH_Manta.Effects.PS_Manta_Gun_MuzzleFlash',EffectSocket=Gun_Socket_02)
		
	// Engine sound.
	Begin Object Class=AudioComponent Name=FlitterEngineSound
		SoundCue=SoundCue'Flitter.Soundcues.Vehicle_Flitter_EngineLoop'
	End Object
	EngineSound=FlitterEngineSound
	Components.Add(FlitterEngineSound);
	
	CollisionSound=SoundCue'A_Vehicle_Cicada.SoundCues.A_Vehicle_Cicada_Collide'
	
	// Scrape sound.
	Begin Object Class=AudioComponent Name=BaseScrapeSound
		SoundCue=SoundCue'A_Gameplay.A_Gameplay_Onslaught_MetalScrape01Cue'
	End Object
	ScrapeSound=BaseScrapeSound
	Components.Add(BaseScrapeSound);
	
		// Initialize sound parameters.
	EngineStartOffsetSecs=0.5
	EngineStopOffsetSecs=1.0
	


}
