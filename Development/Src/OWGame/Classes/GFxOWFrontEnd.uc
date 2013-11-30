/**
 * Controllable Force Couple which affects actor motion. NOT to be transmitted between client and server.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class GFxOWFrontEnd extends GFxMoviePlayer;

function bool Start(optional bool StartPaused = false)
{
	super.Start();
	Advance(0);
	
	return true;
}

function FlashToConsole(string command)
{
    local GameViewportClient gameview;

     gameview = GetGameViewportClient();
     gameview.ConsoleCommand(command);
}

