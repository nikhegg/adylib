local PANEL = {}

function PANEL:Init()
    self:DockMargin(0,0,0,0)
    self:DockPadding(0,0,0,0)
    self.BaseClass.SetTitle(self, "")
    self.BaseClass.ShowCloseButton(self, false)

    -- Params
    self.BackgroundColor = Color(32,32,32,254)
    self.BackgroundMaterialColor = nil
    self.BackgroundMaterial = nil
    self.RoundRadius = ADYLIB:ScaleUI(15)
    self.IsRounded = {}
    self:SetAnglesRounded(true, true, true, true)
    -- self.IsRounded.TopLeft = true
    -- self.IsRounded.TopRight = true
    -- self.IsRounded.BottomLeft = true
    -- self.IsRounded.BottomRight = true

    self.BlurDepth = 0
    --

    self.Titlebar = vgui.Create("AdyDraggable", self)
    self.Titlebar:Dock(TOP)
    self.Titlebar:SetTall(ADYLIB:ScaleUI(48))
    self.Titlebar:SetMoveTarget(self)
    function self.Titlebar:Paint(w,h)
        local pnl = self:GetParent()
        local round = pnl.RoundRadius
        if not round or round < 0 then round = 0 end
        draw.RoundedBox(round, 0, 0, w, h, Color(26,26,26))
    end
    self.Titlebar.IconScale = 0.45
    self.Titlebar.Icon = nil
    self.Titlebar.IconColor = nil
    self.Titlebar.TitleMargin = ADYLIB:ScaleUI(5)
    self.Titlebar.Text = "Window"
    self.Titlebar.Font = ADYLIB:CreateFont({
        font = "Montserrat",
        extended = true,
        size = 26,
        weight = 500,
        antialias = true
    })

    self.Titlebar.Marginer = vgui.Create("DPanel", self.Titlebar)
    self.Titlebar.Marginer:Dock(LEFT)
    self.Titlebar.Marginer:SetMouseInputEnabled(false)
    function self.Titlebar.Marginer:Paint() end


    self.Titlebar.CloseButton = vgui.Create("DButton", self.Titlebar)
    self.Titlebar.CloseButton:Dock(RIGHT)
    self.Titlebar.CloseButton:SetText("")
    function self.Titlebar.CloseButton:DoClick()
        local titlebar = self:GetParent()
        if not IsValid(titlebar) then return end
        local pnl = titlebar:GetParent()
        if not IsValid(pnl) then return end
        pnl:Close()
    end
    local crossMaterial = Material("ady/cross.png")
    function self.Titlebar.CloseButton:Paint(w,h)
        local titlebar = self:GetParent()
        local size = w * titlebar.IconScale
        local pos = w/2 - size/2
        surface.SetDrawColor(color_white)
        surface.SetMaterial(crossMaterial)
        surface.DrawTexturedRect(pos, pos, size, size)
    end
    
    self.Titlebar.Title = vgui.Create("DPanel", self.Titlebar)
    self.Titlebar.Title:SetTall(self.Titlebar:GetTall())
    self.Titlebar.Title:SetMouseInputEnabled(false)
    function self.Titlebar.Title:Paint(w,h)
        local titlebar = self:GetParent()
        if not IsValid(titlebar) then return end
        local pnl = titlebar:GetParent()
        if not IsValid(pnl) then return end

        local iconSize = 0
        if titlebar.Icon then
            surface.SetFont(titlebar.Font)
            local _, th = surface.GetTextSize(titlebar.Text)
            iconSize = th
            surface.SetMaterial(titlebar.Icon)
            surface.SetDrawColor(titlebar.IconColor or color_white)
            surface.DrawTexturedRect(0, h/2 - iconSize/2, iconSize, iconSize)
            iconSize = iconSize + titlebar.TitleMargin
        end
        draw.SimpleText(titlebar.Text, titlebar.Font, iconSize, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end


function PANEL:GetTitle()
    return self.Titlebar.Text
end

function PANEL:SetTitle(title)
    self.Titlebar.Text = title
end

function PANEL:GetDraggable()
    return self.Titlebar:IsBlocked()
end

function PANEL:SetDraggable(draggable)
    if draggable then self.Titlebar:Unblock()
    else self.Titlebar:Block() end
end

function PANEL:PerformLayout(w,h)
    self.Titlebar:SetWide(w)
    local titlebarTall = self.Titlebar:GetTall()
    self.Titlebar.CloseButton:SetSize(titlebarTall, titlebarTall)

    self.Titlebar.Marginer:SetSize(self.RoundRadius/2, titlebar)

    surface.SetFont(self.Titlebar.Font)
    local titleW, titleH = surface.GetTextSize(self.Titlebar.Text)
    if self.Titlebar.Icon then
        titleW = titleW + titleH + self.Titlebar.TitleMargin
    end
    self.Titlebar.Title:SetSize(titleW, titlebarTall)
    if self.Titlebar.Title:GetDock() == NODOCK then
        self.Titlebar.Title:Center()
    else
        self.Titlebar.Title:DockMargin(self.Titlebar.TitleMargin, 0, self.Titlebar.TitleMargin, 0)
    end
end

function PANEL:Paint(w,h)
    if self.BlurDepth and self.BlurDepth ~= 0 then
        ADYLIB:DrawBlurTexture(self, self.BlurDepth)
    end

    masks.Start()

    surface.SetDrawColor(self.BackgroundColor or color_black)
    surface.DrawRect(0,0,w,h)
    if self.BackgroundMaterial then
        surface.SetDrawColor(self.BackgroundMaterialColor or color_white)
        surface.SetMaterial(self.BackgroundMaterial)
        surface.DrawTexturedRect(0,0,w,h)
    end

    masks.Source()

    draw.RoundedBoxEx(
        self.RoundRadius,0,0,w,h,color_white,
        self.IsRounded.TopLeft, self.IsRounded.TopRight,
        self.IsRounded.BottomLeft, self.IsRounded.BottomRight
    )

    masks.End()
end




-- API??
function PANEL:GetBackgroundColor()
    return self.BackgroundColor
end
function PANEL:SetBackgroundColor(r,g,b,a)
    self.BackgroundColor = ADYLIB:ToGModColor(r,g,b,a)
end
function PANEL:GetBackgroundTexture()
    return self.BackgroundMaterial
end
function PANEL:SetBackgroundTexture(material,r,g,b,a)
    if type(material) == "string" then
        material = Material(material)
    end
    self.BackgroundMaterial = material
    self.BackgroundMaterialColor = ADYLIB:ToGModColor(r,g,b,a)
end
function PANEL:GetRoundRadius()
    return self.RoundRadius
end
function PANEL:SetRoundRadius(radius)
    self.RoundRadius = radius
end
function PANEL:GetAnglesRounded()
    return self.IsRounded.TopLeft, self.IsRounded.TopRight, self.IsRounded.BottomLeft, self.IsRounded.BottomRight
end
function PANEL:SetAnglesRounded(topLeft, topRight, bottomLeft, bottomRight)
    self.IsRounded.TopLeft = topLeft
    self.IsRounded.TopRight = topRight
    self.IsRounded.BottomLeft = bottomLeft
    self.IsRounded.BottomRight = bottomRight
end
function PANEL:GetBlurDepth()
    return self.BlurDepth
end
function PANEL:SetBlurDepth(depth)
    self.BlurDepth = depth
end

function PANEL:IsTitlebarVisible()
    return self.Titlebar:IsVisible()
end
function PANEL:SetTitlebarVisible(visible)
    self.Titlebar:SetVisible(visible)
end
function PANEL:GetTitlebarTall()
    return self.Titlebar:GetTall()
end
function PANEL:SetTitlebarTall(height)
    self.Titlebar:SetTall(height)
end
function PANEL:GetTitlebarIcon()
    return self.Titlebar.Icon, self.Titlebar.IconColor
end
function PANEL:SetTitlebarIcon(material,r,g,b,a)
    if type(material) == "string" then material = Material(material) end
    self.Titlebar.Icon = material
    self.Titlebar.IconColor = ADYLIB:ToGModColor(r,g,b,a)
end
--- Accepts value from 0 to 1
function PANEL:SetTitlebarIconScale(multiplier)
    self.Titlebar.IconScale = math.Clamp(multiplier, 0, 1)
end
function PANEL:GetTitlebarIconScale()
    return self.Titlebar.IconScale
end
function PANEL:GetTitleDock()
    return self.Titlebar.Title:GetDock()
end
function PANEL:TitleDock(dock)
    self.Titlebar.Title:Dock(dock)
end
function PANEL:GetTitleDockMargin()
    return self.Titlebar.TitleMargin
end
function PANEL:TitleDockMargin(margin)
    self.Titlebar.TitleMargin = margin
end

function PANEL:IsIgnoringBounds()
    return self.Titlebar:IsIgnoringBounds()
end
function PANEL:IgnoreBounds(ignore)
    self.Titlebar:IgnoreBounds(ignore)
end

vgui.Register("AdyFrame", PANEL, "DFrame")