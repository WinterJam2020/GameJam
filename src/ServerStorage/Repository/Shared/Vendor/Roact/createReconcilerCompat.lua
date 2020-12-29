--[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local Logging = require(script.Parent.Logging)

local reifyMessage = [[
Roact.reify has been renamed to Roact.mount and will be removed in a future release.
Check the call to Roact.reify at:
]]

local teardownMessage = [[
Roact.teardown has been renamed to Roact.unmount and will be removed in a future release.
Check the call to Roact.teardown at:
]]

local reconcileMessage = [[
Roact.reconcile has been renamed to Roact.update and will be removed in a future release.
Check the call to Roact.reconcile at:
]]

local function createReconcilerCompat(reconciler)
	return {
		reify = function(...)
			Logging.warnOnce(reifyMessage)
			return reconciler.mountVirtualTree(...)
		end,

		teardown = function(...)
			Logging.warnOnce(teardownMessage)
			return reconciler.unmountVirtualTree(...)
		end,

		reconcile = function(...)
			Logging.warnOnce(reconcileMessage)
			return reconciler.updateVirtualTree(...)
		end,
	}
end

return createReconcilerCompat