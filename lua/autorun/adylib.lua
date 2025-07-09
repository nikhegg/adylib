local VERSION = "1.0"
ADYLIB = {}

local f = {
    {n="ady/ady_sxml.lua",t="sh"},
    {n="ady/ady_messages.lua",t="sh"},
    {n="ext/cl_melons_masks.lua",t="c"}
}
for k,v in ipairs(f) do
    if SERVER then
        if v.t ~= "s" then AddCSLuaFile(v.n) end
        if v.t ~= "c" then include(v.n) end
    end
    if CLIENT and v.t ~= "s" then include(v.n) end
end

ADYLIB.Random = {}
local smalls = "abcdefghijklmnopqrstuvwxyz"
local capitals = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local numbers = "0123456789"
local symbols = "!@#$%^&*-_+="

---@class RandomStringParams
---@field capitals boolean|nil
---@field numbers boolean|nil
---@field smalls boolean|nil
---@field symbols boolean|nil

--- **[Server/Client]** Returns random string of specified length. Use `params` to customize the generation.
---@param length number
---@param params RandomStringParams
---@return string
function ADYLIB.Random:GetRandomString(length, params)
    local chars
    if params then
        chars = ""
        if params.smalls then chars = chars .. smalls end
        if params.capitals then chars = chars .. capitals end
        if params.numbers then chars = chars .. numbers end
        if params.symbols then chars = chars .. symbols end
    end
    if #chars == 0 then
        chars = smalls .. capitals .. numbers
    end

    if #chars == 0 then return "" end
    local str = ""
    for i=1,length do
        local rand = math.random(1, #chars)
        str = str .. string.sub(chars, rand, rand)
    end
    return str
end

--- **[Server/Client]** Returns the length of any string counting cyrillic symbols as one instead of two.
function ADYLIB:CyrillicStringLength(str)
    return #(str:gsub('[\128-\191]',''))
end

function ADYLIB:StringCharSplit(str)
    local chars = {}
    -- Используем UTF-8 aware pattern для разбора символов
    for uchar in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, uchar)
    end
    return chars
end

--- **[Server/Client]** Return the version of AdyLib
--- @return string
function ADYLIB:GetVersion()
    return VERSION
end