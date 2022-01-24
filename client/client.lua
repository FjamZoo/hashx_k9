local QBCore = exports['qb-core']:GetCoreObject()
---- ** Locales ** ----
local activate_k9 = false
local k9_name = Lang:t("info.k9_name")
local k9_id = false
local searching = false
local following = true

local sit = {
    dict = "creatures@rottweiler@amb@world_dog_sitting@idle_a",
    anim = "idle_b"
}
local laydown = {
    dict = "creatures@rottweiler@amb@sleep_in_kennel@",
    anim = "sleep_in_kennel"
}
local searchhit = {
    dict = "creatures@rottweiler@indication@",
    anim = "indicate_high"
}


---- ** Functions ** ----
---- ** Sit and Lay animations ** ----
local function PlayAnimation(dict, anim)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
      Wait(0)
  end
  local DOG = NetworkGetEntityFromNetworkId(k9_id)
  following = false
  TaskPlayAnim(DOG, dict, anim, 8.0, -8.0, -1, 2, 0.0, 0, 0, 0)
end

local function K9AttackorFollow(target)
  local DOG = NetworkGetEntityFromNetworkId(k9_id)
  if target then
    SetCanAttackFriendly(DOG, true, true);
    TaskPutPedDirectlyIntoMelee(DOG, target, 0.0, -1.0, 0.0, false);
    following = false
    QBCore.Functions.Notify(k9_name.." is attacking!", "error", 2000)
  else
    TaskFollowToOffsetOfEntity(DOG, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true);
    following = true
    QBCore.Functions.Notify(k9_name.." is following.", "primary", 2000)
  end
end

-- Spawns and Deletes K9
local function DespawnK9()
  if k9_id then
      local DOG = NetworkGetEntityFromNetworkId(k9_id)
      if DoesEntityExist(DOG) then
        DeleteEntity(DOG)
      end
  end
  following = true
  k9_id = false
  searching = false
end

local function CheckK9Conditions()  
  if k9_id then
    local DOG = NetworkGetEntityFromNetworkId(k9_id)
    local DOG_COORDS = GetEntityCoords(DOG)
    local PLAYER_COORDS = GetEntityCoords(PlayerPedId())
    local DISTANCE = #(DOG_COORDS - PLAYER_COORDS)
    if DISTANCE > 100 and not IsPedInAnyVehicle(DOG, false) then
      K9AttackorFollow(false)
    end
    if IsEntityDead(DOG) or IsEntityDead(PlayerPedId()) then
      DespawnK9()
    end
  end
end

local function EnableK9(bool)
  SetPedRelationshipGroupHash(PlayerPedId(), GetHashKey("PLAYER_POLICE"))
  if bool then
    activate_k9 = true
    while activate_k9 do
        Wait(15000)
        CheckK9Conditions()
    end
  end
end


--Animation set if we found something.
local function K9Found(status, type)
  local time = math.random(500,1500)
  if(type == 'vehicle') then
    time = math.random(1500,3500)
  end
  Wait(time)
  if status then
    QBCore.Functions.Notify(Lang:t("success.k9_alert"), "success", 4000)
    searching = false
    PlayAnimation(searchhit.dict, searchhit.anim)
    Wait(2500)
    PlayAnimation(sit.dict, sit.anim)
    following = false
  else
    QBCore.Functions.Notify(Lang:t("error.k9_alert"), "error", 4000)
    following = true
  end
end

-- Gets Closest Door To Player
local function GetClosestVehicleDoor(vehicle)
  local PLAYER = GetEntityCoords(PlayerPedId(), false)
  local BACKLEFT = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "door_dside_r"))
  local BACKRIGHT = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "door_pside_r"))
  local BLDISTANCE = #(PLAYER - BACKLEFT)
  local BRDISTANCE = #(PLAYER - BACKRIGHT)

  local FOUND_DOOR = false

  if BLDISTANCE < BRDISTANCE then
      FOUND_DOOR = 2
  else
      FOUND_DOOR = 3
  end

  return FOUND_DOOR
