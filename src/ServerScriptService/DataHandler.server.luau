--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

-- exp, statPoints, meleeStat, defenseStat, swordStat, gunStat, fruitStat
local DEFAULT_PLAYER_DATA = {
	0, -- exp 1
	0, -- statPoints 2
	0, -- meleeStat 3
	0, -- defenseStat 4
	0, -- swordStat 5
	0, -- gunStat 6
	0, -- fruitStat 7
	"[]", -- inventory 8
} :: { number | string }

local dataStore = DataStoreService:GetDataStore(Constants.DATA_STORE_NAME)

local function jsonDecode(encodedString: string)
	return HttpService:JSONDecode(encodedString)
end

local function jsonEncode(decodedTable: {})
	return HttpService:JSONEncode(decodedTable)
end

local function onPlayerAdded(player: Player)
	player:SetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE, Constants.DEFAULT_SPECIAL_COOLDOWNS_STRING)

	local playerDataString = dataStore:GetAsync(player.UserId) or "{}"
	local _, playerDataTable = pcall(jsonDecode, playerDataString)
	if type(playerDataTable) ~= "table" then
		playerDataTable = DEFAULT_PLAYER_DATA
	end
	if type(playerDataTable[1]) ~= "number" then
		playerDataTable[1] = DEFAULT_PLAYER_DATA[1]
	end
	if type(playerDataTable[2]) ~= "number" then
		playerDataTable[2] = DEFAULT_PLAYER_DATA[2]
	end
	if type(playerDataTable[3]) ~= "number" then
		playerDataTable[3] = DEFAULT_PLAYER_DATA[3]
	end
	if type(playerDataTable[4]) ~= "number" then
		playerDataTable[4] = DEFAULT_PLAYER_DATA[4]
	end
	if type(playerDataTable[5]) ~= "number" then
		playerDataTable[5] = DEFAULT_PLAYER_DATA[5]
	end
	if type(playerDataTable[6]) ~= "number" then
		playerDataTable[6] = DEFAULT_PLAYER_DATA[6]
	end
	if type(playerDataTable[7]) ~= "number" then
		playerDataTable[7] = DEFAULT_PLAYER_DATA[7]
	end
	if type(playerDataTable[8]) ~= "string" then
		playerDataTable[8] = DEFAULT_PLAYER_DATA[8]
	end

	player:SetAttribute(Constants.EXP_ATTRIBUTE, playerDataTable[1])
	player:SetAttribute(Constants.STAT_POINTS_ATTRIBUTE, playerDataTable[2])
	player:SetAttribute("meleeStat", playerDataTable[3])
	player:SetAttribute("defenseStat", playerDataTable[4])
	player:SetAttribute("swordStat", playerDataTable[5])
	player:SetAttribute("gunStat", playerDataTable[6])
	player:SetAttribute("fruitStat", playerDataTable[7])
	player:SetAttribute(Constants.INVENTORY_ATTRIBUTE, playerDataTable[8])
end

local function onPlayerRemoving(player: Player)
	local exp = player:GetAttribute(Constants.EXP_ATTRIBUTE) or 0
	if type(exp) ~= "number" then
		exp = 0
	end
	local statPoints = player:GetAttribute(Constants.STAT_POINTS_ATTRIBUTE) or 0
	if type(statPoints) ~= "number" then
		statPoints = 0
	end
	local meleeStat = player:GetAttribute("meleeStat") or 0
	if type(meleeStat) ~= "number" then
		meleeStat = 0
	end
	local defenseStat = player:GetAttribute("defenseStat") or 0
	if type(defenseStat) ~= "number" then
		defenseStat = 0
	end
	local swordStat = player:GetAttribute("swordStat") or 0
	if type(swordStat) ~= "number" then
		swordStat = 0
	end
	local gunStat = player:GetAttribute("gunStat") or 0
	if type(gunStat) ~= "number" then
		gunStat = 0
	end
	local fruitStat = player:GetAttribute("fruitStat") or 0
	if type(fruitStat) ~= "number" then
		fruitStat = 0
	end
	local inventoryString = player:GetAttribute(Constants.INVENTORY_ATTRIBUTE) or "[]"
	if type(inventoryString) ~= "string" then
		inventoryString = "[]"
	end

	if
		type(exp) ~= "number"
		or type(statPoints) ~= "number"
		or type(meleeStat) ~= "number"
		or type(defenseStat) ~= "number"
		or type(swordStat) ~= "number"
		or type(gunStat) ~= "number"
		or type(fruitStat) ~= "number"
		or type(inventoryString) ~= "string"
	then
		return
	end

	local playerDataTable =
		{ exp, statPoints, meleeStat, defenseStat, swordStat, gunStat, fruitStat, inventoryString } :: { number | string }

	local _, playerDataString = pcall(jsonEncode, playerDataTable)
	if type(playerDataString) ~= "string" then
		return
	end
	dataStore:SetAsync(player.UserId, playerDataString)
end

local function initialize()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

initialize()
