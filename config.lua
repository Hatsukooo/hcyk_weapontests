Config = {} -- Don't touch this

-- Debug Settings
Config.Debug = true -- Enable debug messages in server console
Config.Webhook = "YOUR_WEBHOOK_HERE" -- Discord webhook for logging test results and admin actions

-- Database settings
Config.UseDatabase = true -- Whether to store test results in database

-- Notification System
Config.Notification = {
    type = "ox", -- Select notification system: "esx", "okok", or "ox"
    position = "top", -- Position for ox notifications - https://overextended.dev/ox_lib/Modules/Interface/Client/notify
    timeout = 2000 -- Notification display time in milliseconds
}

-- NPC Instructor Settings
Config.Ped = {
    model = "a_m_y_business_01", -- Model for instructor NPC
    location = vector3(21.6585, -1107.6157, 28.7972), -- Position of instructor
    heading = 156.6843, -- Direction NPC faces
}

-- Location and Interaction
Config.TargetCoords = vec3(21.6585, -1107.6157, 29.7972) -- Target zone location

-- Test Settings
Config.TestSettings = {
    PassingScore = 75, -- Percentage needed to pass the test
    QuestionCount = 10, -- Number of questions to include in each test
    TimePerQuestion = 60, -- Seconds allowed for each question
    CooldownTime = 30, -- Cooldown time in minutes before another attempt
}

-- License Fee Settings
Config.LicenseFee = 500 -- Amount to charge for the license after passing the test, set to 0 for free

-- Map Blip Settings
Config.Blip = { -- Set to false to disable blip
    sprite = 134, -- Blip sprite (icon)
    color = 13, -- Blip color
    name = "Weapon Licensing", -- Blip label on map
    scale = 0.8, -- Blip size
    short = false, -- Whether to show on edge of minimap
}

-- Permission Settings
Config.AdminGroups = { -- Groups that can use admin commands
    ["admin"] = true,
    ["owner"] = true,
    ["developer"] = true
}