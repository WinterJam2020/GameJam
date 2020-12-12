local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CastAttachment = require(script.Parent.Logic.CastAttachment)
local CastVectorPoint = require(script.Parent.Logic.CastVectorPoint)
local CastLinkAttachment = require(script.Parent.Logic.CastLinkAttachment)

local ActiveHitboxes = {}
local HitboxesConfigured = 0
local Connection

local Handler = {}

local function ServiceStop(ForceStop)
	if HitboxesConfigured == 0 or ForceStop then
		Connection = Connection:Disconnect()
	end
end

function Handler.Add(HitboxObject)
	HitboxesConfigured += 1
	ActiveHitboxes[HitboxObject.Object] = HitboxObject
end

function Handler.Remove(Object)
	if ActiveHitboxes[Object] then
		HitboxesConfigured -= 1
		ActiveHitboxes[Object] = ActiveHitboxes[Object]:Destroy()
		ServiceStop()
	end
end

function Handler.Check(Object, CanWarn)
	if ActiveHitboxes[Object] then
		if CanWarn then
			warn("This hitbox already exists!")
		end

		return ActiveHitboxes[Object]
	end
end

local function ServiceRun()
	Connection = RunService.Heartbeat:Connect(function()
		local IsActive = false
		for HitboxObject, Object in next, ActiveHitboxes do
			if Object.Destroyed then
				return Handler.Remove(HitboxObject)
			end

			if Object.Active then
				IsActive = true
				for _, Point in ipairs(Object.Points) do
					local RayStart: Vector3, RayDirection: Vector3
					local RelativePointToWorld
					local Method

					if Point.RelativePart then
						Method = CastVectorPoint
						RayStart, RayDirection, RelativePointToWorld = Method.Solve(Point)
					elseif Point.Attachment0 == nil and typeof(Point.Attachment) == "Instance" then
						Method = CastAttachment
						RayStart, RayDirection = Method.Solve(Point)
					elseif Point.Attachment0 then
						Method = CastLinkAttachment
						RayStart, RayDirection = Method.Solve(Point)
					end

					if RayStart then
						local RaycastResult: RaycastResult? = Workspace:Raycast(RayStart, RayDirection, Object.RaycastParams)
						Method.LastPosition(Point, RelativePointToWorld)

						if RaycastResult then
							local HitPart = RaycastResult.Instance
							if not Object.PartMode then
								local Target = HitPart.Parent
								if Target and not Object.TargetsHit[Target] then
									local Humanoid: Humanoid? = Target:FindFirstChildOfClass("Humanoid")
									if Humanoid then
										Object.TargetsHit[Target] = true
										Object.OnHit:Fire(HitPart, Humanoid, RaycastResult)
									end
								end
							else
								if not Object.TargetsHit[HitPart] then
									Object.TargetsHit[HitPart] = true
									Object.OnHit:Fire(HitPart, nil, RaycastResult)
								end
							end
						end
					end
				end
			end
		end

		if not IsActive then
			ServiceStop(true)
		end
	end)
end

CollectionService:GetInstanceAddedSignal("RaycastEnabled"):Connect(ServiceRun)

return Handler