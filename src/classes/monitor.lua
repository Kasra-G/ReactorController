_G.MONITOR_CONSTANTS = {
    MINIMUM_DIVIDER_X_VALUE = 3,
    MINIMUM_DIVIDER_Y_VALUE = 1,
}

-- table of which graphs to draw

---@type table<string>
local graphs =
{
    "Energy Buffer",
    "Control Level",
    "Temperatures",
}

local function round(num, dig)
    return math.floor(10 ^ dig * num + 0.5) / (10 ^ dig)
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

local function getPercPower()
    return _G.averageStoredThisTick / _G.capacity * 100
end

local function getEfficiency()
    return _G.averageLastRFT / _G.averageFuelUsage
end

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
    _G.minb = math.min(_G.maxb - 10, _G.minb + 10)
end
local function minSub10()
    _G.minb = math.max(0, _G.minb - 10)
end
local function maxAdd10()
    _G.maxb = math.min(100, _G.maxb + 10)
end
local function maxSub10()
    _G.maxb = math.max(_G.minb + 10, _G.maxb - 10)
end

local function turnOff()
    if (_G.btnOn) then
        _G.btnOff = true
        _G.btnOn = false
        _G.reactor.setActive(false)
    end
end

local function turnOn()
    if (_G.btnOff) then
        _G.btnOff = false
        _G.btnOn = true
        _G.reactor.setActive(true)
    end
end

--adds buttons
local function addReactorControlButtons(touch, offset, shouldDrawBufferVisualization)
    local buttonSize = Vector2.new(8, 3)
    local offsetOnOff = offset + Vector2.new(5, 3)

    addButton(touch, "On", turnOn, offsetOnOff, buttonSize, colors.red, colors.lime)
    addButton(touch, "Off", turnOff, offsetOnOff + Vector2.new(12, 0), buttonSize, colors.red, colors.lime)
    if shouldDrawBufferVisualization then
        addButton(touch, "+ 10", minAdd10, offset + Vector2.new(5, 14), buttonSize, colors.purple, colors.pink)
        addButton(touch, " + 10 ", maxAdd10, offset + Vector2.new(17, 14), buttonSize, colors.magenta, colors.pink)
        addButton(touch, "- 10", minSub10, offset + Vector2.new(5, 18), buttonSize, colors.purple, colors.pink)
        addButton(touch, " - 10 ", maxSub10, offset + Vector2.new(17, 18), buttonSize, colors.magenta, colors.pink)
    end
end

local GRAPH_SEPARATION_X = 23
local GRAPH_FIRST_OFFSET_X = 4

local function getFirstAvailableGraphSlot(graphSlots)
    local offset = GRAPH_FIRST_OFFSET_X
    while graphSlots[offset] ~= nil do
        offset = offset + GRAPH_SEPARATION_X
    end
    return offset
end

local function getGraphXCoord(graphSlots, name)
    for xCoord, graph in pairs(graphSlots) do
        if graph.name == name then
            return xCoord
        end
    end
    return -1
end

local function createGraph(name)
    return {name = name}
end

local function enableGraph(graphSlots, name)
    if getGraphXCoord(graphSlots, name) > -1 then
        return
    end

    local slotXCoord = getFirstAvailableGraphSlot(graphSlots)

    graphSlots[slotXCoord] = createGraph(name)
end

local function disableGraph(graphSlots, name)
    local graphXSlot = getGraphXCoord(graphSlots, name)

    graphSlots[graphXSlot] = nil
end

local function toggleGraph(graphSlots, name)

    local graphSlotX = getGraphXCoord(graphSlots, name)
    if graphSlotX == -1 then
        enableGraph(graphSlots, name)
    else
        disableGraph(graphSlots, name)
    end
end

---comment
---@param monitor Monitor
local function addGraphButtons(monitor, graphSlots, offset, size)
    for i, graphName in pairs(graphs) do
        addButton(
            monitor.touch,
            graphName,
            function()
                toggleGraph(graphSlots, graphName)
            end,
            offset + Vector2.new(0, i * 3 - 1),
            size,
            colors.red,
            colors.lime
        )
    end
end


local function drawGraphButtons(mon, offset, size)
    DrawUtil.drawBox(mon, colors.orange, offset, size)
    local textPos = offset + Vector2.new(4, 0)
    DrawUtil.drawText(mon, " Graph Controls ", textPos, colors.black, colors.orange
    )
end

