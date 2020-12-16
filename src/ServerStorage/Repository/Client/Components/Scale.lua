-- CREDIT: https://devforum.roblox.com/t/what-is-a-good-method-to-properly-scaling-ui/218157/4?u=kampfkarren

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Resources = require(ReplicatedStorage.Resources)
local Roact = Resources:LoadLibrary("Roact")

local CurrentCamera = Workspace.CurrentCamera
local TopInset, BottomInset = GuiService:GetGuiInset()

local Scale = Roact.PureComponent:extend("Scale")
Scale.defaultProps = {
	Scale = 1,
}

function Scale:init()
	self:Update()

	self.listener = CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		self:Update()
	end)
end

function Scale:Update()
	local currentSize = self.props.Size
	local viewportSize = CurrentCamera.ViewportSize - (TopInset + BottomInset)

	self:setState({
		scale = 1 / math.max(
			currentSize.X / viewportSize.X,
			currentSize.Y / viewportSize.Y
		),
	})
end

function Scale:willUnmount()
	self.listener:Disconnect()
end

function Scale:render()
	return Roact.createElement("UIScale", {
		Scale = self.state.scale * self.props.Scale,
	})
end

return Scale