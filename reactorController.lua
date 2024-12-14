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

local reactorVersion, reactor
local mon, monSide
local sizex, sizey, dim, oo, offy
local btnOn, btnOff, invalidDim
local minb, maxb
local rod, rfLost
local storedLastTick, storedThisTick, lastRFT = 0,0,0
local fuelTemp, caseTemp, fuelUsage, waste, capacity = 0,0,0,0,1
local t
local displayingGraphMenu = false

local secondsToAverage = 2

local averageStoredThisTick = 0
local averageLastRFT = 0
local averageRod = 0
local averageFuelUsage = 0
local averageWaste = 0
local averageFuelTemp = 0
local averageCaseTemp = 0
local averageRfLost = 0

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

-- Draw a box with no fill
local function drawBox(size, xoff, yoff, color)
    if (monSide == nil) then
        return
    end
    local x,y = mon.getCursorPos()
    mon.setBackgroundColor(color)
    local horizLine = string.rep(" ", size[1])
    mon.setCursorPos(xoff + 1, yoff + 1)
    mon.write(horizLine)
    mon.setCursorPos(xoff + 1, yoff + size[2])
    mon.write(horizLine)

    -- Draw vertical lines
    for i=0, size[2] - 1 do
        mon.setCursorPos(xoff + 1, yoff + i + 1)
        mon.write(" ")
        mon.setCursorPos(xoff + size[1], yoff + i +1)
        mon.write(" ")
    end
    mon.setCursorPos(x,y)
    mon.setBackgroundColor(colors.black)
end

--Draw a filled box
local function drawFilledBox(size, xoff, yoff, colorOut, colorIn)
    if (monSide == nil) then
        return
    end
    local horizLine = string.rep(" ", size[1] - 2)
    drawBox(size, xoff, yoff, colorOut)
    local x,y = mon.getCursorPos()
    mon.setBackgroundColor(colorIn)
    for i=2, size[2] - 1 do
        mon.setCursorPos(xoff + 2, yoff + i)
        mon.write(horizLine)
    end
    mon.setBackgroundColor(colors.black)
    mon.setCursorPos(x,y)
end

--Draws text on the screen
local function drawText(text, x1, y1, backColor, textColor)
    if (monSide == nil) then
        return
    end
    local x, y = mon.getCursorPos()
    mon.setCursorPos(x1, y1)
    mon.setBackgroundColor(backColor)
    mon.setTextColor(textColor)
    mon.write(text)
    mon.setTextColor(colors.white)
    mon.setBackgroundColor(colors.black)
    mon.setCursorPos(x,y)
end

--Helper method for adding buttons
local function addButt(name, callBack, size, xoff, yoff, color1, color2)
    t:add(name, callBack,
            xoff + 1, yoff + 1,
            size[1] + xoff, size[2] + yoff,
            color1, color2)
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
    addButt("On", turnOn, {8, 3}, dim + 7, 3 + oo,
            colors.red, colors.lime)
    addButt("Off", turnOff, {8, 3}, dim + 19, 3 + oo,
            colors.red, colors.lime)
    if (btnOn) then
        t:toggleButton("On", true)
    else
        t:toggleButton("Off", true)
    end
    if (sizey > 24) then
        addButt("+ 10", minAdd10, {8, 3}, dim + 7, 14 + oo,
                colors.purple, colors.pink)
        addButt(" + 10 ", maxAdd10, {8, 3}, dim + 19, 14 + oo,
                colors.magenta, colors.pink)
        addButt("- 10", minSub10, {8, 3}, dim + 7, 18 + oo,
                colors.purple, colors.pink)
        addButt(" - 10 ", maxSub10, {8, 3}, dim + 19, 18 + oo,
                colors.magenta, colors.pink)
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
        if (v[2] and v[1] < dim) then
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
    for i,v in pairs(graphs) do
        addButt(v, function() toggleGraph(v) end, {20, 3},
                dim + 7, offy + i * 3 - 1,
                colors.red, colors.lime)
        if (graphsToDraw[v] ~= nil) then
            t:toggleButton(v, true)
        end
    end
end

local function drawGraphButtons()
    drawBox({sizex - dim - 3, oo - offy - 1},
            dim + 2, offy, colors.orange)
    drawText(" Graph Controls ",
            dim + 7, offy + 1,
            colors.black, colors.orange)
end

