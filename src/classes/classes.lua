---@class ReactorStatistics
local ReactorStatistics = {
    
}
---comment
---@param id string
---@param type string
---@return ReactorStatistics
local function newReactorStatistics(id, type)

    local reactorStatisticsInstance = {
    }
	setmetatable(reactorStatisticsInstance, {__index = ReactorStatistics})
    return reactorStatisticsInstance
end

_G.ReactorStatistics = {
    new = newReactorStatistics
}

---@class Vector2
local Vector2 = {
    ---@type number
    x = nil,
    ---@type number
    y = nil,
}

_G.Vector2 = {
    new = vector.new,
    zero = vector.new(0, 0),
    one = vector.new(1, 1),
}
