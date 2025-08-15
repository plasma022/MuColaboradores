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
local Comm = require(ReplicatedStorage.Shared.Comm)

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

	-- Si los datos de HP/MP actuales no existen (ej. un jugador antiguo),
	-- o si son mayores al mximo (ej. por un nerf), los ajustamos.
	if data.CurrentHP == nil or data.CurrentHP > profile.DerivedStats.MaxHP then
		data.CurrentHP = profile.DerivedStats.MaxHP
	end
	if data.CurrentMP == nil or data.CurrentMP > profile.DerivedStats.MaxMP then
		data.CurrentMP = profile.DerivedStats.MaxMP
	end

	-- Nuevos stats derivados para la UI
	local minDamage, maxDamage = Formulas.calculateDamageRange(data.Clase, stats.Fuerza, stats.Agilidad)
	profile.DerivedStats.TotalDamage = string.format("%d - %d", minDamage, maxDamage)

	local attackSpeedStat = Formulas.calculateAttackSpeed(data.Clase, stats.Agilidad)
	profile.DerivedStats.TotalAttackSpeed = attackSpeedStat
	profile.DerivedStats.TotalDefense = Formulas.calculateDefense(stats.Agilidad)

	profile.DerivedStats.TimeMultiplier = Formulas.calculateTimeMultiplier(attackSpeedStat)
end

function DataManager:GetFullStats(profile)
	local data = profile.Data
	local stats = data.EstadisticasBase
	local derived = profile.DerivedStats

	return {
		Level = data.Nivel,
		StatPoints = data.PuntosDeStatsDisponibles,
		STR = stats.Fuerza,
		AGI = stats.Agilidad,
		VIT = stats.Vitalidad,
		ENE = stats.Energia,
		ClassName = data.Clase,
		TotalDamage = derived.TotalDamage,
		TotalAttackSpeed = derived.TotalAttackSpeed,
		TotalDefense = derived.TotalDefense,
		HP = data.CurrentHP,
		MaxHP = derived.MaxHP,
		MP = data.CurrentMP,
		MaxMP = derived.MaxMP,
	}
end

function DataManager:sendFullStatsToClient(player)
	local profile = DataManager:GetProfile(player)
	if not profile then 
		print("[StatsService] No se pudo enviar los stats a " .. player.Name .. " porque el perfil no fue encontrado.")
		return 
	end

	local fullStats = DataManager:GetFullStats(profile)
	Comm.Server:Fire(player, "UpdateStats", fullStats)
	print("[StatsService] Stats iniciales enviados a " .. player.Name)
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
