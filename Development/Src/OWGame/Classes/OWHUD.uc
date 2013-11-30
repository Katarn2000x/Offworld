/**
 * UT Heads Up Display base functionality share by old HUD and Scaleform HUD
 *
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class OWHUD extends UDKHUD
	//dependson(UTWeapon)
	config(Game);
	
/** GFx movie used for displaying spawn menu */
var OWGFxSpawnMenu		SpawnMenuMovie;
	
struct stringKV
{
	var string Key;
	var string Value;
};

var OWPlayerController OWPlayerOwner;
var const color BlackColor, BlueColor;
var array<StringKV> Messages;
var OWVPawn_Flitter flitter;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	OWPlayerOwner = OWPlayerController(PlayerOwner);
	SetMessage("Inputs","");
}


/** 
  * Called when pause menu is opened
  */
function CloseOtherMenus();


//Spawn menu stuff is modeled after pause menu stuff in UTHUDBase

/*
 * Toggle the Pause Menu on or off.
 * 
 */
function OpenSpawnMenu()
{
	if ( SpawnMenuMovie != none && SpawnMenuMovie.bMovieIsOpen )
	{
		return;
	}
	else
	{
		CloseOtherMenus();
		
		//PlayOwner.SetPause(True);
		
		if ( SpawnMenuMovie == None )
		{
			SpawnMenuMovie = new class'OWGFxSpawnMenu';
			SpawnMenuMovie.MovieInfo = SwfMovie'OWFrontEnd.ow_spawnmenu';
			SpawnMenuMovie.bEnableGammaCorrection = false;
			SpawnMenuMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
			SpawnMenuMovie.SetTimingMode(TM_Real);		
		}
		//SetVisible(false);
		SpawnMenuMovie.Start();
		SpawnMenuMovie.PlayOpenAnimation();
		
		if( !WorldInfo.IsPlayInMobilePreview() )
		{
			SpawnMenuMovie.AddFocusIgnoreKey('Escape');
		}
		
	}
}
/*
 * Complete necessary actions for OnPauseMenuClose.
 * Fired from Flash.
 */
function CompleteSpawnMenuClose( OWGFxSpawnMenu Movie)
{
    //PlayerOwner.SetPause(False);
	if(Movie != None)
	{
		Movie.Close(false);  // Keep the Pause Menu loaded in memory for reuse.
	}
	OWPlayerOwner.RequestSpawn();
	
    //SetVisible(true);
}


function SetMessage(string key, string value)
{
	local int index;
	local stringKV kv;
	
	kv.Key = key;
	kv.Value = value;
	index = Messages.Find('Key', key);
	if (index == -1)
	{
		Messages.AddItem(kv);
	}
	else
	{
		Messages.Remove(index,1);
		Messages.InsertItem(index, kv);
	}
}

function string VectorString(vector in, optional bool bShowLocal = false)
{
	local string result;
	
	result = Buffer(string(in.X), 12, 0)$" | "$Buffer(string(in.Y), 12, 0)$" | "$Buffer(string(in.Z), 12, 0);
		
	if (bShowLocal)
	{
		result $= "  Local: "$
			Buffer(string(TransformVectorByRotation(flitter.Rotation,in, true).X), 12, 0)$" | "$
			Buffer(string(TransformVectorByRotation(flitter.Rotation,in, true).Y), 12, 0)$" | "$
			Buffer(string(TransformVectorByRotation(flitter.Rotation,in, true).Z), 12, 0);
	}
	
	return result;
		
}

function string RotatorString(Rotator in)
{
	return Buffer(string(in.Roll), 12, 0)$" | "$Buffer(string(in.Pitch), 12, 0)$" | "$Buffer(string(in.Yaw), 12, 0);
}

function string Buffer(string s, int l, int removeFromEnd)
{
	s = Left(s, Len(s)-removeFromEnd);
	
	while(Len(s) < l)
	{
		s = " "$s;
	}
	return s;
}

function DrawHUD()
{
	local float xPos, yPos, yScale;
	local stringKV kv;
	local int i;
	local vector TransThrottle, RotThrottle, Thrust, Torque;
	
	super(HUD).DrawHUD();
	
	flitter = OWVPawn_Flitter(OWPlayerOwner.Pawn);
	if(flitter != None)
		{
		//vehicle.DisplayDebug(Self, out_YL, out_YPos);
		
		TransThrottle.X = flitter.FrontEngine.Throttle;
		TransThrottle.Y = flitter.RightEngine.Throttle;
		TransThrottle.Z = flitter.UpEngine.Throttle;
		
		RotThrottle.X = flitter.RotateCouple.Throttle;
		RotThrottle.Y = flitter.LookUpCouple.Throttle;
		RotThrottle.Z = flitter.TurnCouple.Throttle;
		
		Thrust.X = flitter.FrontEngine.Thrust;
		Thrust.Y = flitter.RightEngine.Thrust;
		Thrust.Z = flitter.UpEngine.Thrust;
		
		Torque.X = flitter.RotateCouple.Torque;
		Torque.Y = flitter.LookUpCouple.Torque;
		Torque.Z = flitter.TurnCouple.Torque;
		
		SetMessage("Mass           ", string(flitter.Mass));
		SetMessage("Location       ", VectorString(flitter.Location));
		SetMessage("Velocity       ", VectorString(flitter.Velocity, true));
		SetMessage("Acceleration   ", VectorString(flitter.CalcAcceleration, true));
		SetMessage("LinearInput	   ", VectorString(flitter.LinearInput));
		SetMessage("TransThrottle  ", VectorString(TransThrottle));
		SetMessage("Thrust         ", VectorString(Thrust));
		
		SetMessage(".", "");
		SetMessage("MomentOfInertia", VectorString(flitter.CalcMomentOfInertia));
		SetMessage("Rotation       ", RotatorString(flitter.Rotation));
		SetMessage("AngularVelocity", VectorString(flitter.AngularVelocity, true));
		SetMessage("AngAcceleration", VectorString(flitter.CalcAngularAcceleration, true));
		SetMessage("RotationalInput", VectorString(flitter.RotationalInput));
		SetMessage("RotThrottle    ", VectorString(RotThrottle));
		SetMessage("Torque         ", VectorString(Torque));
		
		xPos = 10.f;
		yPos = 100.f;
		yScale = 20.f;
		
		Canvas.DrawColor = RedColor;
		
		foreach Messages(kv, i)
		{
			DrawMonospace(kv.Key$": "$kv.Value, xPos, yPos+i*yScale, 7);
		}
	}
}	

function DrawMonospace(string s, float xPos, float yPos, float charWidth)
{
	local int index;
	for(index = 0; index < Len(s); index++)
	{
		Canvas.SetPos(xPos+index*charWidth, yPos);
		Canvas.DrawText(Mid(s, index, 1));
	}
}

defaultproperties
{
	BlackColor=(R=0,G=0,B=0,A=255)
	BlueColor=(R=0,G=0,B=255,A=255)
}


