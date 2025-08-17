--[[
	ClassService.lua
	Servicio que maneja la selección de clase de los jugadores.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClassConfig = require(ReplicatedStorage.Shared.config.ClassConfig) -- Asumiendo que tienes este módulo

local ClassService = {}

-- ATRIBUTOS DEL SERVICIO
ClassService.PlayerDataService = nil
ClassService.StatsService = nil
ClassService.InventoryService = nil

-- MÉTODOS
function ClassService:Init()
	-- No se necesita nada en la inicialización
end

function ClassService:Start(ServiceManager)
	-- Obtenemos referencias a otros servicios
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")
	self.StatsService = ServiceManager:GetService("StatsService")
	self.InventoryService = ServiceManager:GetService("InventoryService")

	-- Conectamos el RemoteEvent para que el cliente pueda solicitar elegir una clase
	Remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
		self:_onSelectClass(player, classId)
	end)

	-- Conectamos la lógica para revisar la clase de un jugador cuando entra
	Players.PlayerAdded:Connect(function(player)
		-- Esperamos un poco para asegurarnos de que el perfil del jugador esté cargado
		task.wait(1) 
		self:_checkPlayerClass(player)
	end)

	print("[ClassService] Listo y escuchando peticiones de selección de clase.")
end

-- Función privada que se ejecuta cuando un jugador elige una clase
function ClassService:_onSelectClass(player, classId)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return end

	-- 1. Validar que el jugador no tenga ya una clase
	if playerData.PlayerClass and playerData.PlayerClass ~= "Default" then
		warn(`[ClassService] El jugador {player.Name} intentó elegir una clase teniendo ya una.`)
		return
	end

	-- 2. Validar que la clase elegida exista en la configuración
	local classData = ClassConfig[classId]
	if not classData then
		warn(`[ClassService] El jugador {player.Name} intentó elegir una clase inexistente: {classId}`)
		return
	end

	-- 3. Asignar la clase y los stats iniciales
	playerData.PlayerClass = classId
	playerData.Stats = classData.BaseStats -- Asignamos los stats base de la clase

	-- 4. Otorgar ítems y habilidades iniciales
	if classData.StartingItems then
		for _, itemId in ipairs(classData.StartingItems) do
			self.InventoryService:AddItem(player, itemId, 1)
		end
	end
	
	if classData.StartingSkills then
		playerData.Skills = classData.StartingSkills
	end

	-- 5. Recalcular todos los stats derivados con los nuevos stats base
	self.StatsService:RecalculateDerivedStats(player)

	-- 6. Notificar al cliente que todo se actualizó para que pueda cerrar la UI de selección
	Remotes.PlayerStatUpdate:FireClient(player, playerData)
	
	print(`[ClassService] El jugador {player.Name} ha elegido la clase: {classId}`)
	
	-- Recargamos el personaje para que los cambios visuales (ítems) se apliquen
	player:LoadCharacter()
end

-- Función para revisar si el jugador necesita elegir una clase al entrar.
function ClassService:_checkPlayerClass(player)
	local playerData = self.PlayerDataService:GetData(player)

	if not playerData then
		warn(`[ClassService] No se pudo revisar la clase para {player.Name} porque no se encontraron sus datos.`)
		return
	end

	-- Si la clase es nil o "Default", le pedimos al cliente que muestre la UI de selección
	if not playerData.PlayerClass or playerData.PlayerClass == "Default" then
		print(`[ClassService] El jugador {player.Name} necesita elegir una clase.`)
		Remotes.ShowClassSelection:FireClient(player)
	else
		print(`[ClassService] El jugador {player.Name} ya tiene la clase: {playerData.PlayerClass}`)
	end
end

return ClassService
