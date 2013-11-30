class OWVPawn_Flitter extends OWVehiclePawn
	abstract;

var OWEngine FrontEngine;
var OWEngine UpEngine;
var OWEngine RightEngine;

var OWCouple LookUpCouple;
var OWCouple TurnCouple;
var OWCouple RotateCouple;
	
var vector LastVelocity;
var vector LastAngularVelocity;

var vector CalcAcceleration;
var vector CalcAngularAcceleration;
var vector CalcMomentOfInertia;

var repnotify vector TurretFlashLocation;
var repnotify rotator TurretWeaponRotation;
var	repnotify byte TurretFlashCount;
var repnotify byte TurretFiringMode;

replication
{
	if(bNetDirty)
		TurretFlashLocation;
	if(!isSeatControllerReplicationViewer(1) || bDemoRecording)
		TurretFlashCount, TurretFiringMode, TurretWeaponRotation;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
}	

event Tick(float DeltaTime)
{
	
	//local vector gravityKill;
	//gravityKill.Z = 460;
	//AddForce(gravityKill);
	
	super.tick(DeltaTime);
	
	CalcAcceleration = (Velocity - LastVelocity) / DeltaTime;
	CalcAngularAcceleration = (AngularVelocity - LastAngularVelocity) / DeltaTime;
	LastVelocity = Velocity;
	LastAngularVelocity = AngularVelocity;
	
	Guidance(DeltaTime);
}
	
function Guidance(float DeltaTime)
{
	local vector lAccel, lAngAccel, lVel, lAngVel;
	
	lAccel = TransformVectorByRotation(Rotation, CalcAcceleration, true);
	lVel = TransformVectorByRotation(Rotation, Velocity, true);
	lAngAccel = TransformVectorByRotation(Rotation, CalcAngularAcceleration, true);
	lAngVel = TransformVectorByRotation(Rotation, AngularVelocity, true);
	
	ThrottleEngine(FrontEngine,		LinearInput.X,	0.0, 	lVel.X, 	lAccel.X,	DeltaTime);
	ThrottleEngine(RightEngine,		LinearInput.Y,	0.0, 	lVel.Y, 	lAccel.Y,	DeltaTime);
	ThrottleEngine(UpEngine,		LinearInput.Z,	0.0, 	lVel.Z, 	lAccel.Z,	DeltaTime);
	
	ThrottleCouple(RotateCouple, 	RotationalInput.X,	0.0,	lAngVel.X, 	lAngAccel.X, CalcMomentOfInertia.X, DeltaTime);
	ThrottleCouple(LookUpCouple, 	RotationalInput.Y,	0.0,	lAngVel.Y, 	lAngAccel.Y, CalcMomentOfInertia.Y, DeltaTime);
	ThrottleCouple(TurnCouple, 		RotationalInput.Z,	0.0,	lAngVel.Z, 	lAngAccel.Z, CalcMomentOfInertia.Z, DeltaTime);
	
	// VelocityLock = TransformVectorByRotation(Rotation, lVelLock, false);
	
	// VelocityLock.X = 0.0;
	// VelocityLock.Y = 0.0;
	// VelocityLock.Z = 0.0;
}

function ThrottleEngine(OWEngine Engine, float ThrottleScalar, float DesVel, float Vel, float Accel, float DeltaTime)
{
	local float SmoothingFactor, LinJerk, ReqVelChange, TargAccel, ReqThrustChange, MaxThrustChange;
	
	SmoothingFactor = 0.1;
	
	LinJerk = Engine.Yank * SmoothingFactor / Mass;
	
	ReqVelChange = DesVel - Vel;
	
	if(ReqVelChange != 0)
	{
		TargAccel = Sqrt(2* LinJerk * ReqVelChange * ReqVelChange) * ReqVelChange / abs(ReqVelChange);
	}
	else TargAccel = 0;
	
	ReqThrustChange = Mass * (TargAccel - Accel);
	
	MaxThrustChange = Engine.Yank * DeltaTime;
	
	// Wants to stabalize speed
	Engine.Throttle = ReqThrustChange / MaxThrustChange;
	
	if (ThrottleScalar > 0.0)
		Engine.Throttle += ThrottleScalar * (1.0 - Engine.Throttle);
	else if (ThrottleScalar < 0.0)
		Engine.Throttle += ThrottleScalar * (1.0 + Engine.Throttle);
	
	Engine.Throttle = FClamp(Engine.Throttle, -1.0f, 1.0f);
}

