local function OnSymbolDirty(inst, name, prefab, symbol)
    --inst:PushEvent("clientpethealthsymboldirty", { symbol = inst.components.pethealthbar:GetSymbol() })
    inst:PushEvent("clientpethealthsymboldirty", {name = name, prefab = prefab, symbol = symbol})
end

-- [0-4] for over time
local function OnStatusDirty(inst, name, prefab, status)
    --inst:PushEvent("clientpethealthstatusdirty")
    inst:PushEvent("clientpethealthstatusdirty", {name = name, prefab = prefab, status = status})
end

 -- 1 = green, 2 = red -- Note: This is hooked up like a net_event
local function OnPulseDirty(inst, name, prefab, pulse)
    --inst:PushEvent("clientpethealthpulsedirty")
    inst:PushEvent("clientpethealthpulsedirty", {name = name, prefab = prefab, pulse = pulse})
end

local function OnHealthMaxDirty(inst, name, prefab, max_health)
    --inst:PushEvent("clientpetmaxhealthdirty", { max = inst.components.pethealthbar._maxhealth:value() })
    inst:PushEvent("clientpetmaxhealthdirty", {name = name, prefab = prefab, max = max_health})
end

local function OnHealthPctDirty(inst, name, prefab, health_percent)
    --inst:PushEvent("clientpethealthdirty", { percent = inst.components.pethealthbar._healthpct:value() })
    inst:PushEvent("clientpethealthdirty", {name = name, prefab = prefab, percent = health_percent})
end

local function OnPetSkinDirty(inst, name, prefab, skin)
    --inst:PushEvent("clientpetskindirty")
    inst:PushEvent("clientpetskindirty", {name = name, prefab = prefab, skin = skin})
end

local function OnHealthDelta(inst, pet, data)
    local self = inst.components.pethealthbars
    if self then
        local name = self.pets[pet]
        local pet_info = name and self.pet_info[name]
        local prev_health = pet_info.health_percent
        pet_info.health_percent = data.newpercent
        if prev_health ~= pet_info.health_percent then
            if not data.overtime and data.oldpercent ~= nil then
                --self._pulse:set_local(0) -- TODO how to handle this?
                pet_info.pulse = data.oldpercent < data.newpercent and 1 or 2
            end
            self:UpdatePetsStr()
            OnHealthPctDirty(inst, name, pet.prefab, data.newpercent)
        end
    end
end

local function onsetpetskin(self, petskin)
    self._petskin:set(petskin)
end

local function OnPetAdded(inst, name, prefab)
    inst:PushEvent("clientpetadded", {name = name, prefab = prefab})
end

local function OnPetRemoved(inst, name, prefab)
    inst:PushEvent("clientpetremoved", {name = name, prefab = prefab})
end

local function OnPetsStr(inst)
    local self = inst.components.pethealthbars
    if self then
        local old_pet_info = self:GetPetsInfo()
        local pets_str = self:GetPetsStr()
        self.client_pet_info = pets_str and ConvertStringToTable(pets_str) or {}
        for name,info in pairs(self.client_pet_info) do
            local old_info = old_pet_info[name]
            if old_info then
                if info.symbol ~= old_info.symbol then
                    OnSymbolDirty(inst, name, info.prefab, info.symbol)
                end
                if info.status ~= old_info.status then
                    OnStatusDirty(inst, name, info.prefab, info.status)
                end
                if info.max_health ~= old_info.max_health then
                    OnPulseDirty(inst, name, info.prefab, info.max_health)
                end
                if info.pulse ~= old_info.pulse then
                    OnHealthMaxDirty(inst, name, info.prefab, info.pulse)
                end
                if info.health_percent ~= old_info.health_percent then
                    OnHealthPctDirty(inst, name, info.prefab, info.health_percent)
                end
                if info.skin ~= old_info.skin then
                    OnPetSkinDirty(inst, name, info.prefab, info.skin)
                end
            else
                OnPetAdded(inst, name, info.prefab)
            end
        end
        for name,info in pairs(old_pet_info) do
            if not self.client_pet_info[name] then
                OnPetRemoved(inst, name, info.prefab)
            end
        end
    end
end

