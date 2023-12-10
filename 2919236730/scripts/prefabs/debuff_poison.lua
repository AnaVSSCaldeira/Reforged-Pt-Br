--TODO RENAME THIS ALL TO ACID!
--[[
TODO
create debuff for poison
	make adjustable
	make scorpeon stuff call it with the correct parameters
optimize and clean the code
impact does 10 dmg without armor, so impact is affected by armor, wearing stone reduces it to 1 dmg, then the poison deals 8 dmg/s for 8 seconds
--]]
local assets = {}
local prefabs = {}
local tuning_values = TUNING.FORGE.SCORPEON
--------------------------------------------------------------------------
local function OnTick(inst, target) -- TODO need to have a check to make sure damage does not go over total_damage, also the animation for the health loss doesn't consistenly decrease due to the tick rate. Maybe make the tick rate be whatever 1 health would be? this way the animation is clean
    -- Extra check just in case this runs after the debuff has been removed
    if not target.components.debuffable:HasDebuff(inst.debuff_name) then
        target.components.health:RemoveRegen(inst.debuff_name)
        return
    end
	local current_time = GetTime()
	local current_tick_duration = current_time - inst.previous_tick_time
	inst.previous_tick_time = current_time
    if target.components.health and not target.components.health:IsDead() and not target:HasTag("playerghost") then -- TODO any method that checks these?
		local poison_dmg = -inst.total_damage / inst.duration * current_tick_duration--(inst.tick_rate - FRAMES)
		if target.components.buffable then -- Apply poison resistance
			target.components.buffable:ApplyStatBuffs({"poison_resistance"}, poison_dmg) -- TODO "poison_resistance" good name? is there a better name? acid_resistance??? if so then change poison to acid everywhere
		end
		target.components.health:DoDelta(poison_dmg < 0 and poison_dmg or 0, true, inst.cause, nil, inst.caster, true)
        target.components.health:AddRegen(inst.debuff_name, (poison_dmg/(inst.tick_rate/FRAMES)) * 30) -- Calculate 1 seconds worth of damage
    else
        inst.components.debuff:Stop()
    end
end

local function OnAttached(inst, target)
    inst.entity:SetParent(target.entity)
    inst.task = inst:DoPeriodicTask(inst.tick_rate, OnTick, nil, target) -- TODO low tick rate causes issues...hmmm
	inst.previous_tick_time = GetTime()
	if target.components.colouradder then
        target.components.colouradder:PushColour("debuff_poison_" .. tostring(inst.GUID), inst.colour_to_add[1], inst.colour_to_add[2], inst.colour_to_add[3], 1, true, inst.colour_add_speed)
    end
    --inst:DoTaskInTime(0, function() -- Delay one frame to ensure any changes made to the total damage and duration
        --target.components.health:AddRegen(inst.prefab, -inst.total_damage/inst.duration)
    --end)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function OnDetached(inst, target)
	if target.components.colouradder then
        target.components.colouradder:PopColour("debuff_poison_" .. tostring(inst.GUID), true, inst.colour_add_speed)
	end
    target:DoTaskInTime(0, function()
        target.components.health:RemoveRegen(inst.debuff_name)
    end)
	inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "corrosiveover" then
        inst.components.debuff:Stop()
    end
end

local function OnExtended(inst, target)
    inst.components.timer:StopTimer("corrosiveover")
    inst.components.timer:StartTimer("corrosiveover", inst.duration)
end

local function DoT_OnInit(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil then
        parent:PushEvent("startcorrosivedebuff", inst)
    end
end
--------------------------------------------------------------------------
local function dot_fn(inst)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	inst.entity:AddNetwork()
    ------------------------------------------
	inst:AddTag("CLASSIFIED")
	------------------------------------------
    inst:DoTaskInTime(0, DoT_OnInit)
	------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
    if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff:SetExtendedFn(OnExtended)
	------------------------------------------
	inst.duration = 10 -- in seconds
	inst.total_damage = 50
	inst.tick_rate = 4*FRAMES--0.1 -- of a second (for acid)
	inst.colour_to_add = {0.1, 0.5, 0.1}
	inst.colour_add_speed = 0.25 -- seconds it takes to reach color
	inst.cause = "poison_dot"
	inst.caster = nil
	inst.debuff_name = "debuff_poison"
    ------------------------------------------
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", OnTimerDone)
	------------------------------------------
	inst.SetCaster = function(inst, caster)
		inst.caster = caster
	end
	inst.SetDebuffName = function(inst, name)
		inst.debuff_name = name
	end
	inst.Start = function(inst)
		inst.components.timer:StartTimer("corrosiveover", inst.duration)
	end
	------------------------------------------
	return inst
end

local function scorpeon_acid_fn(inst)
	local inst = dot_fn(inst)
	------------------------------------------
	inst.entity:SetPristine()
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end
	------------------------------------------
	inst.duration = tuning_values.ACID_WEAROFF_TIME
	inst.nameoverride = "peghook_dot" -- So we don't have to make the describe strings.
	inst.total_damage = tuning_values.ACID_DAMAGE_TOTAL
	inst.cause = "peghook_dot"
	inst.debuff_name = "scorpeon_dot"
	inst:Start()
	------------------------------------------
	return inst
end

return Prefab("debuff_poison", dot_fn),
	Prefab("scorpeon_dot", scorpeon_acid_fn)
