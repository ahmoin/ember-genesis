--!strict

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))
local InputMetadata = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InputMetadata"))

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local instances = script.Instances :: any
local actionGui = instances.ActionGui

local HORIZONTAL_PADDING = 40
local VERTICAL_PADDING = 40

type ActionCallback = (string, Enum.UserInputState, InputObject) -> ...any

local InputCategory = {
	KeyboardAndMouse = "KeyboardAndMouse",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

local ActionManager = {
	InputCategory = InputCategory,
	_initialized = false,
	_bindings = {} :: { [string]: any },
}

function ActionManager.bindAction(
	actionName: string,
	callback: ActionCallback,
	keyboardAndMouseInput: Enum.KeyCode | Enum.UserInputType,
	gamepadInput: Enum.KeyCode | Enum.UserInputType,
	displayOrder: number?
)
	if ActionManager._bindings[actionName] then
		return
	end

	local binding = {
		connections = {},
		keyboardAndMouseInput = keyboardAndMouseInput,
		gamepadInput = gamepadInput,
	}

	local actionFrame = instances.ActionFrame:Clone()
	local contentFrame = actionFrame.ContentFrame
	contentFrame.Name = actionName
	actionFrame.LayoutOrder = displayOrder or 0
	actionFrame.Parent = actionGui.ListFrame

	binding.frame = actionFrame
	local inputCategory = player:GetAttribute(Constants.INPUT_CATEGORY_ATTRIBUTE)
	ActionManager._updateInputDisplay(binding, inputCategory, contentFrame)

	local callbackWrapper = function(...)
		local action, inputState = ...

		if action == actionName then
			if inputState == Enum.UserInputState.Begin then
				contentFrame.ActionLabel.BackgroundColor3 = Color3.new(1, 1, 1)
				contentFrame.ActionLabel.TextColor3 = Color3.new(0, 0, 0)
			elseif inputState == Enum.UserInputState.End then
				contentFrame.ActionLabel.BackgroundColor3 = Color3.new(0, 0, 0)
				contentFrame.ActionLabel.TextColor3 = Color3.new(1, 1, 1)
			end
		end

		callback(...)
	end

	table.insert(
		binding.connections,
		actionFrame.TouchButton.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.Begin, inputObject)
			end
		end)
	)

	table.insert(
		binding.connections,
		actionFrame.TouchButton.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.End, inputObject)
			end
		end)
	)

	ContextActionService:BindAction(actionName, callbackWrapper, false, keyboardAndMouseInput, gamepadInput)
	ActionManager._bindings[actionName] = binding
end

function ActionManager.unbindAction(actionName: string)
	local binding = ActionManager._bindings[actionName]
	if binding then
		for _, connection in binding.connections do
			connection:Disconnect()
		end

		binding.frame:Destroy()
		ActionManager._bindings[actionName] = nil
	end

	ContextActionService:UnbindAction(actionName)
end

function ActionManager._updateInputDisplay(binding, inputCategory, contentFrame)
	local oldButtonDisplay = contentFrame.InputFrame:FindFirstChild("ButtonDisplayFrame")
	if oldButtonDisplay then
		oldButtonDisplay:Destroy()
	end

	local buttonDisplay: Instance
	if inputCategory == InputCategory.KeyboardAndMouse then
		buttonDisplay = ActionManager._getButtonDisplayForInput(binding.keyboardAndMouseInput)
	elseif inputCategory == InputCategory.Gamepad then
		buttonDisplay = ActionManager._getButtonDisplayForInput(binding.gamepadInput)
	elseif inputCategory == InputCategory.Touch then
		buttonDisplay = ActionManager._getButtonDisplayForInput(Enum.UserInputType.Touch)
	end
	local inputFrame = contentFrame.InputFrame
	if typeof(inputFrame) == "Instance" and typeof(buttonDisplay) == "Instance" then
		buttonDisplay.Parent = inputFrame
	end

	binding.frame.TouchButton.Visible = inputCategory == InputCategory.Touch
end

