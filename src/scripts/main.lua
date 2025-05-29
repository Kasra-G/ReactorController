local function insertAllFilepathsInDirectoryToTable(path, outputFilenames)
    for _, file in pairs(fs.list(path)) do
        local filepath = fs.combine(path, file)
        if fs.isDir(filepath) then
            insertAllFilepathsInDirectoryToTable(filepath, outputFilenames)
        else
            table.insert(outputFilenames, filepath)
        end
    end
end

local function executeAllLuaFilesInSrcFolderExceptMain()
    local filepaths = {}
    insertAllFilepathsInDirectoryToTable("src", filepaths)
    for _, filepath in pairs(filepaths) do
        if filepath ~= "src/scripts/main.lua" then
            shell.run(filepath)
        end
    end
end

local function promptAndReadInputAndLoopUntilValid(prompt, validAnswersList)
    local validAnswer = nil
    local validAnswersTable = {}
    for _, answer in pairs(validAnswersList) do
        validAnswersTable[answer] = true
    end
    while not validAnswer do
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

local function runUpdateLogic()
    local updateAvailable = _G.UpdateScript.checkForUpdate()
    if not updateAvailable then
        return false
    end

    print("Update available!")
    -- Set some state variable somewhere to tell us an update is available
    if not UPDATE_CONFIG.AUTOUPDATE then
        print("Automatic update skipped because it's not enabled!")
        return false
    end
    print("Automatic update is enabled! Updating...")
    return _G.UpdateScript.performUpdate()
end

local function start()
    executeAllLuaFilesInSrcFolderExceptMain()
    -- Let reactors run for 1 second on world load.
    sleep(1)

    term.clear()
    term.setCursorPos(1,1)

    ConfigUtil.writeAllConfigsAsDefaults()
    ConfigUtil.readAllConfigs()

    if not UPDATE_CONFIG.FIRST_TIME_SETUP_COMPLETE then
        print("First time startup detected!")
        runFirstTimeSetup()
        UPDATE_CONFIG.FIRST_TIME_SETUP_COMPLETE = true
        ConfigUtil.writeAllConfigs()
    end

    local didUpdate = runUpdateLogic()
    if didUpdate then
        print("Successfully updated! Rebooting...")
        os.reboot()
    end

    -- For now, main() is in controller.lua
    main()
end

start()
