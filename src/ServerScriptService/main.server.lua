--[[
	main.server.lua
	Punto de entrada del SERVIDOR.
	Su única responsabilidad es encontrar y arrancar el ServiceManager.
]]

print("Iniciando servidor...")

-- Obtenemos la referencia a las carpetas principales dentro de ServerScriptService
local core = script.Parent.core
local servicesFolder = script.Parent.services

-- Cargamos el ServiceManager desde la carpeta 'core'
local ServiceManager = require(core.ServiceManager)

-- Le damos la orden de iniciar todos los servicios que se encuentran en la carpeta 'services'
ServiceManager:Start(servicesFolder)

print("Servidor iniciado y todos los servicios están corriendo.")