function ActionManager._getButtonDisplayForInput(input: Enum.KeyCode | Enum.UserInputType)
	local buttonDisplay = instances.ButtonDisplayFrame:Clone()
	local gamepadImage
	if input.EnumType == Enum.KeyCode then
		gamepadImage = UserInputService:GetImageForKeyCode(input :: Enum.KeyCode)
	end

	if input == Enum.UserInputType.Touch then
		local touchIcon = instances.TouchImageLabel:Clone()
		touchIcon.Parent = buttonDisplay
	elseif gamepadImage and gamepadImage ~= "" then
		local gamepadIcon = instances.GamepadImageLabel:Clone()
		gamepadIcon.Image = gamepadImage
		gamepadIcon.Parent = buttonDisplay
	elseif InputMetadata.MouseButtonImage[input] then
		local mouseIcon = instances.MouseImageLabel:Clone()
		mouseIcon.Image = InputMetadata.MouseButtonImage[input]
		mouseIcon.Parent = buttonDisplay
	else
		local border = instances.KeyboardBorderImage:Clone()
		border.Parent = buttonDisplay

		local buttonTextString = UserInputService:GetStringForKeyCode(input :: Enum.KeyCode)

		local buttonTextImage = InputMetadata.KeyboardButtonImage[input]
		if not buttonTextImage then
			buttonTextImage = InputMetadata.KeyboardButtonIconMapping[buttonTextString]
		end

		if not buttonTextImage then
			local keyCodeMappedText = InputMetadata.KeyCodeToTextMapping[input :: Enum.KeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local keyboardIcon = instances.KeyboardImageLabel:Clone()
			keyboardIcon.Image = buttonTextImage
			keyboardIcon.Parent = buttonDisplay
		elseif buttonTextString and buttonTextString ~= "" then
			local keyboardText = instances.KeyboardTextLabel:Clone()
			keyboardText.Text = buttonTextString
			keyboardText.TextSize = InputMetadata.KeyCodeToFontSize[input :: Enum.KeyCode]
				or InputMetadata.DefaultFontSize
			keyboardText.Parent = buttonDisplay
		end
	end

	return buttonDisplay
end

function ActionManager._getCategoryOfInputType(inputType: Enum.UserInputType)
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

function ActionManager._getDefaultInputCategory()
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

function ActionManager._updatePositionAndScale()
	local touchControlsEnabled = playerGui:FindFirstChild("TouchGui") ~= nil
	local minScreenSize = math.min(actionGui.AbsoluteSize.X, actionGui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < 500

	local verticalPadding = VERTICAL_PADDING
	local inputCategory = player:GetAttribute(Constants.INPUT_CATEGORY_ATTRIBUTE)
	if touchControlsEnabled and inputCategory == InputCategory.Touch then
		verticalPadding += if isSmallScreen then 70 else 210
	end

	actionGui.ListFrame.UIScale.Scale = if isSmallScreen then 0.85 else 1
	actionGui.ListFrame.Position = UDim2.new(1, -HORIZONTAL_PADDING, 1, -verticalPadding)
end

local function onHeartbeat()
	local character = player.Character
	if not character then
		actionGui.Enabled = false
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then
		actionGui.Enabled = false
		return
	end
	local specialOne = tool:GetAttribute(Constants.SPECIAL_ONE_ATTRIBUTE)
	local specialTwo = tool:GetAttribute(Constants.SPECIAL_TWO_ATTRIBUTE)
	actionGui.Enabled = true

	for _, binding in ActionManager._bindings do
		local actionFrame = binding.frame
		if not actionFrame then
			continue
		end
		local contentFrame = actionFrame:FindFirstChildOfClass("Frame")
		if not contentFrame then
			continue
		end
		local actionLabel = contentFrame:FindFirstChild("ActionLabel")
		if not actionLabel then
			continue
		end
		if not actionLabel:IsA("TextLabel") then
			continue
		end
		if type(specialOne) == "string" and contentFrame.Name == Constants.SPECIAL_ONE_ATTRIBUTE then
			actionLabel.Text = specialOne
		end
		if type(specialTwo) == "string" and contentFrame.Name == Constants.SPECIAL_TWO_ATTRIBUTE then
			actionLabel.Text = specialTwo
		end
	end
end

function ActionManager._initialize()
	assert(not ActionManager._initialized, "ActionManager already initialized!")
	assert(RunService:IsClient(), "ActionManager can only be used on the client!")

	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	player:GetAttributeChangedSignal(Constants.INPUT_CATEGORY_ATTRIBUTE):Connect(function()
		local inputCategory = player:GetAttribute(Constants.INPUT_CATEGORY_ATTRIBUTE)
		for _, binding in ActionManager._bindings do
			local actionFrame = binding.frame
			local contentFrame = actionFrame and actionFrame:FindFirstChildOfClass("Frame")
			if actionFrame and contentFrame then
				ActionManager._updateInputDisplay(binding, inputCategory, contentFrame)
			end
		end
		ActionManager._updatePositionAndScale()
	end)

	actionGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ActionManager._updatePositionAndScale)

	actionGui.Parent = playerGui
	actionGui.Enabled = false
	ActionManager._updatePositionAndScale()

	onHeartbeat()
	RunService.Heartbeat:Connect(onHeartbeat)

	ActionManager._initialized = true
end

ActionManager._initialize()

return ActionManager
