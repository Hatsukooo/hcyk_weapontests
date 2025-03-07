local target = exports.ox_target

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

function startmain()
  if type(Config.Ped) == "table" then
    if Config.Ped.model ~= "" then
      RequestModel(Config.Ped.model)
      while not HasModelLoaded(Config.Ped.model) do
        Wait(100)
      end

      local ped = CreatePed(0, Config.Ped.model, Config.Ped.location, Config.Ped.heading, false, true)
      FreezeEntityPosition(ped, true)
      SetEntityInvincible(ped, true)
      SetBlockingOfNonTemporaryEvents(ped, true)
      TaskPlayAnim(ped, Config.Ped.animDict, Config.Ped.animName, 8.0, -8.0, -1, Config.Ped.animFlag, 0.0, false, false, false)
    end
  end

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
  end

  target:addSphereZone({
    coords = Config.TargetCoords,
    radius = 1.0,
    debug = true,
    drawSprite = true,
    options = {
      {
        label = "Test",
        icon = "fas fa-bomb",
        iconColor = "red",
        distance = 1.5,
        onSelect = function(data)
          DebugPrint("Selected")
        end
      }
    }
  })
end

CreateThread(function()
  startmain()
end)

--[[
Creates a new targetable sphere zone.

exports.ox_target:addSphereZone(parameters)

    parameters: table
        coords: vector3
        name?: string
            An optional name to refer to the zone instead of using the id.
        radius?: number
        debug?: boolean
        drawSprite?: boolean
            Draw a sprite at the centroid of the zone. Defaults to true.
        options: TargetOptions

Return:

    id: number


TargetOptions

All target actions are formated as an array containing objects with the following properties.
TargetOption

    label: string
    name?: string
        An identifier used when removing an option.
    icon?: string
        Name of a Font Awesome

    icon.

iconColor?: string
distance?: number

    The max distance to display the option.

bones?: string or string[]

    A bone name or array of bone names (see GetEntityBoneIndexByName).
    offset?: vector3
        Offset the targetable area of an entity, relative to the model dimensions.
    offsetAbsolute?: vector3
        Offset the targetable area of an entity, relative to the entity's world coords.
    offsetSize?: number
        The radius of the targetable area for an entity offset.
    groups?: string or string[] or table<string, number>
        A group, array of groups, or pairs of groups-grades required to show the option.
        Groups are framework dependent, and may refer to jobs, gangs, etc.
    items?: string or string[] or table<string, number>
        An item, array of items, or pairs of items-count required to show the option.
        Items are framework dependent.
    anyItem?: boolean
        Only require a single item from the items table to exist.
    canInteract?: function(entity, distance, coords, name, bone)
        Options will always display if this is undefined.
    menuName?: string
        The option is only displayed when a menu has been set with openMenu.
    openMenu?: string
        Sets the current menu name, displaying only options for the menuName.
    onSelect?: function(data)
    export?: string
    event?: string
    serverEvent?: string
    command?: string

Callback

This is the data returned to a registered callback or event for selected option.

A selected option will trigger a single action, in order of priority:

    onSelect
    export
    event
    server event
    command

    data: table
        entity: number
            The id of the entity hit by the shape test. If triggering a server event, this is the network id instead.
        coords: vector3
            The resulting coordinates where the shape test hit a collision.
        distance: number
            The player's distance from the coords.
        zone?: number
            The id of the selected zone, if applicable.
]]--