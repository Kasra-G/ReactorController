---@class Navbar
local Navbar = {
    ---@type table<string, string>
    pageNameMap = nil,

    touch = nil,
    ---@type Vector2
    offset = nil,
    ---@type Vector2
    size = nil,

    handleEvents = function()
        
    end,

    ---comment
    ---@param self Navbar
    ---@param reactorStats ReactorStatistics
    draw = function(self, reactorStats)

    end
}

---comment
---@param peripheralId string
---@return Navbar
local function new(peripheralId)
    local monitorPeripheral = peripheral.wrap(peripheralId)
    local touch = _G.Touchpoint.new(peripheralId)

    local monitorInstance = {
        id = peripheralId,
        peripheral = monitorPeripheral,
        touch = touch,
    }

	setmetatable(monitorInstance, {__index = Navbar})
    return monitorInstance
end

_G.Navbar = {
    new = new
}
