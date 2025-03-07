Config = {}
Config.Debug = true

Config.Notification = {
    type = "ox", -- select default notification | esx, okok, ox
    position = "top", -- ox only | https://overextended.dev/ox_lib/Modules/Interface/Client/notify
    timeout = 2000 -- notification timeout in ms
}

Config.Ped = {
    model = "a_m_y_business_01",
    location = vector3(21.6585, -1107.6157, 29.7972),
    heading = 156.6843,
    animDict = "amb@code_human_in_backseat@female@base",
    animName = "base",
    animFlag = 1,
}

Config.TargetCoords = vec3(21.6585, -1107.6157, 29.7972)

Config.MaxWrong = 3 -- Maximum of wrong answears player can get
Config.Blip = false -- Table {} or false

--[[ blip is attached to TargetCoords
Config.Blip = {
    sprite = 134,
    color = 13,
    name = "Test",
    scale = 0.8,
    short = false,
    -- aditional settings in client 
    -- https://docs.fivem.net/docs/game-references/blips/
}
]]--

Config.TestSettings = {
    PassingScore = 75, -- Percentage needed to pass the test
    QuestionCount = 10, -- Number of questions to include in each test
    TimePerQuestion = 60, -- Seconds allowed for each question
}

Config.LicenseFee = 500 -- Amount to charge for the license after passing the test, set to 0 for free