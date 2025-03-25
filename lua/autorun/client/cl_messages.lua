net.Receive("ADY:Message", function (len)
	local parts = {}
	while true do
		local i = net.ReadUInt(8)
		if i == 0 then break end
		local str = net.ReadString()
		local col = net.ReadColor(false)
		table.insert(parts, col)
		table.insert(parts, str)
	end

	chat.AddText(unpack(parts))
end)