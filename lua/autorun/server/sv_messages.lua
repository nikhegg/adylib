ADYLIB = ADYLIB or {}

util.AddNetworkString("ADY:Message")

local Meta = {}
Meta.__index = Meta

local function InsertPart(tbl, text, color)
	if not text then return end
	local part = {}
	part.text = text
	part.color = color or tbl.default_color or color_white
	table.insert(tbl.msgs, part)
end

function Meta:Add(element, color)
	if type(element) == "table" then
		for k, part in ipairs(element) do
			InsertPart(self, part.text, part.color)		
		end
	else
		InsertPart(self, element, color)
	end
	return self
end

function Meta:SetDefaultColor(color)
	self.default_color = color
	return self
end

function Meta:GetDefaultColor()
	return self.default_color
end

function Meta:Send(players)
	net.Start("ADY:Message")
	for k, msg in pairs(self.msgs) do
		net.WriteUInt(1,8)
		net.WriteString(msg.text)
		if !msg.color then
			msg.color = self.default_color or color_white
		end
		net.WriteColor(Color(msg.color.r, msg.color.g, msg.color.b), false)
	end
	net.WriteUInt(0,8)
	if players == nil then
		net.Broadcast()
	else
		net.Send(players)
	end
	return self
end

function ADYLIB:Message(msgs)
	local t = {}
	t.msgs = msgs or {}
	setmetatable(t, Meta)
	return t
end