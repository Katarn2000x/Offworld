/**
 * Controllable Force Couple which affects actor motion. NOT to be transmitted between client and server.
 *
 * Copyright 2011 Offworld All Rights Reserved.
 */
class OWCouple extends Component;

/** The orientation of the Couple compared to the containing actor. */
var rotator Rotation;

/** The maximum amount of Torque this couple can generate. */
var float MaxTorque;

/** The minimum amount of Torque this couple can generate (can be negative). */
var float MinTorque;

/** The amount of Torque this couple generated in the last tick. */
var float Torque;

/** The maximum rate at which the Torque can be changed. */
var float Power;

/** How much the Torque should be changed in the next tick.
	(Value between -1.0 and 1.0 representing Power magnitude). */
var float Throttle;
	
defaultproperties
{
}


