local LOCAL_REPO_DETAILS_FILENAME = "/commit.txt"
local GITHUB_CONSTANTS = {
    OWNER = "Kasra-G",
    REPO = "ReactorController",
    BRANCH = "development",
}

local FILES_TO_DELETE_ON_UPDATE = {
    "/src",
    "/defaults",
    "/state",
    "startup",
}

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

local function downloadGitHubFileByPath(filepath, tempFoldername)
    if tempFoldername == nil then
        tempFoldername = ""
    end

    local endpoint = "https://raw.githubusercontent.com/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/refs/heads/"..GITHUB_CONSTANTS.BRANCH.."/"..filepath
    local response = http.get(endpoint)
    local contents = response.readAll()
    local file = fs.open(fs.combine(tempFoldername, filepath), "w")
    file.write(contents)
    file.close()
    print("File", filepath, "downloaded!")
end

local function getGitHubTreeDetails(treeSHA)
    local endpoint = "https://api.github.com/repos/"..GITHUB_CONSTANTS.OWNER.."/"..GITHUB_CONSTANTS.REPO.."/git/trees/"..treeSHA
    local response = http.get(endpoint)
    local contents = response.readAll()
    return textutils.unserialiseJSON(contents)
end

local function downloadGitHubTreeRecursively(path, treeSHA, tempFoldername)
    local treeDetails = getGitHubTreeDetails(treeSHA)
    for _, treeEntry in pairs(treeDetails.tree) do
        local subfilePath = path.."/"..treeEntry.path
        if treeEntry.type == "tree" then
            downloadGitHubTreeRecursively(subfilePath, treeEntry.sha, tempFoldername)
        elseif treeEntry.type == "blob" then
            downloadGitHubFileByPath(subfilePath, tempFoldername)
        end
    end
end

local function downloadRemoteSrcDirectory(remoteRepoRootTreeSHA, tempFoldername)
    local remoteRepoRootTreeDetails = getGitHubTreeDetails(remoteRepoRootTreeSHA)
    local srcDirectoryName = "src"

    for _, treeEntry in pairs(remoteRepoRootTreeDetails.tree) do
        if treeEntry.path == srcDirectoryName and treeEntry.type == "tree" then
            downloadGitHubTreeRecursively(srcDirectoryName, treeEntry.sha, tempFoldername)
        end
    end
end

--- Checks if there is an update to install
---@return boolean
local function checkForUpdate()
    local remoteRepoSHA
    local success, err = pcall(function() remoteRepoSHA = getRemoteRepoSHA() end)
    if not success then
        print("Could not check for update with error", err)
        return false
    end
    local localRepoSHA = getLocalRepoSHA(LOCAL_REPO_DETAILS_FILENAME)
    return localRepoSHA ~= remoteRepoSHA
end

--- Updates and saves the project. src and startup files are deleted and then redownloaded.
local function performUpdate()
    local remoteRepoSHA
    local success, err = pcall(function() remoteRepoSHA = getRemoteRepoSHA() end)
    if not success then
        print("Could not reach remote repository with error", err)
        return false
    end

    local tempFoldername = "temp"

    success, err = pcall(
        function()
            downloadRemoteSrcDirectory(remoteRepoSHA, "temp")
            downloadGitHubFileByPath("startup", "temp")
        end
    )
    if not success then
        print("Repo download failed with error", err)
        fs.delete(tempFoldername)
        return false
    end
    for _, filepath in pairs(FILES_TO_DELETE_ON_UPDATE) do
        fs.delete(filepath)
    end
    for _, filename in pairs(fs.list(tempFoldername)) do
        fs.move(fs.combine(tempFoldername, filename), filename)
    end

    saveRepoSHA(remoteRepoSHA, LOCAL_REPO_DETAILS_FILENAME)
    fs.delete(tempFoldername)
    return success
end

_G.UpdateScript = {
    checkForUpdate = checkForUpdate,
    performUpdate = performUpdate,
    saveRepoDetails = saveRepoSHA,
}
