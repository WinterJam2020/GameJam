local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Resources = require(ReplicatedStorage.Resources)
local EasingFunctions = Resources:LoadLibrary("EasingFunctions")
local Enumeration = Resources:LoadLibrary("Enumerations")
local Lerps = Resources:LoadLibrary("Lerps")
local Table = Resources:LoadLibrary("Table")
local Typer = Resources:LoadLibrary("Typer")

local Heartbeat = RunService.Heartbeat
local RenderStepped = RunService.RenderStepped

local Completed = Enum.TweenStatus.Completed
local Canceled = Enum.TweenStatus.Canceled
local Linear = EasingFunctions[Enumeration.EasingFunction.Linear.Value]

local function GetRenderEvent(Object)
	if typeof(Object) == "Instance" and Object:IsA("Camera") then
		return RenderStepped
	else
		return Heartbeat
	end
end

local Tween = {
	__index = {
		Running = false;
		Duration = 1;
		ElapsedTime = 0;
		EasingFunction = EasingFunctions[Enumeration.EasingFunction.Standard.Value];
		LerpFunction = function(_, EndValue)
			return EndValue
		end;
	};
}

local OpenTweens = {} -- Will prevent objects from getting garbage collected until Tween finishes

-- local ConstructorTuple = t.tuple(
-- 	t.optional(t.number),
-- 	t.optional(t.union(t.callback, t.enumerationByType(Enumeration.EasingFunction))),
-- 	t.union(t.callback, t.table, t.userdata),
-- 	t.optional(t.any)
-- )

Tween.new = Typer.AssignSignature(Typer.OptionalNumber, Typer.OptionalFunctionOrEnumerationOfTypeEasingFunction, Typer.FunctionOrTableOrUserdata, Typer.Any, function(Duration, EasingFunction, Callback, Argument)
	Duration = Duration or 1
	EasingFunction = type(EasingFunction) == "userdata" and EasingFunctions[EasingFunction.Value] or EasingFunction or Linear

	local self = setmetatable({
		Argument = Argument;
		Callback = Callback;
		Duration = Duration;
		EasingFunction = EasingFunction;
	}, Tween)

	function self.Interpolator(Step)
		local ElapsedTime = self.ElapsedTime + Step
		self.ElapsedTime = ElapsedTime

		if Duration > ElapsedTime then
			local Value = EasingFunction(ElapsedTime, 0, 1, Duration)
			if Argument ~= nil then
				Callback(Argument, Value)
			else
				Callback(Value)
			end
		else
			if Argument ~= nil then
				Callback(Argument, 1)
			else
				Callback(1)
			end

			self:Stop()
		end
	end

	return self:Resume()
end)

function Tween.__index:Stop(Finished)
	if self.Running then
		self.Connection = self.Connection:Disconnect()
		self.Running = false
		local ObjectTable = OpenTweens[self.Object]
		if ObjectTable then
			ObjectTable[self.Property] = nil -- This is for override checks
		end
	end

	local Callback = self.FinishedCallback
	if Callback == true then
		if Finished then
			self.Object:Destroy()
		end
	elseif Callback then
		if self.CallbackArgument ~= nil then
			Callback(self.CallbackArgument, Finished and Completed or Canceled)
		else
			Callback(Finished and Completed or Canceled)
		end
	end

	return self
end

function Tween.__index:Resume()
	if self.Duration == 0 then
		self.Object[self.Property] = self.EndValue
	else
		if not self.Running then
			self.Connection = GetRenderEvent(self.Object):Connect(self.Interpolator)
			self.Running = true
			local ObjectTable = OpenTweens[self.Object]
			if ObjectTable then
				ObjectTable[self.Property] = self -- This is for override checks
			end
		end
	end

	return self
end

function Tween.__index:Restart()
	self.ElapsedTime = 0
	return self:Resume()
end

function Tween.__index:Wait()
	local Event = GetRenderEvent(self.Object)
	while self.Running do
		Event:Wait()
	end

	return self
end

-- local CallTuple = t.tuple(
-- 	t.optional(t.union(t.callback, t.enumerationByType(Enumeration.EasingFunction))),
-- 	t.optional(t.number),
-- 	t.optional(t.boolean),
-- 	t.optional(t.union(t.callback, t.table, t.userdata, t.literal(true))),
-- 	t.optional(t.any)
-- )

return Table.Lock(Tween, Typer.AssignSignature(5, Typer.OptionalFunctionOrEnumerationOfTypeEasingFunction, Typer.OptionalNumber, Typer.OptionalBoolean, Typer.OptionalFunctionOrTableOrUserdataOrTrue, Typer.Any, function(_, Object, Property, EndValue, EasingFunction, Duration, Override, Callback, CallbackArgument)
	-- local TypeSuccess, TypeError = CallTuple(EasingFunction, Duration, Override, Callback, CallbackArgument)
	-- if not TypeSuccess then
	-- 	error(TypeError, 2)
	-- end

	Duration = Duration or 1
	local LerpFunction = Lerps[typeof(EndValue)]
	local StartValue = Object[Property]
	EasingFunction = type(EasingFunction) == "userdata" and EasingFunctions[EasingFunction.Value] or EasingFunction or Linear

	local self = setmetatable({
		CallbackArgument = CallbackArgument;
		Duration = Duration;
		EasingFunction = EasingFunction;
		EndValue = EndValue;
		FinishedCallback = Callback;
		LerpFunction = LerpFunction;
		Object = Object;
		Property = Property;
		StartValue = StartValue;
	}, Tween)

	function self.Interpolator(Step)
		local ElapsedTime = self.ElapsedTime + Step
		self.ElapsedTime = ElapsedTime

		if Duration > ElapsedTime then
			Object[Property] = LerpFunction(StartValue, EndValue, EasingFunction(ElapsedTime, 0, 1, Duration))
		else
			self:Stop(true)
			Object[Property] = EndValue
		end
	end

	local ObjectTable = OpenTweens[Object] -- Handle Overriding Interpolations

	if ObjectTable then
		local OpenTween = ObjectTable[Property]
		if OpenTween then
			if Override then
				OpenTween:Stop()
			else
				return self:Stop()
			end
		end
	else
		ObjectTable = {}
		OpenTweens[Object] = ObjectTable
	end

	ObjectTable[Property] = self
	return self:Resume()
end), script.Name)