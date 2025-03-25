local Window

function AdyLibTest()
    if IsValid(Window) then return end
    Window = vgui.Create("AdyFrame")
    Window:SetTitle("AdyLibTest")
    Window:SetSize(1280,720)
    Window:MakePopup()
    Window:Center()
    Window:SetCornerRound(15)
    Window:SetBackgroundColor(0,0,0,200)

    local pp = vgui.Create("AdyPagePanel", Window)
    pp:SetSize(Window:GetWide()/2, Window:GetTall()/2)
    pp:Center()
    pp:SetCycled(true)

    local page = vgui.Create("DPanel")
    page:SetSize(128,128)
    function page:Paint(w, h)
        --draw.RoundedBox(15, 0, 0, w, h, Color(0, 0, 255))
        draw.RoundedBox(15,0,0,w,h,ADYLIB:RainbowColor())
    end
    pp:AddPage(page)

    local btn = vgui.Create("DButton")
    btn:SetSize(200, 64)
    btn:SetText("Test button")
    pp:AddPage(btn)

    local block = vgui.Create("DPanel")
    block:SetSize(256,128)
    function block:Paint(w, h)
        draw.RoundedBox(0,0,0,w,h,Color(0,0,0))
    end
    pp:AddPage(block)


    local prev = vgui.Create("DButton", Window)
    prev:Dock(TOP)
    prev:SetText("<")
    function prev:DoClick()
        pp:PreviousPage()
    end
    local next = vgui.Create("DButton", Window)
    next:Dock(TOP)
    next:SetText(">")
    function next:DoClick()
        pp:NextPage()
    end

    local label = vgui.Create("DLabel", Window)
    label:SetText("1/" .. #pp:GetPages())
    --label:SetFont("CloseCaption_Bold")
    label:Center()
    label:AlignBottom(15)

    pp:OnPageChange(function(cur, total)
        label:SetText(cur .. "/" .. total)
    end)
end


net.Receive("AdyLibTest", AdyLibTest)