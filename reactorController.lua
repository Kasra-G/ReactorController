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

dofile("/usr/apis/touchpoint.lua")
dofile("classes.lua")
dofile("draw.lua")
dofile("graph.lua")
dofile("monitor.lua")

local reactorVersion, reactor
local mon, monSide
local sizex, sizey, dividerXCoord, oo, offy
local btnOn, btnOff, invalidDim
local minb, maxb
local rod, rfLost
local storedLastTick, storedThisTick, lastRFT = 0,0,0
local fuelTemp, caseTemp, fuelUsage, waste, capacity = 0,0,0,0,1
local t
local displayingGraphMenu = false

local SECONDS_TO_AVERAGE = 2

local averageStoredThisTick = 0
local averageLastRFT = 0
local averageRod = 0
local averageFuelUsage = 0
local averageWaste = 0
local averageFuelTemp = 0
local averageCaseTemp = 0
local averageRfLost = 0

local MINIMUM_DIVIDER_X_VALUE = 3

-- table of which graphs to draw
local graphsToDraw = {}

-- table of all the graphs
local graphs =
{
    "Energy Buffer",
    "Control Level",
    "Temperatures",
}

-- marks the offsets for each graph position
-- { XOffset, <is_available> }
local XOffs =
{
    { 4, true},
    {27, true},
    {50, true},
    {73, true},
    {96, true},
}

--Helper method for adding buttons
local function addButton(touch, name, callBack, offset, size, color1, color2)
    local buttonTopLeftCorner = offset + Vector2.one
    local buttonBottomRightCorner = offset + size
    touch:add(
        name,
        callBack,
        buttonTopLeftCorner.x,
        buttonTopLeftCorner.y,
        buttonBottomRightCorner.x,
        buttonBottomRightCorner.y,
        color1,
        color2
    )
end

local function minAdd10()
    minb = math.min(maxb - 10, minb + 10)
end
local function minSub10()
    minb = math.max(0, minb - 10)
end
local function maxAdd10()
    maxb = math.min(100, maxb + 10)
end
local function maxSub10()
    maxb = math.max(minb + 10, maxb - 10)
end

local function turnOff()
    if (btnOn) then
        t:toggleButton("Off")
        t:toggleButton("On")
        btnOff = true
        btnOn = false
        reactor.setActive(false)
    end
end

local function turnOn()
    if (btnOff) then
        t:toggleButton("Off")
        t:toggleButton("On")
        btnOff = false
        btnOn = true
        reactor.setActive(true)
    end
end

--adds buttons
local function addButtons()
    if (sizey == 24) then
        oo = 1
    end
    local buttonSize = Vector2.new(8, 3)
    local offsetOnOff = Vector2.new(dividerXCoord + 5, 3 + oo)

    addButton(
        t,
        "On",
        turnOn,
        offsetOnOff,
        buttonSize,
        colors.red,
        colors.lime
    )

    addButton(
        t,
        "Off",
        turnOff,
        offsetOnOff + Vector2.new(12, 0),
        buttonSize,
        colors.red,
        colors.lime
    )

    if (btnOn) then
        t:toggleButton("On", true)
    else
        t:toggleButton("Off", true)
    end

    local offset = Vector2.new(dividerXCoord, oo)

    if (sizey > 24) then
        addButton(
            t,
            "+ 10",
            minAdd10,
            offset + Vector2.new(5, 14),
            buttonSize,
            colors.purple,
            colors.pink
        )
        addButton(
            t,
            " + 10 ",
            maxAdd10,
            offset + Vector2.new(17, 14),
            buttonSize,
            colors.magenta,
            colors.pink
        )
        addButton(
            t,
            "- 10",
            minSub10,
            offset + Vector2.new(5, 18),
            buttonSize,
            colors.purple,
            colors.pink
        )
        addButton(
            t,
            " - 10 ",
            maxSub10,
            offset + Vector2.new(17, 18),
            buttonSize,
            colors.magenta,
            colors.pink
        )
    end
end

--Resets the monitor
local function resetMon()
    if (monSide == nil) then
        return
    end
    mon.setBackgroundColor(colors.black)
    mon.clear()
    mon.setTextScale(0.5)
    mon.setCursorPos(1,1)
end

local function getPercPower()
    return averageStoredThisTick / capacity * 100
end

local function rnd(num, dig)
    return math.floor(10 ^ dig * num) / (10 ^ dig)
