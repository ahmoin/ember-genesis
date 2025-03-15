--!strict

local Constants = {
	DASH_DURATION = 0.5,
    DASH_IMPULSE_MAGNITUDE = 128,
    MAX_LEVEL = 2700,
	ENEMEY_DESTROY_DELAY_DURATION = 2,
	ENEMY_RESPAWN_DELAY_DURATION = 16,

    IS_ANIMATING_ATTRIBUTE = "isAnimating",
    IS_DEAD_ATTRIBUTE = "isDead",
    IS_ON_COOLDOWN_ATTRIBUTE = "isOnCooldown",

    ANIMATION_INDEX_ATTRIBUTE = "animationIndex",
    DAMAGE_ATTRIBUTE = "damage",
    HITBOX_OFFSET_ATTRIBUTE = "hitboxOffset",
    HITBOX_SIZE_ATTRIBUTE = "hitboxSize",
    SWING_COOLDOWN_ATTRIBUTE = "swingCooldown",
    VOLUME_ATTRIBUTE = "volume",

    ACCEPT_QUEST_BUTTON_ATTRIBUTE = "acceptQuestButton",
    AGGROED_PLAYER_USER_ID_ATTRIBUTE = "aggroedPlayerUserId",
    CHARACTER_COLLISION_GROUP = "character",
    DASH_DEBOUNCE_ATTRIBUTE = "onDashCooldown",
    DATA_STORE_NAME = "main",
    DEFAULT_SPECIAL_COOLDOWNS_STRING = "0,0",
    DIALOG_ATTRIBUTE = "dialog",
    DISABLED_ATTRIBUTE = "disabled",
    EXP_ATTRIBUTE = "exp",
    ID_ATTRIBUTE = "id",
    INPUT_CATEGORY_ATTRIBUTE = "inputCategory",
    INVENTORY_ATTRIBUTE = "inventory",
    INITIAL_ORIENTATION_ATTRIBUTE = "initialOrientation",
    INITIAL_POSITION_ATTRIBUTE = "initialPosition",
    NAME_ATTRIBUTE = "name",
    NPC_COLLISION_GROUP = "npc",
    QUEST_ID_ATTRIBUTE = "questId",
    QUEST_PROGRESS_ATTRIBUTE = "questProgress",
    SPECIAL_COOLDOWNS_ATTRIBUTE = "specialCooldowns",
    SPECIAL_ONE_ATTRIBUTE = "specialOne",
    SPECIAL_TWO_ATTRIBUTE = "specialTwo",
    STAT_POINTS_ATTRIBUTE = "statPoints",
    WATER_ATTACHMENT_NAME = "waterAttachment",
    WATER_MODEL_NAME = "WaterModel",
    WIND_COLLECTION_TAG = "windShake",
    ZONE_ATTRIBUTE = "zone",

    DASH_KEY_CODE = Enum.KeyCode.Q,

    DEFAULT_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    MEDIUM_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
    SLOW_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

return Constants
