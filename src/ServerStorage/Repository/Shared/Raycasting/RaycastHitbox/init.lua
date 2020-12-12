local HitboxObject = require(script.HitboxObject)
local MainHandler = require(script.MainHandler)

local RaycastHitbox = {
	AttachmentName = "HitboxPoint";
	WarningMessage = true;
}

function RaycastHitbox.Initialize(Object: BasePart, IgnoreList)
	if not Object then
		error("No Object was provided!", 2)
	end

	local NewHitbox = MainHandler.Check(Object)
	if not NewHitbox then
		NewHitbox = HitboxObject.new(Object, IgnoreList)
		NewHitbox:SeekAttachments(RaycastHitbox.AttachmentName, RaycastHitbox.WarningMessage)
		MainHandler.Add(NewHitbox)
	end

	return NewHitbox
end

RaycastHitbox.Deinitialize = MainHandler.Remove

function RaycastHitbox.GetHitbox(Object: BasePart)
	return MainHandler.Check(Object, RaycastHitbox.WarningMessage)
end

return RaycastHitbox