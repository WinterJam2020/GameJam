local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")
local Services = Resources:LoadLibrary("Services")

if Services.RunService:IsServer() then
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