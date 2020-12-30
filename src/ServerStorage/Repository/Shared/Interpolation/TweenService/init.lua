local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Resources = require(ReplicatedStorage.Resources)
local EasingFunctions = require(script.EasingFunctions)
local Lerps = require(script.Lerps)
local Services = Resources:LoadLibrary("Services")
local t = Resources:LoadLibrary("t")

local RunService: RunService = Services.RunService
local TweenService: TweenService = Services.TweenService

local DEFAULT_PRIORITY = 0
local NEGATIVE_HUGE = -math.huge

local TweenApi = {
	Bezier = require(script.Bezier);
	EasingFunctions = EasingFunctions;
	Lerps = Lerps;
}

local PriorityRecord = {}
local LockRecord = {}

local NonNegativeNumber = t.numberMin(0)
local InstanceOrTable = t.union(t.Instance, t.table)
local StringOrFunction = t.union(t.string, t.callback)
local OptionalNonNegativeNumber = t.optional(NonNegativeNumber)
local OptionalStringOrFunction = t.optional(StringOrFunction)
local OptionalString = t.optional(t.string)
local OptionalFunction = t.optional(t.callback)

local TweenTuple = t.tuple(InstanceOrTable, OptionalNonNegativeNumber, OptionalStringOrFunction, OptionalString, t.table, OptionalNonNegativeNumber, OptionalFunction)
local TweenAsyncTuple = t.tuple(InstanceOrTable, OptionalNonNegativeNumber, OptionalStringOrFunction, OptionalString, t.table, OptionalNonNegativeNumber, OptionalFunction, OptionalFunction)
local RoTweenTuple = t.tuple(t.Instance, NonNegativeNumber, t.string, t.string, t.table)
local GetValueTuple = t.tuple(t.numberConstrained(0, 1), t.union(t.enum(Enum.EasingStyle), t.string), t.union(t.enum(Enum.EasingDirection), t.string))

local StepFunction
if RunService:IsServer() then
	StepFunction = RunService.Heartbeat
else
	StepFunction = RunService.RenderStepped
end

local DeltaTimeRender = 1 / 60
local LastTime = time()
StepFunction:Connect(function()
	local CurrentTime = time()
	LastTime, DeltaTimeRender = CurrentTime, DeltaTimeRender + (CurrentTime - LastTime - DeltaTimeRender) / 4
end)

local function Interpolate(Object, Properties, Time, EasingStyle, Priority, Callback)
	local PrivateMap = PriorityRecord[Object]
	if not Time or Time < DeltaTimeRender then
		for Property, Value in next, Properties do
			local OverridenPriority = PrivateMap and PrivateMap[Property]
			if (OverridenPriority or NEGATIVE_HUGE) <= Priority then
				local ExcludeMap = LockRecord[Property]
				if ExcludeMap then
					local MV = ExcludeMap[Object]
					if MV then
						ExcludeMap[Object] = (MV + 1) % 2 ^ 53
					end
				end

				if OverridenPriority then
					PrivateMap[Property] = nil
				end

				Object[Property] = Value
			end
		end

		if Callback then
			return Callback()
		end

		return
	elseif type(EasingStyle) ~= "function" then
		EasingStyle = EasingFunctions[EasingStyle]
	end

	local T0 = time() - DeltaTimeRender
	local X = EasingStyle(DeltaTimeRender / Time)
	local FLerps = {}
	local MXKeys = {}
	local NoScan = true

	if not PrivateMap then
		PrivateMap = {}
		NoScan = false
		PriorityRecord[Object] = PrivateMap
	end

	for Property, Value in next, Properties do
		if NoScan or (PrivateMap[Property] or NEGATIVE_HUGE) <= Priority then
			local ExcludeMap = LockRecord[Property]
			if not ExcludeMap then
				ExcludeMap = {}
				LockRecord[Property] = ExcludeMap
			end

			local MV = ((ExcludeMap[Object] or 0) + 1) % 2 ^ 53
			local TypeLerp = Lerps[typeof(Value)](Object[Property], Value)
			MXKeys[Property] = MV
			ExcludeMap[Object] = MV
			PrivateMap[Property] = Priority
			FLerps[Property] = TypeLerp
			Object[Property] = TypeLerp(X)
		end
	end

	repeat
		StepFunction:Wait()
		local Elapsed = time() - T0
		if Elapsed >= Time then
			break
		end

		X = EasingStyle(Elapsed / Time)
		for Property, FLerp in next, FLerps do
			if LockRecord[Property][Object] ~= MXKeys[Property] then
				FLerps[Properties] = nil
			else
				Object[Property] = FLerp(X)
			end
		end
	until not next(FLerps)

	for Property in next, FLerps do
		local MX = LockRecord[Property]
		Object[Property] = Properties[Property]
		MX[Object] = nil
		PrivateMap[Property] = nil
	end

	if not next(PrivateMap) then
		PriorityRecord[Object] = nil
	end

	if Callback then
		return Callback()
	end
