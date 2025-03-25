local PANEL = {}

function PANEL:Init()
    self.Base = vgui.Create("AvatarImage", self)
    self.Base:Dock(FILL)
    self.Base:SetPaintedManually(true)
end

function PANEL:GetBase()
    return self.Base
end

function PANEL:SetMask(mask)
    render.ClearStencil()
    render.SetStencilEnable(true)
  
    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)
  
    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilPassOperation(STENCILOPERATION_ZERO)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(1)
  
    mask()
  
    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilReferenceValue(1)
end

function PANEL:RemoveMask()
    render.SetStencilEnable(false)
    render.ClearStencil()
end

function PANEL:Paint(w, h)
    self:SetMask(function()
      local poly = {}
  
      local x, y = w / 2, h / 2
      for angle = 1, 360 do
        local rad = math.rad(angle)
  
        local cos = math.cos(rad) * y
        local sin = math.sin(rad) * y
  
        poly[#poly + 1] = {
          x = x + cos,
          y = y + sin
        }
      end
  
      draw.NoTexture()
      surface.SetDrawColor(255, 255, 255)
      surface.DrawPoly(poly)
    end)
    self.Base:PaintManual()
    self:RemoveMask()
end

function PANEL:SetPlayer(ply, size)
    self.Base:SetPlayer(ply, size)
end

function PANEL:SetTooltip(tooltip)
	self.Base:SetTooltip(tooltip)
end

vgui.Register("AdyAvatar", PANEL, "DPanel")