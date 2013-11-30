/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWGhostDriver extends GamePawn;
	//dependson(OWPlayerController);
	
	/**
 * Pawn starts firing!
 * Called from PlayerController::StartFiring
 * Network: Local Player
 *
 * @param	FireModeNum		fire mode number
 */
simulated function StartFire(byte FireModeNum)
{
	`Log("Attempted to start fire from ghost pawn");
	super.StartFire( FireModeNum );

}

defaultproperties
{
}
