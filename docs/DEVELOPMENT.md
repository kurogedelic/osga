# OSGA Development Guide

## Project Structure

```
osga/
├── api/                    # Core API modules
│   ├── sound/             # Audio engine
│   ├── network/           # Networking (OSC, UDP)
│   ├── touchosc/          # TouchOSC integration
│   ├── libs/              # Third-party libraries
│   └── fonts/             # Font resources
├── apps/                  # OSGA applications
├── config/                # Platform-specific configurations
├── debug/                 # Debug and monitoring tools
├── docs/                  # Documentation
├── osga-run/              # Runtime environment
├── osga-sim/              # Simulator for development
├── scripts/               # Deployment and utility scripts
└── touchosc/              # TouchOSC layouts (.tosc files)
```

## Quick Start

### Development Environment
```bash
# macOS
./run_mac.sh

# Linux
./run_linux.sh

# Windows
run_windows.bat
```

### Remote Debugging (Raspberry Pi)
```bash
# Deploy debug version to RPi
./scripts/deploy_debug_rpi.sh pi@hostname.local

# Monitor performance
ssh pi@hostname.local 'tail -f /tmp/osga_debug_*.log'
```

## API Reference

### Core Modules
- **`osga.sound`** - Audio engine with synthesis and sampling
- **`osga.gfx`** - Graphics utilities and effects
- **`osga.system`** - Platform detection and configuration
- **`osga.font`** - Font management

### Platform Optimization
The sound API automatically detects Raspberry Pi 3A and applies optimizations:
- Reduced sample rate (22050 Hz)
- Larger audio buffers (4096 samples)
- Limited voice count (6 simultaneous)
- Disabled filters for performance

### TouchOSC Integration
Network control via OSC protocol on port 8000:
```lua
-- Default mappings
/1/push1-4  → koto.swA, swB, swC, swR
/1/xy1      → koto.gyroX, gyroY
/1/rotary1  → koto.rotaryValue
```

## App Development

### Basic App Structure
```lua
local app = {
    _meta = {
        name = "App Name",
        author = "Your Name",
        version = "1.0",
        slug = "appname"
    }
}

function app.init()
    -- Initialize app
end

function app.update(koto, dt)
    -- Update logic (koto = input state)
end

function app.draw(koto)
    -- Rendering
end

function app.cleanup()
    -- Cleanup resources
end

return app
```

### Input Handling (koto object)
```lua
koto = {
    swA, swB, swC, swR = false,  -- Button states
    rotaryValue = 0,             -- Rotary encoder (0-360)
    rotaryInc, rotaryDec = false,-- Rotary direction
    gyroX, gyroY, gyroZ = 0,     -- Gyroscope simulation
    button = { back = false }    -- System buttons
}
```

### Audio Synthesis
```lua
-- Create oscillator
local osc = osga.sound.synth.oscillator("sawtooth", 440)

-- Create channel and add source
local channel = osga.sound.channel.new()
channel:addSource(osc)
osga.sound.addChannel(channel)

-- Start playback
channel:play()
```

## Debugging

### Performance Monitoring
- Press **F12** in runtime to toggle debug overlay
- Monitor FPS, memory usage, and active audio sources
- Check logs for buffer underruns and performance issues

### Audio Troubleshooting
```lua
-- Get debug information
local info = osga.sound.getDebugInfo and osga.sound.getDebugInfo()
if info then
    print("Platform:", info.platform)
    print("Optimized:", info.optimized)
    print("Active voices:", info.active_voices)
end
```

## Platform-Specific Notes

### Raspberry Pi 3A
- Automatic detection and optimization
- Mono audio output for performance
- Filters disabled by default
- Larger audio buffers to prevent dropouts

### Desktop Development
- Full feature set available
- Stereo audio output
- All effects and filters enabled
- Mouse simulation for touch testing

## Testing

### TouchOSC Testing
1. Import `.tosc` files from `touchosc/` directory
2. Configure TouchOSC to send to OSGA's IP on port 8000
3. Use debug mode ('O' key) to monitor OSC messages

### Performance Testing
1. Run Acidtest app for audio stress testing
2. Monitor debug overlay for performance metrics
3. Check system resources on target hardware

## Deployment

### Raspberry Pi Deployment
```bash
# Standard deployment
git clone https://github.com/kurogedelic/osga.git
cd osga

# Debug deployment
./scripts/deploy_debug_rpi.sh pi@hostname.local
```

### Service Configuration
OSGA can run as a systemd service on Raspberry Pi:
```bash
sudo systemctl enable osga
sudo systemctl start osga
```

## Contributing

### Code Style
- Use 4-space indentation
- Prefer explicit variable names
- Comment complex algorithms
- Follow existing API patterns

### Performance Guidelines
- Test on target hardware (RPi 3A)
- Monitor memory usage in loops
- Prefer integer math where possible
- Use voice limiting for audio applications

### Documentation
- Update relevant `.md` files for significant changes
- Document new API functions
- Include usage examples
- Update `CLAUDE.md` for major sessions