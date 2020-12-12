local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

if RunService:IsServer() then
	return function(Name: string)
		return Promise.Resolve(Resources:GetRemoteFunction(Name))
	end
else
	return function(Name: string)
		return Promise.new(function(Resolve)
			Resolve(Resources:GetRemoteFunction(Name))
		end)
	end
end