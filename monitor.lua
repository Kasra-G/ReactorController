---@class Monitor
local Monitor = {
    ---@type string
    name = nil,
    ---@type table
    mon = nil,
    ---@type table
    touch = nil,
    ---@type Vector2
    size = nil,
    ---@type integer
    oo = nil,
    ---@type integer
    dim = nil,

    ---comment
    ---@param self Monitor
    clear = function(self)
        self.mon.setBackgroundColor(colors.black)
        self.mon.clear()
        self.mon.setTextScale(0.5)
        self.mon.setCursorPos(1,1)
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
    local touch = touchpoint.new(peripheralId)
    local sizex, sizey = mon.getSize()
    local oo = sizey - 37
    local dim = sizex - 33

    local monitorInstance = {
        name = peripheralId,
        mon = mon,
        touch = touch,
        sizex = sizex,
        sizey = sizey,
        oo = oo,
        dim = dim,
    }

	setmetatable(monitorInstance, {__index = Monitor})
    return monitorInstance
end

_G.Monitor = {
    new = new
}