local LOCAL_REPO_DETAILS_FILENAME = "/commit.txt"

local function getRemoteRepoSHA()
    local response = http.get("https://api.github.com/repos/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/commits/"..GITHUB_CONSTANTS.BRANCH)
    local responseJSON = response.readAll()
    return textutils.unserialiseJSON(responseJSON).sha
end

local function getLocalRepoSHA(filepath)
    local file = fs.open(filepath, "r")
    if file == nil then
        print("Local version file not found! Assuming there is an update available.")
        return ""
    end
    local contents = file.readAll()
    file.close()
    return textutils.unserialiseJSON(contents)
end

local function saveRepoSHA(repoSHA, path)
    local file = fs.open(path, "w")
    file.write(textutils.serializeJSON(repoSHA))
    file.close()
end

local function deleteExistingFiles()
    fs.delete("/src")
    fs.delete("/defaults")
    fs.delete("/state")
    fs.delete("startup")
end

local function downloadGitHubFileByPath(filepath)
    local endpoint = "https://raw.githubusercontent.com/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/refs/heads/"..GITHUB_CONSTANTS.BRANCH.."/"..filepath
    local response = http.get(endpoint)
    local contents = response.readAll()
    local file = fs.open(filepath, "w")
    file.write(contents)
    file.close()
end

local function getGitHubTreeDetails(treeSHA)
    local endpoint = "https://api.github.com/repos/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/git/trees/"..treeSHA
    local response = http.get(endpoint)
    local contents = response.readAll()
    return textutils.unserialiseJSON(contents)
end

local function downloadGitHubTreeRecursively(path, treeSHA)
    local treeDetails = getGitHubTreeDetails(treeSHA)
    for _, treeEntry in pairs(treeDetails.tree) do
        local subfilePath = path.."/"..treeEntry.path
        if treeEntry.type == "tree" then
            downloadGitHubTreeRecursively(subfilePath, treeEntry.sha)
        elseif treeEntry.type == "blob" then
            downloadGitHubFileByPath(subfilePath)
        end
    end
end

local function downloadRemoteSrcDirectory(remoteRepoRootTreeSHA)
    local remoteRepoRootTreeDetails = getGitHubTreeDetails(remoteRepoRootTreeSHA)
    local srcDirectoryName = "src"

    for _, treeEntry in pairs(remoteRepoRootTreeDetails.tree) do
        if treeEntry.path == srcDirectoryName and treeEntry.type == "tree" then
            downloadGitHubTreeRecursively(srcDirectoryName, treeEntry.sha)
        end
    end
end

--- Checks if there is an update to install
---@return boolean
local function checkForUpdate()
    local remoteRepoSHA = getRemoteRepoSHA()
    local localRepoSHA = getLocalRepoSHA(LOCAL_REPO_DETAILS_FILENAME)
    return localRepoSHA ~= remoteRepoSHA
end

--- Updates and saves the project. src and startup files are deleted and then redownloaded.
local function performUpdate()
    local remoteRepoSHA = getRemoteRepoSHA()

    deleteExistingFiles()
    downloadRemoteSrcDirectory(remoteRepoSHA)
    downloadGitHubFileByPath("startup")
    saveRepoSHA(remoteRepoSHA, LOCAL_REPO_DETAILS_FILENAME)
end

_G.UpdateScript = {
    checkForUpdate = checkForUpdate,
    performUpdate = performUpdate,
    saveRepoDetails = saveRepoSHA,
}
