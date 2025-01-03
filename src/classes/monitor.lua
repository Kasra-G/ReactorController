---@class Monitor
local Monitor = {

    navbar = nil,
    ---@type Page
    activePage = nil,
    ---@type string
    id = nil,
    ---@type table
    peripheral = nil,
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
        self.peripheral.setBackgroundColor(colors.black)
        self.peripheral.clear()
        self.peripheral.setTextScale(0.5)
        self.peripheral.setCursorPos(1,1)
    end,

    ---@param self Monitor
    drawScene = function(self)
        if (invalidDim) then
            self.peripheral.write("Invalid Monitor Dimensions")
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
    local monitorPeripheral = peripheral.wrap(peripheralId)
    local touch = _G.Touchpoint.new(peripheralId)

    local monitorInstance = {
        id = peripheralId,
        peripheral = monitorPeripheral,
        touch = touch,
    }

	setmetatable(monitorInstance, {__index = Monitor})
    return monitorInstance
end

_G.Monitor = {
    new = new
}
