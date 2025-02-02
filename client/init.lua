---StatesHandlersStatus Options:
-- 1 - Awaiting response
-- -1 - Server does not allow data transfer
-- -2 - State does not exist

local StatusHandlers<const> = {}
local StatesHandlersStatus<const> = {}

function GetState(id)
    if StatesHandlersStatus[id] ~= nil then
        return
    end
    StatesHandlersStatus[id] = promise:new()
    TriggerServerEvent("fsl_ps:get:state:"..GetCurrentResourceName()..":"..id)
    RegisterNetEvent("fsl_ps:get:state:"..GetCurrentResourceName()..":"..id, function(state)
        if state == -1 then
            StatesHandlersStatus[id]:resolve(-1)
        else
            local __sdata = state
            StatusHandlers[id] = setmetatable({}, {
                __index = function (t, k)
                    return __sdata[k]
                end,
                __newindex = function(_, _, _)end
            })
            StatesHandlersStatus[id]:resolve(0)
        end
    end)
    RegisterNetEvent("fsl_ps:update:"..GetCurrentResourceName()..":"..id, function(k, v)
        if StatusHandlers[id] == nil then
            local waited = 0
            while not StatusHandlers[id] and waited < 50 do
                Wait(100)
                waited += 1
            end
            if not StatusHandlers[id] or StatesHandlersStatus[id].value == -1 then
                return
            end
        end
        rawset(StatusHandlers[id], k, v)
    end)
    Citizen.Await(StatesHandlersStatus[id])
    return function()
        return StatusHandlers[id]
    end
end

local GlobalStatusHandlers<const> = {}
local GlobalStatesHandlersStatus<const> = {}

function GetGlobalState(id)
    if GlobalStatesHandlersStatus[id] ~= nil then
        return
    end
    GlobalStatesHandlersStatus[id] = promise:new()
    TriggerServerEvent("fsl_ps:get:global:state:"..id)
    RegisterNetEvent("fsl_ps:get:global:state:"..id, function(state)
        if state == -1 then
            GlobalStatesHandlersStatus[id]:resolve(-1)
        else
            local __sdata = state
            GlobalStatusHandlers[id] = setmetatable({}, {
                __index = function (t, k)
                    return __sdata[k] or rawget(t, k)
                end,
                __newindex = function(_, _, _)end
            })
            GlobalStatesHandlersStatus[id]:resolve(0)
        end
    end)
    RegisterNetEvent("fsl_ps:update:global:"..id, function(k, v)
        if GlobalStatusHandlers[id] == nil then
            local waited = 0
            while not GlobalStatusHandlers[id] and waited < 50 do
                Wait(100)
                waited += 1
            end
            if not GlobalStatusHandlers[id] or GlobalStatesHandlersStatus[id].value == -1 then
                return
            end
        end
        rawset(GlobalStatusHandlers[id], k, v)
    end)
    Citizen.Await(GlobalStatesHandlersStatus[id])
    return function()
        return GlobalStatusHandlers[id]
    end
end