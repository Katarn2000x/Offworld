/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */

class OWGFxHudWrapper extends GFxMoviePlayer;

//A reference to the playercontroller that is being shown this movie
var PlayerController PCReference;

function ShowMovie(PlayerController Caller)
{
	PCReference = Caller;
	InitializeMoviePlayer();
	Start();
	Advance(0);
	`Log("Did we try to start?");
}

//Called from elsewhere in script to initalize the movie

event InitializeMoviePlayer()
{
	// Sets up our delegate to be called from ActionScript
	SetupASDelegate(SpawnPlayer);
}

// ,,,

delegate SpawnMeDelegate();


simulated function SpawnPlayer()
{
	//Code goes here
}

function SetupASDelegate(delegate<SpawnMeDelegate> d)
{
	local GFxObject RootObj;
	
	RootObj = GetVariableObject("_root");
	ActionScriptSetFunction(RootObj, "SpawnMe");
}

defaultproperties
{
	bDisplayWithHudOff=true
	MovieInfo=SwfMovie'OWFrontEnd.offworldspawnmenu'
	bPauseGameWhileActive=true
	bCaptureInput=true
	
	
}