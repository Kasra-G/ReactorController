---@class Page
local Page = {
    ---@type string
    name = nil,
    ---@type table
    mon = nil,
    ---@type table
    touch = nil,
    ---@type Vector2
    offset = nil,
    ---@type Vector2
    size = nil,

    ---@param self Page
    draw = function(self)
        if (_G.displayingGraphMenu) then
            drawGraphButtons()
        end
        drawControls()
        drawStatus()
        drawStatistics()
        self.touch:draw()
    end,

    ---comment
    ---@param self Page
    ---@param reactorStats ReactorStatistics
    update = function(self, reactorStats)

    end
}

---comment
---@param peripheralId string
---@return Page
local function new(peripheralId)
    local monitorPeripheral = peripheral.wrap(peripheralId)
    local touch = _G.Touchpoint.new(peripheralId)

    local monitorInstance = {
        id = peripheralId,
        peripheral = monitorPeripheral,
        touch = touch,
    }

	setmetatable(monitorInstance, {__index = Page})
    return monitorInstance
end

_G.Page = {
    new = new
}