local function drawEnergyBuffer(mon, offset, graphSize, drawPercentLabelOnRight)
    DrawUtil.drawText(mon, "Energy Buffer", offset, colors.black, colors.orange)
    DrawUtil.drawFilledBoxWithBorder(mon, colors.red, colors.gray, offset + Vector2.new(0, 1), graphSize)

    local energyBufferMaxHeight = graphSize.y - 2
    local unitEnergyLevel = getPercPower() / 100
    local energyBufferHeight = math.floor(unitEnergyLevel * energyBufferMaxHeight + 0.5)
    local rndpw = round(getPercPower(), 2)

    local energyBufferColor
    if rndpw < _G.maxb and rndpw > _G.minb then
        energyBufferColor = colors.green
    elseif rndpw >= _G.maxb then
        energyBufferColor = colors.orange
    elseif rndpw <= _G.minb then
        energyBufferColor = colors.blue
    end

    local energyBufferTipOffset = offset + Vector2.new(1, 2 + energyBufferMaxHeight - energyBufferHeight)
    local energyBufferSize = Vector2.new(graphSize.x - 2, energyBufferHeight)

    DrawUtil.drawFilledBox(mon, energyBufferColor, energyBufferTipOffset, energyBufferSize)

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
        format(_G.averageStoredThisTick).."RF",
        energyBufferTextOffset,
        rfLabelBackgroundColor,
        colors.black
    )
end

local function drawControlGraph(mon, offset, size, averageRod)
    local unitRodLevel = averageRod / 100
    local controlRodMaxPixelHeight = size.y - 2
    local controlRodPixelHeight = math.ceil(unitRodLevel * controlRodMaxPixelHeight)

    DrawUtil.drawText(mon, "Control Level", offset + Vector2.new(1, 0), colors.black, colors.orange)
    DrawUtil.drawFilledBoxWithBorder(mon, colors.yellow, colors.gray, offset + Vector2.new(0, 1), size)
    DrawUtil.drawFilledBox(mon, colors.white, offset + Vector2.new(3, 2), Vector2.new(9, controlRodPixelHeight))

    local controlRodLevelTextPos, color
    if controlRodPixelHeight > 0 then
        color = colors.white
        controlRodLevelTextPos = offset + Vector2.new(4, 1 + controlRodPixelHeight)
    else
        color = colors.yellow
        controlRodLevelTextPos = offset + Vector2.new(4, 2)
    end

    DrawUtil.drawText(mon, string.format("%6.2f%%", averageRod), controlRodLevelTextPos, color, colors.black)
end

local function drawTemperatures(mon, offset, size)

    DrawUtil.drawFilledBoxWithBorder(mon, colors.black, colors.gray, offset + Vector2.new(1, 1), size)

    local CASE_TEMP_COLOR = colors.lightBlue
    local FUEL_TEMP_COLOR = colors.magenta
    local BACKGROUND_COLOR = colors.black

    local assumedMaxCaseTemperature = 3000
    local assumedMaxFuelTemperature = 3000
    local temperatureMaxHeight = size.y - 2

    local tempUnit = (_G.reactorVersion == "Bigger Reactors") and "K" or "C"
    local tempFormat = "%4s"..tempUnit

    DrawUtil.drawText(mon, "Temperatures", offset + Vector2.new(2, 0), BACKGROUND_COLOR, colors.orange)
    DrawUtil.drawFilledBox(mon, colors.gray, offset + Vector2.new(8, 2), Vector2.new(1, temperatureMaxHeight))

    -- case temp
    DrawUtil.drawText(mon, "Case", offset + Vector2.new(3, 1), colors.gray, colors.lightBlue)
    local caseUnit = math.min(_G.averageCaseTemp / assumedMaxCaseTemperature, 1)
    local caseTempHeight = math.floor(caseUnit * temperatureMaxHeight + 0.5)

    local caseTempOffset = offset + Vector2.new(2, 2 + temperatureMaxHeight - caseTempHeight)
    local caseTempSize = Vector2.new(6, caseTempHeight)

    DrawUtil.drawFilledBox(mon, CASE_TEMP_COLOR, caseTempOffset, caseTempSize)

    local caseTempTextOffset = caseTempOffset
    local caseTempTextBackgroundColor = CASE_TEMP_COLOR
    local caseTempTextColor = BACKGROUND_COLOR

    if caseTempHeight <= 0 then
        caseTempTextOffset = caseTempOffset + Vector2.new(0, -1)
        caseTempTextColor, caseTempTextBackgroundColor = caseTempTextBackgroundColor, caseTempTextColor
    end

    local caseRnd = math.floor(_G.averageCaseTemp + 0.5)
    DrawUtil.drawText(mon, string.format(tempFormat, caseRnd..""), caseTempTextOffset, caseTempTextBackgroundColor, caseTempTextColor)

    -- fuel temp
    DrawUtil.drawText(mon, "Fuel", offset + Vector2.new(10, 1), colors.gray, colors.lightBlue)
    local fuelUnit = math.min(_G.averageFuelTemp / assumedMaxFuelTemperature, 1)
    local fuelTempHeight = math.floor(fuelUnit * temperatureMaxHeight + 0.5)

    local fuelTempOffset = offset + Vector2.new(9, 2 + temperatureMaxHeight - fuelTempHeight)
    local fuelTempSize = Vector2.new(6, fuelTempHeight)

    DrawUtil.drawFilledBox(mon, FUEL_TEMP_COLOR, fuelTempOffset, fuelTempSize)

    local fuelTempTextOffset = fuelTempOffset
    local fuelTempTextBackgroundColor = FUEL_TEMP_COLOR
    local fuelTempTextColor = BACKGROUND_COLOR

    if fuelTempHeight <= 0 then
        fuelTempTextOffset = fuelTempOffset + Vector2.new(0, -1)
        fuelTempTextColor, fuelTempTextBackgroundColor = fuelTempTextBackgroundColor, fuelTempTextColor
    end

    local fuelRnd = math.floor(_G.averageFuelTemp + 0.5)
    DrawUtil.drawText(mon, string.format(tempFormat, fuelRnd..""), fuelTempTextOffset, fuelTempTextBackgroundColor, fuelTempTextColor)