local function drawEnergyBuffer(xoff)
    local srf = sizey - 9
    local off = xoff
    local right = off + 19 < dim
    local poff = right and off + 15 or off - 6

    drawBox({15, srf + 2}, off - 1, 4, colors.gray)
    local pwr = math.floor(getPercPower() / 100
            * (srf))
    drawFilledBox({13, srf}, off, 5,
            colors.red, colors.red)
    local rndpw = rnd(getPercPower(), 2)
    local color = (rndpw < maxb and rndpw > minb) and colors.green
            or (rndpw >= maxb and colors.orange or colors.blue)
    if (pwr > 0) then
        drawFilledBox({13, pwr + 1}, off, srf + 4 - pwr,
                color, color)
    end
    --drawPoint(off + 14, srf + 5 - pwr, pwr > 0 and color or colors.red)
    drawText(string.format(right and "%.2f%%" or "%5.2f%%", rndpw), poff, srf + 5 - pwr,
            colors.black, color)
    drawText("Energy Buffer", off + 1, 4,
            colors.black, colors.orange)
    drawText(format(averageStoredThisTick).."RF", off + 1, srf + 5 - pwr,
            pwr > 0 and color or colors.red, colors.black)
end

local function drawControlLevel(xoff)
    local srf = sizey - 9
    local off = xoff
    drawBox({15, srf + 2}, off - 1, 4, colors.gray)
    drawFilledBox({13, srf}, off, 5,
            colors.yellow, colors.yellow)
    local rodTr = math.floor(averageRod / 100
            * (srf))
    drawText("Control Level", off + 1, 4,
            colors.black, colors.orange)
    if (rodTr > 0) then
        drawFilledBox({9, rodTr}, off + 2, 5,
                colors.white, colors.white)
    end
    drawText(string.format("%6.2f%%", averageRod), off + 4, rodTr > 0 and rodTr + 5 or 6,
            rodTr > 0 and colors.white or colors.yellow, colors.black)

end

local function drawTemperatures(xoff)
    local srf = sizey - 9
    local off = xoff
    drawBox({15, srf + 2}, off, 4, colors.gray)
    --drawFilledBox({12, srf}, off, 5,
    --	colors.red, colors.red)

    local tempUnit = (reactorVersion == "Bigger Reactors") and "K" or "C"
    local tempFormat = "%4s"..tempUnit

    local fuelRnd = math.floor(averageFuelTemp)
    local caseRnd = math.floor(averageCaseTemp)
    local fuelTr = math.floor(fuelRnd / 2000
            * (srf))
    local caseTr = math.floor(caseRnd / 2000
            * (srf))
    drawText(" Case ", off + 2, 5,
            colors.gray, colors.lightBlue)
    drawText(" Fuel ", off + 9, 5,
            colors.gray, colors.magenta)
    if (fuelTr > 0) then
        fuelTr = math.min(fuelTr, srf)
        drawFilledBox({6, fuelTr}, off + 8, srf + 5 - fuelTr,
                colors.magenta, colors.magenta)

        drawText(string.format(tempFormat, fuelRnd..""),
                off + 10, srf + 6 - fuelTr,
                colors.magenta, colors.black)
    else
        drawText(string.format(tempFormat, fuelRnd..""),
                off + 10, srf + 5,
                colors.black, colors.magenta)
    end

    if (caseTr > 0) then
        caseTr = math.min(caseTr, srf)
        drawFilledBox({6, caseTr}, off + 1, srf + 5 - caseTr,
                colors.lightBlue, colors.lightBlue)
        drawText(string.format(tempFormat, caseRnd..""),
                off + 3, srf + 6 - caseTr,
                colors.lightBlue, colors.black)
    else
        drawText(string.format(tempFormat, caseRnd..""),
                off + 3, srf + 5,
                colors.black, colors.lightBlue)
    end

    drawText("Temperatures", off + 2, 4,
            colors.black, colors.orange)
    drawBox({1, srf}, off + 7, 5,
            colors.gray)
end

local function drawGraph(name, offset)
    if (name == "Energy Buffer") then
        drawEnergyBuffer(offset)
    elseif (name == "Control Level") then
        drawControlLevel(offset)
    elseif (name == "Temperatures") then
        drawTemperatures(offset)
    end
end

local function drawGraphs()
    for i,v in pairs(graphsToDraw) do
        if (v + 15 < dim) then
            drawGraph(i,v)
        end
    end
end

