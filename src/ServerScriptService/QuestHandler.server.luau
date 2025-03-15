--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local npcs = Workspace:WaitForChild("NPCs")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local acceptQuestRemote = remotes:WaitForChild("AcceptQuest")

local function onAcceptQuestEvent(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local rootPart = humanoid.RootPart
	if not rootPart then
		return
	end

	local closetQuestNPC: Model? = nil
	local closestDistance = math.huge
	for _, npc in npcs:GetChildren() do
		if not npc:IsA("Model") then
			continue
		end

		local questId = npc:GetAttribute(Constants.QUEST_ID_ATTRIBUTE)
		if type(questId) ~= "number" then
			continue
		end

		local distance = (npc:GetPivot().Position - rootPart.Position).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closetQuestNPC = npc
		end
	end

	if not closetQuestNPC then
		return
	end

	local questId = closetQuestNPC:GetAttribute(Constants.QUEST_ID_ATTRIBUTE)
	if type(questId) ~= "number" then
		return
	end

	player:SetAttribute(Constants.QUEST_ID_ATTRIBUTE, questId)
	player:SetAttribute(Constants.QUEST_PROGRESS_ATTRIBUTE, 0)
end

local function initialize()
	acceptQuestRemote.OnServerEvent:Connect(onAcceptQuestEvent)
end

initialize()
