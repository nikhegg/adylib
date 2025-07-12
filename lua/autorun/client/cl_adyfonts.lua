ADYLIB = ADYLIB or {}

local fontCache = {}
local fontParams = {
    antialias = function(name, bool)
        if not bool then return "NoAA-" .. name end
        return name
    end,
    weight = function(name, weight)
        return name .. "-" .. weight .. "W"
    end,
    shadow = function(name, bool)
        if not bool then return name end
        return name .. "-SHADOW"
    end,
    italic = function(name, bool)
        if not bool then return name end
        return name .. "-ITALIC"
    end,
    underline = function(name, bool)
        if not bool then return name end
        return name .. "-UNDERLINE"
    end,
    outline = function(name, bool)
        if not bool then return name end
        return name .. "-OUTLINE"
    end,
    strikeout = function(name, bool)
        if not bool then return name end
        return name .. "-STRIKEOUT"
    end,
    symbol = function(name, bool)
        if not bool then return name end
        return name .. "-SYMBOL"
    end,
    rotary = function(name, bool)
        if not bool then return name end
        return name .. "-ROTARY"
    end,
    additive = function(name, bool)
        if not bool then return end
        return name .. "-ADDITIVE"
    end,
    blursize = function(name, blursize)
        if blursize == 0 then return name end
        return name .. "-BLUR" .. blursize
    end,
    scanlines = function(name, scanlines)
        if scanlines == 0 then return name end
        return name .. "-SL" .. scanlines
    end,
}

--- **[Client]** `ADYLIB:CreateFont` is an alternative approach to Garry's Mod fonts. 
--- This method allows you not to create a name for your font. 
--- It generates the name by font parameters instead.
--- 
--- ```
--- local titleFont = ADYLIB:CreateFont({
---     font="Arial",
---     size=32,
---     antialias=true
--- })
--- label:SetFont(titleFont)
--- ```
--- 
--- This method will be useful when you use the same font in different files and it's not guaranteed that required font exists.
--- It also prevents you from generating same fonts with different names.
---@param tbl FontData
---@returns name string
function ADYLIB:CreateFont(tbl)
    tbl.size = ADYLIB:ScaleUI(tbl.size)
    local name = tbl.font .. "-" .. tbl.size
    
    for k,changeFunc in pairs(fontParams) do
        if tbl[k] ~= nil then
            name = changeFunc(name, tbl[k])
        end
    end

    if not table.HasValue(fontCache, name) then
        surface.CreateFont(name, tbl)
    end

    return name
end