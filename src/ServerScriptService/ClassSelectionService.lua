--[[
    Archivo: ClassSelectionService.lua
    Tipo: Script
    Ubicacion: ServerScriptService/
    Descripcion: Maneja la logica del servidor para la seleccion de clases.
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)
local CharacterFormulas = require(ReplicatedStorage.Shared.CharacterFormulas)

local CLASS_STARTING_DATA = {
	["DarkKnight"] = {
		EstadisticasBase = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"],
		Skills = {"Cyclone", "TwistingSlash", "Inner", "DeathStab"}
	},
	["DarkWizard"] = {
		EstadisticasBase = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"],
		Skills = {"EnergyBall", "EvilSpirit", "ManaShield", "IceStorm"}
	},
	["FairyElf"] = {
		EstadisticasBase = CharacterFormulas.CLASS_BASE_STATS["FairyElf"],
		Skills = {"TripleShot", "GreaterDefense", "GreaterDamage", "IceShot"}
	}
}

Comm.Server:On("SelectClass", function(player, selectedClass)
	local profile = DataManager:GetProfile(player)
	if not profile or profile.Data.Clase ~= "Default" then
		return
	end

	local classData = CLASS_STARTING_DATA[selectedClass]
	if not classData then
		warn("El jugador", player.Name, "intent� seleccionar una clase inv�lida:", selectedClass)
		return
	end

	profile.Data.Clase = selectedClass
	profile.Data.EstadisticasBase = classData.EstadisticasBase
	profile.Data.Skills = classData.Skills
	profile.Data.PuntosDeStatsDisponibles = 0

	print("[ClassSelection] El jugador", player.Name, "ha seleccionado la clase:", selectedClass)

	player:LoadCharacter()
end)

local function checkPlayerClass(player)
	print("[ClassSelection] Revisando la clase para el jugador:", player.Name)

	local profile = DataManager:GetProfile(player)
	local wait_cycles = 0

	while not profile and wait_cycles < 10 do
		print("[ClassSelection] El perfil de", player.Name, "no est� listo, esperando...")
		task.wait(0.5)
		profile = DataManager:GetProfile(player)
		wait_cycles = wait_cycles + 1
	end

	if not profile then
		warn("[ClassSelection] Tiempo de espera agotado para el perfil de:", player.Name)
		return
	end

	print("[ClassSelection] Perfil encontrado. La clase actual es:", profile.Data.Clase)

	if profile.Data.Clase == "Default" then
		print("[ClassSelection] La clase es 'Default'. Mostrando la GUI de selecci�n.")
		Comm.Server:Fire(player, "ShowClassSelection")
	else
		print("[ClassSelection] El jugador ya tiene una clase. Omitiendo GUI.")
	end
end

Players.PlayerAdded:Connect(checkPlayerClass)
