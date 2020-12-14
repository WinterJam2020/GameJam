local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local PromiseChild = Resources:LoadLibrary("PromiseChild")
local PromiseGetRemoteEvent = Resources:LoadLibrary("PromiseGetRemoteEvent")

local PromiseRemoteEventMixin = {}

function PromiseRemoteEventMixin:Add(Class, RemoteEventName: string, UsePromiseChild: boolean?)
	assert(not Class.PromiseRemoteEventMixin)
	assert(not Class.RemoteEventName)

	Class.PromiseRemoteEvent = self.PromiseRemoteEvent
	Class.UsePromiseChild = UsePromiseChild == nil and false or UsePromiseChild
	Class.RemoteEventName = RemoteEventName
end

function PromiseRemoteEventMixin:PromiseRemoteEvent()
	return self.Janitor:AddPromise(
		self.UsePromiseChild and PromiseChild(self.Object, self.RemoteEventName)
		or PromiseGetRemoteEvent(self.RemoteEventName)
	)
end

return PromiseRemoteEventMixin