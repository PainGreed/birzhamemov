LinkLuaModifier("modifier_item_birzha_ward", "items/birzha_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_birzha_sentry_ward", "items/birzha_ward", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_birzha_observer_ward", "items/birzha_ward", LUA_MODIFIER_MOTION_NONE)

item_birzha_ward = class({})

function item_birzha_ward:GetIntrinsicModifierName()
    local mod = self:GetCaster():FindAllModifiersByName("modifier_item_birzha_ward")[1]
    if mod then
        if mod:GetAbility() ~= self then return end
    end
    return "modifier_item_birzha_ward"
end

function item_birzha_ward:GetAbilityTextureName()
    local stack = self:GetCaster():GetModifierStackCount("modifier_item_birzha_ward", self:GetCaster())
    if stack == 0 then
        return "items/birzha_ward_1"
    end
    return "items/birzha_ward_"..stack
end

function item_birzha_ward:GetGoldCost()  
    if not IsServer() then return end
    if self:GetCursorTarget() then
        return 0
    end  
    if self.type == "observer" then
        return self.observer_cost
    elseif self.type == "sentry" then
        return self.sentry_cost
    end
    return 0
end

function item_birzha_ward:OnAbilityPhaseStart()
    self.vTargetPosition = self:GetCursorPosition()
    if not GridNav:IsTraversable( self.vTargetPosition ) then
        DisplayError(self:GetCaster():GetPlayerOwnerID(), "#dota_hud_error_no_wards_here")
        return false
    end
    if self:GetCursorTarget() then
        if self:GetCursorTarget() and self:GetCursorTarget() ~= self:GetCaster() then
            DisplayError(self:GetCaster():GetPlayerOwnerID(), "#dota_hud_error_cant_cast_on_other")
            return false
        end
    end
    if self:GetCursorTarget() == nil and self:GetCurrentCharges() <= 0 then
        DisplayError(self:GetCaster():GetPlayerOwnerID(), "#dota_hud_error_no_charges")
        return false
    end
    return true;
end

function item_birzha_ward:OnSpellStart()
    if not IsServer() then return end
    local target = self:GetCursorTarget()
    if target and target == self:GetCaster() then
        local one_charge = self:GetCurrentCharges()
        local two_charge = self:GetSecondaryCharges()
        self:SetCurrentCharges(two_charge)
        self:SetSecondaryCharges(one_charge)
        if self.type == "observer" then
            DisplayError(self:GetCaster():GetPlayerOwnerID(), "#change_sentry")
            self.type = "sentry"
        elseif self.type == "sentry" then
            DisplayError(self:GetCaster():GetPlayerOwnerID(), "#change_observer")
            self.type = "observer"
        end
        self:StartCooldown(1)
        return
    end
    local bonus_time = 0
    if self.bonus_time then
        bonus_time = self.bonus_time
    end
    self:GetCaster():EmitSound("DOTA_Item.ObserverWard.Activate")
    if self.type == "observer" then
        local hWard = CreateUnitByName("npc_dota_observer_wards", self:GetCursorPosition(), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
        hWard:AddNewModifier(self:GetCaster(), self, "modifier_item_birzha_observer_ward", {})
        hWard:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = 120 + bonus_time})
        local mod = self:GetCaster():FindModifierByName("modifier_item_birzha_ward")
        if mod then
            if mod:GetStackCount() == 3 then
                hWard:SetDayTimeVisionRange(1700)
                hWard:SetNightTimeVisionRange(1700)
            end
        end
    elseif self.type == "sentry" then
        local hWard = CreateUnitByName("npc_dota_sentry_wards", self:GetCursorPosition(), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
        hWard:AddNewModifier(self:GetCaster(), self, "modifier_item_birzha_sentry_ward", {})
        hWard:AddNewModifier(self:GetCaster(), self, "modifier_kill", {duration = 480 + bonus_time})
    end
    self:SetCurrentCharges(self:GetCurrentCharges()-1)
end
    
modifier_item_birzha_ward = class({})

function modifier_item_birzha_ward:IsHidden()
	return false
end

function modifier_item_birzha_ward:IsPurgable()
    return false
end

function modifier_item_birzha_ward:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_item_birzha_ward:OnCreated()
    if not IsServer() then return end
    if self:GetAbility().init == nil then
        self:GetAbility().init = true
        self:GetAbility().observer_cd = 0
        self:GetAbility().sentry_cd = 0
        self:GetAbility().observer_cd_max = 150
        self:GetAbility().sentry_cd_max = 20
        self:GetAbility().observer_max = 1
        self:GetAbility().sentry_max = 1
        self:GetAbility().bonus_time = 10
        self:GetAbility().sentry_cost = 75
        self:GetAbility().observer_cost = 200
        self:GetAbility().assists = 0
        self:GetAbility().level = 1
        self:GetAbility().type = "observer"
    end
    self:StartIntervalThink(1)
    self:SetStackCount(self:GetAbility().level)
end

function modifier_item_birzha_ward:OnStackCountChanged(stacks)
    if self:GetStackCount() == 2 then
        self:GetAbility().observer_cd_max = 120
        self:GetAbility().sentry_cd_max = 15
        self:GetAbility().observer_max = 1
        self:GetAbility().sentry_max = 2
        self:GetAbility().bonus_time = 20
        self:GetAbility().sentry_cost = 65
        self:GetAbility().observer_cost = 175
    elseif self:GetStackCount() == 3 then
        self:GetAbility().observer_cd_max = 90
        self:GetAbility().sentry_cd_max = 10
        self:GetAbility().observer_max = 2
        self:GetAbility().sentry_max = 4
        self:GetAbility().bonus_time = 30
        self:GetAbility().sentry_cost = 50
        self:GetAbility().observer_cost = 150
    end
end

function modifier_item_birzha_ward:OnIntervalThink()
    if not IsServer() then return end
    self:GetAbility().observer_cd = self:GetAbility().observer_cd + 1
    self:GetAbility().sentry_cd = self:GetAbility().sentry_cd + 1

    if self:GetAbility().type == "observer" then
        if self:GetAbility():GetCurrentCharges() < self:GetAbility().observer_max and self:GetAbility().observer_cd >= self:GetAbility().observer_cd_max then
            self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges()+1)
            self:GetAbility().observer_cd = 0
        end
        if self:GetAbility():GetSecondaryCharges() < self:GetAbility().sentry_max and self:GetAbility().sentry_cd >= self:GetAbility().sentry_cd_max then
            self:GetAbility():SetSecondaryCharges(self:GetAbility():GetSecondaryCharges()+1)
            self:GetAbility().sentry_cd = 0
        end
    elseif self:GetAbility().type == "sentry" then
        if self:GetAbility():GetCurrentCharges() < self:GetAbility().sentry_max and self:GetAbility().sentry_cd >= self:GetAbility().sentry_cd_max then
            self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges()+1)
            self:GetAbility().sentry_cd = 0
        end
        if self:GetAbility():GetSecondaryCharges() < self:GetAbility().observer_max and self:GetAbility().observer_cd >= self:GetAbility().observer_cd_max then
            self:GetAbility():SetSecondaryCharges(self:GetAbility():GetSecondaryCharges()+1)
            self:GetAbility().observer_cd = 0
        end
    end
