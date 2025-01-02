local OWNER = "Kasra-G"
local REPO = "ReactorController"
local BRANCH = "development"
local COMMIT_FILENAME = "/commit.txt"

--Github: https://github.com/Kasra-G/ReactorController/#readme

local function getRemoteRepoDetails()
    local response = http.get("https://api.github.com/repos/"..OWNER.."/"..REPO.."/commits/"..BRANCH)
    local responseJSON = response.readAll()
    return textutils.unserialiseJSON(responseJSON)
end

local function getLocalRepoDetails()
    local file = fs.open(COMMIT_FILENAME, "r")
    if file == nil then
        print("Local version file not found! Assuming there is an update available.")
        return "{}"
    end
    local contents = file.readAll()
    file.close()
    return textutils.unserialiseJSON(contents)
end

local function saveRepoDetails(repoDetails)
    local serialized = textutils.serializeJSON(repoDetails)
    local file = fs.open(COMMIT_FILENAME, "w")
    file.write(serialized)
    file.close()
end

local function deleteExistingFiles()
    fs.delete("/src")
    fs.delete("startup")
end

local function downloadGitHubFileContents(filepath)
    local endpoint = "https://raw.githubusercontent.com/"..OWNER.."/"..REPO.."/refs/heads/"..BRANCH.."/"..filepath
    local response = http.get(endpoint)
    local contents = response.readAll()
    local file = fs.open(filepath, "w")
    file.write(contents)
    file.close()
end

local function getGitHubTreeDetails(treeSHA)
    local endpoint = "https://api.github.com/repos/"..OWNER.."/"..REPO.."/git/trees/"..treeSHA
    local response = http.get(endpoint)
    local contents = response.readAll()
    local treeDetails = textutils.unserialiseJSON(contents)
    return treeDetails
end

local function downloadGitHubTreeRecursively(path, treeSHA)
    local treeDetails = getGitHubTreeDetails(treeSHA)
    for _, treeEntry in pairs(treeDetails.tree) do
        if treeEntry.type == "tree" then
            downloadGitHubTreeRecursively(path.."/"..treeEntry.path, treeEntry.sha)
        else
            downloadGitHubFileContents(path.."/"..treeEntry.path)
        end
    end
end

local function downloadRemoteSrcDirectory(remoteRepoRootTreeSHA)
    local remoteRepoRootTreeDetails = getGitHubTreeDetails(remoteRepoRootTreeSHA)
    local srcDirectoryName = "src"

    for _, treeEntry in pairs(remoteRepoRootTreeDetails.tree) do
        print(treeEntry.path)
        if treeEntry.path == srcDirectoryName then
            downloadGitHubTreeRecursively(srcDirectoryName, treeEntry.sha)
        end
    end
end

local remoteRepoDetails

local function performUpdate()
    deleteExistingFiles()
    downloadRemoteSrcDirectory(remoteRepoDetails.sha)
    downloadGitHubFileContents("startup")
end

local function checkForUpdate()
    remoteRepoDetails = getRemoteRepoDetails()

    local localRepoDetails = getLocalRepoDetails()

    local updateAvailable = localRepoDetails.sha ~= remoteRepoDetails.sha

    return updateAvailable
end

_G.UpdateScript = {
    checkForUpdate = checkForUpdate,
    performUpdate = performUpdate,
    saveRepoDetails = saveRepoDetails,
}