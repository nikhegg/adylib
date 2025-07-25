tableflow = tableflow or {}
tableflow.__index = tableflow

local flowData = {}
local callbacks = {}

function tableflow:Receive(name, callback)
    local nameType = type(name)
    assert(nameType == "string", "tableflow name should be a string, got " .. nameType)
    local callbackType = type(callback)
    assert(callbackType == "function", "tableflow:Receive() callback should be a function, got " .. callbackType)
    callbacks[name] = callback
    return self
end

net.Receive("ADY/tableflow/Start", function()
    local name = net.ReadString()
    local total = net.ReadUInt(8)
    
    flowData[name] = {
        received = 0,
        total = total,
        parts = {}
    }
end)

net.Receive("ADY/tableflow/Chunk", function()
    local name = net.ReadString()
    local chunkID = net.ReadUInt(8)
    local chunkSize = net.ReadUInt(16)
    local data = net.ReadData(chunkSize)
    if not flowData[name] then return end
    flowData[name].parts[chunkID] = data
    flowData[name].received = flowData[name].received + 1
end)

net.Receive("ADY/tableflow/End", function()
    local name = net.ReadString()
    if not flowData[name] then
        error("Received unhandled tableflow name: " .. name)
    end
    if not callbacks[name] then
        flowData[name] = nil
        print("[tableflow] Flow " .. name .. " is not handled. Handle it using ADYLIB.tableflow:Receive(" .. name .. ", ...)")
        return
    end
    if flowData[name].received ~= flowData[name].total then
        local received = flowData[name].received
        local total = flowData[name].total
        flowData[name] = nil
        error("tableflow - incomplete or missing data in " .. name .. ": got " .. received .. " out of " .. total .. " chunks")
    end
    

    local compressedData = table.concat(flowData[name].parts)
    local data = util.Decompress(compressedData)
    if not data then
        error("Failed to decompress the tableflow data for " .. name)
    end

    local tbl = util.JSONToTable(data, true)
    callbacks[name](tbl, flowData[name].total)

    flowData[name] = nil
end)

net.Receive("ADY/tableflow/Single", function()
    local name = net.ReadString()
    local chunkSize = net.ReadUInt(16)
    local compressedData = net.ReadData(chunkSize)
    local data = util.Decompress(compressedData)
    if not data then
        error("Failed to decompress the tableflow data for " .. name)
    end
    local tbl = util.JSONToTable(data, true)

    if not callbacks[name] then
       flowData[name] = nil
       print("[tableflow] Flow " .. name .. " is not handled. Handle it using ADYLIB.tableflow:Receive(" .. name .. ", ...)")
       return
    end
    
    callbacks[name](tbl, 1)

    flowData[name] = nil
end)

ADYLIB.tableflow = tableflow