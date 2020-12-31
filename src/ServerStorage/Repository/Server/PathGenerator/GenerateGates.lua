local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadLibrary("Constants")

local Gate = ServerStorage.Props.Gate

local PATH_WIDTH = Constants.SKI_PATH.PATH_WIDTH + 4
local NUM_GATES = Constants.SKI_PATH.NUM_GATES

local function generateGates(spline, container, rightOffset)
	for i = 0, NUM_GATES - 1 do
		local cf = spline:GetArcRotCFrame(i / (NUM_GATES - 1))
		local gate = Gate:Clone()
		gate.CFrame = cf * CFrame.new(rightOffset, 1.8, 0)
		gate.Parent = container
	end
end

return function(spline, parent)
	local container = Instance.new("Model")
	container.Name = "Gates"
	container.Parent = parent
	generateGates(spline, container, PATH_WIDTH / 2) -- right
	generateGates(spline, container, -PATH_WIDTH / 2) -- left
end