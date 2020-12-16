local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local EventConnection = Roact.Component:extend("EventConnection")

function EventConnection:init()
	self.connection = nil
end

function EventConnection:didMount()
	self.connection = self.props.Event:Connect(self.props.Function)
end

function EventConnection.render()
	return nil
end

function EventConnection:didUpdate(oldProps)
	if self.props.Event ~= oldProps.Event or self.props.Function ~= oldProps.Function then
		self.connection:Disconnect()
		self.connection = self.props.Event:Connect(self.props.Function)
	end
end

function EventConnection:willUnmount()
	if self.connection then
		self.connection:Disconnect()
	end

	self.connection = nil
end

return EventConnection