end

local function K9ToggleVehicle(target)
  searching = false
  local DOG = NetworkGetEntityFromNetworkId(k9_id)
  local VEHICLE = QBCore.Functions.GetClosestVehicle()
  local DOOR = GetClosestVehicleDoor(VEHICLE)
  local PLAYER_COORDS = GetEntityCoords(PlayerPedId())
  local VEHICLE_COORDS = GetEntityCoords(VEHICLE)
  local DOG_COORDS = GetEntityCoords(DOG)
  local SEAT = 0

  if #(VEHICLE_COORDS - DOG_COORDS) < 5 or target then
    if DOOR == 3 then
      SEAT = "seat_pside_r"
    else
      SEAT = "seat_dside_r"
    end
    if IsEntityAttached(DOG) then
        following = false
        SetEntityInvincible(DOG, true)
        SetPedCanRagdoll(DOG, false)
        --Get Vehicle Coords, Open Rear Passenger Door, Spawn Dog
        local DOOR_COORDS = GetEntryPositionOfDoor(VEHICLE, DOOR);
        local  bool, gZero = GetGroundZFor_3dCoord(DOOR_COORDS.x, DOOR_COORDS.y, PLAYER_COORDS.z+5, false);

        SetVehicleDoorOpen(VEHICLE, DOOR, false, false);
        Wait(500)
        AttachEntityToEntity(DOG, VEHICLE, GetEntityBoneIndexByName(VEHICLE, SEAT), 0.0, -0.25, 0.40, 0.0, 0.0, 0, false, false, false, true, 20, true)
        Wait(500)
        DetachEntity(DOG, false, false)  
        SetEntityCoords(DOG, DOOR_COORDS.x, DOOR_COORDS.y, gZero, false, false, false, false)
        ClearPedTasks(DOG)
        Wait(1500)
        K9AttackorFollow(target)
        SetPedCanRagdoll(DOG, true)
        SetEntityInvincible(DOG, false)
        SetVehicleDoorShut(VEHICLE, DOOR, false)

    else
      following = true
      SetVehicleDoorOpen(VEHICLE, DOOR, false, false)
      Wait(1500)
      AttachEntityToEntity(DOG, VEHICLE, GetEntityBoneIndexByName(VEHICLE, SEAT), 0.0, -0.25, 0.40, 0.0, 0.0, 0, false, false, false, true, 20, true)
      PlayAnimation(sit.dict, sit.anim)
      SetVehicleDoorShut(VEHICLE, DOOR, false)

    end
  else
    QBCore.Functions.Notify(k9_name..Lang:t("error.k9_toofar"), "error", 4000)
  end
end

-- Gets Players
local function GetPlayers()
  local players = {}
  for i = 0, 256 do
      if NetworkIsPlayerActive(i) then
          table.insert(players, i)
      end
  end
  return players
end

local function K9SearchPerson()
    following = false
    local TARGET = GetPlayerSourceAheadOfPlayer()

    if TARGET > 0 then
      TriggerServerEvent("K9:SERVER:SEARCH_PERSON", TARGET)
    else
      QBCore.Functions.Notify(k9_name..Lang:t("error.k9_locaterror"), "error", 4500)
    end
    
end

-- Gets Player ID
function GetPlayerId(target_ped)
  local players = GetPlayers()
  for a = 1, #players do

      local ped = GetPlayerPed(players[a])
      local server_id = GetPlayerServerId(players[a])
      if target_ped == ped then
          return server_id
      end
  end
  return 0
end

