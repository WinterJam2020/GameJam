local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumeration")

Enumeration.DataStoreHandler = {"ForceLoad", "Steal", "Repeat", "Cancel"}
Enumeration.RectangleMode = {"AllCorners", "SingleEdge", "SingleCorner"}

Enumeration.EasingFunction = {
	"Standard";
	"Deceleration";
	"Acceleration";
	"Sharp";

	"FabricStandard";
	"FabricAccelerate";
	"FabricDecelerate";

	"UWPAccelerate";

	"Linear";

	"InSine";
	"OutSine";
	"InOutSine";
	"OutInSine";

	"InBack";
	"OutBack";
	"InOutBack";
	"OutInBack";

	"InQuad";
	"OutQuad";
	"InOutQuad";
	"OutInQuad";

	"InQuart";
	"OutQuart";
	"InOutQuart";
	"OutInQuart";

	"InQuint";
	"OutQuint";
	"InOutQuint";
	"OutInQuint";

	"InBounce";
	"OutBounce";
	"InOutBounce";
	"OutInBounce";

	"InElastic";
	"OutElastic";
	"InOutElastic";
	"OutInElastic";

	"InCirc";
	"OutCirc";
	"InOutCirc";
	"OutInCirc";

	"InCubic";
	"OutCubic";
	"InOutCubic";
	"OutInCubic";

	"InExpo";
	"OutExpo";
	"InOutExpo";
	"OutInExpo";

	"Smooth";
	"Smoother";
	"RevBack";
	"RidiculousWiggle";
	"Spring";
	"SoftSpring";
}

return Enumeration