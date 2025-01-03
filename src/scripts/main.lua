term.clear()

shell.run("/src/config/projectConfigs.lua")
shell.run("/src/constants/projectConstants.lua")
shell.run("/src/util/draw.lua")
shell.run("/src/classes/touchpoint.lua")
shell.run("/src/classes/classes.lua")
shell.run("/src/classes/graph.lua")
shell.run("/src/classes/page.lua")
shell.run("/src/classes/navbar.lua")
shell.run("/src/classes/monitor.lua")
shell.run("/src/scripts/controller.lua")
shell.run("/src/scripts/update.lua")
shell.run("/src/util/config.lua")

local function promptAndReadInputAndLoopUntilValid(prompt, validAnswersList)
    local validAnswer
    local validAnswersTable = {}
    for _, answer in pairs(validAnswersList) do
        validAnswersTable[answer] = true
    end
    while true do
        print(prompt)
        local input = read()
        if validAnswersTable[input] then
            validAnswer = input
            break
        end
        print("Invalid response. Please try again!")
    end
    return validAnswer
end

local function runFirstTimeSetup()
    local response = promptAndReadInputAndLoopUntilValid("Do you want to automatically install updates? (y/n)", {"y", "n"})
    if response == "y" then
        UPDATE_CONFIG.AUTOUPDATE = true
    end
end

if UPDATE_CONFIG.DO_FIRST_TIME_SETUP then
    print("First time startup detected!")
    runFirstTimeSetup()
    UPDATE_CONFIG.DO_FIRST_TIME_SETUP = false
    ConfigUtil.writeAllConfigs()
end

-- For now, do update check here
local updateAvailable = _G.UpdateScript.checkForUpdate()
if updateAvailable then
    print("Update available!")
    -- Set some state variable somewhere to tell us an update is available
    if UPDATE_CONFIG.AUTOUPDATE then
        print("Automatic update is enabled! Updating...")
        _G.UpdateScript.performUpdate()
        print("Finished update! Rebooting...")
        sleep(1)
        os.reboot()
    else
        print("Automatic update skipped because it's not enabled!")
        sleep(1)
    end
end
-- For now, main() is in controller.lua
main()
