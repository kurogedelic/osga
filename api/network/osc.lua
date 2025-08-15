-- api/network/osc.lua
-- OSC (Open Sound Control) protocol implementation for OSGA
-- Based on OSC 1.0 specification

local osc = {}

-- Helper function to align to 4-byte boundary
local function padToFour(str)
    local padding = 4 - (#str % 4)
    if padding == 4 then padding = 0 end
    return str .. string.rep('\0', padding)
end

-- Helper function to read null-terminated string
local function readString(data, pos)
    local endPos = data:find('\0', pos, true)
    if not endPos then return nil, pos end
    local str = data:sub(pos, endPos - 1)
    -- Align to 4-byte boundary
    local alignedEnd = endPos + (4 - (endPos % 4)) % 4
    return str, alignedEnd
end

-- Read 32-bit integer (big-endian)
local function readInt32(data, pos)
    if pos + 3 > #data then return nil, pos end
    local b1, b2, b3, b4 = data:byte(pos, pos + 3)
    local value = b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4
    -- Handle signed integers
    if value >= 0x80000000 then
        value = value - 0x100000000
    end
    return value, pos + 4
end

-- Read 32-bit float (big-endian)
local function readFloat32(data, pos)
    if pos + 3 > #data then return nil, pos end
    local b1, b2, b3, b4 = data:byte(pos, pos + 3)
    
    -- IEEE 754 float reconstruction
    local sign = b1 >= 128 and -1 or 1
    local exponent = (b1 % 128) * 2 + math.floor(b2 / 128)
    local mantissa = ((b2 % 128) * 65536 + b3 * 256 + b4) / 8388608
    
    if exponent == 0 then
        return sign * mantissa * 2^(-126), pos + 4
    elseif exponent == 255 then
        return mantissa == 0 and sign * math.huge or 0/0, pos + 4
    else
        return sign * (1 + mantissa) * 2^(exponent - 127), pos + 4
    end
end

-- Write 32-bit integer (big-endian)
local function writeInt32(value)
    value = math.floor(value)
    if value < 0 then
        value = value + 0x100000000
    end
    return string.char(
        math.floor(value / 0x1000000) % 256,
        math.floor(value / 0x10000) % 256,
        math.floor(value / 0x100) % 256,
        value % 256
    )
end

-- Write 32-bit float (big-endian)
local function writeFloat32(value)
    if value == 0 then
        return "\0\0\0\0"
    end
    
    local sign = value < 0 and 128 or 0
    value = math.abs(value)
    
    -- Calculate exponent and mantissa
    local exponent = math.floor(math.log(value) / math.log(2))
    local mantissa = value / (2 ^ exponent) - 1
    
    exponent = exponent + 127
    mantissa = mantissa * 8388608
    
    return string.char(
        sign + math.floor(exponent / 2),
        (exponent % 2) * 128 + math.floor(mantissa / 65536),
        math.floor(mantissa / 256) % 256,
        math.floor(mantissa) % 256
    )
end

-- Decode OSC message
function osc.decode(data)
    local pos = 1
    local message = {}
    
    -- Read address pattern
    local address, newPos = readString(data, pos)
    if not address or not address:match("^/") then
        return nil, "Invalid OSC address"
    end
    message.address = address
    pos = newPos
    
    -- Read type tag string
    local typeTags, newPos = readString(data, pos)
    if not typeTags or not typeTags:match("^,") then
        return nil, "Invalid type tag string"
    end
    typeTags = typeTags:sub(2) -- Remove leading comma
    pos = newPos
    
    -- Read arguments based on type tags
    message.args = {}
    for i = 1, #typeTags do
        local tag = typeTags:sub(i, i)
        local value
        
        if tag == 'i' then
            -- 32-bit integer
            value, pos = readInt32(data, pos)
        elseif tag == 'f' then
            -- 32-bit float
            value, pos = readFloat32(data, pos)
        elseif tag == 's' then
            -- String
            value, pos = readString(data, pos)
        elseif tag == 'T' then
            -- True
            value = true
        elseif tag == 'F' then
            -- False
            value = false
        elseif tag == 'N' then
            -- Nil
            value = nil
        else
            -- Unsupported type
            return nil, "Unsupported type tag: " .. tag
        end
        
        table.insert(message.args, value)
    end
    
    return message
end

-- Encode OSC message
function osc.encode(address, ...)
    local args = {...}
    local data = ""
    
    -- Add address pattern
    data = data .. padToFour(address .. '\0')
    
    -- Build type tag string and encode arguments
    local typeTags = ","
    local argData = ""
    
    for _, arg in ipairs(args) do
        local argType = type(arg)
        
        if argType == "number" then
            if math.floor(arg) == arg then
                -- Integer
                typeTags = typeTags .. 'i'
                argData = argData .. writeInt32(arg)
            else
                -- Float
                typeTags = typeTags .. 'f'
                argData = argData .. writeFloat32(arg)
            end
        elseif argType == "string" then
            typeTags = typeTags .. 's'
            argData = argData .. padToFour(arg .. '\0')
        elseif argType == "boolean" then
            typeTags = typeTags .. (arg and 'T' or 'F')
        elseif argType == "nil" then
            typeTags = typeTags .. 'N'
        else
            error("Unsupported argument type: " .. argType)
        end
    end
    
    -- Add type tags
    data = data .. padToFour(typeTags .. '\0')
    
    -- Add arguments
    data = data .. argData
    
    return data
end

-- Create OSC bundle (multiple messages with timestamp)
function osc.bundle(timetag, ...)
    local messages = {...}
    local data = "#bundle\0"
    
    -- Add timetag (NTP timestamp or 1 for immediate)
    if timetag == nil or timetag == 1 then
        data = data .. "\0\0\0\0\0\0\0\1"
    else
        -- Convert timestamp to NTP format (not implemented)
        data = data .. "\0\0\0\0\0\0\0\1"
    end
    
    -- Add messages
    for _, msg in ipairs(messages) do
        local msgData = type(msg) == "string" and msg or osc.encode(msg.address, unpack(msg.args))
        data = data .. writeInt32(#msgData) .. msgData
    end
    
    return data
end

return osc