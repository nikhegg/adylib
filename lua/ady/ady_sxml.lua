ADYLIB = ADYLIB or {}
local SXML = {}

local function GetTagPattern(tag)
    return "<" .. tag .. ">(.-)</" .. tag .. ">"
end
local function GetCDataPattern(tag)
    return "<" .. tag .. ">%s*<!%[CDATA%[(.-)%]%]>%s*</" .. tag .. ">"
end

local function RegexExtract(str, pattern, firstMatchOnly)
    if firstMatchOnly then
        return str:match(pattern) or ""
    else
        local data = {}
        for match in string.gmatch(str, pattern) do
            table.insert(data, match)
        end
        return data
    end
end

function SXML:ExtractTagData(xml, tag, firstMatchOnly)
    local pattern = GetTagPattern(tag)
    return RegexExtract(xml, pattern, firstMatchOnly)
end

function SXML:ExtractCData(xml, tag, firstMatchOnly)
    local pattern = GetCDataPattern(tag)
    return RegexExtract(xml, pattern, firstMatchOnly)
end

ADYLIB.SXML = SXML