--[[
    Archivo: Comm.lua
    Tipo: ModuleScript
    Ubicacion: ReplicatedStorage/Shared/
    Descripcion: Modulo centralizado para la comunicacion Cliente-Servidor.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ClientToServer = Remotes:FindFirstChild("ClientToServer") or Instance.new("RemoteEvent", Remotes)
ClientToServer.Name = "ClientToServer"

local ServerToClient = Remotes:FindFirstChild("ServerToClient") or Instance.new("RemoteEvent", Remotes)
ServerToClient.Name = "ServerToClient"

local serverListeners = {}
local clientListeners = {}

local Comm = {}
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
