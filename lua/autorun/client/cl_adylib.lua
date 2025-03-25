ADYLIB = ADYLIB or {}

-- UI Scale
local UI_SCALE = {
    x = nil,
    y = nil
}
function ADYLIB:CalcScales()
    UI_SCALE.x = ScrW()/1920
    UI_SCALE.y = ScrH()/1080
end
ADYLIB:CalcScales()
-- Should be used to calc the width of window or panel with dynamic size
function ADYLIB:ScaleX()
    return UI_SCALE.x
end
-- Should be used to calc the height of window or panel with dynamic size
function ADYLIB:ScaleY()
    return UI_SCALE.y
end
-- Should be used to calc size of elements with static size
function ADYLIB:ScaleUI(pixels)
    local scale = math.min(UI_SCALE.x, UI_SCALE.y)
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
function ADYLIB:InvertColor(r,g,b,a)
    return ColorInvert(self:ToGModColor(r,g,b,a))
end

-- Blur
local BLUR = Material("pp/blurscreen")
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