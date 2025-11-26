
local robbing = false
local lastRobbedNpc = nil
local cooldown = {}

-- Configuration
local Config = {
    robberyKey = 38, -- E key
    robberyDistance = 2.0,
    minMoney = 50,
    maxMoney = 500,
    successChance = 70, -- 70% success rate
    cooldownTime = 300000, -- 5 minutes in milliseconds
    policeAlertChance = 30, -- 30% chance to alert police
    robberyTime = 5000 -- 5 seconds to rob
}

-- Function to check if NPC can be robbed
function CanRobNpc(ped)
    if not DoesEntityExist(ped) then return false end
    if IsPedAPlayer(ped) then return false end
    if IsPedInAnyVehicle(ped, false) then return false end
    if IsPedDeadOrDying(ped, true) then return false end
    if IsPedInCombat(ped, PlayerPedId()) then return false end
    
    local npcId = tostring(ped)
    if cooldown[npcId] and (GetGameTimer() - cooldown[npcId]) < Config.cooldownTime then
        return false
    end
    
    return true
end

-- Function to get closest NPC
function GetClosestNpc()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestNpc = nil
    local closestDistance = Config.robberyDistance
    
    local peds = GetGamePool('CPed')
    for _, ped in pairs(peds) do
        if ped ~= playerPed and CanRobNpc(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestNpc = ped
            end
        end
    end
    
    return closestNpc, closestDistance
end

-- Function to rob NPC
function RobNpc(ped)
    if robbing then return end
    
    robbing = true
    local playerPed = PlayerPedId()
    
    -- Make NPC scared
    TaskHandsUp(ped, Config.robberyTime, playerPed, -1, false)
    PlayPedAmbientSpeechNative(ped, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE")
    
    -- Play robbery animation
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Wait(100)
    end
    
    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, -1, 0, 0, false, false, false)
    
    -- Show progress notification
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName("Robbing NPC...")
    EndTextCommandThefeedPostTicker(false, true)
    
    -- Wait for robbery to complete
    Wait(Config.robberyTime)
    
    -- Calculate success
    local success = math.random(100) <= Config.successChance
    
    if success then
        local money = math.random(Config.minMoney, Config.maxMoney)
        
        -- Add money to player (you'll need to integrate with your economy system)
        -- TriggerServerEvent('npc_robbery:addMoney', money)
        
        -- Notification
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName("~g~Robbery successful! Stolen $" .. money)
        EndTextCommandThefeedPostTicker(false, true)
        
        -- Make NPC run away
        ClearPedTasksImmediately(ped)
        TaskReactAndFleePed(ped, playerPed)
        
        -- Police alert chance
        if math.random(100) <= Config.policeAlertChance then
            local coords = GetEntityCoords(playerPed)
            -- TriggerServerEvent('npc_robbery:policeAlert', coords)
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName("~r~Police have been alerted!")
            EndTextCommandThefeedPostTicker(false, true)
        end
    else
        -- Failed robbery
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName("~r~Robbery failed! NPC has no money.")
        EndTextCommandThefeedPostTicker(false, true)
        
        -- NPC runs away
        ClearPedTasksImmediately(ped)
        TaskReactAndFleePed(ped, playerPed)
    end
    
    -- Add to cooldown
    cooldown[tostring(ped)] = GetGameTimer()
    lastRobbedNpc = ped
    robbing = false
end

-- Main thread for drawing and detection
Citizen.CreateThread(function()
    while true do
        Wait(0)
        
        if not robbing then
            local closestNpc, distance = GetClosestNpc()
            
            if closestNpc then
                -- Draw 3D text
                local coords = GetEntityCoords(closestNpc)
                DrawText3D(coords.x, coords.y, coords.z + 1.0, "[E] Rob NPC")
                
                -- Check for key press
                if IsControlJustPressed(0, Config.robberyKey) then
                    RobNpc(closestNpc)
                end
            end
        end
    end
end)

-- Function to draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end
RegisterCommand('robberylog', function(source, args, rawCommand)
    local src = source
    
    if src == 0 then -- Console
        print("^3=== NPC Robbery Log ===^0")
        for k, v in pairs(robberyLog) do
            print("Player: " .. v.player .. " | Amount: $" .. v.amount .. " | Time: " .. v.time)
        end
    else
        -- Check if player is admin (you'll need to implement your admin check)
        -- For now, only console can use this
        print("^1This command can only be used from console^0")
    end
end, false)

-- Clear robbery log command
RegisterCommand('clearrobberylog', function(source, args, rawCommand)
    if source == 0 then
        robberyLog = {}
        print("^2Robbery log cleared!^0")
    end
end, false)
