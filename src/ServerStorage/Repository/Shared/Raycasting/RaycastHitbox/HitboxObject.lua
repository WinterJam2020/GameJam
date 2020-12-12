local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Resources = require(ReplicatedStorage.Resources)
local BaseObject = Resources:LoadLibrary("BaseObject")
local Signal = Resources:LoadLibrary("Signal")
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

local COLLECTION_TAG = "RaycastEnabled"

local HitboxObject = setmetatable({ClassName = "HitboxObject"}, BaseObject)
HitboxObject.__index = HitboxObject

local IsAnAttachment = t.instanceIsA("Attachment")
local IsABasePart = t.instanceIsA("BasePart")

local ConstructorTuple = t.tuple(IsABasePart, t.optional(t.array(t.Instance)))
local SetPointsTuple = t.tuple(IsABasePart, t.array(t.Vector3))
local LinkAttachmentsTuple = t.tuple(IsAnAttachment, IsAnAttachment)

function HitboxObject.new(Object: BasePart, IgnoreList)
	assert(ConstructorTuple(Object, IgnoreList))

	local self = setmetatable(BaseObject.new(Object), HitboxObject)
	self.OnHit = self.Janitor:Add(Signal.new(), "Destroy")
	self.Janitor:Add(self.Object.AncestryChanged:Connect(function()
		if not Workspace:IsAncestorOf(self.Object) and not Players:IsAncestorOf(self.Object) then
			self:Destroy()
		end
	end), "Disconnect", "AncestryChanged")

	self.Active = false
	self.Destroyed = false
	self.PartMode = false
	self.DebugMode = false
	self.Points = {}
	self.TargetsHit = {}

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	self.RaycastParams.FilterDescendantsInstances = IgnoreList or {}

	self.Janitor:Add(function()
		CollectionService:RemoveTag(self.Object, COLLECTION_TAG)
		self.Destroyed = true
		self.Active = false
	end, true)

	return self
end

function HitboxObject:Configure(Object: BasePart, IgnoreList)
	self.Janitor:Remove("AncestryChanged")
	self.Object = Object
	self.Janitor:Add(self.Object.AncestryChanged:Connect(function()
		if not Workspace:IsAncestorOf(self.Object) and not Players:IsAncestorOf(self.Object) then
			self:Destroy()
		end
	end), "Disconnect", "AncestryChanged")

	self.RaycastParams.FilterDescendantsInstances = IgnoreList or {}
	return self
end

function HitboxObject:SetPoints(Object: BasePart, VectorPoints)
	local TypeSuccess, TypeError = SetPointsTuple(Object, VectorPoints)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Points = self.Points
	local Length = #Points
	for _, Vector in ipairs(VectorPoints) do
		Length += 1
		Points[Length] = {
			RelativePart = Object;
			Attachment = Vector;
			LastPosition = nil;
		}
	end
end

function HitboxObject:RemovePoints(Object: BasePart, VectorPoints)
	local TypeSuccess, TypeError = SetPointsTuple(Object, VectorPoints)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Points = self.Points
	for Index, Point in ipairs(Points) do
		local Attachment: Vector3 = Point.Attachment
		local RelativePart: BasePart = Point.RelativePart

		for _, Vector in ipairs(VectorPoints) do
			if Attachment == Vector and RelativePart == Object then
				Points[Index] = nil
			end
		end
	end
end

function HitboxObject:LinkAttachments(PrimaryAttachment: Attachment, SecondaryAttachment: Attachment)
	local TypeSuccess, TypeError = LinkAttachmentsTuple(PrimaryAttachment, SecondaryAttachment)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	table.insert(self.Points, {
		RelativePart = nil;
		Attachment = PrimaryAttachment;
		Attachment0 = SecondaryAttachment;
		LastPosition = nil;
	})
end

function HitboxObject:UnlinkAttachments(PrimaryAttachment: Attachment)
	local TypeSuccess, TypeError = IsAnAttachment(PrimaryAttachment)
	if not TypeSuccess then
		error(TypeError, 2)
	end

	local Points = self.Points
	for Index, Point in ipairs(Points) do
		if Point.Attachment == PrimaryAttachment then
			Table.FastRemove(Points, Index)
			break
		end
	end
end

function HitboxObject:SeekAttachments(AttachmentName, CanWarn)
	local Points = self.Points
	local Length = #Points

	if Length == 0 then
		local FilterDescendantsInstances = self.RaycastParams.FilterDescendantsInstances
		table.insert(FilterDescendantsInstances, Workspace.Terrain)
		self.RaycastParams.FilterDescendantsInstances = FilterDescendantsInstances
	end

	for _, Descendant in ipairs(self.Object:GetDescendants()) do
		if Descendant:IsA("Attachment") and Descendant.Name == AttachmentName then
			Length += 1
			Points[Length] = {
				Attachment = Descendant;
				RelativePart = nil;
				LastPosition = nil;
			}
		end
	end

	if CanWarn then
		if Length == 0 then
			warn(string.format("\n[[RAYCAST WARNING]]\nNo attachments with the name %q were found in %s. No raycasts will be drawn. Can be ignored if you are using SetPoints.", AttachmentName, self.Object.Name))
		else
			print(string.format("\n[[RAYCAST MESSAGE]]\n\nCreated Hitbox for %s - Attachments found: %d", self.Object.Name, Length))
		end
	end
end

function HitboxObject:Start()
	CollectionService:AddTag(self.Object, COLLECTION_TAG)
	self.Active = true
	return self
end

function HitboxObject:Stop()
	CollectionService:RemoveTag(self.Object, COLLECTION_TAG)
	for _, Point in ipairs(self.Points) do
		Point.LastPosition = nil
	end

	self.Active = false
	self.TargetsHit = {}
	return self
end

return HitboxObject