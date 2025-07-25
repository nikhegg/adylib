local PANEL = {}

function PANEL:Init()
    self.RowSize = 3
    self.RowHeight = 100

    self.MarginX = 10
    self.MarginY = 10
end

function PANEL:PerformLayout(w,h)
    local marginXWidth = self.MarginX * (self.RowSize + 1)
    local width = math.floor((w - marginXWidth)/self.RowSize)
    local height = self.RowHeight
    local lastY = 0
    for i, child in ipairs(self:GetChildren()) do
        local row = math.floor((i-1)/self.RowSize)
        -- local x = self.MarginX * i + width * (i-1)
        local x = self.MarginX * (i - row * self.RowSize) + width * (i - row * self.RowSize - 1)
        local y = row * self.RowHeight + self.MarginY * (row+1)
        child:SetSize(width, height)
        child:SetPos(x,y)
        lastY = y
    end
    self:SetTall(lastY + height + self.MarginY*2)
end

function PANEL:Think()
    self:InvalidateLayout(true)
end

function PANEL:GetColumns()
    return self.RowSize
end
function PANEL:SetColumns(amount)
    self.RowSize = amount
end
function PANEL:GetRowTall()
    return self.RowHeight
end
function PANEL:SetRowTall(height)
    self.RowHeight = height
end
function PANEL:GetMargin()
    return self.MarginX, self.MarginY
end
function PANEL:SetMargin(margin)
    self:SetMarginX(margin)
    self:SetMarginY(margin)
end
function PANEL:GetMarginX()
    return self.MarginX
end
function PANEL:SetMarginX(margin)
    self.MarginX = margin
end
function PANEL:GetMarginY()
    return self.MarginY
end
function PANEL:SetMarginY(margin)
    self.MarginY = margin
end

vgui.Register("AdyGrid", PANEL, "Panel")