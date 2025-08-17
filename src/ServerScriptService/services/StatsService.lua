--[[
	StatsService.lua
	Servicio que gestiona todos los cálculos relacionados con las estadísticas del jugador.
	Calcula stats derivados (HP, MP, Daño) y maneja la asignación de puntos.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CharacterFormulas = require(ReplicatedStorage.Shared.util.character_formulas) -- Asumiendo que tienes este módulo

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

	if playerData.StatPoints > 0 then
		-- Verificamos que el stat que se quiere subir es válido (STR, AGI, VIT, ENE)
		if playerData.Stats[statToIncrease] then
			playerData.StatPoints = playerData.StatPoints - 1
			playerData.Stats[statToIncrease] = playerData.Stats[statToIncrease] + 1

			-- Después de cambiar un stat base, recalculamos los stats derivados
			self:RecalculateDerivedStats(player)

			-- Notificamos al cliente que la asignación fue exitosa
			-- El cliente debería tener un listener para este evento y actualizar la UI
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
	if not playerData then return end

	local stats = playerData.Stats
	
	-- Usamos las fórmulas del módulo compartido para los cálculos
	playerData.MaxHP = CharacterFormulas.CalculateMaxHP(playerData.Nivel, stats.VIT)
	playerData.MaxMP = CharacterFormulas.CalculateMaxMP(playerData.Nivel, stats.ENE)
	
	-- Asegurarnos de que la vida/maná actual no supere el nuevo máximo
	playerData.CurrentHP = math.min(playerData.CurrentHP, playerData.MaxHP)
	playerData.CurrentMP = math.min(playerData.CurrentMP, playerData.MaxMP)

	-- Aquí irían más cálculos: Defensa, Daño Mínimo/Máximo, Velocidad de Ataque, etc.
	-- playerData.Defense = CharacterFormulas.CalculateDefense(stats.AGI)
	-- playerData.MinDamage, playerData.MaxDamage = CharacterFormulas.CalculateDamage(stats.STR)

	print(`[StatsService] Stats recalculados para {player.Name}`)
end

-- Función pública para obtener un stat específico de un jugador
function StatsService:GetStat(player, statName)
	local playerData = self.PlayerDataService:GetData(player)
	if playerData and playerData.Stats[statName] then
		return playerData.Stats[statName]
	end
	return nil
end

return StatsService
