local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local AutomatedScrollingFrame = Resources:LoadLibrary("AutomatedScrollingFrame")
local Roact = Resources:LoadLibrary("Roact")
local Table = Resources:LoadLibrary("Table")

local AutomatedScrollingFrameComponent = Roact.PureComponent:extend("AutomatedScrollingFrameComponent")

function AutomatedScrollingFrameComponent:init(props)
	self.ref = props[Roact.Ref] or Roact.createRef()
end

function AutomatedScrollingFrameComponent:render()
	local props = Table.Copy(self.props)
	props.UIGridStyleLayout = nil
	props[Roact.Ref] = self.ref
	return Roact.createElement("ScrollingFrame", props)
end

function AutomatedScrollingFrameComponent:didMount()
	local UIGridStyleLayout
	if self.props.UIGridStyleLayout then
		UIGridStyleLayout = self.props.UIGridStyleLayout:getValue()
	end

	self.connection = AutomatedScrollingFrame(self.ref:getValue(), UIGridStyleLayout)
end

function AutomatedScrollingFrameComponent:willUnmount()
	self.connection:Disconnect()
end

return AutomatedScrollingFrameComponent