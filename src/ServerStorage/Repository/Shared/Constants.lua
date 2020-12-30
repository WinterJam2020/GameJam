local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

return Table.Lock({
	RUN_TWEEN = 0;
	QUEUE_TWEEN = 1;
	PAUSE_TWEEN = 2;
	STOP_TWEEN = 3;

	SPAWN_AT_TOP = 4;
	REPLICATE_POSITION = 5;

	READY_PLAYER = 6;
	GET_SPLINE_ALPHA = 7;

	DISPLAY_LEADERBOARD = 8; -- GameEvent:FireAllClients(Constants.DISPLAY_LEADERBOARD)
	HIDE_LEADERBOARD = 9; -- GameEvent:FireAllClients(Constants.HIDE_LEADERBOARD)

	SHOW_MENU = 10; -- GameEvent:FireAllClients(Constants.SHOW_MENU)
	HIDE_MENU = 11; -- GameEvent:FireAllClients(Constants.HIDE_MENU)

	SHOW_COUNTDOWN = 13; -- GameEvent:FireAllClients(Constants.SHOW_COUNTDOWN)
	HIDE_COUNTDOWN = 14; -- GameEvent:FireAllClients(Constants.HIDE_COUNTDOWN)
	IS_COUNTDOWN_ACTIVE = 15; -- GameEvent:FireAllClients(Constants.IS_COUNTDOWN_ACTIVE, bool Active)
	SET_COUNTDOWN_DURATION = 16; -- GameEvent:FireAllClients(Constants.SET_COUNTDOWN_DURATION, int Length)

	RESET_UI = 17; -- GameEvent:FireAllClients(Constants.RESET_UI)

	SPAWN_CHARACTER = 18;
	DESPAWN_CHARACTER = 19;
	START_SKIING = 20;
	STOP_SKIING = 21;

	CONFIGURATION = {
		RAGDOLL_TAG_NAME = "PlayerRagdoll";

		-- How the day-night cycle handles.
		DAY_NIGHT_CONSTANTS = {
			DAY_LENGTH = 60;
			TRANSITION_LENGTH = 4;
			TRANSITION_STYLE = "Smoother";
			TRANSITION_DIRECTION = "Out";
		};
	};

	REMOTE_NAMES = {
		PARTICLE_ENGINE_EVENT = "ParticleEvent";
		TIME_SYNC_REMOTE_EVENT_NAME = "TimeSyncServiceRemoteEvent";
		TIME_SYNC_REMOTE_FUNCTION_NAME = "TimeSyncServiceRemoteFunction";
		ANALYTICS_REMOTE_EVENT_NAME = "AnalyticsEvent";
		SKI_PATH_REMOTE_FUNCTION_NAME = "SkiPathRemoteFunction";
	};

	TYPE_CHECKS = {
		IParticleProperties = t.interface {
			Position = t.Vector3;
			Global = t.optional(t.boolean);
			Velocity = t.optional(t.Vector3);
			Gravity = t.optional(t.Vector3);
			WindResistance = t.optional(t.number);
			Lifetime = t.optional(t.number);
			Size = t.optional(t.Vector2);
			Bloom = t.optional(t.Vector2);
			Transparency = t.optional(t.number);
			Color = t.optional(t.Color3);
			Occlusion = t.optional(t.boolean);
			RemoveOnCollision = t.optional(t.union(t.callback, t.boolean));
			Function = t.optional(t.callback);
		};
	};

	ASSERTION_MESSAGES = {
		INVALID_ARGUMENT = "invalid argument #%d to '%s' (%s expected, got %s)"; -- 1, "message", "type", "expectedType"
	};

	SKI_PATH = {
		TERRAIN_WIDTH = 100;
		PATH_WIDTH = 40;
		NUM_GATES = 50;
		SCALE_FACTOR = 100; -- scales up the ski path 100x
		MAX_BANK_ANGLE = math.rad(60);
		WEDGE_DEPTH = 4; -- terrain depth in studs
		DEBUG = false;
	}
}, nil, script.Name)