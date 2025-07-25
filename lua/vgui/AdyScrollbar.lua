local PANEL = {}

function PANEL:Init()
    self:SetWide(8)
    self:SetTall(8)

    self.Dragging = false
    self.VerticalScrollbar = true
    
    self.Margin = 0

    self.ThumbStart = 0
    self.ThumbEnd = 0

    self:SetMouseInputEnabled(true)
end

function PANEL:Think()
    local scrollable = self:GetParent()
    if not IsValid(scrollable) then return end

    -- Automatically deals with pos & size
    local scrollbarMargin = self.Margin
    if self.VerticalScrollbar then
        self:SetPos(scrollable:GetWide() - self:GetWide(), self.Margin)
        if IsValid(scrollable.HorizontalScrollbar) and scrollable.HorizontalScrollbar:IsVisible() then
            scrollbarMargin = scrollbarMargin + scrollable.HorizontalScrollbar:GetTall()
        end
        self:SetTall(scrollable:GetTall() - scrollbarMargin - self.Margin)
    else
        self:SetPos(self.Margin, scrollable:GetTall() - self:GetTall())
        if IsValid(scrollable.VerticalScrollbar) and scrollable.VerticalScrollbar:IsVisible() then
            scrollbarMargin = scrollable.VerticalScrollbar:GetWide()
        end
        self:SetWide(scrollable:GetWide() - scrollbarMargin - self.Margin)
    end
    --

    local canvasMaxSize, selfMaxSize
    if self.VerticalScrollbar then
        canvasMaxSize = scrollable.Canvas:GetTall()
        selfMaxSize = self:GetTall()
    else
        canvasMaxSize = scrollable.Canvas:GetWide()
        selfMaxSize = self:GetWide()
    end

    -- Thumb is dragged
    if self.Dragging then
        local cursorX, cursorY = self:CursorPos()
        local cursorT, scrollableCenter
        if self.VerticalScrollbar then
            cursorT = cursorY
            selfMaxSize = self:GetTall()
            scrollableCenter = scrollable:GetTall()/2
        else
            cursorT = cursorX
            selfMaxSize = self:GetWide()
            scrollableCenter = scrollable:GetWide()/2
        end
        cursorT = math.Clamp(cursorT, 0, selfMaxSize - (self.ThumbEnd - self.ThumbStart)/2)
        local k = cursorT / selfMaxSize
        local offset = math.Clamp(canvasMaxSize * k - scrollableCenter, 0, canvasMaxSize)
        if self.VerticalScrollbar then
            scrollable.TargetOffset.y = offset
            -- scrollable.Canvas:SetY(-offset)
        else
            scrollable.TargetOffset.x = offset
            -- scrollable.Canvas:SetX(-offset)
        end
    end
    --

    -- Recalc thumb position
    local currentStart, currentEnd
    if self.VerticalScrollbar then
        currentStart = -scrollable.Canvas:GetY()
        currentEnd = currentStart + scrollable:GetTall()
    else
        currentStart = -scrollable.Canvas:GetX()
        currentEnd = currentStart + scrollable:GetWide()
    end
    self.ThumbStart = math.Clamp(selfMaxSize * currentStart/canvasMaxSize, 0, selfMaxSize)
    self.ThumbEnd = math.Clamp(selfMaxSize * currentEnd/canvasMaxSize, 0, selfMaxSize)
    --
end

function PANEL:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end
    local scrollable = self:GetParent()
    if not IsValid(scrollable) then return end
    self:MouseCapture(true)
    self.Dragging = true
    self.RememberedSpeed = scrollable:GetScrollSpeed()
    scrollable:SetScrollSpeed(27)
    -- self.RememberedSpeed = scrollable:GetScrollSpeed()
    -- scrollable.ScrollSpeed = scrollable:SetScrollSpeed(27)
end

function PANEL:OnMouseReleased(code)
    if code ~= MOUSE_LEFT then return end
    self.Dragging = false
    self:MouseCapture(false)
    local scrollable = self:GetParent()
    if not IsValid(scrollable) then return end
    scrollable:SetScrollSpeed(self.RememberedSpeed)
    self.RememberedSpeed = nil
end

function PANEL:Paint(w,h)
    self:DrawBackground(w,h)
    if self.VerticalScrollbar then
        self:DrawThumb(0, self.ThumbStart, w, self.ThumbEnd - self.ThumbStart)
    else
        self:DrawThumb(self.ThumbStart, 0, self.ThumbEnd - self.ThumbStart, h)
    end
end

function PANEL:DrawThumb(x,y,tw,th)
    local drawColor = Color(52,52,52)
    if self:IsHovered() then drawColor = Color(72,72,72) end
    draw.RoundedBox(5,x,y,tw,th,drawColor)
    -- if self:IsVertical() then
    --     draw.RoundedBox(0,0,(self.ThumbEnd + self.ThumbStart)/2, tw, 2, Color(0,0,255))
    -- else
    --     draw.RoundedBox(0,(self.ThumbStart + self.ThumbEnd)/2, 0, 2, th, Color(0,0,255))
    -- end
end
function PANEL:DrawBackground(w,h)
    surface.SetDrawColor(Color(16,16,16,220))
    surface.DrawRect(0,0,w,h)
end
function PANEL:IsVertical()
    return self.VerticalScrollbar
end
function PANEL:SetVertical(bool)
    self.VerticalScrollbar = bool
end
function PANEL:SetHorizontal(bool)
    self:SetVertical(not bool)
end
function PANEL:IsHorizontal()
    return not self.VerticalScrollbar
end

vgui.Register("AdyScrollbar", PANEL, "Panel")