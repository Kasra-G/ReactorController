
local CONFIGS = {}
CONFIGS["update"] = UPDATE_CONFIG

local DEFAULTS_PATH = "/defaults/"
local OVERRIDES_PATH = "/overrides/"
local STATE_PATH = "/state/"
local CONFIG_EXTENSION = ".default.conf"
local OVERRIDE_EXTENSION = ".override.conf"
local STATE_EXTENSION = ".state.conf"

local function isTableEmpty(table)
    for _, _ in pairs(table) do
        return false
    end
    return true
end

local function serializeTableAndWriteToFile(table, path)
    local file = fs.open(path, "w")
    file.write(textutils.serialize(table))
    file.close()
end

local function readFileAndReturnDeserialized(path)
    local file = fs.open(path, "r")
    if file == nil then
        return {}
    end
    local contents = file.readAll()
    file.close()
    return textutils.unserialise(contents)
end

local function readState(stateID)
    return readFileAndReturnDeserialized(STATE_PATH..stateID..STATE_EXTENSION)
end

local function readConfigDefaults(configID)
    return readFileAndReturnDeserialized(DEFAULTS_PATH..configID..CONFIG_EXTENSION)
end

local function readConfigOverrides(configID)
    return readFileAndReturnDeserialized(OVERRIDES_PATH..configID..OVERRIDE_EXTENSION)
end

local function spread(source, destination)
    for key, value in pairs(source) do
        destination[key] = value
    end
end

local function readConfig(configID)
    local configData = CONFIGS[configID]
    local defaults = readConfigDefaults(configID)
    local overrides = readConfigOverrides(configID)
    spread(defaults, configData)
    spread(overrides, configData)
end

local function writeConfig(configID)
    local configData = CONFIGS[configID]
    local defaults = readConfigDefaults(configID)
    local overrides = {}
    for key, value in pairs(configData) do
        if configData[key] ~= defaults[key] then
            overrides[key] = value
        end
    end

    if isTableEmpty(overrides) then
        fs.delete(OVERRIDES_PATH..configID..OVERRIDE_EXTENSION)
        return
    end
    serializeTableAndWriteToFile(overrides, OVERRIDES_PATH..configID..OVERRIDE_EXTENSION)
end

local function writeState(stateID, stateData)
    serializeTableAndWriteToFile(stateData, STATE_PATH..stateID..STATE_EXTENSION)
end

local function writeConfigAsDefault(configID)
    local configData = CONFIGS[configID]
    serializeTableAndWriteToFile(configData, DEFAULTS_PATH..configID..CONFIG_EXTENSION)
end

local function writeAllConfigsAsDefaults()
    for configID, _ in pairs(CONFIGS) do
        writeConfigAsDefault(configID)
    end
end

local function readAllConfigs()
    for configID, _ in pairs(CONFIGS) do
        readConfig(configID)
    end
end

local function writeAllConfigs()
    for configID, _ in pairs(CONFIGS) do
        writeConfig(configID)
    end
end

local function resetConfig(configID)
    fs.delete(OVERRIDES_PATH..configID..OVERRIDE_EXTENSION)
    readConfig(configID)
end

_G.ConfigUtil = {
    writeAllConfigsAsDefaults = writeAllConfigsAsDefaults,
    writeAllConfigs = writeAllConfigs,
    readAllConfigs = readAllConfigs,
    writeConfig = writeConfig,
    writeState = writeState,
    readConfig = readConfig,
    readState = readState,
    resetConfig = resetConfig,
}
