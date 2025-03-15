--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Signal = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Signal"))

local function onTweenCompleted(textLabel: TextLabel, finishedSignal: any, tween: Tween?)
	if typeof(tween) == "Instance" and tween:IsA("Tween") then
		tween:Cancel()
	end
	textLabel.MaxVisibleGraphemes = -1
	if typeof(finishedSignal) == "table" then
		if finishedSignal.Fire then
			finishedSignal:Fire()
		end
		if finishedSignal.DisconnectAll then
			finishedSignal:DisconnectAll()
		end
	end
end

local function doTypewriterEffect(text: string, textLabel: TextLabel)
	textLabel.MaxVisibleGraphemes = 0
	textLabel.Text = text

	local amountOfGraphemes = 0
	for _ in utf8.graphemes(text) do
		amountOfGraphemes += 1
	end

	local tweenInfo = TweenInfo.new(0.02 * amountOfGraphemes, Enum.EasingStyle.Linear)
	local typewriterTween = TweenService:Create(textLabel, tweenInfo, { MaxVisibleGraphemes = amountOfGraphemes })
	typewriterTween:Play()
	local finishedSignal = Signal.new()
	typewriterTween.Completed:Once(function()
		onTweenCompleted(textLabel, finishedSignal)
	end)

	return finishedSignal, typewriterTween
end

return doTypewriterEffect
