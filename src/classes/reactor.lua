-- Function to calculate the average of an array of values
local function calculateAverage(array)
    local sum = 0
    local count = 0
    for _, value in pairs(array) do
        sum = sum + value
        count = count + 1
    end
    return sum / count
end


local function setRods(reactor, level)
    level = math.max(level, 0)
    level = math.min(level, 100)
    local count = reactor.getNumberOfControlRods()

    local numberToAddOneLevelTo = math.floor((level - math.floor(level)) * count + 0.5)

    local levelsMap = {}
    for idx0, _ in pairs(reactor.getControlRodsLevels()) do
        local rodLevel = math.floor(level)
        if numberToAddOneLevelTo > 0 then
            rodLevel = rodLevel + 1
            numberToAddOneLevelTo = numberToAddOneLevelTo - 1
        end
        levelsMap[idx0] = rodLevel
    end
    reactor.setControlRodsLevels(levelsMap)
end


local function lerp(start, finish, t)
    t = math.max(0, math.min(1, t))

    return (1 - t) * start + t * finish
end

local function iteratePID(pid, error)
    -- Proportional term
    local P = pid.Kp * error

    -- Integral term
    pid.integral = pid.integral + pid.Ki * error
    pid.integral = math.max(math.min(100, pid.integral), -100)

    -- Derivative term
    local derivative = pid.Kd * (error - pid.lastError)

    -- Calculate control rod level
    local rodLevel = math.max(math.min(P + pid.integral + derivative, 100), 0)

    -- Update PID controller state
    pid.lastError = error
    return rodLevel
end

---@class Reactor
---@field id string
---@field active boolean
---@field activelyCooled boolean
---@field lastUpdatedTick number
---@field lastRFT number
---@field rodLevel number
---@field fuelUsage number
---@field waste number
---@field fuelTemp number
---@field caseTemp number
---@field fuelEfficiency number
---@field steamProductionRate number
---@field storedSteam number
---@field steamCapacity number
---@field lastRFTValues Deque
---@field rodLevelValues Deque
---@field fuelUsageValues Deque
---@field wasteValues Deque
---@field fuelTempValues Deque
---@field caseTempValues Deque
---@field steamProductionRateValues Deque
---@field storedSteamValues Deque
---@field averageLastRFT number
---@field averageRodLevel number
---@field averageFuelUsage number
---@field averageWaste number
---@field averageFuelTemp number
---@field averageSteamProductionRate number
---@field averageStoredSteam number
---@field averageFuelEfficiency number
---@field getLastRFT function
---@field getRodLevel function
---@field getFuelUsage function
---@field getWaste function
---@field getFuelTemp function
---@field getCaseTemp function
---@field getSteamProductionRate function
---@field getStoredSteam function
---@field getSteamCapacity function
---@field isActivelyCooled function
---@field getActive function
---@field setActive function
---@field setRodLevels function
local Reactor = {

    lastUpdatedTick = 0,

    updateAverages = function (self)
        self.fuelUsageValues:pushleft(self.fuelUsage)
        self.lastRFTValues:pushleft(self.lastRFT)
        self.fuelTempValues:pushleft(self.fuelTemp)
        self.caseTempValues:pushleft(self.caseTemp)
        self.rodLevelValues:pushleft(self.rodLevel)
        self.wasteValues:pushleft(self.waste)
        self.steamProductionRateValues:pushleft(self.steamProductionRate)
        self.storedSteamValues:pushleft(self.storedSteam)

        local ticksToAverage = 20 * _G.SECONDS_TO_AVERAGE
        while self.lastRFTValues.size > ticksToAverage do
            self.fuelUsageValues:popright()
            self.lastRFTValues:popright()
            self.fuelTempValues:popright()
            self.caseTempValues:popright()
            self.rodLevelValues:popright()
            self.wasteValues:popright()
            self.steamProductionRateValues:popright()
            self.storedSteamValues:popright()
        end

        self.averageFuelUsage = self.fuelUsageValues:average()
        self.averageLastRFT = self.lastRFTValues:average()
        self.averageFuelTemp = self.fuelTempValues:average()
        self.averageCaseTemp = self.caseTempValues:average()
        self.averageRodLevel = self.rodLevelValues:average()
        self.averageWaste = self.wasteValues:average()
        self.averageSteamProductionRate = self.steamProductionRateValues:average()
        self.averageStoredSteam = self.storedSteamValues:average()

        self.averageFuelEfficiency = self.averageLastRFT / self.averageFuelUsage
    end,

    ---@param self Reactor
    ---@param currentTickNumber number
    update = function(self, currentTickNumber)
        if self.lastUpdatedTick >= currentTickNumber then
            return
        elseif self.lastUpdatedTick < currentTickNumber - 1 then
            -- We missed the last tick - Don't do anything different for now...
            print("missed last tick!")
        end

        self.activelyCooled = self.isActivelyCooled()
        self.active = self.getActive()
        self.lastRFT = self.getLastRFT()
        self.rodLevel = self.getRodLevel()
        self.fuelUsage = self.getFuelUsage()
        self.waste = self.getWaste()
        self.fuelTemp = self.getFuelTemp()
        self.caseTemp = self.getCaseTemp()
        self.steamProductionRate = self.getSteamProductionRate()
        self.storedSteam = self.getStoredSteam()
        self.steamCapacity = self.getSteamCapacity()
        self.fuelEfficiency = self.lastRFT / self.fuelUsage

        self:updateAverages()
        self.lastUpdatedTick = currentTickNumber
    end,

    ---@param self Reactor
    -- -@param targetRFT number
    -- -@param targetRF number
    updateRods = function (self)
        if not self.active then
            return
        end

        local currentGenerationRate = self.averageLastRFT
        local currentStoredAmount = _G.overallStats.storedThisTick
        local capacity = _G.overallStats.capacity
        local targetGenerationRate = _G.overallStats.rfLost

        if self.activelyCooled then
            currentGenerationRate = self.averageSteamProductionRate
            currentStoredAmount = _G.overallStats.storedSteam
            capacity = _G.overallStats.steamCapacity
            targetGenerationRate = _G.overallStats.steamConsumedLastTick
        end

        local diffb = _G.maxb - _G.minb
        local minRF = _G.minb / 100 * capacity
        local diffRF = diffb / 100 * capacity
        local diffr = diffb / 100
        -- local targetStoredAmount = diffRF / 2 + minRF
        local targetStoredAmount = currentStoredAmount

        self.pid.setpointRFT = targetGenerationRate
        self.pid.setpointRF = targetStoredAmount / capacity * 1000

        local errorRFT = self.pid.setpointRFT - currentGenerationRate
        local errorRF = self.pid.setpointRF - currentStoredAmount / capacity * 1000

        local W_RFT = lerp(1, 0, (math.abs(targetStoredAmount - currentStoredAmount) / capacity / (diffr / 4)))
        W_RFT = math.max(math.min(W_RFT, 1), 0)

        local W_RF = (1 - W_RFT)  -- Adjust the weight for energy error

        -- Combine the errors with weights
        local combinedError = W_RFT * errorRFT + W_RF * errorRF
        local error = combinedError
        local rftRodLevel = iteratePID(self.pid, error)

        -- Set control rod levels
        self.setRodLevels(rftRodLevel)
    end,
}

