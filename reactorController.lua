local tag = "reactorConfig"
version = "0.42"
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
local reactorType
local mon, monSide, reactorSide
local sizex, sizey, dim, oo, offy
local btnOn, btnOff, invalidDim
local minb, maxb, minrod
local rod, rfLost
local storedLastTick, storedThisTick, lastRFT, maxRFT = 0,0,0,1
local fuelTemp, caseTemp, fuelUsage, waste, capacity = 0,0,0,0,0
local t
local displayingGraphMenu = false
local calibrated = false

--table of which graphs to draw
local graphsToDraw = {}

--table of all the graphs
local graphs = 
{
    "Energy Buffer",
    "Control Level",
    "Temperatures",
}

--marks the offsets for each graph position
local XOffs = 
{
    { 4, true}, 
    {27, true}, 
    {50, true}, 
    {73, true}, 
    {96, true},
}

--Draw a single point
local function drawPoint(x, y, color)
    if (monSide ~= nil) then
        local ix,iy = mon.getCursorPos()
        mon.setCursorPos(x,y)
        mon.setBackgroundColor(color)
        mon.write(" ")
        mon.setBackgroundColor(colors.black)
        mon.setCursorPos(ix,iy)
    end
end

--Draw a box with no fill
local function drawBox(size, xoff, yoff, color)
    if (monSide ~= nil) then
        local x,y = mon.getCursorPos()
        mon.setBackgroundColor(color)
        for i=0,size[1] - 1 do
            mon.setCursorPos(xoff + i + 1, yoff + 1)
            mon.write(" ")
            mon.setCursorPos(xoff + i + 1, yoff + size[2])
            mon.write(" ")
        end
        for i=0, size[2] - 1 do
            mon.setCursorPos(xoff + 1, yoff + i + 1)
            mon.write(" ")
            mon.setCursorPos(xoff + size[1], yoff + i +1)
            mon.write(" ")
        end
        mon.setCursorPos(x,y)
        mon.setBackgroundColor(colors.black)
    end
end

--Draw a filled box
local function drawFilledBox(size, xoff, yoff, colorOut, colorIn)
    if (monSide ~= nil) then
        local horizLine = ""
        for i=2, size[1] - 1 do
            horizLine  = horizLine.." "
        end
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
end

--Draws text on the screen
local function drawText(text, x1, y1, backColor, textColor)
    if (monSide ~= nil) then
        local x, y = mon.getCursorPos()
        mon.setCursorPos(x1, y1)
        mon.setBackgroundColor(backColor)
        mon.setTextColor(textColor)
        mon.write(text)
        mon.setTextColor(colors.white)
        mon.setBackgroundColor(colors.black)
        mon.setCursorPos(x,y)
    end
end

--Helper method for adding buttons
local function addButt(name, callBack, size, xoff, yoff, color1, color2)
    if (monSide ~= nil) then
        t:add(name, callBack, 
            xoff + 1, yoff + 1, 
            size[1] + xoff, size[2] + yoff, 
            color1, color2)	
    end
end

--adds buttons
local function addButtons()
    if (sizey == 24) then
        oo = 1
    end
    addButt("On", nil, {8, 3}, dim + 7, 3 + oo,
        colors.red, colors.lime)
    addButt("Off", nil, {8, 3}, dim + 19, 3 + oo,
        colors.red, colors.lime)
    if (btnOn) then
        t:toggleButton("On")
    else
        t:toggleButton("Off")
    end
    if (sizey > 24) then
        addButt("+ 10", nil, {8, 3}, dim + 7, 14 + oo,
            colors.purple, colors.pink)
        addButt(" + 10 ", nil, {8, 3}, dim + 19, 14 + oo,
            colors.magenta, colors.pink)
        addButt("- 10", nil, {8, 3}, dim + 7, 18 + oo,
            colors.purple, colors.pink)
        addButt(" - 10 ", nil, {8, 3}, dim + 19, 18 + oo,
            colors.magenta, colors.pink)
    end
