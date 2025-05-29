---@type table<string, Monitor>
_G.monitors = {}
---@type table<string, Reactor>
_G.reactors = {}
-- _G.turbines = {}

_G.fluidBuffers = {}

---@type table<string, EnergyBuffer>
_G.energyBuffers = {}

_G.masterAutoRodControl = true

-- These are averaged when possible
---@class OverallStats
_G.overallStats = {
    storedLastTick = 0,
    storedThisTick = 0,
    lastRFT = 0,
    rfLost = 0,
    steamConsumedLastTick = 2000,
    fuelUsage = 0,
    waste = 0,
    capacity = 1000,
    efficiency = function ()
        return _G.overallStats.lastRFT / _G.overallStats.fuelUsage
    end
}

_G.selectedReactor = nil

-- -@class AveragedTurbineStatistics
-- -@field fuelUsage number
-- -@field fuelUsageValues Deque
-- -@field lastRFT number
-- -@field lastRFTValues Deque
-- -@field waste number
-- -@field wasteValues Deque
-- -@field fuelTemp number
-- -@field fuelTempValues Deque
-- -@field caseTemp number
-- -@field caseTempValues Deque

local function updateOverallStats()
    _G.overallStats.storedLastTick = 0
    _G.overallStats.storedThisTick = 0
    _G.overallStats.capacity = 0
    for id, energyBuffer in pairs(energyBuffers) do
        _G.overallStats.storedLastTick = _G.overallStats.storedLastTick + energyBuffer.averageEnergyStoredLastTick
        _G.overallStats.storedThisTick = _G.overallStats.storedThisTick + energyBuffer.averageEnergyStoredThisTick
        _G.overallStats.capacity = _G.overallStats.capacity + energyBuffer.capacity
    end

    _G.overallStats.fuelUsage = 0
    _G.overallStats.waste = 0
    _G.overallStats.lastRFT = 0
    _G.overallStats.steamProductionRate = 0
    _G.overallStats.storedSteam = 0
    _G.overallStats.steamCapacity = 0
    _G.overallStats.steamConsumedLastTick = 4000

    for id, reactor in pairs(reactors) do
        if reactor.isActivelyCooled then
            _G.overallStats.steamProductionRate = _G.overallStats.steamProductionRate + reactor.averageSteamProductionRate
            _G.overallStats.storedSteam = _G.overallStats.storedSteam + reactor.averageStoredSteam
            _G.overallStats.steamCapacity = _G.overallStats.steamCapacity + reactor.steamCapacity
        end
        _G.overallStats.fuelUsage = _G.overallStats.fuelUsage + reactor.averageFuelUsage
        _G.overallStats.lastRFT = _G.overallStats.lastRFT + reactor.averageLastRFT
        _G.overallStats.waste = _G.overallStats.waste + reactor.waste
    end

    _G.overallStats.rfLost = math.floor(_G.overallStats.lastRFT + _G.overallStats.storedLastTick - _G.overallStats.storedThisTick + 0.5)
end

_G.btnOn = nil
_G.minb = nil
_G.maxb = nil

_G.SECONDS_TO_AVERAGE = 0.5


-- Function to calculate the average of an array of values
local function calculateAverage(array)
    local sum = 0
    local count = 0
    for _, value in pairs(array) do
        sum = sum + value
        count = count + 1
    end
    return sum / count
end

-- TODO: Move to 2 or 3 stage PID controller to eliminate integral windup (oscillations)
-- TODO: Provide multiple PID presets for different sizes of reactors
    -- User can choose the one that works the best for each reactor.
-- TODO: Dynamic setting of PID constants based on measured change in RFT per % change in control rods
-- TODO: Try using % of max RFT generation as basis of PID controller
-- TODO: Try using gain scheduling to reduce integral windup

--TODO: Update this to handle settings for multiple reactors and turbines
local function saveToConfig()
    local file = fs.open(tag.."Serialized.txt", "w")
    local configs = {
        ["_G.maxb"] = _G.maxb,
        ["_G.minb"] = _G.minb,
        ["_G.rod"] = _G.rod,
        ["_G.btnOn"] = _G.btnOn,
        graphsToDraw = graphsToDraw,
        XOffs = XOffs,
    }
    local serialized = textutils.serialize(configs)
    file.write(serialized)
    file.close()
end



