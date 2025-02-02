local DB = exports.DatabaseManager:GetDatabaseTableManager("player_states2")

CreateThread(function()
    DB.Create({
        {"id", "INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT"},
        {"state", "VARCHAR(255) NOT NULL"},
        {"resource", "VARCHAR(255) NULL"},
        {"identifier", "VARCHAR(255) NOT NULL"},
        {"data", "LONGTEXT NULL DEFAULT '[]'"}
    })
end)

local DB_SELECT_USER = DB.Prepare.Select({"state", "resource", "identifier"})
local DB_INSERT_USER = DB.Prepare.Insert({"state", "resource", "identifier"})

---@param id string
---@param resource string|nil
---@param identifier string
---@return boolean
function EnsurePlayerState(id, resource, identifier)
    local data = DB_SELECT_USER.execute(id, resource, identifier)
    if not data then
        return DB_INSERT_USER.execute(id, resource, identifier) ~= 0
    end
    return true
end

local DB_UPDATE_USER = DB.Prepare.Update({"data"}, {"state", "resource", "identifier"})
local DB_UPDATE_ASYNC_USER = DB.Prepare.Update({"data"}, {"state", "resource", "identifier"}, false)

---@param id string
---@param resource string|nil
---@param identifier string
---@param data any
---@return boolean
function SetPlayerState(id, resource, identifier, data)
    return DB_UPDATE_USER.execute({json.encode(data)}, {id, resource, identifier})
end

---@param id string
---@param resource string|nil
---@param identifier string
---@return table|nil
function GetPlayerState(id, resource, identifier)
    local data = DB_SELECT_USER.execute(id, resource, identifier)
    if not data then return nil end
    return json.decode(data.data)
end

---@param id string
---@param resource string|nil
---@param identifier string
---@param data any
---@return boolean
function SetPlayerStateAsync(id, resource, identifier, data)
    return DB_UPDATE_ASYNC_USER.execute({json.encode(data)}, {id, resource, identifier})
end

exports("EnsurePlayerState", EnsurePlayerState)
exports("GetPlayerState", GetPlayerState)
exports("SetPlayerState", SetPlayerState)
exports("SetPlayerStateAsync", SetPlayerStateAsync)