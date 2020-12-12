local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Scheduler = Resources:LoadLibrary("Scheduler")

local HOUR_DIFFERENCE = math.floor((os.time() - tick()) / 900 + 0.5) * 900

local SyncedPoller = {
	ClassName = "SyncedPoller";
	__tostring = function(self)
		return self.ClassName
	end;
}

SyncedPoller.__index = SyncedPoller

local function SyncedPollerLoop(self, Interval, Function)
	while 1 do
		if self._Paused then
			self._BindableEvent.Event:Wait()
		end

		-- if self._Paused then
		-- 	while self._Paused do
		-- 		self._BindableEvent.Event:Wait()
		-- 	end
		-- end

		local CurrentTime = tick() + HOUR_DIFFERENCE
		local TimeElapsed = CurrentTime + Scheduler.Wait(Interval - CurrentTime % Interval)

		if self._Running then
			Function(TimeElapsed)
		else
			break
		end
	end
end

function SyncedPoller.new(Interval, Function)
	local self = setmetatable({
		_Running = true;
		_Paused = false;
		_BindableEvent = Instance.new("BindableEvent");
	}, SyncedPoller)

	Scheduler.Spawn(SyncedPollerLoop, self, Interval, Function)
	return self
end

function SyncedPoller:__newindex(Index, Value)
	if Index == "Running" then
		assert(type(Value) == "boolean")
		self._Running = Value
	elseif Index == "Paused" then
		assert(type(Value) == "boolean")
		if not Value then
			self._Paused = false
			self._BindableEvent:Fire()
		else
			self._Paused = true
		end
	end
end

function SyncedPoller:Destroy()
	self.Running = false
	self._BindableEvent = self._BindableEvent:Destroy()
	setmetatable(self, nil)
end

return SyncedPoller