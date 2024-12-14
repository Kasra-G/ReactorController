local version = "1.0"

--Github: https://github.com/Kasra-G/ReactorController/#readme

-- ["filename"] = "pastebinCode"
local filesToUpdate = {
    ["/reactorController.lua"] = "b17hfTqe",
    ["/usr/apis/touchpoint.lua"] = "nx9pkLbJ",
    ["/update_reactor.lua"] = "w6vVtrLb",
}

local function getPastebinFileContents(filename, pastebinCode)
    local tempFilename = "/temp" .. filename

    -- Avoid calling pastebin API directly to be more robust towards any future API changes
    shell.run("pastebin", "get", pastebinCode, tempFilename)
    local tempFile = fs.open(tempFilename, "r")
    
    if not tempFile then
        return nil
    end

    local fileContents = tempFile.readAll()
    tempFile.close()
    fs.delete(tempFilename)
    return fileContents
end

-- Requires HTTP to be enabled
local function getVersion(fileContents)
    if not fileContents then
        return nil
    end

    local _, numberChars = fileContents:lower():find('local version = "')

    if not numberChars then
        return nil
    end

    local fileVersion = ""
    local char = ""

    while char ~= '"' do
        numberChars = numberChars + 1
        char = fileContents:sub(numberChars,numberChars)
        fileVersion = fileVersion .. char
    end

    fileVersion = fileVersion:sub(1,#fileVersion-1) -- Remove quotes around the version number
    return fileVersion
end

local function updateFile(filename, pastebinCode)
        if fs.isDir(filename) then
            print("[Error] " .. filename .. " is a directory")
            return
        end
        local pastebinContents = getPastebinFileContents(filename, pastebinCode)

        if not pastebinContents then
            print("[Error] " .. filename .. " has an invalid link")
        end

        local pastebinVersion = getVersion(pastebinContents)
        if not pastebinVersion then
            print("[Error] the pastebin code for " .. filename .. " does not have a version variable")
            return
        end

        local localVersion = nil
        if fs.exists(filename) then
            local localFile = fs.open(filename,"r")
            localVersion = getVersion(localFile.readAll())
            localFile.close()
        end

        if localVersion ~= pastebinVersion then
            local localFile = fs.open(filename,"w")
            localFile.write(pastebinContents)
            localFile.close()
            print("[Success] " .. filename .. " has been updated to version " .. pastebinVersion)
        elseif pastebinVersion == localVersion then
            print("[Success] No update required: " .. filename .. " is already the latest version")
        end
end

local function main() 
    fs.makeDir("/usr")
    fs.makeDir("/usr/apis")
    for filename, pastebinCode in pairs(filesToUpdate) do
        updateFile(filename, pastebinCode)
    end
end

main()