end

local function drawGraph(mon, dividerXCoord, name, graphOffset, graphSize)
    if (name == "Energy Buffer") then
        local drawPercentLabelOnRight = graphOffset.x + 19 < dividerXCoord - 1
        drawEnergyBuffer(mon, graphOffset, graphSize, drawPercentLabelOnRight)
    elseif (name == "Control Level") then
        drawControlGraph(mon, graphOffset, graphSize, _G.averageRod)
    elseif (name == "Temperatures") then
        drawTemperatures(mon, graphOffset, graphSize)
    end
end

local function drawGraphs(mon, monitorSize, graphSlots, dividerXCoord, offset, size)
    DrawUtil.drawBox(mon, colors.lightBlue, offset, size)
    local label = " Reactor Graphs "
    DrawUtil.drawText(
        mon,
        label,
        offset + Vector2.new(dividerXCoord - (#label + 5) - 1, 0),
        colors.black,
        colors.lightBlue
    )

    local graphSize = Vector2.new(15, monitorSize.y - 7)
    local graphYOffset = 4
    for graphXOffset, graph in pairs(graphSlots) do
        if graphXOffset + graphSize.x < dividerXCoord then
            drawGraph(mon, dividerXCoord, graph.name, Vector2.new(graphXOffset, graphYOffset), graphSize)
        end
    end
end

local function drawControls(mon, offset, size, drawBufferVisualization)
    if not drawBufferVisualization then
        size = Vector2.new(30, 9)
    end

    DrawUtil.drawBox(mon, colors.cyan, offset, size)
    DrawUtil.drawText(mon, " Reactor Controls ", offset + Vector2.new(4, 0), colors.black, colors.cyan)

    local reactorOnOffLabel = "Reactor "..(_G.btnOn and "Online" or "Offline")
    local reactorOnOffLabelColor = _G.btnOn and colors.green or colors.red
    DrawUtil.drawText(mon, reactorOnOffLabel, offset + Vector2.new(7, 2), colors.black, reactorOnOffLabelColor)

    if not drawBufferVisualization then
        return
    end

    local bufferMinInPixels = _G.minb / 5
    local bufferMaxInPixels = _G.maxb / 5
    local bufferRangePixelWidth = bufferMaxInPixels - bufferMinInPixels

    local bufferVisualOffset = offset + Vector2.new(5, 8)
    local bufferVisualSize = Vector2.new(20, 3)

    DrawUtil.drawText(mon, "Buffer Target Range", bufferVisualOffset + Vector2.new(0, -1), colors.black, colors.orange)
    DrawUtil.drawFilledBox(mon, colors.red, bufferVisualOffset, bufferVisualSize)
    DrawUtil.drawFilledBox(mon, colors.green, bufferVisualOffset + Vector2.new(bufferMinInPixels, 0), Vector2.new(bufferRangePixelWidth, 3))

    DrawUtil.drawText(
        mon,
        string.format("%3s", _G.minb.."%"),
        bufferVisualOffset + Vector2.new(bufferMinInPixels - 3, bufferVisualSize.y),
        colors.black,
        colors.purple
    )
    DrawUtil.drawText(
        mon,
        _G.maxb.."%",
        bufferVisualOffset + Vector2.new(bufferMaxInPixels, bufferVisualSize.y),
        colors.black,
        colors.magenta
    )
    DrawUtil.drawText(mon, "Min", offset + Vector2.new(7, 13), colors.black, colors.purple)
    DrawUtil.drawText(mon, "Max", offset + Vector2.new(19, 13), colors.black, colors.purple)
end

local function drawStatistics(mon, offset, size)
    DrawUtil.drawBox(mon, colors.blue, offset, size)
    DrawUtil.drawText(mon, " Reactor Statistics ", offset + Vector2.new(4, 0), colors.black, colors.blue
    )

    DrawUtil.drawText(
        mon,
        "Generating : "..format(_G.averageLastRFT).."RF/t",
        offset + Vector2.new(2, 2),
        colors.black,
        colors.green
    )

    DrawUtil.drawText(
        mon,
        "RF Drain   "..(_G.averageStoredThisTick <= _G.averageLastRFT and "> " or ": ")..format(_G.averageRfLost).."RF/t",
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
        "Fuel Usage : "..format(_G.averageFuelUsage).."B/t",
        offset + Vector2.new(2, 8),
        colors.black,
        colors.green
    )

    DrawUtil.drawText(
        mon,
        "Waste      : "..string.format("%7d mB", _G.waste),
        offset + Vector2.new(2, 10),
        colors.black,
        colors.green
    )
end

local function updateReactorControlButtonStates(touch)
    if _G.btnOn then
        touch:setButton("On", true)
        touch:setButton("Off", false)
    else
        touch:setButton("On", false)
        touch:setButton("Off", true)
    end
end

local function updateGraphMenuButtonStates(touch, graphSlots)
    for _, graphName in pairs(graphs) do
        touch:setButton(graphName, false)
    end
    for _, graph in pairs(graphSlots) do
        touch:setButton(graph.name, true)
    end
end

    ---@return integer
local function calculateDividerYCoord(sizey)
    if sizey <= 24 then
        return MONITOR_CONSTANTS.MINIMUM_DIVIDER_Y_VALUE
    end
    return sizey - 37
end

---@return integer
local function calculateDividerXCoord(sizex)
    if sizex <= 36 then
        return MONITOR_CONSTANTS.MINIMUM_DIVIDER_X_VALUE
    end
    return sizex - 31
end

local function greaterThanEqualTo(firstVector2, secondVector2)
    return firstVector2.x >= secondVector2.x and firstVector2.y >= secondVector2.y
end

local MINIMUM_SIZE_TO_DRAW = {x = 36, y = 24}
local REACTOR_CONTROL_MIN_SIZE = {x = 36, y = 24}
local REACTOR_CONTROL_BUFFER_VIS_MIN_SIZE = {x = 36, y = 38}
local GRAPH_MENU_MIN_SIZE = {x = 36, y = 52}
local GRAPHS_MIN_SIZE = {x = 57, y = 24}
local STATISTICS_MIN_SIZE = {x = 36, y = 24}

local function getDrawOptions(monitorSize)
    local drawOptions = {
        drawInvalidMonitorDimensions = not greaterThanEqualTo(monitorSize, MINIMUM_SIZE_TO_DRAW),
        drawReactorControls = greaterThanEqualTo(monitorSize, REACTOR_CONTROL_MIN_SIZE),
        drawReactorControlsBufferVisualization = greaterThanEqualTo(monitorSize, REACTOR_CONTROL_BUFFER_VIS_MIN_SIZE),
        drawGraphMenu = greaterThanEqualTo(monitorSize, GRAPH_MENU_MIN_SIZE),
        drawGraphs = greaterThanEqualTo(monitorSize, GRAPHS_MIN_SIZE),
        drawStatistics = greaterThanEqualTo(monitorSize, STATISTICS_MIN_SIZE),
    }
    return drawOptions
end

---@class Monitor
local Monitor = {
    navbar = nil,
    ---@type Page
    activePage = nil,
    ---@type string
    id = nil,
    ---@type table
    mon = nil,
    ---@type table
    touch = nil,
    monPeripheral = nil,

    -- mutable!
    graphSlots = nil,

    -- Never edit these outside of handleResize()!
    size = nil,
    dividerYCoord = nil,
    dividerXCoord = nil,
    drawOptions = nil,

    ---comment
    ---@param self Monitor
    clear = function(self)
        self.mon.setBackgroundColor(colors.black)
        self.mon.clear()
        self.mon.setCursorPos(1,1)
    end,

    handleClick = function(self, buttonName)

        -- Enable when navbar and page is created
        -- local button = self.navbar.touch.buttonList[buttonName] or self.activePage.touch.buttonList[buttonName]
        -- button.func()

        self.touch.buttonList[buttonName].func()
        print(buttonName, "clicked on", self.id)
    end,
    
    handleResize = function(self)
        self.monPeripheral.setTextScale(0.5)
        self.size = Vector2.new(self.monPeripheral.getSize())
        self.mon = window.create(self.monPeripheral, 1, 1, self.size.x, self.size.y, false)
        self.touch = _G.Touchpoint.new(self.id, self.mon)
        self.dividerXCoord = calculateDividerXCoord(self.size.x)
        self.dividerYCoord = calculateDividerYCoord(self.size.y)
        
        self.drawOptions = getDrawOptions(self.size)
        if self.drawOptions.drawGraphMenu then
            local offset = Vector2.new(self.dividerXCoord + 5, self.dividerYCoord - 14)
            local size = Vector2.new(20, 3)
            addGraphButtons(self, self.graphSlots, offset, size)
        end

        if self.drawOptions.drawReactorControls then
            local offset = Vector2.new(self.dividerXCoord, self.dividerYCoord)
            addReactorControlButtons(self.touch, offset, self.drawOptions.drawReactorControlsBufferVisualization)
        end
    end,

    handleEvents = function(self, event)
        if event[2] ~= self.id then
            return
        end
        local touchpointEvent = { self.touch:handleEvents(unpack(event)) }
        if touchpointEvent[1] == "button_click" then
            local buttonName = touchpointEvent[3]
			self:handleClick(buttonName)

            -- Immediately draw the clicked monitor so that users don't feel any input delay when using the monitors
			self:draw()
        end
        if event[1] == "monitor_resize" then
            self:handleResize()
        end
    end,

    ---@param self Monitor
    draw = function(self)
        self.mon.setVisible(false)
        self:clear()
        
        if self.drawOptions.drawInvalidMonitorDimensions then
            self.mon.write("Invalid Monitor Dimensions")
        end

        if self.drawOptions.drawGraphMenu then
            local offset = Vector2.new(self.dividerXCoord + 1, self.dividerYCoord - 14 + 1)
            local size = Vector2.new(30, 13)
            drawGraphButtons(self.mon, offset, size)
            updateGraphMenuButtonStates(self.touch, self.graphSlots)
        end

        if self.drawOptions.drawReactorControls then
            local offset = Vector2.new(self.dividerXCoord + 1, self.dividerYCoord + 1)
            local size = Vector2.new(30, 23)
            drawControls(self.mon, offset, size, self.drawOptions.drawReactorControlsBufferVisualization)
            updateReactorControlButtonStates(self.touch)
        end

        if self.drawOptions.drawGraphs then
            local offset = Vector2.new(2, 2)
            local size = Vector2.new(self.dividerXCoord - 2, self.size.y - 2)
            drawGraphs(self.mon, self.size, self.graphSlots, self.dividerXCoord, offset, size)
        end

        if self.drawOptions.drawStatistics then
            local offset = Vector2.new(self.dividerXCoord + 1, self.size.y - 12)
            local size = Vector2.new(30, 12)
            drawStatistics(self.mon, offset, size)
        end

        self.touch:drawAllButtons()
        self.mon.setVisible(true)
    end
}

---comment
---@param id string
---@return Monitor
local function new(id)
    local monPeripheral = peripheral.wrap(id)

    local monitorInstance = {
        id = id,
        monPeripheral = monPeripheral,
        graphSlots = {},
    }
	setmetatable(monitorInstance, {__index = Monitor})
    monitorInstance:handleResize()

    enableGraph(monitorInstance.graphSlots, "Energy Buffer")
    enableGraph(monitorInstance.graphSlots, "Control Level")
    enableGraph(monitorInstance.graphSlots, "Temperatures")
    return monitorInstance
end

_G.Monitor = {
    new = new
}
