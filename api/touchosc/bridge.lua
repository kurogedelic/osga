-- api/touchosc/bridge.lua
-- TouchOSC Bridge for OSGA
-- Maps OSC messages from TouchOSC to OSGA control inputs

local osc = require("api.network.osc")
local udp_server = require("api.network.udp_server")

local bridge = {}
bridge.__index = bridge

function bridge.new(port)
    local self = setmetatable({}, bridge)
    
    -- Initialize server
    self.server = udp_server.new(port or 8000)
    self.handlers = {}
    self.mappings = {}
    self.enabled = false
    self.debug = false
    
    -- Statistics
    self.stats = {
        messages_received = 0,
        messages_processed = 0,
        last_message_time = 0,
        last_ip = nil,
        last_port = nil
    }
    
    return self
end

function bridge:start()
    if not self.server:isAvailable() then
        print("TouchOSC Bridge: LuaSocket not available")
        return false
    end
    
    local success, err = self.server:start()
    if not success then
        print("TouchOSC Bridge failed to start: " .. (err or "unknown error"))
        return false
    end
    
    self.enabled = true
    
    -- Print connection info
    local ip = self.server:getLocalIP()
    print("========================================")
    print("TouchOSC Bridge Started!")
    print("IP Address: " .. ip)
    print("Port: " .. self.server.port)
    print("Configure TouchOSC to send to:")
    print("  Host: " .. ip)
    print("  Port: " .. self.server.port)
    print("========================================")
    
    return true
end

function bridge:stop()
    self.server:stop()
    self.enabled = false
    print("TouchOSC Bridge stopped")
end

-- Register a handler for a specific OSC address
function bridge:on(address, callback)
    self.handlers[address] = callback
    if self.debug then
        print("TouchOSC: Registered handler for " .. address)
    end
end

-- Register multiple handlers at once
function bridge:register(handlers)
    for address, callback in pairs(handlers) do
        self:on(address, callback)
    end
end

-- Map TouchOSC controls to koto inputs
function bridge:mapToKoto(koto)
    -- Default mappings for common controls
    
    -- Buttons
    self:on("/1/push1", function(args)
        if args[1] then
            koto.swA = args[1] > 0
        end
    end)
    
    self:on("/1/push2", function(args)
        if args[1] then
            koto.swB = args[1] > 0
        end
    end)
    
    self:on("/1/push3", function(args)
        if args[1] then
            koto.swC = args[1] > 0
        end
    end)
    
    self:on("/1/push4", function(args)
        if args[1] then
            koto.swR = args[1] > 0
        end
    end)
    
    -- XY Pad for gyro simulation
    self:on("/1/xy1", function(args)
        if args[1] and args[2] then
            koto.gyroX = (args[1] - 0.5) * 4  -- Map 0-1 to -2 to 2
            koto.gyroY = (args[2] - 0.5) * 4
        end
    end)
    
    -- Rotary control
    self:on("/1/rotary1", function(args)
        if args[1] then
            koto.rotaryValue = args[1] * 360  -- Map 0-1 to 0-360
            
            -- Simulate tick events for rotation
            local newValue = math.floor(args[1] * 100)
            if self.lastRotaryValue then
                if newValue > self.lastRotaryValue then
                    koto.rotaryInc = true
                    koto.rotaryDec = false
                    koto.rotaryTicks = 1
                elseif newValue < self.lastRotaryValue then
                    koto.rotaryInc = false
                    koto.rotaryDec = true
                    koto.rotaryTicks = -1
                end
            end
            self.lastRotaryValue = newValue
        end
    end)
    
    -- Faders for additional control
    self:on("/1/fader1", function(args)
        if args[1] then
            koto.gyroZ = args[1] * 2 - 1  -- Map 0-1 to -1 to 1
        end
    end)
    
    -- Toggle switches
    self:on("/1/toggle1", function(args)
        if args[1] then
            koto.swA = args[1] > 0
        end
    end)
    
    self:on("/1/toggle2", function(args)
        if args[1] then
            koto.swB = args[1] > 0
        end
    end)
    
    self:on("/1/toggle3", function(args)
        if args[1] then
            koto.swC = args[1] > 0
        end
    end)
    
    -- Multitoggle for menu selection (if available)
    self:on("/1/multitoggle1/*/*", function(args, address)
        -- Parse row and column from address
        local row, col = address:match("/1/multitoggle1/(%d+)/(%d+)")
        if row and col and args[1] then
            local index = (tonumber(row) - 1) * 4 + tonumber(col)
            -- Could be used for app selection in Kumo
            if self.debug then
                print("Multitoggle pressed: " .. index)
            end
        end
    end)
    
    print("TouchOSC: Default koto mappings registered")
end

-- Process incoming messages
function bridge:update()
    if not self.enabled then
        return
    end
    
    -- No-op to keep update loop clean
    
    -- Receive UDP data
    local data, ip, port = self.server:receive()
    if not data then
        return
    end
    
    -- Update statistics
    self.stats.messages_received = self.stats.messages_received + 1
    self.stats.last_message_time = os.time()
    self.stats.last_ip = ip
    self.stats.last_port = port
    
    -- Decode OSC message
    local message, err = osc.decode(data)
    if not message then
        if self.debug then
            print("TouchOSC: Failed to decode message: " .. (err or "unknown"))
        end
        return
    end
    
    if self.debug then
        print(string.format("TouchOSC: %s from %s:%d", message.address, ip, port))
        if message.args and #message.args > 0 then
            for i, arg in ipairs(message.args) do
                print(string.format("  arg[%d]: %s", i, tostring(arg)))
            end
        end
    end
    
    -- Find and call handler
    local handler = self.handlers[message.address]
    if handler then
        handler(message.args, message.address)
        self.stats.messages_processed = self.stats.messages_processed + 1
    else
        -- Check for pattern matching (e.g., /1/multitoggle1/*/*)
        for pattern, handler in pairs(self.handlers) do
            if message.address:match("^" .. pattern:gsub("%*", "%%d+") .. "$") then
                handler(message.args, message.address)
                self.stats.messages_processed = self.stats.messages_processed + 1
                break
            end
        end
    end
end

-- Send feedback to TouchOSC
function bridge:send(address, ...)
    if not self.enabled or not self.stats.last_ip then
        return false
    end
    
    local data = osc.encode(address, ...)
    return self.server:send(data, self.stats.last_ip, self.stats.last_port or 9000)
end

-- Get connection statistics
function bridge:getStats()
    return self.stats
end

-- Enable/disable debug output
function bridge:setDebug(enabled)
    self.debug = enabled
end

return bridge