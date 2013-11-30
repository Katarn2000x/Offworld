/**
 * Controllable Force which affects actor motion. NOT to be transmitted between client and server.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class OWEngine extends Component;

/** The position of the Force compared to the containing actor. */
var vector Position;

/** The orientation of the Force compared to the containing actor. */
var rotator Rotation;

/** The maximum amount of Force this couple can generate. */
var float MaxThrust;

/** The minimum amount of Force this couple can generate (can be negative). */
var float MinThrust;

/** The amount of Force this couple generated in the last tick. */
var float Thrust;

/** The maximum rate at which the Thrust can be changed. */
var float Yank;

/** How much the Thrust should be changed in the next tick. 
	(Value between -1.0 and 1.0 representing Yank magnitude). */
var float Throttle;
	
defaultproperties
{
}


