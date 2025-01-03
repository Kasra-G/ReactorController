-- This file is in pastebin

local GITHUB_CONSTANTS = {
    OWNER = "Kasra-G",
    REPO = "ReactorController",
    BRANCH = "development",
}

local function getRemoteRepoSHA()
    local response = http.get("https://api.github.com/repos/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/commits/"..GITHUB_CONSTANTS.BRANCH)
    local responseJSON = response.readAll()
    return textutils.unserialiseJSON(responseJSON).sha
end

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
    _G.UpdateScript.performUpdate()
end
