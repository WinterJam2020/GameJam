local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Debug = Resources:LoadLibrary("Debug")
local Table = Resources:LoadLibrary("Table")
local Typer = Resources:LoadLibrary("Typer")
local WeakInstanceTable = Resources:LoadLibrary("WeakInstanceTable")

local NetworkOwnerService = {}

local SERVER_FLAG = "Server"
local WEAK_KEY_VALUE = {__mode = "kv"}

local Table_FastRemove = Table.FastRemove

function NetworkOwnerService:Initialize()
	-- self.PartOwnerData = setmetatable({}, {__mode = "k"})
	self.PartOwnerData = WeakInstanceTable()
	return self
end

local function AddOwnerData(self, BasePart: BasePart, Data)
	local OwnerDataStack = self.PartOwnerData[BasePart]
	if not OwnerDataStack then
		OwnerDataStack = setmetatable({}, WEAK_KEY_VALUE)
		self.PartOwnerData[BasePart] = OwnerDataStack
	end

	if #OwnerDataStack > 5 then
		Debug.Warn("[NetworkOwnerService] - Possibly a memory leak, lots of owners")
	end

	table.insert(OwnerDataStack, Data)
end

local function UpdateOwner(self, BasePart: BasePart)
	local OwnerDataStack = self.PartOwnerData[BasePart]
	if not OwnerDataStack then
		local CanSet, Error = BasePart:CanSetNetworkOwnership()
		if not CanSet then
			return Debug.Warn("[NetworkOwnerService] - Cannot set network ownership: %s (%s)", Error, BasePart)
		else
			return BasePart:SetNetworkOwnershipAuto()
		end
	else
		local Player = OwnerDataStack[#OwnerDataStack].Player
		if Player == SERVER_FLAG then
			Player = nil
		end

		local CanSet, Error = BasePart:CanSetNetworkOwnership()
		if not CanSet then
			return Debug.Warn("[NetworkOwnerService] - Cannot set network ownership: %s (%s)", Error, BasePart)
		else
			return BasePart:SetNetworkOwner(Player)
		end
	end
end

function NetworkOwnerService:_removeOwner(part, toRemove)
	local ownerDataStack = self._partOwnerData[part]
	if not ownerDataStack then
		warn("[NetworkOwnerService] - No data for part")
		return false
	end

	for index, item in pairs(ownerDataStack) do
		if item == toRemove then
			table.remove(ownerDataStack, index)

			if #ownerDataStack == 0 then
				self._partOwnerData[part] = nil
			end

			return true
		end
	end

	return false
end

local function RemoveOwner(self, BasePart: BasePart, ToRemove)
	local OwnerDataStack = self.PartOwnerData[BasePart]
	if not OwnerDataStack then
		Debug.Warn("[NetworkOwnerService] - No data for %s!", BasePart)
		return false
	else
		local Index = table.find(OwnerDataStack, ToRemove)
		if Index then
			Table_FastRemove(OwnerDataStack, Index)
			if #OwnerDataStack == 0 then
				self.PartOwnerData[BasePart] = nil
			end

			return true
		end

		return false
	end
end

NetworkOwnerService.AddSetNetworkOwnerHandle = Typer.AssignSignature(2, Typer.InstanceWhichIsABasePart, Typer.OptionalInstanceWhichIsAPlayer, function(self, BasePart: BasePart, Player: Player?)
	if not self.PartOwnerData then
		Debug.Error("NetworkOwnerService has not been initialized!")
	end

	local Data = {Player = Player or SERVER_FLAG}
	AddOwnerData(self, BasePart, Data)
	UpdateOwner(self, BasePart)

	return function()
		if not RemoveOwner(self, BasePart, Data) then
			Debug.Warn("[NetworkOwnerService] - Failed to remove owner data.")
		else
			UpdateOwner(self, BasePart)
		end
	end
end)

return NetworkOwnerService