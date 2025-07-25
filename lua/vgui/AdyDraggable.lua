local PANEL = {}

function PANEL:Init()
    self.Blocked = false
    self.MoveTarget = self
    self.Dragged = false
    self.DragOffset = {x = 0, y = 0}
    self.BoundsIgnored = false
end

function PANEL:IsBlocked()
    return self.Blocked
end

function PANEL:Block()
    self.Blocked = true
end

function PANEL:Unblock()
    self.Blocked = false
end

function PANEL:SetMoveTarget(target)
    self.MoveTarget = target
end

function PANEL:GetMoveTarget()
    return self.MoveTarget
end

function PANEL:IgnoreBounds(bool)
    self.BoundsIgnored = bool
end

function PANEL:IsIgnoringBounds()
    return self.BoundsIgnored
end

function PANEL:OnMousePressed(mouseCode)
    if self.Blocked then return end
    if mouseCode ~= MOUSE_LEFT then return end
    self:MouseCapture(true)
    self.Dragged = true
    local mouseX, mouseY = gui.MousePos()
    self.DragOffset.x = mouseX - self.MoveTarget.x
    self.DragOffset.y = mouseY - self.MoveTarget.y
    self:SetCursor("sizeall")
end

function PANEL:OnMouseReleased(mouseCode)
    if mouseCode ~= MOUSE_LEFT then return end
    self:MouseCapture(false)
    self.Dragged = false
    self:SetCursor("hand")
end

function PANEL:Think()
    if self.Blocked then
        if self.Dragged then
            self:OnMouseReleased(MOUSE_LEFT)
        end
        return
    end
    if not self.Dragged then return end
    local mouseX, mouseY = gui.MousePos()

    local newX = mouseX - self.DragOffset.x
    local newY = mouseY - self.DragOffset.y

    local parent = self.MoveTarget:GetParent()
    if not self.BoundsIgnored and parent then
        if newX < 0 then
            newX = 0
        elseif newX + self.MoveTarget:GetWide() >= parent:GetWide() then
            newX = parent:GetWide() - self.MoveTarget:GetWide()
        end
        if newY < 0 then
            newY = 0
        elseif newY + self.MoveTarget:GetTall() >= parent:GetTall() then
            newY = parent:GetTall() - self.MoveTarget:GetTall()
        end
    end

    self.MoveTarget:SetPos(newX, newY)
end

vgui.Register("AdyDraggable", PANEL, "DPanel")