local AUTOMATIC_UPDATE_ENABLED = false

shell.run("/src/classes/touchpoint.lua")
shell.run("/src/classes/classes.lua")
shell.run("/src/util/draw.lua")
shell.run("/src/classes/page.lua")
shell.run("/src/classes/navbar.lua")
shell.run("/src/classes/monitor.lua")
shell.run("/src/scripts/controller.lua")
shell.run("/src/scripts/update.lua")

-- For now, do update check here
local updateAvailable = _G.UpdateScript.checkForUpdate()
if updateAvailable then
    print("Update available!")

    if AUTOMATIC_UPDATE_ENABLED then
        print("Automatic update is enabled! Updating...")
        _G.UpdateScript.performUpdate()
    else
        print("Automatic update skipped because it's not enabled!")
    end
    
end
-- For now, main() is in controller.lua
main()