--!strict

local Constants = {
	WATER_ATTACHMENT_NAME = "waterAttachment",
	WATER_MODEL_NAME = "WaterModel",
	DATA_STORE_NAME = "main",
	NPC_COLLISION_GROUP = "npc",
	CHARACTER_COLLISION_GROUP = "character",

	WIND_COLLECTION_TAG = "windShake",

	DASH_DEBOUNCE_ATTRIBUTE = "onDashCooldown",
	DASH_KEY_CODE = Enum.KeyCode.Q,
	DASH_IMPULSE_MAGNITUDE = 128,
	DASH_DURATION = 0.5,

	MAX_LEVEL = 2700,
	EXP_ATTRIBUTE = "exp",
	STAT_POINTS_ATTRIBUTE = "statPoints",

	AGGROED_PLAYER_USER_ID_ATTRIBUTE = "aggroedPlayerUserId",

	NAME_ATTRIBUTE = "name",
	ACCEPT_QUEST_BUTTON_ATTRIBUTE = "acceptQuestButton",
	INPUT_CATEGORY_ATTRIBUTE = "inputCategory",

	QUEST_ID_ATTRIBUTE = "questId",
	QUEST_PROGRESS_ATTRIBUTE = "questProgress",

	IS_DEAD_ATTRIBUTE = "isDead",

	INITIAL_POSITION_ATTRIBUTE = "initialPosition",
	INITIAL_ORIENTATION_ATTRIBUTE = "initialOrientation",

	IS_ANIMATING_ATTRIBUTE = "isAnimating",

	DIALOG_ATTRIBUTE = "dialog",

	DEFAULT_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	MEDIUM_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
	SLOW_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),

	ZONE_ATTRIBUTE = "zone",

	ANIMATION_INDEX_ATTRIBUTE = "animationIndex",

	IS_ON_COOLDOWN_ATTRIBUTE = "isOnCooldown",
	SWING_COOLDOWN_ATTRIBUTE = "swingCooldown",

	DAMAGE_ATTRIBUTE = "damage",
	VOLUME_ATTRIBUTE = "volume",

	DISABLED_ATTRIBUTE = "disabled",
	ID_ATTRIBUTE = "id",

	HITBOX_SIZE_ATTRIBUTE = "hitboxSize",
	HITBOX_OFFSET_ATTRIBUTE = "hitboxOffset",

	SPECIAL_ONE_ATTRIBUTE = "specialOne",
	SPECIAL_TWO_ATTRIBUTE = "specialTwo",

	SPECIAL_COOLDOWNS_ATTRIBUTE = "specialCooldowns",
	DEFAULT_SPECIAL_COOLDOWNS_STRING = "0,0",

	INVENTORY_ATTRIBUTE = "inventory",
}

return Constants
