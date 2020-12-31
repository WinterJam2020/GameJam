local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Constants = Resources:LoadShared("Constants").SKI_PATH

local TERRAIN_WIDTH = Constants.TERRAIN_WIDTH
local TERRAIN_DEPTH = Constants.TERRAIN_DEPTH

local function CFrameUpAt(pos: Vector3, up: Vector3, look: Vector3) -- CFrame.lookAt but for up
	local lookProjected = (look - look:Dot(up) * up).Unit
	local right = lookProjected:Cross(up)
    return CFrame.fromMatrix(pos, right, up, -lookProjected)
end

return function(spline)
    local endCFrame = spline:GetCFrame(1)
    local cframe = CFrameUpAt(
        endCFrame.Position,
        Vector3.new(0, 1, 0),
        endCFrame.LookVector
    )
    -- workspace.Terrain:FillBlock(
    --     cframe * CFrame.new(0, 0, -100),
    --     Vector3.new(TERRAIN_WIDTH, TERRAIN_DEPTH, 200),
    --     Enum.Material.Snow
    -- )
    workspace.Terrain:FillCylinder(
        cframe * CFrame.new(0, -TERRAIN_DEPTH, -TERRAIN_WIDTH),
        TERRAIN_DEPTH,
        TERRAIN_WIDTH * 3/2,
        Enum.Material.Snow
    )
end