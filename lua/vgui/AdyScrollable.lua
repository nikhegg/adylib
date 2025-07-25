local PANEL_CLASS = "AdyScrollable"
local PANEL = {}

function PANEL:Init()

    self.Canvas = vgui.Create("DPanel", self)
    self.Canvas:SetPaintBackground(false)
    function self.Canvas:OnMouseWheeled(delta)
        local parent = self:GetParent()
        if not IsValid(parent) or not parent.OnMouseWheeled then return end
        parent:OnMouseWheeled(delta)
    end

    -- Scrolling
    self.IsXScrollAllowed = true
    self.IsYScrollAllowed = true

    self.TargetOffset = {
        x = 0,
        y = 0
    }

    self.ScrollPower = 100
    self.ScrollSpeed = 5
    self.MaxOverscroll = 120

    self.VerticalScrollbar = vgui.Create("AdyScrollbar")
    self.VerticalScrollbar:SetWide(8)
    self.VerticalScrollbar:SetParent(self)
    self.HorizontalScrollbar = vgui.Create("AdyScrollbar")
    self.HorizontalScrollbar:SetTall(8)
    self.HorizontalScrollbar:SetParent(self)
    self.HorizontalScrollbar:SetVertical(false)
    -- Scolling

    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(false)
end

function PANEL:IsValid()
    local valid = true
    if valid then valid = IsValid(self.Canvas) end
    return valid
end

function PANEL:OnMouseWheeled(delta)
    if self.VerticalScrollbar and self.VerticalScrollbar.Dragging then return end
    if self.HorizontalScrollbar and self.HorizontalScrollbar.Dragging then return end
    -- if not self:IsHovered() then return end

    if self.IsYScrollAllowed and --[[self.VerticalOverflow]] self.VerticalScrollbar:IsVisible() and not self.HorizontalScrollbar:IsHovered() then
        -- local newY = self.TargetOffset.y - delta * self.ScrollPower
        -- local leftY = self.Canvas:GetTall() - self:GetTall()
        -- self.TargetOffset.y = math.Clamp(newY, 0, math.max(0, leftY))
        self.TargetOffset.y = self.TargetOffset.y - delta * self.ScrollPower
    elseif self.IsXScrollAllowed and --[[self.HorizontalOverflow]] self.HorizontalScrollbar:IsVisible() and not self.VerticalScrollbar:IsHovered() then
        -- local newX = self.TargetOffset.x - delta * self.ScrollPower
        -- local leftX = self.Canvas:GetWide() - self:GetWide()
        -- self.TargetOffset.x = math.Clamp(newX, 0, math.max(0, leftX))
        self.TargetOffset.x = self.TargetOffset.x - delta * self.ScrollPower
    end
end

local function NormalizeTargetOffset(target, min, max, overscroll)
    if target < min then
        target = Lerp(FrameTime() * 8, target, min)
    elseif target > max then
        target = Lerp(FrameTime() * 8, target, max)
    end
    return math.Clamp(target, -overscroll, max + overscroll)
end

function PANEL:PerformLayout(w,h)
    -- self:UpdateScrollbars()
    local offsetX, offsetY = self.Canvas:GetPos()
    -- print(offsetX .. "-" .. self.TargetOffset.x, offsetY .. "-" .. self.TargetOffset.y)

    if self.TargetOffset.y ~= offsetY then
        local dy = math.abs(offsetY + self.TargetOffset.y)
        local boost = 1 + 50 / (dy + 1)
        local speed = self.ScrollSpeed * boost
        offsetY = Lerp(FrameTime() * speed, offsetY, -self.TargetOffset.y)
    end
    if self.TargetOffset.x ~= offsetX then
        local dx = math.abs(offsetX + self.TargetOffset.x)
        local boost = 1 + 50 / (dx + 1)
        local speed = self.ScrollSpeed * boost
        offsetX = Lerp(FrameTime() * speed, offsetX, -self.TargetOffset.x)
    end
    self.Canvas:SetPos(math.Round(offsetX), math.Round(offsetY))
    self:LayoutChildren()

    -- Try no limits mode
    local canvasX, canvasY = self.Canvas:GetSize()
    local selfX, selfY = self:GetSize()
    
    local maxOffsetX = math.max(0, canvasX - selfX)
    local maxOffsetY = math.max(0, canvasY - selfY)
    self.TargetOffset.x = NormalizeTargetOffset(self.TargetOffset.x, 0, maxOffsetX, self.MaxOverscroll)
    self.TargetOffset.y = NormalizeTargetOffset(self.TargetOffset.y, 0, maxOffsetY, self.MaxOverscroll)