local function K9SearchVehicle()
  following = false
  local VEHICLE = QBCore.Functions.GetClosestVehicle()
  local PLATE = GetVehicleNumberPlateText(VEHICLE)
  local DOG = NetworkGetEntityFromNetworkId(k9_id)

  if VEHICLE then
    QBCore.Functions.Notify(k9_name..Lang:t("info.k9_searching"), "success", 4500)

    local PLAYERS = {}
    local MAX_SEATS = GetVehicleMaxNumberOfPassengers(VEHICLE) -2

    for i = -1, MAX_SEATS do

      local TARGET = GetPedInVehicleSeat(VEHICLE, i)
      
      if TARGET ~= nil then
          local SERVER_ID = GetPlayerId(TARGET)

          if SERVER_ID > 0 then
            table.insert(PLAYERS, SERVER_ID)
          end
      end

    end
    
    TriggerServerEvent("K9:SERVER:SEARCH_VEHICLE", PLATE, PLAYERS)
    
    searching = true

    if searching then
    local offset_1 = GetOffsetFromEntityInWorldCoords(VEHICLE, 2.0, -2.0, 0.0)
    TaskGoToCoordAnyMeans(DOG, offset_1.x, offset_1.y, offset_1.z, 5.0, 0, false, 1, 10.0)
    Wait(2500)
    end

    if searching then
    local offset_2 = GetOffsetFromEntityInWorldCoords(VEHICLE, 2.0, 2.0, 0.0)
    TaskGoToCoordAnyMeans(DOG, offset_2.x, offset_2.y, offset_2.z, 5.0, 0, false, 1, 10.0)
    Wait(2500)
    end

    if searching then
    local offset_3 = GetOffsetFromEntityInWorldCoords(VEHICLE, -2.0, 2.0, 0.0)
    TaskGoToCoordAnyMeans(DOG, offset_3.x, offset_3.y, offset_3.z, 5.0, 0, false, 1, 10.0)
    Wait(2500)
    end

    if searching then
    local offset_4 = GetOffsetFromEntityInWorldCoords(VEHICLE, -2.0, -2.0, 0.0)
    TaskGoToCoordAnyMeans(DOG, offset_4.x, offset_4.y, offset_4.z, 5.0, 0, false, 1, 10.0)
    Wait(2500)
    end

    searching = false
  else
      QBCore.Functions.Notify(Lang:t("error.k9_vehlocate"), "error", 4000)
  end
end

-- Gets Player ID
local function GetPlayersInRadius(min, max)
  local players = GetPlayers()
  local IN_RANGE = {}
  for a = 1, #players do
      
    local PED = GetPlayerPed(players[a])
    local PED_COORDS = GetEntityCoords(PED)
    local PLAYER_COORDS = GetEntityCoords(PlayerPedId())
    local DISTANCE = #(PED_COORDS - PLAYER_COORDS)

    if DISTANCE <= max and DISTANCE >= min then
      table.insert(IN_RANGE, PED)
    end  

  end
  return IN_RANGE
end

local function K9SearchArea()
  local PLAYERS = GetPlayersInRadius(20,75)

  for i = 1, #PLAYERS do
    following = false
    QBCore.Functions.Notify(k9_name..Lang:t("info.k9_scent"), "primary", 4000)
    local DOG = NetworkGetEntityFromNetworkId(k9_id)
    local DOG_COORDS = GetEntityCoords(DOG)
    local COORDS = GetEntityCoords(PLAYERS[i])
    TaskGoToCoordAnyMeans(DOG, COORDS.x, COORDS.y, COORDS.z, 5.0, 0, false, 1, 10.0)

    while #(DOG_COORDS - COORDS) > 2 do
      Wait(1000)
      DOG_COORDS = GetEntityCoords(DOG)
      if following then
        break
      end
    end

    if following then
      QBCore.Functions.Notify(k9_name..Lang:t("info.k9_nofollow"), "primary", 4000)
      break
    end
    QBCore.Functions.Notify(k9_name..Lang:t("info.k9_lostscent"), "primary", 4000)
    K9AttackorFollow(false)
    Wait(2000)
  end

end

-- Gets Control Of Ped
local function RequestNetworkControl()
    NetworkRequestControlOfNetworkId(k9_id)
    while not NetworkHasControlOfNetworkId(k9_id) do
        Wait(500)
        NetworkRequestControlOfNetworkId(k9_id)
    end
end

