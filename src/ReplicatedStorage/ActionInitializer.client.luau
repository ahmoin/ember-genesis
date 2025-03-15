--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionManager = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("ActionManager"))
local AnimationController = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("AnimationController"))
local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Signals = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Signals"))
local Specials = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Specials"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local useSpecialRemote = remotes:WaitForChild("UseSpecial")

local animations = ReplicatedStorage:WaitForChild("Animations")

local player = Players.LocalPlayer

local function doSpecial(action: string)
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		return
	end
	local specialName = tool:GetAttribute(action)
	if type(specialName) ~= "string" then
		return
	end
	local specialTable = Specials.specialMoves[specialName]
	if type(specialTable) ~= "table" then
		return
	end

	local cooldownString = player:GetAttribute(Constants.SPECIAL_COOLDOWNS_ATTRIBUTE)
	if type(cooldownString) ~= "string" then
		return
	end
	local specialIndex = specialTable.specialIndex
	local cooldownValue = tonumber(Specials.getValueAtIndex(specialIndex, cooldownString))
	if type(cooldownValue) ~= "number" or cooldownValue > 0 then
		return
	end

	if specialTable.doDash then
		Signals.doDashSignal:Fire()
	end
	local specialAnimation = animations:FindFirstChild(specialName)
	if not specialAnimation or not specialAnimation:IsA("Animation") then
		return
	end
	AnimationController.playAnimation(specialAnimation)
end

local function actionHandler(action: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.End then
		return
	end
	local index = (action == Constants.SPECIAL_ONE_ATTRIBUTE and 1) or (action == Constants.SPECIAL_TWO_ATTRIBUTE and 2)
	if type(index) ~= "number" then
		return
	end
	useSpecialRemote:FireServer(index)
	doSpecial(action)
end

local function initialize()
	ActionManager.bindAction(Constants.SPECIAL_ONE_ATTRIBUTE, actionHandler, Enum.KeyCode.Z, Enum.KeyCode.ButtonX, 1)
	ActionManager.bindAction(Constants.SPECIAL_TWO_ATTRIBUTE, actionHandler, Enum.KeyCode.X, Enum.KeyCode.ButtonY, 2)
end

initialize()
