--[[
	ClassService.lua
	Maneja la selección de clase, escuchando cuando los datos del jugador están listos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ClassConfig = require(ReplicatedStorage.Shared.config.ClassConfig)
local Signals = require(ReplicatedStorage.Shared.util.Signal)

local ClassService = {}

-- ATRIBUTOS DEL SERVICIO
ClassService.PlayerDataService = nil
ClassService.StatsService = nil
ClassService.InventoryService = nil

-- MÉTODOS
function ClassService:Init()
	-- No se necesita nada
end

function ClassService:Start(ServiceManager)
	self.PlayerDataService = ServiceManager:GetService("PlayerDataService")
	self.StatsService = ServiceManager:GetService("StatsService")
	self.InventoryService = ServiceManager:GetService("InventoryService")

	Remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
		self:_onSelectClass(player, classId)
	end)

	-- Nos conectamos a la señal para saber cuándo actuar.
	Signals:Connect(function(eventName, player, playerData)
		if eventName == "PlayerDataLoaded" then
			self:_checkPlayerClass(player, playerData)
		end
	end)

	print("[ClassService] Listo y escuchando peticiones.")
end

-- Esta función ahora es llamada por la señal
function ClassService:_checkPlayerClass(player, playerData)
	if not playerData then return end

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
	if not playerData or (playerData.Clase and playerData.Clase ~= "Default") then return end

	local classData = ClassConfig[classId]
	if not classData then return end

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
