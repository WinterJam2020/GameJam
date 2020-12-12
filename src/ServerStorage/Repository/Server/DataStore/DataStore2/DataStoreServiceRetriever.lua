-- This function is monkey patched to return MockDataStoreService during tests
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local DataStoreService = Resources:LoadLibrary("DataStoreService")

local DataStoreServiceRetriever = {}

function DataStoreServiceRetriever.Get()
	return DataStoreService
end

return DataStoreServiceRetriever