end

--Resets the monitor
local function resetMon()
    if (monSide ~= nil) then
        mon.setBackgroundColor(colors.black)
        mon.clear()
        mon.setTextScale(0.5)
        mon.setCursorPos(1,1)
    end
end

local function getPercPower()
    return storedThisTick / capacity * 100
end

local function rnd(num, dig)
    return math.floor(10 ^ dig * num) / (10 ^ dig)
end

local function getEfficiency()
    return lastRFT / fuelUsage
end

local function getGenRatio()
    return lastRFT / capacity
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

local function disableGraph(name)
    if (graphsToDraw[name] ~= nil) then
        if (displayingGraphMenu) then
            t:toggleButton(name)
        end
        getXOff(graphsToDraw[name])[2] = true
        graphsToDraw[name] = nil
    end
end

local function addGraphButtons()
    offy = oo - 14
    for i,v in pairs(graphs) do
        addButt(v, nil, {20, 3},
            dim + 7, offy + i * 3 - 1,
            colors.red, colors.lime)
        if (graphsToDraw[v] ~= nil) then
            t:toggleButton(v)
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

local function isGraph(name)
    for i,v in pairs(graphs) do
        if (v == name) then
            return true
        end
    end
    return false
end

local function getGraph(num)
    for i,v in pairs(graphsToDraw) do
        if (v == num) then
            return i
        end
    end
    return nil
end

local function enableGraph(name)
    if (graphsToDraw[name] == nil) then
        local e = getAvailableXOff()
        if (e ~= -1) then
            graphsToDraw[name] = e
            if (displayingGraphMenu) then
                t:toggleButton(name)
            end
        end
    end
end

local function toggleGraph(name)
    if (graphsToDraw[name] == nil) then
        enableGraph(name)
    else
        disableGraph(name)
    end
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
    drawText(format(storedThisTick).."RF", off + 1, srf + 5 - pwr,
        pwr > 0 and color or colors.red, colors.black)
end

local function drawControlLevel(xoff)
    local srf = sizey - 9
    local off = xoff
    drawBox({15, srf + 2}, off - 1, 4, colors.gray)
    drawFilledBox({13, srf}, off, 5,
        colors.red, colors.red)
    local rodTr = math.floor(rod / 100 
        * (srf))
    drawText("Control Level", off + 1, 4,
        colors.black, colors.orange)
    if (rodTr > 0) then
        drawFilledBox({9, rodTr}, off + 2, 5,
            colors.orange, colors.orange)
    end
    drawText(string.format("%6.2f%%", rod), off + 4, rodTr > 0 and rodTr + 5 or 6,
        rodTr > 0 and colors.orange or colors.red, colors.black)

end

local function drawTemperatures(xoff)
    local srf = sizey - 9
    local off = xoff
    drawBox({15, srf + 2}, off, 4, colors.gray)
    --drawFilledBox({12, srf}, off, 5,
    --	colors.red, colors.red)

    local fuelRnd = math.floor(fuelTemp)
    local caseRnd = math.floor(caseTemp)
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

        drawText(string.format("%4sC", fuelRnd..""), 
            off + 10, srf + 6 - fuelTr,
            colors.magenta, colors.black)
    else
        drawText(string.format("%4sC", fuelRnd..""), 
            off + 10, srf + 5,
            colors.black, colors.magenta)
    end

    if (caseTr > 0) then
        caseTr = math.min(caseTr, srf)
        drawFilledBox({6, caseTr}, off + 1, srf + 5 - caseTr,
            colors.lightBlue, colors.lightBlue)
        drawText(string.format("%4sC", caseRnd..""), 
            off + 3, srf + 6 - caseTr,
            colors.lightBlue, colors.black)
    else
        drawText(string.format("%4sC", caseRnd..""), 
            off + 3, srf + 5,
            colors.black, colors.lightBlue)
    end

    drawText("Temperatures", off + 2, 4,
        colors.black, colors.orange)
    drawBox({1, srf}, off + 7, 5,
        colors.gray)
