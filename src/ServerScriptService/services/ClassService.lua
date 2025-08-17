--[[
	ClassService.lua
	Servicio que maneja la selección de clase de los jugadores.
	Ubicación: ServerScriptService/services/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClassConfig = require(ReplicatedStorage.Shared.config.ClassConfig)

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

	-- CORRECCIÓN: Ya no revisamos la clase cuando el jugador entra.
	-- Esperamos la notificación del PlayerDataService.

	print("[ClassService] Listo y escuchando peticiones de selección de clase.")
end

-- CORRECCIÓN: Nueva función que es llamada por PlayerDataService cuando los datos están listos.
function ClassService:OnPlayerDataLoaded(player)
	local playerData = self.PlayerDataService:GetData(player)

	if not playerData then
		warn(`[ClassService] No se pudo revisar la clase para {player.Name} porque no se encontraron sus datos.`)
		return
	end

	-- Si la clase es nil o "Default", le pedimos al cliente que muestre la UI de selección
	if not playerData.Clase or playerData.Clase == "Default" then
		print(`[ClassService] El jugador {player.Name} necesita elegir una clase.`)
		Remotes.ShowClassSelection:FireClient(player)
	else
		print(`[ClassService] El jugador {player.Name} ya tiene la clase: {playerData.Clase}`)
	end
end


-- Función privada que se ejecuta cuando un jugador elige una clase
function ClassService:_onSelectClass(player, classId)
	local playerData = self.PlayerDataService:GetData(player)
	if not playerData then return end

	if playerData.Clase and playerData.Clase ~= "Default" then
		warn(`[ClassService] El jugador {player.Name} intentó elegir una clase teniendo ya una.`)
		return
	end

	local classData = ClassConfig[classId]
	if not classData then
		warn(`[ClassService] El jugador {player.Name} intentó elegir una clase inexistente: {classId}`)
		return
	end

	playerData.Clase = classId
	playerData.EstadisticasBase = classData.BaseStats

	if classData.StartingItems then
		for _, itemId in ipairs(classData.StartingItems) do
			self.InventoryService:AddItem(player, itemId, 1)
		end
	end
	
	if classData.StartingSkills then
		playerData.Skills = classData.StartingSkills
	end

	self.StatsService:RecalculateDerivedStats(player)
	Remotes.PlayerStatUpdate:FireClient(player, playerData)
	
	print(`[ClassService] El jugador {player.Name} ha elegido la clase: {classId}`)
	
	player:LoadCharacter()
end

return ClassService
