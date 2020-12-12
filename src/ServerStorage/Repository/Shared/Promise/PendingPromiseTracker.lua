local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local PendingPromiseTracker = {ClassName = "PendingPromiseTracker"}
PendingPromiseTracker.__index = PendingPromiseTracker

function PendingPromiseTracker.new()
	return setmetatable({PendingPromises = {}}, PendingPromiseTracker)
end

function PendingPromiseTracker:Add(PendingPromise)
	if PendingPromise:GetStatus() == Promise.Status.Started then
		self.PendingPromises[PendingPromise] = true
		PendingPromise:Finally(function()
			self.PendingPromises[PendingPromise] = nil
		end)
	end
end

function PendingPromiseTracker:GetAll()
	local PendingPromises = {}
	local Length = 0
	for PendingPromise in next, self.PendingPromises do
		Length += 1
		PendingPromises[Length] = PendingPromise
	end

	return PendingPromises
end

return PendingPromiseTracker