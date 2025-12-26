ADYLIB = {}

local VERSION = "1.0"
--- **[Server/Client]** Return the version of AdyLib
--- @return string
function ADYLIB:GetVersion()
    return VERSION
end


---@class Addon
local Addon = {}
Addon.__index = Addon
Addon.AddonName = "Unknown Addon"
Addon.AddonColor = nil
Addon.BaseDir = nil
Addon.LoadSilently = false

local LEVELS = {
    WARNING = Color(255,255,0),
    ERROR = Color(255,0,0),
    DEBUG = Color(142,127,255),
    SUCCESS = Color(40,255,144)
}
--- TBD BaseLog method
---@private
---@param level string -- Types???
---@param ... unknown
function Addon:_BaseLog(level, ...)
    level = string.upper(level)

    local prefixColor = self.AddonColor or color_white
    MsgC(prefixColor, "[", self.AddonName)
    
    local levelColor = LEVELS[level]
    local textColor = color_white
    if levelColor then
        MsgC(prefixColor, " | ", levelColor, level)
        textColor = levelColor
    end
    -- MsgC(prefixColor, "] ", textColor, ..., "\n")
    MsgC(prefixColor, "] ")
    MsgC(textColor, ...)
    MsgC("\n")
end

--- TBD Log anything
---@param ... unknown
function Addon:Log(...)
    self:_BaseLog("info", ...)
end

--- TBD Log any warning
---@param ... unknown
function Addon:LogWarning(...)
    self:_BaseLog("warning", ...)
end

---TBD Log any error
---@param ... unknown
function Addon:LogError(...)
    self:_BaseLog("error", ...)
end

function Addon:LogDebug(...)
    self:_BaseLog("debug", ...)
end

--- TBD Script to share and include client files
---@private
---@param f string
function Addon:_ClientFileHandle(f)
    if self.ClientFileCount then
        self.ClientFileCount = self.ClientFileCount + 1
    end

    if SERVER then
        AddCSLuaFile(f)
        if self.LoadSilently then return end
        self:Log("~ Sharing " .. f)
    else
        include(f)
        if self.LoadSilently then return end
        -- self:Log("Loading " .. f .. " ✓")
        self:Log("✓ " .. f)
    end
end
--- TBD Script to include server files
---@private
---@param f string
function Addon:_ServerFileHandle(f)
    if not SERVER then return end

    if self.ServerFileCount then
        self.ServerFileCount = self.ServerFileCount + 1
    end

    if not self.LoadSilently then
        self:Log("+ Loading " .. f)
    end

    include(f)
end
---TBD Script to share and include shared files
---@private
---@param f string
function Addon:_SharedFileHandle(f)
    self:_ServerFileHandle(f)
    self:_ClientFileHandle(f)
end
Addon.FileStates = {
    cl = Addon._ClientFileHandle,
    sv = Addon._ServerFileHandle,
    sh = Addon._SharedFileHandle
}

---comment
---@private
---@param dir? string
---@param depth? integer
function Addon:RecursiveLoad(dir, depth)
    depth = depth or 1
    if depth >= 6 then return end

    dir = dir or self.BaseDir

    local files, dirs = file.Find(dir .. "/*", "LUA")
    for _, file in ipairs(files) do
        local path = dir .. "/"  .. file
        if string.EndsWith(dir, "vgui") then
            self:_ClientFileHandle(path)
        else
            for stateStr, func in pairs(self.FileStates) do
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

--- TBD Load addon files
function Addon:Load(silentLoad)
    silentLoad = silentLoad or self.LoadSilently or false

    -- local prefix = (SERVER and "Server") or (CLIENT and "Client") or "Void"
    self.ClientFileCount = 0
    if SERVER then
        self.ServerFileCount = 0
    end

    self:Log("Loading all files...")
    self:RecursiveLoad()

    local suffix = "("
    local total = 0
    if SERVER then
        suffix = suffix .. self.ServerFileCount .. " included, " .. self.ClientFileCount .. " shared)"
        total = self.ServerFileCount + self.ClientFileCount
        self.ServerFileCount = nil
    else
        suffix = ""
        total = self.ClientFileCount
    end
    self.ClientFileCount = nil

    self:Log("Successfully loaded ", LEVELS.SUCCESS, total, " file" .. (total ~= 1 and "s" or "") .. " ", color_white , suffix)
    hook.Run(self.AddonName .. "/Loaded")
end

--- TBD Initialize addon
---@param baseDir string
---@param addonName? string
---@param addonColor? string
---@return Addon Addon
function ADYLIB:CreateAddon(baseDir, addonName, addonColor)
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

        addon.AddonName = info.Name
        addon.AddonColor = info.Color
    else
        if not isstring(addonName) then
            error("Addon name should be a string, got " .. type(addonName), 2)
        end
        if not IsColor(addonColor) then
            error("Addon color should be a Color, got " .. type(addonColor), 2)
        end
        addon.AddonName = addonName
        addon.AddonColor = addonColor
    end
    addon.BaseDir = baseDir

    setmetatable(addon, Addon)
    self.Translator:Register(addon.AddonName)
    return addon
end

function ADYLIB:Load()
    self.AddonName = "AdyLib"
    self.AddonColor = Color(52,219,160)
    self.BaseDir = "ady"
    self.LoadSilently = false

    setmetatable(self, Addon)
    Addon.Load(ADYLIB)
end

ADYLIB:Load()