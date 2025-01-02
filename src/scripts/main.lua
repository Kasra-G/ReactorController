shell.run("/src/classes/touchpoint.lua")
shell.run("/src/classes/classes.lua")
shell.run("/src/util/draw.lua")
shell.run("/src/classes/page.lua")
shell.run("/src/classes/navbar.lua")
shell.run("/src/classes/monitor.lua")
shell.run("/src/scripts/controller.lua")
shell.run("/src/scripts/update.lua")

-- For now, update() is in update.lua
update()
-- For now, main() is in controller.lua
main()