local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local DataStore2 = Resources:LoadLibrary("DataStore2")
local GetTimeString = Resources:LoadLibrary("GetTimeString")
local Promise = Resources:LoadLibrary("Promise")
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local Services = Resources:LoadLibrary("Services")

local Players: Players = Services.Players
local CollectionService: CollectionService = Services.CollectionService
local RunService: RunService = Services.RunService

local PlayerDataHandler = {}

local TIME_STRING = "Best Time " .. utf8.char(9202)
local POINTS_STRING = "Points " .. utf8.char(127894)

type PlayerData = {
	BestTime: number,
	Points: number,
	SkiColor: string,
}

local DEFAULT_PLAYER_DATA: PlayerData = {
	BestTime = 0;
	Points = 0;
	SkiColor = "Blue";
}

function PlayerDataHandler:Initialize()
	DataStore2.Combine(
		"WinterGame" .. (RunService:IsStudio() and "Build" or "Release"),
		"GameData"
	)

	local function PlayerAdded(Player: Player)
		CollectionService:AddTag(Player, "PlayerDataConnected")
		local GameData = DataStore2.new("GameData", Player)

		PromiseChild(Player, "PlayerGui", 5):Then(function(PlayerGui: PlayerGui)
			local MainGui = Instance.new("ScreenGui")
			MainGui.Name = "MainGui"
			MainGui.Parent = PlayerGui
		end):Catch(CatchFactory("PromiseChild"))

		GameData:GetTableAsync(DEFAULT_PLAYER_DATA):Then(function(PlayerData: PlayerData)
			if Player:IsDescendantOf(Players) then
				local Leaderstats = Instance.new("Folder")
				Leaderstats.Name = "leaderstats"

				local Configuration = Instance.new("Folder")
				Configuration.Name = "Configuration"

				local BestTime = Instance.new("StringValue")
				BestTime.Name = TIME_STRING
				BestTime.Value = GetTimeString(PlayerData.BestTime)
				BestTime.Parent = Leaderstats

				local Points = Instance.new("IntValue")
				Points.Name = POINTS_STRING
				Points.Value = PlayerData.Points
				Points.Parent = Leaderstats

				local SkiColor = Instance.new("StringValue")
				SkiColor.Name = "SkiColor"
				SkiColor.Value = PlayerData.SkiColor
				SkiColor.Parent = Configuration

				Configuration.Parent = Leaderstats
				Leaderstats.Parent = Player
			end
		end):Catch(CatchFactory("SavedPlayerData:GetTableAsync")):Finally(function()
			if Player:IsDescendantOf(Players) then
				PromiseChild(Player, "leaderstats", 5):Then(function(Leaderstats: Folder)
					local Array = table.create(3)
					Array[1], Array[2], Array[3] = PromiseChild(Leaderstats, TIME_STRING, 5), PromiseChild(Leaderstats, POINTS_STRING, 5), PromiseChild(Leaderstats, "Configuration", 5)

					Promise.All(Array):Spread(function(BestTime: StringValue, Points: IntValue, Configuration: Folder)
						PromiseChild(Configuration, "SkiColor", 5):Then(function(SkiColor: StringValue)
							local PlayerDataMap = {
								BestTime = function(CurrentValue: number)
									BestTime.Value = GetTimeString(CurrentValue)
								end;

								Points = function(CurrentValue: number)
									Points.Value = CurrentValue
								end;

								SkiColor = function(CurrentValue: string)
									SkiColor.Value = CurrentValue
								end;
							}

							GameData:OnUpdate(function(PlayerData: PlayerData)
								for StatName, StatValue in next, PlayerData do
									PlayerDataMap[StatName](StatValue)
								end
							end)
						end):Catch(CatchFactory("PromiseChild"))
					end):Catch(CatchFactory("Promise.All"))
				end):Catch(CatchFactory("PromiseChild"))
			end
		end)
	end

	Players.PlayerAdded:Connect(PlayerAdded)
	for _, Player in ipairs(Players:GetPlayers()) do
		if not CollectionService:HasTag(Player, "PlayerDataConnected") then
			PlayerAdded(Player)
		end
	end

	return self
end

function PlayerDataHandler:GetDataStore(Player: Player)
	return DataStore2("GameData", Player)
end

return PlayerDataHandler