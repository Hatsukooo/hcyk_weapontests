fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Hatcyk'
description 'hcyk_weapontests'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua',
    'questions.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/serrver.lua',
}

files {
    'web/build/index.html',
    'web/build/**/*'
}

ui_page 'web/build/index.html'

dependencies {
    'ox_lib',
}