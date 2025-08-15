--[[
    Archivo: SkillConfig.lua
    Tipo: ModuleScript
    Ubicaci�n: ReplicatedStorage/Shared/
    Descripci�n: La "base de datos" de todas las habilidades del juego.
--]]
local SkillConfig = {

	-- ================= SKILLS DE DARK WIZARD (SM) =================
	["EnergyBall"] = { SkillName = "Energy Ball", RequiredClass = "DarkWizard", RequiredLevel = 1, ManaCost = 3, BaseCooldown = 1, DamageType = "Magic", DamageFormula = function(stats) return 10 + (stats.Energia * 1.2) end, AreaOfEffect = {Shape = "Projectile", Speed = 80, Size = Vector3.new(2,2,2)}, AnimationID = "rbxassetid://106506344186255", IconID = "rbxassetid://76727627021005", VFX_ID = "EnergyBallEffect"},
	["EvilSpirit"] = { SkillName = "Evil Spirit", RequiredClass = "DarkWizard", RequiredLevel = 30, ManaCost = 20, BaseCooldown = 3, DamageType = "Magic", DamageFormula = function(stats) return 40 + (stats.Energia * 1.8) end, AreaOfEffect = {Shape = "Circle", Size = 15}, AnimationID = "rbxassetid://99434020645260", IconID = "rbxassetid://134787483687563", VFX_ID = "EvilSpiritEffect"},
	["ManaShield"] = { SkillName = "Mana Shield", RequiredClass = "DarkWizard", RequiredLevel = 50, ManaCost = 50, BaseCooldown = 10, EffectType = "Buff", BuffFormula = function(stats) return { Name = "ManaShield", Description = "Absorbe da�o a cambio de Man�.", DamageAbsorption = 0.5, ManaDrainRatio = 1.5, Duration = 180 } end, AnimationID = "rbxassetid://118181198258588", IconID = "rbxassetid://114905448282923", VFX_ID = "ManaShieldAura"},
	["IceStorm"] = { SkillName = "Ice Storm", RequiredClass = "DarkWizard", RequiredLevel = 80, ManaCost = 40, BaseCooldown = 6, DamageType = "Magic", DamageFormula = function(stats) return 60 + (stats.Energia * 2.2) end, AreaOfEffect = {Shape = "Circle", Size = 20}, SecondaryEffect = {Name = "Slow", Power = 0.3, Duration = 3}, AnimationID = "rbxassetid://70579287299579", IconID = "rbxassetid://125127345279202", VFX_ID = "IceStormEffect"},

	-- ================= SKILLS DE DARK KNIGHT (BK) =================
	["Cyclone"] = { SkillName = "Cyclone", RequiredClass = "DarkKnight", RequiredLevel = 8, ManaCost = 8, BaseCooldown = 2, DamageType = "Physical", DamageFormula = function(stats) return 15 + (stats.Fuerza * 1.5) end, AreaOfEffect = {Shape = "Circle", Size = 8}, AnimationID = "rbxassetid://125792693141855", IconID = "rbxassetid://77329175261521", VFX_ID = "CycloneEffect"},
	["TwistingSlash"] = { SkillName = "Twisting Slash", RequiredClass = "DarkKnight", RequiredLevel = 28, ManaCost = 15, BaseCooldown = 3, DamageType = "Physical", DamageFormula = function(stats) return 30 + (stats.Fuerza * 2.0) end, AreaOfEffect = {Shape = "Circle", Size = 12}, AnimationID = "rbxassetid://82203553551413", IconID = "rbxassetid://93107442019349", VFX_ID = "TwistingSlashEffect"},
	["Inner"] = { SkillName = "Inner Strength", RequiredClass = "DarkKnight", RequiredLevel = 40, ManaCost = 20, BaseCooldown = 10, EffectType = "Buff", BuffFormula = function(stats) return { Name = "InnerStrength", Description = "Aumenta la vida m�xima.", StatModifiers = {MaxHP_Multiplier = 1.2}, Duration = 180 } end, AnimationID = "rbxassetid://108523493842633", IconID = "rbxassetid://134425311950945", VFX_ID = "InnerStrengthAura"},
	["DeathStab"] = { SkillName = "Death Stab", RequiredClass = "DarkKnight", RequiredLevel = 120, ManaCost = 30, BaseCooldown = 4, DamageType = "Physical", DamageFormula = function(stats) return 100 + (stats.Fuerza * 3.0) end, AreaOfEffect = {Shape = "Cone", Size = 15, Angle = 45}, AnimationID = "rbxassetid://125792693141855", IconID = "rbxassetid://100074345540137", VFX_ID = "DeathStabEffect"},

	-- ================= SKILLS DE FAIRY ELF =================
	["TripleShot"] = { SkillName = "Triple Shot", RequiredClass = "FairyElf", RequiredLevel = 20, ManaCost = 10, BaseCooldown = 2, DamageType = "Physical", DamageFormula = function(stats) return 5 + (stats.Agilidad * 1.8) end, AreaOfEffect = {Shape = "MultiProjectile", Count = 3, SpreadAngle = 15}, AnimationID = "rbxassetid://129612779287723", IconID = "rbxassetid://109905544767279", VFX_ID = "ArrowEffect"},
	["GreaterDefense"] = { SkillName = "Greater Defense", RequiredClass = "FairyElf", RequiredLevel = 35, ManaCost = 20, BaseCooldown = 10, EffectType = "Buff", BuffFormula = function(stats) return { Name="GreaterDefense", StatModifiers = {Defense_Bonus = 50 + (stats.Energia * 0.5)}, Duration = 180} end, AnimationID = "rbxassetid://118181198258588", IconID = "rbxassetid://139589261038283", VFX_ID = "DefenseAura"},
	["GreaterDamage"] = { SkillName = "Greater Damage", RequiredClass = "FairyElf", RequiredLevel = 55, ManaCost = 30, BaseCooldown = 10, EffectType = "Buff", BuffFormula = function(stats) return { Name="GreaterDamage", StatModifiers = {Damage_Bonus = 20 + (stats.Energia * 0.4)}, Duration = 180} end, AnimationID = "rbxassetid://118181198258588", IconID = "rbxassetid://91498147913282", VFX_ID = "DamageAura"},
	["IceShot"] = { SkillName = "Ice Shot", RequiredClass = "FairyElf", RequiredLevel = 85, ManaCost = 15, BaseCooldown = 3, DamageType = "Physical", DamageFormula = function(stats) return 40 + (stats.Agilidad * 2.5) end, AreaOfEffect = {Shape = "Projectile", Speed = 120, Size = Vector3.new(1,1,3)}, SecondaryEffect = {Name = "Freeze", Duration = 1.5}, AnimationID = "rbxassetid://129612779287723", IconID = "rbxassetid://87924652960899", VFX_ID = "IceArrowEffect"},
}

return SkillConfig
