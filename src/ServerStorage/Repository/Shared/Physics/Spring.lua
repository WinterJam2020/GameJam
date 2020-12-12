--[[
	class Spring

	Description:
		A physical model of a spring, useful in many applications. Properties only evaluate
		upon index making this model good for lazy applications

	API:
		Spring = Spring.new(number position)
			Creates a new spring in 1D
		Spring = Spring.new(Vector3 position)
			Creates a new spring in 3D
		Spring.Position
			Returns the current position
		Spring.Velocity
			Returns the current velocity
		Spring.Target
			Returns the target
		Spring.Damper
			Returns the damper
		Spring.Speed
			Returns the speed

		Spring.Target = number/Vector3
			Sets the target
		Spring.Position = number/Vector3
			Sets the position
		Spring.Velocity = number/Vector3
			Sets the velocity
		Spring.Damper = number [0, 1]
			Sets the spring damper, defaults to 1
		Spring.Speed = number [0, infinity)
			Sets the spring speed, defaults to 1

		Spring:TimeSkip(number DeltaTime)
			Instantly skips the spring forwards by that amount of now
		Spring:Impulse(number/Vector3 velocity)
			Impulses the spring, increasing velocity by the amount given
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Typer = Resources:LoadLibrary("Typer")

local Spring = {ClassName = "Spring"}

type ClockFunction = () -> number
type HasMul = number | Vector3 | Vector2

--[[**
	Creates a new spring.
	@param [Typer.NumberOrVector2OrVector3] Initial A number or Vector3 (anything with * number and addition/subtraction defined). Defaults to 0.
	@param [Typer.OptionalFunction] ClockFunction A timing function such as `os.clock` or `time` to use for delta time purposes. Defaults to `time`.
	@returns [Typer.Spring]
**--]]
Spring.new = Typer.AssignSignature(Typer.OptionalNumberOrVector2OrVector3, Typer.OptionalFunction, function(Initial: HasMul?, ClockFunction: ClockFunction?)
	local Target = Initial or 0
	ClockFunction = ClockFunction or time
	return setmetatable({
		ClockFunction = ClockFunction;
		Time0 = ClockFunction();
		Position0 = Target;
		Velocity0 = 0 * Target;
		Target = Target;
		Damper = 1;
		Speed = 1;
	}, Spring)
end)

--[[**
	Impulse the spring with a change in velocity.
	@param [Typer.NumberOrVector2OrVector3] Velocity The velocity to impulse with.
	@returns [Typer.Nil]
**--]]
function Spring:Impulse(Velocity: HasMul): nil
	self.Velocity += Velocity
end

local function PositionVelocity(self, CurrentTime)
	local p0 = self.Position0
	local v0 = self.Velocity0
	local p1 = self.Target
	local d = self.Damper
	local s = self.Speed

	local t = s*(CurrentTime - self.Time0)
	local d2 = d*d

	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d*t)/h
		co, si = ep*math.cos(h*t), ep*math.sin(h*t)
	elseif d2 == 1 then
		h = 1
		local ep = math.exp(-d*t)/h
		co, si = ep, ep*t
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h)*t)/(2*h)
		local v = math.exp((-d - h)*t)/(2*h)
		co, si = u + v, u - v
	end

	local a0 = h*co + d*si
	local a1 = 1 - (h*co + d*si)
	local a2 = si/s

	local b0 = -s*si
	local b1 = s*si
	local b2 = h*co - d*si

	return
		a0*p0 + a1*p1 + a2*v0,
		b0*p0 + b1*p1 + b2*v0
end

--- Skip forwards in now
-- @param delta now to skip forwards
function Spring:TimeSkip(Delta)
	local CurrentTime: number = self.ClockFunction()
	local Position, Velocity = PositionVelocity(self, CurrentTime + Delta)

	self.Position0 = Position
	self.Velocity0 = Velocity
	self.Time0 = CurrentTime
end

function Spring:__index(Index)
	if Spring[Index] then
		return Spring[Index]
	elseif Index == "Value" or Index == "Position" or Index == "p" then
		return PositionVelocity(self, self.ClockFunction())
	elseif Index == "Velocity" or Index == "v" then
		local _, Velocity = PositionVelocity(self, self.ClockFunction())
		return Velocity
	elseif Index == "Target" or Index == "t" then
		return self.Target
	elseif Index == "Damper" or Index == "d" then
		return self.Damper
	elseif Index == "Speed" or Index == "s" then
		return self.Speed
	elseif Index == "Clock" or Index == "ClockFunction" then
		return self.ClockFunction
	else
		Debug.Error("%s is not a valid member of Spring", tostring(Index))
	end
end

function Spring:__newindex(Index, Value)
	local CurrentTime = self.ClockFunction()
	if Index == "Value" or Index == "Position" or Index == "p" then
		local _, Velocity = PositionVelocity(self, CurrentTime)
		self.Position0 = Value
		self.Velocity0 = Velocity
		self.Time0 = CurrentTime
	elseif Index == "Velocity" or Index == "v" then
		self.Position0 = PositionVelocity(self, CurrentTime)
		self.Velocity0 = Value
		self.Time0 = CurrentTime
	elseif Index == "Target" or Index == "t" then
		self.Position0, self.Velocity0 = PositionVelocity(self, CurrentTime)
		self.Target = Value
		self.Time0 = CurrentTime
	elseif Index == "Damper" or Index == "d" then
		self.Position0, self.Velocity0 = PositionVelocity(self, CurrentTime)
		self.Damper = Value < 0 and 0 or Value > 1 and 1 or Value
		self.Time0 = CurrentTime
	elseif Index == "Speed" or Index == "s" then
		self.Position0, self.Velocity0 = PositionVelocity(self, CurrentTime)
		self.Speed = Value < 0 and 0 or Value
		self.Time0 = CurrentTime
	elseif Index == "Clock" or Index == "ClockFunction" then
		self.Position0, self.Velocity0 = PositionVelocity(self, CurrentTime)
		self.ClockFunction = Value
		self.Time0 = Value()
	else
		Debug.Error("%s is not a valid member of Spring", tostring(Index))
	end
end

return Spring