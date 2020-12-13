local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local PromiseGetRemoteEvent = Resources:LoadLibrary("PromiseGetRemoteEvent")

local PromiseRemoteEventMixin = {}

function PromiseRemoteEventMixin:Add(Class, RemoteEventName: string)
	assert(not Class.PromiseRemoteEventMixin)
	assert(not Class.RemoteEventName)

	Class.PromiseRemoteEvent = self.PromiseRemoteEvent
	Class.RemoteEventName = RemoteEventName
end

function PromiseRemoteEventMixin:PromiseRemoteEvent()
	return self.Janitor:AddPromise(PromiseGetRemoteEvent(self.RemoteEventName))
end

return PromiseRemoteEventMixin