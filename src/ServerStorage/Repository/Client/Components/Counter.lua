local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local EventConnection = Resources:LoadLibrary("EventConnection")
local Roact = Resources:LoadLibrary("Roact")
local Services = Resources:LoadLibrary("Services")

local RunService: RunService = Services.RunService

local Counter = Roact.Component:extend("Counter")

local Roact_createElement = Roact.createElement
local Roact_createFragment = Roact.createFragment

function Counter:init()
	self.total, self.updateTotal = Roact.createBinding(0)

	self.heartbeat = function(delta)
		self.updateTotal(self.total:getValue() + delta)
	end
end

function Counter:render()
	return Roact_createFragment({
		Roact_createElement(EventConnection, {
			Event = RunService.Heartbeat,
			Function = self.heartbeat,
		}),

		self.props.Render(self.total),
	})
end

return Counter