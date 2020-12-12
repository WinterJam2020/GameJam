local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage.Resources)
local Enumeration = Resources:LoadLibrary("Enumerations")
local Table = Resources:LoadLibrary("Table")
local t = Resources:LoadLibrary("t")

return Table.Lock({
	RUN_TWEEN = 0;
	QUEUE_TWEEN = 1;
	PAUSE_TWEEN = 2;
	STOP_TWEEN = 3;

	CONFIGURATION = {
		GROUP_ID = 5302637; -- The Id of your group.
		MINIMUM_RANK_FOR_STAFF_SPAWN = 15; -- The rank at which players will spawn in staff spawns.
		MAX_SPAWN_ATTEMPTS = 10;
		DEFAULT_ROLE = "Guest";
		RAISED_VECTOR3 = Vector3.new(0, 4, 0); -- How high should they spawn above a spawn part?

		-- How the day-night cycle handles.
		DAY_NIGHT_CONSTANTS = {
			DAY_LENGTH = 60;
			TRANSITION_LENGTH = 4;
			TRANSITION_STYLE = "Smoother";
			TRANSITION_DIRECTION = "Out";
		};

		BUBBLE_CHAT = {
			-- Max number of NFC normalized codepoints a message can be.
			MAX_MESSAGE_LENGTH = 200;

			-- The amount of studs the camera has to move before a rerender occurs.
			CAMERA_CHANGED_EPSILON = 0.5;

			-- Triggers a billboard rerender when its offset (determined by the character's hitbox size) changes by this amount
			BILLBOARD_OFFSET_EPSILON = 0.5;

			SETTINGS = {
				-- The amount of time, in seconds, to wait before a bubble fades out.
				BubbleDuration = 15;

				-- The amount of messages to be displayed, before old ones disappear
				-- immediately when a new message comes in.
				MaxBubbles = 3;

				-- Styling for the bubbles. These settings will change various visual aspects.
				BackgroundColor3 = Color3.fromRGB(250, 250, 250);
				TextColor3 = Color3.fromRGB(57, 59, 61);
				TextSize = 16;
				Font = Enum.Font.GothamSemibold;
				Transparency = 0.1;
				CornerRadius = UDim.new(0, 12);
				TailVisible = true;
				Padding = 8; -- in pixels
				MaxWidth = 300; --in pixels

				-- Extra space between the head and the billboard (useful if you want to
				-- leave some space for other character billboard UIs)
				VerticalStudsOffset = 0;

				-- Space in pixels between two bubbles
				BubblesSpacing = 6;

				-- The distance (from the camera) that bubbles turn into a single bubble
				-- with ellipses (...) to indicate chatter.
				MinimizeDistance = 40;
				-- The max distance (from the camera) that bubbles are shown at
				MaxDistance = 100;
			};

			THEMES = {
				BackgroundColor = {
					Dark = Color3.fromRGB(57, 59, 61);
					Light = Color3.fromRGB(250, 250, 250);
					Friend = Color3.fromRGB(186, 151, 207);
				};

				FontColor = {
					Dark = Color3.fromRGB(250, 250, 250);
					Light = Color3.fromRGB(57, 59, 61);
					Friend = Color3.new();
				};
			};
		};

		GAME_ANALYTICS = {
			TELEPORT_SETTING_KEY = "GASessionData";

			LOG_SETTINGS = {
				MAX_CLIENT_ERRORS_TO_SEND = 10;
				MAX_SERVER_ERRORS_TO_SEND = 30;
				SERVER_LOG_RESET_TIME_SECONDS = 60 * 5;
				CLIENT_LOG_RESET_TIME_SECONDS = 60 * 15;
				CLIENT_MESSAGES_TO_SEND = {
					[Enum.MessageType.MessageError] = true;
				};

				SERVER_MESSAGES_TO_SEND = {
					[Enum.MessageType.MessageError] = true;
					[Enum.MessageType.MessageWarning] = true;
				};

				ERROR_TYPE_MAPPING  = {
					[Enum.MessageType.MessageInfo] = Enumeration.GAErrorSeverityType.Info;
					[Enum.MessageType.MessageWarning] = Enumeration.GAErrorSeverityType.Warning;
					[Enum.MessageType.MessageError] = Enumeration.GAErrorSeverityType.Error;
				};
			};
		};
	};

	REMOTE_NAMES = {
		PARTICLE_ENGINE_EVENT = "ParticleEvent";
		TIME_SYNC_REMOTE_EVENT_NAME = "TimeSyncServiceRemoteEvent";
		TIME_SYNC_REMOTE_FUNCTION_NAME = "TimeSyncServiceRemoteFunction";

		REPORT_LOG_ERRORS_REMOTE_EVENT = "GAReportLogErrorsRemoteEvent";
		SET_TELEPORT_DATA_REMOTE_EVENT = "GASetPlayerSessionIdRemoteEvent";
		GET_PLAYER_DATA_REMOTE_FUNCTION = "GAGetPlayerDataRemoteFunction";
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

		IChatMessage = t.strictInterface {
			Id = t.string;
			Name = t.string;
			Text = t.string;
			UserId = t.string;
			Timestamp = t.number;
			Adornee = t.union(t.instanceIsA("BasePart"), t.instanceIsA("Model"));
		};

		IChatMessageData = t.interface {
			Id = t.number;
			SpeakerUserId = t.number;
			FromSpeaker = t.string;
			Time = t.number;

			Message = t.optional(t.string);
		};

		IChatSettings = t.strictInterface {
			BubbleDuration = t.optional(t.number);
			MaxBubbles = t.optional(t.number);

			BackgroundColor3 = t.optional(t.Color3);
			TextColor3 = t.optional(t.Color3);
			TextSize = t.optional(t.number);
			Font = t.optional(t.enum(Enum.Font));
			Transparency = t.optional(t.number);
			CornerRadius = t.optional(t.UDim);
			TailVisible = t.optional(t.boolean);
			Padding = t.optional(t.number);
			MaxWidth = t.optional(t.number);

			VerticalStudsOffset = t.optional(t.number);

			BubblesSpacing = t.optional(t.number);

			MinimizeDistance = t.optional(t.number);
			MaxDistance = t.optional(t.number);
		};
	};

	ASSERTION_MESSAGES = {
		INVALID_ARGUMENT = "invalid argument #%d to '%s' (%s expected, got %s)"; -- 1, "message", "type", "expectedType"
	};
}, nil, script.Name)