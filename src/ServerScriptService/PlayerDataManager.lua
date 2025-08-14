--[[
    Archivo: PlayerDataManager.lua
    Tipo: ModuleScript
    Ubicacion: ServerScriptService/
    Descripcion: Maneja el guardado y carga de datos de jugadores.
--]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local ProfileService = require(ServerScriptService.ProfileService)
local PlayerConfig = require(ReplicatedStorage.Shared.PlayerConfig)
local Formulas = require(ReplicatedStorage.Shared.CharacterFormulas)

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData_v1.2",
	PlayerConfig
)

local Profiles = {}
local DataManager = {}

function DataManager:GetProfile(player)
	return Profiles[player]
end

function DataManager:CalculateDerivedStats(profile)
	local data = profile.Data
	local stats = data.EstadisticasBase

	profile.DerivedStats = {}
	profile.DerivedStats.MaxHP = Formulas.calculateMaxHP(data.Clase, data.Nivel, stats.Vitalidad)
	profile.DerivedStats.MaxMP = Formulas.calculateMaxMP(data.Clase, data.Nivel, stats.Energia)

	local totalAgility = stats.Agilidad 
	local attackSpeedStat = Formulas.calculateAttackSpeed(totalAgility)
	profile.DerivedStats.TimeMultiplier = Formulas.calculateTimeMultiplier(attackSpeedStat)
end

local function onPlayerAdded(player)
	local profile

	if IS_STUDIO then
		local MockData = require(ServerScriptService.MockData)
		profile = MockData.LoadProfileAsync(player)
	else
		local success, result = pcall(function()
			return ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
		end)

		if not success then
			warn("Error cr?tico al intentar cargar el perfil para " .. player.Name .. ": " .. tostring(result))
			player:Kick("Error cr?tico del servidor al cargar tu perfil. Intenta de nuevo.")
			return
		end
		profile = result
	end

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Tu perfil ha sido liberado. Por favor, ?nete de nuevo.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			DataManager:CalculateDerivedStats(profile)
			print("Perfil cargado para", player.Name)
		else
			profile:Release()
		end
	else
		warn("No se pudo cargar el perfil para " .. player.Name .. ". Causa probable: Throttling de DataStore.")
		player:Kick("No se pudo cargar tu perfil (servidor ocupado). Intenta de nuevo en unos minutos.")
	end
end

local function onPlayerRemoving(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

return DataManager
