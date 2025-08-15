--[[
    Archivo: StatsService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja la lgica para asignar puntos de estadsticas.
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.PlayerDataManager)
local Comm = require(ReplicatedStorage.Shared.Comm)

local function assignStatPoint(player, statName)
	local profile = DataManager:GetProfile(player)
	if not profile then return end

	-- Validar que el jugador tenga puntos disponibles
	if profile.Data.PuntosDeStatsDisponibles <= 0 then
		print("[StatsService] El jugador " .. player.Name .. " intent asignar un punto sin tener disponibles.")
		return
	end

	-- Validar que el nombre del stat sea correcto
	local statToUpgrade = profile.Data.EstadisticasBase[statName]
	if not statToUpgrade then
		print("[StatsService] El jugador " .. player.Name .. " intent asignar un punto a un stat invlido: " .. tostring(statName))
		return
	end

	-- Asignar el punto
	profile.Data.PuntosDeStatsDisponibles = profile.Data.PuntosDeStatsDisponibles - 1
	profile.Data.EstadisticasBase[statName] = profile.Data.EstadisticasBase[statName] + 1

	-- Recalcular todos los stats derivados
	DataManager:CalculateDerivedStats(profile)

	-- Empaquetar y enviar todos los stats actualizados al cliente
	local fullStats = DataManager:GetFullStats(profile)
	Comm.Server:Fire(player, "UpdateStats", fullStats)

	print("[StatsService] Punto asignado a " .. statName .. " para el jugador " .. player.Name)
end

Comm.Server:On("AssignStatPoint", assignStatPoint)
