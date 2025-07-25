util.AddNetworkString("ADY/tableflow/Start")
util.AddNetworkString("ADY/tableflow/Chunk")
util.AddNetworkString("ADY/tableflow/End")
util.AddNetworkString("ADY/tableflow/Single")

local MAX_CHUNK_SIZE = 60000

tableflow = tableflow or {}
tableflow.__index = tableflow

local flowID, flowData

function tableflow:Start(name)
    local nameType = type(name)
    assert(nameType == "string", "tableflow name should be a string, got " .. nameType)
    flowID = name
    flowData = nil
    return self
end


function tableflow:WriteTable(tbl)
    assert(flowID, "tableflow should be prepared first. Use ADYLIB.tableflow:Start(...) before sending")
    assert(type(tbl) == "table", "tableflow:WriteTable argument should be a table")

    local json = util.TableToJSON(tbl)
    flowData = util.Compress(json)
    return self
end

local function tableflowNetSend(ply)
    if not ply then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

local function handleSinglePart(ply)
    local dataSize = #flowData

    net.Start("ADY/tableflow/Single")
    net.WriteString(flowID)
    net.WriteUInt(dataSize, 16)
    net.WriteData(flowData, dataSize)
    tableflowNetSend(ply)
    flowData = nil
end

local function tableflowSend(ply)
    assert(flowID and flowData, "tableflow should be prepared first. Use ADYLIB.tableflow:Start(...) before sending")
    
    local parts = math.ceil(#flowData / MAX_CHUNK_SIZE)

    if parts == 1 then
        handleSinglePart(ply)
        return
    end

    net.Start("ADY/tableflow/Start")
    net.WriteString(flowID)
    net.WriteUInt(parts, 8)
    tableflowNetSend(ply)

    for i=1,parts do
        local chunk = flowData:sub((i - 1) * MAX_CHUNK_SIZE + 1, i * MAX_CHUNK_SIZE)
        local chunkSize = #chunk
        net.Start("ADY/tableflow/Chunk")
        net.WriteString(flowID)
        net.WriteUInt(i, 8)
        net.WriteUInt(chunkSize, 16)
        net.WriteData(chunk, chunkSize)
        tableflowNetSend(ply)
    end

    net.Start("ADY/tableflow/End")
    net.WriteString(flowID)
    tableflowNetSend(ply)
    flowData = nil
end

function tableflow:Send(ply)
    tableflowSend(ply)
end

function tableflow:Broadcast()
    tableflowSend()
end

ADYLIB.tableflow = tableflow