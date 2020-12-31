local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local ParticleEngine = Resources:LoadLibrary("ParticleEngine")

local ParticleEngineHelper = {}

local RandomLib = Random.new(tick() % 1 * 1E7)
local NextInteger = RandomLib.NextInteger -- haha optimize
local NextNumber = RandomLib.NextNumber

function ParticleEngineHelper.Add(Properties)
	ParticleEngine:Add(Properties)
end

function ParticleEngineHelper.Remove(Properties)
	ParticleEngine:Remove(Properties)
end

local function GetRandomAngles(VelocityCFrame, Amount)
	return VelocityCFrame * CFrame.Angles(
		(NextNumber(RandomLib) - 0.5) * Amount,
		(NextNumber(RandomLib) - 0.5) * Amount,
		(NextNumber(RandomLib) - 0.5) * Amount
	)
end

local SNOW_GRAVITY = Vector3.new(0, -3, 0)
local REFLECTABLE_BLOOM = Vector2.new(2, 2)
local REFLECTABLE_GRAVITY = Vector3.new(0, -50, 0)

-- function ParticleEngineHelper.SnowParticle(Position, VelocityCFrame)
-- 	ParticleEngine:Add {
-- 		Occlusion = true;
-- 		Size = Vector2.new(0.05 + NextNumber(RandomLib) / 20, 0.05 + NextNumber(RandomLib) / 20);
-- 		Velocity = GetRandomAngles(VelocityCFrame, 0.2).Position.Unit * NextNumber(RandomLib, 100, 200);
-- 		Transparency = 0,--0.1 + NextNumber(RandomLib) * 0.4;
-- 		Position = Position;
-- 		Gravity = SNOW_GRAVITY;
-- 		WindResistance = 10;
-- 		Lifetime = NextNumber(RandomLib) + 0.5;
-- 		Color = Color3.fromRGB(NextInteger(RandomLib, 230, 255), NextInteger(RandomLib, 230, 255), NextInteger(RandomLib, 230, 255));
-- 	}
-- end

function ParticleEngineHelper.WindParticle(Position, VelocityCFrame)
	ParticleEngine:Add {
		Occlusion = false;
		Size = Vector2.new(0.5, 0.5);
		Velocity = Vector3.new(), --VelocityCFrame.LookVector * NextNumber(RandomLib, 50, 100);
		Transparency = 0.1 + NextNumber(RandomLib) * 0.4;
		Position = Position;
		Gravity = SNOW_GRAVITY;
		WindResistance = 10;
		Lifetime = NextNumber(RandomLib) + 0.5;
		Color = Color3.fromRGB(255, 255, 255)
	}
end

local function RemoveOnCollision(Particle, _, Position, Normal, Material): boolean
	if Material == Enum.Material.Snow or Material == Enum.Material.Grass then
		return false
	else
		local ParticleVelocity = Particle.Velocity
		local VelocityUnit = ParticleVelocity.Unit
		local VelocityDot = VelocityUnit - 2 * VelocityUnit:Dot(Normal) * Normal

		Particle.Position = Position + VelocityDot / 20
		Particle.Velocity = VelocityDot * (ParticleVelocity.Magnitude / 2) + Vector3.new(NextNumber(RandomLib) - 0.5, 0, NextNumber(RandomLib) - 0.5)
		return true
	end
end

local function SnowFunction(Particle, _, CurrentTime)
	local RemainingTime = Particle.Lifetime - CurrentTime
	if RemainingTime <= 0.5 then
		Particle.Transparency = -3 + 4 * (1 - RemainingTime)
	end
end

function ParticleEngineHelper.ReflectableSnowParticle(Position, ReflectedNormal)
	ParticleEngine:Add {
		Bloom = REFLECTABLE_BLOOM;
		Occlusion = true;
		Size = Vector2.new(0.1 + NextNumber(RandomLib) / 10, 0.1 + NextNumber(RandomLib) / 10);
		Velocity = (ReflectedNormal + Vector3.new(NextNumber(RandomLib) - 0.5, NextNumber(RandomLib) - 0.5, NextNumber(RandomLib) - 0.5) / 2) * 50;
		Transparency = -3;
		Position = Position;
		Gravity = REFLECTABLE_GRAVITY;
		WindResistance = 0.2;
		Lifetime = 2;
		Color = Color3.fromRGB(NextInteger(RandomLib, 230, 255), NextInteger(RandomLib, 230, 255), NextInteger(RandomLib, 230, 255));
		RemoveOnCollision = RemoveOnCollision;
		Function = SnowFunction;
	}
end

return ParticleEngineHelper