---@class Addon
---@field private __index Addon
---@field private __Name string
---@field private __Color Color|nil
---@field private __BaseDir string|nil
---@field private __Version string|nil
---@field private __LoadSilently boolean
---@field private __ClientFileCount number
---@field private __ServerFileCount number
local Addon = {}
Addon.__index = Addon
Addon.__Name = "Unknown Addon"
Addon.__Color = nil
Addon.__BaseDir = nil
Addon.__Version = nil
Addon.__LoadSilently = false
Addon.__ClientFileCount = 0
Addon.__ServerFileCount = 0

---@class AdyLib: Addon
ADYLIB = ADYLIB or {}
local VERSION = "1.0.0"

---@alias LogLevel
---| "Info"
---| "Warning"
---| "Error"
---| "Debug"
LogLevel = {
    Info = "Info",
    Warning = "Warning",
    Error = "Error",
    Debug = "Debug",
}


local LEVEL_COLORS = {
    [LogLevel.Warning] = Color(255, 255, 0),
    [LogLevel.Error] = Color(255, 0, 0),
    [LogLevel.Debug] = Color(142, 127, 255),
    SUCCESS = Color(40, 255, 144),
}

---@private
---@param level LogLevel
---@param ... unknown Strings and Color objects to display in log
function Addon:__BaseLog(level, ...)
    if level == LogLevel.Debug and not ady.__Debug then return end

    local time = os.date("%H:%M")
    MsgC(color_white, time, " | ")

    local prefixColor = self.__Color or color_white
    MsgC(prefixColor, "[", self.__Name)

    local levelColor = LEVEL_COLORS[level]
    local textColor = color_white
    if levelColor then
        MsgC(prefixColor, " | ", levelColor, level)
        textColor = levelColor
    end

    MsgC(prefixColor, "] ")
    MsgC(textColor, ...)
    MsgC("\n")
end

---@alias LogMessageArg string|Color
local LOG_LEVEL_SET = {}
for _, v in pairs(LogLevel) do LOG_LEVEL_SET[v] = true end

