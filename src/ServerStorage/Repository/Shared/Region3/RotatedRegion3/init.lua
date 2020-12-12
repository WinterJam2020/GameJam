local Workspace = game:GetService("Workspace")
local GJK = require(script.GJK)
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

function RotatedRegion3.new(CoordinateFrame: CFrame, Size)
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

function RotatedRegion3.Wedge(CoordinateFrame: CFrame, Size)
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

function RotatedRegion3.CornerWedge(CoordinateFrame: CFrame, Size)
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

function RotatedRegion3.Cylinder(CoordinateFrame: CFrame, Size)
	local Set = table.create(2, CoordinateFrame)
	Set[2] = Size / 2

	return setmetatable({
		AlignedRegion3 = Region3.new(WorldBoundingBox(Vertices.Block(CoordinateFrame, Size / 2)));
		Centroid = CoordinateFrame.Position;
		CFrame = CoordinateFrame;
		Set = Set;
		Shape = "Cylinder";
		Size = Size;
		Support = Supports.Cylinder;
	}, RotatedRegion3)
end

function RotatedRegion3.Ball(CoordinateFrame: CFrame, Size)
	local Set = table.create(2, CoordinateFrame)
	Set[2] = Size / 2

	return setmetatable({
		AlignedRegion3 = Region3.new(WorldBoundingBox(Vertices.Block(CoordinateFrame, Size / 2)));
		Centroid = CoordinateFrame.Position;
		CFrame = CoordinateFrame;
		Set = Set;
		Shape = "Ball";
		Size = Size;
		Support = Supports.Ellipsoid;
	}, RotatedRegion3)
end

function RotatedRegion3.FromPart(BasePart)
	return RotatedRegion3[Vertices.Classify(BasePart)](BasePart.CFrame, BasePart.Size)
end

-- Public Constructors

function RotatedRegion3:CastPoint(Point)
	return GJK.new(self.Set, table.create(1, Point), self.Centroid, Point, self.Support, Supports.PointCloud):IsColliding()
end

function RotatedRegion3:CastPart(BasePart)
	local Region = RotatedRegion3.FromPart(BasePart)
	return GJK.new(self.Set, Region.Set, self.Centroid, Region.Centroid, self.Support, Region.Support):IsColliding()
end

function RotatedRegion3:FindPartsInRegion3(IgnoreList, MaxParts)
	local Found = {}
	local Length = 0
	for _, BasePart in ipairs(Workspace:FindPartsInRegion3(self.AlignedRegion3, IgnoreList, MaxParts)) do
		if self:CastPart(BasePart) then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:FindPartsInRegion3WithIgnoreList(IgnoreList, MaxParts)
	IgnoreList = IgnoreList or {}
	local Found = {}
	local Length = 0

	for _, BasePart in ipairs(Workspace:FindPartsInRegion3WithIgnoreList(self.AlignedRegion3, IgnoreList, MaxParts)) do
		if self:CastPart(BasePart) then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:FindPartsInRegion3WithWhiteList(Whitelist, MaxParts)
	Whitelist = Whitelist or {}
	local Found = {}
	local Length = 0

	for _, BasePart in ipairs(Workspace:FindPartsInRegion3WithWhiteList(self.AlignedRegion3, Whitelist, MaxParts)) do
		if self:CastPart(BasePart) then
			Length += 1
			Found[Length] = BasePart
		end
	end

	return Found
end

function RotatedRegion3:Cast(IgnoreList, MaxParts)
	IgnoreList = type(IgnoreList) == "table" and IgnoreList or table.create(1, IgnoreList)
	return self:FindPartsInRegion3WithIgnoreList(IgnoreList, MaxParts)
end

return RotatedRegion3