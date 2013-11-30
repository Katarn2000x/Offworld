/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWEntryHUD extends HUD
	config(Game);

var OWGFxMenu MainMenuMovie;

event PostRender()
{
	return;
}

function OpenMainMenu()
{
	`Log("Opening the main menu");
	if(MainMenuMovie != None && MainMenuMovie.bMovieIsOpen )
	{
		return;
	}
	else
	{
		if( MainMenuMovie == None )
		{
			`Log("Initializing the main menu");
			MainMenuMovie = new class'OWGFxMenu';
			MainMenuMovie.bEnableGammaCorrection = false;
			MainMenuMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
			MainMenuMovie.SetTimingMode(TM_Real);		
		}
		`Log("Starting the main menu");
		MainMenuMovie.Start();	
	}
}

defaultproperties
{
}