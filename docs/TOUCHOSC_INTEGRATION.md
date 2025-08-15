# TouchOSC Network Integration Plan

## Overview
Enable OSGA to receive control data from TouchOSC apps over network (OSC protocol), allowing remote control from phones/tablets.

## What is TouchOSC?
- Mobile app for iOS/Android that sends OSC (Open Sound Control) messages
- Custom UI creation with sliders, buttons, XY pads, etc.
- Network communication via UDP
- Industry standard for music/visual performance control

## Implementation Architecture

```
[TouchOSC App] --UDP/OSC--> [OSGA OSC Server] --> [OSGA Apps]
   (Phone)        Port 8000     (RPi/Desktop)        (Control)
```

## Phase 1: Core OSC Library

### 1.1 OSC Message Parser
```lua
-- api/network/osc.lua
local osc = {}

function osc.decode(data)
    -- Parse OSC packet format
    -- Extract address pattern and arguments
end

function osc.encode(address, ...)
    -- Create OSC message
    -- Return binary data
end
```

### 1.2 UDP Server
```lua
-- api/network/udp_server.lua
local socket = require("socket")

local server = {}

function server:start(port)
    self.udp = socket.udp()
    self.udp:setsockname("*", port or 8000)
    self.udp:settimeout(0) -- non-blocking
end

function server:receive()
    local data, ip, port = self.udp:receivefrom()
    if data then
        return osc.decode(data), ip, port
    end
end
```

## Phase 2: TouchOSC Bridge

### 2.1 Message Router
```lua
-- api/touchosc/bridge.lua
local bridge = {
    handlers = {},
    server = nil
}

function bridge:init(port)
    self.server = require("api.network.udp_server")
    self.server:start(port or 8000)
end

function bridge:on(address, callback)
    self.handlers[address] = callback
end

function bridge:update()
    local msg, ip, port = self.server:receive()
    if msg and self.handlers[msg.address] then
        self.handlers[msg.address](msg.args, ip, port)
    end
end
```

### 2.2 Control Mapping
```lua
-- api/touchosc/mapping.lua
local mapping = {}

-- Map TouchOSC controls to OSGA inputs
mapping.controls = {
    ["/1/fader1"] = function(value) 
        koto.gyroX = (value - 0.5) * 2 
    end,
    ["/1/toggle1"] = function(value) 
        koto.swA = value > 0 
    end,
    ["/1/xy1"] = function(x, y)
        koto.gyroX = (x - 0.5) * 2
        koto.gyroY = (y - 0.5) * 2
    end,
    ["/1/rotary1"] = function(value)
        koto.rotaryValue = value * 360
    end
}
```

## Phase 3: App Integration

### 3.1 Update osga-sim/main.lua
```lua
-- Add to love.load()
if love.system.getOS() ~= "Android" and love.system.getOS() ~= "iOS" then
    touchOSC = require("api.touchosc.bridge")
    touchOSC:init(8000)
    
    -- Register handlers
    touchOSC:on("/1/fader1", function(args)
        -- Update koto values
    end)
end

-- Add to love.update(dt)
if touchOSC then
    touchOSC:update()
end
```

### 3.2 Configuration File
```lua
-- config/touchosc.lua
return {
    enabled = true,
    port = 8000,
    
    -- Default layout mapping
    layout = "osga_default",
    
    -- Control ranges
    ranges = {
        gyro = { min = -2, max = 2 },
        rotary = { min = 0, max = 360 }
    },
    
    -- Network settings
    network = {
        broadcast = true,
        multicast = "224.0.0.1"
    }
}
```

## Phase 4: TouchOSC Layouts

### 4.1 Default OSGA Layout
Create TouchOSC layout file with:
- 3 Toggle buttons (A, B, C)
- 1 Push button (R)
- 1 Rotary knob
- 1 XY pad (Gyro simulation)
- Multiple faders for parameters

### 4.2 App-Specific Layouts
- **Mariawa**: XY pad for gravity, faders for physics params
- **Acidtest**: Step sequencer grid, knobs for filter
- **Yoru**: Sliders for ambient mix levels

## Implementation Steps

### Week 1: Core OSC
1. Implement OSC decoder/encoder
2. Create UDP server
3. Test with simple messages

### Week 2: Bridge Layer
1. Message routing system
2. Control mapping
3. Configuration system

### Week 3: Integration
1. Add to simulator
2. Add to runtime
3. Create default mappings

### Week 4: Layouts & Testing
1. Design TouchOSC layouts
2. Test with real devices
3. Documentation

## Dependencies

```lua
-- Required LuaRocks packages
dependencies = {
    "luasocket",     -- UDP networking
    "lua-osc",       -- OSC protocol (optional)
    "lustache"       -- Template engine for layouts
}
```

## Network Discovery

### Zeroconf/Bonjour
```lua
-- Advertise OSGA as OSC receiver
local zeroconf = require("zeroconf")
zeroconf:advertise("OSGA", "_osc._udp", 8000)
```

## Security Considerations

1. **Input Validation**: Sanitize all OSC values
2. **Rate Limiting**: Prevent message flooding
3. **IP Whitelist**: Optional trusted device list
4. **Value Clamping**: Ensure values within safe ranges

## Testing Tools

- **TouchOSC Editor**: Layout creation
- **OSCulator** (Mac): OSC monitoring
- **Pure Data**: OSC testing
- **oscsend/oscdump**: Command-line tools

## Example Usage

```lua
-- In your app
function app.init()
    -- Register for TouchOSC events
    if osga.touchosc then
        osga.touchosc:on("/mariawa/gravity", function(value)
            gravity = value * 2
        end)
        
        osga.touchosc:on("/mariawa/add_ball", function()
            addCircle()
        end)
    end
end
```

## Performance Notes

- UDP is connectionless, expect occasional packet loss
- Keep update rate reasonable (30-60 Hz)
- Buffer multiple parameter changes
- Use OSC bundles for synchronized updates

## Future Extensions

1. **Bi-directional**: Send feedback to TouchOSC
2. **MIDI Bridge**: TouchOSC → MIDI → OSGA
3. **Web Control**: WebSocket alternative
4. **Multi-device**: Support multiple controllers
5. **Recording**: Capture and replay OSC sequences