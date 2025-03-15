--!strict

type Quest = {
	questLabel: string,
	progressLabelFormat: string,
	amount: number,
	exp: number,
}

local Quests = {
	{
		questLabel = "Defending Orkney Village",
		progressLabelFormat = "Defeat 5 Brigands - %d/%d",
		amount = 5,
		exp = 100,
	},
	{
		questLabel = "Destroying the Disruptive Magic",
		progressLabelFormat = "Defeat 5 Wandering Mages - %d/%d",
		amount = 5,
		exp = 1000,
	},
} :: { Quest }

return Quests
