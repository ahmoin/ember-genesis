--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local Signal = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Signal"))

type ActionCallback = (string, Enum.UserInputState, InputObject) -> ...any

local InputCategory = {
	KeyboardAndMouse = "KeyboardAndMouse",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

local lastInputCategory = InputCategory.Unknown
local lastInputCategoryChanged = Signal.new()

local player = Players.LocalPlayer

local function setLastInputCategory(inputCategory: string)
	if lastInputCategory == inputCategory then
		return
	end

	lastInputCategory = inputCategory
	lastInputCategoryChanged:Fire(inputCategory)
end

local function getCategoryOfInputType(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		return InputCategory.Gamepad
	elseif inputType == Enum.UserInputType.Keyboard or string.find(inputType.Name, "Mouse") then
		return InputCategory.KeyboardAndMouse
	elseif inputType == Enum.UserInputType.Touch then
		return InputCategory.Touch
	else
		return InputCategory.Unknown
	end
end

local function onInputTypeChanged(inputType: Enum.UserInputType)
	local inputCategory = getCategoryOfInputType(inputType)
	if inputCategory ~= InputCategory.Unknown then
		setLastInputCategory(inputCategory)
	end
end

local function getDefaultInputCategory()
	local lastInputType = UserInputService:GetLastInputType()
	lastInputCategory = getCategoryOfInputType(lastInputType)

	if lastInputCategory ~= InputCategory.Unknown then
		return lastInputCategory
	end

	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return InputCategory.KeyboardAndMouse
	elseif UserInputService.TouchEnabled then
		return InputCategory.Touch
	elseif UserInputService.GamepadEnabled then
		return InputCategory.Gamepad
	else
		return InputCategory.Unknown
	end
end

local function onLastInputCategoryChanged()
	player:SetAttribute(Constants.INPUT_CATEGORY_ATTRIBUTE, lastInputCategory)
end

local function initialize()
	UserInputService.LastInputTypeChanged:Connect(onInputTypeChanged)

	local defaultInputCategory = getDefaultInputCategory()
	setLastInputCategory(defaultInputCategory)

	lastInputCategoryChanged:Connect(onLastInputCategoryChanged)

	onLastInputCategoryChanged()
end

initialize()