end

local beg
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
    if (dim > -1) then
        drawBox({dim, sizey - 2},
            1, 1, colors.lightBlue)
        drawText(" Reactor Graphs ", dim - 18, 2, 
            colors.black, colors.lightBlue)
        drawGraphs()
    end
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
    else
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
end

local function drawStatistics()
    local oS = sizey - 13
    drawBox({sizex - dim - 3, sizey - oS - 1}, dim + 2, oS,
        colors.blue)
    drawText(" Reactor Statistics ", dim + 7, oS + 1,
        colors.black, colors.blue)

    --statistics
    drawText("Generating : "
        ..format(lastRFT).."RF/t", dim + 5, oS + 3,
        colors.black, colors.green)
    drawText("RF Drain   "
        ..(storedThisTick <= lastRFT and "> " or ": ")
        ..format(rfLost)
        .."RF/t", dim + 5, oS + 5,
        colors.black, colors.red)
    drawText("Efficiency : "
        ..format(getEfficiency()).."RF/B", 
        dim + 5, oS + 7,
        colors.black, colors.green)
    drawText("Fuel Usage : "
        ..format(fuelUsage)
        .."B/t", dim + 5, oS + 9,
        colors.black, colors.green)
    drawText("Waste      : "
        ..string.format("%7d mB", waste),
        dim + 5, oS + 11,
        colors.black, colors.green)
end

--Draw a scene
local function drawScene()
    if (monSide ~= nil) then
        t:draw()
    end
    if (displayingGraphMenu) then
        drawGraphButtons()
    end
    if (invalidDim) then
        if (monSide ~= nil) then
            mon.write("Invalid Monitor Dimensions")
        end
    else
        drawControls()
        drawStatus()
        drawStatistics()
    end
end

--Redraws all the buttons
--Updates the important values
local function reDrawButtons()
    if (monSide ~= nil) then
        t = touchpoint.new(monSide)
        sizex, sizey = mon.getSize()
        oo = sizey - 37
        dim = sizex - 33
    end
    --print(sizex, sizey)
    if (sizex == 36) then
        dim = -1
    end
    if (pcall(addGraphButtons)) then
        drawGraphButtons()
        displayingGraphMenu = true
    else
        if (monSide ~= nil) then
            t = touchpoint.new(monSide)
        end
        displayingGraphMenu = false
    end
    local rtn = pcall(addButtons)
    if (not rtn) then
        if (monSide ~= nil) then
            t = touchpoint.new(monSide)
        end
        invalidDim = true
    else
        invalidDim = false
    end
    --t:draw()
end

local function setRods(level)
    if (reactorVersion == "Big Reactors") then
        reactor.setAllControlRodLevels(level)
    elseif (reactorVersion == "Bigger Reactors") then
        reactor.setAllControlRodLevels(level)
    elseif (reactorVersion == "Extreme Reactors") then
        for i in pairs(reactor.getControlRodsLevels()) do
            reactor.setControlRodLevel(i, level)
        end
    end
end

--Turns off the reactor
local function turnOff()
    if (btnOn) then
        t:toggleButton("Off")
        t:toggleButton("On")
        btnOff = true
        btnOn = false
        setRods(100)
        reactor.setActive(false)
    end
end

--Turns on the reactor
local function turnOn()
    if (btnOff) then
        t:toggleButton("Off")
        t:toggleButton("On")
        btnOff = false
        btnOn = true
        reactor.setActive(true)
    end
end

