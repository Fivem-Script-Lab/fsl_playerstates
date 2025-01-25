local esxIdentifier = ESX and ESX.GetPlayerFromId
local _type = type

---@param source number
---@return string
function GetPlayerIdentifier(source)
    if _type(source) ~= "number" then return source end
    return esxIdentifier and (esxIdentifier(source).identifier) or GetPlayerIdentifierByType(source, "license")
end