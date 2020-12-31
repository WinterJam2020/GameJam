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
	GameInProgress = nil;
	GameLoop = nil;
	ParticleEngine = nil;
	PlayerData = {};
	PlayerDataHandler = nil;
	SkiChain = nil;
	SkiChainCFrames = nil;
	SkiPathGenerator = nil;
	SkiPathRemote = nil;
	TimeSyncService = nil;
}

local SERVER_EVENTS = {
	[Constants.READY_PLAYER] = function(Player: Player)
		CollectionService:AddTag(Player, "ReadyPlayers")
	end;
}

local Postie_PromiseInvokeClient = Postie.PromiseInvokeClient
local Promise_Delay = Promise.Delay

function ServerHandler:Initialize()
	self.Constants = Constants
	self.GameInProgress = ValueObject.new(false)
	self.ParticleEngine = Resources:LoadLibrary("ParticleEngine"):Initialize()
	self.PlayerDataHandler = Resources:LoadLibrary("PlayerDataHandler"):Initialize()
	self.SkiPathGenerator = Resources:LoadServer("SkiPathGenerator")
	self.TimeSyncService = Resources:LoadLibrary("TimeSyncService"):Initialize()

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
		self.GameLoop = SyncedPoller.new(10, function()
			if self.GameInProgress.Value then
				self.GameLoop.Paused = true
				self.GameInProgress.Changed:Wait()
				self.GameLoop.Paused = false
				table.clear(self.PlayerData)
			end

			local ReadyPlayers = CollectionService:GetTagged("ReadyPlayers")
			if #ReadyPlayers > 0 then
				local GameEvent: RemoteEvent = self.GameEvent
				self.GameInProgress.Value = true

				for _, Player: Player in ipairs(ReadyPlayers) do
					CollectionService:RemoveTag(Player, "ReadyPlayers")
					GameEvent:FireClient(Player, Constants.START_THE_COUNTDOWN)
					GameEvent:FireClient(Player, Constants.SPAWN_CHARACTER, self.SkiChainCFrames)
					GameEvent:FireClient(Player, Constants.START_SKIING)

					self.PlayerData[Player] = {
						StartTime = time();
						EndTime = 0;
						HasFinished = false;
					}
				end

				local CurrentPlayerData = self.PlayerData
				local function GetLength(): number
					local Length: number = 0
					for _ in next, CurrentPlayerData do
						Length += 1
					end

					return Length
				end

				local function IsEveryoneDone(): boolean
					local GoalLength: number = GetLength()
					local Length: number = 0

					for _, PlayerData in next, CurrentPlayerData do
						if PlayerData.HasFinished then
							Length += 1
						end
					end

					return Length == GoalLength
				end

				-- Check if player finished skiing
				local ShouldContinue = Instance.new("BindableEvent")
				local CountdownTime = 0
				local CountdownPoller
				CountdownPoller = SyncedPoller.new(0.5, function(_, ElapsedTime)
					CountdownTime += ElapsedTime
					if CountdownTime >= Constants.CONFIGURATION.TIME_PER_ROUND or IsEveryoneDone() then
						ShouldContinue:Fire()
						CountdownPoller:Destroy()
					else
						for Player, PlayerData in next, CurrentPlayerData do
							if PlayerData.HasFinished then
								continue
							end

							Postie_PromiseInvokeClient(Player, "GetProgress", 10):Then(function(Alpha: number)
								if Alpha == 1 then
									PlayerData.HasFinished = true
									PlayerData.EndTime = time()
								end
							end):Catch(CatchFactory("Postie.PromiseInvokeClient"))--:Wait()
						end
					end
				end)

				ShouldContinue.Event:Wait()
				ShouldContinue:Destroy()

				GameEvent:FireAllClients(Constants.IS_COUNTDOWN_ACTIVE, false)
				GameEvent:FireAllClients(Constants.HIDE_COUNTDOWN)

				local Entries = {}
				local Length = 0

				for Player, PlayerData in next, CurrentPlayerData do
					-- print(Resources("Fmt")("Player: {}\n{}", Player.Name, Resources("Debug").TableToString(PlayerData, true, "PlayerData")))
					Length += 1
					if PlayerData.HasFinished then
						local DataStore = self.PlayerDataHandler:GetDataStore(Player)
						local CurrentTime = PlayerData.EndTime - PlayerData.StartTime

						DataStore:Update(function(CurrentData)
							if CurrentData.BestTime < CurrentTime then
								CurrentData.BestTime = CurrentTime
							end

							return CurrentData
						end)

						Entries[Length] = {
							Time = CurrentTime;
							Username = Player.Name;
						}
					else
						Entries[Length] = {
							Time = 60;
							Username = Player.Name;
						}
					end
				end

				GameEvent:FireAllClients(Constants.DISPLAY_LEADERBOARD, Entries)

				Promise_Delay(5):Then(function()
					GameEvent:FireAllClients(Constants.HIDE_LEADERBOARD)
					GameEvent:FireAllClients(Constants.DESPAWN_CHARACTER)
					return Promise_Delay(5)
				end):Then(function()
					GameEvent:FireAllClients(Constants.REMOUNT_UI) -- I WIN WOOOOOOOOOO
					return Promise_Delay(1)
				end):Then(function()
					self.GameInProgress.Value = false
				end)

				-- Promise.Delay(5):Wait()
				-- self.GameEvent:FireAllClients(Constants.HIDE_LEADERBOARD)
				-- Promise.Delay(5):Wait()
				-- self.GameEvent:FireAllClients(Constants.DESPAWN_CHARACTER)
				-- -- self.GameEvent:FireAllClients(Constants.SHOW_MENU)
				-- self.GameEvent:FireAllClients(Constants.REMOUNT_UI)
				-- Promise.Delay(1):Wait()
				-- self.GameInProgress.Value = false
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