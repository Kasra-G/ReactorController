local OWNER = "Kasra-G"
local REPO = "ReactorController"
local BRANCH = "development"
local COMMIT_FILENAME = "/commit.txt"
local AUTOMATIC_UPDATE_ENABLED = true

--Github: https://github.com/Kasra-G/ReactorController/#readme

local function getRepoDetails(jsonString)
    return textutils.unserialiseJSON(jsonString)
end

local function getRemoteRepoJsonString()
    local response = http.get("https://api.github.com/repos/"..OWNER.."/"..REPO.."/commits/"..BRANCH)
    return response.readAll()
end

local function getLocalRepoJsonString()
    local file = fs.open(COMMIT_FILENAME, "r")
    if file == nil then
        print("Local version file not found! Assuming there is an update available.")
        return "{}"
    end
    local contents = file.readAll()
    file.close()
    return contents
end

local function checkForUpdate(localRepoDetails, remoteRepoDetails)
    return localRepoDetails.sha ~= remoteRepoDetails.sha
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

function _G.performUpdate(remoteRepoRootTreeSHA)
    deleteExistingFiles()
    downloadRemoteSrcDirectory(remoteRepoRootTreeSHA)
    downloadGitHubFileContents("startup")
end

local remoteRepoJson = getRemoteRepoJsonString()
local remoteRepoDetails = getRepoDetails(remoteRepoJson)

local localRepoJson = getLocalRepoJsonString()
local localRepoDetails = getRepoDetails(localRepoJson)

local update_available = checkForUpdate(localRepoDetails, remoteRepoDetails)

if update_available and AUTOMATIC_UPDATE_ENABLED then
    performUpdate(remoteRepoDetails.sha)
end