--adjusts the level of the rods
local function adjustRods()
    local currentRF = storedThisTick
    local diffb = maxb - minb
    maxRF = maxb / 100 * capacity
    minRF = minb / 100 * capacity
    diffRF = diffb / 100 * capacity
    local diffr = diffb / 100
    local targetRFT = rfLost
    local currentRFT = lastRFT
    local diffRFT = currentRFT/targetRFT
    local targetRF = diffRF / 2 + minRF

    currentRF = math.min(currentRF, maxRF)
    local equation1 = math.min((currentRF - minRF)/diffRF, 1)
    equation1 = math.max(equation1, 0)
    
	local rodLevel = rod
    if (storedThisTick < minRF) then
        rodLevel = 0
    elseif ((storedThisTick < maxRF and storedThisTick > minRF)) then
        equation1 = equation1 * (currentRF / targetRF) --^ 2
        equation1 = equation1 * diffRFT --^ 5
        equation1 = equation1 * 100

        rodLevel = equation1
    elseif (storedThisTick > maxRF) then
        rodLevel = 100
    end
    setRods(rodLevel)
end

--Saves the configuration of the reactor controller
local function saveChanges()
    local file = fs.open(tag..".txt", "w")
    file.writeLine(calibrated)
    if (calibrated) then
        file.writeLine(capacity)
        file.writeLine(maxRFT)
    end
    file.writeLine(maxb)
    file.writeLine(minb)
    file.writeLine(rod)
    file.writeLine(btnOn)
    for i,v in pairs(XOffs) do
        local graph = getGraph(v[1])
        graph = (graph == nil and "nil" or graph)
        file.writeLine(graph)
        file.writeLine(v[1])
    end
    file.close()
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
end

--Updates statistics and adjusts the rods
local function compute()
    updateStats()
    if (btnOn) then
        adjustRods()
    end
end

--The main routine that runs each tick
function routine()
    while (true) do
        --[[
        If the graphs are drawn every tick, everything
        just breaks.
        If the graphs are drawn every 2nd tick, my
        RFLost calculation is wrong every time
        If the graphs are drawn every 3rd tick, my
        RFLost calculation is wrong sometimes

        THIS MAKES NO SENSE
        ]]
        for i = 1,4 do	
            compute()
            sleep(0.01)
        end
        resetMon()
        drawScene()
    end
end

--Manages window resizing events
function resizer()
    while (true) do
        local event = os.pullEvent("monitor_resize")
        if (event == "monitor_resize") then
            reDrawButtons()
        end
    end
end

local function calibrate()
    setRods(0)
    reactor.setActive(true)
    sleep(15)
    updateStats()
    setRods(100)
    reactor.setActive(false)
    if (reactorVersion == "Big Reactors") then
        capacity = storedThisTick
    end
    maxRFT = lastRFT
end

--Initialize variables from either a config file or the defaults
local function initializeVars()
    invalidDim = false
    if (not fs.exists(tag..".txt")) then
        print("Config file "..tag.." not found, generating a default one!")
        repeat
            print("The program can be optionally calibrated. Proceed? (y/n) ")
            local response = read()
            if (response == "n") then
                print("Calibration skipped. Some functions may be unavailable")
                calbrated = false
            elseif (response == "y") then
                print("Beginning 15 second calibration, do not turn off the reactor!")
                calibrate()
                print("Calibrated!")
                calibrated = true
            end
        until response == "y" or response == "n"
        
        maxb = 70
        minb = 30
        rod = 80
        btnOn = false
        if (monSide == nil) then
            btnOn = true
        end
        dim = sizex - 33
        oo = sizey - 37
        enableGraph("Energy Buffer")
        enableGraph("Control Level")
        enableGraph("Temperatures")
    else
        local file = fs.open(tag..".txt", "r")
        print("Config file "..tag.." found! Using configurated settings")

        calibrated = file.readLine() == "true"
        
        --read calibration information
        if (calibrated) then
        	capacity = tonumber(file.readLine())
        	maxRFT = tonumber(file.readLine())
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
    end
    btnOff = not btnOn
    diffb = maxb - minb
    reactor.setActive(btnOn)
end

