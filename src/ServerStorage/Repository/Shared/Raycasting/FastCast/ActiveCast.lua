local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")
local typeof = Resources:LoadLibrary("TypeOf")

local ActiveCastStatic = {ClassName = "ActiveCast"}
ActiveCastStatic.__index = ActiveCastStatic

local FastCast = nil
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"
local FC_VIS_OBJ_NAME = "FastCastVisualizationObjects"
local ERR_OBJECT_DISPOSED = "This ActiveCast has been terminated. It can no longer be used."

-- If pierce callback has to run more than this many times, it will register a hit and stop calculating pierces.
-- This only applies for repeated piercings, e.g. the amount of parts that fit within the space of a single cast segment (NOT the whole bullet's trajectory over its entire lifetime)
local MAX_PIERCE_TEST_COUNT = 100

local function GetFastCastVisualizationContainer()
	local fcVisualizationObjects = Workspace.Terrain:FindFirstChild(FC_VIS_OBJ_NAME)
	if fcVisualizationObjects ~= nil then
		return fcVisualizationObjects
	end

	fcVisualizationObjects = Instance.new("Folder")
	fcVisualizationObjects.Name = FC_VIS_OBJ_NAME
	fcVisualizationObjects.Archivable = false
	fcVisualizationObjects.Parent = Workspace.Terrain
	return fcVisualizationObjects
end

local function DbgVisualizeSegment(castStartCFrame, castLength)
	if FastCast.VisualizeCasts ~= true then
		return
	end

	local adornment = Instance.new("ConeHandleAdornment")
	adornment.Adornee = Workspace.Terrain
	adornment.CFrame = castStartCFrame
	adornment.Height = castLength
	adornment.Color3 = Color3.new()
	adornment.Radius = 0.25
	adornment.Transparency = 0.5
	adornment.Parent = GetFastCastVisualizationContainer()
	return adornment
end

local function DbgVisualizeHit(atCF, wasPierce)
	if FastCast.VisualizeCasts ~= true then
		return
	end

	local adornment = Instance.new("SphereHandleAdornment")
	adornment.Adornee = Workspace.Terrain
	adornment.CFrame = atCF
	adornment.Radius = 0.4
	adornment.Transparency = 0.25
	adornment.Color3 = not wasPierce and Color3.new(0.2, 1, 0.5) or Color3.new(1, 0.2, 0.2)
	adornment.Parent = GetFastCastVisualizationContainer()
	return adornment
end

local function GetPositionAtTime(time, origin, initialVelocity, acceleration)
	local force = Vector3.new((acceleration.X * time^2) / 2, (acceleration.Y * time^2) / 2, (acceleration.Z * time^2) / 2)
	return origin + (initialVelocity * time) + force
end

local function GetVelocityAtTime(time, initialVelocity, acceleration)
	return initialVelocity + acceleration * time
end

local function GetTrajectoryInfo(cast, index)
	assert(cast.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	local trajectories = cast.StateInfo.Trajectories
	local trajectory = trajectories[index]
	local duration = trajectory.EndTime - trajectory.StartTime

	local origin = trajectory.Origin
	local vel = trajectory.InitialVelocity
	local accel = trajectory.Acceleration

	local array = table.create(2)
	array[1], array[2] = GetPositionAtTime(duration, origin, vel, accel), GetVelocityAtTime(duration, vel, accel)
	return array
end

local function GetLatestTrajectoryEndInfo(cast)
	assert(cast.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	return GetTrajectoryInfo(cast, #cast.StateInfo.Trajectories)
end

local function CloneCastParams(params)
	local clone = RaycastParams.new()
	clone["CollisionGroup"] = params.CollisionGroup
	clone.FilterType = params.FilterType
	clone.FilterDescendantsInstances = params.FilterDescendantsInstances
	clone.IgnoreWater = params.IgnoreWater
	return clone
end

local function SendRayHit(cast, resultOfCast, segmentVelocity, cosmeticBulletObject)
	cast.Caster.RayHit:Fire(cast, resultOfCast, segmentVelocity, cosmeticBulletObject)
end

local function SendRayPierced(cast, resultOfCast, segmentVelocity, cosmeticBulletObject)
	cast.Caster.RayPierced:Fire(cast, resultOfCast, segmentVelocity, cosmeticBulletObject)
end

local function SendLengthChanged(cast, lastPoint, rayDir, rayDisplacement, segmentVelocity, cosmeticBulletObject)
	cast.Caster.LengthChanged:Fire(cast, lastPoint, rayDir, rayDisplacement, segmentVelocity, cosmeticBulletObject)
end

local function SimulateCast(cast, delta)
	assert(cast.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	local latestTrajectory = cast.StateInfo.Trajectories[#cast.StateInfo.Trajectories]

	local origin = latestTrajectory.Origin
	local totalDelta = cast.StateInfo.TotalRuntime - latestTrajectory.StartTime
	local initialVelocity = latestTrajectory.InitialVelocity
	local acceleration = latestTrajectory.Acceleration

	local lastPoint: Vector3 = GetPositionAtTime(totalDelta, origin, initialVelocity, acceleration)

	cast.StateInfo.TotalRuntime += delta
	totalDelta = cast.StateInfo.TotalRuntime - latestTrajectory.StartTime

	local currentTarget = GetPositionAtTime(totalDelta, origin, initialVelocity, acceleration)
	local segmentVelocity = GetVelocityAtTime(totalDelta, initialVelocity, acceleration)
	local totalDisplacement = currentTarget - lastPoint -- This is the displacement from where the ray was on the last from to where the ray is now.

	local rayDir: Vector3 = totalDisplacement.Unit * segmentVelocity.Magnitude * delta
	local targetWorldRoot = cast.RayInfo.WorldRoot
	local resultOfCast = targetWorldRoot:Raycast(lastPoint, rayDir, cast.RayInfo.Parameters)

	local point = currentTarget
	local part = nil
	local material = Enum.Material.Air

	if resultOfCast then
		point = resultOfCast.Position
		part = resultOfCast.Instance
		material = resultOfCast.Material
	end

	local rayDisplacement = (point - lastPoint).Magnitude
	SendLengthChanged(cast, lastPoint, rayDir.Unit, rayDisplacement, segmentVelocity, cast.RayInfo.CosmeticBulletObject)
	cast.StateInfo.DistanceCovered += rayDisplacement

	local rayVisualization = nil
	if delta > 0 then
		rayVisualization = DbgVisualizeSegment(CFrame.new(lastPoint, lastPoint + rayDir), rayDisplacement)
	end

	if part and part ~= cast.RayInfo.CosmeticBulletObject then
		if cast.RayInfo.CanPierceCallback then
			if cast.StateInfo.IsActivelySimulatingPierce then
				error("ERROR: The latest call to CanPierceCallback took too long to complete! This cast is going to suffer desyncs which WILL cause unexpected behavior and errors. Please fix your performance problems, or remove statements that yield (e.g. wait() calls)")
			end

			cast.StateInfo.IsActivelySimulatingPierce = true
		end

		if cast.RayInfo.CanPierceCallback == nil or (cast.RayInfo.CanPierceCallback ~= nil and cast.RayInfo.CanPierceCallback(cast, resultOfCast, segmentVelocity, cast.RayInfo.CosmeticBulletObject) == false) then
			cast.StateInfo.IsActivelySimulatingPierce = false
			SendRayHit(cast, resultOfCast, segmentVelocity, cast.RayInfo.CosmeticBulletObject)
			cast:Destroy()
			return DbgVisualizeHit(CFrame.new(point), false)
		else
			if rayVisualization ~= nil then
				rayVisualization.Color3 = Color3.new(0.4, 0.05, 0.05) -- Turn it red to signify that the cast was scrapped.
			end

			DbgVisualizeHit(CFrame.new(point), true)

			local params = cast.RayInfo.Parameters
			local alteredParts = {}
			local currentPierceTestCount = 0
			local originalFilter = params.FilterDescendantsInstances
			local brokeFromSolidObject = false

			while 1 do
				if resultOfCast.Instance:IsA("Terrain") then
					if material == Enum.Material.Water then
						error("Do not add Water as a piercable material. If you need to pierce water, set cast.RayInfo.Parameters.IgnoreWater = true instead", 0)
					end

					warn("WARNING: The pierce callback for this cast returned TRUE on Terrain! This can cause severely adverse effects.")
				end

				if params.FilterType == Enum.RaycastFilterType.Blacklist then
					local filter = params.FilterDescendantsInstances
					table.insert(filter, resultOfCast.Instance)
					table.insert(alteredParts, resultOfCast.Instance)
					params.FilterDescendantsInstances = filter
				else
					local filter = params.FilterDescendantsInstances
					Table.RemoveObject(filter, resultOfCast.Instance)
					table.insert(alteredParts, resultOfCast.Instance)
					params.FilterDescendantsInstances = filter
				end

				SendRayPierced(cast, resultOfCast, segmentVelocity, cast.RayInfo.CosmeticBulletObject)
				resultOfCast = targetWorldRoot:Raycast(lastPoint, rayDir, params)
				if resultOfCast == nil then
					break
				end

				if currentPierceTestCount > MAX_PIERCE_TEST_COUNT then
					warn("WARNING: Exceeded maximum pierce test for a single ray segment (attempted to test the same segment " .. MAX_PIERCE_TEST_COUNT .. " times!)")
					break
				end

				currentPierceTestCount += 1

				if cast.RayInfo.CanPierceCallback(cast, resultOfCast, segmentVelocity, cast.RayInfo.CosmeticBulletObject) == false then
					brokeFromSolidObject = true
					break
				end
			end

			cast.RayInfo.Parameters.FilterDescendantsInstances = originalFilter
			cast.StateInfo.IsActivelySimulatingPierce = false

			if brokeFromSolidObject then
				SendRayHit(cast, resultOfCast, segmentVelocity, cast.RayInfo.CosmeticBulletObject)
				cast:Destroy()
				return DbgVisualizeHit(CFrame.new(resultOfCast.Position), false)
			end
		end
	end

	if cast.StateInfo.DistanceCovered >= cast.RayInfo.MaxDistance then
		cast:Destroy()
		DbgVisualizeHit(CFrame.new(currentTarget), false)
	end
end

function ActiveCastStatic.new(caster, origin, direction, velocity, castDataPacket)
	if type(velocity) == "number" then
		velocity = direction.Unit * velocity
	end

	local cast = {
		Caster = caster;

		StateInfo = {
			UpdateConnection = nil;
			Paused = false;
			TotalRuntime = 0;
			DistanceCovered = 0;
			IsActivelySimulatingPierce = false;
			Trajectories = {
				{
					StartTime = 0;
					EndTime = -1;
					Origin = origin;
					InitialVelocity = velocity;
					Acceleration = castDataPacket.Acceleration;
				};
			};
		};

		UserData = {};
		RayInfo = {
			Parameters = castDataPacket.RaycastParams;
			WorldRoot = Workspace;
			MaxDistance = castDataPacket.MaxDistance or 1000;
			CosmeticBulletObject = castDataPacket.CosmeticBulletTemplate; -- This is intended. We clone it a smidge of the way down.
			CanPierceCallback = castDataPacket.CanPierceFunction;
		};
	}

	if cast.RayInfo.Parameters ~= nil then
		cast.RayInfo.Parameters = CloneCastParams(cast.RayInfo.Parameters)
	end

	local usingProvider = false
	if castDataPacket.CosmeticBulletProvider == nil then
		if cast.RayInfo.CosmeticBulletObject ~= nil then
			cast.RayInfo.CosmeticBulletObject = cast.RayInfo.CosmeticBulletObject:Clone()
			cast.RayInfo.CosmeticBulletObject.CFrame = CFrame.new(origin, origin + direction)
			cast.RayInfo.CosmeticBulletObject.Parent = castDataPacket.CosmeticBulletContainer
		end
	else
		if typeof(castDataPacket.CosmeticBulletProvider) == "PartCache" then
			if cast.RayInfo.CosmeticBulletObject ~= nil then
				warn("Do not define FastCastBehavior.CosmeticBulletTemplate and FastCastBehavior.CosmeticBulletProvider at the same time! The provider will be used, and CosmeticBulletTemplate will be set to nil.")
				cast.RayInfo.CosmeticBulletObject = nil
				castDataPacket.CosmeticBulletTemplate = nil
			end

			cast.RayInfo.CosmeticBulletObject = castDataPacket.CosmeticBulletProvider:GetPart()
			cast.RayInfo.CosmeticBulletObject.CFrame = CFrame.new(origin, origin + direction)
			usingProvider = true
		else
			warn("FastCastBehavior.CosmeticBulletProvider was not an instance of the PartCache module (an external/separate model)! Are you inputting an instance created via PartCache.new If so, are you on the latest version of PartCache Setting FastCastBehavior.CosmeticBulletProvider to nil.")
			castDataPacket.CosmeticBulletProvider = nil
		end
	end

	local targetContainer
	if usingProvider then
		targetContainer = castDataPacket.CosmeticBulletProvider.CurrentCacheParent
	else
		targetContainer = castDataPacket.CosmeticBulletContainer
	end

	if castDataPacket.AutoIgnoreContainer and targetContainer then
		local ignoreList = cast.RayInfo.Parameters.FilterDescendantsInstances
		if not table.find(ignoreList, targetContainer) then
			table.insert(ignoreList, targetContainer)
			cast.RayInfo.Parameters.FilterDescendantsInstances = ignoreList
		end
	end

	local event
	if RunService:IsClient() then
		event = RunService.RenderStepped
	else
		event = RunService.Heartbeat
	end

	cast.StateInfo.UpdateConnection = event:Connect(function(delta)
		if not cast.StateInfo.Paused then
			SimulateCast(cast, delta)
		end
	end)

	return setmetatable(cast, ActiveCastStatic)
end

function ActiveCastStatic.SetStaticFastCastReference(ref)
	FastCast = ref
end

---- GETTERS AND SETTERS ----

local function ModifyTransformation(cast, velocity, acceleration, position)
	local trajectories = cast.StateInfo.Trajectories
	local lastTrajectory = trajectories[#trajectories]

	if lastTrajectory.StartTime == cast.StateInfo.TotalRuntime then
		velocity = velocity == nil and lastTrajectory.InitialVelocity or velocity
		acceleration = acceleration == nil and lastTrajectory.Acceleration or acceleration
		position = position == nil and position or lastTrajectory.Origin

		lastTrajectory.Origin = position
		lastTrajectory.InitialVelocity = velocity
		lastTrajectory.Acceleration = acceleration
	else
		lastTrajectory.EndTime = cast.StateInfo.TotalRuntime

		local information = GetLatestTrajectoryEndInfo(cast)
		local point, velAtPoint = information[1], information[2]

		table.insert(cast.StateInfo.Trajectories, {
			StartTime = cast.StateInfo.TotalRuntime;
			EndTime = -1;
			Origin = position == nil and point or position;
			InitialVelocity = velocity == nil and velAtPoint or velocity;
			Acceleration = acceleration == nil and lastTrajectory.Acceleration or acceleration;
		})
	end
end

function ActiveCastStatic:SetVelocity(velocity)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("SetVelocity", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	ModifyTransformation(self, velocity, nil, nil)
end

function ActiveCastStatic:SetAcceleration(acceleration)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("SetAcceleration", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	ModifyTransformation(self, nil, acceleration, nil)
end

function ActiveCastStatic:SetPosition(position)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("SetPosition", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	ModifyTransformation(self, nil, nil, position)
end

function ActiveCastStatic:GetVelocity()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("GetVelocity", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	local currentTrajectory = self.StateInfo.Trajectories[#self.StateInfo.Trajectories]
	return GetVelocityAtTime(self.StateInfo.TotalRuntime - currentTrajectory.StartTime, currentTrajectory.InitialVelocity, currentTrajectory.Acceleration)
end

function ActiveCastStatic:GetAcceleration()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("GetAcceleration", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	local currentTrajectory = self.StateInfo.Trajectories[#self.StateInfo.Trajectories]
	return currentTrajectory.Acceleration
end

function ActiveCastStatic:GetPosition()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("GetPosition", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	local currentTrajectory = self.StateInfo.Trajectories[#self.StateInfo.Trajectories]
	return GetPositionAtTime(self.StateInfo.TotalRuntime - currentTrajectory.StartTime, currentTrajectory.Origin, currentTrajectory.InitialVelocity, currentTrajectory.Acceleration)
end

function ActiveCastStatic:AddVelocity(velocity)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("AddVelocity", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	self:SetVelocity(self:GetVelocity() + velocity)
end

function ActiveCastStatic:AddAcceleration(acceleration)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("AddAcceleration", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	self:SetAcceleration(self:GetAcceleration() + acceleration)
end

function ActiveCastStatic:AddPosition(position)
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("AddPosition", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	self:SetPosition(self:GetPosition() + position)
end

function ActiveCastStatic:Pause()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("Pause", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	self.StateInfo.Paused = true
end

function ActiveCastStatic:Resume()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("Resume", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)
	self.StateInfo.Paused = false
end

function ActiveCastStatic:Destroy()
	assert(getmetatable(self) == ActiveCastStatic, ERR_NOT_INSTANCE:format("Terminate", "ActiveCast.new(...)"))
	assert(self.StateInfo.UpdateConnection ~= nil, ERR_OBJECT_DISPOSED)

	local trajectories = self.StateInfo.Trajectories
	local lastTrajectory = trajectories[#trajectories]
	lastTrajectory.EndTime = self.StateInfo.TotalRuntime

	self.StateInfo.UpdateConnection:Disconnect()
	self.Caster.CastTerminating:FireSync(self)
	self.StateInfo.UpdateConnection = nil

	self.Caster = nil
	self.StateInfo = nil
	self.RayInfo = nil
	self.UserData = nil
	setmetatable(self, nil)
end

return ActiveCastStatic