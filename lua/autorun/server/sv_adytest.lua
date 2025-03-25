util.AddNetworkString("AdyLibTest")

hook.Add("PlayerSay", "AdyLibTestCommand", function(ply, text)
    print(text)
    if text ~= "!adytest" then return end
    net.Start("AdyLibTest")
    net.Send(ply)
    return ""
end)