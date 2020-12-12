--- Provides a basis for binders that can be retrieved anywhere
-- @classmod BinderProvider

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local BinderProvider = {ClassName = "BinderProvider"}
BinderProvider.__index = BinderProvider

function BinderProvider.new(InitializeMethod)
	return setmetatable({
		BindersAddedPromise = Promise.new();
		AfterInitPromise = Promise.new();

		_initMethod = InitializeMethod or error("No initMethod");
		_afterInit = false;
		_binders = {};
	}, BinderProvider)
end

function BinderProvider:PromiseBinder(BinderName)
	if self.BindersAddedPromise:GetStatus() == Promise.Status.Resolved then
		local Binder = self:Get(BinderName)
		if Binder then
			return Promise.Resolve(Binder)
		else
			return Promise.Reject()
		end
	end

	return self.BindersAddedPromise:Then(function()
		local Binder = self:Get(BinderName)
		if Binder then
			return Binder
		else
			return Promise.Reject()
		end
	end)
end

function BinderProvider:Init()
	self:_initMethod(self)
	self.BindersAddedPromise:Resolve()
end

function BinderProvider:AfterInit()
	self._afterInit = true
	for _, Binder in ipairs(self._binders) do
		Binder:Init()
	end

	self.AfterInitPromise:Resolve()
end

function BinderProvider:__index(Index)
	if BinderProvider[Index] then
		return BinderProvider[Index]
	end

	error(string.format("%q Not a valid index", tostring(Index)))
end

function BinderProvider:Get(TagName)
	assert(type(TagName) == "string", "tagName must be a string")
	return rawget(self, TagName)
end

function BinderProvider:Add(Binder)
	assert(not self._afterInit, "Already inited")
	assert(not self:Get(Binder:GetTag()))

	table.insert(self._binders, Binder)
	self[Binder:GetTag()] = Binder
end

return BinderProvider