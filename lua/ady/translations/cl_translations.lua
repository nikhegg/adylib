net.Receive("AdyLib/Translations", function()
    local sources = net.ReadTable()
    ADYLIB.Translator.__sources = sources
    ADYLIB.Translator:Update()
end)