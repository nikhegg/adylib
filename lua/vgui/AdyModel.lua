local PANEL = {}

function PANEL:Init()
    self.Entity = nil
	self.LastPaint = 0
	self.DirectionalLight = {}
	self.FarZ = 4096

	self:SetCamPos( Vector( 50, 50, 50 ) )
	self:SetLookAt( Vector( 0, 0, 40 ) )
	self:SetFOV( 70 )

	self:SetText( "" )
	self:SetAnimSpeed( 0.5 )
	self:SetAnimated( false )

	self:SetAmbientLight( Color( 50, 50, 50 ) )

	self:SetDirectionalLight( BOX_TOP, Color( 255, 255, 255 ) )
	self:SetDirectionalLight( BOX_FRONT, Color( 255, 255, 255 ) )

	self:SetColor( color_white )

    -- Custom Things
    self.AllowZoom = true
    self.ZoomDefaults = {
        min = self.Zoom.min,
        current = self.Zoom.current,
        max = self.Zoom.max,
        speed = 5
    }
    self:RestoreZoom()
    self.Zoom.current = 600
    self.MoveY = {
        min = 20,
        max = 85
    }
end

function PANEL.Think(self)
    self.Zoom.current = Lerp(RealFrameTime() * 5)
end

function PANEL:GetZoom()
    return self.Zoom.current
end

function PANEL:SetZoom(zoom)
    if type(zoom) ~= "number" then return end
    self.Zoom.target = zoom
end

-- Zoom without animation
function PANEL:ForceZoom(zoom)
    if type(zoom) ~= "number" then return end
    self.Zoom.current = zoom
    self:SetZoom(zoom)
end

function PANEL:RestoreZoom()
    self.Zoom = {
        min = self.ZoomDefaults.min,
        current = self.ZoomDefaults.current,
        target = self.ZoomDefaults.current,
        max = self.ZoomDefaults.max,
        speed = self.ZoomDefaults.speed
    }
end

function PANEL:SetPlayermodel(ply)
    self:SetModel(ply:GetModel())
    for k,v in ipairs(ply:GetBodyGroups()) do
        self.Entity:SetBodygroup(v.id, ply:GetBodygroup(v.id))
    end
    self.Entity:SetSkin(ply:GetSkin())
    function self.Entity:GetPlayerColor() return ply:GetPlayerColor() end
end

vgui.Register("AdyModel", PANEL, "DModelPanel")