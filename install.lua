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
    downloadGitHubFileByPath(updateScriptPath)
    shell.run(updateScriptPath)
    print("Downloading files!")
    _G.UpdateScript.performUpdate()
    print("Download complete. Rebooting...")
    sleep(1)
end

install()