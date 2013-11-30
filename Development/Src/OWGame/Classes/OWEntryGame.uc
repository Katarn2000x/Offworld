/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWEntryGame extends OWGame;


var bool PlayerSpawned;

function bool NeedPlayers()
{
	return false;
}

exec function AddBots(int num) {}

function StartMatch()
{}

auto State PendingMatch
{
	function RestartPlayer(Controller aPlayer)
	{
		`Log("Tried to restart that player");
		OWEntryHUD(OWEntryPlayerController(aPlayer).myHUD).OpenMainMenu();
		ClearTimer('Timer');
	}

	function Timer()
    {
		local PlayerController PC;
		`Log("In the timer function");
		
		foreach WorldInfo.AllControllers(class'PlayerController',PC)
		{
			if(PC.IsLocalPlayerController())
			{
				RestartPlayer(PC);
			}
		}		
    }

    function BeginState(Name PreviousStateName)
    {
		SetTimer(0.01, true, 'Timer');
		
			
		bWaitingToStartMatch = true;
		//OWGameReplicationInfo(GameReplicationInfo).bWarmupRound = false;
		//bQuickStart = false;
    }

	function EndState(Name NextStateName)
	{
		//OWGameReplicationInfo(GameReplicationInfo).bWarmupRound = false;
	}
}


defaultproperties
{
	HUDType=class'OWGame.OWEntryHUD'
	PlayerControllerClass=class'OWGame.OWEntryPlayerController'
	//ConsolePlayerControllerClass=class'UTGame.UTEntryPlayerController'

	//bUseClassicHUD=true
	//bExportMenuData=false
}
