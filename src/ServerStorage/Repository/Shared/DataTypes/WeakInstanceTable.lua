local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Typer = Resources:LoadLibrary("Typer")

local WeakInstanceTable = {
	ClassName = "WeakInstanceTable";
	__newindex = Typer.AssignSignature(2, Typer.Instance, Typer.Any, function(self, Index, Value)
		if not Index:IsDescendantOf(game) then
			error("Index is not a descendant of the DataModel.", 2)
		end

		rawset(self, Index, Value)
		Index.AncestryChanged:Connect(function()
			if not Index:IsDescendantOf(game) then
				rawset(self, Index, nil)
			end
		end)
	end);

	-- __newindex = function(self, Index, Value)
	-- 	local TypeSuccess, TypeError = t.Instance(Index)
	-- 	if not TypeSuccess then
	-- 		error(TypeError, 2)
	-- 	end

	-- 	if not Index:IsDescendantOf(game) then
	-- 		error("Index is not a descendant of the DataModel.", 2)
	-- 	end

	-- 	rawset(self, Index, Value)
	-- 	Index.AncestryChanged:Connect(function()
	-- 		if not Index:IsDescendantOf(game) then
	-- 			rawset(self, Index, nil)
	-- 		end
	-- 	end)
	-- end;

	__tostring = function(self)
		return self.ClassName
	end;
}

return function()
	return setmetatable({}, WeakInstanceTable)
end