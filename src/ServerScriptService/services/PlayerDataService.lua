--[[
	PlayerDataService.lua
	Servicio fundamental que gestiona la carga y el guardado de los datos de los jugadores.
	Utiliza ProfileService para garantizar la seguridad de los datos.
	Ubicación: ServerScriptService/services/
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Módulos
local ProfileService = require(ReplicatedStorage.Shared.lib.ProfileService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerConfig = require(ReplicatedStorage.Shared.config.PlayerConfig)

local PlayerDataService = {}

-- CONFIGURACIÓN
local PROFILE_STORE_NAME = "PlayerData"
local PROFILE_TEMPLATE = PlayerConfig

-- ATRIBUTOS DEL SERVICIO
PlayerDataService.Profiles = {} -- Caché para los perfiles de los jugadores conectados.
PlayerDataService.StatsService = nil
PlayerDataService.InventoryService = nil
PlayerDataService.ClassService = nil -- <-- AÑADIDO

-- MÉTODOS
function PlayerDataService:Init()
	-- No se necesita nada en la inicialización para este servicio
end

function PlayerDataService:Start(ServiceManager)
	-- Obtenemos referencias a otros servicios que necesitaremos notificar
	self.StatsService = ServiceManager:GetService("StatsService")
	self.InventoryService = ServiceManager:GetService("InventoryService")
	self.ClassService = ServiceManager:GetService("ClassService") -- <-- AÑADIDO

	-- Conectamos los eventos de entrada y salida de jugadores
	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)

	print("[PlayerDataService] Listo y escuchando jugadores.")
end

function PlayerDataService:_onPlayerAdded(player)
	local profileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, PROFILE_TEMPLATE)
	local profile = profileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			self.Profiles[player] = nil
			player:Kick("Se ha cargado tu perfil desde otra sesión. Por favor, vuelve a unirte.")
		end)

		if player:IsDescendantOf(Players) then
			self.Profiles[player] = profile
			print(`[PlayerDataService] Perfil cargado para {player.Name}`)
			
			-- CORRECCIÓN: Notificamos a los otros servicios que los datos están listos
			self.ClassService:OnPlayerDataLoaded(player)
			
			-- Enviamos los datos iniciales al cliente
			Remotes.PlayerStatUpdate:FireClient(player, profile.Data)
		else
			profile:Release()
		end
	else
		player:Kick("No se pudo cargar tu perfil. Inténtalo de nuevo más tarde.")
	end
end

function PlayerDataService:_onPlayerRemoving(player)
	local profile = self.Profiles[player]
	if profile then
		profile:Release()
		print(`[PlayerDataService] Perfil liberado para {player.Name}`)
	end
end

-- Función pública para obtener los datos de un jugador
function PlayerDataService:GetData(player)
	local profile = self.Profiles[player]
	return profile and profile.Data
end

return PlayerDataService