local PetHealthBars = Class(function(self, inst)
    self.inst = inst
    self.pets = {}
    self.pet_info = {}
    self.client_pet_info = {}
    self.tasks = {}
    self._pets_str = net_string(inst.GUID, "pethealthbars._pets_str", "newpetinfo")
    self.ismastersim = TheWorld.ismastersim

    if self.ismastersim then
        self._onhealthdelta = function(pet, data)
            OnHealthDelta(self.inst, pet, data)
        end

        self.corrosives = {}
        self._onremovecorrosive = function(debuff)
            local pet = debuff.pethealthbar_pet
            if pet and self.corrosives[pet] then
                self.corrosives[pet][debuff] = nil
            end
        end
        self._onstartcorrsivedebuff = function(pet, debuff)
            if self.corrosives[pet][debuff] == nil then
                self.corrosives[pet][debuff] = true
                debuff.pethealthbar_pet = pet
                self.inst:ListenForEvent("onremove", self._onremovecorrosive, debuff)
            end
        end

        self.hots = {}
        self._onremovehots = function(debuff)
            local pet = debuff.pethealthbar_pet
            if pet and self.hots[pet] then
                self.hots[debuff] = nil
            end
        end
        self._onstarthealthregen = function(pet, debuff)
            if self.hots[pet][debuff] == nil then
                self.hots[pet][debuff] = true
                debuff.pethealthbar_pet = pet
                self.inst:ListenForEvent("onremove", self._onremovehots, debuff)
            end
        end

        self.small_hots = {}
        self._onremovesmallhots = function(debuff)
            local pet = debuff.pethealthbar_pet
            if pet and self.small_hots[pet] then
                self.small_hots[debuff] = nil
            end
        end
        self._onstartsmallhealthregen = function(pet, debuff)
            if self.small_hots[pet][debuff] == nil then
                self.small_hots[pet][debuff] = true
                debuff.pethealthbar_pet = pet
                self.inst:ListenForEvent("onremove", self._onremovesmallhots, debuff)
            end
        end

        self._onremove = function(pet)
            self:RemovePet(pet)
        end
    else
        inst:ListenForEvent("newpetinfo", OnPetsStr)
        inst:DoTaskInTime(0, OnHealthPctDirty) -- TODO needed? for some reason they call this with a frame delay, some sort of initializer?
    end
end)
--------------------------------------------------------------------------
-- Common
--------------------------------------------------------------------------
function PetHealthBars:GetSymbol(pet, key)
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    return pet_info and pet_info.symbol
end

function PetHealthBars:GetMaxHealth(pet, key)
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    return pet_info and pet_info.max_health
end

-- returns -2 large down, -1 small down, 0 none, 1 small up, 2 large up
function PetHealthBars:GetOverTime()
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    local val = pet_info and pet_info.status
    return ((val <= 0 or val >= 5) and 0)
        or (val <= 2 and val)
        or val - 5
end

function PetHealthBars:GetPercent()
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    return pet_info and pet_info.health_percent
end

function PetHealthBars:GetPulse()
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    return pet_info and pet_info.pulse
end

function PetHealthBars:ResetPulse()
    local name = pet and self.pets[pet]
    local pet_info = self.ismastersim and name and self.pet_info[name] or not self.ismastersim and self.client_pet_info[key]
    if pet_info then
        pet_info.pulse = 0
    end
end

function PetHealthBars:GetPetsStr()
    return self._pets_str:value()
end

function PetHealthBars:GetPetsInfo()
    return self.ismastersim and self.pet_info or self.client_pet_info
end

function PetHealthBars:GetPetInfo(name)
    local pet_info = self:GetPetsInfo()
    return pet_info and pet_info[name]
end
--------------------------------------------------------------------------
-- Server only
--------------------------------------------------------------------------
function PetHealthBars:SetSymbol(pet, symbol)
    local name = self.pets[pet]
    local pet_info = name and self.pet_info[name]
    if self.ismastersim and pet_info and  pet_info.symbol ~= symbol then
        pet_info.symbol = symbol
        self:UpdatePetsStr()
        OnSymbolDirty(self.inst, name, pet.prefab, symbol)
    end
end

function PetHealthBars:SetMaxHealth(pet, max_health)
    local name = self.pets[pet]
    local pet_info = name and self.pet_info[name]
    if self.ismastersim and pet_info and pet_info.max_health ~= max_health then
        pet_info.max_health = max_health
        self:UpdatePetsStr()
        OnHealthMaxDirty(self.inst, name, pet.prefab, max_health)
    end
end

function PetHealthBars:SetPetSkin(pet, skin)
    local name = self.pets[pet]
    local pet_info = name and self.pet_info[name]
    if self.ismastersim and pet_info and pet_info.skin ~= skin then
        pet_info.skin = skin or 0
        self:UpdatePetsStr()
        OnPetSkinDirty(self.inst, name, pet.prefab, skin)
    end
end

local function InitPet(inst, self, pet)
    self.tasks[pet] = nil
    local name = self.pets[pet]
    local health_percent = pet.components.health and pet.components.health:GetPercent() or 1
    if self.pet_info[name].health_percent ~= health_percent then
        self.pet_info[name].health_percent = health_percent
        self:UpdatePetsStr()
        OnHealthPctDirty(self.inst, name, pet.prefab, health_percent)
    end
end

