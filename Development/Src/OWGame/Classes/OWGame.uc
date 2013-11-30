/**
 * Base game class for all games in Offworld.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class OWGame extends SimpleGame;
	
// Variable which references the default vehicle archetype stored within a package
var class<UDKVehicle> DefaultVehicleClass;

/**
 * Called when the controller wants to be given a pawn. Here we give the player a vehicle to drive as well.
 *
 * @param		NewPlayer		Controller requesting a new a pawn
 * @network						Server
 */
 
static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	local string NewMapName,GameTypeName,ThisMapPrefix,GameOption;
	local int PrefixIndex, MapPrefixPos,GameTypePrefixPos;
	local class<GameInfo> OWGameType;

	if(Left(MapName, 13) ~= "OWFrontEndMap" )
	{
		`Log("Game set to OWEntryGame");
		return class'OWEntryGame';
		
		/*OWGameType = class<GameInfo>(DynamicLoadObject("OWGame.OWGame",class'Class'));
		
		if( OWGameType != None )
		{
			return OWGameType.static.SetGameType( MapName, Options, Portal );
		}
		*/
	}
	
	return Default.class;
}
 
 
function RestartPlayer(Controller NewPlayer)
{
	local NavigationPoint StartSpot;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local UDKVehicle Vehicle;

	// If the level is restarting, not a dedicated server and not a listen server then abort
	if (bRestartLevel && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.NetMode != NM_ListenServer)
	{
		return;
	}

	// Find an appropriate starting point within the world for the player
	StartSpot = FindPlayerStart(NewPlayer, 255);

	// If the start spot cannot be found using FindPlayerStart, then try to use the previous stored start spot
	if (StartSpot == None)
	{
		// If the player had a start spot previously, attempt to use that
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
		}
		else
		{
			// No start spot found at all, abort
			return;
		}
	}

	// Spawn a pawn for the player to possess
	if (NewPlayer.Pawn == None)
	{
		NewPlayer.Pawn = Spawn(class'OWGhostDriver',,, StartSpot.Location, StartSpot.Rotation);
	}

	// Check if the pawn could not be spawned. If it couldn't then send the controller to the dead state
	if (NewPlayer.Pawn == None)
	{
		// Server side version of the controller
		NewPlayer.GotoState('Dead');

		// If the controller is a player controller, then tell the client version of the player controller to go to the dead state
		if (PlayerController(NewPlayer) != None)
		{
			PlayerController(NewPlayer).ClientGotoState('Dead', 'Begin');
		}
	}
	else
	{
		// The pawn was spawned, initialize the pawn
		NewPlayer.Pawn.SetAnchor(StartSpot);

		if (PlayerController(NewPlayer) != None)
		{
			PlayerController(NewPlayer).TimeMargin = -0.1f;
			StartSpot.AnchoredPawn = None;
		}

		// Set the last start spot
		NewPlayer.Pawn.LastStartSpot = PlayerStart(StartSpot);
		// Set the last start time
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		// Tell the controller to take control over the new pawn
		NewPlayer.Possess(NewPlayer.Pawn, false);
		// Set the rotation of the client side controller to the spawned pawn
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, true);

		// Set the pawn defaults
		SetPlayerDefaults(NewPlayer.Pawn);

		// Activate any PlayerSpawned Kismet sequences within the level
		
		/*
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned', true, Events);

			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None && SpawnedEvent.CheckActivate(NewPlayer, NewPlayer))
				{
					SpawnedEvent.SpawnPoint = StartSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
		*/
		if (OWPlayerController(NewPlayer) != None)
		{
			if(OWPlayerController(NewPlayer).myHUD == none)
			{
				OWPlayerController(NewPlayer).ClientSetHud(class'OWHUD');
			}
			
			//Show the spawn menu to the player
			`Log("Attemping to open spawn menu from owgame");
			OWHUD(OWPlayerController(NewPlayer).myHUD).OpenSpawnMenu();
		}
		
		
		
		// If we have a valid vehicle archetype...
		/*
		if (DefaultVehicleClass != None)
		{
			// Remove the collision from the pawn so that we don't encroach the pawn when spawning the vehicle
			NewPlayer.Pawn.SetCollision(false, false, false);
			// Spawn the vehicle
			Vehicle = SpawnDefaultVehicleFor(NewPlayer, StartSpot);
			if (Vehicle != None)
			{
				// If we have successfully spawned the vehicle, get the pawn to drive the vehicle
				Vehicle.DriverEnter(NewPlayer.Pawn);
			}
		}
		*/
	}
}

function ProcessSpawnRequest(Controller RequestPlayer)
{
	local UDKVehicle Vehicle;
	
	// If we have a valid vehicle archetype...
	if (DefaultVehicleClass != None)
	{
		// Remove the collision from the pawn so that we don't encroach the pawn when spawning the vehicle
		RequestPlayer.Pawn.SetCollision(false, false, false);
		// Spawn the vehicle
		Vehicle = SpawnDefaultVehicleFor(RequestPlayer, RequestPlayer.StartSpot);
		if (Vehicle != None)
		{
			// If we have successfully spawned the vehicle, get the pawn to drive the vehicle
			Vehicle.DriverEnter(RequestPlayer.Pawn);
		}
	}
}

/**
 * Spawns the default pawn for a controller at a given start spot
 *
 * @param	NewPlayer	Controller to spawn the pawn for
 * @param	StartSpot	Where to spawn the pawn
 * @return	Pawn		Returns the pawn that was spawned
 * @network				Server
 */
function UDKVehicle SpawnDefaultVehicleFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local Rotator StartRotation;
	local UDKVehicle SpawnedVehicle;

	// Quick exit if NewPlayer is none or if StartSpot is none
	if (NewPlayer == None || StartSpot == None)
	{
		return None;
	}

	// Only the start spot's yaw from its rotation is required
	StartRotation = Rot(0, 0, 0);
	StartRotation.Yaw = StartSpot.Rotation.Yaw;

	// Spawn the default pawn archetype at the start spot's location and the start rotation defined above
	// Set SpawnedVehicle to the spawned vehicle
	SpawnedVehicle = Spawn(DefaultVehicleClass,,, StartSpot.Location, StartRotation);

	// Return the value of SpawnedVehicle
	return SpawnedVehicle;
}
	
defaultproperties
{	
	DefaultVehicleClass=class'OWVPawn_Flitter_Content'
	HUDType=class'OWGame.OWHUD'
	PlayerControllerClass=class'OWGame.OWPlayerController'
	bDelayedStart=false
	bRestartLevel=false
	
	//DefaultPawnClass=class'OWVPawn_Flitter_Content'
	//PlayerReplicationInfoClass=class'OWGame.OWPlayerReplicationInfo'
	//GameReplicationInfoClass=class'OWGame.OWGameReplicationInfo'
	//PopulationManagerClass=class'OWGame.OWPopulationManager'
	
}

