LinkLuaModifier( "modifier_birzha_stunned", "modifiers/modifier_birzha_dota_modifiers.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_migi_inside", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_migi_inside_parent", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_migi_inside_caster", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_migi_inside_cooldown", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

migi_inside = class({})

function migi_inside:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level )
end

function migi_inside:GetManaCost(level)
    return self.BaseClass.GetManaCost(self, level)
end

function migi_inside:GetCastRange(location, target)
    return self.BaseClass.GetCastRange(self, location, target)
end







function migi_inside:CastFilterResultTarget(target)
    if target:HasModifier("modifier_migi_inside_cooldown") then
        return UF_FAIL_CUSTOM
    end
    local nResult = UnitFilter( target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, self:GetCaster():GetTeamNumber() )
    if nResult ~= UF_SUCCESS then
        return nResult
    end
    return UF_SUCCESS
end 

function migi_inside:GetCustomCastErrorTarget(target)
    if target:HasModifier("modifier_migi_inside_cooldown") then
        return "#dota_hud_error_migi_inside"
    end
end









function migi_inside:OnSpellStart()
    self.target = self:GetCursorTarget()
    if self.target:TriggerSpellAbsorb( self ) then
        return
    end
    if self:GetCaster():GetUnitName() == "npc_dota_hero_migi" then
        self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_migi_inside", { target = self.target:entindex() } )
    end
end

modifier_migi_inside = class({})

function modifier_migi_inside:IsPurgable() return false end
function modifier_migi_inside:IsHidden() return true end

function modifier_migi_inside:OnCreated( kv )
    self.close_distance = 80
    self.far_distance = 2000
    self.speed = 800

    if not IsServer() then return end
    self.target = EntIndexToHScript(kv.target)
    self:GetCaster():SetForwardVector((self.target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized())
    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_1)
    if self:ApplyHorizontalMotionController() == false then
        if not self:IsNull() then
            self:Destroy()
        end
    end
end

function modifier_migi_inside:OnDestroy()
    if not IsServer() then return end
    self:GetCaster():FadeGesture(ACT_DOTA_CAST_ABILITY_1)
    self:GetParent():InterruptMotionControllers( true )
    if not self.success then return end
    if self.target:IsMagicImmune() then return end
    self.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_migi_inside_parent", {})
    self.target:EmitSound("Hero_LifeStealer.Infest")
end

function modifier_migi_inside:CheckState()
    local state = {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_STUNNED] = true,
    }

    return state
end