function PetHealthBars:AddPet(pet, symbol, max_health, no_removal)
    if self.ismastersim and not self.pets[pet] then
        -- Generate name for storing the pet
        local name = pet.prefab
        local count = 1
        while(self.pet_info[name]) do
            name = pet.prefab .. "_" .. tostring(count)
            count = count + 1
        end

        self.pets[pet] = name

        self.pet_info[name] = {
            prefab = pet.prefab,
            symbol = symbol,
            status = 0,
            max_health = max_health or pet.components.health and pet.components.health.maxhealth or 100,
            pulse = 0,
            health_percent = pet.components.health and pet.components.health:GetPercent() or 1,
            skin = pet.skinname or 0,
        }

        self.corrosives[pet] = {}
        self.hots[pet]       = {}
        self.small_hots[pet] = {}

        self.inst:ListenForEvent("healthdelta", self._onhealthdelta, pet)
        self.inst:ListenForEvent("startcorrosivedebuff", self._onstartcorrsivedebuff, pet)
        self.inst:ListenForEvent("starthealthregen", self._onstarthealthregen, pet)
        self.inst:ListenForEvent("startsmallhealthregen", self._onstartsmallhealthregen, pet)
        if not no_removal then
            self.inst:ListenForEvent("onremove", self._onremove, pet)
        end
        self.tasks[pet] = self.inst:DoTaskInTime(0, InitPet, self, pet)

        self:UpdatePetsStr()
        OnPetAdded(self.inst, name, pet.prefab)
        self.inst:StartUpdatingComponent(self)

        return name
    end
end

function PetHealthBars:RemovePet(pet)
    if self.pets[pet] then
        local name = self.pets[pet]
        if self.tasks[pet] ~= nil then
            self.tasks[pet]:Cancel()
        end
        self.inst:RemoveEventCallback("healthdelta", self._onhealthdelta, pet)
        self.inst:RemoveEventCallback("startcorrosivedebuff", self._onstartcorrsivedebuff, pet)
        self.inst:RemoveEventCallback("starthealthregen", self._onstarthealthregen, pet)
        self.inst:RemoveEventCallback("startsmallhealthregen", self._onstartsmallhealthregen, pet)
        self.inst:RemoveEventCallback("onremove", self._onremove, pet)

        local k = next(self.corrosives[pet])
        while k ~= nil do
            self.inst:RemoveEventCallback("onremove", self._onremovecorrosive, k)
            self.corrosives[pet][k] = nil
            k = next(self.corrosives[pet])
        end
        self.corrosives[pet] = nil
        k = next(self.hots[pet])
        while k ~= nil do
            self.inst:RemoveEventCallback("onremove", self._onremovehots, k)
            self.hots[pet][k] = nil
            k = next(self.hots[pet])
        end
        self.hots[pet] = nil
        k = next(self.small_hots[pet])
        while k ~= nil do
            self.inst:RemoveEventCallback("onremove", self._onremovesmallhots, k)
            self.small_hots[pet][k] = nil
            k = next(self.small_hots[pet])
        end
        self.small_hots[pet] = nil

        self.pet_info[name] = nil
        self.pets[pet] = nil

        self:UpdatePetsStr()
        OnPetRemoved(self.inst, name, pet.prefab)
    end
end

function PetHealthBars:OnUpdate(dt)
    local status_change = false
    for pet,name in pairs(self.pets) do
        if not (pet and pet.replica.health) then return end
        local regen = pet.replica.health:GetPercent() < 1 and pet.replica.health:GetRegen() or 0
        local MOST_REGEN_THRESHOLD = 5
        -- These values are from the original OnUpdate function that uses self:GetOverTime()
        local status = (regen <= -MOST_REGEN_THRESHOLD and 3) or
        (regen < 0 and 4) or
        (regen >= MOST_REGEN_THRESHOLD and 2) or
        (regen > 0 and 2) or 0 -- TeammateHealthBadge does not show regen with 1 so force to 2

        if self.pet_info[name].status ~= status then
            status_change = true
            self.pet_info[name].status = status
        end
    end
    if status_change then
        self:UpdatePetsStr()
    end
end

function PetHealthBars:UpdatePetsStr()
    self._pets_str:set(SerializeTable(self.pet_info))
end

function PetHealthBars:GetDebugString()
    local debug_str = ""
    local count = 1
    for pet,name in pairs(self.pets) do
        if count > 1 then
            debug_str = debug_str .. ", "
        end
        count = count + 1
        local pet_info = self.pet_info[name]
        debug_str = debug_str .. string.format("name: %s, %0.2f%% of %d, sym: 0x%08X, stat: %d", name, pet_info.health_percent * 100, pet_info.max_health, pet_info.symbol or 0, pet_info.status)
    end
    return debug_str == "" and "no pets" or debug_str
end

return PetHealthBars
