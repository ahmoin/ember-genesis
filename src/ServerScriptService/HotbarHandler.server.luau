--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local toolTemplatesFolder = ServerStorage:WaitForChild("Tools")
local defaultTool = toolTemplatesFolder:WaitForChild("Combat")

local function onPlayerHeartbeat(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local existingTool = backpack:FindFirstChild(defaultTool.Name) or character:FindFirstChild(defaultTool.Name)
	if existingTool then
		return
	end

	local tool = defaultTool:Clone()
	tool.Parent = backpack
end

local function onHeartbeat()
	for _, player in Players:GetPlayers() do
		onPlayerHeartbeat(player)
	end
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
