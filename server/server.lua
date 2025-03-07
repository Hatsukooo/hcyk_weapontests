-- Debug print function
local function DebugPrint(...)
    if Config.Debug then
      print("[HCYK_WEAPONTESTS] - ", ...)
    end
  end
  
  -- Initialize the database if needed
  CreateThread(function()
    if Config.UseDatabase then
      DebugPrint("Checking database setup")
      MySQL.ready(function()
        MySQL.query([[
          CREATE TABLE IF NOT EXISTS `weapon_test_results` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(60) NOT NULL,
            `passed` tinyint(1) NOT NULL DEFAULT 0,
            `score` int(11) NOT NULL,
            `date` timestamp NOT NULL DEFAULT current_timestamp(),
            PRIMARY KEY (`id`)
          );
        ]], {}, function(rowsChanged)
          DebugPrint("Database initialized")
        end)
      end)
    end
  end)
  
  -- Function to send data to webhook
  local function SendWebhook(title, message, color, fields)
    local embed = {
      {
        ["title"] = title,
        ["description"] = message,
        ["type"] = "rich",
        ["color"] = color,
        ["fields"] = fields or {},
        ["footer"] = {
          ["text"] = "HCYK Weapon Test System • " .. os.date("%Y-%m-%d %H:%M:%S"),
        },
      }
    }
    
    -- Don't attempt to send if webhook is not configured
    if Config.Webhook == "YOUR_WEBHOOK_HERE" then
      DebugPrint("Webhook not configured - skipping log")
      return
    end
    
    PerformHttpRequest(Config.Webhook, function(err, text, headers) 
      if err ~= 201 then
        DebugPrint("Webhook send error: " .. tostring(err))
      end
    end, 'POST', json.encode({embeds = embed}), { ['Content-Type'] = 'application/json' })
  end
  
  -- Check if a player has a weapon license
  local function CheckPlayerLicense(playerId, cb)
    TriggerEvent('esx_license:checkLicense', playerId, 'weapon', function(hasLicense)
      cb(hasLicense)
    end)
  end
  
  -- Grant a weapon license to a player
  local function GrantWeaponLicense(playerId, cb)
    TriggerEvent('esx_license:addLicense', playerId, 'weapon', function(success)
      if cb then
        cb(success)
      end
    end)
  end
  
  -- Callback for client to check if player has license
  lib.callback.register('hcyk_weapontests:checkLicense', function(source, licenseType)
    local src = source
    local hasLicense = false
    
    CheckPlayerLicense(src, function(result)
      hasLicense = result
    end)
    
    -- Wait a moment for the async operation to complete
    Wait(100)
    return hasLicense
  end)
  
  -- Event handler for when a player submits a test
  RegisterNUICallback('submitTest', function(data, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local passed = data.passed
    local score = data.score
    local wrongAnswers = data.wrongAnswers or {}
    
    if not xPlayer then
      DebugPrint("Error: Player not found: " .. src)
      cb({})
      return
    end
    
    -- Send webhook with test details
    local webhookColor = passed and 65280 or 16711680 -- Green if passed, red if failed
    local webhookTitle = passed and "Weapon License Test Passed" or "Weapon License Test Failed"
    local playerName = GetPlayerName(src)
    local identifier = xPlayer.getIdentifier()
    
    -- Create fields for webhook
    local fields = {
      {
        ["name"] = "Player",
        ["value"] = playerName .. " (ID: " .. src .. ")",
        ["inline"] = true
      },
      {
        ["name"] = "Score",
        ["value"] = math.floor(score) .. "% (Passing: " .. Config.TestSettings.PassingScore .. "%)",
        ["inline"] = true
      },
      {
        ["name"] = "Identifier",
        ["value"] = identifier,
        ["inline"] = false
      }
    }
    
    -- Add wrong answers to webhook if applicable
    if #wrongAnswers > 0 then
      local wrongAnswersText = "Wrong Answers:\n"
      for i, answer in ipairs(wrongAnswers) do
        if i <= 5 then -- Limit to 5 wrong answers to avoid webhook limits
          wrongAnswersText = wrongAnswersText .. "• Question: " .. answer.question .. "\n"
        end
      end
      
      if #wrongAnswers > 5 then
        wrongAnswersText = wrongAnswersText .. "... and " .. (#wrongAnswers - 5) .. " more."
      end
      
      table.insert(fields, {
        ["name"] = "Mistakes",
        ["value"] = wrongAnswersText,
        ["inline"] = false
      })
    end
    
    SendWebhook(webhookTitle, "Player has " .. (passed and "passed" or "failed") .. " the weapon license test.", webhookColor, fields)
    
    if passed then
      -- Process license fee
      if Config.LicenseFee and Config.LicenseFee > 0 then
        local playerMoney = xPlayer.getMoney()
        if playerMoney < Config.LicenseFee then
          TriggerClientEvent('hcyk_weapontests:client:notification', src, "You don't have enough money to pay the license fee ($" .. Config.LicenseFee .. ").", "error", "Weapon License", 3000)
          cb({})
          return
        end
        
        -- Remove the fee
        xPlayer.removeMoney(Config.LicenseFee)
        DebugPrint("Charged license fee: $" .. Config.LicenseFee .. " to: " .. GetPlayerName(src))
      end
      
      -- Grant the license
      GrantWeaponLicense(src, function(success)
        if success then
          DebugPrint("Granted weapon license to: " .. GetPlayerName(src))
          
          -- Save to database if enabled
          if Config.UseDatabase then
            local identifier = xPlayer.getIdentifier()
            
            MySQL.insert('INSERT INTO weapon_test_results (identifier, passed, score) VALUES (?, ?, ?)', {
              identifier,
              1,
              score or 100
            }, function(rowsChanged)
              DebugPrint("Saved test result to database for: " .. GetPlayerName(src))
            end)
          end
          
          -- Notify the player
          TriggerClientEvent('hcyk_weapontests:client:notification', src, "You have been granted a weapon license.", "success", "License Granted", 5000)
        else
          DebugPrint("Failed to grant weapon license to: " .. GetPlayerName(src))
          TriggerClientEvent('hcyk_weapontests:client:notification', src, "There was an error granting your license. Please contact an administrator.", "error", "Weapon License", 5000)
        end
      end)
    else
      -- Log failed test attempt
      if Config.UseDatabase then
        local identifier = xPlayer.getIdentifier()
        MySQL.insert('INSERT INTO weapon_test_results (identifier, passed, score) VALUES (?, ?, ?)', {
          identifier,
          0,
          score or 0
        }, function()
          DebugPrint("Saved failed test result to database for: " .. GetPlayerName(src))
        end)
      end
      
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "You have failed the weapon license test. You can try again later.", "error", "Test Failed", 5000)
    end
    
    cb({})
  end)
  
  -- Event to handle test passed
  RegisterNetEvent('hcyk_weapontests:server:testPassed')
  AddEventHandler('hcyk_weapontests:server:testPassed', function(score)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then
      DebugPrint("Error: Player not found: " .. src)
      return
    end
    
    -- Check if the player already has a license
    CheckPlayerLicense(src, function(hasLicense)
      if hasLicense then
        -- They already have a license, this shouldn't happen but handle it anyway
        DebugPrint("Player already has a weapon license: " .. GetPlayerName(src))
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "You already have a weapon license.", "error", "Weapon License", 3000)
        return
      end
      
      -- Check if the player can afford the license fee (if configured)
      if Config.LicenseFee and Config.LicenseFee > 0 then
        local playerMoney = xPlayer.getMoney()
        if playerMoney < Config.LicenseFee then
          TriggerClientEvent('hcyk_weapontests:client:notification', src, "You don't have enough money to pay the license fee ($" .. Config.LicenseFee .. ").", "error", "Weapon License", 3000)
          return
        end
        
        -- Remove the fee
        xPlayer.removeMoney(Config.LicenseFee)
        DebugPrint("Charged license fee: $" .. Config.LicenseFee .. " to: " .. GetPlayerName(src))
      end
      
      -- Grant the license
      GrantWeaponLicense(src, function(success)
        if success then
          DebugPrint("Granted weapon license to: " .. GetPlayerName(src))
          
          -- Save to database if enabled
          if Config.UseDatabase then
            local identifier = xPlayer.getIdentifier()
            
            MySQL.insert('INSERT INTO weapon_test_results (identifier, passed, score) VALUES (?, ?, ?)', {
              identifier,
              1,
              score or 100
            }, function(rowsChanged)
              DebugPrint("Saved test result to database for: " .. GetPlayerName(src))
            end)
          end
          
          -- Send webhook notification
          local webhookColor = 65280 -- Green
          local fields = {
            {
              ["name"] = "Player",
              ["value"] = GetPlayerName(src) .. " (ID: " .. src .. ")",
              ["inline"] = true
            },
            {
              ["name"] = "Score",
              ["value"] = math.floor(score) .. "%",
              ["inline"] = true
            },
            {
              ["name"] = "Identifier",
              ["value"] = xPlayer.getIdentifier(),
              ["inline"] = false
            }
          }
          
          SendWebhook("Weapon License Granted", "Player has passed the test and was granted a weapon license.", webhookColor, fields)
          
          -- Notify the player
          TriggerClientEvent('hcyk_weapontests:client:licenseGranted', src)
        else
          DebugPrint("Failed to grant weapon license to: " .. GetPlayerName(src))
          TriggerClientEvent('hcyk_weapontests:client:notification', src, "There was an error granting your license. Please contact an administrator.", "error", "Weapon License", 5000)
        end
      end)
    end)
  end)
  
  -- Command to check a player's license status
  RegisterCommand('checklicense', function(source, args, rawCommand)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    CheckPlayerLicense(src, function(hasLicense)
      local status = hasLicense and "You have a weapon license." or "You do not have a weapon license."
      TriggerClientEvent('hcyk_weapontests:client:notification', src, status, "info", "License Status", 3000)
    end)
  end, false)
  
  -- Command to reset a player's license status (admin only)
  RegisterCommand('resetlicense', function(source, args, rawCommand)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    -- Check if the player is an admin
    if xPlayer.getGroup() ~= 'admin' then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "You don't have permission to use this command.", "error", "Command Error", 3000)
      return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "Usage: /resetlicense [playerID]", "error", "Command Error", 3000)
      return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "Player not found", "error", "Command Error", 3000)
      return
    end
    
    -- Remove the license
    TriggerEvent('esx_license:removeLicense', targetId, 'weapon', function(rowsChanged)
      if rowsChanged > 0 then
        DebugPrint("Admin removed weapon license from: " .. GetPlayerName(targetId))
        
        -- Send webhook log
        local webhookColor = 16776960 -- Yellow
        local fields = {
          {
            ["name"] = "Admin",
            ["value"] = GetPlayerName(src) .. " (ID: " .. src .. ")",
            ["inline"] = true
          },
          {
            ["name"] = "Target",
            ["value"] = GetPlayerName(targetId) .. " (ID: " .. targetId .. ")",
            ["inline"] = true
          },
          {
            ["name"] = "Target Identifier",
            ["value"] = targetPlayer.getIdentifier(),
            ["inline"] = false
          }
        }
        
        SendWebhook("Weapon License Removed", "Admin has forcibly removed a player's weapon license.", webhookColor, fields)
        
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Weapon license removed from " .. GetPlayerName(targetId), "success", "License Removed", 3000)
        
        TriggerClientEvent('hcyk_weapontests:client:notification', targetId, "Your weapon license has been revoked by an admin", "error", "License Revoked", 5000)
      else
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Player doesn't have a weapon license", "error", "Command Error", 3000)
      end
    end)
  end, false)
  
  -- Admin command to force grant a license
  RegisterCommand('grantlicense', function(source, args, rawCommand)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "You don't have permission to use this command.", "error", "Command Error", 3000)
      return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "Usage: /grantlicense [playerID]", "error", "Command Error", 3000)
      return
    end
    
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    if not targetPlayer then
      TriggerClientEvent('hcyk_weapontests:client:notification', src, "Player not found", "error", "Command Error", 3000)
      return
    end
    
    -- Grant the license
    GrantWeaponLicense(targetId, function(success)
      if success then
        DebugPrint("Admin granted weapon license to: " .. GetPlayerName(targetId))
        
        -- Send webhook log
        local webhookColor = 65280 -- Green
        local fields = {
          {
            ["name"] = "Admin",
            ["value"] = GetPlayerName(src) .. " (ID: " .. src .. ")",
            ["inline"] = true
          },
          {
            ["name"] = "Target",
            ["value"] = GetPlayerName(targetId) .. " (ID: " .. targetId .. ")",
            ["inline"] = true
          },
          {
            ["name"] = "Target Identifier",
            ["value"] = targetPlayer.getIdentifier(),
            ["inline"] = false
          }
        }
        
        SendWebhook("Weapon License Granted by Admin", "Admin has manually granted a weapon license to player.", webhookColor, fields)
        
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Successfully granted weapon license to " .. GetPlayerName(targetId), "success", "License Granted", 3000)
        
        TriggerClientEvent('hcyk_weapontests:client:notification', targetId, "You have been granted a weapon license by an administrator", "success", "License Granted", 5000)
      else
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Failed to grant weapon license", "error", "Command Error", 3000)
      end
    end)
  end, false)
  
  -- Event for notification handling
  RegisterNetEvent('hcyk_weapontests:server:notification')
  AddEventHandler('hcyk_weapontests:server:notification', function(message, type, title, timeout)
    local src = source
    TriggerClientEvent('hcyk_weapontests:client:notification', src, message, type, title, timeout)
  end)