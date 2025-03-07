local function DebugPrint(...)
  if Config.Debug then
    print("[HCYK_WEAPONTESTS] - "...)
  end
end
if Config.Debug then
  print("[HCYK_WEAPONTESTS] - "...)
end

function Notif(msg, type, title, timeout)
  local title = title
  local timeout = timeout

  if Config.NotificationType == "esx" then
      ESX.ShowNotification(msg, true, true)
  elseif Config.NotificationType == "okok" then
      exports['okokNotify']:Alert(title, msg, 3000, type)
  elseif Config.NotificationType == "ox" then
      if type == "info" then
          lib.notify({
              title = title,
              description = msg,
              type = 'info',
              duration = timeout,
              position = Config.NotifyPosition,
          })
      else
          lib.notify({
              title = title,
              description = msg,
              type = type,
              duration = timeout,
              position = Config.NotifyPosition,
          })
      end
  end
end