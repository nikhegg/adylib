local VERSION = "1.0"
ADYLIB = {}

local f = {
    {n="ady/ady_sxml.lua",t="sh"},
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
function ADYLIB.Random:GetRandomString(length, params)
    --[[
        Params = {
            symbols: true/false,
            numbers: true/false,
            smalls: true/false,
            capitals: true/false,
        }
    ]]
    local chars
    if params then
        chars = ""
        if params.smalls then chars = chars .. smalls end
        if params.capitals then chars = chars .. capitals end
        if params.numbers then chars = chars .. numbers end
        if params.symbols then chars = chars .. symbols end
    else
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

function ADYLIB:CyrillicStringLength(str)
    return #(str:gsub('[\128-\191]',''))
end

function ADYLIB:GetVersion()
    return VERSION
end