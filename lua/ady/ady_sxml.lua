ADYLIB = ADYLIB or {}
local SXML = {}

--- Transforms tag string to RegEx Tag string
---@param tag string
---@return string
local function GetTagPattern(tag)
    return "<" .. tag .. ">(.-)</" .. tag .. ">"
end
--- Transforms tag string to RegEx CDATA string
---@param tag string
---@return string
local function GetCDataPattern(tag)
    return "<" .. tag .. ">%s*<!%[CDATA%[(.-)%]%]>%s*</" .. tag .. ">"
end

--- Main function to extract pattern from any string
---@param str string
---@param pattern string
---@param firstMatchOnly? boolean
---@return string|table
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

--- **[Server/Client]** This method allows to extract Tag Data (the one that is not wrapped with `![CDATA[...]]`) from an XML string.
--- Tag name should be clear and without any XML formatting (so use **tag** instead of **<tag>**).
--- 
--- By default this method returns list of all matches. You can change is by setting third argument `firstMatchOnly` to `true` so it will return string.
---@param xml string
---@param tag string
---@param firstMatchOnly? boolean
---@return string|table
function SXML:ExtractTagData(xml, tag, firstMatchOnly)
    local pattern = GetTagPattern(tag)
    return RegexExtract(xml, pattern, firstMatchOnly)
end

--- **[Server/Client]** This method allows to extract `![CDATA[...]]` from an XML string.
--- Tag name should be clear and without any XML formatting (so use **tag** instead of **<tag>**).
--- 
--- By default this method returns list of all matches. You can change is by setting third argument `firstMatchOnly` to `true` so it will return string.
---@param xml string
---@param tag string
---@param firstMatchOnly? boolean
---@return string|table
function SXML:ExtractCData(xml, tag, firstMatchOnly)
    local pattern = GetCDataPattern(tag)
    return RegexExtract(xml, pattern, firstMatchOnly)
end

ADYLIB.SXML = SXML