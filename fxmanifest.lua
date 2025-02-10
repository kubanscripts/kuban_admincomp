-- ██╗  ██╗██╗   ██╗██████╗  █████╗ ███╗   ██╗███████╗ ██████╗██████╗ ██╗██████╗ ████████╗███████╗
-- ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔════╝
-- █████╔╝ ██║   ██║██████╔╝███████║██╔██╗ ██║███████╗██║     ██████╔╝██║██████╔╝   ██║   ███████╗
-- ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║╚██╗██║╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ╚════██║
-- ██║  ██╗╚██████╔╝██████╔╝██║  ██║██║ ╚████║███████║╚██████╗██║  ██║██║██║        ██║   ███████║
-- ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ╚══════╝                                                                                            
-- https://discord.gg/UzVbtKEzgN 

fx_version 'cerulean'

game 'gta5'

lua54 'yes'

version '1.0.2'

author 'KubanScripts'

description 'Admin Compensation Resource using ox_lib'

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'cl_comp.lua'

server_scripts {
    'version.lua',
    'sv_comp.lua',
    '@oxmysql/lib/MySQL.lua'

}
escrow_ignore {
    'version.lua',
    'config.lua',
}
