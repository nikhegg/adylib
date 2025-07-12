ADYLIB = ADYLIB or {}

-- UI Scale
local UI_SCALE = {
    x = nil,
    y = nil
}
--- **[Client]** Recalculates screen scaling coefficients based on the current resolution.
--- 
--- **Note: Normally called automatically - avoid manual calls unless necessary.**
function ADYLIB:CalcScales()
    UI_SCALE.x = ScrW()/1920
    UI_SCALE.y = ScrH()/1080
end
ADYLIB:CalcScales()
--- **[Client]** Scales a given pixel value proportionally based on the player's screen width.
--- 
--- In case you need to preserve aspect ratio, use `ADYLIB:ScaleUI(pixels)` instead.
---@param pixels any
---@return number
function ADYLIB:ScaleX(pixels)
    return UI_SCALE.x * pixels
end
--- **[Client]** Scales a given pixel value proportionally based on the player's screen height.
--- 
--- In case you need to preserve aspect ratio, use `ADYLIB:ScaleUI(pixels)` instead.
--- @param pixels number
--- @return number
function ADYLIB:ScaleY(pixels)
    return UI_SCALE.y * pixels
end
--- **[Client]** Scales a given pixel value proportionally based on the player's screen resolution, preserving aspect ratio.
---
--- Use this method to adapt UI elements designed for 1920x1080 to other screen sizes.
---@param pixels number
---@return number
function ADYLIB:ScaleUI(pixels)
    local scale = math.min(UI_SCALE.x, UI_SCALE.y)
    if not scale then return 0 end -- Meaningless thing to be honest...
    if pixels ~= nil and type(pixels) == "number" then
        return scale * pixels
    else
        return scale
    end
end
hook.Add("OnScreenSizeChanged", "AdyLib/ScreenResize", function()
    ADYLIB:CalcScales()
end)

-- Colors

--- **[Client]** Transforms any RGB color format to Garry's Mod Color class.
--- It is allowed to pass either existing color or R,G,B values as separate arguments.
---@param r number|table
---@param g? number
---@param b? number
---@param a? number
---@return Color
function ADYLIB:ToGModColor(r,g,b,a)
    if type(r) ~= "number" then
        if r == nil then
            r = 0
        else
            if type(r) ~= "table" then
                r = {}
            end
            if r.r == nil then r.r = 0 end
            if r.g == nil then r.g = 0 end
            if r.b == nil then r.b = 0 end
            if r.a == nil then r.a = 0 end
            return r
        end
    end
    if g == nil or type(g) ~= "number" then g = 0 end
    if b == nil or type(b) ~= "number" then b = 0 end
    if a == nil or type(a) ~= "number" then a = 0 end
    return Color(r,g,b,a)
end
--- **[Client]** Returns a smoothly transitioning rainbow color based on the current time.
--- Useful for generating animated color effect when called every frame.
---@param speed? number
---@return Color
function ADYLIB:RainbowColor(speed)
    if speed == nil or type(speed) == "number" and speed <= 0 then
        speed = 1
    end
	local time = CurTime()
	local r = math.sin(time * speed + 0) * 127 + 128
	local g = math.sin(time * speed + 2) * 127 + 128
	local b = math.sin(time * speed + 4) * 127 + 128
	return Color(r,g,b)
end
local function ColorInvert(c)
    return Color(255-c.r,255-c.g,255-c.b,c.a)
end
--- Inverts the color. This method does not change alpha channel during transformation.
--- 
--- No need to use `ADYLIB:ToGmodColor(...)` as this method automatically validates the color.
---@param r table|number
---@param g? number
---@param b? number
---@param a? number
---@return Color
function ADYLIB:InvertColor(r,g,b,a)
    return ColorInvert(self:ToGModColor(r,g,b,a))
end

-- Blur
local BLUR = Material("pp/blurscreen")
--- **[Client]** This method be called in Paint methods as it uses `surface` class.
--- 
--- Allows to easily draw blur texture with specified blur depth.
---@param panel Panel
---@param depth number
function ADYLIB:DrawBlurTexture(panel, depth)
    if depth == nil then
        depth = 3
    elseif depth > 30 then
        depth = 30
    end
    local x, y = panel:LocalToScreen(0,0)
    surface.SetDrawColor(Color(255,255,255))
    surface.SetMaterial(BLUR)
    for i=1,depth do
        BLUR:SetFloat("$blur", i)
        BLUR:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end
end