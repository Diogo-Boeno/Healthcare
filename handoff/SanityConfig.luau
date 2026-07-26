--!strict
-- Every knob for the sanity system. Change values here, never the other scripts.

local SanityConfig = {
	MAX = 100,
	MIN = 0,
	START = 100,

	ATTRIBUTE = "Sanity", -- Player attribute the server writes / the client reads
	REMOTE = "SanityScareHit", -- RemoteEvent name (auto-created in ReplicatedStorage)
	LIGHT_TAG = "LightSource", -- CollectionService tag you put on light-emitting objects

	-- SANITY + HEALTH (server)
	DRAIN_PER_SECOND = 4, -- sanity lost per second in the dark
	REGEN_PER_SECOND = 8, -- sanity gained per second near a light
	LIGHT_CHECK_INTERVAL = 0.25, -- how often the server re-checks dark vs lit
	ZERO_HEALTH_DPS = 5, -- health lost per second while sanity is 0
	SCARE_DAMAGE = 20, -- damage per jumpscare
	SCARE_COOLDOWN = 1, -- min seconds between scares

	-- SCREEN EFFECTS (client)
	EFFECT_THRESHOLD = 0.5, -- effects + low-sanity audio start below this fraction (0..1)
	SMOOTH_SPEED = 6, -- bar/effect smoothing; higher = snappier
	EFFECTS = {
		BLUR = 24, -- blur size at 0 sanity
		SATURATION = -0.6, -- color drain (more negative = grayer)
		BRIGHTNESS = -0.15, -- darker
		CONTRAST = 0.25, -- crushed blacks
		TINT = Color3.fromRGB(120, 90, 90), -- tint pushed at max intensity
	},

	-- LOW-SANITY AUDIO (client)
	PLAYER_AUDIO = {
		BREATHING_VOLUME = 0.6,
		HEARTBEAT_VOLUME = 0.7,
		PITCH_MIN = 1.0, -- heartbeat speed at the threshold
		PITCH_MAX = 1.8, -- heartbeat speed at 0 sanity (racing)
	},

	-- HALLUCINATION (client)
	HALLUCINATION = {
		ENTITY_NAME = "Larry", -- rig at ReplicatedStorage.Entities.<name>
		LIGHT_RADIUS = 30, -- won't spawn within this many studs of a light
		SPAWN_MIN = 12, -- closest it spawns behind you (studs)
		SPAWN_MAX = 20, -- farthest it spawns behind you (studs)
		SPAWN_SPREAD = math.rad(35), -- side-to-side cone behind you
		CHECK_INTERVAL = 1.5, -- how often it tries to appear (seconds)
		BASE_CHANCE = 0.35, -- spawn chance per try in the dark...
		SANITY_BONUS = 0.5, -- ...plus this * (1 - sanity fraction)
		GAZE_DOT = 0.985, -- how dead-on you must look (1 = exact center)
		BREATHING_FALLBACK = 2, -- start breathing after this if the warn has no Ended
		DISSIPATE_TIME = 0.35, -- fade-out seconds when the flashlight dispels it
		SCARE_DESPAWN_DELAY = 1, -- seconds it lingers after a lights-off scare
	},

	-- SOUNDS: name paths under SoundService. A path ending on a Folder = random child.
	SOUNDS = {
		WARN = { "EntitiesSounds", "Warns" },
		SCREAM = { "EntitiesSounds", "Screams" },
		MONSTER_BREATHING = { "EntitiesSounds", "Breathing", "Monster" },
		PLAYER_BREATHING = { "EntitiesSounds", "Breathing", "Player" },
		HEARTBEAT = nil :: { string }?, -- optional; e.g. { "EntitiesSounds", "Heartbeat" }
	},

	-- HUD BAR. If a ScreenGui named SCREEN_NAME with a Frame named "Fill" exists,
	-- the client uses it (style it however you want). Otherwise it builds this one.
	UI = {
		SCREEN_NAME = "SanityUI",
		BAR_FULL = Color3.fromRGB(232, 232, 234), -- fill color at full sanity
		BAR_EMPTY = Color3.fromRGB(201, 61, 61), -- fill color at 0 sanity
		BAR_BG = Color3.fromRGB(21, 21, 24),
		BAR_STROKE = Color3.fromRGB(52, 52, 58),
	},
}

table.freeze(SanityConfig.EFFECTS)
table.freeze(SanityConfig.PLAYER_AUDIO)
table.freeze(SanityConfig.HALLUCINATION)
table.freeze(SanityConfig.SOUNDS)
table.freeze(SanityConfig.UI)

return table.freeze(SanityConfig)
