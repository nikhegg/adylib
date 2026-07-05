ADYLIB = ADYLIB or {}
ADYLIB.Utils = ADYLIB.Utils or {}

---**[Server/Client]** Parses SteamID and `Player` instance from a `Player` or `string` variable. Returns SteamID as `string` by default
--- 
--- This methods returns pair of SteamID as `string` and `Player` instance if `returnPly` is set to `true`
---@param ply Player|string
---@param returnPly boolean|nil
---@return string
---@return Player|nil
function ADYLIB.Utils:ParseSteamID(ply, returnPly)
    if returnPly == nil then returnPly = false end

    local steamID, plyToReturn

    if type(ply) == "string" then
        steamID = ply
        if returnPly then
            local plyCopy = player.GetBySteamID(ply)
            if type(plyCopy) ~= "boolean" then
                plyToReturn = plyCopy
            end
        else plyToReturn = nil end
    else
        steamID = ply:SteamID()
    end

    return steamID, plyToReturn
end