-- Rotated Region3
-- EgoMoose
-- December 1, 2020

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CreateGJK = require(script.CreateGJK)
local Supports = require(script.Supports)
local Vertices = require(script.Vertices)

local RotatedRegion3 = {ClassName = "RotatedRegion3"}
RotatedRegion3.__index = RotatedRegion3

type Map<Index, Value> = {[Index]: Value}
type Array<Value> = Map<number, Value>

local function WorldBoundingBox(Set: Array<Vector3>): (Vector3, Vector3)
	local MinX, MinY, MinZ = math.huge, math.huge, math.huge
	local MaxX, MaxY, MaxZ = -math.huge, -math.huge, -math.huge

	for _, Vector in ipairs(Set) do
		local X, Y, Z = Vector.X, Vector.Y, Vector.Z

		if X < MinX then
			MinX = X
		end

		if X > MaxX then
			MaxX = X
		end

		if Y < MinY then
			MinY = Y
		end

		if Y > MaxY then
			MaxY = Y
		end

		if Z < MinZ then
			MinZ = Z
		end

		if Z > MaxZ then
			MaxZ = Z
		end
	end

	return Vector3.new(MinX, MinY, MinZ), Vector3.new(MaxX, MaxY, MaxZ)
end

function RotatedRegion3.new(CoordinateFrame: CFrame, Size: Vector3)
	local Set = Vertices.Block(CoordinateFrame, Size / 2)
	return setmetatable({
		AlignedRegion3 = Region3.new(WorldBoundingBox(Set));
		Centroid = CoordinateFrame.Position;
		CFrame = CoordinateFrame;
		Set = Set;
		Shape = "Block";
		Size = Size;
		Support = Supports.PointCloud;
	}, RotatedRegion3)
end

RotatedRegion3.Block = RotatedRegion3.new

function RotatedRegion3.Wedge(CoordinateFrame: CFrame, Size: Vector3)
	local Set = Vertices.Wedge(CoordinateFrame, Size / 2)
	return setmetatable({
		AlignedRegion3 = Region3.new(WorldBoundingBox(Vertices.Block(CoordinateFrame, Size / 2)));
		Centroid = Vertices.GetCentroid(Set);
		CFrame = CoordinateFrame;
		Set = Set;
		Shape = "Wedge";
		Size = Size;
		Support = Supports.PointCloud;
	}, RotatedRegion3)
end

function RotatedRegion3.CornerWedge(CoordinateFrame: CFrame, Size: Vector3)
	local Set = Vertices.CornerWedge(CoordinateFrame, Size / 2)
	return setmetatable({
		AlignedRegion3 = Region3.new(WorldBoundingBox(Vertices.Block(CoordinateFrame, Size / 2)));
		Centroid = Vertices.GetCentroid(Set);
		CFrame = CoordinateFrame;
		Set = Set;
		Shape = "CornerWedge";
		Size = Size;
		Support = Supports.PointCloud;
	}, RotatedRegion3)
end

local function GetCorners(CoordinateFrame: CFrame, HalfSize: Vector3): Array<Vector3>
	local X, Y, Z = HalfSize.X, HalfSize.Y, HalfSize.Z
	local Array: Array<Vector3> = table.create(8)
	Array[1] = CoordinateFrame:PointToWorldSpace(Vector3.new(-X, Y, Z))
	Array[2] = CoordinateFrame:PointToWorldSpace(Vector3.new(-X, -Y, Z))
	Array[3] = CoordinateFrame:PointToWorldSpace(Vector3.new(-X, -Y, -Z))
	Array[4] = CoordinateFrame:PointToWorldSpace(Vector3.new(X, -Y, -Z))
	Array[5] = CoordinateFrame:PointToWorldSpace(Vector3.new(X, Y, -Z))
	Array[6] = CoordinateFrame:PointToWorldSpace(HalfSize)
	Array[7] = CoordinateFrame:PointToWorldSpace(Vector3.new(X, -Y, Z))
	Array[8] = CoordinateFrame:PointToWorldSpace(Vector3.new(-X, Y, -Z))

	return Array
end

function RotatedRegion3.Cylinder(CoordinateFrame: CFrame, Size: Vector3)
	local HalfSize: Vector3 = Size / 2
	local Set = table.create(2, CoordinateFrame)
	Set[2] = HalfSize

	return setmetatable({
		CFrame = CoordinateFrame;
		Size = Size;
		Shape = "Cylinder";
		Set = Set;
		Support = Supports.Cylinder;
		Centroid = CoordinateFrame.Position;
		AlignedRegion3 = Region3.new(WorldBoundingBox(GetCorners(CoordinateFrame, HalfSize)));
	}, RotatedRegion3)
