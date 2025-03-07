local target = exports.ox_target

-- Debug function that only prints when Config.Debug is true
local function DebugPrint(...)
  if Config.Debug then
    print("[HCYK_WEAPONTESTS] - ", ...)
  end
end

-- Notification function that supports different notification systems
function Notif(msg, type, title, timeout)
  local title = title or "Weapon Test"
  local timeout = timeout or Config.Notification.timeout

  if Config.Notification.type == "esx" then
    ESX.ShowNotification(msg, true, true)
  elseif Config.Notification.type == "okok" then
    exports['okokNotify']:Alert(title, msg, timeout, type)
  elseif Config.Notification.type == "ox" then
    if type == "info" then
      lib.notify({
        title = title,
        description = msg,
        type = 'info',
        duration = timeout,
        position = Config.Notification.position,
      })
    else
      lib.notify({
        title = title,
        description = msg,
        type = type,
        duration = timeout,
        position = Config.Notification.position,
      })
    end
  end
end

-- Variables to track test status
local testActive = false
local testPassed = false
local currentTest = nil

-- Function to check if player has the weapon license
local function HasWeaponLicense()
  -- This would need to be implemented based on your licensing system
  -- For example with ESX:
  -- local xPlayer = ESX.GetPlayerData()
  -- return xPlayer.licenses and xPlayer.licenses["weapon"]
  
  -- Placeholder, replace with your actual implementation
  return false
end

-- Function to open the weapon test UI
local function OpenWeaponTest()
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = "setVisible",
    data = true
  })
  testActive = true
  DebugPrint("Weapon test UI opened")
end

-- Function to close the weapon test UI
local function CloseWeaponTest()
  SetNuiFocus(false, false)
  SendNUIMessage({
    action = "setVisible",
    data = false
  })
  testActive = false
  DebugPrint("Weapon test UI closed")
end

-- Function to get all questions from the questions.lua file
local function GetQuestions()
  local questions = require('questions')
  DebugPrint("Loaded " .. #questions .. " questions")
  return questions
end

-- Function to start the main system
function startmain()
  -- Create the instructor NPC if configured
  if type(Config.Ped) == "table" and Config.Ped.model ~= "" then
    RequestModel(Config.Ped.model)
    while not HasModelLoaded(Config.Ped.model) do
      Wait(100)
    end

    local ped = CreatePed(0, Config.Ped.model, Config.Ped.location, Config.Ped.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Add animation if configured
    if Config.Ped.animDict and Config.Ped.animName then
      RequestAnimDict(Config.Ped.animDict)
      while not HasAnimDictLoaded(Config.Ped.animDict) do
        Wait(100)
      end
      TaskPlayAnim(ped, Config.Ped.animDict, Config.Ped.animName, 8.0, -8.0, -1, Config.Ped.animFlag or 1, 0.0, false, false, false)
    end
    
    DebugPrint("Created instructor NPC")
  end

  -- Create the blip if configured
  if type(Config.Blip) == "table" then
    local blip = AddBlipForCoord(Config.Blip[1], Config.Blip[2], Config.Blip[3])
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, Config.Blip.short)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(blip)
    DebugPrint("Created map blip")
  end

  -- Create the target zone
  target:addSphereZone({
    coords = Config.TargetCoords,
    radius = 1.0,
    debug = Config.Debug,
    drawSprite = true,
    options = {
      {
        label = "Take Weapon License Test",
        icon = "fas fa-gun",
        iconColor = "red",
        distance = 1.5,
        onSelect = function(data)
          if HasWeaponLicense() then
            Notif("You already have a weapon license.", "error", "Weapon License", 3000)
            return
          end
          
          if testPassed then
            Notif("You've already passed the test. Go to the sheriff's office to collect your license.", "info", "Weapon License", 5000)
            return
          end
          
          OpenWeaponTest()
        end
      }
    }
  })
  
  DebugPrint("Created target zone at " .. tostring(Config.TargetCoords))
end

-- NUI Callbacks
RegisterNUICallback('getQuestions', function(data, cb)
  DebugPrint("NUI requested questions")
  local questions = GetQuestions()
  cb({questions = questions})
end)

RegisterNUICallback('submitTest', function(data, cb)
  DebugPrint("Test submitted with score: " .. tostring(data.score) .. ", Passed: " .. tostring(data.passed))
  
  testPassed = data.passed
  
  -- Handle test results
  if data.passed then
    Notif("Congratulations! You passed the weapon license test.", "success", "Test Passed", 5000)
    
    -- You might want to save this to the database or trigger a server event
    TriggerServerEvent('hcyk_weapontests:server:testPassed')
  else
    local wrongCount = #data.wrongAnswers
    Notif("You failed the test. You had " .. wrongCount .. " incorrect answers. Try again later.", "error", "Test Failed", 5000)
  end
  
  cb({})
end)

RegisterNUICallback('hideFrame', function(data, cb)
  CloseWeaponTest()
  cb({})
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    if testActive then
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      DisableControlAction(0, 24, true) 
      DisableControlAction(0, 25, true) 
      DisableControlAction(0, 257, true) 
      DisableControlAction(0, 263, true) 
      
      if IsDisabledControlJustReleased(0, 177) then
      end
    end
    if not testActive then
      Wait(1000)
    end
  end
end)

CreateThread(function()
  startmain()
end)
