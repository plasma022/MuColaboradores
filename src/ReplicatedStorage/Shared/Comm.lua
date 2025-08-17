--[[
    Archivo: Comm.lua
    Tipo: ModuleScript
    Ubicacion: ReplicatedStorage/Shared/
    Descripcion: Modulo centralizado para la comunicacion Cliente-Servidor.
                 Gestiona la creacion y el acceso a todos los RemoteEvents.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Contenedor principal para todos los eventos remotos.
local RemotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemotesFolder then
    RemotesFolder = Instance.new("Folder")
    RemotesFolder.Name = "RemoteEvents"
    RemotesFolder.Parent = ReplicatedStorage
end

-- Función auxiliar para crear un RemoteEvent si no existe
local function createRemote(name)
    local remote = RemotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = RemotesFolder
    end
    return remote
end

-- --- Eventos para el sistema de comunicacion general (multiplexing) ---
local ClientToServer = createRemote("ClientToServer")
local ServerToClient = createRemote("ServerToClient")

-- --- Eventos dedicados para el sistema de Inventario ---
createRemote("UpdateInventory")
createRemote("EquipItem")
createRemote("DropItemEvent")
createRemote("UpdateClientStats")


-- --- API del Módulo ---

local serverListeners = {}
local clientListeners = {}

local Comm = {}

-- Referencia directa a la carpeta de Remotes para que otros scripts puedan acceder a los eventos dedicados.
Comm.RemotesFolder = RemotesFolder

-- API para el sistema de multiplexing (si aún se necesita)
Comm.Server = {}
Comm.Client = {}

function Comm.Server:Fire(player, eventName, ...)
	ServerToClient:FireClient(player, eventName, ...)
end

function Comm.Server:FireAll(eventName, ...)
	ServerToClient:FireAllClients(eventName, ...)
end

function Comm.Client:Fire(eventName, ...)
	ClientToServer:FireServer(eventName, ...)
end

function Comm.Server:On(eventName, callback)
	serverListeners[eventName] = callback
end

function Comm.Client:On(eventName, callback)
	clientListeners[eventName] = callback
end

-- Conexiones para el sistema de multiplexing
if RunService:IsServer() then
	ClientToServer.OnServerEvent:Connect(function(player, eventName, ...)
		if serverListeners[eventName] then
			serverListeners[eventName](player, ...)
		end
	end)
elseif RunService:IsClient() then
	ServerToClient.OnClientEvent:Connect(function(eventName, ...)
		if clientListeners[eventName] then
			clientListeners[eventName](...)
		end
	end)
end

return Comm