--[[
	Remotes.lua
	Módulo compartido que define y centraliza todos los RemoteEvents y RemoteFunctions.
	Evita errores de tipeo y mantiene la comunicación organizada.
	Ubicación: ReplicatedStorage/Shared/
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Buscamos o creamos una carpeta para guardar los objetos Remote y mantener el explorador limpio
local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "RemotesFolder"
	remotesFolder.Parent = ReplicatedStorage
end

-- Función interna para crear un remote si no existe, asegurando que no haya duplicados.
local function getOrCreate(className, name)
	local remote = remotesFolder:FindFirstChild(name)
	if remote and remote:IsA(className) then
		return remote
	else
		if remote then remote:Destroy() end
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
		return remote
	end
end

-- Definimos TODOS los remotes del juego en un solo lugar.
-- Esta tabla será el "diccionario" de comunicación entre cliente y servidor.
return {
	-- Eventos (Cliente -> Servidor o Servidor -> Cliente)
	InventoryUpdated = getOrCreate("RemoteEvent", "InventoryUpdated"),
	EquipItem = getOrCreate("RemoteEvent", "EquipItem"),
    PlayerStatUpdate = getOrCreate("RemoteEvent", "PlayerStatUpdate"),

	-- Funciones (Cliente pide datos -> Servidor responde)
	AssignStatPoint = getOrCreate("RemoteFunction", "AssignStatPoint"),
    GetItemInfo = getOrCreate("RemoteFunction", "GetItemInfo")
}
