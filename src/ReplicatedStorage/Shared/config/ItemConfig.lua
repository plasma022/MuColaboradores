--[[
	ItemConfig.lua
	Base de datos de todos los ítems del juego.
	Define las propiedades, estadísticas y comportamiento de cada ítem.
	Ubicación: ReplicatedStorage/Shared/config/
]]

return {
	-- EJEMPLOS DE ÍTEMS --

	-- Armas
	["ShortSword"] = {
		Name = "Short Sword",
		Description = "A basic sword for beginners.",
		Slot = "Weapon", -- A qué parte del equipo pertenece
		Stats = {
			MinDamage = 5,
			MaxDamage = 10,
		},
		AccessoryId = "rbxassetid://YOUR_SWORD_MESH_ID", -- ID del accesorio para mostrarlo
	},
	["SmallAxe"] = {
		Name = "Small Axe",
		Description = "A simple axe.",
		Slot = "Weapon",
		Stats = {
			MinDamage = 7,
			MaxDamage = 12,
		},
		AccessoryId = "rbxassetid://YOUR_AXE_MESH_ID",
	},

	-- Armaduras
	["LeatherHelmet"] = {
		Name = "Leather Helmet",
		Description = "Basic head protection.",
		Slot = "Helmet",
		Stats = {
			Defense = 5,
		},
		AccessoryId = "rbxassetid://YOUR_HELMET_MESH_ID",
	},
	["LeatherArmor"] = {
		Name = "Leather Armor",
		Description = "A simple leather tunic.",
		Slot = "Armor",
		Stats = {
			Defense = 10,
		},
		-- No necesita AccessoryId si la armadura se aplica con texturas
	},
	
	-- Consumibles (Ejemplo a futuro)
	["SmallHealthPotion"] = {
		Name = "Small Health Potion",
		Description = "Restores a small amount of health.",
		Slot = nil, -- No se equipa
		Consumable = true,
		Effect = {
			Type = "Heal",
			Amount = 50,
		},
	},
}
