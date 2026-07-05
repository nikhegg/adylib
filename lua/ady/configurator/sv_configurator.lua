---@class AdyLib
ADYLIB = ADYLIB or {}
ADYLIB.Config = ADYLIB.Config or {}

---@class AdyConfigurator
---@field private __index AdyConfigurator
---@field private __Path string
---@field private __Config table
---@field AutosaveMins number
---@field LastSaveTime number
local AdyConfigurator = {}
AdyConfigurator.__index = AdyConfigurator
AdyConfigurator.__Path = ""
AdyConfigurator.__Config = {}
AdyConfigurator.AutosaveMins = 0
AdyConfigurator.LastSaveTime = 0
---**[Server]** Sets config value by key
---@param key string
---@param value any
function AdyConfigurator:Set(key, value)
    self.__Config[key] = value
end
---**[Server]** Returns the value that is stored in config by key
---@param key string
---@return any
function AdyConfigurator:Get(key)
    return self.__Config[key]
end
---**[Server]** Removes value in config by specified key
---@param key string
function AdyConfigurator:Delete(key)
    self.__Config[key] = nil
end
---**[Server]** Returns whole config as Lua table
---@return table
function AdyConfigurator:GetAll()
    return self.__Config
end
---**[Server]** Saves the config to its' file. Automatically invoked on server shutdown
function AdyConfigurator:Save()
    if not file.Exists(self.__Path, "DATA") then
        ADYLIB:Log("Cannot save config: " .. self.__Path .. " does not exist", LogLevel.Warning)
        return
    end

    local json = util.TableToJSON(self.__Config)
    file.Write(self.__Path, json)

    local now = os.time()
    self.LastSaveTime = now
end
---**[Server]** Sets the frequency of config automatic save in minutes
---@param mins number
function AdyConfigurator:SetAutosave(mins)
    if type(mins) ~= "number" then return end
    self.AutosaveMins = mins
end


---@type table<number, AdyConfigurator>
local configurators = {}
---**[Server]** TBD
---@param path string
---@return AdyConfigurator
function ADYLIB.Config:Use(path)
    local obj = {}
    setmetatable(obj, AdyConfigurator)

    obj.__Path = path
    local pathSplit = string.Split(path, "/")
    table.remove(pathSplit, #pathSplit)

    for _, dir in ipairs(path) do
        if not file.IsDir(dir, "DATA") then
            file.CreateDir(dir)
        end
    end

    local configString = "{}"
    if not file.Exists(path, "DATA") then
        file.Write(path, configString)
    else
        configString = file.Read(path, "DATA")
    end

    obj.__Config = util.JSONToTable(configString) or {}

    table.insert(configurators, obj)
    return obj
end

---**[Server]** TBD
function ADYLIB.Config:SaveAll()
    for _, config in pairs(configurators) do
        config:Save()
    end
end

local function ConfigAutosave()
    for _, config in ipairs(configurators) do
        local autosaveTime = config.AutosaveMins
        if autosaveTime and autosaveTime > 0 then
            autosaveTime = autosaveTime * 60 -- To seconds
            local now = os.time()
            local lastSave = config.LastSaveTime
            if now - lastSave >= autosaveTime then
                config:Save()
            end
        end
    end
end

hook.Add("Initialize", "Ady/StartConfigsAutosave", function()
    timer.Create("Ady/ConfigsAutosave", 60, 0, ConfigAutosave)
end)

hook.Add("ShutDown", "Ady/SaveConfigs", function()
    ADYLIB.Config:SaveAll()
end)