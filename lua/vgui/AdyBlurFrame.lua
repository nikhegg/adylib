local PANEL = {}

function PANEL:Init()
    self.lblTitle:SetVisible(false)
    self:ShowCloseButton(false)
    self:DockPadding(0,0,0,0)
    
    self.BackgroundColor = Color(0,0,0,50)
    self.BlurDepth = 0
    self.CornerRound = 0
    self:SetupHeader("WIndow")
end

function PANEL:SetupHeader(text)
    if IsValid(self.Header) then
        self.Header:Remove()
    end
    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetSize(self:GetWide(), ADYLIB:ScaleUI(48))
    function self.Header:Paint(w, h)
        draw.RoundedBox(self:GetParent().CornerRound, 0, 0, w, h, Color(26,26,26))
    end
    self.Header:SetCursor("hand")
    self.Header.Dragging = false
    self.Header.DragOffset = {x = 0, y = 0}
    function self.Header:OnMousePressed(mouseCode)
        if mouseCode == MOUSE_LEFT then
            self.Dragging = true
            local mouseX, mouseY = gui.MousePos()
            self.DragOffset.x = mouseX - self:GetParent().x
            self.DragOffset.y = mouseY - self:GetParent().y
            self:MouseCapture(true)
            self:SetCursor("sizeall")
        end
    end
    function self.Header:OnMouseReleased(mouseCode)
        if mouseCode == MOUSE_LEFT then
            self.Dragging = false
            self:MouseCapture(false)
            self:SetCursor("hand")
        end
    end
    function self.Header:Think()
        if self.Dragging then
            local mouseX, mouseY = gui.MousePos()
            self:GetParent():SetPos(mouseX - self.DragOffset.x, mouseY - self.DragOffset.y)
        end
    end

    local closeButtonContainer = vgui.Create("DPanel", self.Header)
    closeButtonContainer:Dock(RIGHT)
    --function closeButtonContainer:Paint() end

    self.Header.CloseButton = vgui.Create("DButton", closeButtonContainer)
    function self.Header.CloseButton:DoClick()
        self:GetParent():GetParent():GetParent():Close()
    end
    self.Header.CloseButton:SetText("")
    self.Header:InvalidateLayout(true)
    local scaledButtonSize = ADYLIB:ScaleUI(20)
    self.Header.CloseButton:SetSize(scaledButtonSize, scaledButtonSize)
    self.Header.CloseButton:SetY(self.Header:GetTall()/2 - self.Header.CloseButton:GetTall()/2)
    self.Header.CloseButton:AlignRight(ADYLIB:ScaleUI(15))
    --self.Header.CloseButton:SetX(self.Header:GetWide() - self.Header.CloseButton:GetWide())
    function self.Header.CloseButton:Paint(w,h)
        local cross = Material("ady/cross.png")
        surface.SetMaterial(cross)
        if not self:IsEnabled() then
            surface.SetDrawColor(Color(70,70,70)) 
        elseif self:IsHovered() then
            surface.SetDrawColor(Color(255,70,94))
        else surface.SetDrawColor(color_white) end
        surface.DrawTexturedRect(0,0,w,h)
    end

    self.Header.Icon = vgui.Create("DImage", self.Header)
    self.Header.Icon:SetSize(32,32)
    self.Header.Icon:SetImage("ady/settings.png")
    self.Header.Icon:AlignLeft(ADYLIB:ScaleUI(15))
    self.Header.Icon:SetY(self.Header:GetTall()/2 - self.Header.Icon:GetTall()/2)
    function self.Header.Icon:GetCurrentWide()
        if self:IsVisible() then return self:GetWide()
        else return 0 end
    end

    self.Header.Label = vgui.Create("DLabel", self.Header)
    self.Header.Label:SetText(text)
    self.Header.Label:SetFont("Trebuchet24")
    self.Header.Label:SetColor(color_white)
    self.Header.Label:SizeToContents()
    self.Header.Label:AlignLeft(ADYLIB:ScaleUI(15) + self.Header.Icon:GetCurrentWide())
    self.Header.Label:SetY(self.Header:GetTall()/2 - self.Header.Label:GetTall()/2)
    return self.Header
end

function PANEL:RemoveHeader()
    if not IsValid(self.Header) then return end
    self.Header:Remove()
end

-- RGBA color
function PANEL:SetBackgroundColor(r,g,b,a)
    self.BackgroundColor = ADYLIB:ToGModColor(r,g,b,a)
end

function PANEL:GetBackgroundColor()
    return self.BackgroundColor
end

function PANEL:SetBlurDepth(depth)
    if type(depth) ~= "number" then return end
    if depth < 0 then depth = 0 end
    if depth > 0 and self.CornerRound ~= 0 then
        self:Close()
        error("Frame Blur doesn't work with rounded corners")
    end
    self.BlurDepth = depth
end

function PANEL:GetBlurDepth()
    return self.BlurDepth
end

function PANEL:SetCornerRound(radius)
    if type(radius) ~= "number" then return end
    if radius < 0 then radius = 0 end
    if radius > 0 and self.BlurDepth ~= 0 then
        self:Close()
        error("Frame Blur doesn't work with rounded corners")
    end
    self.CornerRound = radius
end

function PANEL:GetCornerRound()
    return self.CornerRound
end

function PANEL:Paint(w,h)
    masks.Start()
    if self.BlurDepth ~= 0 then
        ADYLIB:DrawBlurTexture(self, self.BlurDepth)
    end
    if self.BackgroundColor.a ~= 0 then
        surface.SetDrawColor(self.BackgroundColor)
        surface.DrawRect(0,0,w,h)
    end
    masks.Source()
    draw.RoundedBox(self.CornerRound, 0, 0, w, h, color_white)
    masks.End()
end

vgui.Register("AdyFrame", PANEL, "DFrame")