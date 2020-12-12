local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local Debug = Resources:LoadLibrary("Debug")
local Table = Resources:LoadLibrary("Table")
local Typer = Resources:LoadLibrary("Typer")

local PartCache = setmetatable({ClassName = "PartCache"}, BaseObject)
PartCache.__index = PartCache

local CF_REALLY_FAR_AWAY = CFrame.new(0, 10E8, 0)
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

local function AssertWarn(Success, Message)
	if not Success then
		warn(Message or "Assertion failed!")
	end
end

local function MakeFromTemplate(Template, CurrentCacheParent)
	local NewPart = Template:Clone()
	NewPart.CFrame = CF_REALLY_FAR_AWAY
	NewPart.Anchored = true
	NewPart.Parent = CurrentCacheParent
	return NewPart
end

-- local ConstructorTuple = t.tuple(
-- 	t.instanceIsA("BasePart"),
-- 	t.optional(t.intersection(t.integer, t.numberPositive)),
-- 	t.optional(t.Instance)
-- )

PartCache.new = Typer.AssignSignature(Typer.InstanceWhichIsABasePart, Typer.OptionalPositiveInteger, Typer.OptionalInstance, function(Template, PrecreatedParts, CurrentCacheParent)
	PrecreatedParts = PrecreatedParts or 5
	CurrentCacheParent = CurrentCacheParent or Workspace

	AssertWarn(PrecreatedParts ~= 0, "PrecreatedParts is 0! This may have adverse effects when initially using the cache.")
	AssertWarn(Template.Archivable, "The template's Archivable property has been set to false, which prevents it from being cloned. It will temporarily be set to true.")

	local OldArchivable = Template.Archivable
	Template.Archivable = true

	local NewTemplate = Template:Clone()
	Template.Archivable = OldArchivable
	Template = NewTemplate

	local self = setmetatable(BaseObject.new(Template), PartCache)
	self.Open = table.create(PrecreatedParts)
	self.InUse = {}
	self.CurrentCacheParent = CurrentCacheParent
	self.ExpansionSize = 10

	for Index = 1, PrecreatedParts do
		self.Open[Index] = MakeFromTemplate(Template, CurrentCacheParent)
	end

	self.Janitor:Add(self.Object, "Destroy")
	self.Janitor:Add(function()
		for Index, Object in ipairs(self.Open) do
			self.Open[Index] = Object:Destroy()
		end

		for Index, Object in ipairs(self.InUse) do
			self.InUse[Index] = Object:Destroy()
		end
	end, true)

	self.Object.Parent = nil
	return self
end)

function PartCache:GetPart(): BasePart
	if getmetatable(self) ~= PartCache then
		Debug.Error(ERR_NOT_INSTANCE, "GetPart", "PartCache.new")
	end

	if #self.Open == 0 then
		warn("No parts available in the cache! Creating [" .. self.ExpansionSize .. "] new part instance(s) - this amount can be edited by changing the ExpansionSize property of the PartCache instance... (This cache now contains a grand total of " .. tostring(#self.Open + #self.InUse + self.ExpansionSize) .. " parts.)")
		for Index = 1, self.ExpansionSize do
			self.Open[Index] = MakeFromTemplate(self.Object, self.CurrentCacheParent)
		end
	end

	local Part = table.remove(self.Open)
	table.insert(self.InUse, Part)
	return Part
end

PartCache.ReturnPart = Typer.AssignSignature(2, Typer.InstanceWhichIsABasePart, function(self, Part: BasePart)
	if getmetatable(self) ~= PartCache then
		Debug.Error(ERR_NOT_INSTANCE, "ReturnPart", "PartCache.new")
	end

	local Index = table.find(self.InUse, Part)
	if Index then
		Table.FastRemove(self.InUse, Index)
		table.insert(self.Open, Part)
		Part.CFrame = CF_REALLY_FAR_AWAY
		Part.Anchored = true
	else
		error("Attempted to return part \"" .. Part.Name .. "\" (" .. Part:GetFullName() .. ") to the cache, but it's not in-use! Did you call this on the wrong part?")
	end
end)

local function IsValidParent(Value, TypeOfString)
	return TypeOfString == "Instance" and (Value:IsDescendantOf(Workspace) or Value == Workspace)
end

PartCache.SetCacheParent = Typer.AssignSignature(2, {IsValidParent = IsValidParent}, function(self, NewParent)
	if getmetatable(self) ~= PartCache then
		Debug.Error(ERR_NOT_INSTANCE, "SetCacheParent", "PartCache.new")
	end

	self.CurrentCacheParent = NewParent
	for _, Object in ipairs(self.Open) do
		Object.Parent = NewParent
	end

	for _, Object in ipairs(self.InUse) do
		Object.Parent = NewParent
	end
end)

PartCache.Expand = Typer.AssignSignature(2, Typer.OptionalInteger, function(self, ExpandBy)
	if getmetatable(self) ~= PartCache then
		Debug.Error(ERR_NOT_INSTANCE, "Expand", "PartCache.new")
	end

	ExpandBy = ExpandBy == nil and self.ExpansionSize or ExpandBy
	for Index = 1, ExpandBy do
		self.Open[Index] = MakeFromTemplate(self.Object, self.CurrentCacheParent)
	end
end)

return PartCache