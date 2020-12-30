local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local SyncedPoller = Resources:LoadLibrary("SyncedPoller")

local ServerHandler = {
	Constants = nil;
	ParticleEngine = nil;
	TimeSyncService = nil;
	PlayerDataHandler = nil;
	GameEvent = nil;

	GameLoop = nil;
}

local SERVER_EVENTS = {
	[Constants.READY_PLAYER] = function(Player: Player)
		CollectionService:AddTag(Player, "ReadyPlayers")
	end;
}

function ServerHandler:Initialize()
	self.Constants = Constants
	self.ParticleEngine = Resources:LoadLibrary("ParticleEngine"):Initialize()
	self.TimeSyncService = Resources:LoadLibrary("TimeSyncService"):Initialize()
	self.PlayerDataHandler = Resources:LoadLibrary("PlayerDataHandler"):Initialize()
	self.GameEvent = Resources:GetRemoteEvent("GameEvent")

	self.GameEvent.OnServerEvent:Connect(function(Player, FunctionCall, ...)
		local Function = SERVER_EVENTS[FunctionCall]
		if Function then
			Function(Player, ...)
		end
	end)

	return self
end

function ServerHandler:StartGameLoop()
	if self.GameLoop then
		self.GameLoop.Paused = false
	else
		self.GameLoop = SyncedPoller.new(1, function()
			local ReadyPlayers = CollectionService:GetTagged("ReadyPlayers")
			if #ReadyPlayers > 1 then
				return true
			end
		end)
	end

	return self
end

function ServerHandler:StopGameLoop()
	if self.GameLoop then
		self.GameLoop.Paused = true
	else
		warn("GameLoop doesn't exist!")
	end

	return self
end

return ServerHandler