--Initialize program
local function initialize()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    os.loadAPI("/usr/apis/touchpoint.lua")
    reactorSide = getPeripheral("BiggerReactors_Reactor")
    reactorVersion = "Bigger Reactors"
    reactor = peripheral.wrap(reactorSide)
    if (reactor == nil) then
        reactorSide = getPeripheral("BigReactors-Reactor")
        reactor = peripheral.wrap(reactorSide)
        if (reactor.mbIsConnected ~= nil) then
            reactorVersion = "Extreme Reactors"
        else
            reactorVersion = "Big Reactors"
        end
    end
    if (reactor == nil) then
        reactorSide = getPeripheral("bigger-reactor")
        reactor = peripheral.wrap(reactorSide)
		reactorVersion = "Big Reactors"
    end
    monSide = getPeripheral("monitor")
    monSide = monSide == "" and nil or monSide
    sizex, sizey = 36, 38
    if (monSide ~= nil) then
        mon = peripheral.wrap(monSide)
        sizex, sizey = mon.getSize()
        resetMon()
    end
    return reactor ~= nil
end

--Entry point
function threadMain()
    repeat 
        local good = initialize()
        if (not good) then
            print("Reactor could not be detected! Trying again")
            sleep(1)
        else
            print("Reactor detected! Proceeding with initialization: ")
        end
    until (good)
    initializeVars()
    reDrawButtons()
    saveChanges()
    print("Reactor initialization done!")
	sleep(2)
    term.clear()
    term.setCursorPos(1,1)
    os.startThread(resizer)
    os.startThread(routine)
    print("Reactor Controller Version "..version)
    print("Reactor Mod: "..reactorVersion)
    --main loop
    --local lastTime = 0

    os.startTimer(0.01)
    while (true) do
        local event, p1
        if (monSide ~= nil) then
            event, p1 = t:handleEvents(os.pullEvent("monitor_touch"))
        else
            event = os.pullEvent("monitor_touch")
        end
        if (event == "button_click") then
            if (p1 == "Off") then
                turnOff()
            elseif (p1 == "On") then
                turnOn()
            elseif (p1 == "+ 10") then
                minb = math.min(maxb - 10, minb + 10)
            elseif (p1 == "- 10") then
                minb = math.max(0, minb - 10)
            elseif (p1 == " + 10 ") then
                maxb = math.min(100, maxb + 10)
            elseif (p1 == " - 10 ") then
                maxb = math.max(minb + 10, maxb - 10)
            elseif (isGraph(p1)) then
                toggleGraph(p1)
            end
            saveChanges()
        end
    end
end

--thread stuff below here
local threads = {}
local starting = {}
local eventFilter = nil

rawset(os, "startThread", function(fn, blockTerminate)
        table.insert(starting, {
                cr = coroutine.create(fn),
                blockTerminate = blockTerminate or false,
                error = nil,
                dead = false,
                filter = nil
            })
    end)

local function tick(t, evt, ...)
    if t.dead then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == "terminate" and t.blockTerminate then return end

    coroutine.resume(t.cr, evt, ...)
    t.dead = (coroutine.status(t.cr) == "dead")
end

local function tickAll()
    if #starting > 0 then
        local clone = starting
        starting = {}
        for _,v in ipairs(clone) do
            tick(v)
            table.insert(threads, v)
        end
    end
    local e
    if eventFilter then
        e = {eventFilter(coroutine.yield())}
    else
        e = {coroutine.yield()}
    end
    local dead = nil
    for k,v in ipairs(threads) do
        tick(v, unpack(e))
        if v.dead then
            if dead == nil then dead = {} end
            table.insert(dead, k - #dead)
        end
    end
    if dead ~= nil then
        for _,v in ipairs(dead) do
            table.remove(threads, v)
        end
    end
end

rawset(os, "setGlobalEventFilter", function(fn)
        if eventFilter ~= nil then error("This can only be set once!") end
        eventFilter = fn
        rawset(os, "setGlobalEventFilter", nil)
    end)

if type(threadMain) == "function" then
    os.startThread(threadMain)
else
    os.startThread(function() shell.run("shell") end)
end

while #threads > 0 or #starting > 0 do
    tickAll()
end

print("All threads terminated!")
print("Exiting thread manager")
