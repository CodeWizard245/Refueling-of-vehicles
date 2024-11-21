local vehicleFuelLevels = {}

RegisterServerEvent("syncFuel:setFuelLevel")
AddEventHandler("syncFuel:setFuelLevel", function(vehicleId, fuelLevel)
    vehicleFuelLevels[vehicleId] = fuelLevel
end)

RegisterServerEvent("syncFuel:getFuelLevel")
AddEventHandler("syncFuel:getFuelLevel", function(vehicleId)
    local source = source
    local fuelLevel = vehicleFuelLevels[vehicleId] or 15
    TriggerClientEvent("syncFuel:returnFuelLevel", source, fuelLevel)
end)
