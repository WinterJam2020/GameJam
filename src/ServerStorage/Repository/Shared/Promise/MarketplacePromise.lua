local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local MarketplacePromise = {}

function MarketplacePromise.PromiseUserOwnsGamePass(PlayerOrUserId, GamePassId)
	local UserId = type(PlayerOrUserId) == "number" and PlayerOrUserId or PlayerOrUserId.UserId
	return Promise.Defer(function(Resolve, Reject)
		local Success, Value = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, UserId, GamePassId);
		(Success and Resolve or Reject)(Value)
	end)
end

function MarketplacePromise.PromiseUserOwnsGamePassAsync(PlayerOrUserId, GamePassId)
	local UserId = type(PlayerOrUserId) == "number" and PlayerOrUserId or PlayerOrUserId.UserId
	return Promise.new(function(Resolve, Reject)
		local Success, Value = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, UserId, GamePassId);
		(Success and Resolve or Reject)(Value)
	end)
end

function MarketplacePromise.PromisePlayerOwnsAsset(Player, AssetId)
	return Promise.Defer(function(Resolve, Reject)
		local Success, Value = pcall(MarketplaceService.PlayerOwnsAsset, MarketplaceService, Player, AssetId);
		(Success and Resolve or Reject)(Value)
	end)
end

return MarketplacePromise