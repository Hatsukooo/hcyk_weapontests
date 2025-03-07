local target = exports.ox_target
local ESX = exports['es_extended']:getSharedObject()
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

local testActive = false
local testPassed = false

local function OpenWeaponTest()
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = "setVisible",
    data = true
  })
  testActive = true
  DebugPrint("Weapon test UI opened")
end

local function CloseWeaponTest()
  SetNuiFocus(false, false)
  SendNUIMessage({
    action = "setVisible",
    data = false
  })
  testActive = false
  DebugPrint("Weapon test UI closed")
end

local function GetQuestions()
  local questions = require('questions')
  DebugPrint("Loaded " .. #questions .. " questions")
  return questions
end

function startmain()
  if type(Config.Ped) == "table" and Config.Ped.model ~= "" then
    RequestModel(Config.Ped.model)
    while not HasModelLoaded(Config.Ped.model) do
      Wait(100)
    end

    local ped = CreatePed(0, Config.Ped.model, Config.Ped.location, Config.Ped.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetEntityAsMissionEntity(ped, true, true)    
    
    DebugPrint("Created instructor NPC")
  end

  if type(Config.Blip) == "table" then
    local blip = AddBlipForCoord(Config.TargetCoords)
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

  target:addSphereZone({
    coords = Config.TargetCoords,
    radius = 1.0,
    debug = Config.Debug,
    drawSprite = true,
    options = {
      {
        label = "Take Weapon License Test (Cost: $" .. Config.LicenseFee .. ")",
        icon = "fas fa-gun",
        iconColor = "red",
        distance = 1.5,
        onSelect = function(data)
          lib.callback.await('hcyk_weapontests:checkLicense', function(hasLicense)
              if hasLicense then
                Notif("You already have a weapon license.", "info", "License Check", 5000)
              else
                OpenWeaponTest()
              end
            end, "weapon")
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
  
  if data.passed then
    Notif("Congratulations! You passed the weapon license test.", "success", "Test Passed", 5000)
    
    ESX.TriggerServerCallback('esx_license:addLicense', function()
      Notif("You have been granted a weapon license.", "success", "License Granted", 5000)
    end, "weapon")
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

CreateThread(function()
  startmain()
  DebugPrint("Weapon test system started")
end)

RegisterNetEvent('hcyk_weapontests:client:notification')
AddEventHandler('hcyk_weapontests:client:notification', function(message, type, title, timeout)
  Notif(message, type, title, timeout)
end)

-- DEV: Command to force open the test UI (for development)
if Config.Debug then
  RegisterCommand('weapontest', function()
    OpenWeaponTest()
  end, false)
  
  RegisterCommand('checklicense', function()
    CheckWeaponLicense()
    Wait(500) -- Give time for the callback
    local statusText = hasLicense and "You have a weapon license." or "You do not have a weapon license."
    Notif(statusText, "info", "License Status", 3000)
  end, false)
end