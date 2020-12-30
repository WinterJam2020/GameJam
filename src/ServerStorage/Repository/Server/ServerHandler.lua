local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Constants = Resources:LoadLibrary("Constants")
local Postie = Resources:LoadLibrary("Postie")
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")
local SyncedPoller = Resources:LoadLibrary("SyncedPoller")
local ValueObject = Resources:LoadLibrary("ValueObject")

local Workspace: Workspace = Services.Workspace
local Players: Players = Services.Players
local CollectionService: CollectionService = Services.CollectionService

local ServerHandler = {
	Constants = nil;
	GameEvent = nil;
	GameInProgress = ValueObject.new(false);
	GameLoop = nil;
	ParticleEngine = nil;
	PlayerData = {};
	PlayerDataHandler = nil;
	TimeSyncService = nil;
	SkiPathGenerator = nil;
	SkiPathRemote = nil;
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
	self.SkiPathGenerator = Resources:LoadServer("SkiPathGenerator")

	self.SkiPathRemote = Resources:GetRemoteFunction(Constants.REMOTE_NAMES.SKI_PATH_REMOTE_FUNCTION_NAME)
	self.GameEvent = Resources:GetRemoteEvent("GameEvent")
	self.GameFunction = Resources:GetRemoteFunction("GameFunction")

	self.SkiPathGenerator:Initialize()

	self.GameEvent.OnServerEvent:Connect(function(Player: Player, FunctionCall: number, ...)
		local Function = SERVER_EVENTS[FunctionCall]
		if Function then
			Function(Player, ...)
		end
	end)

	local Baseplate = Workspace:FindFirstChild("Baseplate")
	if Baseplate then
		Baseplate:Destroy()
	end

	self.SkiChain, self.SkiChainCFrames = self.SkiPathGenerator:Generate()
	function self.SkiPathRemote.OnServerInvoke()
		return self.SkiChainCFrames
	end

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
					-- Player:LoadCharacter()
					self.GameEvent:FireClient(Player, Constants.SPAWN_CHARACTER, self.SkiChainCFrames)
					self.GameEvent:FireClient(Player, Constants.START_SKIING)
					self.PlayerData[Player] = {
						StartTime = time();
						EndTime = 0;
						Progress = 0;
						HasFinished = false;
					}

					-- Check if player finished skiing
					local CountdownTime = 0
					local CountdownPoller
					CountdownPoller = SyncedPoller.new(0.5, function(_, ElapsedTime)
						CountdownTime += ElapsedTime
						if CountdownTime >= 60 then
							CountdownPoller:Destroy()
						else
							for EnteredPlayer, _PlayerData in next, self.PlayerData do
								local _, Alpha = Postie.InvokeClient(EnteredPlayer, "GetProgress", 1)
								print(EnteredPlayer.Name, "-", Alpha)
							end
						end
					end)

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