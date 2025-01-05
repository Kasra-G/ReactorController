-- This file is in pastebin

local GITHUB_CONSTANTS = {
    OWNER = "Kasra-G",
    REPO = "ReactorController",
    BRANCH = "development",
}

local function downloadGitHubFileByPath(filepath)
    local endpoint = "https://raw.githubusercontent.com/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/refs/heads/"..GITHUB_CONSTANTS.BRANCH.."/"..filepath
    local response = http.get(endpoint)
    local contents = response.readAll()
    local file = fs.open(filepath, "w")
    file.write(contents)
    file.close()
end

--- Download the update script and reboot
local function install()
    local updateScriptPath = "src/scripts/update.lua"
    local success, err = pcall(function() downloadGitHubFileByPath(updateScriptPath) end)
    if not success then
        error("Failed to install the script with error", err)
    end
    shell.run(updateScriptPath)
    print("Downloading files!")
    local success = _G.UpdateScript.performUpdate()
    if not success then
        error("Failed to install the script! Do you have internet access?")
    end
    print("Files downloaded successfully.")
    sleep(1)
    os.reboot()
end

install()