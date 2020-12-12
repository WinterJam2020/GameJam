local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local MarketplacePromise = Resources:LoadLibrary("MarketplacePromise")
local Promise = Resources:LoadLibrary("Promise")
local WeakInstanceTable = Resources:LoadLibrary("WeakInstanceTable")

local FreeGamePasses = (function()
	local BoolValue = ReplicatedStorage:FindFirstChild("FreeGamePasses")
	return BoolValue and BoolValue.Value and RunService:IsStudio()
end)()

local BoughtGamePasses = WeakInstanceTable()
local BoughtPassUpdated = WeakInstanceTable()
local ListeningPasses = {}

local GamePasses = {}

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player, GamePassId, WasPurchased)
	if WasPurchased then
		BoughtGamePasses[Player] = BoughtGamePasses[Player] or {}
		BoughtGamePasses[Player][GamePassId] = true
		GamePasses.BoughtPassUpdated(Player):Fire()
	end
end)

function GamePasses.ListenForPass(GamePassId)
	if not ListeningPasses[GamePassId] then
		ListeningPasses[GamePassId] = true

		local function CheckGamePassOwnership(Player)
			BoughtGamePasses[Player] = BoughtGamePasses[Player] or {}
			MarketplacePromise.PromiseUserOwnsGamePass(Player.UserId, GamePassId):Then(function(Value)
				BoughtGamePasses[Player][GamePassId] = Value
			end):Catch(CatchFactory("MarketplacePromise.PromiseUserOwnsGamePass")):Finally(function()
				GamePasses.BoughtPassUpdated(Player):Fire()
			end)
		end

		if RunService:IsServer() then
			Players.PlayerAdded:Connect(CheckGamePassOwnership)
			for _, Player in ipairs(Players:GetPlayers()) do
				CheckGamePassOwnership(Player)
			end
		else
			CheckGamePassOwnership(Players.LocalPlayer)
		end
	end
end

function GamePasses.PlayerOwnsPass(Player, GamePassId)
	BoughtGamePasses[Player] = BoughtGamePasses[Player] or {}
	return FreeGamePasses or not not BoughtGamePasses[Player][GamePassId]
end

function GamePasses.BoughtPassUpdated(Player)
	Player = Player or Players.LocalPlayer
	local BindableEvent = BoughtPassUpdated[Player]
	if not BindableEvent then
		BindableEvent = Instance.new("BindableEvent")
		BoughtPassUpdated[Player] = BindableEvent
	end

	return BindableEvent
end

function GamePasses.PlayerOwnsPassAsync(Player, GamePassId)
	BoughtGamePasses[Player] = BoughtGamePasses[Player] or {}
	return Promise.Promisify(function()
		while BoughtGamePasses[Player][GamePassId] == nil do
			GamePasses.BoughtPassUpdated(Player).Event:Wait()
		end

		return GamePasses.PlayerOwnsPass(Player, GamePassId)
	end)()
end

return GamePasses