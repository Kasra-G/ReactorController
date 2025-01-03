---@class Peripheral
local Peripheral = {
    ---@type string
    id = nil,
    ---@type string
    type = nil,
    ---@type table
    wrap = nil,
}
---comment
---@param id string
---@param type string
---@return Peripheral
local function newPeripheral(id, type)

    local peripheralInstance = {
        id = id,
        type = type,
        wrap = peripheral.wrap(id),
    }
	setmetatable(peripheralInstance, {__index = Peripheral})
    return peripheralInstance
end

_G.Peripheral = {
    new = newPeripheral
}

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

-- local function newVector2(x, y)

--     local Vector2Instance = {
--         x = x,
--         y = y,
--     }
-- 	setmetatable(Vector2Instance, {__index = Vector2, __add = Vector2.__add, __sub = Vector2.__sub})
--     return Vector2Instance
-- end

-- _G.Vector2 = {
--     new = newVector2,
--     zero = newVector2(0, 0),
--     one = newVector2(1, 1),

--     __add = function (a, b)
--         local t = type(b)
--         if t == "table" then
--             return Vector2.new(a.x + b.x, a.y + b.y)
--         elseif t == "number" then
--             return Vector2.new(a.x + b, a.y + b)
--         end
--     end,

--     __sub = function (a, b)
--         local t = type(b)
--         if t == "table" then
--             return Vector2.new(a.x - b.x, a.y - b.y)
--         elseif t == "number" then
--             return Vector2.new(a.x - b, a.y - b)
--         end
--     end,
-- }

---@class Vector2
local Vector2 = {
    ---@type number
    x = nil,
    ---@type number
    y = nil,
}

Vector2.mt = {}

Vector2.mt.__index = Vector2

---comment
---@param x number
---@param y number
---@return Vector2
function Vector2.new(x, y)
	local instance = {x = x, y = y}
	return setmetatable(instance, Vector2.mt)
end

Vector2.mt.__add = function(self, other)
    local t = type(other)
    if t == "table" then
        return Vector2.new(self.x + other.x, self.y + other.y)
    elseif t == "number" then
        return Vector2.new(self.x + other, self.y + other)
    end
end

Vector2.mt.__sub = function(self, other)
    local t = type(other)
    if t == "table" then
        return Vector2.new(self.x - other.x, self.y - other.y)
    elseif t == "number" then
        return Vector2.new(self.x - other, self.y - other)
    end
end

_G.Vector2 = {
    new = Vector2.new,
    zero = Vector2.new(0, 0),
    one = Vector2.new(1, 1),
}
