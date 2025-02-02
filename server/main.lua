local _ipairs = ipairs
local _pcall = pcall

local GlobalCallbacks<const> = {}
local GlobalDefaultData<const> = {}

exports("AttachGlobalHandler", function(id, cb)
    GlobalCallbacks[id] = GlobalCallbacks[id] or {}
    GlobalCallbacks[id][#GlobalCallbacks[id]+1] = cb
end)

exports("UpdateGlobalState", function(source, id, identifier, key, value)
    key = "$" .. key
    local res = GetInvokingResource()
    for _, cb in _ipairs(GlobalCallbacks[id]) do
        _pcall(cb, source, identifier, key, value, res)
    end
end)

exports("DoesGlobalStateExist", function(id)
    return GlobalDefaultData[id] ~= nil
end)

exports("SetGlobalStateData", function(id, data)
    GlobalDefaultData[id] = data
end)

exports("GetGlobalStateDefaultData", function(id)
    return GlobalDefaultData[id]
end)