end

local function getEfficiency()
    return averageLastRFT / averageFuelUsage
end

local function format(num)
    if (num >= 1000000000) then
        return string.format("%7.3f G", num / 1000000000)
    elseif (num >= 1000000) then
        return string.format("%7.3f M", num / 1000000)
    elseif (num >= 1000) then
        return string.format("%7.3f K", num / 1000)
    elseif (num >= 1) then
        return string.format("%7.3f ", num)
    elseif (num >= .001) then
        return string.format("%7.3f m", num * 1000)
    elseif (num >= .000001) then
        return string.format("%7.3f u", num * 1000000)
    else
        return string.format("%7.3f ", 0)
    end
end


local function getAvailableXOff()
    for i,v in pairs(XOffs) do
        if (v[2] and v[1] < dividerXCoord - 1) then
            v[2] = false
            return v[1]
        end
    end
    return -1
end

local function getXOff(num)
    for i,v in pairs(XOffs) do
        if (v[1] == num) then
            return v
        end
    end
    return nil
end

local function enableGraph(name)
    if (graphsToDraw[name] ~= nil) then
        return
    end
    local e = getAvailableXOff()
    if (e ~= -1) then
        graphsToDraw[name] = e
        if (displayingGraphMenu) then
            t:toggleButton(name)
        end
    end
end

local function disableGraph(name)
    if (graphsToDraw[name] == nil) then
        return
    end
    if (displayingGraphMenu) then
        t:toggleButton(name)
    end
    getXOff(graphsToDraw[name])[2] = true
    graphsToDraw[name] = nil
end

local function toggleGraph(name)
    if (graphsToDraw[name] == nil) then
        enableGraph(name)
    else
        disableGraph(name)
    end
end

local function addGraphButtons()
    offy = oo - 14
    local graphButtonSize = Vector2.new(20, 3)
    local graphButtonOffset = Vector2.new(dividerXCoord + 5, offy)
    for i,graphName in pairs(graphs) do

        addButton(
            t,
            graphName,
            function() toggleGraph(graphName) end,
            graphButtonOffset + Vector2.new(0, i * 3 - 1),
            graphButtonSize,
            colors.red,
            colors.lime
        )
        if (graphsToDraw[graphName] ~= nil) then
            t:toggleButton(graphName, true)
        end
    end
end

local function drawGraphButtons(mon, offset, size)

    DrawUtil.drawRectangle(mon, colors.black, colors.orange, offset, size)
    local textPos = offset + Vector2.new(4, 0)
    DrawUtil.drawText(
        mon,
        " Graph Controls ",
        textPos,
        colors.black,
        colors.orange
    )
end

local function drawEnergyBuffer(mon, offset, graphSize, drawPercentLabelOnRight)
    DrawUtil.drawText(mon, "Energy Buffer", offset, colors.black, colors.orange)
    DrawUtil.drawRectangle(mon, colors.red, colors.gray, offset + Vector2.new(0, 1), graphSize)

    local energyBufferMaxHeight = graphSize.y - 2
    local unitEnergyLevel = getPercPower() / 100
    local energyBufferHeight = math.floor(unitEnergyLevel * energyBufferMaxHeight + 0.5)
    local rndpw = rnd(getPercPower(), 2)

    local energyBufferColor
    if rndpw < maxb and rndpw > minb then
        energyBufferColor = colors.green
    elseif rndpw >= maxb then
        energyBufferColor = colors.orange
    elseif rndpw <= minb then
        energyBufferColor = colors.blue
    end

    local energyBufferTipOffset = offset + Vector2.new(1, 2 + energyBufferMaxHeight - energyBufferHeight)
    local energyBufferSize = Vector2.new(graphSize.x - 2, energyBufferHeight)

    DrawUtil.drawFilledRectangle(mon, energyBufferColor, energyBufferTipOffset, energyBufferSize)

    local energyBufferTextOffset = energyBufferTipOffset
    local rfLabelBackgroundColor = energyBufferColor

    if energyBufferHeight <= 0 then
        energyBufferTextOffset = energyBufferTipOffset + Vector2.new(0, -1)
        rfLabelBackgroundColor = colors.red
    end

    local percentLabelXOffset = offset.x - 6
    if drawPercentLabelOnRight then
        percentLabelXOffset = offset.x + 15
    end

    DrawUtil.drawText(
        mon,
        string.format(drawPercentLabelOnRight and "%.2f%%" or "%5.2f%%", rndpw),
        Vector2.new(percentLabelXOffset, energyBufferTextOffset.y),
        colors.black,
        energyBufferColor
    )
    DrawUtil.drawText(
        mon,
        format(averageStoredThisTick).."RF",
        energyBufferTextOffset,
        rfLabelBackgroundColor,
        colors.black
    )
