/**
 * Contains information regarding the game mode that is pertinant to all players and specific to Offworld.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class OWGameReplicationInfo extends GameReplicationInfo
	config(Game);
	
/** whether the server is a console so we need to make adjustments to sync up */
var bool bConsoleServer;

defaultproperties
{
	TickGroup=TG_PreAsyncWork
}