function GetPlayerSourceAheadOfPlayer()
    local PLAYER = PlayerPedId()
    local COORDS = GetEntityCoords(PLAYER)
    local OFFSET = GetOffsetFromEntityInWorldCoords(PLAYER, 0.0, 2.0, 0.0)
    local RAY = StartShapeTestCapsule(COORDS.x, COORDS.y, COORDS.z, OFFSET.x, OFFSET.y, OFFSET.z, 0.5, 12, PLAYER, 7)
    local RETURN, HIT, ENDCOORDS, SURFACE, PED = GetShapeTestResult(RAY)

    if HIT then
        return GetPlayerId(PED)
    else
        return false
    end

end


---- ** Job Handlers ** ----

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
  local player = QBCore.Functions.GetPlayerData()
  PlayerJob = player.job

  if PlayerJob or PlayerJob.name == "police" then
    EnableK9()
  end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
  DespawnK9()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
  PlayerJob = JobInfo
  if JobInfo.name == "police" then
    EnableK9()
  end
end)

---- ** Create Threads ** ----
CreateThread(function()
  exports['qb-target']:AddBoxZone("1234", vector3(458.95, -1016.99, 28.17), 1.5, 1.6, {
    name = "1234", 
    heading = 102.0, 
    debugPoly = false, 
    minZ = 25.7, 
    maxZ = 30.9, 
  }, {
    options = { 
      {
        type = "client",
        event = "qb-k9:client:menu", 
        icon = 'fas fa-dog', 
        label = Lang:t("info.k9_lostscent"), 
        job = Config.Autorhized, 
      }
    },
    distance = 2.5,
  })
end)

---- ** Register NetEvents ** ----

RegisterNetEvent('qb-k9:client:menu', function()
  local K9Purchase = {
    {
        header = Lang:t("menu.purchase_header"),
        isMenuHeader = true
    },
    {
      header = Lang:t("menu.k9_takeout"),
      txt = Lang:t("menu.takeout_txt"),
      params = {
        event = 'qb-k9:client:PurchaseDog',
      }
    },
    {
      header = Lang:t("menu.k9_return"),
      txt = Lang:t("menu.return_txt"),
      params = {
        event = 'qb-k9:client:ReturnDoggo',
      }
    },
  }

  exports['qb-menu']:openMenu(K9Purchase)
end)

RegisterNetEvent('qb-k9:client:ReturnDoggo', function() 
  if k9_id then
    DespawnK9()
    QBCore.Functions.Notify(Lang:t("info.k9_return"), "success", 4500)
  else
    QBCore.Functions.Notify(Lang:t("error.k9_returnerror"), "error", 4500)
  end
end)


RegisterNetEvent('qb-k9:client:PurchaseDog', function()
  if k9_id then
    DespawnK9()
  end

  local K9Dawgs = {}
  for k,v in pairs(Config.DogModelProps) do
    K9Dawgs[#K9Dawgs + 1] = {
        header = Config.DogModelProps[k]["Header"],
        txt = Config.DogModelProps[k]["Text"],
        params = {
            event = 'qb-k9:client:SpawnHandler',
            args = {
                model = Config.DogModelProps[k]["Dog"],
                colour = Config.DogModelProps[k]["Colour"],
                vest = Config.DogModelProps[k]["Vest"],
            }
        }
    }
end
exports['qb-menu']:openMenu(K9Dawgs)
end)

RegisterNetEvent('qb-k9:client:SpawnHandler', function(data) 
  TriggerServerEvent("K9:SERVER:SPAWN_K9", data.model, data.colour, data.vest)
end)

