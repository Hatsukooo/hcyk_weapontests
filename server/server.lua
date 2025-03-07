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
  
  -- Event handler for when a player passes the test
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
        
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Weapon license removed from " .. GetPlayerName(targetId), "success", "License Removed", 3000)
        
        TriggerClientEvent('hcyk_weapontests:client:notification', targetId, "Your weapon license has been revoked by an admin", "error", "License Revoked", 5000)
      else
        TriggerClientEvent('hcyk_weapontests:client:notification', src, "Player doesn't have a weapon license", "error", "Command Error", 3000)
      end
    end)
  end, false)
  
  -- Event for notification handling
  RegisterNetEvent('hcyk_weapontests:server:notification')
  AddEventHandler('hcyk_weapontests:server:notification', function(message, type, title, timeout)
    local src = source
    TriggerClientEvent('hcyk_weapontests:client:notification', src, message, type, title, timeout)
  end)