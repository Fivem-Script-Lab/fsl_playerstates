fx_version 'cerulean'

game 'gta5'

lua54 'yes'

author 'Verbaz'

description 'Script designed for easy management of player statistics and other data'

server_scripts {
    '@es_extended/imports.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/player_identifier.lua'
}