end

--[[**
	Tweens the given object to the given properties without yielding the current thread.
	@param [t:union<t:Instance, t:table>] Object The object you wish to tween.
	@param [t:optional<t:numberMin<0>>] Length The length of the tween. Defaults to 0.5.
	@param [t:optional<t:union<t:string, t:callback>>] EasingStyle The style of the tween. Defaults to Linear.
	@param [t:optional<t:string>] EasingDirection The direction of the tween. Defaults to Out.
	@param [t:table] Properties The ending properties of the object.
	@param [t:optional<t:numberMin<0>>] Priority The priority of the tween. Defaults to 0.
	@returns [void]
**--]]
function TweenApi.Tween(Object, Length, EasingStyle, EasingDirection, Properties, Priority, FunctionToCall)
	assert(TweenTuple(Object, Length, EasingStyle, EasingDirection, Properties, Priority, FunctionToCall))

	Length = Length or 0.5
	if type(EasingStyle) == "function" then
		EasingStyle = EasingStyle
	else
		EasingStyle = (EasingDirection or "Out") .. (EasingStyle or "Linear")
	end

	Priority = Priority or DEFAULT_PRIORITY
	return Interpolate(Object, Properties, Length, EasingStyle, Priority or DEFAULT_PRIORITY, FunctionToCall)
end

--[[**
	Tweens the given object to the given properties without yielding the current thread.
	@param [t:union<t:Instance, t:table>] Object The object you wish to tween.
	@param [t:optional<t:numberMin<0>>] Length The length of the tween. Defaults to 0.5.
	@param [t:optional<t:union<t:string, t:callback>>] EasingStyle The style of the tween. Defaults to Linear.
	@param [t:optional<t:string>] EasingDirection The direction of the tween. Defaults to Out.
	@param [t:table] Properties The ending properties of the object.
	@param [t:optional<t:numberMin<0>>] Priority The priority of the tween. Defaults to 0.
	@param [t:optional<t:callback>] Function The function to call when the tween ends.
	@returns [t:tuple<t:boolean, t:string>] A success value and the error message if not successful.
**--]]
function TweenApi.TweenAsync(Object, Length, EasingStyle, EasingDirection, Properties, Priority, Function, FunctionToCall)
	assert(TweenAsyncTuple(Object, Length, EasingStyle, EasingDirection, Properties, Priority, Function, FunctionToCall))

	Length = Length or 0.5
	if type(EasingStyle) == "function" then
		EasingStyle = EasingStyle
	else
		EasingStyle = (EasingDirection or "Out") .. (EasingStyle or "Linear")
	end

	Priority = Priority or DEFAULT_PRIORITY
	local Thread = coroutine.create(Interpolate)
	return coroutine.resume(Thread, Object, Properties, Length, EasingStyle, Priority, Function, FunctionToCall)
