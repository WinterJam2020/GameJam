local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Constants = Resources:LoadLibrary("Constants")
local Table = Resources:LoadLibrary("Table")

local Analytics = setmetatable({ClassName = "Analytics"}, BaseObject)
Analytics.__index = Analytics

Resources:LoadLibrary("PromiseRemoteEventMixin"):Add(Analytics, Constants.REMOTE_NAMES.ANALYTICS_REMOTE_EVENT_NAME)

function Analytics.new()
	local self = setmetatable(BaseObject.new(), Analytics)
	self.Category = "PlaceId-" .. tostring(game.PlaceId)

	self:PromiseRemoteEvent():Then(function(AnalyticsEvent: RemoteEvent)
		self.AnalyticsEvent = AnalyticsEvent
	end):Catch(CatchFactory("Analytics:PromiseRemoteEvent"))

	self.Janitor:Add(function() end, true)

	return self
end

local function NewLineToVertical(Stack: string): string
	local NewStack = ""
	local First = true
	for Line in string.gmatch(Stack, "[^\r\n]+") do
		if First then
			NewStack = Line
			First = false
		else
			NewStack ..= " | " .. Line
		end
	end

	return NewStack
end

function Analytics:Fire()
end

return Table.Lock(Analytics, nil, script.Name)