end

function RotatedRegion3.Ball(CoordinateFrame: CFrame, Size: Vector3)
	local HalfSize: Vector3 = Size / 2
	local Set = table.create(2, CoordinateFrame)
	Set[2] = HalfSize

	return setmetatable({
		CFrame = CoordinateFrame;
		Size = Size;
		Shape = "Ball";
		Set = Set;
		Support = Supports.Ellipsoid;
		Centroid = CoordinateFrame.Position;
		AlignedRegion3 = Region3.new(WorldBoundingBox(GetCorners(CoordinateFrame, HalfSize)));
	}, RotatedRegion3)
end

local Vertices_Classify = Vertices.Classify
function RotatedRegion3.FromPart(BasePart: BasePart)
	return RotatedRegion3[Vertices_Classify(BasePart)](BasePart.CFrame, BasePart.Size)
end

-- Public Constructors

function RotatedRegion3:CastPoint(Point: Vector3): boolean
	return CreateGJK(self.Set, table.create(1, Point), self.Centroid, Point, self.Support, Supports.PointCloud)()
end

function RotatedRegion3:CastPart(BasePart: BasePart): boolean
	local Region = RotatedRegion3[Vertices_Classify(BasePart)](BasePart.CFrame, BasePart.Size)
	return CreateGJK(self.Set, Region.Set, self.Centroid, Region.Centroid, self.Support, Region.Support)()
end

function RotatedRegion3:FindPartsInRegion3(IgnoreInstance: Instance, MaxParts: number?)
	local Found = {}
	local Length = 0

	local Set = self.Set
	local Centroid = self.Centroid
	local Support = self.Support

	for _, BasePart in ipairs(Workspace:FindPartsInRegion3(self.AlignedRegion3, IgnoreInstance, MaxParts)) do
		local Region = RotatedRegion3[Vertices_Classify(BasePart)](BasePart.CFrame, BasePart.Size)
		if CreateGJK(Set, Region.Set, Centroid, Region.Centroid, Support, Region.Support)() then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:FindPartsInRegion3WithIgnoreList(IgnoreList, MaxParts: number?)
	IgnoreList = IgnoreList or {}
	local Found = {}
	local Length = 0

	local Set = self.Set
	local Centroid = self.Centroid
	local Support = self.Support

	for _, BasePart in ipairs(Workspace:FindPartsInRegion3WithIgnoreList(self.AlignedRegion3, IgnoreList, MaxParts)) do
		local Region = RotatedRegion3[Vertices_Classify(BasePart)](BasePart.CFrame, BasePart.Size)
		if CreateGJK(Set, Region.Set, Centroid, Region.Centroid, Support, Region.Support)() then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:FindPartsInRegion3WithWhiteList(Whitelist, MaxParts: number?)
	Whitelist = Whitelist or {}
	local Found = {}
	local Length = 0

	local Set = self.Set
	local Centroid = self.Centroid
	local Support = self.Support

	for _, BasePart in ipairs(Workspace:FindPartsInRegion3WithWhiteList(self.AlignedRegion3, Whitelist, MaxParts)) do
		local Region = RotatedRegion3[Vertices_Classify(BasePart)](BasePart.CFrame, BasePart.Size)
		if CreateGJK(Set, Region.Set, Centroid, Region.Centroid, Support, Region.Support)() then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:GetPlayers(): Array<Player>
	local FoundPlayers: Array<Player> = {}
	local Length: number = 0

	local Set = self.Set
	local Centroid = self.Centroid
	local Support = self.Support

	for _, Player in ipairs(Players:GetPlayers()) do
		local Character = Player.Character
		if Character then
			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if HumanoidRootPart then
				local Region = RotatedRegion3[Vertices_Classify(HumanoidRootPart)](HumanoidRootPart.CFrame, HumanoidRootPart.Size)
				if CreateGJK(Set, Region.Set, Centroid, Region.Centroid, Support, Region.Support)() then
					Length += 1
					FoundPlayers[Length] = Player
				end
			end
		end
	end

	return FoundPlayers
end

function RotatedRegion3:Cast(IgnoreList, MaxParts: number?)
	IgnoreList = type(IgnoreList) == "table" and IgnoreList or table.create(1, IgnoreList)
	return self:FindPartsInRegion3WithIgnoreList(IgnoreList, MaxParts)
end

return RotatedRegion3