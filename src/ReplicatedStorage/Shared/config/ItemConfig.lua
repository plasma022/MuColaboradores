--[[
    Archivo: ItemConfig.lua
    Tipo: ModuleScript
    Ubicacion: ReplicatedStorage/Shared/
    Descripcion: Catalogo central de todos los items del juego.
--]]

local ItemConfig = {
    -- Armas
    SWORD_01 = {
        Name = "Short Sword",
        Type = "Weapon", -- Corresponde al nombre del Slot en la GUI
        Description = "A basic sword for beginners.",
        ImageId = "rbxassetid://1234567890", -- Placeholder
        Level = 1,

        -- Stats del Item
        MinDmg = 5,
        MaxDmg = 10,
        AttackSpeed = 10,

        -- Requisitos
        ReqClass = "Dark Knight",
        ReqStats = {
            Strength = 20,
            Agility = 15,
        }
    },

    -- Armaduras
    HELMET_01 = {
        Name = "Bronze Helm",
        Type = "Helmet", -- Corresponde al nombre del Slot en la GUI
        Description = "A sturdy bronze helmet.",
        ImageId = "rbxassetid://0987654321", -- Placeholder
        Level = 3,

        -- Stats del Item
        Defense = 8,
        
        -- Requisitos
        ReqClass = "Dark Knight",
        ReqStats = {
            Strength = 30,
        }
    },

    POTION_HP_01 = {
        Name = "Small HP Potion",
        Type = "Consumable",
        Description = "Recovers a small amount of HP.",
        ImageId = "rbxassetid://1122334455", -- Placeholder
    },
}

return ItemConfig