---@class PIDController
local PIDController = {
    Kp = -.08,
    Ki = -.0015,
    Kd = -.01,
    setpoint = 0,
    integral = 0,
    lastError = 0,

    iterate = function(self, error)

    end
}
---comment
---@return PIDController
local function new(Kp, Ki, Kd)
    local pidControllerInstance = {
        Kp = Kp,
        Ki = Ki,
        Kd = Kd,
    }
	setmetatable(pidControllerInstance, {__index = PIDController})
    return pidControllerInstance
end

_G.PIDController = {
    new = new
}