local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local Debug = Resources:LoadLibrary("Debug")

local Debug_Assert = Debug.Assert
local IProperties = Constants.TYPE_CHECKS.IParticleProperties

local ParticleEngineServer = {}

function ParticleEngineServer:Initialize()
	self.RemoteEvent = Resources:GetRemoteEvent(Constants.REMOTE_NAME.PARTICLE_ENGINE_EVENT)
	self.RemoteEvent.OnServerEvent:Connect(function(Player, Properties)
		Properties.Global = nil
		for _, OtherPlayer in ipairs(Players:GetPlayers()) do
			if OtherPlayer ~= Player then
				self.RemoteEvent:FireClient(OtherPlayer, Properties)
			end
		end
	end)

	return self
end

local DEFAULT_SIZE = Vector2.new(0.2, 0.2)
local EMPTY_VECTOR2 = Vector2.new()
local EMPTY_VECTOR3 = Vector3.new()
local WHITE_COLOR3 = Color3.new(1, 1, 1)

function ParticleEngineServer:Add(Properties)
	local TypeSuccess, TypeError = IProperties(Properties)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	Properties.Velocity = Properties.Velocity or EMPTY_VECTOR3
	Properties.Size = Properties.Size or DEFAULT_SIZE
	Properties.Bloom = Properties.Bloom or EMPTY_VECTOR2
	Properties.Gravity = Properties.Gravity or EMPTY_VECTOR3
	Properties.Color = Properties.Color or WHITE_COLOR3
	Properties.Transparency = Properties.Transparency or 0.5

	Debug_Assert(self.RemoteEvent, "Uninitialized ParticleEngine!"):FireAllClients(Properties)
	return Properties
end

return ParticleEngineServer