end

function modifier_item_birzha_ward:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_TOOLTIP
    }

    return funcs
end

function modifier_item_birzha_ward:OnTooltip()
    return self:GetAbility().assists
end

function modifier_item_birzha_ward:GetModifierConstantManaRegen()
    return 2
end

function modifier_item_birzha_ward:GetModifierBonusStats_Strength()
    if self:GetStackCount() == 1 then return 0 end
    if self:GetStackCount() == 2 then return 10 end
    return 20
end

function modifier_item_birzha_ward:GetModifierBonusStats_Agility()
    if self:GetStackCount() == 1 then return 0 end
    if self:GetStackCount() == 2 then return 10 end
    return 20
end

function modifier_item_birzha_ward:GetModifierBonusStats_Intellect()
    if self:GetStackCount() == 1 then return 0 end
    if self:GetStackCount() == 2 then return 10 end
    return 20
end


modifier_item_birzha_observer_ward = class({})

function modifier_item_birzha_observer_ward:IsHidden() return true end

function modifier_item_birzha_observer_ward:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = true,
    }

    return state
end

modifier_item_birzha_sentry_ward = class({})

function modifier_item_birzha_sentry_ward:IsHidden() return true end

function modifier_item_birzha_sentry_ward:CheckState()
    local state = {
        [MODIFIER_STATE_INVISIBLE] = true,
    }

    return state
end

function modifier_item_birzha_sentry_ward:IsAura()
    return true
end

function modifier_item_birzha_sentry_ward:IsHidden()
    return false
end

function modifier_item_birzha_sentry_ward:IsPurgable()
    return false
end

function modifier_item_birzha_sentry_ward:GetAuraRadius()
    return 900
end

function modifier_item_birzha_sentry_ward:GetModifierAura()
    return "modifier_truesight"
end
   
function modifier_item_birzha_sentry_ward:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_birzha_sentry_ward:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_item_birzha_sentry_ward:GetAuraSearchType()
    return DOTA_UNIT_TARGET_ALL
end

function modifier_item_birzha_sentry_ward:GetAuraDuration()
    return 0.1
end