--- **[Server/Client]** Logs a message to console. Works similar to `MsgC`. 
--- 
--- Accepts `string`s and `Color` objects 
--- 
--- If the last argument is a `LogLevel` value, it changes the level of logging
---@overload fun(self: Addon, ...: LogMessageArg, level?: LogLevel)
function Addon:Log(...)
    local args = {...}
    if #args == 0 then return end

    local level = LogLevel.Info
    if LOG_LEVEL_SET[args[#args]] then
        level = args[#args]
        args[#args] = nil
    end

    self:__BaseLog(level, unpack(args))
end

--- TBD Script to share and include client files
---@private
---@param f string
function Addon:__ClientFileHandle(f)
    if self.__ClientFileCount then
        self.__ClientFileCount = self.__ClientFileCount + 1
    end

    if SERVER then
        AddCSLuaFile(f)
        if self.__LoadSilently then return end
        self:Log("~ Shared " .. f)
    else
        local ok, err = xpcall(function() include(f) end, debug.traceback)

        if not ok then
            self:Log("! Failed to load " .. f .. "\n" .. err, LogLevel.Error)
            return
        end

        if self.__LoadSilently then return end
        self:Log("✓ " .. f)
    end
end
--- TBD Script to include server files
---@private
---@param f string
function Addon:__ServerFileHandle(f)
    if not SERVER then return end

    if self.__ServerFileCount then
        self.__ServerFileCount = self.__ServerFileCount + 1
    end

    local ok, err = xpcall(function() include(f) end, debug.traceback)

    if not ok then
        self:Log("! Failed to load " .. f .. "\n" .. err, LogLevel.Error)
        return
    end

    if self.__LoadSilently then return end
    self:Log("+ Loaded " .. f)
end

---TBD Script to share and include shared files
---@private
---@param f string
function Addon:__SharedFileHandle(f)
    self:__ServerFileHandle(f)
    self:__ClientFileHandle(f)
end
Addon.__FileStates = {
    cl = Addon.__ClientFileHandle,
    sv = Addon.__ServerFileHandle,
    sh = Addon.__SharedFileHandle
}

---**[Server/Client]** Returns current addon verison
---@return string
function Addon:GetVersion()
    return self.__Version
end

---comment
---@private
---@param dir? string
---@param depth? integer
function Addon:RecursiveLoad(dir, depth)
    depth = depth or 1
    if depth >= 6 then return end

    dir = dir or self.__BaseDir

    local files, dirs = file.Find(dir .. "/*", "LUA")
    for _, file in ipairs(files) do
        local path = dir .. "/"  .. file
        if string.EndsWith(dir, "vgui") then
            self:__ClientFileHandle(path)
        else
            for stateStr, func in pairs(self.__FileStates) do
                if string.StartsWith(file, stateStr) then
                    func(self, path)
                end
            end
        end
    end

    for _, subfolder in ipairs(dirs) do
        self:RecursiveLoad(dir .. "/" .. subfolder, depth + 1)
    end
end

--- Loads files from a subdirectory using default cl_/sv_/sh_ routing rules
---@param dir string
function Addon:LoadDirectory(dir)
    self:RecursiveLoad(dir)
end

--- TBD Load addon files
---@private
function Addon:__Load(silentLoad)
    silentLoad = silentLoad or self.__LoadSilently or false

    self.__ClientFileCount = 0
    if SERVER then
        self.__ServerFileCount = 0
    end

    self:Log("Loading all files...")
    self:RecursiveLoad()

    local suffix = "("
    local total = 0
    if SERVER then
        suffix = suffix .. self.__ServerFileCount .. " included, " .. self.__ClientFileCount .. " shared)"
        total = self.__ServerFileCount + self.__ClientFileCount
        self.__ServerFileCount = nil
    else
        suffix = ""
        total = self.__ClientFileCount
    end
    self.__ClientFileCount = nil

    self:Log("Successfully loaded ", LEVEL_COLORS.SUCCESS, total, " file" .. (total ~= 1 and "s " or " "), color_white, suffix, LogLevel.Info)
    hook.Run(self.__Name .. "/Loaded")
end

---@class AddonMetadata
---@field baseDir string
---@field name string|nil
---@field color Color|nil
---@field version string|nil

--- **[Server/Client]** Creates a new addon instance that is controlled by AdyLib
--- Provides addon with utility methods, e.g. loading helper and logging
---@param metadata AddonMetadata
---@return Addon Addon
function ADYLIB:CreateAddon(metadata)
    local baseDir = metadata.baseDir
    local addonName = metadata.name or baseDir
    local addonColor = metadata.color or color_white
    local version = metadata.version or "dev-1.0"

    if not baseDir then
        error("No base directory specified", 2)
    end
    if not isstring(baseDir) then
        error("Base directory should be a string, got " .. type(baseDir), 2)
    end

    local addon = {}
    if not addonName or not addonColor then
        local initFile = baseDir .. "/init.lua"
        if not file.Exists(initFile, "LUA") then
            error("Incorrect addon structure - /lua/" .. initFile .. " does not exist", 2)
        end
        if file.Read(initFile, "LUA") == "" then
            error("Incorrect addon structure - /lua/" .. initFile .. " is empty", 2)
        end

        if SERVER then
            AddCSLuaFile("lua/" .. initFile)
        end

        local info = include(initFile)
        if not info or not istable(info) then
            error("Incorrect addon structure - " .. initFile .. " should return addon info (as a table)", 2)
        end

        if not info.Name then
            error("Incorrect addon structure - " .. initFile .. " should return info.Name (string)", 2)
        end
        if not isstring(info.Name) then
            error("Incorrect addon structure - " .. initFile .. " info.Name should be a string, got " .. type(info.Name), 2)
        end
        if not info.Color then
            error("Incorrect addon structure - " .. initFile .. " should return info.Color (Color)", 2)
        end
        if not IsColor(info.Color) then
            error("Incorrect addon structure - " .. initFile .. " info.Color should be a Color, got " .. type(info.Color), 2)
        end

        addon.__Name = info.Name
        addon.__Color = info.Color
    else
        if not isstring(addonName) then
            error("Addon name should be a string, got " .. type(addonName), 2)
        end
        if not IsColor(addonColor) then
            error("Addon color should be a Color, got " .. type(addonColor), 2)
        end
        addon.__Name = addonName
        addon.__Color = addonColor
    end
    addon.__BaseDir = baseDir
    addon.__Version = version

    setmetatable(addon, Addon)
    self.Translator:Register(addon.__Name)

    timer.Simple(0, function()
        addon:__Load()
    end)
    return addon
end

function ADYLIB:__Load()
    self.__Name = "AdyLib"
    self.__Color = Color(52,219,160)
    self.__Version = VERSION
    self.__BaseDir = "ady"
    self.__LoadSilently = false
    self.__Debug = true

    setmetatable(self, Addon)
    Addon.__Load(ADYLIB)
end
ADYLIB:__Load()

---@diagnostic disable-next-line: lowercase-global
ady = ADYLIB