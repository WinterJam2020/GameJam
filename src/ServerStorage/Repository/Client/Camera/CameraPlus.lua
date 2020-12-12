local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")
local Scheduler = Resources:LoadLibrary("Scheduler")
local Tween = Resources:LoadLibrary("Tween")

Resources:LoadLibrary("EasingFunctions")

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local LookAt = nil

local Scriptable = Enum.CameraType.Scriptable
local Custom = Enum.CameraType.Custom
local CLASS_NAME = "CameraPlus"

local CameraPlus = {}
local API = {}
local Metatable = {}

local function CFrameToPositionAndFocus(CFrame, LookDistance)
	local Position = CFrame.Position
	return Position, Position + CFrame.LookVector * (type(LookDistance) == "number" and LookDistance or 10)
end

--[[**
	Sets the position of the CurrentCamera.
	@param [t:Vector3] Position The position you want to set.
	@returns [t:none]
**--]]
function API.SetPosition(_, Position)
	if CurrentCamera.CameraType == Scriptable then
		if not LookAt then
			LookAt = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 5
		end

		CurrentCamera.CFrame = CFrame.new(Position, LookAt)
	else
		if not LookAt then
			LookAt = CurrentCamera.Focus.Position
		end

		CurrentCamera.CFrame = CFrame.new(Position)
		CurrentCamera.Focus = CFrame.new(LookAt)
	end
end

--[[**
	Gets the position of the CurrentCamera.
	@returns [t:Vector3] The position of the CurrentCamera.
**--]]
function API.GetPosition()
	return CurrentCamera.CFrame.Position
end

--[[**
	Sets the Focus of the CurrentCamera.
	@param [t:Vector3] Focus The focus vector you want to set.
	@returns [t:none]
**--]]
function API:SetFocus(Focus)
	LookAt = Focus
	self:SetPosition(self:GetPosition())
end

--[[**
	Set the camera's position and what it is looking at.
	@param [t:Vector3] Position The position vector you want to set.
	@param [t:Vector3] Focus The focus vector you want to set.
	@returns [t:none]
**--]]
function API:SetView(Position, Focus)
	LookAt = Focus
	self:SetPosition(Position)
end

--[[**
	Sets the CurrentCamera's FieldOfView.
	@param [t:number] FieldOfView The FieldOfView.
	@returns [t:none]
**--]]
function API.SetFOV(_, FieldOfView)
	CurrentCamera.FieldOfView = FieldOfView
end

--[[**
	Gets the CurrentCamera's FieldOfView.
	@returns [t:number] The FieldOfView.
**--]]
function API.GetFOV()
	return CurrentCamera.FieldOfView
end

--[[**
	Increments the CurrentCamera's current FieldOfView.
	@param [t:number] DeltaFoV The number you wish to increment by.
	@returns [t:none]
**--]]
function API.IncrementFOV(_, DeltaFoV)
	CurrentCamera.FieldOfView = CurrentCamera.FieldOfView + DeltaFoV
end

--[[**
	Sets the CurrentCamera's roll.
	@param [t:number] Roll The number you are setting the roll to be.
	@returns [t:none]
**--]]
function API.SetRoll(_, Roll)
	CurrentCamera:SetRoll(Roll)
end

--[[**
	Gets the CurrentCamera's roll.
	@returns [t:number] The roll of the CurrentCamera.
**--]]
function API.GetRoll()
	return CurrentCamera:GetRoll()
end

--[[**
	Increments the CurrentCamera's current roll.
	@param [t:number] DeltaRoll The number you wish to increment by.
	@returns [t:none]
**--]]
function API.IncrementRoll(_, DeltaRoll)
	CurrentCamera:SetRoll(CurrentCamera:GetRoll() + DeltaRoll)
end

