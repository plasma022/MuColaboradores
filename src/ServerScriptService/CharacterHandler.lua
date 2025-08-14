--[[
    Archivo: CharacterHandler.lua
    Tipo: Script
    Ubicacion: ServerScriptService/
    Descripcion: Gestiona la aparicion de los personajes personalizados.
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)

local isLoadingCharacter = {}

local function onCharacterDied(player)
	print(player.Name, "ha muerto. Reaparecer� en 5 segundos.")
	task.wait(5)
	if player and player:IsDescendantOf(Players) then
		isLoadingCharacter[player] = false
		player:LoadCharacter()
	end
end

local function onCharacterAdded(character, player)
	if isLoadingCharacter[player] then return end
	isLoadingCharacter[player] = true

	local profile = DataManager:GetProfile(player)
	local wait_cycles = 0
	while not profile and wait_cycles < 20 do
		print("[CharacterHandler] El perfil de", player.Name, "a�n no est� listo, esperando...")
		task.wait(0.5)
		profile = DataManager:GetProfile(player)
		wait_cycles = wait_cycles + 1
	end

	if not profile then
		warn("[CharacterHandler] No se pudo obtener el perfil de", player.Name, "despu�s de esperar.")
		isLoadingCharacter[player] = false
		return
	end

	if profile.Data.Clase == "Default" then
		print("[CharacterHandler] Jugador con clase 'Default'. Omitiendo carga de modelo personalizado.")
		isLoadingCharacter[player] = false
		return
	end

	print("[CharacterHandler] Perfil encontrado. Cargando modelo de clase:", profile.Data.Clase)

	character:Destroy()

	local characterModel = ServerStorage:FindFirstChild(profile.Data.Clase)
	if not characterModel then
		warn("[CharacterHandler] No se encontr� el modelo para la clase:", profile.Data.Clase)
		isLoadingCharacter[player] = false
		return
	end

	local newCharacter = characterModel:Clone()
	newCharacter.Name = player.Name
	player.Character = newCharacter

	local humanoid = newCharacter:WaitForChild("Humanoid")
	local derivedStats = profile.DerivedStats
	humanoid.MaxHealth = derivedStats.MaxHP
	humanoid.Health = derivedStats.MaxHP

	humanoid.Died:Connect(function()
		onCharacterDied(player)
	end)

	newCharacter.Parent = workspace

	Comm.Server:Fire(player, "InitialStatsUpdate", {
		Nivel = profile.Data.Nivel,
		Clase = profile.Data.Clase,
		MaxHP = derivedStats.MaxHP,
		CurrentHP = derivedStats.MaxHP,
		MaxMP = derivedStats.MaxMP,
		CurrentMP = derivedStats.MaxMP,
		Zen = profile.Data.Zen,
		Skills = profile.Data.Skills
	})
end

Players.PlayerAdded:Connect(function(player)
	isLoadingCharacter[player] = false
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	isLoadingCharacter[player] = nil
end)
