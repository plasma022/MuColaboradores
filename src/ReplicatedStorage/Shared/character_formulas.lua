--[[
    Archivo: CharacterFormulas.lua
    Tipo: ModuleScript
    Ubicacin: ReplicatedStorage/Shared/
    Descripcin: Centraliza TODOS los clculos matemticos y animaciones base del personaje.
--]]

local Formulas = {}

Formulas.statNameMap = {
	Strength = "STR",
	Agility = "AGI",
	Vitality = "VIT",
	Energy = "ENE"
}

-- Animaciones por defecto que todas las clases pueden usar.
Formulas.DefaultAnimations = {
	HitMelee = "rbxassetid://80458845151117"
}

-- == CORRECCIN CLAVE: Nombres de stats estandarizados a espaol ==
-- Stats y animaciones base de cada clase al Nivel 1.
Formulas.CLASS_BASE_STATS = {
	["DarkKnight"] = {
		HP=79, MP=32, Fuerza=15, Agilidad=10, Vitalidad=12, Energia=5, VelocidadAtaque = 45,
		RunAnimID = "rbxassetid://127681785238768",
		RecoilAnimID = "rbxassetid://99256836368216",
		DeathAnimID = "rbxassetid://104083807651488",
		WeaponAttackAnims = {
			Sword = "rbxassetid://93241459333840"
		}
	},
	["DarkWizard"] = {
		HP=63, MP=18, Fuerza=5, Agilidad=10, Vitalidad=8, Energia=20, VelocidadAtaque = 30,
		RunAnimID = "rbxassetid://119542539921749",
		RecoilAnimID = "rbxassetid://92766645817090",
		DeathAnimID = "rbxassetid://103898651293300",
		WeaponAttackAnims = {}
	},
	["FairyElf"] = {
		HP=74, MP=30, Fuerza=10, Agilidad=15, Vitalidad=10, Energia=10, VelocidadAtaque = 35,
		RunAnimID = "rbxassetid://120898088288165",
		RecoilAnimID = "rbxassetid://92766645817090",
		DeathAnimID = "rbxassetid://104083807651488",
		WeaponAttackAnims = {
			Bow = "rbxassetid://129612779287723"
		}
	},
}

local CLASS_ATTACK_SPEED_DIVISORS = {
    DarkKnight = 15,
    DarkWizard = 20,
    FairyElf = 10
}

function Formulas.calculateMaxHP(className, level, vit)
	local base = Formulas.CLASS_BASE_STATS[className] or Formulas.CLASS_BASE_STATS["DarkKnight"]
	local calculatedHP
	if className == "DarkWizard" then calculatedHP = base.HP + math.floor(level * 1.5 + vit * 2)
	elseif className == "DarkKnight" then calculatedHP = base.HP + math.floor(level * 2.2 + vit * 3) * 1.1
	elseif className == "FairyElf" then calculatedHP = base.HP + math.floor(level * 1.8 + vit * 2.5)
	else calculatedHP = base.HP + math.floor(level * 2.2 + vit * 3) * 1.1 end
	return math.floor(calculatedHP)
end

function Formulas.calculateMaxMP(className, level, ene)
	local base = Formulas.CLASS_BASE_STATS[className] or Formulas.CLASS_BASE_STATS["DarkKnight"]
	local calculatedMP
	if className == "DarkWizard" then calculatedMP = base.MP + math.floor(level * 2 + ene * 3)
	elseif className == "DarkKnight" then calculatedMP = base.MP + math.floor(level * 1 + ene * 1.5)
	elseif className == "FairyElf" then calculatedMP = base.MP + math.floor(level * 1.2 + ene * 2)
	else calculatedMP = base.MP + math.floor(level * 1 + ene * 1.5) end
	return math.floor(calculatedMP)
end

function Formulas.calculateDamageRange(className, str, agi)
	local minDamage, maxDamage
	if className == "DarkKnight" then
		minDamage = math.floor(str / 8)
		maxDamage = math.floor(str / 4)
	elseif className == "DarkWizard" then
		minDamage = math.floor(str / 10)
		maxDamage = math.floor(str / 6)
	elseif className == "FairyElf" then
		minDamage = math.floor((agi * 2 + str) / 12)
		maxDamage = math.floor((agi * 2 + str) / 7)
	else
		minDamage = 1
		maxDamage = 2
	end
	return minDamage, maxDamage
end

function Formulas.calculateAttackSpeed(className, agi)
    local baseStats = Formulas.CLASS_BASE_STATS[className]
    local divisor = CLASS_ATTACK_SPEED_DIVISORS[className]

    if not baseStats or not divisor then
        -- Valores por defecto si la clase no se encuentra
        baseStats = Formulas.CLASS_BASE_STATS["DarkKnight"]
        divisor = CLASS_ATTACK_SPEED_DIVISORS["DarkKnight"]
    end

    local baseSpeed = baseStats.VelocidadAtaque
    local bonusFromAgi = math.floor(agi / divisor)
    local itemBonus = 0 -- Placeholder para futuros bonus de items

    return baseSpeed + bonusFromAgi + itemBonus
end

function Formulas.calculateTimeMultiplier(attackSpeedStat)
	return 1 / (1 + (attackSpeedStat * 0.01)) 
end

function Formulas.calculateDefense(agi)
	return math.floor(agi / 4)
end

return Formulas