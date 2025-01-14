---@class Deque
---@field first number
---@field last number
---@field sum number
---@field size number
---@field list table<number>
local Deque = {
    sum = 0,
    size = 0,
    first = 0,
    last = -1,

    ---@param self Deque
    ---@param value number
    pushleft = function(self, value)
        local first = self.first - 1
        self.first = first
        self.list[first] = value
        self.size = self.size + 1
        self.sum = self.sum + value
    end,

    ---@param self Deque
    ---@param value number
    pushright = function (self, value)
        local last = self.last + 1
        self.last = last
        self.list[last] = value
        self.size = self.size + 1
        self.sum = self.sum + value
    end,

    ---@param self Deque
    ---@return number
    popleft = function (self)
        local first = self.first
        if first > self.last then error("list is empty") end

        local value = self.list[first]
        self.list[first] = nil        -- to allow garbage collection
        self.first = first + 1
        self.size = self.size - 1
        self.sum = self.sum - value
        return value
    end,

    ---@param self Deque
    ---@return number
    popright = function (self)
        local last = self.last
        if self.first > last then error("list is empty") end
        local value = self.list[last]
        self.list[last] = nil         -- to allow garbage collection
        self.last = last - 1
        self.size = self.size - 1
        self.sum = self.sum - value
        return value
    end,

    ---@param self Deque
    ---@return number
    average = function (self)
        return self.sum / self.size
    end
}

---@return Deque
local function new()
    local dequeInstance = {list = {}}
    setmetatable(dequeInstance, {__index = Deque})
    return dequeInstance
end

_G.Deque = {
    new = new
}