end

--[[**
	Not useful for 99.99% of people. Made specifically for a different module.
	@returns nothing useful
**--]]
function TweenApi.TweenCreate(Object, Time, EasingStyle, EasingDirection, Properties, Priority)
	Priority = Priority or DEFAULT_PRIORITY
	return coroutine.create(Interpolate), {Object, Properties, Time, (EasingDirection or "Out") .. (EasingStyle or "Linear"), Priority}
end

local EasingStyles = {Linear = 0, Sine = 1, Back = 2, Quad = 3, Quart = 4, Quint = 5, Bounce = 6, Elastic = 7, Exponential = 8, Circular = 9, Cubic = 10}
local EasingDirections = {In = 0, Out = 1, InOut = 2}

--[[**
	The exact same as vanilla TweenService::GetValue.
	@param [t:numberConstrained<0, 1>] Alpha An interpolation value between 0 and 1.
	@param [t:union<t:enum<Enum.EasingStyle>, t:string>] EasingStyle The easing style to use.
	@param [t:union<t:enum<Enum.EasingDirection>, t:string>] EasingDirection The easing direction to use.
	@returns [t:number]
**--]]
function TweenApi.GetValue(Alpha, EasingStyle, EasingDirection)
	assert(GetValueTuple(Alpha, EasingStyle, EasingDirection))
	EasingStyle = type(EasingStyle) == "string" and EasingStyles[EasingStyle] or EasingStyle
	EasingDirection = type(EasingDirection) == "string" and EasingDirections[EasingDirection] or EasingDirection
	return TweenService:GetValue(Alpha, EasingStyle, EasingDirection)
end

--[[**
	Uses vanilla TweenService to tween the given object to the given properties.
	@param [t:Instance] Object The Instance you want to tween.
	@param [t:numberMin<0>] Length The length of the tween.
	@param [t:string] EasingStyle The style of the tween.
	@param [t:string] EasingDirection The direction of the tween.
	@param [t:table] Properties The ending properties of the object.
	@returns [void]
**--]]
function TweenApi.RoTween(Object, Length, EasingStyle, EasingDirection, Properties)
	assert(RoTweenTuple(Object, Length, EasingStyle, EasingDirection, Properties))

	local Tween = TweenService:Create(
		Object,
		TweenInfo.new(Length, EasingStyles[EasingStyle], EasingDirections[EasingDirection]),
		Properties
	)

	Tween:Play()
	Tween.Completed:Wait()
	Tween:Destroy()
end

--[[**
	Uses vanilla TweenService to tween the given object to the given properties without yielding the current thread.
	@param [t:Instance] Object The Instance you want to tween.
	@param [t:numberMin<0>] Length The length of the tween.
	@param [t:string] EasingStyle The style of the tween.
	@param [t:string] EasingDirection The direction of the tween.
	@param [t:table] Properties The ending properties of the object.
	@returns [void]
**--]]
function TweenApi.RoTweenAsync(Object, Length, EasingStyle, EasingDirection, Properties)
	assert(RoTweenTuple(Object, Length, EasingStyle, EasingDirection, Properties))

	local Tween = TweenService:Create(
		Object,
		TweenInfo.new(Length, EasingStyles[EasingStyle], EasingDirections[EasingDirection]),
		Properties
	)

	Tween.Completed:Connect(function()
		Tween:Destroy()
	end)

	Tween:Play()
end

--[[**
	Interrupts any tweens running on the given Instance.
	@param [t:union<t:Instance, t:table>] Object The Instance you want to cancel the tweens for.
	@returns [void]
**--]]
function TweenApi.Interrupt(Object)
	assert(InstanceOrTable(Object))

	for _, Table in next, LockRecord do
		if not Object or Table[Object] then
			Table[Object] = nil
		end
	end

	if Object then
		PriorityRecord[Object] = nil
	else
		PriorityRecord = {}
	end
end

return TweenApi