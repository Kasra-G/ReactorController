local version = "0.51"
local tag = "reactorConfig"
--[[
Program made by DrunkenKas
	See github: https://github.com/Kasra-G/ReactorController/#readme

The MIT License (MIT)
 
Copyright (c) 2021 Kasra Ghaffari

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]


---@type table<string, Monitor>
local monitors = {}

_G.reactorVersion = nil
_G.reactor = nil
_G.btnOn = nil
_G.btnOff = nil
_G.minb = nil
_G.maxb = nil
_G.rod = nil
_G.rfLost = nil
_G.storedLastTick = 0
_G.storedThisTick = 0
_G.lastRFT = 0

_G.fuelTemp = 0
_G.caseTemp = 0
_G.fuelUsage = 0
_G.waste = 0
_G.capacity = 1

_G.SECONDS_TO_AVERAGE = 0.5

_G.averageStoredThisTick = 0
_G.averageStoredLastTick = 0
_G.averageLastRFT = 0
_G.averageRod = 0
_G.averageFuelUsage = 0
_G.averageWaste = 0
_G.averageFuelTemp = 0
_G.averageCaseTemp = 0
_G.averageRfLost = 0

--returns the side that a given peripheral type is connected to
local function getPeripheral(targetType)
    for _, name in pairs(peripheral.getNames()) do
        if (peripheral.getType(name) == targetType) then
            return name
        end
    end
    return ""
end

local function setRods(level)
    level = math.max(level, 0)
    level = math.min(level, 100)
    local count = reactor.getNumberOfControlRods()

    local numberToAddOneLevelTo = math.floor((level - math.floor(level)) * count + 0.5)

    local levelsMap = {}
    for idx0, _ in pairs(reactor.getControlRodsLevels()) do
        local rodLevel = math.floor(level)
        if numberToAddOneLevelTo > 0 then
            rodLevel = rodLevel + 1
            numberToAddOneLevelTo = numberToAddOneLevelTo - 1
        end
        levelsMap[idx0] = rodLevel
    end
    _G.reactor.setControlRodsLevels(levelsMap)
end

local function lerp(start, finish, t)
    t = math.max(0, math.min(1, t))

    return (1 - t) * start + t * finish
end

-- Function to calculate the average of an array of values
local function calculateAverage(array)
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    return sum / #array
end

-- Define PID controller parameters
local pid = {
    setpointRFT = 0,      -- Target RFT
    setpointRF = 0,      -- Target RF
    Kp = -.08,           -- Proportional gain
    Ki = -.0015,          -- Integral gain
    Kd = -.01,         -- Derivative gain
    integral = 0,       -- Integral term accumulator
    lastError = 0,      -- Last error for derivative term
}

local function iteratePID(pid, error)
    -- Proportional term
    local P = pid.Kp * error

    -- Integral term
    pid.integral = pid.integral + pid.Ki * error
    pid.integral = math.max(math.min(100, pid.integral), -100)

    -- Derivative term
    local derivative = pid.Kd * (error - pid.lastError)

    -- Calculate control rod level
    local rodLevel = math.max(math.min(P + pid.integral + derivative, 100), 0)

    -- Update PID controller state
    pid.lastError = error
    return rodLevel
end
local pretty = require("cc.pretty")

local function updateRods()
    if (not _G.btnOn) then
        return
    end
    local currentRF = _G.averageStoredLastTick
    local diffb = _G.maxb - _G.minb
    local minRF = _G.minb / 100 * _G.capacity
    local diffRF = diffb / 100 * _G.capacity
    local diffr = diffb / 100
    local targetRFT = _G.averageRfLost
    local currentRFT = _G.averageLastRFT
    local targetRF = diffRF / 2 + minRF

    pid.setpointRFT = targetRFT
    pid.setpointRF = targetRF / _G.capacity * 1000

    local errorRFT = pid.setpointRFT - currentRFT
    local errorRF = pid.setpointRF - currentRF / _G.capacity * 1000

    local W_RFT = lerp(1, 0, (math.abs(targetRF - currentRF) / _G.capacity / (diffr / 4)))
    W_RFT = math.max(math.min(W_RFT, 1), 0)

    local W_RF = (1 - W_RFT)  -- Adjust the weight for energy error

    -- Combine the errors with weights
    local combinedError = W_RFT * errorRFT + W_RF * errorRF
    local error = combinedError
    local rftRodLevel = iteratePID(pid, error)

    -- Set control rod levels
    setRods(rftRodLevel)
end

-- Saves the configuration of the reactor controller
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

local storedThisTickValues = {}
local lastRFTValues = {}
local rodValues = {}
local fuelUsageValues = {}
local wasteValues = {}
local fuelTempValues = {}
local caseTempValues = {}
local rfLostValues = {}

local function updateStats()
    if (_G.reactorVersion == "Big Reactors") then
        _G.storedThisTick = _G.reactor.getEnergyStored()
        _G.lastRFT = _G.reactor.getEnergyProducedLastTick()
        _G.rod = _G.reactor.getControlRodLevel(0)
        _G.fuelUsage = _G.reactor.getFuelConsumedLastTick() / 1000
        _G.waste = _G.reactor.getWasteAmount()
        _G.fuelTemp = _G.reactor.getFuelTemperature()
        _G.caseTemp = _G.reactor.getCasingTemperature()
        -- Big Reactors doesn't give us a way to directly query RF capacity through CC APIs
        _G.capacity = math.max(_G.capacity, _G.reactor.getEnergyStored)
    elseif (_G.reactorVersion == "Extreme Reactors") then
        local bat = _G.reactor.getEnergyStats()
        local fuel = _G.reactor.getFuelStats()

        _G.storedThisTick = bat.energyStored
        _G.lastRFT = bat.energyProducedLastTick
        _G.capacity = bat.energyCapacity
        _G.rod = calculateAverage(_G.reactor.getControlRodsLevels())
        _G.fuelUsage = fuel.fuelConsumedLastTick / 1000
        _G.waste = _G.reactor.getWasteAmount()
        _G.fuelTemp = _G.reactor.getFuelTemperature()
        _G.caseTemp = _G.reactor.getCasingTemperature()
    elseif (_G.reactorVersion == "Bigger Reactors") then
        _G.storedThisTick = _G.reactor.battery().stored()
        _G.lastRFT = _G.reactor.battery().producedLastTick()
        _G.capacity = _G.reactor.battery().capacity()
        _G.rod = _G.reactor.getControlRod(0).level()
        _G.fuelUsage = _G.reactor.fuelTank().burnedLastTick() / 1000
        _G.waste = _G.reactor.fuelTank().waste()
        _G.fuelTemp = _G.reactor.fuelTemperature()
        _G.caseTemp = _G.reactor.casingTemperature()
    end
    _G.rfLost = math.floor(_G.lastRFT + _G.storedLastTick - _G.storedThisTick + 0.5)
end

--Initialize variables from either a config file or the defaults
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
    elseif (legacyConfigExists) then
        local file = fs.open(tag..".txt", "r")
        local calibrated = file.readLine() == "true"

        --read calibration information
        if (calibrated) then
            _ = tonumber(file.readLine())
            _ = tonumber(file.readLine())
        end
        _G.maxb = tonumber(file.readLine())
        _G.minb = tonumber(file.readLine())
        _G.rod = tonumber(file.readLine())
        _G.btnOn = file.readLine() == "true"

        --read Graph data
        for i in pairs(XOffs) do
            local graph = file.readLine()
            local v1 = tonumber(file.readLine())
            local v2 = true
            if (graph ~= "nil") then
                v2 = false
                graphsToDraw[graph] = v1
            end

            XOffs[i] = {v1, v2}

        end
        file.close()
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

local function getAllPeripheralIdsForType(targetType)
    ---@type table<string, boolean>
    local peripheralIds = {}
    for _, id in pairs(peripheral.getNames()) do
        if (peripheral.getType(id) == targetType) then
            peripheralIds[id] = true
        end
    end
    return peripheralIds
end

local function disconnectMonitor(monitorID)
    if monitors[monitorID] == nil then
        return
    end

    print("Monitor "..monitorID.." disconnected!")
    monitors[monitorID] = nil
end

local function connectMonitor(monitorID)
    print("Monitor "..monitorID.." connected!")
    monitors[monitorID] = Monitor.new(monitorID)
end

local function discoverAndConnectMonitors()
    local ids = getAllPeripheralIdsForType("monitor")
    for id, _ in pairs(ids) do
        connectMonitor(id)
    end
end

local function redrawMonitors()
    for _, monitor in pairs(monitors) do
        monitor:draw()
        -- ---@type ReactorStatistics
        -- local reactorStats = {}
        -- monitor:update(reactorStats)
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
        end

        if event[1] == "peripheral" and peripheral.getType(event[2]) == "monitor" then
            connectMonitor(event[2])
        end

        if event[1] == "peripheral_detach" then
            disconnectMonitor(event[2])
        end
    end
end

local function updateAverages()
    table.insert(storedThisTickValues, _G.storedThisTick)
    table.insert(lastRFTValues, _G.lastRFT)
    table.insert(rodValues, _G.rod)
    table.insert(fuelUsageValues, _G.fuelUsage)
    table.insert(wasteValues, _G.waste)
    table.insert(fuelTempValues, _G.fuelTemp)
    table.insert(caseTempValues, _G.caseTemp)
    table.insert(rfLostValues, _G.rfLost)

    local maxIterations = 20 * _G.SECONDS_TO_AVERAGE
    while #storedThisTickValues > maxIterations do
        table.remove(storedThisTickValues, 1)
        table.remove(lastRFTValues, 1)
        table.remove(rodValues, 1)
        table.remove(fuelUsageValues, 1)
        table.remove(wasteValues, 1)
        table.remove(fuelTempValues, 1)
        table.remove(caseTempValues, 1)
        table.remove(rfLostValues, 1)
    end

    -- Calculate running averages
    _G.averageStoredThisTick = calculateAverage(storedThisTickValues)
    _G.averageLastRFT = calculateAverage(lastRFTValues)
    _G.averageRod = calculateAverage(rodValues)
    _G.averageFuelUsage = calculateAverage(fuelUsageValues)
    _G.averageWaste = calculateAverage(wasteValues)
    _G.averageFuelTemp = calculateAverage(fuelTempValues)
    _G.averageCaseTemp = calculateAverage(caseTempValues)
    _G.averageRfLost = calculateAverage(rfLostValues)
end


-- Main loop, handles all the events
local function loop()
    ::begin::

    local curTime = math.floor(os.clock() * 20)
    local lastTime = curTime
    local maxRetries = 10
    local tries = 0
    local cur = {}
    local last = {}
    sleep(0)
    while true do
        tries = 0
        curTime = math.floor(os.clock() * 20)
        if curTime ~= lastTime + 1 then
            print("lastTime "..lastTime..", curTime "..curTime)
            goto begin
        end

        updateStats()
        cur.rft = _G.reactor.getEnergyProducedLastTick()
        cur.energy = _G.reactor.getEnergyStats().energyStored
        if last.rft ~= nil and last.energy ~= nil then
            while cur.rft == last.rft and cur.energy == last.energy or tries <= maxRetries do
                updateStats()
                cur.rft = _G.reactor.getEnergyProducedLastTick()
                cur.energy = _G.reactor.getEnergyStats().energyStored
                tries = tries + 1
            end
            updateAverages()
            updateRods()
            redrawMonitors()
            _G.averageStoredLastTick = _G.averageStoredThisTick
        end

        _G.storedLastTick = _G.storedThisTick
        _G.lastRFTPrev = _G.lastRFT
        last.rft = cur.rft
        last.energy = cur.energy
        lastTime = curTime
        sleep(0)
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

    local reactorDetected = false
    while not reactorDetected do
        reactorDetected = detectReactor()
        if not reactorDetected then
            print("Reactor not detected! Trying again...")
            sleep(1)
        end
    end

    print("Reactor detected!")

    _G.maxb = 70
    _G.minb = 30
    _G.rod = 80
    _G.btnOn = true
    _G.btnOff = not _G.btnOn
    _G.reactor.setActive(_G.btnOn)
    discoverAndConnectMonitors()

    -- initMon()
    -- print("Writing config to disk...")
    -- saveToConfig()
    -- print("Reactor initialization done! Starting controller")

    -- term.clear()
    -- term.setCursorPos(1,1)
    -- print("Reactor Controller Version "..version)
    -- print("Reactor Mod: "..reactorVersion)
    --main loop

    parallel.waitForAny(loop, eventListener)
end
