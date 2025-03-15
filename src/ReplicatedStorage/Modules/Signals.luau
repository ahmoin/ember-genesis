--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Signal"))

local Signals = {
	doDashSignal = Signal.new(),
}

return Signals
