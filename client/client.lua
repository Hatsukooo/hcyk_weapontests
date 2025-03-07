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
    ESX.ShowNotification(msg, true, false, type)
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
local cooldownUntil = 0

local function OpenWeaponTest()
  -- Check for cooldown
  if cooldownUntil > 0 and GetGameTimer() < cooldownUntil then
    local remainingSeconds = math.ceil((cooldownUntil - GetGameTimer()) / 1000)
    local minutes = math.floor(remainingSeconds / 60)
    local seconds = remainingSeconds % 60
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    Notif("You must wait " .. timeString .. " before taking the test again.", "error", "Cooldown Active", 5000)
    return
  end
  
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

local function SetupInstructorNPC()
  if type(Config.Ped) == "table" and Config.Ped.model ~= "" then
    -- Check if model is a string or a hash
    local modelHash = type(Config.Ped.model) == "string" and GetHashKey(Config.Ped.model) or Config.Ped.model
    
    -- Request the model
    RequestModel(modelHash)
    local timeout = GetGameTimer() + 10000 -- 10 second timeout
    
    -- Wait for model to load with timeout
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeout do
      Wait(100)
    end
    
    if HasModelLoaded(modelHash) then
      local ped = CreatePed(0, modelHash, Config.Ped.location, Config.Ped.heading, false, true)
      FreezeEntityPosition(ped, true)
      SetEntityInvincible(ped, true)
      SetBlockingOfNonTemporaryEvents(ped, true)
      TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)
      SetEntityAsMissionEntity(ped, true, true)    
      
      DebugPrint("Created instructor NPC")
    else
      DebugPrint("Failed to load NPC model: " .. Config.Ped.model)
    end
  end
end

local function SetupMapBlip()
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
end

local function CheckWeaponLicense(cb)
  lib.callback('hcyk_weapontests:checkLicense', false, function(hasLicense)
    if cb then
      cb(hasLicense)
    end
  end, "weapon")
end

function startMain()
  SetupInstructorNPC()
  SetupMapBlip()
  exports.ox_target:addSphereZone({
    coords = Config.TargetCoords,
    radius = 1.5,
    debug = Config.Debug,
    drawSprite = true,
    options = {
      {
        label = "Take Weapon License Test (Cost: $" .. Config.LicenseFee .. ")",
        icon = "fas fa-gun",
        iconColor = "red",
        distance = 2.0,
        onSelect = function(data)
          CheckWeaponLicense(function(hasLicense)
            if hasLicense then
              Notif("You already have a weapon license.", "info", "License Check", 5000)
            else
              -- Check if player has enough money
              if Config.LicenseFee > 0 then
                lib.callback('hcyk_weapontests:checkMoney', false, function(hasMoney)
                  if hasMoney then
                    OpenWeaponTest()
                  else
                    Notif("You do not have enough money to take the test.", "error", "Insufficient Funds", 5000)
                  end
                end, Config.LicenseFee)
              else
                OpenWeaponTest()
              end
            end
          end)
        end
      }
    }
  })
  
  DebugPrint("Created target zone at " .. tostring(Config.TargetCoords))
end

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
  else
    local wrongCount = #data.wrongAnswers
    Notif("You failed the test. You had " .. wrongCount .. " incorrect answers. Try again later.", "error", "Test Failed", 5000)
    
    if Config.TestSettings.CooldownTime > 0 then
      cooldownUntil = GetGameTimer() + (Config.TestSettings.CooldownTime * 60 * 1000)
      DebugPrint("Setting cooldown until: " .. cooldownUntil)
    end
  end
  
  TriggerServerEvent('hcyk_weapontests:server:submitTest', data)
  
  cb({})
end)


RegisterNUICallback('hideFrame', function(data, cb)
  CloseWeaponTest()
  cb({})
end)

CreateThread(function()
  startMain()
  DebugPrint("Weapon test system started")
end)

RegisterNetEvent('hcyk_weapontests:client:notification')
AddEventHandler('hcyk_weapontests:client:notification', function(message, type, title, timeout)
  Notif(message, type, title, timeout)
end)

RegisterNetEvent('hcyk_weapontests:client:licenseGranted')
AddEventHandler('hcyk_weapontests:client:licenseGranted', function()
  Notif("You have been granted a weapon license.", "success", "License Granted", 5000)
end)

-- DEV: Command to force open the test UI (for development)
if Config.Debug then
  RegisterCommand('weapontest', function()
    OpenWeaponTest()
  end, false)
  
  RegisterCommand('checklicense', function()
    CheckWeaponLicense(function(hasLicense)
      local statusText = hasLicense and "You have a weapon license." or "You do not have a weapon license."
      Notif(statusText, "info", "License Status", 3000)
    end)
  end, false)
  
  -- Reset cooldown command (for testing)
  RegisterCommand('resetcooldown', function()
    cooldownUntil = 0
    Notif("Cooldown timer has been reset.", "success", "Debug Command", 3000)
  end, false)
end