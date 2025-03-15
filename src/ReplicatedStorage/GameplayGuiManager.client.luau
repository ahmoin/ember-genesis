--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Levels = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Levels"))
local Quests = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Quests"))
local doTypewriterEffect = require(ReplicatedStorage:WaitForChild("Utility"):WaitForChild("doTypewriterEffect"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local refundStatsRemote = remotes:WaitForChild("RefundStats")
local spendStatsRemote = remotes:WaitForChild("SpendStatPoints")
local acceptQuestRemote = remotes:WaitForChild("AcceptQuest")

local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local gameplayGui = playerGui:WaitForChild("GameplayGui")

local menuButtonsFrame = gameplayGui:WaitForChild("MenuButtonsFrame")
local menuButton = menuButtonsFrame:WaitForChild("MenuButton")
local statsButton = menuButtonsFrame:WaitForChild("StatsButton")
local itemsButton = menuButtonsFrame:WaitForChild("ItemsButton")

local statsFrame = gameplayGui:WaitForChild("StatsFrame")
local itemsFrame = gameplayGui:WaitForChild("ItemsFrame")

local statsContainerFrame = statsFrame:WaitForChild("ContainerFrame")
local meleeFrame = statsContainerFrame:WaitForChild("MeleeFrame")
local defenseFrame = statsContainerFrame:WaitForChild("DefenseFrame")
local swordFrame = statsContainerFrame:WaitForChild("SwordFrame")
local gunFrame = statsContainerFrame:WaitForChild("GunFrame")
local fruitFrame = statsContainerFrame:WaitForChild("FruitFrame")
local footerFrame = statsContainerFrame:WaitForChild("FooterFrame")
local refundStatsButton = footerFrame:WaitForChild("RefundStatsButton")
local statPointsLabel = footerFrame:WaitForChild("StatPointsLabel")
local statPointsAmountTextBox = statsContainerFrame:WaitForChild("HeaderFrame"):WaitForChild("TextBox")
local dialogFrame = gameplayGui:WaitForChild("DialogFrame")
local dialogMainFrame = dialogFrame:WaitForChild("MainFrame")
local dialogSkipButton = dialogMainFrame:WaitForChild("SkipButton")
local dialogContainerFrame = dialogMainFrame:WaitForChild("ContainerFrame")
local dialogLabel = dialogContainerFrame:WaitForChild("DialogLabel")
local dialogNameLabel = dialogContainerFrame:WaitForChild("NameLabel")
local dialogOptionsFrame = dialogFrame:WaitForChild("OptionsFrame")
local dialogOptionsContainerFrame = dialogOptionsFrame:WaitForChild("ContainerFrame")
local lastDialogOption = dialogOptionsContainerFrame:WaitForChild("Option4")
local questFrame = gameplayGui:WaitForChild("QuestFrame")
local questLabel = questFrame:WaitForChild("QuestLabel")
local questProgressLabel = questFrame:WaitForChild("ProgressLabel")
local experienceFrame = gameplayGui:WaitForChild("ExperienceFrame")
local experienceBarFrame = experienceFrame:WaitForChild("BarFrame")
local experienceLabel = experienceFrame:WaitForChild("ExperienceLabel")
local levelLabel = experienceLabel:WaitForChild("LevelLabel")
local zoneAlertFrame = gameplayGui:WaitForChild("ZoneAlertFrame")

local statFrames = { meleeFrame, defenseFrame, swordFrame, gunFrame, fruitFrame }

local frameToStatType = {
	[meleeFrame] = "meleeStat",
	[defenseFrame] = "defenseStat",
	[swordFrame] = "swordStat",
	[gunFrame] = "gunStat",
	[fruitFrame] = "fruitStat",
} :: { [Frame]: string }

local npcs = Workspace:WaitForChild("NPCs")

local lastClickedSkipButton = 0
local finishedSignal: any
local dialogTypewriterTween: Tween?
local lastZone = ""
local initialExpChanged = true
local lastLevel = 0

local function onMenuButtonActivated()
	local newText = menuButton.Text == "Menu" and "Close" or "Menu"

	for _, child in menuButtonsFrame:GetChildren() do
		if child == menuButton then
			continue
		end
		child.Visible = newText == "Close"
	end
	menuButton.Text = newText
end

local function onStatsButtonActivated()
	statsFrame.Visible = not statsFrame.Visible
end

local function onItemsButtonActivated()
	itemsFrame.Visible = not itemsFrame.Visible
end

local function onRefundStatsButtonActivated()
	refundStatsRemote:FireServer()
end

local function onStatPointsAttributeChanged()
	local statPoints = player:GetAttribute(Constants.STAT_POINTS_ATTRIBUTE) or 0
	if type(statPoints) ~= "number" then
		return
	end

	local statString = tostring(statPoints)
	if type(statString) ~= "string" then
		return
	end

	statPointsLabel.Text = statString
end

local function onIncreaseButtonActivated(statFrame: Frame)
	local statType = statFrame.Name
	local statNumber = statType == "MeleeFrame" and 1
		or statType == "DefenseFrame" and 2
		or statType == "SwordFrame" and 3
		or statType == "GunFrame" and 4
		or statType == "FruitFrame" and 5
	local textBoxText = statPointsAmountTextBox.Text
	local amount = tonumber(textBoxText)
	if type(amount) ~= "number" then
		return
	end
	spendStatsRemote:FireServer(statNumber, amount)
end

local function onStatAttributeChanged(statAttribute: string, statLabel: TextLabel)
	local statValue = player:GetAttribute(statAttribute)
	if type(statValue) ~= "number" then
		return
	end
	local statNumber = tostring(statValue)
	if type(statNumber) ~= "string" then
		return
	end
	statLabel.Text = statNumber
end

local function setupStatFrame(statFrame: Frame)
	local increaseButton = statFrame:WaitForChild("IncreaseButton")
	if not increaseButton or not increaseButton:IsA("GuiButton") then
		return
	end
	local statLabel = increaseButton:WaitForChild("StatLabel")
	if not statLabel or not statLabel:IsA("TextLabel") then
		return
	end
	increaseButton.Activated:Connect(function()
		onIncreaseButtonActivated(statFrame)
	end)
	local statAttribute = frameToStatType[statFrame]
	onStatAttributeChanged(statAttribute, statLabel)
	player:GetAttributeChangedSignal(statAttribute):Connect(function()
		onStatAttributeChanged(statAttribute, statLabel)
	end)
end

local function setupStatFrames()
	for _, statFrame in statFrames do
		setupStatFrame(statFrame)
	end
end

local function toggleAllPromptVisibility(isVisible: boolean)
	for _, npc in npcs:GetChildren() do
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			continue
		end
		local rootPart = humanoid.RootPart
		if not rootPart then
			continue
		end
		local proximityPrompt = rootPart:FindFirstChildOfClass("ProximityPrompt")
		if not proximityPrompt then
			continue
		end
		proximityPrompt.Enabled = isVisible
	end
end

local function hideDialogFrame()
	TweenService:Create(dialogFrame, Constants.DEFAULT_TWEEN_INFO, {
		Position = UDim2.fromScale(0.5, 2),
	}):Play()
	task.delay(0.1, function()
		dialogFrame.Visible = false
		toggleAllPromptVisibility(true)
	end)
end

local function onAcceptQuestButtonActivated()
	hideDialogFrame()
	acceptQuestRemote:FireServer()
end

local function onSkipButtonActivated()
	local currentTime = os.clock()
	if currentTime - lastClickedSkipButton <= 0.4 then
		if typeof(dialogTypewriterTween) == "Instance" and dialogTypewriterTween:IsA("Tween") then
			dialogTypewriterTween:Cancel()
		end
		dialogLabel.MaxVisibleGraphemes = -1
		if typeof(finishedSignal) == "table" then
			if finishedSignal.Fire then
				finishedSignal:Fire()
			end
			if finishedSignal.DisconnectAll then
				finishedSignal:DisconnectAll()
			end
		end
	end
	lastClickedSkipButton = currentTime
end

local function onPromptTriggered(prompt: ProximityPrompt, triggeredPlayer: Player)
	if triggeredPlayer and triggeredPlayer ~= player then
		return
	end
	local name = prompt:GetAttribute(Constants.NAME_ATTRIBUTE)
	if type(name) ~= "string" then
		return
	end

	local dialog = prompt:GetAttribute(Constants.DIALOG_ATTRIBUTE)
	if type(dialog) ~= "string" then
		return
	end

	dialogNameLabel.Text = name
	for index = 1, 4 do
		local dialogOptionButton = dialogOptionsContainerFrame:FindFirstChild("Option" .. tostring(index))
		if not dialogOptionButton or not dialogOptionButton:IsA("TextButton") then
			continue
		end
		dialogOptionButton.Visible = false
	end

	dialogMainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	dialogMainFrame.Position = UDim2.fromScale(0.5, 0.5)
	dialogFrame.Position = UDim2.fromScale(0.5, 2)
	TweenService:Create(dialogFrame, Constants.DEFAULT_TWEEN_INFO, {
		Position = UDim2.fromScale(0.5, 0.9),
	}):Play()

	if type(finishedSignal) == "table" and finishedSignal.DisconnectAll then
		finishedSignal:DisconnectAll()
	end
	if typeof(dialogTypewriterTween) == "Instance" and dialogTypewriterTween:IsA("Tween") then
		dialogTypewriterTween:Cancel()
	end
	finishedSignal, dialogTypewriterTween = doTypewriterEffect(dialog, dialogLabel)

	finishedSignal:Once(function()
		TweenService:Create(dialogMainFrame, Constants.DEFAULT_TWEEN_INFO, {
			Position = UDim2.fromScale(0, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
		}):Play()
		for index = 1, 4 do
			local dialogOptionButton = dialogOptionsContainerFrame:FindFirstChild("Option" .. tostring(index))
			if not dialogOptionButton or not dialogOptionButton:IsA("TextButton") then
				continue
			end
			local optionText = prompt:GetAttribute("option" .. tostring(index))
			dialogOptionButton.Visible = optionText ~= nil and optionText ~= ""
			if type(optionText) == "string" then
				dialogOptionButton.Text = optionText
			end
		end
		local acceptButtonName = prompt:GetAttribute(Constants.ACCEPT_QUEST_BUTTON_ATTRIBUTE)
		local acceptQuestButton = type(acceptButtonName) == "string"
			and dialogOptionsContainerFrame:FindFirstChild(acceptButtonName)
		if
			type(acceptButtonName) == "string"
			and typeof(acceptQuestButton) == "Instance"
			and acceptQuestButton:IsA("GuiButton")
		then
			acceptQuestButton.Visible = true
		end
	end)

	dialogFrame.Visible = true
	toggleAllPromptVisibility(false)
	local acceptButtonName = prompt:GetAttribute(Constants.ACCEPT_QUEST_BUTTON_ATTRIBUTE)
	if type(acceptButtonName) ~= "string" then
		return
	end
	local acceptQuestButton = dialogOptionsContainerFrame:FindFirstChild(acceptButtonName)
	if not acceptQuestButton or not acceptQuestButton:IsA("GuiButton") then
		return
	end
	acceptQuestButton.Activated:Once(onAcceptQuestButtonActivated)
end

local function onQuestIdAttributeChanged()
	local questId = player:GetAttribute(Constants.QUEST_ID_ATTRIBUTE)
	local isVisible = type(questId) == "number" and questId ~= -1
	local oldVisibility = questFrame.Visible
	if isVisible ~= oldVisibility then
		if isVisible then
			questFrame.Position = UDim2.fromScale(0.99, 2)
			questFrame.Visible = true
			TweenService:Create(questFrame, Constants.DEFAULT_TWEEN_INFO, {
				Position = UDim2.fromScale(0.99, 0.982),
			}):Play()
		else
			questFrame.Position = UDim2.fromScale(0.99, 0.982)
			TweenService:Create(questFrame, Constants.DEFAULT_TWEEN_INFO, {
				Position = UDim2.fromScale(0.99, 2),
			}):Play()
			task.delay(0.1, function()
				if not isVisible then
					questFrame.Visible = false
				end
			end)
		end
	end

	local quest = Quests[questId]
	if not quest then
		return
	end

	questLabel.Text = quest.questLabel
	questProgressLabel.Text = string.format(quest.progressLabelFormat, 0, quest.amount)
end

local function onQuestProgressAttributeChanged()
	local questProgress = player:GetAttribute(Constants.QUEST_PROGRESS_ATTRIBUTE)
	local questId = player:GetAttribute(Constants.QUEST_ID_ATTRIBUTE)
	if type(questProgress) ~= "number" or type(questId) ~= "number" then
		return
	end

	local quest = Quests[questId]
	if not quest then
		return
	end

	questProgressLabel.Text = string.format(quest.progressLabelFormat, questProgress, quest.amount)
end

local function onExpAttributeChanged()
	local exp = player:GetAttribute(Constants.EXP_ATTRIBUTE)
	if type(exp) ~= "number" then
		return
	end
	local level = Levels.getLevel(exp)
	local currentLevelExp = Levels.getExpForLevel(level)
	local nextLevelExp = Levels.getExpForLevel(level + 1)
	local expNeededForNextLevel = nextLevelExp - currentLevelExp
	local leftOverExp = exp - currentLevelExp

	experienceLabel.Text = tostring(leftOverExp) .. " / " .. tostring(expNeededForNextLevel)
	levelLabel.Text = "Level: " .. tostring(level)
	experienceBarFrame.Size = UDim2.fromScale(leftOverExp / expNeededForNextLevel, 1)
	if initialExpChanged then
		lastLevel = level
	else
		if level > lastLevel then
			print("Leveled up!")
			lastLevel = level
		end
	end
	initialExpChanged = false
end

local function playZoneMusic(zone: string)
	for _, child in SoundService:GetChildren() do
		if not child:IsA("Sound") then
			continue
		end
		if child.Name == zone then
			if not child.IsPlaying then
				child.Volume = 0
				child:Play()
				local volume = child:GetAttribute(Constants.VOLUME_ATTRIBUTE) or 0.25
				if type(volume) ~= "number" then
					return
				end
				TweenService:Create(child, Constants.MEDIUM_TWEEN_INFO, { Volume = volume }):Play()
			end
		else
			if child.IsPlaying then
				TweenService:Create(child, Constants.MEDIUM_TWEEN_INFO, { Volume = 0 }):Play()
				task.delay(Constants.MEDIUM_TWEEN_INFO.Time, function()
					child:Stop()
				end)
			end
		end
	end
end

local function onZoneAttributeChanged()
	local zone = player:GetAttribute(Constants.ZONE_ATTRIBUTE)
	if type(zone) ~= "string" or zone == lastZone then
		return
	end
	lastZone = zone
	if zone == "" then
		playZoneMusic("Sea")
		return
	else
		playZoneMusic(zone)
	end
	for _, child in zoneAlertFrame:GetDescendants() do
		if child:IsA("Frame") then
			TweenService:Create(child, Constants.DEFAULT_TWEEN_INFO, {
				BackgroundTransparency = 0,
			}):Play()
		end
		if child:IsA("TextLabel") then
			child.Visible = true
			child.Text = zone
			TweenService:Create(child, Constants.DEFAULT_TWEEN_INFO, {
				TextTransparency = 0,
			}):Play()
		end
		if child:IsA("UIStroke") then
			TweenService:Create(child, Constants.DEFAULT_TWEEN_INFO, {
				Transparency = 0,
			}):Play()
		end
	end
	local size = #zone * 0.025
	TweenService:Create(zoneAlertFrame, Constants.SLOW_TWEEN_INFO, {
		Size = UDim2.new(size, 32, 0.1, 0),
	}):Play()
	task.delay(4, function()
		TweenService:Create(zoneAlertFrame, Constants.SLOW_TWEEN_INFO, {
			Size = UDim2.new(0, 32, 0.1, 0),
		}):Play()
		task.delay(2, function()
			for _, child in zoneAlertFrame:GetDescendants() do
				if child:IsA("Frame") then
					TweenService:Create(child, Constants.MEDIUM_TWEEN_INFO, {
						BackgroundTransparency = 1,
					}):Play()
				end
				if child:IsA("TextLabel") then
					child.Visible = false
				end
				if child:IsA("UIStroke") then
					TweenService:Create(child, Constants.MEDIUM_TWEEN_INFO, {
						Transparency = 1,
					}):Play()
				end
			end
		end)
	end)
end

local function initialize()
	setupStatFrames()

	menuButton.Activated:Connect(onMenuButtonActivated)
	statsButton.Activated:Connect(onStatsButtonActivated)
	itemsButton.Activated:Connect(onItemsButtonActivated)
	refundStatsButton.Activated:Connect(onRefundStatsButtonActivated)

	lastDialogOption.Activated:Connect(hideDialogFrame)

	dialogSkipButton.Activated:Connect(onSkipButtonActivated)

	player:GetAttributeChangedSignal(Constants.STAT_POINTS_ATTRIBUTE):Connect(onStatPointsAttributeChanged)
	onStatPointsAttributeChanged()

	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	player:GetAttributeChangedSignal(Constants.QUEST_ID_ATTRIBUTE):Connect(onQuestIdAttributeChanged)
	onQuestIdAttributeChanged()

	player:GetAttributeChangedSignal(Constants.QUEST_PROGRESS_ATTRIBUTE):Connect(onQuestProgressAttributeChanged)
	onQuestProgressAttributeChanged()

	player:GetAttributeChangedSignal(Constants.EXP_ATTRIBUTE):Connect(onExpAttributeChanged)
	onExpAttributeChanged()

	experienceFrame.Visible = true

	player:GetAttributeChangedSignal(Constants.ZONE_ATTRIBUTE):Connect(onZoneAttributeChanged)
	onZoneAttributeChanged()
end

initialize()
