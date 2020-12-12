--- Executes code at a specific point in render step priority queue
-- @module OnRenderStepFrame

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

type Function = () -> nil

local function OnRenderStepFrame(Priority: number, Function: Function): Function
	local Key = HttpService:GenerateGUID(false) .. "OnRenderStepFrame"
	local Unbound = false

	RunService:BindToRenderStep(Key, Priority, function()
		if not Unbound then
			RunService:UnbindFromRenderStep(Key)
			Function()
		end
	end)

	return function()
		if not Unbound then
			RunService:UnbindFromRenderStep(Key)
			Unbound = true
		end
	end
end

return OnRenderStepFrame