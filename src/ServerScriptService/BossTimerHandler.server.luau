--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local bossTimers = Workspace:WaitForChild("BossTimers")
local enemies = Workspace:WaitForChild("Enemies")

local enemyTemplates = ServerStorage:WaitForChild("Enemies")

local function formatTime(seconds: number)
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60

	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function getNextHalfHour()
	local currentTime = os.time()
	local currentMinute = math.floor(currentTime / 60) % 60

	local minutesToNextHalfHour = 30 - (currentMinute % 30)

	local secondsToNextHalfHour = minutesToNextHalfHour * 60 - (currentTime % 60)

	return secondsToNextHalfHour
end

local function spawnBoss(bossName: string, pivot: CFrame)
	if enemies:FindFirstChild(bossName) then
		return
	end
	local enemyTemplate = enemyTemplates:FindFirstChild(bossName)
	if not enemyTemplate then
		return
	end
	local enemy = enemyTemplate:Clone()
	enemy:PivotTo(pivot)
	enemy.Parent = enemies
end

local function onBossTimerPartHeartbeat(bossTimerPart: BasePart)
	local billboardGui = bossTimerPart:FindFirstChildOfClass("BillboardGui")
	if not billboardGui then
		return
	end
	local timerLabel = billboardGui:FindFirstChild("TimerLabel")
	if not timerLabel or not timerLabel:IsA("TextLabel") then
		return
	end

	local remainingTime = getNextHalfHour()

	if remainingTime == 1 then
		task.delay(
			1,
			spawnBoss,
			bossTimerPart.Name,
			CFrame.new(bossTimerPart:GetPivot().Position) * CFrame.new(0, 8, 0)
		)
	end

	timerLabel.Text = "Spawns in " .. formatTime(remainingTime)
end

local function onHeartbeat()
	for _, bossTimerPart in bossTimers:GetChildren() do
		if not bossTimerPart:IsA("BasePart") then
			continue
		end
		onBossTimerPartHeartbeat(bossTimerPart)
	end
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
