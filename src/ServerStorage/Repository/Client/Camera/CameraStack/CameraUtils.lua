--- Utility methods for cameras
-- @module CameraUtils

local CameraUtils = {}

function CameraUtils.GetCubeoidDiameter(Size: Vector3)
	return math.sqrt(Size.X^2 + Size.Y^2 + Size.Z^2)
end

--- Use spherical bounding box to calculate how far back to move a camera
-- See: https://community.khronos.org/t/zoom-to-fit-screen/59857/12
function CameraUtils.FitBoundingBoxToCamera(Size, FovDeg, AspectRatio)
	local Radius = CameraUtils.GetCubeoidDiameter(Size)/2
	return CameraUtils.FitSphereToCamera(Radius, FovDeg, AspectRatio)
end

function CameraUtils.FitSphereToCamera(Radius, FovDeg, AspectRatio)
	local HalfMinFov = math.rad(FovDeg) / 2
	if AspectRatio < 1 then
		HalfMinFov = math.atan(AspectRatio * math.tan(HalfMinFov))
	end

	return Radius / math.sin(HalfMinFov)
end

function CameraUtils.IsOnScreen(Camera, Position)
	local _, OnScreen = Camera:WorldToScreenPoint(Position)
	return OnScreen
end

return CameraUtils