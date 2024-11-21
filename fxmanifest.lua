fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Fuel System with Refueling Zones'
version '1.0.0'

client_scripts {
    'client.lua',
    'config.lua',  -- Подключаем конфиг файл
}

server_scripts {
    'server.lua', -- Здесь будет серверная логика, например, синхронизация топлива
}


