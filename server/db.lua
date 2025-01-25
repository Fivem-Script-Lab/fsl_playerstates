local DB = exports.DatabaseManager:GetDatabaseTableManager("player_states")

DB.Create({
    {"id", "INT(11) UNSIGNED PRIMARY KEY AUTO_INCREMENT"},
    {"state", "VARCHAR(255) NOT NULL"},
    {"resource", "VARCHAR(255) NULL"},
    {"identifier", "VARCHAR(255) NOT NULL"},
    {"data", "LONGTEXT NULL DEFAULT '[]'"}
})

local DB_SELECT_USER = DB.Prepare.Select({"state", "resource", "identifier"})
local DB_INSERT_USER = DB.Prepare.Insert({"state", "resource", "identifier"})

function EnsurePlayerState(id, res, iden)
    local data = DB_SELECT_USER.execute(id, res, iden)
    if not data then
        return DB_INSERT_USER.execute(id, res, iden) ~= 0
    end
    return true
end

local DB_UPDATE_USER = DB.Prepare.Update({"data"}, {"state", "resource", "identifier"})
local DB_UPDATE_ASYNC_USER = DB.Prepare.Update({"data"}, {"state", "resource", "identifier"}, false)

function SetPlayerState(id, res, iden, data)
    return DB_UPDATE_USER.execute({json.encode(data)}, {id, res, iden})
end

function GetPlayerState(id, res, iden)
    local data = DB_SELECT_USER.execute(id, res, iden)
    if not data then return nil end
    return json.decode(data.data)
end

function SetPlayerStateAsync(id, res, iden, data)
    return DB_UPDATE_ASYNC_USER.execute({json.encode(data)}, {id, res, iden})
end