function modifier_migi_inside:UpdateHorizontalMotion( me, dt )
    local origin = self:GetParent():GetOrigin()
    if not self.target:IsAlive() then
        self:EndCharge( false )
    end
    local direction = self.target:GetOrigin() - origin
    direction.z = 0
    local distance = direction:Length2D()
    direction = direction:Normalized()

    if distance<self.close_distance then
        self:EndCharge( true )
    elseif distance>self.far_distance then
        self:EndCharge( false )
    end

    local target = origin + direction * self.speed * dt
    self:GetParent():SetOrigin( target )
    self:GetParent():FaceTowards( (self.target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized() )
end

function modifier_migi_inside:OnHorizontalMotionInterrupted()
    if not self:IsNull() then
        self:Destroy()
    end
end

function modifier_migi_inside:EndCharge( success )
    if success then
        self.success = true
    end
    if not self:IsNull() then
        self:Destroy()
    end
end


modifier_migi_inside_cooldown = class({})

function modifier_migi_inside_cooldown:IsHidden() return true end
function modifier_migi_inside_cooldown:RemoveOnDeath() return false end


modifier_migi_inside_parent = class({})

function modifier_migi_inside_parent:IsPurgable() return false end
function modifier_migi_inside_parent:IsHidden() return true end

function modifier_migi_inside_parent:OnCreated()
    self.ally = self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber()
    self.regen = self:GetAbility():GetSpecialValueFor("regen_enemy")
    if IsServer() then
        self.damage = self:GetCaster():GetAverageTrueAttackDamage(nil) / 100 * (self:GetAbility():GetSpecialValueFor("bonus_damage") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_4"))
        self.health = self:GetCaster():GetMaxHealth() / 100 * (self:GetAbility():GetSpecialValueFor("bonus_health") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_2"))
        self.magic_amplify = self:GetCaster():GetSpellAmplification(false) / 100 * (self:GetAbility():GetSpecialValueFor("bonus_magic_amplify") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_4"))
        self.health_regen = self:GetCaster():GetHealthRegen() / 100 * self:GetAbility():GetSpecialValueFor("health_regen")
        self:SetHasCustomTransmitterData(true)
        if not self:GetCaster():HasModifier("modifier_migi_inside_caster") then
            self.attack_time = 0
            self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_migi_inside_caster", {target = self:GetParent():entindex()})
        end
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_migi_inside_parent:OnRefresh()
    self:OnCreated()
end

function modifier_migi_inside_parent:AddCustomTransmitterData() return {
    damage = self.damage,
    health = self.health,
    magic_amplify = self.magic_amplify,
    health_regen = self.health_regen

} end

function modifier_migi_inside_parent:HandleCustomTransmitterData(data)
    self.damage = data.damage
    self.health = data.health
    self.magic_amplify = data.magic_amplify
    self.health_regen = data.health_regen
end

function modifier_migi_inside_parent:OnIntervalThink()
    self.ally = self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber()
    self:AddCustomTransmitterData()
    if IsServer() then
        self:GetParent():CalculateStatBonus(true)
        self:ForceRefresh()
        self.damage = self:GetCaster():GetAverageTrueAttackDamage(nil) / 100 * (self:GetAbility():GetSpecialValueFor("bonus_damage") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_4"))
        self.health = self:GetCaster():GetMaxHealth() / 100 * (self:GetAbility():GetSpecialValueFor("bonus_health") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_2"))
        self.magic_amplify = self:GetCaster():GetSpellAmplification(false) / 100 * (self:GetAbility():GetSpecialValueFor("bonus_magic_amplify") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_4"))
        self.health_regen = self:GetCaster():GetHealthRegen() / 100 * self:GetAbility():GetSpecialValueFor("health_regen")
        if self.ally then return end
        if self:GetParent():HasModifier("modifier_fountain_passive_invul") then return end
        self.attack_time = self.attack_time + FrameTime()
        if self.attack_time >= (self:GetAbility():GetSpecialValueFor("attack_cooldown") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_3")) then
            self:GetCaster():EmitSound("Hero_LifeStealer.Consume")
            self:GetCaster():PerformAttack(self:GetParent(), true, true, true, true, false, false, true)
            local infest_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_life_stealer/life_stealer_infest_cast.vpcf", PATTACH_POINT, self:GetParent())
            ParticleManager:SetParticleControl(infest_particle, 0, self:GetParent():GetAbsOrigin())
            ParticleManager:SetParticleControlEnt(infest_particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(infest_particle)
            self.attack_time = 0
        end
    end
end

function modifier_migi_inside_parent:OnDestroy()
    if not IsServer() then return end
    self:GetCaster():RemoveModifierByName("modifier_migi_inside_caster")
    if self:GetCaster():HasTalent("special_bonus_birzha_migi_6") then
        
    else
        self:GetCaster():BirzhaTrueKill(nil, self:GetCaster())
    end
end

function modifier_migi_inside_parent:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_AVOID_DAMAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }

    return funcs
end

function modifier_migi_inside_parent:GetModifierPreAttack_BonusDamage()
    if not self.ally then return end
    return self.damage
end

function modifier_migi_inside_parent:GetModifierHealthBonus()
    if not self.ally then return end
    return self.health
end

function modifier_migi_inside_parent:GetModifierConstantHealthRegen()
    if not self.ally then return end
    return self.health_regen
end

function modifier_migi_inside_parent:GetModifierSpellAmplify_Percentage()
    if not self.ally then return end
    return self.magic_amplify
end

function modifier_migi_inside_parent:GetModifierPhysicalArmorBonus()
    if self:GetCaster():HasShard() then
        if self.ally then
            return 7
        else
            return -7
        end
    end
    return 0
end

function modifier_migi_inside_parent:GetModifierHPRegenAmplify_Percentage()
    if self.ally then return end
    return self.regen
end

function modifier_migi_inside_parent:GetModifierAvoidDamage(keys)
    if not self.ally then return 0 end
    local ab = self:GetCaster():FindAbilityByName("migi_bubble")
    if ab and ab:GetLevel() > 0 then
        if ab:IsFullyCastable() then
            local nFXIndex = ParticleManager:CreateParticle( "particles/migi_shield.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() );
            ParticleManager:SetParticleControl( nFXIndex, 0, Vector( 0, 0, -1000 ) )
            ParticleManager:SetParticleControlEnt(nFXIndex, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
            ab:UseResources(false, false, true)
            return 1
        else
            return 0
        end
    end
    return 0
end

function modifier_migi_inside_parent:GetModifierMoveSpeedBonus_Percentage()
    if self.ally then
        local ab = self:GetCaster():FindAbilityByName("migi_speed")
        if ab and ab:GetLevel() > 0 then
            return ab:GetSpecialValueFor("movespeed") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_1")
        end
    end
    if not self.ally then
        local ab = self:GetCaster():FindAbilityByName("migi_speed")
        if ab and ab:GetLevel() > 0 then
            return (ab:GetSpecialValueFor("movespeed") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_1")) * -1
        end
    end

    return 0
end

function modifier_migi_inside_parent:GetModifierEvasion_Constant()
    if not self.ally then return 0 end
    local ab = self:GetCaster():FindAbilityByName("migi_speed")
    if ab and ab:GetLevel() > 0 then
        return ab:GetSpecialValueFor("evasion") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_1")
    end
    return 0
end

function modifier_migi_inside_parent:GetEffectName()
    return "particles/migi_infected.vpcf"
end

function modifier_migi_inside_parent:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

modifier_migi_inside_caster = class({})

function modifier_migi_inside_caster:IsPurgable() return false end
function modifier_migi_inside_caster:IsHidden() return true end

function modifier_migi_inside_caster:OnCreated(kv)
    if not IsServer() then return end
    self:GetParent():AddNoDraw()
    self.target = EntIndexToHScript(kv.target)
    self:StartIntervalThink(FrameTime())
    --self.target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_migi_inside_cooldown", {duration = 60})
    local ab = self:GetParent():FindAbilityByName("migi_inside")
    if ab then
        ab:SetActivated(false)
    end
end

function modifier_migi_inside_caster:OnDestroy()
    if not IsServer() then return end
    self:GetParent():RemoveNoDraw()
    local ab = self:GetParent():FindAbilityByName("migi_inside")
    if ab then
        ab:SetActivated(true)
    end
    if self.target and not self.target:IsNull() and self.target:IsAlive() then
        self.target:RemoveModifierByName("modifier_migi_inside_cooldown")
    end
end

function modifier_migi_inside_caster:OnIntervalThink()
    if not IsServer() then return end
    local abs = self.target:GetAbsOrigin()
    abs.z = 0
    self:GetParent():SetAbsOrigin(abs)
end

function modifier_migi_inside_caster:CheckState()
    return {
        [MODIFIER_STATE_STUNNED]            = true,
        [MODIFIER_STATE_INVULNERABLE]       = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION]  = true,
        [MODIFIER_STATE_NO_HEALTH_BAR]  = true,
        [MODIFIER_STATE_OUT_OF_GAME] = true,
    }
end

function modifier_migi_inside_caster:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ORDER
    }
end

function modifier_migi_inside_caster:OnOrder(keys)
    if not IsServer() then return end
    
    if keys.unit == self:GetParent() then
        local cancel_commands = 
        {
            [DOTA_UNIT_ORDER_MOVE_TO_POSITION]  = true,
            [DOTA_UNIT_ORDER_MOVE_TO_TARGET]    = true,
            [DOTA_UNIT_ORDER_ATTACK_MOVE]       = true,
            [DOTA_UNIT_ORDER_ATTACK_TARGET]     = true,
            [DOTA_UNIT_ORDER_CAST_POSITION]     = true,
            [DOTA_UNIT_ORDER_CAST_TARGET]       = true,
            [DOTA_UNIT_ORDER_CAST_TARGET_TREE]  = true,
            [DOTA_UNIT_ORDER_HOLD_POSITION]     = true,
            [DOTA_UNIT_ORDER_STOP]              = true
        }
        
        if cancel_commands[keys.order_type] and self:GetElapsedTime() >= 0.1 then
        	self.target:RemoveModifierByName("modifier_migi_inside_parent")
            local caster = self:GetCaster()
            if not self:IsNull() then
                self:Destroy()
            end
            caster:BirzhaTrueKill(nil, caster)
        end
    end
end

LinkLuaModifier( "modifier_migi_bubble", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

migi_bubble = class({})

function migi_bubble:GetIntrinsicModifierName()
    return "modifier_migi_bubble"
end

function migi_bubble:GetCooldown(level)
    return self.BaseClass.GetCooldown( self, level ) + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_7")
end

modifier_migi_bubble = class({})

function modifier_migi_bubble:IsPurgable() return false end
function modifier_migi_bubble:IsHidden() return true end

function modifier_migi_bubble:OnCreated( kv )
    if not IsServer() then return end
    self:StartIntervalThink(FrameTime())
end

function modifier_migi_bubble:OnIntervalThink( kv )
    if not IsServer() then return end
    local mod = self:GetParent():FindModifierByName("modifier_migi_inside_caster")
    if mod then
        local target = mod.target
        if target and target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
            if self:GetAbility():IsFullyCastable() then
                if target:HasModifier("modifier_fountain_passive_invul") then return end
                target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_birzha_stunned", {duration = self:GetAbility():GetSpecialValueFor("stun_duration") + self:GetCaster():FindTalentValue("special_bonus_birzha_migi_5")})
                local damageTable = {
                    victim = target,
                    attacker = self:GetParent(),
                    damage = self:GetAbility():GetSpecialValueFor("damage"),
                    damage_type = DAMAGE_TYPE_PURE,
                    ability = self:GetAbility()
                }
                ApplyDamage(damageTable)
                self:GetAbility():UseResources(false, false, true)
            end
        end
    end
end

migi_speed = class({})

LinkLuaModifier( "modifier_migi_mutation", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

migi_mutation = class({})

function migi_mutation:GetIntrinsicModifierName()
    return "modifier_migi_mutation"
end

modifier_migi_mutation = class({})

function modifier_migi_mutation:IsPurgable() return false end
function modifier_migi_mutation:IsHidden() return true end

function modifier_migi_mutation:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    }

    return funcs
end

function modifier_migi_mutation:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_migi_mutation:GetModifierHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_migi_mutation:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_migi_mutation:GetModifierSpellAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_amplify")
end

LinkLuaModifier( "modifier_migi_death", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

migi_death = class({})

function migi_death:OnOwnerSpawned()
    if not IsServer() then return end
    self:StartCooldown(60)
end

function migi_death:GetIntrinsicModifierName()
    return "modifier_migi_death"
end

modifier_migi_death = class({})

function modifier_migi_death:IsPurgable() return false end
function modifier_migi_death:IsHidden() return true end

function modifier_migi_death:OnCreated()
    if not IsServer() then return end
    self:GetAbility():StartCooldown(60)
    self:StartIntervalThink(FrameTime())
end

function modifier_migi_death:OnIntervalThink()
    if self:GetParent():HasModifier("modifier_birzha_start_game") then
         self:GetAbility():StartCooldown(60)
        return
    end
    if self:GetParent():HasModifier("modifier_migi_inside_caster") then
         self:GetAbility():StartCooldown(60)
        return
    end
    if self:GetAbility():IsFullyCastable() then
        self:GetParent():BirzhaTrueKill(nil, self:GetParent())
        self:GetAbility():StartCooldown(60)
    end
end

function modifier_migi_death:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    }
    return funcs
end

function modifier_migi_death:GetModifierStatusResistanceStacking()
    return 100
end

LinkLuaModifier( "modifier_migi_aghanim_ability", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_migi_weapon", "abilities/heroes/migi.lua", LUA_MODIFIER_MOTION_NONE )

migi_aghanim_ability = class({})

function migi_aghanim_ability:OnInventoryContentsChanged()
    if self:GetCaster():HasScepter() then
        self:SetHidden(false)       
        if not self:IsTrained() then
            self:SetLevel(1)
        end
    else
        self:SetHidden(true)
    end
end

function migi_aghanim_ability:OnHeroCalculateStatBonus()
    self:OnInventoryContentsChanged()
end

function migi_aghanim_ability:GetIntrinsicModifierName()
    if self:GetCaster():IsIllusion() then return end
    return "modifier_migi_aghanim_ability"
end

modifier_migi_aghanim_ability = class({})

function modifier_migi_aghanim_ability:IsPurgable() return false end
function modifier_migi_aghanim_ability:IsHidden() return true end

function modifier_migi_aghanim_ability:OnCreated(params)
    if IsServer() then
        self.spirits_num_spirits        = 0
        self.spirits_spiritsSpawned     = {}
        self.spirit_radius              = 600
        self:GetAbility().update_timer  = 0
        self.time_to_update             = 0.8
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_migi_aghanim_ability:OnIntervalThink()
    if IsServer() then
        if self:GetCaster():IsAlive() then
            local caster                    = self:GetCaster()
            local caster_position           = caster:GetAbsOrigin()
            local ability                   = self:GetAbility()
            local elapsedTime               = GameRules:GetGameTime() - 1
            local idealNumSpiritsSpawned    = elapsedTime / 1

            idealNumSpiritsSpawned  = math.min(idealNumSpiritsSpawned, 5)

            if self.spirits_num_spirits < idealNumSpiritsSpawned then
                local newSpirit = CreateUnitByName("npc_dota_wisp_spirit", caster_position, false, caster, caster, caster:GetTeam())
                local spiritIndex = self.spirits_num_spirits + 1
                newSpirit.spirit_index = spiritIndex
                self.spirits_num_spirits = spiritIndex
                self.spirits_spiritsSpawned[spiritIndex] = newSpirit
                newSpirit:AddNewModifier( caster, ability, "modifier_migi_weapon", {} )
            end
            

            local currentRadius = self.spirit_radius
            local deltaRadius   = 12
            currentRadius       = currentRadius + deltaRadius
            currentRadius       = math.min( math.max( currentRadius, 350 ), 350 )
            self.spirit_radius  = currentRadius
            local currentRotationAngle  = elapsedTime * 150
            local rotationAngleOffset   = 360 / 5

            for k,spirit in pairs( self.spirits_spiritsSpawned ) do
                if not spirit:IsNull() and spirit:IsAlive() then
                    local rotationAngle = currentRotationAngle - rotationAngleOffset * (k - 1)
                    local relPos        = Vector(0, currentRadius, 0)
                    relPos              = RotatePosition(Vector(0,0,0), QAngle( 0, -rotationAngle, 0 ), relPos)
                    local absPos        = GetGroundPosition( relPos + caster_position, spirit)
                    spirit:SetAbsOrigin(absPos)
                end
            end

            if ability.update_timer > self.time_to_update then
                for k,spirit in pairs( self.spirits_spiritsSpawned ) do
                    if spirit:IsNull() or not spirit:IsAlive() then
                        local rotationAngle = currentRotationAngle - rotationAngleOffset * (k - 1)
                        local relPos        = Vector(0, currentRadius, 0)
                        relPos              = RotatePosition(Vector(0,0,0), QAngle( 0, -rotationAngle, 0 ), relPos)
                        local absPos        = GetGroundPosition( relPos + caster_position, self:GetParent())
                        local newSpirit = CreateUnitByName("npc_dota_wisp_spirit", absPos, false, caster, caster, caster:GetTeam())
                        newSpirit.spirit_index = k
                        self.spirits_spiritsSpawned[k] = newSpirit
                        newSpirit:AddNewModifier( caster, ability, "modifier_migi_weapon", {} )
                        ability.update_timer = 0
                        break
                    end
                end
            end

            for k,spirit in pairs( self.spirits_spiritsSpawned ) do
                if spirit:IsNull() or not spirit:IsAlive() then
                    ability.update_timer    = ability.update_timer + FrameTime()
                    break
                end
            end
        end
    end
end


















modifier_migi_weapon = class({})

function modifier_migi_weapon:CheckState()
    local state = {
        [MODIFIER_STATE_NO_TEAM_MOVE_TO]    = true,
        [MODIFIER_STATE_NO_TEAM_SELECT]     = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_ATTACK_IMMUNE]      = true,
        [MODIFIER_STATE_MAGIC_IMMUNE]       = true,
        [MODIFIER_STATE_INVULNERABLE]       = true,
        [MODIFIER_STATE_UNSELECTABLE]       = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP]     = true,
        [MODIFIER_STATE_NO_HEALTH_BAR]      = true,
    }

    return state
end

function modifier_migi_weapon:OnCreated(params)
    if IsServer() then
        local pfx_pull = ParticleManager:CreateParticle("particles/migi_pull.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt( pfx_pull, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetOrigin(), true )
        ParticleManager:SetParticleControlEnt( pfx_pull, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true )
        self:AddParticle(pfx_pull, true, false, -1, false, false)
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_migi_weapon:OnIntervalThink()
    if IsServer() then
        if not self:GetCaster():IsAlive() then self:GetParent():ForceKill(false) return end 
        if not self:GetCaster():HasScepter() then self:GetParent():ForceKill(false) return end 
        local spirit = self:GetParent()
        local nearby_enemy_units = FindUnitsInRadius(
            self:GetCaster():GetTeam(),
            spirit:GetAbsOrigin(), 
            nil, 
            100, 
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
            DOTA_UNIT_TARGET_FLAG_NONE, 
            FIND_ANY_ORDER, 
            false
        )

        if nearby_enemy_units ~= nil and #nearby_enemy_units > 0 then
            modifier_migi_weapon:OnHit(self:GetCaster(), spirit, nearby_enemy_units, 50 + self:GetCaster():GetAverageTrueAttackDamage(nil) * 0.4, self:GetAbility())
        end
    end
end

function modifier_migi_weapon:OnHit(caster, spirit, enemies_hit, damage, ability) 
    local damage_table          = {}
    damage_table.attacker       = caster
    damage_table.ability        = ability
    damage_table.damage_type    = DAMAGE_TYPE_PURE
    damage_table.damage = damage
    for _,enemy in pairs(enemies_hit) do
        if enemy:IsAlive() and not spirit:IsNull() then 
            damage_table.victim = enemy
            ApplyDamage(damage_table)
            local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, nil )
            ParticleManager:SetParticleControlEnt( nFXIndex, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true )
            ParticleManager:SetParticleControl( nFXIndex, 1, enemy:GetOrigin() )
            ParticleManager:SetParticleControlForward( nFXIndex, 1, (spirit:GetOrigin()-enemy:GetOrigin()):Normalized() )
            ParticleManager:SetParticleControlEnt( nFXIndex, 10, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetOrigin(), true )
            ParticleManager:ReleaseParticleIndex( nFXIndex )
            enemy:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
            spirit:ForceKill(false)
            break
        end
    end
end