local ESX = GetResourceState("es_extended") == "started" and exports.es_extended:getSharedObject()
local esxIdentifier = ESX and ESX.GetPlayerFromId

local _type = type
local _pairs = pairs
local _setmetatable = setmetatable

local GL_STATE_ID<const> = "$__PL_ST"

---@param source number|string
---@return string
local function GetPlayerIdentifier(source)
    if _type(source) ~= "number" then return source end
    if esxIdentifier then
        return esxIdentifier(source).identifier
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return GetPlayerIdentifierByType(source, "license")
end

local States<const> = {}
local StatesOptions<const> = {
    __save_instant = false,
    __update_client = false
}
StatesOptions.__index = StatesOptions
local PlayerStates<const> = {}

local ToBeSaved<const> = {}

local cached_export = exports.PlayerStates

local EnsurePlayerState = function(...)
    return cached_export:EnsurePlayerState(...)
end
local SetPlayerState = function(...)
    return cached_export:SetPlayerState(...)
end
local SetPlayerStateAsync = function(...)
    return cached_export:SetPlayerStateAsync(...)
end
local GetPlayerState = function(...)
    return cached_export:GetPlayerState(...)
end

---@param source number
---@param id string
---@return boolean|table
local function State(source, id, global_id)
    local invoking = (global_id and GL_STATE_ID) or GetInvokingResource() or GetCurrentResourceName()
    if global_id then
        if cached_export:DoesGlobalStateExist(id) then
            local state_data = cached_export:GetGlobalStateDefaultData(id)
            States[id] = States[id] or {}
            States[id][invoking] = state_data
        end
    end
    if not States[id] or not States[id][invoking] then return false end
    local identifier = GetPlayerIdentifier(source)
    if not PlayerStates[identifier] then
        PlayerStates[identifier] = {}
    end
    if not PlayerStates[identifier][invoking] then
        PlayerStates[identifier][invoking] = {}
    end
    if not PlayerStates[identifier][invoking][id] then
        local data = GetPlayerState(id, invoking, identifier)
        if not data then
            EnsurePlayerState(id, invoking, identifier)
        end
        local __sdata = {}
        for k,v in pairs(States[id][invoking]) do
            __sdata[k] = v
        end
        if data then
            for name, value in _pairs(data) do
                if __sdata[name] ~= nil then
                    __sdata[name] = value
                end
            end
        end
        local __soptions = _setmetatable({}, StatesOptions)
        ToBeSaved[identifier] = ToBeSaved[identifier] or {}
        ToBeSaved[identifier][id] = ToBeSaved[identifier][id] or {}
        PlayerStates[identifier][invoking][id] = _setmetatable({}, {
            __index = function (_, k)
                if k == "__data" then
                    return __sdata
                end
                return __sdata[k] or __soptions[k]
            end,
            __newindex = function(_, k, v)
                if __soptions[k] ~= nil then
                    __soptions[k] = v
                    return
                end
                local isNew = false
                if k:sub(1, 1) == "$" then
                    k = k:sub(2)
                    isNew = true
                end
                if __sdata[k] == nil then return end
                if __sdata[k] == v then
                    return
                end
                __sdata[k] = v
                if __soptions.__save_instant and not isNew then
                    SetPlayerState(id, invoking, identifier, __sdata)
                    if global_id then
                        cached_export:UpdateGlobalState(source, id, identifier, k, v)
                        if __soptions.__update_client then
                            TriggerClientEvent("fsl_ps:update:global:"..id, source, k, v)
                        end
                    else
                        if __soptions.__update_client then
                            TriggerClientEvent("fsl_ps:update:"..invoking..":"..id, source, k, v)
                        end
                    end
                elseif not isNew then
                    ToBeSaved[identifier][id][invoking] = ToBeSaved[identifier][id][invoking] or {
                        id = id,
                        invoking = invoking,
                        identifier = identifier,
                        data = __sdata
                    }
                    if global_id then
                        cached_export:UpdateGlobalState(source, id, identifier, k, v)
                        if __soptions.__update_client then
                            TriggerClientEvent("fsl_ps:update:global:"..id, source, k, v)
                        end
                    else
                        if __soptions.__update_client then
                            TriggerClientEvent("fsl_ps:update:"..invoking..":"..id, source, k, v)
                        end
                    end
                end
            end
        })
    end
    return PlayerStates[identifier][invoking][id]
end

function CreateState(id, args)
    local invoking = GetInvokingResource() or GetCurrentResourceName()
    if not States[id] then
        States[id] = {}
    end
    if States[id][invoking] then return false end
    States[id][invoking] = args
    RegisterNetEvent("fsl_ps:get:state:"..invoking..":"..id, function()
        local src = source
        local state = State(src, id)
        if state.__update_client then
            TriggerClientEvent("fsl_ps:get:state:"..invoking..":"..id, src, state.__data)
        else
            TriggerClientEvent("fsl_ps:get:state:"..invoking..":"..id, src, -1)
        end
    end)
end

function CreateGlobalState(id, args)
    local invoking = GL_STATE_ID
    if not States[id] then
        States[id] = {}
    end
    if States[id][invoking] then return false end
    States[id][invoking] = args
    cached_export:SetGlobalStateData(id, args)
    RegisterNetEvent("fsl_ps:get:global:state:"..id, function()
        local src = source
        local state = State(src, id, true)
        if state.__update_client then
            TriggerClientEvent("fsl_ps:get:global:state:"..id, src, state.__data)
        else
            TriggerClientEvent("fsl_ps:get:global:state:"..id, src, -1)
        end
    end)
end

---@param id string
---@return function|boolean
function GetState(id)
    if not States[id] then return false end
    ---@param source number
    ---@return any
    return function(source)
        return State(source, id)
    end
end

local GlobalStates<const> = {}

function GetGlobalState(id)
    if not GlobalStates[id] then
        cached_export:AttachGlobalHandler(id, function(source, _, index, value, res)
            if res == GetCurrentResourceName() then return end
            State(source, id, true)[index] = value
        end)
        GlobalStates[id] = true
    end
    return function(source)
        return State(source, id, true)
    end
end

AddEventHandler("onResourceStop", function (resName)
    if resName == GetCurrentResourceName() then
        for _, players_data in _pairs(ToBeSaved) do
            for _, data in _pairs(players_data) do
                for _, v in _pairs(data) do
                    SetPlayerStateAsync(v.id, v.invoking, v.identifier, v.data)
                end
            end
        end
    end
end)

CreateThread(function()
    local _Wait = Wait
    while true do
        _Wait(1000 * 60 * 10)
        for _, players_data in _pairs(ToBeSaved) do
            for _, data in _pairs(players_data) do
                for k, v in _pairs(data) do
                    SetPlayerStateAsync(v.id, v.invoking, v.identifier, v.data)
                    data[k] = nil
                end
            end
        end
    end
end)