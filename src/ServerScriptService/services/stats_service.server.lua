--[[
    Archivo: StatsService.lua
    Tipo: Script
    Ubicacin: ServerScriptService/
    Descripcin: Maneja la lgica para asignar puntos de estadsticas y sincronizarlas con el cliente.
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function safeRequireShared(name)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 5)
	if not shared then warn("[StatsService] ReplicatedStorage.Shared no disponible") return nil end
	local module = shared:FindFirstChild(name) or shared:WaitForChild(name, 5)
	if not module then warn("[StatsService] Módulo '"..name.."' no encontrado en Shared") return nil end
	local ok, res = pcall(require, module)
	if not ok then warn("[StatsService] Error al require: ", res) return nil end
	return res
end

local DataManager = require(ServerScriptService.core.player_data_manager)
local Comm = safeRequireShared("comm")

if not DataManager then
	warn("[StatsService] Objeto encontrado no es ModuleScript: player_data_manager or failed to require it. Algunas funciones quedarán inactivas.")
end
if not Comm then
	warn("[StatsService] Comm no disponible en ReplicatedStorage.Shared; eventos remotos no serán registrados en este servicio.")
end

-- Funcin para asignar un punto de stat
local function assignStatPoint(player, statName)
	if not DataManager or not DataManager.GetProfile then
		warn("[StatsService] assignStatPoint: DataManager no disponible; abortando.")
		return
	end
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

	-- Enviar los stats actualizados al cliente
	DataManager:sendFullStatsToClient(player)

	print("[StatsService] Punto asignado a " .. statName .. " para el jugador " .. player.Name)
end

-- Conectar los eventos
if Comm and Comm.Server then
	if DataManager then
		Comm.Server:On("AssignStatPoint", assignStatPoint)
		Comm.Server:On("RequestInitialStats", function(player)
			if DataManager and DataManager.sendFullStatsToClient then
				DataManager:sendFullStatsToClient(player)
			else
				warn("[StatsService] RequestInitialStats: DataManager.sendFullStatsToClient no disponible.")
			end
		end)
	else
		warn("[StatsService] Comm disponible pero DataManager no está listo; no se registraron handlers que dependen de DataManager.")
	end
else
	warn("[StatsService] No se pudo registrar eventos: Comm o Comm.Server no disponibles.")
end