function ThrottleCouple(OWCouple Couple, float ThrottleScalar, float DesVel, float Vel, float Accel, out float MomentOfInertia, float DeltaTime)
{
	local float SmoothingFactor, Jerk, ReqTorqueChange, MaxTorqueChange, TargAccel;
	
	SmoothingFactor = 0.1;
	
	if (MomentOfInertia == 0.0 && Couple.Torque > 0.1 && Accel > 0.1)
		MomentOfInertia = Couple.Torque / Accel;
	
	if (MomentOfInertia == 0.0) return;
	
	if (Couple.Torque > 0.3 && Accel > 0.3)
		MomentOfInertia = 0.999 * MomentOfInertia + 0.001 * Couple.Torque / Accel;
	
	Jerk = Couple.Power * SmoothingFactor / MomentOfInertia;
	
	if(Vel != 0)
	{
		TargAccel = Sqrt(2*Jerk*Vel*Vel) * -Vel / abs(Vel);
	}
	else TargAccel = 0;
	
	
	ReqTorqueChange = MomentOfInertia * TargAccel - Couple.Torque;
	
	MaxTorqueChange = Couple.Power * DeltaTime;
	
	Couple.Throttle = ReqTorqueChange / MaxTorqueChange;
	
	if (ThrottleScalar > 0.0)
		Couple.Throttle += ThrottleScalar * (1.0 - Couple.Throttle);
	else if (ThrottleScalar < 0.0)
		Couple.Throttle += ThrottleScalar * (1.0 + Couple.Throttle);
	
	Couple.Throttle = FClamp(Couple.Throttle, -1.0f, 1.0f);
}
	
DefaultProperties
{
	Begin Object Class=OWEngine Name=DefFront
		MaxThrust=6000.f
		MinThrust=-6000.f
		Yank=9000
	End Object
	FrontEngine=DefFront
	Engines.Add(DefFront)
	
	Begin Object Class=OWEngine Name=DefRight
		Rotation=(Yaw=16384)
		MaxThrust=2000.f
		MinThrust=-2000.f
		Yank=6000
	End Object
	RightEngine=DefRight
	Engines.Add(DefRight)
	
	Begin Object Class=OWEngine Name=DefUp
		Rotation=(Pitch=16384)
		MaxThrust=3000.f
		MinThrust=-3000.f
		Yank=5000
	End Object
	UpEngine=DefUp
	Engines.Add(DefUp)
	
	Begin Object Class=OWCouple Name=DefRotate
		MaxTorque=250.f
		MinTorque=-250.f
		Power=2500.0 // ITS OVER 9000
	End Object
	RotateCouple=DefRotate
	Couples.Add(DefRotate)
	
	Begin Object Class=OWCouple Name=DefLookUp
		Rotation=(Yaw=16384)
		MaxTorque=250.f
		MinTorque=-250.f
		Power=2500.0
	End Object
	LookUpCouple=DefLookUp
	Couples.Add(DefLookUp)
	
	Begin Object Class=OWCouple Name=DefTurn
		Rotation=(Pitch=16384)
		MaxTorque=250.f
		MinTorque=-250.f
		Power=2500.0
	End Object
	TurnCouple=DefTurn
	
	CalcMomentOfInertia=(X=150.0, Y=150.0, Z=150.0)
	
	Couples.Add(DefTurn)
	
	LastVelocity = (X=0.0, Y=0.0, Z=0.0)
	LastAngularVelocity = (X=0.0, Y=0.0, Z=0.0)
	MaxSpeed=6000
	Mass=500     //old 4000, 500 is better // tweaked mass

	
}
