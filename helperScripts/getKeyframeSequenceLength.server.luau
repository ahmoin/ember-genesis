--!strict

local ServerStorage = game:GetService("ServerStorage")

local keyframeSequences = ServerStorage["RBX_ANIMSAVES"].Rig:GetChildren()

for _, keyframeSequence in keyframeSequences do
	if not keyframeSequence:IsA("KeyframeSequence") then
		continue
	end
	print(keyframeSequence.Name, keyframeSequence:GetKeyframes()[#keyframeSequence:GetKeyframes()].Time)
end