--[[**
	Tween the CurrentCamera from one position to the next.
	@param [t:CFrame] Start The starting CFrame.
	@param [t:CFrame] End The ending CFrame.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API.Tween(_, Start, End, Duration, EasingFunction, Yield)
	CurrentCamera.CameraType = Scriptable
	local StartPosition, StartLook = CFrameToPositionAndFocus(Start)
	local EndPosition, EndLook = CFrameToPositionAndFocus(End)
	local CurrentPosition, CurrentLook = StartPosition, StartLook

	local TweenObject = Tween.new(Duration, EasingFunction, function(Alpha)
		CurrentPosition = StartPosition:Lerp(EndPosition, Alpha)
		CurrentLook = StartLook:Lerp(EndLook, Alpha)
		CurrentCamera.CFrame = CFrame.new(CurrentPosition, CurrentLook)
	end)

	if Yield then
		TweenObject:Wait()
	end
end

--[[**
	Tween the CurrentCamera to the position from the current position.
	@param [t:CFrame] End The ending CFrame.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:TweenTo(End, Duration, EasingFunction, Yield)
	CurrentCamera.CameraType = Scriptable
	self:Tween(CurrentCamera.CFrame, End, Duration, EasingFunction, Yield)
end

--[[**
	Tween the CurrentCamera from the current position back to the LocalPlayer.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:TweenToPlayer(Duration, EasingFunction, Yield)
	local Character = LocalPlayer.Character
	if Character then
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local Head = Character:FindFirstChild("Head")
		local WalkSpeed = 16

		if Head then
			if Humanoid then
				WalkSpeed = Humanoid.WalkSpeed
				Humanoid.WalkSpeed = 0
			end

			local CFrameEnd = CFrame.new(Head.Position - Head.CFrame.LookVector * 10, Head.Position)
			if not Yield then
				self:TweenTo(CFrameEnd, Duration, EasingFunction, false)
				Scheduler.Delay(Duration, function()
					CurrentCamera.CameraType = Custom
					CurrentCamera.CameraSubject = Character
					if Humanoid then
						Humanoid.WalkSpeed = WalkSpeed
					end
				end)
			else
				self:TweenTo(CFrameEnd, Duration, EasingFunction, true)
				CurrentCamera.CameraType = Custom
				CurrentCamera.CameraSubject = Character
				if Humanoid then
					Humanoid.WalkSpeed = WalkSpeed
				end
			end
		end
	end
end

--[[**
	Tween the CurrentCamera's FieldOfView.
	@param [t:number] StartFoV The starting FieldOfView.
	@param [t:number] EndFoV The ending FieldOfView.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API.TweenFOV(_, StartFoV, EndFoV, Duration, EasingFunction, Yield)
	local FieldOfView = StartFoV
	local Difference = EndFoV - StartFoV
	local TweenObject = Tween.new(Duration, EasingFunction, function(Alpha)
		FieldOfView = StartFoV + Difference * Alpha
		CurrentCamera.FieldOfView = FieldOfView
	end)

	if Yield then
		TweenObject:Wait()
	end
end

--[[**
	Tween the CurrentCamera's FieldOfView to EndFoV.
	@param [t:number] EndFoV The ending FieldOfView.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:TweenToFOV(EndFoV, Duration, EasingFunction, Yield)
	self:TweenFoV(CurrentCamera.FieldOfView, EndFoV, Duration, EasingFunction, Yield)
end

--[[**
	Tween the CurrentCamera's roll.
	@param [t:number] StartRoll The starting roll.
	@param [t:number] EndRoll The ending roll.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API.TweenRoll(_, StartRoll, EndRoll, Duration, EasingFunction, Yield)
	CurrentCamera.CameraType = Scriptable
	local Roll = StartRoll
	local Difference = EndRoll - StartRoll

	local TweenObject = Tween.new(Duration, EasingFunction, function(Alpha)
		Roll = StartRoll + Difference * Alpha
		CurrentCamera:SetRoll(Roll)
	end)

	if Yield then
		TweenObject:Wait()
	end
end

--[[**
	Tween the CurrentCamera's roll to EndRoll.
	@param [t:number] EndRoll The ending roll.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:TweenToRoll(EndRoll, Duration, EasingFunction, Yield)
	self:TweenRoll(CurrentCamera:GetRoll(), EndRoll, Duration, EasingFunction, Yield)
end

--[[**
	Tween all parts of the CurrentCamera.
	@param [t:CFrame] Start The starting CFrame.
	@param [t:CFrame] End The ending CFrame.
	@param [t:number] StartFoV The starting FieldOfView.
	@param [t:number] EndFoV The ending FieldOfView.
	@param [t:number] StartRoll The starting roll.
	@param [t:number] EndRoll The ending roll.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API.TweenAll(_, Start, End, StartFoV, EndFoV, StartRoll, EndRoll, Duration, EasingFunction, Yield)
	CurrentCamera.CameraType = Scriptable

	local StartPosition, StartLook = CFrameToPositionAndFocus(Start)
	local EndPosition, EndLook = CFrameToPositionAndFocus(End)
	local CurrentPosition, CurrentLook = StartPosition, StartLook
	local FieldOfView, FoVDifference = StartFoV, EndFoV - StartFoV
	local Roll, RollDifference = StartRoll, EndRoll - StartRoll

	local TweenObject = Tween.new(Duration, EasingFunction, function(Alpha)
		CurrentPosition = StartPosition:Lerp(EndPosition, Alpha)
		CurrentLook = StartLook:Lerp(EndLook, Alpha)
		FieldOfView = StartFoV + FoVDifference * Alpha
		Roll = StartRoll + RollDifference * Alpha

		CurrentCamera.CFrame = CFrame.new(CurrentPosition, CurrentLook)
		CurrentCamera.FieldOfView = FieldOfView
		CurrentCamera:SetRoll(Roll)
	end)

	if Yield then
		TweenObject:Wait()
	end
end

--[[**
	Tween all parts of the CurrentCamera.
	@param [t:CFrame] End The ending CFrame.
	@param [t:number] EndFoV The ending FieldOfView.
	@param [t:number] EndRoll The ending roll.
	@param [t:number] Duration The length of the Tween.
	@param [tPlus:enumeration<Enumeration.EasingFunction>] EasingFunction The easing function you want to use.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:TweenToAll(End, EndFoV, EndRoll, Duration, EasingFunction, Yield)
	CurrentCamera.CameraType = Scriptable
	self:TweenAll(CurrentCamera.CFrame, End, CurrentCamera.FieldOfView, EndFoV, CurrentCamera:GetRoll(), EndRoll, Duration, EasingFunction, Yield)
end

--[[**
	Same as CurrentCamera::Interpolate.
	@param [t:Vector3] End The ending position.
	@param [t:Vector3] EndFocus The ending focus.
	@param [t:number] Duration The length of the Tween.
	@param [t:boolean] Yield Optional argument if you wish to yield until the Tween is complete.
	@returns [t:none]
**--]]
function API:Interpolate(EndPosition, EndFocus, Duration, Yield)
	self:TweenTo(CFrame.new(EndPosition, EndFocus), Duration, Enumeration.EasingDirection.InOutSine, Yield)
end

--[[**
	Same as CurrentCamera::IsA.
	@param [t:string] ClassName The ClassName you want to check.
	@returns [t:boolean]
**--]]
function API.IsA(_, ClassName)
	return ClassName == CLASS_NAME or CurrentCamera:IsA(ClassName)
end

Metatable.__metatable = true
function Metatable.__index(_, Index)
	return API[Index] or CurrentCamera[Index]
end

function Metatable.__newindex(_, Index, Value)
	if API[Index] then
		error("Cannot change CameraPlus API.", 0)
	else
		CurrentCamera[Index] = Value
	end
end

function Metatable:__eq(Other)
	return self == Other or CurrentCamera == Other
end

return setmetatable(CameraPlus, Metatable)