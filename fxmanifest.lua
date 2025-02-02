fx_version 'cerulean'

game 'gta5'

lua54 'yes'

author 'Verbaz'

description 'Script designed for easy management of player statistics and other data'

shared_scripts {
    '@ox_lib/init.lua'
}


client_scripts {
    'client/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/main.lua'
}