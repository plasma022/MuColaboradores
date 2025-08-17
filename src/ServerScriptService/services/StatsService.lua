--[[
	StatsService.lua
	Servicio que gestiona todos los cálculos relacionados con las estadísticas del jugador.
	Calcula stats derivados (HP, MP, Daño) y maneja la asignación de puntos.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CharacterFormulas = require(ReplicatedStorage.Shared.util.character_formulas)

local StatsService = {}

-- ATRIBUTOS DEL SERVICIO
StatsService.PlayerDataService = nil

-- MÉTODOS
function StatsService:Init()
	-- No se necesita nada en la inicialización
end

function StatsService:Start(ServiceManager)
	-- Obtenemos la referencia al PlayerDataService
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")

	-- Conectamos la RemoteFunction para que el cliente pueda solicitar asignar un punto de stat
	Remotes.AssignStatPoint.OnServerInvoke = function(player, statToIncrease)
		return self:_onAssignStatPoint(player, statToIncrease)
	end

	print("[StatsService] Listo y escuchando peticiones de asignación de stats.")
end

-- Función privada que se ejecuta cuando un jugador intenta asignar un punto
function StatsService:_onAssignStatPoint(player, statToIncrease)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return {success = false, message = "No se encontraron datos del jugador."} end

	if playerData.PuntosDeStatsDisponibles > 0 then
		if playerData.EstadisticasBase[statToIncrease] then
			playerData.PuntosDeStatsDisponibles = playerData.PuntosDeStatsDisponibles - 1
			playerData.EstadisticasBase[statToIncrease] = playerData.EstadisticasBase[statToIncrease] + 1

			self:RecalculateDerivedStats(player)
			Remotes.PlayerStatUpdate:FireClient(player, playerData)
			
			return {success = true, message = "Punto asignado correctamente."}
		else
			return {success = false, message = "El stat especificado no es válido."}
		end
	else
		return {success = false, message = "No tienes puntos de stat para asignar."}
	end
end

-- Función pública para recalcular todos los stats de un jugador (HP, MP, Daño, etc.)
function StatsService:RecalculateDerivedStats(player)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData or not playerData.EstadisticasBase then return end

	local stats = playerData.EstadisticasBase
	
	-- CORRECCIÓN: Se cambiaron los nombres de las funciones a minúscula para que coincidan con el módulo de fórmulas.
	playerData.MaxHP = CharacterFormulas.calculateMaxHP(playerData.Clase, playerData.Nivel, stats.Vitalidad)
	playerData.MaxMP = CharacterFormulas.calculateMaxMP(playerData.Clase, playerData.Nivel, stats.Energia)
	
	-- Al recalcular, la vida y el maná se restauran al máximo.
	playerData.CurrentHP = playerData.MaxHP
	playerData.CurrentMP = playerData.MaxMP

	print(`[StatsService] Stats recalculados para {player.Name}`)
end

-- Función que el CombatService necesita.
function StatsService:GetDerivedStats(player)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return {} end
	
	-- Aquí irían los cálculos para stats como velocidad de ataque, defensa, etc.
	-- Por ahora, devolvemos una tabla simple.
	return {
		TimeMultiplier = 1 -- Placeholder
	}
end

return StatsService