end

local function drawControlGraph(mon, offset, size, averageRod)
    local unitRodLevel = averageRod / 100
    local controlRodMaxPixelHeight = size.y - 2
    local controlRodPixelHeight = math.ceil(unitRodLevel * controlRodMaxPixelHeight)

    DrawUtil.drawText(
        mon,
        "Control Level",
        offset + Vector2.new(1, 0),
        colors.black,
        colors.orange

    )
    DrawUtil.drawRectangle(
        mon,
        colors.yellow,
        colors.gray,
        offset + Vector2.new(0, 1),
        size
    )
    DrawUtil.drawFilledRectangle(
        mon,
        colors.white,
        offset + Vector2.new(3, 2),
        Vector2.new(9, controlRodPixelHeight)
    )

    local controlRodLevelTextPos, color
    if controlRodPixelHeight > 0 then
        color = colors.white
        controlRodLevelTextPos = offset + Vector2.new(4, 1 + controlRodPixelHeight)
    else
        color = colors.yellow
        controlRodLevelTextPos = offset + Vector2.new(4, 2)
    end

    DrawUtil.drawText(
        mon,
        string.format("%6.2f%%", averageRod),
        controlRodLevelTextPos,
        color,
        colors.black
    )
end

local function drawTemperatures(mon, offset, size)

    DrawUtil.drawRectangle(mon, colors.black, colors.gray, offset + Vector2.new(1, 1), size)

    local CASE_TEMP_COLOR = colors.lightBlue
    local FUEL_TEMP_COLOR = colors.magenta
    local BACKGROUND_COLOR = colors.black

    local assumedMaxCaseTemperature = 3000
    local assumedMaxFuelTemperature = 3000
    local temperatureMaxHeight = size.y - 2

    local tempUnit = (reactorVersion == "Bigger Reactors") and "K" or "C"
    local tempFormat = "%4s"..tempUnit

    DrawUtil.drawText(mon, "Temperatures", offset + Vector2.new(2, 0), BACKGROUND_COLOR, colors.orange)
    DrawUtil.drawFilledRectangle(mon, colors.gray, offset + Vector2.new(8, 2), Vector2.new(1, temperatureMaxHeight))

    -- case temp
    DrawUtil.drawText(mon, "Case", offset + Vector2.new(3, 1), colors.gray, colors.lightBlue)
    local caseUnit = math.min(averageCaseTemp / assumedMaxCaseTemperature, 1)
    local caseTempHeight = math.floor(caseUnit * temperatureMaxHeight + 0.5)

    local caseTempOffset = offset + Vector2.new(2, 2 + temperatureMaxHeight - caseTempHeight)
    local caseTempSize = Vector2.new(6, caseTempHeight)

    DrawUtil.drawFilledRectangle(mon, CASE_TEMP_COLOR, caseTempOffset, caseTempSize)

    local caseTempTextOffset = caseTempOffset
    local caseTempTextBackgroundColor = CASE_TEMP_COLOR
    local caseTempTextColor = BACKGROUND_COLOR

    if caseTempHeight <= 0 then
        caseTempTextOffset = caseTempOffset + Vector2.new(0, -1)
        caseTempTextColor, caseTempTextBackgroundColor = caseTempTextBackgroundColor, caseTempTextColor
    end

    local caseRnd = math.floor(averageCaseTemp + 0.5)
    DrawUtil.drawText(mon, string.format(tempFormat, caseRnd..""), caseTempTextOffset, caseTempTextBackgroundColor, caseTempTextColor)

    -- fuel temp
    DrawUtil.drawText(mon, "Fuel", offset + Vector2.new(10, 1), colors.gray, colors.lightBlue)
    local fuelUnit = math.min(averageFuelTemp / assumedMaxFuelTemperature, 1)
    local fuelTempHeight = math.floor(fuelUnit * temperatureMaxHeight + 0.5)

    local fuelTempOffset = offset + Vector2.new(9, 2 + temperatureMaxHeight - fuelTempHeight)
    local fuelTempSize = Vector2.new(6, fuelTempHeight)

    DrawUtil.drawFilledRectangle(mon, FUEL_TEMP_COLOR, fuelTempOffset, fuelTempSize)

    local fuelTempTextOffset = fuelTempOffset
    local fuelTempTextBackgroundColor = FUEL_TEMP_COLOR
    local fuelTempTextColor = BACKGROUND_COLOR

    if fuelTempHeight <= 0 then
        fuelTempTextOffset = fuelTempOffset + Vector2.new(0, -1)
        fuelTempTextColor, fuelTempTextBackgroundColor = fuelTempTextBackgroundColor, fuelTempTextColor
    end

    local fuelRnd = math.floor(averageFuelTemp + 0.5)
    DrawUtil.drawText(mon, string.format(tempFormat, fuelRnd..""), fuelTempTextOffset, fuelTempTextBackgroundColor, fuelTempTextColor)
