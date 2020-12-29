local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local TimeSyncService = Resources:LoadLibrary("TimeSyncService")

local ProjectilePhysics = {ClassName = "ProjectilePhysics"}

function ProjectilePhysics.new(Initial: number?)
	Initial = Initial or 0
	local self = rawset(rawset(rawset(rawset(setmetatable({}, ProjectilePhysics), "_Clock", TimeSyncService:WaitForSyncedClock()), "_Position0", Initial), "_Velocity0", Initial * 0), "_Acceleration", Initial * 0) -- haha gross
	rawset(self, "_Time0", self._Clock:GetTime())
	return self
end

function ProjectilePhysics:Impulse(Velocity)
	self.Velocity += Velocity
end

function ProjectilePhysics:TimeSkip(DeltaTime)
	local CurrentTime = self._Clock:GetTime()
	local Position, Velocity = self:_PositionVelocity(CurrentTime + DeltaTime)
	rawset(rawset(rawset(self, "_Time0", CurrentTime), "_Velocity0", Velocity), "_Position0", Position)
end

function ProjectilePhysics:SetData(StartTime, Position0, Velocity0, Acceleration)
	rawset(rawset(rawset(rawset(self, "_Acceleration", Acceleration), "_Velocity0", Velocity0), "_Position0", Position0), "_Time0", StartTime) -- haha
end

function ProjectilePhysics:__index(Index)
	local CurrentTime = self._Clock:GetTime()

	if ProjectilePhysics[Index] then
		return ProjectilePhysics[Index]
	elseif Index == "Position" then
		return self:_PositionVelocity(CurrentTime)
	elseif Index == "Velocity" then
		local _, Velocity = self:_PositionVelocity(CurrentTime)
		return Velocity
	elseif Index == "Acceleration" then
		return rawget(self, "_Acceleration")
	elseif Index == "StartTime" then
		return rawget(self, "_Time0")
	elseif Index == "StartPosition" then
		return rawget(self, "_Position0")
	elseif Index == "StartVelocity" then
		return rawget(self, "_Velocity0")
	elseif Index == "Age" then
		return self._Clock:GetTime() - rawget(self, "_Time0")
	else
		error(string.format("%q is not a valid member of ProjectilePhysics", tostring(Index)), 2)
	end
end

function ProjectilePhysics:__newindex(Index, Value)
	local CurrentTime = self._Clock:GetTime()
	if Index == "Position" then
		local _, Velocity = self:_PositionVelocity(CurrentTime)
		rawset(self, "_Position0", Value)
		rawset(self, "_Velocity0", Velocity)
	elseif Index == "Velocity" then
		rawset(self, "_Position0", self:_PositionVelocity(CurrentTime))
		rawset(self, "_Velocity0", Value)
	elseif Index == "Acceleration" then
		local Position, Velocity = self:_PositionVelocity(CurrentTime)
		rawset(self, "_Position0", Position)
		rawset(self, "_Velocity0", Velocity)
		rawset(self, "_Acceleration", Value)
	else
		error(string.format("%q is not a valid member of ProjectilePhysics", tostring(Index)), 2)
	end

	rawset(self, "_Time0", CurrentTime)
end

function ProjectilePhysics:_PositionVelocity(Time): (number, number)
	local DeltaTime = Time - rawget(self, "_Time0")
	local A0 = rawget(self, "_Acceleration")
	local V0 = rawget(self, "_Velocity0")
	local P0 = rawget(self, "_Position0")
	return P0 + V0 * DeltaTime + 0.5 * DeltaTime * DeltaTime * A0, V0 + A0 * DeltaTime
end

return ProjectilePhysics