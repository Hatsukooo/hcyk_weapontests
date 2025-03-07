Config = {}
Config.Debug = true

Config.Notification = {
    type = "ox", -- select default notification | esx, okok, ox
    position = "top-right", -- ox only | https://overextended.dev/ox_lib/Modules/Interface/Client/notify
    timeout = 2000 -- notification timeout in ms
}

Config.Target = false --#IMPORTANT#-- IF YOU SET TO FALSE, IT USES hcyk_markers
Config.Ped = false    --#IMPORTANT#-- IF YOU SET Config.Target to FALSE, IT USES hcyk_markers and doesnt spawn the ped

--[[
Config.Ped = {
    model = "",
    location = vec4(),

}
]]--

Config.MaxWrong = 3 -- Maximum of wrong answears player can get