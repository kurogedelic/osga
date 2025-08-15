-- api/network/udp_server.lua
-- UDP server for receiving OSC messages

local udp_server = {}
udp_server.__index = udp_server

-- Try to load socket library
local socket_available, socket = pcall(require, "socket")

function udp_server.new(port)
    local self = setmetatable({}, udp_server)
    self.port = port or 8000
    self.running = false
    self.udp = nil
    
    if not socket_available then
        print("Warning: LuaSocket not available. UDP server disabled.")
        print("Install with: luarocks install luasocket")
        self.available = false
        return self
    end
    
    self.available = true
    return self
end

function udp_server:start()
    if not self.available then
        return false, "LuaSocket not available"
    end
    
    if self.running then
        return false, "Server already running"
    end
    
    -- Create UDP socket
    self.udp = socket.udp()
    
    -- Bind to all interfaces on specified port
    local success, err = self.udp:setsockname("*", self.port)
    if not success then
        return false, "Failed to bind to port " .. self.port .. ": " .. err
    end
    
    -- Set non-blocking mode
    self.udp:settimeout(0)
    
    self.running = true
    print("UDP server started on port " .. self.port)
    return true
end

function udp_server:stop()
    if self.udp then
        self.udp:close()
        self.udp = nil
    end
    self.running = false
    print("UDP server stopped")
end

function udp_server:receive()
    if not self.running or not self.udp then
        return nil
    end
    
    -- Receive data from any client
    local data, ip, port = self.udp:receivefrom()
    
    if data then
        return data, ip, port
    end
    
    return nil
end

function udp_server:send(data, ip, port)
    if not self.running or not self.udp then
        return false, "Server not running"
    end
    
    local success, err = self.udp:sendto(data, ip, port)
    if not success then
        return false, err
    end
    
    return true
end

-- Get local IP address
function udp_server:getLocalIP()
    if not socket_available then
        return "127.0.0.1"
    end
    
    local s = socket.udp()
    s:setpeername("8.8.8.8", 80)
    local ip = s:getsockname()
    s:close()
    return ip or "127.0.0.1"
end

function udp_server:isAvailable()
    return self.available
end

function udp_server:isRunning()
    return self.running
end

return udp_server