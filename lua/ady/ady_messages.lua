ADYLIB = ADYLIB or {}

---@class MessageBuilder
---@field AlphaEnabled boolean Determines whether alpha channel should be used in message. By default this field is set to `false`.
---@field DefaultColor Color Fallback value for color usage. By default this field is set to `Color(255,255,255)`.
---@field Parts (string|Color)[]
local MessageBuilder = {}
MessageBuilder.__index = MessageBuilder
MessageBuilder.AlphaEnabled = false
MessageBuilder.DefaultColor = Color(255,255,255)
MessageBuilder.Parts = {}

--- **[Server/Client]** Adds a new text part to the message.
--- 
--- In case `element` is table then you should pass `MessageTable[]` as argument.
--- 
--- When `color` is not specified then `:Add` will use fallback value that can be set by `:SetDefaultColor`.
---@param text string
---@param color? Color
---@return self|nil
function MessageBuilder:Add(text, color)
    if not text or type(text) ~= "string" then return end
    table.insert(self.Parts, color or self:GetDefaultColor() or color_white)
    table.insert(self.Parts, text)
    return self
end

--- **[Server/Client]** Changes fallback color that will be used in case when Color object is not passed to `:Add` method.
---@param color Color
---@return MessageBuilder
function MessageBuilder:SetDefaultColor(color)
    self.DefaultColor = color
    return self
end

-- **[Server/Client]** Returns default color that will be used for next added texts in case you haven't specified its' color.
---@return Color
function MessageBuilder:GetDefaultColor()
    return self.DefaultColor
end

if SERVER then
    --- **[Server]** Send built message to player or players.
    --- 
    --- **DO NOT** pass any argument if you want the message to be sent to any user.
    --- Otherwise you can pass `Player` (or table of `Player` objects) who will receive the message.
    ---@param players Player[]|Player|nil
    function MessageBuilder:Send(players)
        net.Start("ADY:Message")
        for _, part in ipairs(self.Parts) do
            if type(part) == "string" then
                net.WriteString(part)
            else
                net.WriteColor(part, true)
            end
        end
        
        if players == nil then
            net.Broadcast()
        else
            net.Send(players)
        end
    end
end

if CLIENT then
    --- **[Client]** Shows built message in `LocalPlayer()`'s chat
    function MessageBuilder:Show()
        -- Yeah yeah it's THAT simple
        chat.AddText(unpack(self.Parts))
    end

    net.Receive("ADY:Message", function (len)
        local parts = {}
        local active = true
        while active do
            local color = net.ReadColor(true)
            if not color.a or color.a == 0 then
                active = false
            else
                local text = net.ReadString()
                table.insert(parts, color)
                table.insert(parts, text)
            end
        end

        chat.AddText(unpack(parts))
    end)
end

--- **[Server/Client]** Creates new Message instance to print any text in user's chat with color support.
--- 
--- Argument should be a table with strict construction:
--- `{[1] = {text="Any string", color=Color(a,b,c,d)}, [2] = {...}, ...}`
---@name ADYLIB:Msg
---@param msgs (string|Color)[]
---@return MessageBuilder MessageBuilder instance of Message to generate
function ADYLIB:Msg(msgs)
    local object = {}
    object.msgs = msgs or {}
    setmetatable(object, MessageBuilder)
    return object
end