/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */

class OWGFxMoviePlayer extends GFxMoviePlayer;

//A reference to the playercontroller that is being shown this movie
var PlayerController PCReference;

function ShowMovie(PlayerController Caller)
{
	PCReference = Caller;
	InitializeMoviePlayer();
}


//Called from elsewhere in script to initalize the movie
event InitializeMoviePlayer()
{
	// Sets up our delegate to be called from ActionScript
	SetupASDelegate(SpawnPlayer);
	Start();
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