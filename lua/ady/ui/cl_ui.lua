ADYLIB = ADYLIB or {}
ADYLIB.UI = ADYLIB.UI or {}

-- Globals
GRADIENT_UP = Material("vgui/gradient_up")
GRADIENT_DOWN = Material("vgui/gradient_down")
GRADIENT_LEFT = Material("vgui/gradient-r")
GRADIENT_RIGHT = Material("vgui/gradient-l")


local function BuildPoly(x, y, w, h, radii, uvFunc)
    local tl = radii.top_left or 0
    local tr = radii.top_right or 0
    local br = radii.bottom_right or 0
    local bl = radii.bottom_left or 0

    local maxR = math.min(w, h) * 0.5
    tl = math.min(tl, maxR); tr = math.min(tr, maxR)
    br = math.min(br, maxR); bl = math.min(bl, maxR)

    uvFunc = uvFunc or function(vx, vy) return vx / w, vy / h end

    local verts = {}
    local function addVert(vx, vy)
        local u, v = uvFunc(vx, vy)
        verts[#verts + 1] = { x = x + vx, y = y + vy, u = u, v = v }
    end

    -- Порядок углов по часовой стрелке (Y вниз)
    local corners = {
        { tl,     tl,     tl, 180, 270 },
        { w - tr, tr,     tr, 270, 360 },
        { w - br, h - br, br,   0,  90 },
        { bl,     h - bl, bl,  90, 180 },
    }
    for _, c in ipairs(corners) do
        local cx, cy, r, a1, a2 = c[1], c[2], c[3], c[4], c[5]
        local steps = math.max(6, math.ceil(r * 0.5))
        for i = 0, steps do
            local a = math.rad(a1 + (a2 - a1) * i / steps)
            addVert(cx + math.cos(a) * r, cy + math.sin(a) * r)
        end
    end
    return verts
end

---comment
---@param round_radius any
---@return table radii Table of radii
---@return boolean zeroRadii Returns `true` if all radii are zero and `false` otherwise
local function GetRadii(round_radius)
    local radii = { top_left=0, top_right=0, bottom_left=0, bottom_right=0 }
    if round_radius == nil then return radii, true end

    local rr = round_radius
    local rrType = type(rr)
    if type(rr) == "number" then
        for k,_ in pairs(radii) do
            radii[k] = rr
        end
    elseif rrType == "table" then
        for k, v in pairs(rr) do
            if radii[k] then radii[k] = v end
        end
    end

    local zeroRadii = true
    for _, v in pairs(radii) do
        if v ~= 0 then zeroRadii = false end
    end

    return radii, zeroRadii
end

---@class RoundRadiusOptions
---@field top_left number|nil
---@field top_right number|nil
---@field bottom_left number|nil
---@field bottom_right number|nil

---@class DrawRectOptions
---@field color Color|nil
---@field material IMaterial|nil
---@field round_radius RoundRadiusOptions|number|nil

---comment
---@param x number
---@param y number
---@param width number
---@param height number
---@param options DrawRectOptions|nil
--
function ADYLIB.UI:DrawRect(x, y, width, height, options)
    local radii, zeroRadii = GetRadii(nil)
    draw.NoTexture()

    -- Options handler
    if options ~= nil then
        -- Round Radius handler
        if options.round_radius ~= nil then
            radii, zeroRadii = GetRadii(options.round_radius)
        end

        if options.color then surface.SetDrawColor(options.color) end
        if options.material then surface.SetMaterial(options.material) end
    end

    if zeroRadii then
        surface.DrawTexturedRect(x, y, width, height)
    else
        local verts = BuildPoly(x, y, width, height, radii)
        surface.DrawPoly(verts)
    end
end


local blurMat = Material("pp/blurscreen")
local blurRT = GetRenderTargetEx(
    "BlurPanel_RT",
    ScrW(), ScrH(),
    RT_SIZE_LITERAL,
    MATERIAL_RT_DEPTH_NONE,
    bit.bor(4, 8),  -- TEXTUREFLAGS_CLAMPS | TEXTUREFLAGS_CLAMPT
    0,
    IMAGE_FORMAT_BGRA8888
)
local blurRTMat = CreateMaterial("BlurPanel_RTMat", "UnlitGeneric", {
    ["$basetexture"] = blurRT:GetName(),
    ["$translucent"] = "1",
    ["$vertexcolor"] = "1",
    ["$vertexalpha"] = "1",
    ["$nofog"] = "1",
    ["$ignorez"] = "1",
})
local function RenderBlurToRT(intensity)
    local sw, sh = ScrW(), ScrH()

    render.UpdateScreenEffectTexture()  -- снимаем текущий кадр
    render.PushRenderTarget(blurRT)
    cam.Start2D()
        surface.SetMaterial(blurMat)
        surface.SetDrawColor(255, 255, 255, 255)
        for i = 1, 3 do
            blurMat:SetFloat("$blur", (i / 3) * intensity)
            blurMat:Recompute()
            surface.DrawTexturedRectUV(0, 0, sw, sh, 0, 0, 1, 1)
            render.UpdateScreenEffectTexture()
        end
    cam.End2D()
    render.PopRenderTarget()
end
---comment
---@param intensity number
---@param x number
---@param y number
---@param width number
---@param height number
---@param round_radius RoundRadiusOptions|number|nil
function ADYLIB.UI:DrawBlur(intensity, x, y, width, height, round_radius)
    if intensity <= 0 then return end
    RenderBlurToRT(intensity)

    local sw, sh = ScrW(), ScrH()
    local radii, zeroRadii = GetRadii(round_radius)

    surface.SetDrawColor(color_white)
    surface.SetMaterial(blurRTMat)

    if zeroRadii then
        surface.DrawTexturedRectUV(0, 0, width, height, x / sw, y / sh, (x + width) / sw, (y + height) / sh)
    else
        local verts = BuildPoly(0, 0, width, height, radii, function(vx, vy)
            return (x + vx) / sw, (y + vy) / sh
        end)
        surface.DrawPoly(verts)
    end
end

-- UI Scale
local UI_SCALE = {
    x = nil,
    y = nil
}
--- **[Client]** Scales a given pixel value proportionally based on the player's screen width.
--- 
--- In case you need to preserve aspect ratio, use `ADYLIB:ScaleUI(pixels)` instead.
---@param pixels any
---@return number
function ADYLIB.UI:ScaleX(pixels)
    return UI_SCALE.x * pixels
end
--- **[Client]** Scales a given pixel value proportionally based on the player's screen height.
--- 
--- In case you need to preserve aspect ratio, use `ADYLIB:ScaleUI(pixels)` instead.
--- @param pixels number
--- @return number
function ADYLIB.UI:ScaleY(pixels)
    return UI_SCALE.y * pixels
end
--- **[Client]** Scales a given pixel value proportionally based on the player's screen resolution, preserving aspect ratio.
---
--- Use this method to adapt UI elements designed for 1920x1080 to other screen sizes.
---@param pixels number
---@return number
function ADYLIB.UI:Scale(pixels)
    local scale = math.min(UI_SCALE.x, UI_SCALE.y)
    if not scale then return 0 end -- Meaningless thing to be honest...
    if pixels ~= nil and type(pixels) == "number" then
        return scale * pixels
    else
        return scale
    end
end
--- **[Client]** Recalculates screen scaling coefficients based on the current resolution.
--- 
--- **Note: Normally called automatically - avoid manual calls unless necessary.**
function ADYLIB.UI:CalcScales()
    UI_SCALE.x = ScrW()/1920
    UI_SCALE.y = ScrH()/1080
end


-- Lerp
--- **[Client]** A frame-rate aware lerp that eliminates the visual "tail" artifact
--- common in standard `Lerp` usage, where the value asymptotically approaches the target
--- but never cleanly snaps to it.
---
--- No `FrameTime()` or `RealFrameTime()` needed — it is handled internally.
---
---@param delta number Speed of interpolation. Higher values move faster. Must be greater than 0.
---@param from number Current value to interpolate from.
---@param to number Target value to interpolate towards.
---@param start? number The original starting value of the animation. When provided, the speed is dynamically scaled based on the total travel distance, so short and long transitions feel consistent. Omit if the delta is already tuned manually.
---@return number
function ADYLIB.UI:Lerp(delta, from, to, start)
    local k = 20
    if start then
        k = math.ceil(math.abs(start - to) / (delta * 1.7))
    end
    local abs = math.abs(from - to)
    local boost = 1 + k/abs
    return Lerp(FrameTime() * delta * boost, from, to)
end


ADYLIB.UI:CalcScales()
hook.Add("OnScreenSizeChanged", "AdyLib/ScreenResize", function()
    ADYLIB.UI:CalcScales()
end)