end

function PANEL:LayoutChildren()
    local maxX, maxY = 0,0
    for _, child in ipairs(self.Canvas:GetChildren()) do
        if IsValid(child) then
            local x,y = child:GetPos()
            maxX = math.max(maxX, x + child:GetWide())
            maxY = math.max(maxY, y + child:GetTall())
            if child:GetDock() == FILL then
                maxX = self:GetViewportWide()
            end
        end
    end
    self.Canvas:SetSize(maxX, maxY)

    local selfW, selfT = self:GetSize()
    -- self.VerticalOverflow = (selfT < maxY)
    -- self.VerticalScrollbar:SetVisible(self.VerticalOverflow)
    -- self.HorizontalOverflow = (selfW < maxX)
    -- self.HorizontalScrollbar:SetVisible(self.HorizontalOverflow)
    self.VerticalScrollbar:SetVisible(selfT < maxY)
    self.HorizontalScrollbar:SetVisible(selfW < maxX)
end

function PANEL:OnChildAdded(child)
    if child == self.Canvas then return end
    if child == self.VerticalScrollbar then return end
    if child == self.HorizontalScrollbar then return end
    timer.Simple(0, function()
        if not IsValid(child) or not self:IsValid() then return end
        if not child:GetParent() == self then return end

        child:SetParent(self.Canvas)
        self:LayoutChildren()
    end)
end

function PANEL:Think()
    self:InvalidateLayout(true)
end

function PANEL:Paint(w,h) end


-- API
function PANEL:GetScrollSpeed()
    return self.ScrollSpeed - 3
end
function PANEL:SetScrollSpeed(speed)
    if type(speed) ~= "number" or speed <= 0 then speed = 1 end
    self.ScrollSpeed = 3 + speed
end

function PANEL:GetScrollPower()
    return self.ScrollPower
end
function PANEL:SetScrollPower(power)
    if type(power) ~= "number" or power < 10 then power = 10 end
    self.ScrollPower = power
end

function PANEL:IsHorizontalScrollEnabled()
    return self.IsXScrollAllowed
end
function PANEL:EnableHorizontalScoll()
    self.IsXScrollAllowed = true
end
function PANEL:DisableHorizontalScroll()
    self.IsXScrollAllowed = false
end
function PANEL:IsVerticalScrollEnabled()
    return self.IsYScrollAllowed
end
function PANEL:EnableVerticalScroll()
    self.IsYScrollAllowed = true
end
function PANEL:DisableVerticalScroll()
    self.IsYScrollAllowed = false
end
function PANEL:GetViewportWide()
    local w = self:GetWide()
    if IsValid(self.VerticalScrollbar) and self.VerticalScrollbar:IsVisible() then
        w = w - self.VerticalScrollbar:GetWide()
    end
    return w
end
function PANEL:GetViewportTall()
    local h = self:GetTall()
    if IsValid(self.HorizontalScrollbar) and self.HorizontalScrollbar:IsVisible() then
        h = h - self.HorizontalScrollbar:GetTall()
    end
    return h
end
function PANEL:GetViewportSize()
    return self:GetViewportWide(), self:GetViewportTall()
end
function PANEL:GetScrollbarsMargin()
    return self.VerticalScrollbar.Margin, self.HorizontalScrollbar.Margin
end
function PANEL:SetScrollbarsMargin(margin)
    self.VerticalScrollbar.Margin = margin
    self.HorizontalScrollbar.Margin = margin
end

vgui.Register(PANEL_CLASS, PANEL, "Panel")