--[[
class AccelTween
--@author TreyReynolds/AxisAngles

Description:
	Provides a means to, with both a continuous position and velocity,
	accelerate from its current position to a target position in minimum time
	given a maximum acceleration.

API:
	AccelTween = AccelTween.new(number maxaccel = 1)
		maxaccel is the maximum acceleration applied to reach its target.

	number AccelTween.p
		Returns the current position.
	number AccelTween.v
		Returns the current velocity.
	number AccelTween.a
		Returns the maximum acceleration.
	number AccelTween.t
		Returns the target position.
	number AccelTween.rtime
		Returns the remaining time before the AccelTween attains the target.

	AccelTween.p = number
		Sets the current position.
	AccelTween.v = number
		Sets the current velocity.
	AccelTween.a = number
		Sets the maximum acceleration.
	AccelTween.t = number
		Sets the target position.
	AccelTween.pt = number
		Sets the current and target position, and sets the velocity to 0.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Services = Resources:LoadLibrary("Services")
local Table = Resources:LoadLibrary("Table")

local AccelTween = {ClassName = "AccelTween"}
local TimingFunction = Services.RunService:IsRunning() and time or os.clock

function AccelTween.new(MaxAcceleration)
	return setmetatable({
		Acceleration = MaxAcceleration or 1;
		T0 = 0;
		Y0 = 0;
		A0 = 0;

		T1 = 0;
		Y1 = 0;
		A1 = 0;
	}, AccelTween)
end

function AccelTween:__index(Index)
	if AccelTween[Index] then
		return AccelTween[Index]
	elseif Index == "Position" or Index == "P" or Index == "p" then
		return self:GetState(TimingFunction())
	elseif Index == "Velocity" or Index == "V" or Index == "v" then
		local _, Velocity = self:GetState(TimingFunction())
		return Velocity
	elseif Index == "Acceleration" or Index == "A" or Index == "a" then
		return self.Acceleration
	elseif Index == "Target" or Index == "T" or Index == "t" then
		return self.Y1
	elseif Index == "RemainingTime" or Index == "RTime" or Index == "rtime" then
		local Time = TimingFunction()
		return Time < self.T1 and self.T1 - Time or 0
	else
		Debug.Error("%s (%s) is not a valid member of \"AccelTween\"", tostring(Index), typeof(Index))
	end
end

function AccelTween:__newindex(Index, Value)
	if Index == "Position" or Index == "P" or Index == "p" then
		self:SetState(Value, nil, nil, nil)
	elseif Index == "Velocity" or Index == "V" or Index == "v" then
		self:SetState(nil, Value, nil, nil)
	elseif Index == "Acceleration" or Index == "A" or Index == "a" then
		self:SetState(nil, nil, Value, nil)
	elseif Index == "Target" or Index == "T" or Index == "t" then
		self:SetState(nil, nil, nil, Value)
	elseif Index == "PositionTarget" or Index == "PT" or Index == "pt" then
		self:SetState(Value, 0, nil, Value)
	else
		Debug.Error("%s (%s) is not a valid member of \"AccelTween\"", tostring(Index), typeof(Index))
	end
end

function AccelTween:GetState(Time)
	if Time < (self.T0 + self.T1) / 2 then
		local DeltaTime = Time - self.T0
		return self.Y0 + DeltaTime * DeltaTime / 2 * self.A0, DeltaTime * self.A0
	elseif Time < self.T1 then
		local DeltaTime = Time - self.T1
		return self.Y1 + DeltaTime * DeltaTime / 2 * self.A1, DeltaTime * self.A1
	else
		return self.Y1, 0
	end
end

function AccelTween:SetState(NewPosition, NewVelocity, NewAcceleration, NewTarget)
	local Time = TimingFunction()
	local Position, Velocity = self:GetState(Time)
	Position = NewPosition or Position
	Velocity = NewVelocity or Velocity
	self.Acceleration = NewAcceleration or self.Acceleration
	local Target = NewTarget or self.Y1

	if self.Acceleration * self.Acceleration < 1E-8 then
		self.T0, self.Y0, self.A0 = 0, Position, 0
		self.T1, self.Y1, self.A1 = math.huge, Target, 0
	else
		local CondA = Target < Position
		local CondB = Velocity < 0
		local CondC = Position - Velocity * Velocity / (2 * self.Acceleration) < Target
		local CondD = Position + Velocity * Velocity / (2 * self.Acceleration) < Target
		if CondA and CondB and CondC or not CondA and (CondB or not CondB and CondD) then
			self.A0 = self.Acceleration
			self.T1 = Time + (math.sqrt(2 * Velocity * Velocity + 4 * self.Acceleration * (Target - Position)) - Velocity) / self.Acceleration
		else
			self.A0 = -self.Acceleration
			self.T1 = Time + (math.sqrt(2 * Velocity * Velocity - 4 * self.Acceleration * (Target - Position)) + Velocity) / self.Acceleration
		end

		self.T0 = Time - Velocity / self.A0
		self.Y0 = Position - Velocity * Velocity / (2 * self.A0)
		self.Y1 = Target
		self.A1 = -self.A0
	end
end

return Table.Lock(AccelTween, nil, script.Name)