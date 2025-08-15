--[[
    Archivo: ClassSelectionService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja la lgica del servidor para la seleccin de clases.
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)
local CharacterFormulas = require(ReplicatedStorage.Shared.CharacterFormulas)

-- Diccionario con los datos iniciales de cada clase para una transicin fcil.
local CLASS_STARTING_DATA = {
	["DarkKnight"] = {
		-- == CORRECCIN CLAVE: Ahora se asignan los stats con los nombres correctos ==
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["DarkKnight"].Energia,
		},
		Skills = {"Cyclone", "TwistingSlash", "Inner", "DeathStab"}
	},
	["DarkWizard"] = {
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["DarkWizard"].Energia,
		},
		Skills = {"EnergyBall", "EvilSpirit", "ManaShield", "IceStorm"}
	},
	["FairyElf"] = {
		EstadisticasBase = {
			Fuerza = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Fuerza,
			Agilidad = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Agilidad,
			Vitalidad = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Vitalidad,
			Energia = CharacterFormulas.CLASS_BASE_STATS["FairyElf"].Energia,
		},
		Skills = {"TripleShot", "GreaterDefense", "GreaterDamage", "IceShot"}
	}
}

-- Escuchamos el evento que enva el cliente desde la GUI de seleccin.
Comm.Server:On("SelectClass", function(player, selectedClass)
	local profile = DataManager:GetProfile(player)
	if not profile or profile.Data.Clase ~= "Default" then
		return
	end

	local classData = CLASS_STARTING_DATA[selectedClass]
	if not classData then
		warn("El jugador", player.Name, "intent seleccionar una clase invlida:", selectedClass)
		return
	end

	-- Actualizamos el perfil del jugador con los datos de la nueva clase.
	profile.Data.Clase = selectedClass
	profile.Data.EstadisticasBase = classData.EstadisticasBase
	profile.Data.Skills = classData.Skills
	profile.Data.PuntosDeStatsDisponibles = 0

	DataManager:CalculateDerivedStats(profile)
    DataManager:sendFullStatsToClient(player)

	print("[ClassSelection] El jugador", player.Name, "ha seleccionado la clase:", selectedClass)

	player:LoadCharacter()
end)

-- Esta funcin revisa si el jugador necesita elegir una clase al entrar.
local function checkPlayerClass(player)
	print("[ClassSelection] Revisando la clase para el jugador:", player.Name)

	local profile = DataManager:GetProfile(player)
	local wait_cycles = 0

	while not profile and wait_cycles < 10 do
		print("[ClassSelection] El perfil de", player.Name, "no est listo, esperando...")
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
		print("[ClassSelection] La clase es 'Default'. Mostrando la GUI de seleccin.")
		Comm.Server:Fire(player, "ShowClassSelection")
	else
		print("[ClassSelection] El jugador ya tiene una clase. Omitiendo GUI.")
	end
end

Players.PlayerAdded:Connect(checkPlayerClass)