local function drawStatus()
    if (dim <= -1) then
        return
    end
    drawBox({dim, sizey - 2},
            1, 1, colors.lightBlue)
    drawText(" Reactor Graphs ", dim - 18, 2,
            colors.black, colors.lightBlue)
    drawGraphs()
end

local function drawControls()
    if (sizey == 24) then
        drawBox({sizex - dim - 3, 9}, dim + 2, oo,
                colors.cyan)
        drawText(" Reactor Controls ", dim + 7, oo + 1,
                colors.black, colors.cyan)
        drawText("Reactor "..(btnOn and "Online" or "Offline"),
                dim + 10, 3 + oo,
                colors.black, btnOn and colors.green or colors.red)
        return
    end

    drawBox({sizex - dim - 3, 23}, dim + 2, oo,
            colors.cyan)
    drawText(" Reactor Controls ", dim + 7, oo + 1,
            colors.black, colors.cyan)
    drawFilledBox({20, 3}, dim + 7, 8 + oo,
            colors.red, colors.red)
    drawFilledBox({(maxb - minb) / 5, 3},
            dim + 7 + minb / 5, 8 + oo,
            colors.green, colors.green)
    drawText(string.format("%3s", minb.."%"), dim + 6 + minb / 5, 12 + oo,
            colors.black, colors.purple)
    drawText(maxb.."%", dim + 8 + maxb / 5, 12 + oo,
            colors.black, colors.magenta)
    drawText("Buffer Target Range", dim + 8, 8 + oo,
            colors.black, colors.orange)
    drawText("Min", dim + 10, 14 + oo,
            colors.black, colors.purple)
    drawText("Max", dim + 22, 14 + oo,
            colors.black, colors.magenta)
    drawText("Reactor ".. (btnOn and "Online" or "Offline"),
            dim + 10, 3 + oo,
            colors.black, btnOn and colors.green or colors.red)
end

local function drawStatistics()
    local oS = sizey - 13
    drawBox({sizex - dim - 3, sizey - oS - 1}, dim + 2, oS,
            colors.blue)
    drawText(" Reactor Statistics ", dim + 7, oS + 1,
            colors.black, colors.blue)

    --statistics
    drawText("Generating : "
            ..format(averageLastRFT).."RF/t", dim + 5, oS + 3,
            colors.black, colors.green)
    drawText("RF Drain   "
            ..(averageStoredThisTick <= averageLastRFT and "> " or ": ")
            ..format(averageRfLost)
            .."RF/t", dim + 5, oS + 5,
            colors.black, colors.red)
    drawText("Efficiency : "
            ..format(getEfficiency()).."RF/B",
            dim + 5, oS + 7,
            colors.black, colors.green)
    drawText("Fuel Usage : "
            ..format(averageFuelUsage)
            .."B/t", dim + 5, oS + 9,
            colors.black, colors.green)
    drawText("Waste      : "
            ..string.format("%7d mB", waste),
            dim + 5, oS + 11,
            colors.black, colors.green)
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

    if (displayingGraphMenu) then
        drawGraphButtons()
    end
    drawControls()
    drawStatus()
    drawStatistics()
    t:draw()
end

--returns the side that a given peripheral type is connected to
local function getPeripheral(name)
    for i,v in pairs(peripheral.getNames()) do
        if (peripheral.getType(v) == name) then
            return v
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

    mon = peripheral.wrap(monSide)

    if mon == nil then
        monSide = nil
        return
    end

    resetMon()
    t = touchpoint.new(monSide)
    sizex, sizey = mon.getSize()
    oo = sizey - 37
    dim = sizex - 33

    if (sizex == 36) then
        dim = -1
    end
    if (pcall(addGraphButtons)) then
        displayingGraphMenu = true
    else
        t = touchpoint.new(monSide)
        displayingGraphMenu = false
    end
    local rtn = pcall(addButtons)
    if (not rtn) then
        t = touchpoint.new(monSide)
        invalidDim = true
    else
        invalidDim = false
    end
end

local function setRods(level)
    level = math.max(level, 0)
    level = math.min(level, 100)
    reactor.setAllControlRodLevels(level)
end

local function lerp(start, finish, t)
    -- Ensure t is in the range [0, 1]
    t = math.max(0, math.min(1, t))

    -- Calculate the linear interpolation
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

    local maxIterations = 20 * secondsToAverage
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
        dim = sizex - 33
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
        local event = (monSide == nil) and { os.pullEvent() } or { t:handleEvents() }

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
