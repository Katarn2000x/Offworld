/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */

class OWPlayerInput extends UDKPlayerInput within OWPlayerController
	config(Input);
	
var globalconfig	bool		bInvertRotate;

var()	config		float	LookRotateScale;


event PlayerInput( float DeltaTime )
{
	local float FOVScale, TimeScale;

	// Save Raw values
	RawJoyUp		= aBaseY;
	RawJoyRight		= aStrafe;
	RawJoyLookRight	= aTurn;
	RawJoyLookUp	= aLookUp;
	
	// PlayerInput shouldn't take timedilation into account
	DeltaTime /= WorldInfo.TimeDilation;
	if (Outer.bDemoOwner && WorldInfo.NetMode == NM_Client)
	{
		DeltaTime /= WorldInfo.DemoPlayTimeDilation;
	}

	PreProcessInput( DeltaTime );

	// Scale to game speed
	TimeScale = 100.f*DeltaTime;
	aBaseY		*= TimeScale * MoveForwardSpeed;
	aStrafe		*= TimeScale * MoveStrafeSpeed;
	aUp			*= TimeScale * MoveStrafeSpeed;
	aTurn		*= TimeScale * LookRightScale;
	aLookUp		*= TimeScale * LookUpScale;
	aBaseZ		*= TimeScale * LookRotateScale;
	
	PostProcessInput( DeltaTime );

	ProcessInputMatching(DeltaTime);

	// Check for Double click movement.
	CatchDoubleClickInput();

	// Take FOV into account (lower FOV == less sensitivity).

	if ( bEnableFOVScaling )
	{
		FOVScale = GetFOVAngle() * 0.01111; // 0.01111 = 1 / 90.0
	}
	else
	{
		FOVScale = 1.0;
	}

	AdjustMouseSensitivity(FOVScale);

	// mouse smoothing
	if ( bEnableMouseSmoothing )
	{
		aMouseX = SmoothMouse(aMouseX, DeltaTime,bXAxis,0);
		aMouseY = SmoothMouse(aMouseY, DeltaTime,bYAxis,1);
	}

	aLookUp			*= FOVScale;
	aTurn			*= FOVScale;
	aBaseZ			*= FOVScale;
	
	// Turning and strafing share the same axis.
	if( bStrafe > 0 )
		aStrafe		+= aBaseX + aMouseX;
	else
		aTurn		+= aBaseX + aMouseX;

	// Look up/down.
	aLookup += aMouseY;
	if (bInvertMouse)
	{
		aLookup *= -1.f;
	}

	if (bInvertTurn)
	{
		aTurn *= -1.f;
	}

	if (bInvertRotate)
	{
		aBaseZ *= -1.f;
	}
	
	// Forward/ backward movement
	aForward		+= aBaseY;

	// Handle walking.
	HandleWalking();

	// check for turn locking
	if (bLockTurnUntilRelease)
	{
		if (RawJoyLookRight != 0)
		{
			aTurn = 0.f;
			if (AutoUnlockTurnTime > 0.f)
			{
				AutoUnlockTurnTime -= DeltaTime;
				if (AutoUnlockTurnTime < 0.f)
				{
					bLockTurnUntilRelease = FALSE;
				}
			}
		}
		else
		{
			bLockTurnUntilRelease = FALSE;
		}
	}

	// ignore move input
	// Do not clear RawJoy flags, as we still want to be able to read input.
	if( IsMoveInputIgnored() )
	{
		aForward	= 0.f;
		aStrafe		= 0.f;
		aUp			= 0.f;
	}

	// ignore look input
	// Do not clear RawJoy flags, as we still want to be able to read input.
	if( IsLookInputIgnored() )
	{
		aTurn		= 0.f;
		aLookup		= 0.f;
		aBaseZ		= 0.f;
	}
	
	
	// aRotate		*=	TimeScale * LookRotateScale;
	
	// aRotate			*= FOVScale;
	
	// if (bInvertRotate)
	// {
		// aRotate *= -1.f;
	// }
	
	// if( IsLookInputIgnored() )
	// {
		// aRotate		= 0.f;
	// }
}

defaultproperties
{
}