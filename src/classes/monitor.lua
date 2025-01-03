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

    ---@param self Monitor
    ---@return Vector2
    size = function(self)
        return Vector2.new(self.mon.getSize())
    end,

    ---@param self Monitor
    ---@return integer
    dividerYCoord = function(self)
        return self:size().y - 37
    end,

    ---@param self Monitor
    ---@return integer
    dividerXCoord = function(self)
        return self:size().x - 31
    end,

    ---comment
    ---@param self Monitor
    clear = function(self)
        self.mon.setBackgroundColor(colors.black)
        self.mon.clear()
        self.mon.setTextScale(0.5)
        self.mon.setCursorPos(1,1)
    end,

    handleEvents = function(self, event)

    end,

    ---@param self Monitor
    drawScene = function(self)
        if (invalidDim) then
            self.mon.write("Invalid Monitor Dimensions")
            return
        end

        if (displayingGraphMenu) then
            drawGraphButtons()
        end
        drawControls()
        drawStatus()
        drawStatistics()
        self.touch:draw()
    end,

    ---comment
    ---@param self Monitor
    ---@param reactorStats ReactorStatistics
    update = function(self, reactorStats)

    end
}

---comment
---@param peripheralId string
---@return Monitor
local function new(peripheralId)
    local mon = peripheral.wrap(peripheralId)
    local touchHandler = _G.Touchpoint.new(peripheralId)

    local monitorInstance = {
        id = peripheralId,
        mon = mon,
        touch = touchHandler,
    }

	setmetatable(monitorInstance, {__index = Monitor})
    return monitorInstance
end

_G.Monitor = {
    new = new
}
