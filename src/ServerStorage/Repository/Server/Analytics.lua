local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext") -- TODO: Use LogService

local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local CatchFactory = Resources:LoadLibrary("CatchFactory")
local Constants = Resources:LoadLibrary("Constants")
local Table = Resources:LoadLibrary("Table")

local Analytics = setmetatable({ClassName = "Analytics"}, BaseObject)
Analytics.__index = Analytics

Resources:LoadLibrary("PromiseRemoteEventMixin"):Add(Analytics, Constants.REMOTE_NAMES.ANALYTICS_REMOTE_EVENT_NAME, false)

function Analytics.new()
	local self = setmetatable(BaseObject.new(), Analytics)
	self.Category = "PlaceId-" .. tostring(game.PlaceId)

	self:PromiseRemoteEvent():Then(function(AnalyticsEvent: RemoteEvent)
		self.AnalyticsEvent = AnalyticsEvent
	end):Catch(CatchFactory("Analytics:PromiseRemoteEvent"))

	self.Janitor:Add(ScriptContext.Error:Connect(function(Message, StackTrace)
		self:Fire(Message, StackTrace)
	end), "Disconnect")

	return self
end

function Analytics:Fire(Message: string, StackTrace: string)
	local AnalyticsEvent = self.AnalyticsEvent
	if AnalyticsEvent then
		AnalyticsEvent:FireServer(
			self.Category,
			string.format("%s | %s", (string.gsub(Message, "Players%.[^.]+%.", "Players.<Player>.")), (string.gsub(StackTrace, "Players%.[^.]+%.", "Players.<Player>."))),
			"none", 1
		)
	end
end

return Table.Lock(Analytics, nil, script.Name)