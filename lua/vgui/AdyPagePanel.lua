local PANEL = {}

function PANEL:Init()
    self.Current = 1
    self.Pages = {}
    self.Cycled = false
    self.PageChangedEvents = {}
end

-- Automatically adds page as a child and centers it
-- This will also make a page invisible in case there are other pages
function PANEL:CreatePage(elementType)
    local page = vgui.Create(elementType)
    local index = self:AddPage(page)
    return page, index
end

-- Adds existing VGUI element as a child
-- This will also make a page invisible in case there are other pages
function PANEL:AddPage(page)
    page:SetParent(self)
    page:Center()
    if #self.Pages ~= 0 then
        page:SetVisible(false)
    end
    table.insert(self.Pages, page)
    return #self.Pages
end

function PANEL:GetPages()
    return self.Pages
end

function PANEL:RemovePage(index)
    table.remove(self.Pages, index)
end

function PANEL:OnPageChange(func)
    if type(func) ~= "function" then return end
    table.insert(self.PageChangedEvents, func)
end

function PANEL:CallPageChange(prevPage)
    if type(prevPage) ~= "number" and prevPage ~= nil then
        if not pcall(function()
            prevPage = tonumber(prevPage)
        end) then
            prevPage = nil
        end
    end
    for _,func in ipairs(self.PageChangedEvents) do
        func(self.Current, #self.Pages, prevPage)
    end
end

function PANEL:PreviousPage()
    local beforePage = self.Pages[self.Current]
    local beforePageIndex = self.Current
    self.Current = self.Current - 1
    if self.Current <= 0 then
        if self.Cycled then self.Current = #self.Pages
        else
            self.Current = 1
            return
        end
    end
    beforePage:SetVisible(false)
    self.Pages[self.Current]:SetVisible(true)
    self:CallPageChange(beforePageIndex)
end

function PANEL:NextPage()
    local beforePage = self.Pages[self.Current]
    local beforePageIndex = self.Current
    self.Current = self.Current + 1
    if self.Current >= #self.Pages + 1 then
        if self.Cycled then self.Current = 1
        else
            self.Current = #self.Pages
            return
        end
    end
    beforePage:SetVisible(false)
    self.Pages[self.Current]:SetVisible(true)
    self:CallPageChange(beforePageIndex)
end

function PANEL:SetPagePointer(index)
    if index == nil then return end
    if index > #self.Pages or index <= 0 then return end
    if type(index) ~= "number" then
        if not pcall(function()
            index = tonumber(index)
        end) then
            return
        end
    end
    local beforePage = self.Pages[self.Current]
    local beforePageIndex = self.Current
    self.Current = index
    beforePage:SetVisible(false)
    self.Pages[self.Current]:SetVisible(true)
    self:CallPageChange(beforePageIndex)
end

function PANEL:GetPagePointer()
    return self.Current
end

function PANEL:GetCurrentPage()
    return self.Pages[self.Current]
end

function PANEL:SetCycled(cycled)
    self.Cycled = cycled
end

function PANEL:GetCycled()
    return self.Cycled
end

function PANEL:Paint(w,h) 
    draw.RoundedBox(0,0,0,w,h,Color(255,255,255))
end

vgui.Register("AdyPagePanel", PANEL, "DPanel")