-- local function updateStats()
    -- if (_G.reactorVersion == "Big Reactors") then
    --     _G.storedThisTick = _G.reactor.getEnergyStored()
    --     _G.lastRFT = _G.reactor.getEnergyProducedLastTick()
    --     _G.rod = _G.reactor.getControlRodLevel(0)
    --     _G.fuelUsage = _G.reactor.getFuelConsumedLastTick() / 1000
    --     _G.waste = _G.reactor.getWasteAmount()
    --     _G.fuelTemp = _G.reactor.getFuelTemperature()
    --     _G.caseTemp = _G.reactor.getCasingTemperature()
    --     -- Big Reactors doesn't give us a way to directly query RF capacity through CC APIs
    --     _G.capacity = math.max(_G.capacity, _G.reactor.getEnergyStored)
    -- elseif (_G.reactorVersion == "Extreme Reactors") then
    --     local bat = _G.reactor.getEnergyStats()
    --     local fuel = _G.reactor.getFuelStats()

    --     _G.storedThisTick = bat.energyStored
    --     _G.lastRFT = bat.energyProducedLastTick
    --     _G.capacity = bat.energyCapacity
    --     _G.rod = calculateAverage(_G.reactor.getControlRodsLevels())
    --     _G.fuelUsage = fuel.fuelConsumedLastTick / 1000
    --     _G.waste = _G.reactor.getWasteAmount()
    --     _G.fuelTemp = _G.reactor.getFuelTemperature()
    --     _G.caseTemp = _G.reactor.getCasingTemperature()
    -- elseif (_G.reactorVersion == "Bigger Reactors") then
    --     _G.storedThisTick = _G.reactor.battery().stored()
    --     _G.lastRFT = _G.reactor.battery().producedLastTick()
    --     _G.capacity = _G.reactor.battery().capacity()
    --     _G.rod = _G.reactor.getControlRod(0).level()
    --     _G.fuelUsage = _G.reactor.fuelTank().burnedLastTick() / 1000
    --     _G.waste = _G.reactor.fuelTank().waste()
    --     _G.fuelTemp = _G.reactor.fuelTemperature()
    --     _G.caseTemp = _G.reactor.casingTemperature()
    -- end
    -- _G.rfLost = math.floor(_G.lastRFT + _G.storedLastTick - _G.storedThisTick + 0.5)
-- end

--TODO: Update this to handle settings for multiple reactors and turbines
local function loadFromConfig()
    _G.invalidDim = false
    local legacyConfigExists = fs.exists(tag..".txt")
    local newConfigExists = fs.exists(tag.."Serialized.txt")
    if (newConfigExists) then
        local file = fs.open(tag.."Serialized.txt", "r")
        print("Config file "..tag.."Serialized.txt found! Using configurated settings")

        local serialized = file.readAll()
        local deserialized = textutils.unserialise(serialized)
        
        _G.maxb = deserialized.maxb
        _G.minb = deserialized.minb
        _G.rod = deserialized.rod
        _G.btnOn = deserialized.btnOn
        graphsToDraw = deserialized.graphsToDraw
        XOffs = deserialized.XOffs
    else
        print("Config file not found, generating default settings!")

        _G.maxb = 70
        _G.minb = 30
        _G.rod = 80
        _G.btnOn = false
    end
    _G.btnOff = not _G.btnOn
    _G.reactor.setActive(_G.btnOn)
end

---@param monitorID string
local function connectMonitor(monitorID)
    print("Monitor "..monitorID.." connected!")
    monitors[monitorID] = Monitor.new(monitorID)
end

---@param reactorID string
local function connectExtremeReactor(reactorID)
    print("Extreme Reactor "..reactorID.." connected!")
    reactors[reactorID] = Reactor.newExtremeReactor(reactorID)
    _G.selectedReactor = reactors[reactorID]
end

---@param energyBufferID string
local function connectForgeEnergyBuffer(energyBufferID)
    print("Energy Buffer "..energyBufferID.." connected!")
    energyBuffers[energyBufferID] = EnergyBuffer.newForgeEnergyBuffer(energyBufferID)
end

---@param energyBufferID string
local function connectReactorEnergyBuffer(energyBufferID)
    print("Reactor Energy Buffer "..energyBufferID.." connected!")
    energyBuffers[energyBufferID] = EnergyBuffer.newReactorEnergyBuffer(energyBufferID)
end

local function firePeriphalAttachEventForAllPeripherals()
    for _, id in pairs(peripheral.getNames()) do
        os.queueEvent("peripheral", id)
    end
end

local function redrawMonitors()
    for _, monitor in pairs(monitors) do
        -- Eventually pass in our list of reactors and turbines to draw stats for.
        monitor:draw()
    end
end

---@param currentTickNumber number
local function updateEnergyBuffers(currentTickNumber)
    for _, energyBuffer in pairs(energyBuffers) do
        energyBuffer:update(currentTickNumber)
    end
end

---@param currentTickNumber number
local function updateReactors(currentTickNumber)
    for _, reactor in pairs(reactors) do
        reactor:update(currentTickNumber)
    end
end

function _G.setReactors(active)
    for _, reactor in pairs(reactors) do
        reactor.setActive(active)
    end
end

local function updateReactorRods()
    for _, reactor in pairs(reactors) do
        reactor:updateRods()
    end
end

