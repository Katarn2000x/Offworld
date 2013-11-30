/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
 
 //Modeled after GFxUI_PauseMenu

class OWGFxFrontEnd extends GFxMoviePlayer;

var GFxObject RootMC, SpawnMC, Btn_Spawn_Wrapper; //PauseMC, OverlayMC, Btn_Resume_Wrapper, Btn_Exit_Wrapper, 
var GFxClikWidget Btn_SpawnMC; //Btn_ResumeMC, Btn_ExitMC, 

function bool Start ( optional bool StartPaused = false )
{
	`Log("Did we try to start?");
	super.Start();
	Advance(0);
	
	RootMC = GetVariableObject("_root");
	SpawnMC = RootMC.GetObject("spawnmenu");
	
	
	Btn_SpawnMC = GFXClikWidget(SpawnMC.GetObject("spawn", class'GFxClikWidget'));

	`Log("Attempting to cast to GFxClikWidget");
	//Btn_SpawnMC = GFxClikWidget(Btn_Spawn_Wrapper.GetObject("btn", class'GFxClikWidget'));
	`Log("Btn_SpawnMC: " $Btn_SpawnMC);
	`Log("Attemping to add event listener");
	Btn_SpawnMC.AddEventListener('CLIK_press', OnPressSpawnButton);
	AddCaptureKey('Enter');
	
	return true;
}

function OnPressSpawnButton(GFxClikWidget.EventData ev)
{
	`Log("Spawn button pressed");
	PlayCloseAnimation();
	`Log("Close animation played");
	
}

function OnPressOptionsButton(GFxClikWidget.EventData ev);
function OnPressHostMultiplayerGameButton(GFxClikWidget.EventData ev);
function OnPressJoinMultiplayerGameButton(GFxClikWidget.EventData ev);
function OnPressQuitButton(GFxClikWidget.EventData ev);


function PlayOpenAnimation()
{
	`Log("Open animation begin play");
	SpawnMC.GotoAndPlay("open");
	`Log("Open animation end play");
}

function PlayCloseAnimation()
{
	SpawnMC.GotoAndPlay("close");
}

function OnCloseAnimationComplete()
{
	`Log("On close animation called from actionscript");
	//OWHUD(GetPC().MyHud).CompleteSpawnMenuClose(self);
}

defaultproperties
{
	bDisplayWithHudOff=true
	bPauseGameWhileActive=false
	bCaptureInput=true	
}