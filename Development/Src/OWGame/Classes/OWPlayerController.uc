/**
 * Stores Offworld specific information about each player in the match.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */

class OWPlayerController extends UDKPlayerController
	dependson(OWGhostDriver)
	dependson(OWPlayerReplicationInfo)
	dependson(OWVehiclePawn)
	dependson(OWGFxSpawnMenu)
	config(Game);

var bool bCleanupComplete;
var bool bCleanupInProgress;
var bool bQuittingToMainMenu;

/** The disconnect command stored from 'NotifyDisconnect', which is to be called when cleanup is done */
var string DisconnectCommand;
	
// Start the spawn menu
function StartSpawnMenu()
{
	OWHUD(myHud).OpenSpawnMenu();
}

function RequestSpawn()
{
	`Log("Processing the spawn request");
	OWGame(WorldInfo.Game).ProcessSpawnRequest(self);
}

// The player wants to fire.
exec function StartFire( optional byte FireModeNum )
{
	`Log("Attempting start fire");
	super.StartFire( FireModeNum );
}


// unreliable server function ServerDriveOW(int data1, int data2, int data3)
// {
	// local vector Force, Torque;
	// Force.X = 	(data1 >> 16);
	// Force.Y = 	(data1 & 65535);
	// Force.Z = 	(data2 >> 16);
	// Torque.X = 	(data2 & 65535);
	// Torque.Y = 	(data3 >> 16);
	// Torque.Z = 	(data3 & 65535);
	
unreliable server function ServerDriveOW(vector Force, vector Torque)
{
	ProcessDriveOW(Force, Torque);
}

function ProcessDriveOW(vector Force, vector Torque)
{
	ClientGoToState(GetStateName(), 'Begin');
}

function PlayerMove( float DeltaTime );

	
// function OnPossess(SeqAct_Possess inAction)
// {
	// Super(Controller).OnPossess(inAction);
// }

state PlayerDriving
{
ignores SeePlayer, HearNoise, Bump;

	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot);
	
	function ProcessDriveOW(vector Force, vector Torque)
	{
		local OWVehiclePawn CurrentVehicle;

		CurrentVehicle = OWVehiclePawn(Pawn);
		
		if (CurrentVehicle != None)
		{
			CurrentVehicle.SetInputsOW(Force, Torque);
		}
	}
	
	// Set the throttle, steering etc. for the vehicle based on the input provided

	function PlayerMove( float DeltaTime )
	{
		local vector Force;
		local vector Torque;
		
		Force.X = PlayerInput.aForward;
		Force.Y = PlayerInput.aStrafe;
		Force.Z = PlayerInput.aUp;
		Torque.X = PlayerInput.aBaseZ;
		Torque.Y = -PlayerInput.aLookUp;
		Torque.Z = PlayerInput.aTurn;
		
		// update 'looking' rotation
		// UpdateRotation(DeltaTime);

		// TODO: Don't send things like aForward and aStrafe for gunners who don't need it
		// Only servers can actually do the driving logic.
		ProcessDriveOW(Force, Torque);
		if (Role < ROLE_Authority)
		{
			ServerDriveOW(
				// ((Force.X  & 65535) << 16) + (Force.Y  & 65535),
				// ((Force.Z  & 65535) << 16) + (Torque.X & 65535),
				// ((Torque.Y & 65535) << 16) + (Torque.Z & 65535)
				Force, Torque
				);
		}

		bPressedJump = false;
	}
		
	event BeginState(Name PreviousStateName)
	{
		CleanOutSavedMoves();
		`Log("player controller entered the driving state");
		`Log("Our pawn is: " $Pawn);
	}

	
	event EndState(Name NextStateName)
	{
		CleanOutSavedMoves();
		`Log("player controller left the driving state");
	}
}

/* epic ===============================================
* ::PawnDied
*
* Called to unpossess our pawn because it has died
* (other unpossession handled by UnPossess())
*
* =====================================================
*/

function PawnDied(Pawn inPawn)
{
	`Log("PlayerController recognizes pawn died");
	Super.PawnDied(inPawn);
	`Log("Player's pawn is now: " $Pawn);
}

/**
 * Triggered when the 'disconnect' console command is called, to allow cleanup before disconnecting (e.g. for the online subsystem)
 * NOTE: If you block disconnect, store the 'Command' parameter, and trigger ConsoleCommand(Command) when done; be careful to avoid recursion
 *
 * @param Command	The command which triggered disconnection, e.g. "disconnect" or "disconnect local" (can parse additional parameters here)
 * @return		Return True to block the disconnect command from going through, if cleanup can't be completed immediately
 */
event bool NotifyDisconnect(string Command)
{
	// "disconnect force" forces a disconnect, without cleanup
	if (Right(Command, 6) ~= " force" || InStr(Command, " force ", true, true) != INDEX_None)
		return false;


	// Call QuitToMainMenu to start the cleanup process
	if (!bCleanupInProgress)
	{
		DisconnectCommand = Command;
		QuitToMainMenu();
	}

	// Only block the disconnect command, if a cleanup is in progress, and it has not yet completed
	return bCleanupInProgress && !bCleanupComplete;
}

/** Called when returning to the main menu. */
function QuitToMainMenu()
{
	bCleanupInProgress = true;
	bQuittingToMainMenu = true;
	if( CleanUpOnlineSubSystemSession(true) == false )
	{
		`Log("OWPlayerController::QuitToMainMenu() - OnlineCleanup failed, finishing quit");
		FinishQuitToMainMenu();	
	}
}