end

local function drawGraph(name, graphOffset, graphSize)
    if (name == "Energy Buffer") then
        local drawPercentLabelOnRight = graphOffset.x + 19 < dividerXCoord - 1
        drawEnergyBuffer(mon, graphOffset, graphSize, drawPercentLabelOnRight)
    elseif (name == "Control Level") then
        drawControlGraph(mon, graphOffset, graphSize, averageRod)
    elseif (name == "Temperatures") then
        drawTemperatures(mon, graphOffset, graphSize)
    end
end

local function drawGraphs(mon, graphsToDraw, dividerXCoord, offset, size)
    DrawUtil.drawRectangle(mon, colors.black, colors.lightBlue, offset, size)
    local label = " Reactor Graphs "
    DrawUtil.drawText(
        mon,
        label,
        offset + Vector2.new(dividerXCoord - (#label + 5) - 1, 0),
        colors.black,
        colors.lightBlue
    )

    local graphSize = Vector2.new(15, sizey - 7)
    local graphYOffset = 4
    for graphName, graphXOffset in pairs(graphsToDraw) do
        if (graphXOffset + graphSize.x < dividerXCoord) then
            drawGraph(graphName, Vector2.new(graphXOffset, graphYOffset), graphSize)
        end
    end
end

local function drawControls(mon, offset, size, drawBufferVisualization)

    DrawUtil.drawRectangle(mon, colors.black, colors.cyan, offset, size)
    DrawUtil.drawText(mon, " Reactor Controls ", offset + Vector2.new(4, 0), colors.black, colors.cyan)

    local reactorOnOffLabel = "Reactor "..(btnOn and "Online" or "Offline")
    local reactorOnOffLabelColor = btnOn and colors.green or colors.red
    DrawUtil.drawText(mon, reactorOnOffLabel, offset + Vector2.new(7, 2), colors.black, reactorOnOffLabelColor)

    if not drawBufferVisualization then
        return
    end

    local bufferMinInPixels = minb / 5
    local bufferMaxInPixels = maxb / 5
    local bufferRangePixelWidth = bufferMaxInPixels - bufferMinInPixels

    local bufferVisualOffset = offset + Vector2.new(5, 8)
    local bufferVisualSize = Vector2.new(20, 3)

    DrawUtil.drawText(mon, "Buffer Target Range", bufferVisualOffset + Vector2.new(0, -1), colors.black, colors.orange)
    DrawUtil.drawFilledRectangle(mon, colors.red, bufferVisualOffset, bufferVisualSize)
    DrawUtil.drawFilledRectangle(mon, colors.green, bufferVisualOffset + Vector2.new(bufferMinInPixels, 0), Vector2.new(bufferRangePixelWidth, 3))

    DrawUtil.drawText(
        mon,
        string.format("%3s", minb.."%"),
        bufferVisualOffset + Vector2.new(bufferMinInPixels - 3, bufferVisualSize.y),
        colors.black,
        colors.purple
    )
    DrawUtil.drawText(
        mon,
        maxb.."%",
        bufferVisualOffset + Vector2.new(bufferMaxInPixels, bufferVisualSize.y),
        colors.black,
        colors.magenta
    )
    DrawUtil.drawText(mon, "Min", offset + Vector2.new(7, 13), colors.black, colors.purple)
    DrawUtil.drawText(mon, "Max", offset + Vector2.new(19, 13), colors.black, colors.purple)
end

local function drawStatistics(mon, offset, size)
    DrawUtil.drawRectangle(mon, colors.black, colors.blue, offset, size)
    DrawUtil.drawText(
        mon,
        " Reactor Statistics ",
        offset + Vector2.new(4, 0),
        colors.black,
        colors.blue
    )

    DrawUtil.drawText(
        mon,
        "Generating : "..format(averageLastRFT).."RF/t",
        offset + Vector2.new(2, 2),
        colors.black,
        colors.green
    )

    DrawUtil.drawText(
        mon,
        "RF Drain   "..(averageStoredThisTick <= averageLastRFT and "> " or ": ")..format(averageRfLost).."RF/t",
        offset + Vector2.new(2, 4),
        colors.black,
        colors.red
    )

    DrawUtil.drawText(
        mon,
        "Efficiency : "..format(getEfficiency()).."RF/B",
        offset + Vector2.new(2, 6),
        colors.black,
        colors.green
    )

    DrawUtil.drawText(
        mon,
        "Fuel Usage : "..format(averageFuelUsage).."B/t",
        offset + Vector2.new(2, 8),
        colors.black,
        colors.green
    )

    DrawUtil.drawText(
        mon,
        "Waste      : "..string.format("%7d mB", waste),
        offset + Vector2.new(2, 10),
        colors.black,
        colors.green
    )
end

--Draw a scene
local function drawScene()
    if (monSide == nil) then
        return
    end
    if (invalidDim) then
        mon.write("Invalid Monitor Dimensions")
        return
    end

    local offset, size

    if (displayingGraphMenu) then
        offset = Vector2.new(dividerXCoord + 1, offy + 1)
        size = Vector2.new(30, 13)
        drawGraphButtons(mon, offset, size)
    end

    offset = Vector2.new(dividerXCoord + 1, oo + 1)
    size = Vector2.new(30, 23)
    local drawBufferVisualization = true
    if (sizey <= 24) then
        size = Vector2.new(30, 9)
        drawBufferVisualization = false
    end
    drawControls(mon, offset, size, drawBufferVisualization)

    if (dividerXCoord > MINIMUM_DIVIDER_X_VALUE) then
        offset = Vector2.new(2, 2)
        size = Vector2.new(dividerXCoord - 2, sizey - 2)
        drawGraphs(mon, graphsToDraw, dividerXCoord, offset, size)
    end

    offset = Vector2.new(dividerXCoord + 1, sizey - 12)
    size = Vector2.new(30, 12)
    drawStatistics(mon, offset, size)

    t:draw()
end

local function getAllPeripheralIdsForType(targetType)
    ---@type string[]
    local peripheralIds = {}
    for _, id in pairs(peripheral.getNames()) do
        if (peripheral.getType(id) == targetType) then
            table.insert(peripheralIds, id)
        end
    end
    return peripheralIds
end

---@type table<string, Monitor>
local monitors = {}

local function initMon2(id)
    local monitor = Monitor.new(id)
    monSide = id
    mon = monitor.mon
    monitor:clear()
    t = monitor.touch

    sizex, sizey = mon.getSize()
    oo = sizey - 37
    dividerXCoord = sizex - 31

    if (sizex == 36) then
        dividerXCoord = MINIMUM_DIVIDER_X_VALUE
    end
    displayingGraphMenu = pcall(function() addGraphButtons() end)
    _, invalidDim = pcall(function() addButtons() end)

    return monitor
end

local function updateMonitors()
    for _, monitor in pairs(monitors) do
        ---@type ReactorStatistics
        local reactorStats = {}
        monitor:update(reactorStats)
    end
end

local function initMonitors()
    monitors = {}
    local ids = getAllPeripheralIdsForType("monitor")

    for _, id in pairs(ids) do
        monitors[id] = initMon2(id)
    end
end
-- DELETE LATER!
initMonitors()

--returns the side that a given peripheral type is connected to
local function getPeripheral(targetType)
    for _, name in pairs(peripheral.getNames()) do
        if (peripheral.getType(name) == targetType) then
            return name
        end
    end
    return ""
end

--Creates all the buttons and determines monitor size
local function initMon()
    monSide = getPeripheral("monitor")
    if (monSide == nil or monSide == "") then
        monSide = nil
        return
    end

    local monitor = Monitor.new(monSide)
    mon = monitor.mon

    if mon == nil then
        monSide = nil
        return
    end

    resetMon()
    t = touchpoint.new(monSide)
    sizex, sizey = mon.getSize()
    oo = sizey - 37
    dividerXCoord = sizex - 31

    if (sizex == 36) then
        dividerXCoord = MINIMUM_DIVIDER_X_VALUE
    end
    displayingGraphMenu = pcall(function() addGraphButtons() end)
    _, invalidDim = pcall(function() addButtons() end)
end

local function setRods(level)
    level = math.max(level, 0)
    level = math.min(level, 100)
    reactor.setAllControlRodLevels(level)
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

local function updateRods()
    if (not btnOn) then
        return
    end
    local currentRF = storedThisTick
    local diffb = maxb - minb
    local minRF = minb / 100 * capacity
    local diffRF = diffb / 100 * capacity
    local diffr = diffb / 100
    local targetRFT = rfLost
    local currentRFT = lastRFT
    local targetRF = diffRF / 2 + minRF

    pid.setpointRFT = targetRFT
    pid.setpointRF = targetRF / capacity * 1000

    local errorRFT = pid.setpointRFT - currentRFT
    local errorRF = pid.setpointRF - currentRF / capacity * 1000

    local W_RFT = lerp(1, 0, (math.abs(targetRF - currentRF) / capacity / (diffr / 4)))
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
        maxb = maxb,
        minb = minb,
        rod = rod,
        btnOn = btnOn,
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
    storedLastTick = storedThisTick
    if (reactorVersion == "Big Reactors") then
        storedThisTick = reactor.getEnergyStored()
        lastRFT = reactor.getEnergyProducedLastTick()
        rod = reactor.getControlRodLevel(0)
        fuelUsage = reactor.getFuelConsumedLastTick() / 1000
        waste = reactor.getWasteAmount()
        fuelTemp = reactor.getFuelTemperature()
        caseTemp = reactor.getCasingTemperature()
        -- Big Reactors doesn't give us a way to directly query RF capacity through CC APIs
        capacity = math.max(capacity, reactor.getEnergyStored)
    elseif (reactorVersion == "Extreme Reactors") then
        local bat = reactor.getEnergyStats()
        local fuel = reactor.getFuelStats()

        storedThisTick = bat.energyStored
        lastRFT = bat.energyProducedLastTick
        capacity = bat.energyCapacity
        rod = reactor.getControlRodLevel(0)
        fuelUsage = fuel.fuelConsumedLastTick / 1000
        waste = reactor.getWasteAmount()
        fuelTemp = reactor.getFuelTemperature()
        caseTemp = reactor.getCasingTemperature()
    elseif (reactorVersion == "Bigger Reactors") then
        storedThisTick = reactor.battery().stored()
        lastRFT = reactor.battery().producedLastTick()
        capacity = reactor.battery().capacity()
        rod = reactor.getControlRod(0).level()
        fuelUsage = reactor.fuelTank().burnedLastTick() / 1000
        waste = reactor.fuelTank().waste()
        fuelTemp = reactor.fuelTemperature()
        caseTemp = reactor.casingTemperature()
    end
    rfLost = lastRFT + storedLastTick - storedThisTick
    -- Add the values to the arrays
    table.insert(storedThisTickValues, storedThisTick)
    table.insert(lastRFTValues, lastRFT)
    table.insert(rodValues, rod)
    table.insert(fuelUsageValues, fuelUsage)
    table.insert(wasteValues, waste)
    table.insert(fuelTempValues, fuelTemp)
    table.insert(caseTempValues, caseTemp)
    table.insert(rfLostValues, rfLost)

    local maxIterations = 20 * SECONDS_TO_AVERAGE
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
    averageStoredThisTick = calculateAverage(storedThisTickValues)
    averageLastRFT = calculateAverage(lastRFTValues)
    averageRod = calculateAverage(rodValues)
    averageFuelUsage = calculateAverage(fuelUsageValues)
    averageWaste = calculateAverage(wasteValues)
    averageFuelTemp = calculateAverage(fuelTempValues)
    averageCaseTemp = calculateAverage(caseTempValues)
    averageRfLost = calculateAverage(rfLostValues)
end

--Initialize variables from either a config file or the defaults
local function loadFromConfig()
    invalidDim = false
    local legacyConfigExists = fs.exists(tag..".txt")
    local newConfigExists = fs.exists(tag.."Serialized.txt")
    if (newConfigExists) then
        local file = fs.open(tag.."Serialized.txt", "r")
        print("Config file "..tag.."Serialized.txt found! Using configurated settings")

        local serialized = file.readAll()
        local deserialized = textutils.unserialise(serialized)
        
        maxb = deserialized.maxb
        minb = deserialized.minb
        rod = deserialized.rod
        btnOn = deserialized.btnOn
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
        maxb = tonumber(file.readLine())
        minb = tonumber(file.readLine())
        rod = tonumber(file.readLine())
        btnOn = file.readLine() == "true"

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

        maxb = 70
        minb = 30
        rod = 80
        btnOn = false
        if (monSide == nil) then
            btnOn = true
        end
        sizex, sizey = 100, 52
        dividerXCoord = sizex - 31
        oo = sizey - 37
        enableGraph("Energy Buffer")
        enableGraph("Control Level")
        enableGraph("Temperatures")
    end
    btnOff = not btnOn
    reactor.setActive(btnOn)
end

local function startTimer(ticksToUpdate, callback)
    local timeToUpdate = ticksToUpdate * 0.05
    local id = os.startTimer(timeToUpdate)
    local fun = function(event)
        if (event[1] == "timer" and event[2] == id) then
            id = os.startTimer(timeToUpdate)
            callback()
        end
    end
    return fun
end


-- Main loop, handles all the events
local function loop()
    local ticksToUpdateStats = 1
    local ticksToRedraw = 4
    
    local hasClicked = false

    local updateStatsTick = startTimer(
        ticksToUpdateStats,
        function()
            updateStats()
            updateRods()
        end
    )
    local redrawTick = startTimer(
        ticksToRedraw,
        function()
            if (not hasClicked) then
                resetMon()
                drawScene()
            end
            hasClicked = false
        end
    )
    local handleResize = function(event)
        if (event[1] == "monitor_resize") then
            local peripheralId = event[2]
            initMon()
        end
    end
    local handleClick = function(event)
        if (event[1] == "button_click") then
			t.buttonList[event[2]].func()
            saveToConfig()
            resetMon()
            drawScene()
            hasClicked = true
        end
    end
    while (true) do
        local event = { os.pullEvent() }

        if monSide ~= nil then
            event = { t:handleEvents(unpack(event)) }
        end

        updateStatsTick(event)
        redrawTick(event)
        handleResize(event)
        handleClick(event)
    end
end

local function detectReactor()
    -- Bigger Reactors V1.
    local reactor_bigger_v1 = getPeripheral("bigger-reactor")
    reactor = reactor_bigger_v1 ~= nil and peripheral.wrap(reactor_bigger_v1)
    if (reactor ~= nil) then
        reactorVersion = "Bigger Reactors"
        return true
    end

    -- Bigger Reactors V2
    local reactor_bigger_v2 = getPeripheral("BiggerReactors_Reactor")
    reactor = reactor_bigger_v2 ~= nil and peripheral.wrap(reactor_bigger_v2)
    if (reactor ~= nil) then
        reactorVersion = "Bigger Reactors"
        return true
    end

    -- Big Reactors or Extreme Reactors
    local reactor_extreme_or_big = getPeripheral("BigReactors-Reactor")
    reactor = reactor_extreme_or_big ~= nil and peripheral.wrap(reactor_extreme_or_big)
    if (reactor ~= nil) then
        reactorVersion = (reactor.mbIsConnected ~= nil) and "Extreme Reactors" or "Big Reactors"
        return true
    end
    return false
end

--Entry point
local function main()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)

    local reactorDetected = false
    while (not reactorDetected) do
        reactorDetected = detectReactor()
        if (not reactorDetected) then
            print("Reactor not detected! Trying again...")
            sleep(1)
        end
    end
    
    print("Reactor detected! Proceeding with initialization ")

    print("Loading config...")
    loadFromConfig()
    print("Initializing monitor if connected...")
    initMon()
    print("Writing config to disk...")
    saveToConfig()
    print("Reactor initialization done! Starting controller")
    sleep(2)

    term.clear()
    term.setCursorPos(1,1)
    print("Reactor Controller Version "..version)
    print("Reactor Mod: "..reactorVersion)
    --main loop

    loop()
end

main()

print("script exited")
sleep(1)