--- SPAWN EVENT
RegisterNetEvent('K9:CLIENT:SPAWN_K9', function(DawgHash, colour, vest)
  local pos = GetEntityCoords(PlayerPedId())
  local heading = GetEntityHeading(PlayerPedId())
  RequestModel(DawgHash);

  while not HasModelLoaded(DawgHash) do
    Wait(1)
    RequestModel(DawgHash);
  end

  local DOG = CreatePed(28, DawgHash, pos.x, pos.y, pos.z, heading, true, true)

  --SET NET ID FOR DOG
  k9_id = NetworkGetNetworkIdFromEntity(DOG)
  --REQEUST CONTROL
  RequestNetworkControl()
  --GET ENTITY
  local DOG = NetworkGetEntityFromNetworkId(k9_id)
  --set K9 Properties
  SetPedComponentVariation(DOG, 0, 0, colour, 0)
  SetPedComponentVariation(DOG, vest, 0, 1, 0)
  SetBlockingOfNonTemporaryEvents(DOG, true)
  SetPedFleeAttributes(DOG, 0, false)
  SetPedRelationshipGroupHash(DOG, GetHashKey("PLAYER_POLICE"))
  SetPedArmour(DOG, 25)
  SetEntityHeading(DOG, 90)

  ---- ** BLIPS ** ----
  local BLIP = AddBlipForEntity(DOG)
  SetBlipAsFriendly(BLIP, true)
  SetBlipSprite(BLIP, 442)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(k9_name)
  EndTextCommandSetBlipName(BLIP)
  K9AttackorFollow(false)

  ---- ** Enable K9 ** ----
  EnableK9(true)
end)


RegisterNetEvent('k9:client:search_results', function(status, type)
  if status then
    K9Found(status, type)
  end
end)


---- ** Register Commands ** ----

RegisterKeyMapping('caninecommanders', 'K9 COMMANDS POLICE ONLY', 'keyboard', 'K')

RegisterCommand("caninecommanders", function()
  if activate_k9 then
    local k9Commands = {
      {
          header = Lang:t("menu.k9_commands"),
          isMenuHeader = true
      },
      {
        header = Lang:t("menu.k9_sit"),
        txt = Lang:t("menu.k9_sittxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "sit"
        }
      },
      {
        header = Lang:t("menu.k9_lay"),
        txt = Lang:t("menu.k9_laytxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "laydown"
        }
      },
      {
        header = Lang:t("menu.k9_carsearch"),
        txt = Lang:t("menu.k9_carsearchtxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "searchcar"
        }
      },
      {
        header = Lang:t("menu.k9_enterveh"),
        txt = Lang:t("menu.k9_entervehtxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "entercar"
        }
      },
      {
        header = Lang:t("menu.k9_searchp"),
        txt = Lang:t("menu.k9_searchptxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "searchdude"
        }
      },
      {
        header = Lang:t("menu.k9_area"),
        txt = Lang:t("menu.k9_areatxt"),
        params = {
          event = 'qb-k9:client:Commands',
          args = "searcharea"
        }
      },
    }
    exports['qb-menu']:openMenu(k9Commands)
  end
end, false) 

RegisterKeyMapping('cannineattackfollow', 'K9 COMMANDS POLICE ONLY', 'keyboard', 'Z')

RegisterCommand("cannineattackfollow", function()
  if activate_k9 then
    local ped = PlayerPedId()
    if IsPlayerFreeAiming(PlayerId()) then
      local bool, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
      if bool then
          if IsEntityAPed(target) then
              following = false
              local DOG = NetworkGetEntityFromNetworkId(k9_id)

              if IsEntityAttached(DOG) then
                K9ToggleVehicle(target)
              else 
                K9AttackorFollow(target)
              end
          end
      end
    else
      if not following then
        K9AttackorFollow(false)
        following = true
      end
    end
  end
end, false) 

RegisterNetEvent('qb-k9:client:Commands', function(data)
  if data == "sit" then
    PlayAnimation(sit.dict, sit.anim)
  elseif data == "laydown" then 
    PlayAnimation(laydown.dict, laydown.anim)
  elseif data == "searchcar" then 
    K9SearchVehicle()
  elseif data == "entercar" then 
    K9ToggleVehicle(false)
  elseif data == "searchdude" then 
    K9SearchPerson()
  elseif data == "searcharea" then 
    K9SearchArea()
  end
end)