/** Called after onlinesubsystem game cleanup has completed. */
function FinishQuitToMainMenu()
{
	// stop any movies currently playing before we quit out
	class'Engine'.static.StopMovie(true);

	bCleanupComplete = true;

	// Call disconnect to force us back to the menu level
	if (DisconnectCommand != "")
	{
		ConsoleCommand(DisconnectCommand);
		DisconnectCommand = "";
	}
	else
	{
		ConsoleCommand("Disconnect");
	}

	`Log("------ QUIT TO MAIN MENU --------");
}

/** Cleans up online subsystem game sessions and posts stats if the match is arbitrated. */
function bool CleanupOnlineSubsystemSession(bool bWasFromMenu)
{
	//local int Item;

	if (WorldInfo.NetMode != NM_Standalone &&
		OnlineSub != None &&
		OnlineSub.GameInterface != None &&
		OnlineSub.GameInterface.GetGameSettings('Game') != None)
	{
		// Set the end delegate so we can know when that is complete and call destroy
		OnlineSub.GameInterface.AddEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);
		OnlineSub.GameInterface.EndOnlineGame('Game');

		return true;
	}

	return false;
}

/**
 * Called when the online game has finished ending.
 */
function OnEndOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	OnlineSub.GameInterface.ClearEndOnlineGameCompleteDelegate(OnEndOnlineGameComplete);

	if(bQuittingToMainMenu)
	{
		// Set the destroy delegate so we can know when that is complete
		OnlineSub.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete);

		// Now we can destroy the game
		if ( !OnlineSub.GameInterface.DestroyOnlineGame('Game') )
		{
			OnDestroyOnlineGameComplete('Game',true);
		}
	}
}

/**
 * Called when the destroy online game has completed. At this point it is safe
 * to travel back to the menus
 *
 * @param SessionName the name of the session the event is for
 * @param bWasSuccessful whether it worked ok or not
 */
function OnDestroyOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete);
	FinishQuitToMainMenu();
}


/** Sets online delegates to respond to for this PC. */
function AddOnlineDelegates(bool bRegisterVoice)
{
	// this is done automatically in net games so only need to call it for standalone.
	if (bRegisterVoice && WorldInfo.NetMode == NM_Standalone && VoiceInterface != None)
	{
		VoiceInterface.RegisterLocalTalker(LocalPlayer(Player).ControllerId);
		//VoiceInterface.AddRecognitionCompleteDelegate(LocalPlayer(Player).ControllerId, SpeechRecognitionComplete);
	}

	// Register a callback for when the profile finishes reading.
	if (OnlineSub != None)
	{
		if (OnlineSub.PlayerInterface != None)
		{
			OnlineSub.PlayerInterface.AddReadProfileSettingsCompleteDelegate(LocalPlayer(Player).ControllerId, OnReadProfileSettingsComplete);
			OnlineSub.PlayerInterface.AddFriendInviteReceivedDelegate(LocalPlayer(Player).ControllerId,OnFriendInviteReceived);
			OnlineSub.PlayerInterface.AddReceivedGameInviteDelegate(LocalPlayer(Player).ControllerId,OnGameInviteReceived);
			OnlineSub.PlayerInterface.AddFriendMessageReceivedDelegate(LocalPlayer(Player).ControllerId,OnFriendMessageReceived);
		}

		if(OnlineSub.SystemInterface != None)
		{
			OnlineSub.SystemInterface.AddConnectionStatusChangeDelegate(OnConnectionStatusChange);
			OnlineSub.SystemInterface.AddLinkStatusChangeDelegate(OnLinkStatusChanged);

			// Do an initial controller check
			if(OnlineSub.SystemInterface.IsControllerConnected(LocalPlayer(Player).ControllerId)==false)
			{
				OnControllerChanged(LocalPlayer(Player).ControllerId, false);
			}
		}
	}
}

/** Clears previously set online delegates. */
event ClearOnlineDelegates()
{
	local LocalPlayer LP;

	Super.ClearOnlineDelegates();

	LP = LocalPlayer(Player);
	if ( OnlineSub != None
	&&	(Role < ROLE_Authority || LP != None))
	{
		if (LP != None)
		{
			if (VoiceInterface != None)
			{
				//VoiceInterface.ClearRecognitionCompleteDelegate(LP.ControllerId, SpeechRecognitionComplete);
				// Only unregister voice support if we aren't traveling to a MP game
				if (OnlineSub.GameInterface == None ||
					(OnlineSub.GameInterface != None && OnlineSub.GameInterface.GetGameSettings('Game') == None))
				{
					VoiceInterface.UnregisterLocalTalker(LP.ControllerId);
				}
			}

			if (OnlineSub.PlayerInterface != None)
			{
				OnlineSub.PlayerInterface.ClearReadProfileSettingsCompleteDelegate(LP.ControllerId, OnReadProfileSettingsComplete);
				OnlineSub.PlayerInterface.ClearFriendInviteReceivedDelegate(LP.ControllerId,OnFriendInviteReceived);
				OnlineSub.PlayerInterface.ClearReceivedGameInviteDelegate(LP.ControllerId,OnGameInviteReceived);
				OnlineSub.PlayerInterface.ClearFriendMessageReceivedDelegate(LP.ControllerId,OnFriendMessageReceived);
			}
		}

		if(OnlineSub.SystemInterface != None)
		{
			OnlineSub.SystemInterface.ClearConnectionStatusChangeDelegate(OnConnectionStatusChange);
			OnlineSub.SystemInterface.ClearLinkStatusChangeDelegate(OnLinkStatusChanged);
		}
	}
}


/** turns on/off voice chat/recognition */
exec function ToggleSpeaking(bool bNowOn)
{
	local LocalPlayer LP;

	if (VoiceInterface != None)
	{
		LP = LocalPlayer(Player);
		if (LP != None)
		{
			if (bNowOn)
			{
				VoiceInterface.StartNetworkedVoice(LP.ControllerId);
				if ( WorldInfo.NetMode != NM_Client )
				{
					//VoiceInterface.StartSpeechRecognition(LP.ControllerId);
				}
			}
			else
			{
				VoiceInterface.StopNetworkedVoice(LP.ControllerId);
				if ( WorldInfo.NetMode != NM_Client )
				{
					//VoiceInterface.StopSpeechRecognition(LP.ControllerId);
				}
			}
		}
	}
}


/**
 * Called when the platform's network link status changes.  If we are playing a match on a remote server, we need to go back
 * to the front end menus and notify the player.
 */
//`{debugexec} 
function OnLinkStatusChanged( bool bConnected )
{
	local string ErrorDisplay;
	local UIDataStore_Registry Registry;

	Registry = UIDataStore_Registry(class'UIRoot'.static.StaticResolveDataStore('Registry'));

	`log(`location@`showvar(bConnected),,'DevNet');

	if ( !bConnected && WorldInfo != None && WorldInfo.Game != None)
	{
		// Don't quit to main menu if we are playing instant action
		if (WorldInfo.NetMode != NM_Standalone)
		{
			// if we're no longer connected to the network, check to see if another error message has been set
			// only display our message if none are currently set.
			if (!Registry.GetData("FrontEndError_Display", ErrorDisplay)
			||	int(ErrorDisplay) == 0 )
			{
				SetFrontEndErrorMessage("<Strings:UTGameUI.Errors.Error_Title>", "<Strings:UTGameUI.Errors.NetworkLinkLost_Message>");
				QuitToMainMenu();
			}
		}
	}
}


/** Callback for when the profile finishes reading for this PC. */
function OnReadProfileSettingsComplete(byte LocalUserNum,bool bWasSuccessful)
{
}

/** Callback for when a game invite has been received. */
function OnGameInviteReceived(byte LocalUserNum,string RequestingNick)
{
}

/** Callback for when a friend request has been received. */
function OnFriendInviteReceived(byte LocalUserNum,UniqueNetId RequestingPlayer,string RequestingNick,string Message)
{
}

/**
 * Called when a friend invite arrives for a local player
 *
 * @param LocalUserNum the user that is receiving the invite
 * @param SendingPlayer the player sending the friend request
 * @param SendingNick the nick of the player sending the friend request
 * @param Message the message to display to the recipient
 *
 * @return true if successful, false otherwise
 */
function OnFriendMessageReceived(byte LocalUserNum,UniqueNetId SendingPlayer,string SendingNick,string Message)
{
}

/**
 * Called when a system level connection change notification occurs. If we are
 * playing a Live match, we may need to notify and go back to the menu. Otherwise
 * silently ignore this.
 *
 * @param ConnectionStatus the new connection status.
 */
 
/*`{debugexec} */

function OnConnectionStatusChange(EOnlineServerConnectionStatus ConnectionStatus)
{
	local OnlineGameSettings GameSettings;
	local bool bInvalidConnectionStatus;

	// We need to always bail in this case
	if (ConnectionStatus == OSCS_DuplicateLoginDetected)
	{
		// Two people can't play or badness will happen
		`Log("Detected another user logging-in with this profile.");
		SetFrontEndErrorMessage("<Strings:UTGameUI.Errors.DuplicateLogin_Title>",
			"<Strings:UTGameUI.Errors.DuplicateLogin_Message>");

		bInvalidConnectionStatus = true;
	}
	else
	{
		// Only care about this if we aren't in a standalone netmode.
		if(WorldInfo.NetMode != NM_Standalone)
		{
			// We know we have an online subsystem or this delegate wouldn't be called
			GameSettings = OnlineSub.GameInterface.GetGameSettings('Game');
			if (GameSettings != None)
			{
				// If we are a internet match, this really matters
				if (!GameSettings.bIsLanMatch)
				{
					// We are playing a internet match. Determine whether the connection
					// status change requires us to drop and go to the menu
					switch (ConnectionStatus)
					{
					case OSCS_ConnectionDropped:
					case OSCS_NoNetworkConnection:
					case OSCS_ServiceUnavailable:
					case OSCS_UpdateRequired:
					case OSCS_ServersTooBusy:
					case OSCS_NotConnected:
						SetFrontEndErrorMessage("<Strings:UTGameUI.Errors.ConnectionLost_Title>",
							"<Strings:UTGameUI.Errors.ConnectionLost_Message>");
						bInvalidConnectionStatus = true;
						break;
					}
				}
			}
		}
	}

	`log(`location@`showenum(EOnlineServerConnectionStatus,ConnectionStatus)@`showvar(bInvalidConnectionStatus),,'DevOnline');
	if ( bInvalidConnectionStatus )
	{
		QuitToMainMenu();
	}
}
/**
 * Sets a error message in the registry datastore that will display to the user the next time they are in the frontend.
 *
 * @param Title		Title of the messagebox.
 * @param Message	Message of the messagebox.
 */
static function SetFrontEndErrorMessage(string Title, string Message)
{
	local UIDataStore_Registry Registry;

	Registry = UIDataStore_Registry(class'UIRoot'.static.StaticResolveDataStore('Registry'));

	Registry.SetData("FrontEndError_Title", Title);
	Registry.SetData("FrontEndError_Message", Message);
	Registry.SetData("FrontEndError_Display", "1");
}
defaultproperties
{
	InputClass=class'OWGame.OWPlayerInput'
	CameraClass=class'GameFramework.GamePlayerCamera'
}
