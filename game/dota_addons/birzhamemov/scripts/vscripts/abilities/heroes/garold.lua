LinkLuaModifier( "modifier_garold_pain_debuff", "abilities/heroes/garold.lua", LUA_MODIFIER_MOTION_NONE )

Garold_pain = class({})

function Garold_pain:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function Garold_pain:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function Garold_pain:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Garold_pain:OnSpellStart()
    if not IsServer() then return end
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")
    local damage = self:GetSpecialValueFor("damage")
    if target:TriggerSpellAbsorb( self ) then return end
    target:EmitSound("Ability.FrostNova")
    local particle = ParticleManager:CreateParticle( "particles/garold/garold_pain.vpcf", PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControl( particle, 1, Vector( 100, 0, 0 ) )
    ParticleManager:ReleaseParticleIndex( particle )
    ApplyDamage({victim = target, attacker = self:GetCaster(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = self})
    target:AddNewModifier(self:GetCaster(), self, "modifier_garold_pain_debuff", {duration = duration})
end

modifier_garold_pain_debuff = class({})

function modifier_garold_pain_debuff:IsPurgable()
    return true
end

function modifier_garold_pain_debuff:IsPurgeException()
    return true
end

function modifier_garold_pain_debuff:OnCreated()
    if not IsServer() then return end
    local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_queenofpain/queen_shadow_strike_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt( particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
    self:AddParticle( particle, false,  false, -1, false, false )
end

function modifier_garold_pain_debuff:GetEffectName()
    return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_garold_pain_debuff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_garold_pain_debuff:CheckState()
    local funcs = {
        [MODIFIER_STATE_SILENCED] = true,
    }
    return funcs
end

LinkLuaModifier( "modifier_Garold_StealPain_stack", "abilities/heroes/garold.lua", LUA_MODIFIER_MOTION_NONE )

Garold_StealPain = class({})

function Garold_StealPain:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function Garold_StealPain:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end

function Garold_StealPain:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function Garold_StealPain:GetIntrinsicModifierName()
    return "modifier_Garold_StealPain_stack"
end

function Garold_StealPain:OnSpellStart()
    if not IsServer() then return end
    local modifier = self:GetCaster():FindModifierByName( "modifier_Garold_StealPain_stack" )
    local stack_count = modifier:GetStackCount() / 100
    local damage_persentage = self:GetSpecialValueFor("damage") + self:GetCaster():FindTalentValue("special_bonus_birzha_garold_1")
    local radius = self:GetSpecialValueFor("radius")

    local targets = FindUnitsInRadius(self:GetCaster():GetTeamNumber(),
    self:GetCaster():GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false)
    
    for _,unit in pairs(targets) do
        ApplyDamage({victim = unit, attacker = self:GetCaster(), damage = stack_count * damage_persentage, damage_type = DAMAGE_TYPE_PURE, ability = self})
        self:GetCaster():SetModifierStackCount("modifier_Garold_StealPain_stack", self, 0)
        local particle = ParticleManager:CreateParticle("particles/garold/garold_stealpain.vpcf", PATTACH_POINT_FOLLOW, unit)
        ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetOrigin(), true)
        ParticleManager:SetParticleControl(particle, 1, Vector(radius,0,0))
        ParticleManager:ReleaseParticleIndex(particle)
        self:GetCaster():EmitSound( "Hero_Antimage.ManaVoid" )
    end
end

modifier_Garold_StealPain_stack = class({})

function modifier_Garold_StealPain_stack:IsPurgable()
    return false
end

function modifier_Garold_StealPain_stack:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH,
    }

    return funcs
end

function modifier_Garold_StealPain_stack:OnTakeDamage( params )
    local max_stacks = self:GetAbility():GetSpecialValueFor("damagestack") + self:GetCaster():FindTalentValue("special_bonus_birzha_garold_3")
    if not IsServer() then return end
    if params.unit == self:GetParent() and params.attacker ~= self:GetParent() then
        if params.attacker:GetUnitName() == "dota_fountain" then return end
        if params.attacker:IsBoss() then return end
        if self:GetParent():IsIllusion() then return end
        if not self:GetParent():IsAlive() then return end
        if (self:GetStackCount() + params.damage) > max_stacks then
            self:GetParent():SetModifierStackCount("modifier_Garold_StealPain_stack", self:GetAbility(), max_stacks)
            return
        end
        if self:GetStackCount() <= max_stacks then
            self:GetParent():SetModifierStackCount("modifier_Garold_StealPain_stack", self:GetAbility(), self:GetStackCount() + params.damage)
        end
    end
end

function modifier_Garold_StealPain_stack:OnDeath( params )
    if not IsServer() then return end
    if params.unit == self:GetParent() then
        self:GetParent():SetModifierStackCount("modifier_Garold_StealPain_stack", self:GetAbility(), 0)
    end
end

LinkLuaModifier("modifier_Garold_HidePain_passive", "abilities/heroes/garold", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_Garold_HidePain_stats", "abilities/heroes/garold", LUA_MODIFIER_MOTION_NONE )

Garold_HidePain = class({}) 

function Garold_HidePain:GetIntrinsicModifierName()
    return "modifier_Garold_HidePain_passive"
end

modifier_Garold_HidePain_passive = class({}) 

function modifier_Garold_HidePain_passive:IsPurgable()
    return false
end

function modifier_Garold_HidePain_passive:DeclareFunctions()
    local funcs = 
    {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
    return funcs
end

function modifier_Garold_HidePain_passive:OnAttackLanded( keys )
    local max_stack = self:GetAbility():GetSpecialValueFor("maxstack")
    local duration = self:GetAbility():GetSpecialValueFor("duration")
    if not IsServer() then return end
    if keys.target == self:GetParent() then
        if self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() then return end
        if not self:GetParent():IsAlive() then return end
        if self:GetStackCount() < max_stack then
            self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_Garold_HidePain_stats", { duration = duration } )
            self:IncrementStackCount()
        end
    end
end

function modifier_Garold_HidePain_passive:GetModifierPhysicalArmorBonus()
    if self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() then return end
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_Garold_HidePain_passive:GetModifierConstantHealthRegen()
    if self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() then return end
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("regen")
end

function modifier_Garold_HidePain_passive:GetModifierMagicalResistanceBonus()
    if self:GetParent():IsIllusion() or self:GetParent():PassivesDisabled() then return end
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("magicarmor")
end

function modifier_Garold_HidePain_passive:RemoveStack()
    self:DecrementStackCount()
end

modifier_Garold_HidePain_stats = class({})

function modifier_Garold_HidePain_stats:IsHidden()
    return true
end

function modifier_Garold_HidePain_stats:IsPurgable()
    return false
end

function modifier_Garold_HidePain_stats:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_Garold_HidePain_stats:OnDestroy()
    if not IsServer() then return end
    local modifier = self:GetParent():FindModifierByName( "modifier_Garold_HidePain_passive" )
    modifier:RemoveStack()
end

LinkLuaModifier( "modifier_joy_stats", "abilities/heroes/garold.lua", LUA_MODIFIER_MOTION_NONE )

Garold_Joy = class({})

function Garold_Joy:GetIntrinsicModifierName()
    return "modifier_joy_stats"
end

modifier_joy_stats = class({})

function modifier_joy_stats:IsPurgable()
    return false
end

function modifier_joy_stats:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }

    return funcs
end


function modifier_joy_stats:OnCreated()
    if not IsServer() then return end
    self.damage_hero = 0
end

function modifier_joy_stats:OnTakeDamage( params )
    local damage_need = self:GetAbility():GetSpecialValueFor("damageforstack") + self:GetCaster():FindTalentValue("special_bonus_birzha_garold_2")
    local max_stacks = self:GetAbility():GetSpecialValueFor("maxstacks") + self:GetCaster():FindTalentValue("special_bonus_birzha_garold_4")
    if not IsServer() then return end
    if params.unit == self:GetParent() and params.attacker ~= self:GetParent() then
        if self:GetParent():IsIllusion() then return end
        if not self:GetParent():IsAlive() then return end
        if params.attacker:GetUnitName() == "dota_fountain" then return end
        if params.attacker:IsBoss() then return end
        self.damage_hero = self.damage_hero + params.damage
        if self.damage_hero >= damage_need then            
            if self:GetStackCount() < max_stacks then
                self:GetParent():SetModifierStackCount("modifier_joy_stats", self:GetAbility(), self:GetStackCount() + 1)
            end
            self.damage_hero = 0
        end
    end
end

function modifier_joy_stats:GetModifierBonusStats_Strength()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("atribute")
end

function modifier_joy_stats:GetModifierBonusStats_Agility()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("atribute")
end

function modifier_joy_stats:GetModifierBonusStats_Intellect()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("atribute")
end

