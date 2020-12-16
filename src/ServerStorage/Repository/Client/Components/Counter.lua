local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local EventConnection = Resources:LoadLibrary("EventConnection")
local Roact = Resources:LoadLibrary("Roact")

local Counter = Roact.Component:extend("Counter")

function Counter:init()
	self.total, self.updateTotal = Roact.createBinding(0)

	self.heartbeat = function(delta)
		self.updateTotal(self.total:getValue() + delta)
	end
end

function Counter:render()
	return Roact.createFragment({
		Roact.createElement(EventConnection, {
			Event = RunService.Heartbeat,
			Function = self.heartbeat,
		}),

		self.props.Render(self.total),
	})
end

return Counter