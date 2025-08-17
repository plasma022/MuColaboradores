--[[
	ClassConfig.lua
	Base de datos de todas las clases del juego.
	Define sus stats base y equipo/habilidades iniciales.
	Ubicación: ReplicatedStorage/Shared/config/
]]

return {
	["DarkKnight"] = {
		Name = "Dark Knight",
		BaseStats = {
			STR = 28,
			AGI = 20,
			VIT = 25,
			ENE = 10,
		},
		StartingItems = {"ShortSword", "LeatherArmor"},
		StartingSkills = {"Cyclone"},
	},
	["DarkWizard"] = {
		Name = "Dark Wizard",
		BaseStats = {
			STR = 18,
			AGI = 18,
			VIT = 15,
			ENE = 30,
		},
		StartingItems = {},
		StartingSkills = {"EnergyBall"},
	},
	["FairyElf"] = {
		Name = "Fairy Elf",
		Name = "Fairy Elf",
		BaseStats = {
			STR = 22,
			AGI = 25,
			VIT = 20,
			ENE = 15,
		},
		StartingItems = {},
		StartingSkills = {"TripleShot"},
	},
}
