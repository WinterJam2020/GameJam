local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")
local SyncedPoller = Resources:LoadLibrary("SyncedPoller")
local ValueObject = Resources:LoadLibrary("ValueObject")

local ServerHandler = {
	Constants = nil;
	GameEvent = nil;
	GameInProgress = ValueObject.new(false);
	GameLoop = nil;
	ParticleEngine = nil;
	PlayerData = {};
	PlayerDataHandler = nil;
	TimeSyncService = nil;
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
	self.GameFunction = Resources:GetRemoteFunction("GameFunction")

	self.GameEvent.OnServerEvent:Connect(function(Player: Player, FunctionCall: number, ...)
		local Function = SERVER_EVENTS[FunctionCall]
		if Function then
			Function(Player, ...)
		end
	end)

	Players.PlayerRemoving:Connect(function(Player: Player)
		if self.PlayerData[Player] then
			self.PlayerData[Player] = nil
		end
	end)

	return self
end

function ServerHandler:StartGameLoop()
	if self.GameLoop then
		self.GameLoop.Paused = false
	else
		self.GameLoop = SyncedPoller.new(1, function()
			if self.GameInProgress.Value then
				self.GameLoop.Paused = true
				self.GameInProgress.Changed:Wait()
				self.GameLoop.Paused = false
				table.clear(self.PlayerData)
			end

			local ReadyPlayers = CollectionService:GetTagged("ReadyPlayers")
			if #ReadyPlayers > 0 then
				self.GameInProgress.Value = true
				for _, Player: Player in ipairs(ReadyPlayers) do
					CollectionService:RemoveTag(Player, "ReadyPlayers")
					Player:LoadCharacter()
					self.PlayerData[Player] = {
						StartTime = time();
						EndTime = 0;
						HasFinished = false;
					}

					-- Check if player finished skiing

					-- if player finished skiing then update the data table

					-- once every player is finished, show leaderboard

					-- give nice delay then reset
					-- might do something like Promise.Delay(5):ThenCall(self.GameEvent.FireAllClients, self.GameEvent, Constants._____) or something
				end
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