---@param peripheralID string
local function handlePeripheralDetach(peripheralID)
    if monitors[peripheralID] ~= nil then
        print("Monitor "..peripheralID.." disconnected!")
        monitors[peripheralID] = nil
    end

    if energyBuffers[peripheralID] ~= nil then
        print("Energy Buffer "..peripheralID.." disconnected!")
        energyBuffers[peripheralID] = nil
    end

    if reactors[peripheralID] ~= nil then
        print("Reactor "..peripheralID.." disconnected!")
        reactors[peripheralID] = nil
    end
end

---@param peripheralID string
---@param peripheralType string
local function handlePeripheralAttach(peripheralID, peripheralType)
    if peripheralType == "monitor" then
        connectMonitor(peripheralID)
    elseif peripheralType == "BigReactors-Reactor" then
        connectExtremeReactor(peripheralID)
        connectReactorEnergyBuffer(peripheralID)
    elseif peripheralType == "energy_storage" then
        connectForgeEnergyBuffer(peripheralID)
    else
        print("Unknown peripheral", peripheralID, "of type", peripheralType, "attached to network")
    end
end


_G.TICKS_TO_REDRAW = 1
local function runLoop(currentTickNumber)
    updateEnergyBuffers(currentTickNumber)
    updateReactors(currentTickNumber)
    updateOverallStats()
    if currentTickNumber % TICKS_TO_REDRAW == 0 then
        redrawMonitors()
    end
end

local function eventListener()
    while true do
        local event = { os.pullEvent() }

        if event[1] == "monitor_touch" or event[1] == "monitor_resize" then
            local monitor = monitors[event[2]]
            if monitor ~= nil then
                monitor:handleEvents(event)
            end
        elseif event[1] == "peripheral" then
            handlePeripheralAttach(event[2],  peripheral.getType(event[2]))
        elseif event[1] == "peripheral_detach" then
            handlePeripheralDetach(event[2])
        end
    end
end

local function loop()
    local loopEventName = "yield"
    local curTime = math.floor(os.clock() * 20)
    local lastTime = curTime

    os.sleep(0)
    while true do
        curTime = math.floor(os.clock() * 20)

        local reactorCount = 0
        for _, reactor in pairs(_G.reactors) do
            reactorCount = reactorCount + 1
        end
        if reactorCount < 1 then
            print("Reactor not detected! Please connect a reactor!")
            sleep(1)
        elseif curTime < lastTime + 1 then
            os.queueEvent(loopEventName)
            os.pullEvent(loopEventName)
        elseif curTime > lastTime + 1 then
            -- We have missed the data from the last tick
            print("Missed last", curTime - lastTime - 1, "ticks!", curTime)
            runLoop(curTime)
        else
            local t = os.epoch("utc")
            -- Guaranteed to run at the start of a new tick
            while os.epoch("utc") - t < 2 do
                os.queueEvent(loopEventName)
                os.pullEvent(loopEventName)
            end
            runLoop(curTime)
            updateReactorRods()
            os.sleep(0)
        end
        lastTime = curTime
    end
end

local function detectReactor()
    -- Bigger Reactors V1.
    local reactor_bigger_v1 = getPeripheral("bigger-reactor")
    _G.reactor = reactor_bigger_v1 ~= nil and peripheral.wrap(reactor_bigger_v1)
    if (_G.reactor ~= nil) then
        _G.reactorVersion = "Bigger Reactors"
        return true
    end

    -- Bigger Reactors V2
    local reactor_bigger_v2 = getPeripheral("BiggerReactors_Reactor")
    _G.reactor = reactor_bigger_v2 ~= nil and peripheral.wrap(reactor_bigger_v2)
    if (_G.reactor ~= nil) then
        _G.reactorVersion = "Bigger Reactors"
        return true
    end

    -- Big Reactors or Extreme Reactors
    local reactor_extreme_or_big = getPeripheral("BigReactors-Reactor")
    _G.reactor = reactor_extreme_or_big ~= nil and peripheral.wrap(reactor_extreme_or_big)
    if (_G.reactor ~= nil) then
        _G.reactorVersion = (_G.reactor.mbIsConnected ~= nil) and "Extreme Reactors" or "Big Reactors"
        return true
    end
    return false
end

--Entry point
function _G.main()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)

    _G.monitors = {}
    _G.reactors = {}
    _G.turbines = {}
    _G.energyBuffers = {}

    _G.maxb = 70
    _G.minb = 30
    _G.rod = 80
    _G.btnOn = true

    -- Manually fire the "peripheral" event to make sure all the connected peripherals are initialized correctly.
    firePeriphalAttachEventForAllPeripherals()

    -- term.clear()
    -- term.setCursorPos(1,1)
    -- print("Reactor Controller Version "..version)
    -- print("Reactor Mod: "..reactorVersion)
    --main loop

    parallel.waitForAll(loop, eventListener)
end
