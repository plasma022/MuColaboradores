--[[
	PlayerDataService.lua
	Gestiona la carga/guardado de datos y notifica a otros servicios cuando los datos están listos.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Módulos
local ProfileService = require(ReplicatedStorage.Shared.lib.ProfileService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerConfig = require(ReplicatedStorage.Shared.config.PlayerConfig)
local Signals = require(ReplicatedStorage.Shared.util.Signal)

local PlayerDataService = {}

-- CONFIGURACIÓN
local PROFILE_STORE_NAME = "PlayerData"
local PROFILE_TEMPLATE = PlayerConfig

-- ATRIBUTOS DEL SERVICIO
PlayerDataService.Profiles = {}

-- MÉTODOS
function PlayerDataService:Init()
	-- No se necesita nada
end

function PlayerDataService:Start(ServiceManager)
	Players.PlayerAdded:Connect(function(player) self:_onPlayerAdded(player) end)
	Players.PlayerRemoving:Connect(function(player) self:_onPlayerRemoving(player) end)
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
			player:Kick("Se ha cargado tu perfil desde otra sesión.")
		end)

		if player:IsDescendantOf(Players) then
			self.Profiles[player] = profile
			print(`[PlayerDataService] Perfil cargado para {player.Name}`)
			
			-- Disparamos la señal global para que otros servicios reaccionen
			Signals:Fire("PlayerDataLoaded", player, profile.Data)
			
			Remotes.PlayerStatUpdate:FireClient(player, profile.Data)
		else
			profile:Release()
		end
	else
		player:Kick("No se pudo cargar tu perfil.")
	end
end

function PlayerDataService:_onPlayerRemoving(player)
	local profile = self.Profiles[player]
	if profile then
		profile:Release()
	end
end

function PlayerDataService:GetData(player)
	local profile = self.Profiles[player]
	return profile and profile.Data
end

return PlayerDataService
