--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Libraries"):WaitForChild("Signal"))

export type SerializedAnimation = {
	id: string,
	weight: number,
}

export type AnimationSet = {
	count: number,
	totalWeight: number,
	connections: { RBXScriptConnection },
	entries: {
		{
			animation: Animation,
			weight: number,
		}
	},
}

type AnimationStateR15 = {
	pose: string,

	currentAnim: string,
	currentAnimInstance: Animation?,
	currentAnimTrack: AnimationTrack?,
	currentAnimKeyframeHandler: RBXScriptConnection?,
	currentAnimSpeed: number,

	runAnimTrack: AnimationTrack?,
	runAnimKeyframeHandler: RBXScriptConnection?,

	toolAnim: string,
	toolAnimInstance: Animation?,
	toolAnimTrack: AnimationTrack?,
	currentToolAnimKeyframeHandler: RBXScriptConnection?,

	legacyToolAnim: string,
	legacyToolAnimTime: number,

	jumpAnimTime: number,
	currentlyPlayingEmote: boolean,
}

type AnimationStateR6 = {
	pose: string,

	rightShoulder: Motor6D,
	leftShoulder: Motor6D,
	rightHip: Motor6D,
	leftHip: Motor6D,
	neck: Motor6D,

	currentAnim: string,
	currentAnimInstance: Animation?,
	currentAnimTrack: AnimationTrack?,
	currentAnimKeyframeHandler: RBXScriptConnection?,
	currentAnimSpeed: number,

	toolAnim: string,
	toolAnimInstance: Animation?,
	toolAnimTrack: AnimationTrack?,
	currentToolAnimKeyframeHandler: RBXScriptConnection?,

	legacyToolAnim: string,
	legacyToolAnimTime: number,

	jumpAnimTime: number,
	currentlyPlayingEmote: boolean,
}

type AnimationEntity = {
	sets: { [string]: AnimationSet },

	meta: {
		director: Humanoid,
		performer: Humanoid,
		animator: Animator,

		preloaded: { [string]: boolean },
		parent: Instance,
	},
}

export type AnimationEntityR15 = AnimationEntity & {
	state: AnimationStateR15,
}

export type AnimationEntityR6 = AnimationEntity & {
	state: AnimationStateR6,
}

type SetMovement = (Vector3, number) -> ()
type FireState = (Enum.HumanoidStateType, ...any) -> ()

export type ManualDirector = {
	fireState: FireState,
	setMovement: SetMovement,
	humanoid: ManualHumanoid,
}

export type ManualHumanoid = {
	Died: Signal.Signal<...any>,
	Running: Signal.Signal<...any>,
	Jumping: Signal.Signal<...any>,
	Climbing: Signal.Signal<...any>,
	GettingUp: Signal.Signal<...any>,
	FreeFalling: Signal.Signal<...any>,
	FallingDown: Signal.Signal<...any>,
	Seated: Signal.Signal<...any>,
	PlatformStanding: Signal.Signal<...any>,
	Swimming: Signal.Signal<...any>,

	MoveDirection: Vector3,
	WalkSpeed: number,
}

export type AnimateController = {
	cleanup: () -> (),
	playEmote: (string | Animation) -> (boolean, AnimationTrack?),
}

export type AnimateControllerManually = AnimateController & {
	fireState: FireState,
	setMovement: SetMovement,
}

return {}