---@param id string
---@return Reactor
local function newExtremeReactor(id)
    local extremeReactor = peripheral.wrap(id)
    local pid = {
        setpointRFT = 0,      -- Target RFT
        setpointRF = 0,      -- Target RF
        Kp = -.008,           -- Proportional gain
        Ki = -.00015,          -- Integral gain
        Kd = -.01,         -- Derivative gain
        integral = 0,       -- Integral term accumulator
        lastError = 0,      -- Last error for derivative term
    }
    local reactorInstance = {
        id = id,
        pid = pid,
        fuelUsageValues = Deque.new(),
        lastRFTValues = Deque.new(),
        fuelTempValues = Deque.new(),
        caseTempValues = Deque.new(),
        rodLevelValues = Deque.new(),
        wasteValues = Deque.new(),
        steamProductionRateValues = Deque.new(),
        storedSteamValues = Deque.new(),

        getFuelUsage = function () return extremeReactor.getFuelStats().fuelConsumedLastTick / 1000 end,
        getLastRFT = function () return extremeReactor.getEnergyStats().energyProducedLastTick end,
        getFuelTemp = extremeReactor.getFuelTemperature,
        getCaseTemp = extremeReactor.getCasingTemperature,
        getRodLevel = function () return calculateAverage(extremeReactor.getControlRodsLevels()) end,
        getWaste = extremeReactor.getWasteAmount,
        getSteamProductionRate = extremeReactor.getHotFluidProducedLastTick,
        getSteamCapacity = extremeReactor.getHotFluidAmountMax,
        getStoredSteam = extremeReactor.getHotFluidAmount,
        getActive = extremeReactor.getActive,
        isActivelyCooled = extremeReactor.isActivelyCooled,
        setActive = extremeReactor.setActive,
        setRodLevels = function (level) setRods(extremeReactor, level) end,
    }
	setmetatable(reactorInstance, {__index = Reactor})
    local currentTickNumber = math.floor(os.clock() * 20)
    reactorInstance:update(currentTickNumber)
    return reactorInstance
end

_G.Reactor = {
    newExtremeReactor = newExtremeReactor,
    -- newBiggerReactor = newBiggerReactor,
}