---@class EnergyBuffer
---@field id string
---@field energyStoredLastTick number
---@field energyStoredThisTick number
---@field energyStoredLastTickValues Deque
---@field energyStoredThisTickValues Deque
---@field averageEnergyStoredLastTick number
---@field averageEnergyStoredThisTick number
---@field lastUpdatedTick number
---@field capacity number
---@field getEnergyStored function
---@field getEnergyCapacity function
local EnergyBuffer = {
    updateAverages = function (self)
        self.energyStoredThisTickValues:pushleft(self.energyStoredThisTick)
        self.energyStoredLastTickValues:pushleft(self.energyStoredLastTick)

        local ticksToAverage = 20 * _G.SECONDS_TO_AVERAGE
        while self.energyStoredThisTickValues.size > ticksToAverage do
            self.energyStoredLastTickValues:popright()
            self.energyStoredThisTickValues:popright()
        end

        self.averageEnergyStoredLastTick = self.energyStoredLastTickValues:average()
        self.averageEnergyStoredThisTick = self.energyStoredThisTickValues:average()
    end,

    ---@param self EnergyBuffer
    ---@param currentTickNumber number
    update = function(self, currentTickNumber)
        if self.lastUpdatedTick >= currentTickNumber then
            return
        elseif self.lastUpdatedTick < currentTickNumber - 1 then
            -- We missed the last tick - we don't know what it is! just set it to 0 for now...
            self.energyStoredLastTick = 0
        end
        local newEnergyStored = self:getEnergyStored()
        self.capacity = self:getEnergyCapacity()
        self.energyStoredLastTick = self.energyStoredThisTick
        self.energyStoredThisTick = newEnergyStored

        self:updateAverages()

        self.lastUpdatedTick = currentTickNumber
    end,

}

---@return EnergyBuffer
local function new(id, energyStoredFunction, energyCapacityFunction)
    local energyBufferInstance = {
        id = id,
        energyStoredLastTick = 0,
        energyStoredThisTick = 0,
        energyStoredLastTickValues = Deque.new(),
        energyStoredThisTickValues = Deque.new(),
        lastUpdatedTick = 0,
        capacity = 0,
        getEnergyStored = energyStoredFunction,
        getEnergyCapacity = energyCapacityFunction,
    }
	setmetatable(energyBufferInstance, {__index = EnergyBuffer})
    local currentTickNumber = math.floor(os.clock() * 20)
    energyBufferInstance:update(currentTickNumber)
    return energyBufferInstance
end

local function newReactorEnergyBuffer(id)
    local energyPeripheral = peripheral.wrap(id)
    return new(
        id,
        function() return energyPeripheral.getEnergyStats().energyStored end,
        function() return energyPeripheral.getEnergyStats().energyCapacity end
    )
end

local function newForgeEnergyBuffer(id)
    local energyPeripheral = peripheral.wrap(id)
    return new(
        id,
        energyPeripheral.getEnergy,
        energyPeripheral.getEnergyCapacity
    )
end

_G.EnergyBuffer = {
    newForgeEnergyBuffer = newForgeEnergyBuffer,
    newReactorEnergyBuffer = newReactorEnergyBuffer,
}