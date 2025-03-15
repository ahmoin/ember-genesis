--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local AnimationController = {}

AnimationController.loadedAnimations = {} :: { [Animation]: AnimationTrack }

local player = Players.LocalPlayer

local function getAnimator(): Animator?
	local character = player.Character
	if not character or not character:IsDescendantOf(Workspace) then
		AnimationController.loadedAnimations = {}
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid:IsDescendantOf(Workspace) or humanoid.Health <= 0 then
		AnimationController.loadedAnimations = {}
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator or not animator:IsDescendantOf(Workspace) then
		AnimationController.loadedAnimations = {}
		return nil
	end

	return animator
end

local function playAnimationTrack(animationTrack: AnimationTrack)
	if animationTrack.IsPlaying then
		return
	end

	animationTrack:Play()
end

local function stopAnimationTrack(animationTrack: AnimationTrack)
	if not animationTrack.IsPlaying then
		return
	end

	animationTrack:Stop()
end

AnimationController.loadAnimation = function(animation: Animation)
	local animator = getAnimator()
	if not animator then
		return
	end

	local existingAnimationTrack = AnimationController.loadedAnimations[animation]
	if existingAnimationTrack then
		return
	end

	local animationTrack = animator:LoadAnimation(animation)
	AnimationController.loadedAnimations[animation] = animationTrack
end

AnimationController.playAnimation = function(animation: Animation)
	local animator = getAnimator()
	if not animator then
		return
	end

	local existingAnimationTrack = AnimationController.loadedAnimations[animation]
	if existingAnimationTrack then
		playAnimationTrack(existingAnimationTrack)
		return
	end

	local animationTrack = animator:LoadAnimation(animation)
	AnimationController.loadedAnimations[animation] = animationTrack
	playAnimationTrack(animationTrack)
end

AnimationController.stopAnimation = function(animation: Animation)
	local animator = getAnimator()
	if not animator then
		return
	end

	local existingAnimationTrack = AnimationController.loadedAnimations[animation]
	if existingAnimationTrack then
		stopAnimationTrack(existingAnimationTrack)
		return
	end

	local animationTrack = animator:LoadAnimation(animation)
	AnimationController.loadedAnimations[animation] = animationTrack
	stopAnimationTrack(animationTrack)
end

return AnimationController
