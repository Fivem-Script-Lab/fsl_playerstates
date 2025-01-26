local esxIdentifier = ESX and ESX.GetPlayerFromId
local _type = type

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
    __save_instant = true
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

function CreateState(id, args)
    local invoking = GetInvokingResource() or GetCurrentResourceName()
    if not States[id] then
        States[id] = {}
    end
    if States[id][invoking] then return false end
    States[id][invoking] = args
    States[id][invoking].__index = States[id][invoking]
end

---@param source number
---@param id string
---@return boolean|table
function State(source, id)
    local invoking = GetInvokingResource() or GetCurrentResourceName()
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
        local __sdata = setmetatable({}, States[id][invoking])
        if data then
            for name, value in pairs(data) do
                if __sdata[name] ~= nil then
                    __sdata[name] = value
                end
            end
        end
        local __soptions = setmetatable({}, StatesOptions)
        ToBeSaved[identifier] = ToBeSaved[identifier] or {}
        ToBeSaved[identifier][id] = ToBeSaved[identifier][id] or {}
        PlayerStates[identifier][invoking][id] = setmetatable({}, {
            __index = function (_, k)
                return __sdata[k]
            end,
            __newindex = function(_, k, v)
                if __soptions[k] ~= nil then
                    __soptions[k] = v
                    return
                end
                if __sdata[k] == nil then return end
                if __sdata[k] == v then
                    return
                end
                __sdata[k] = v
                if __soptions.__save_instant then
                    SetPlayerState(id, invoking, identifier, __sdata)
                else
                    ToBeSaved[identifier][id][invoking] = ToBeSaved[identifier][id][invoking] or {
                        id = id,
                        invoking = invoking,
                        identifier = identifier,
                        data = __sdata
                    }
                end
            end
        })
    end
    return PlayerStates[identifier][invoking][id]
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

AddEventHandler("onResourceStop", function (resName)
    if resName == GetCurrentResourceName() then
        for _, players_data in pairs(ToBeSaved) do
            for _, data in pairs(players_data) do
                for _, v in pairs(data) do
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
        for _, players_data in pairs(ToBeSaved) do
            for _, data in pairs(players_data) do
                for k, v in pairs(data) do
                    SetPlayerStateAsync(v.id, v.invoking, v.identifier, v.data)
                    data[k] = nil
                end
            end
        end
    end
end)