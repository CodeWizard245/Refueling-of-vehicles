local fuelLevel = 15
local maxFuel = 15
local planeFuelLevel = 50
local maxPlaneFuel = 50
local fuelRate = 1
local planeFuelRate = 1
local isRefueling = false
local lowFuelWarning = false 

local lastPos = nil
local distanceTraveled = 0
local currentVehicleId = nil
function IsPointInZone(point, zone)
    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
    end

    local b1, b2, b3, b4
    b1 = sign(point, zone[1], zone[2]) < 0.0
    b2 = sign(point, zone[2], zone[3]) < 0.0
    b3 = sign(point, zone[3], zone[4]) < 0.0
    b4 = sign(point, zone[4], zone[1]) < 0.0

    return ((b1 == b2) and (b2 == b3) and (b3 == b4))
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local isInVehicle = IsPedInAnyVehicle(playerPed, false)

        if isInVehicle then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local isDriver = GetPedInVehicleSeat(vehicle, -1) == playerPed

            if DoesEntityExist(vehicle) then
                local vehicleId = NetworkGetNetworkIdFromEntity(vehicle)

                if vehicleId and vehicleId ~= 0 then
                    if currentVehicleId ~= vehicleId then
                        currentVehicleId = vehicleId
                        TriggerServerEvent("syncFuel:getFuelLevel", vehicleId)
                    end
                end
            end

            if GetIsVehicleEngineRunning(vehicle) and isDriver and not isRefueling then
                local currentPos = GetEntityCoords(vehicle)
                if lastPos then
                    local dist = GetDistanceBetweenCoords(lastPos, currentPos, true)
                    distanceTraveled = distanceTraveled + dist

                    if distanceTraveled >= 1680 then
                        fuelLevel = fuelLevel - fuelRate
                        distanceTraveled = 0
                        if fuelLevel <= 0 then
                            SetVehicleEngineOn(vehicle, false, true, false)
                            fuelLevel = 0
                        end

                        if currentVehicleId then
                            TriggerServerEvent("syncFuel:setFuelLevel", currentVehicleId, fuelLevel)
                        end
                    end
                end
                lastPos = currentPos

                if fuelLevel <= 3 and not lowFuelWarning then
                    TriggerEvent("chat:addMessage", {args = {"~r~Attention: low fuel!"}})
                    lowFuelWarning = true
                end

                if Config.ShowFuelInfo then
                    local fuelText = math.floor(fuelLevel)
                    drawTxt(0.181, 0.70, 0.5, tostring(fuelText), 255, 255, 255, 255)
                    drawTxt(0.179, 0.72, 0.5, "gal", 255, 255, 255, 255)
                end

                if Config.ShowSpeedInfo then
                    local speed = GetEntitySpeed(vehicle) * 2.23694
                    drawTxt(0.160, 0.66, 0.5, tostring(math.floor(speed)), 255, 255, 255, 255)
                    drawTxt(0.155, 0.68, 0.5, "mph", 255, 255, 255, 255)
                end
            end

            if fuelLevel <= 0 then
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
            end
        else
            local isNearStation = false
            for _, zone in ipairs(Config.GasStations) do
                if IsPointInZone({x = playerCoords.x, y = playerCoords.y}, zone) then
                    isNearStation = true
                    drawTxt(0.5, 0.8, 0.4, "~g~Press E to refuel", 255, 255, 255, 255)
                    if IsControlJustReleased(0, 38) then
                        StartRefueling()
                    end
                    break
                end
            end
        end
    end
end)

function StartRefueling()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleClass = GetVehicleClass(vehicle)
    local isAircraft = vehicleClass == 16 or vehicleClass == 15

    isRefueling = true

    Citizen.CreateThread(function()
        while isRefueling do
            Citizen.Wait(1000)

            if isAircraft then
                planeFuelLevel = planeFuelLevel + 1
                if planeFuelLevel >= maxPlaneFuel then
                    planeFuelLevel = maxPlaneFuel
                    isRefueling = false
                    TriggerEvent("chat:addMessage", {args = {"~g~Refueling is complete!"}})
                end
            else
                fuelLevel = fuelLevel + 1
                if fuelLevel >= maxFuel then
                    fuelLevel = maxFuel
                    isRefueling = false
                    TriggerEvent("chat:addMessage", {args = {"~g~Refueling is complete!"}})
                end
            end
            if currentVehicleId then
                TriggerServerEvent("syncFuel:setFuelLevel", currentVehicleId, fuelLevel)
            end
        end
    end)
end

RegisterNetEvent("syncFuel:returnFuelLevel")
AddEventHandler("syncFuel:returnFuelLevel", function(fuel)
    fuelLevel = fuel
end)

function drawTxt(x, y, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end
