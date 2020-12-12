local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Promise = Resources:LoadLibrary("Promise")

local function PromiseChild(Parent, ChildName, Timeout)
	return Promise.new(function(Resolve, Reject, OnCancel)
		local Child = Parent:FindFirstChild(ChildName)
		if Child then
			Resolve(Child)
		else
			local Offset = Timeout or 5
			local StartTime = time()
			local Cancelled = false
			local Connection

			OnCancel(function()
				Cancelled = true
				if Connection then
					Connection = Connection:Disconnect()
				end

				return Reject("PromiseChild(" .. Parent:GetFullName() .. ", \"" .. tostring(ChildName) .. "\") was cancelled.")
			end)

			Connection = Parent:GetPropertyChangedSignal("Parent"):Connect(function()
				if not Parent.Parent then
					if Connection then
						Connection = Connection:Disconnect()
					end

					Cancelled = true
					return Reject("PromiseChild(" .. Parent:GetFullName() .. ", \"" .. tostring(ChildName) .. "\") was cancelled.")
				end
			end)

			repeat
				Promise.Delay(0.03):Wait()
				Child = Parent:FindFirstChild(ChildName)
			until Child or StartTime + Offset < time() or Cancelled

			if Connection then
				Connection:Disconnect()
			end

			if not Timeout then
				Reject("Infinite yield possible for PromiseChild(" .. Parent:GetFullName() .. ", \"" .. tostring(ChildName) .. "\")")
			elseif Child then
				Resolve(Child)
			end
		end
	end)
end

return PromiseChild