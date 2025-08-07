# OSGA - Open Sound & Graphics Appliance

A Love2D-based creative coding environment designed for osga-shield hardware, featuring a 320x240 pixel display and physical controls.

![OSGA](https://img.shields.io/badge/OSGA-v1.0.0-blue.svg)
![Love2D](https://img.shields.io/badge/Love2D-11.4-ff69b4.svg)
![License](https://img.shields.io/badge/license-LGPL%20v3-green.svg)

## Overview

OSGA (Open Sound & Graphics Appliance) is a platform for creating and running interactive audio-visual applications on constrained hardware. It provides a simple API for graphics, sound synthesis, and hardware input handling.

**Hardware:** [osga-shield](https://github.com/kurogedelic/osga-shield) - An open hardware platform for creative coding

## Features

- **Modular App System**: Launch different applications from the home screen (Kumo)
- **Real-time Audio Synthesis**: Advanced sound generation with oscillators, filters, and effects
- **Pixel Art Graphics**: Optimized for 320x240 displays with bitmap-style rendering
- **Physical Controls**: Support for buttons, rotary encoder, and gyroscope input
- **Hot-swappable Apps**: Dynamic loading and unloading of applications

## Getting Started

### Prerequisites

- [Love2D](https://love2d.org/) version 11.4 or higher
- Git for cloning the repository

### Installing Love2D

#### macOS
```bash
# Using Homebrew
brew install love

# Or download from https://love2d.org/
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install love2d
```

#### Windows
Download the installer from [love2d.org](https://love2d.org/) or use:
```bash
# Using Chocolatey
choco install love2d
```

#### Arch Linux
```bash
sudo pacman -S love
```

### Installation

```bash
git clone https://github.com/kurogedelic/osga.git
cd osga
```

### Running the Simulator

```bash
# Run the simulator with default app (Kumo launcher)
love osga-sim

# Run a specific app directly
love osga-sim apps/mariawa
```

### Controls

- **A, S, D**: Switch buttons A, B, C
- **Space**: Rotary encoder button
- **Left/Right Arrow or Mouse Wheel**: Rotary encoder rotation
- **Mouse Movement**: Gyroscope simulation (when enabled)
- **ESC**: Back button
- **P**: Toggle pixel effect (2x/4x pixelation)

## Project Structure

```
osga/
├── api/                    # Core API modules
│   ├── init.lua           # Main API initialization
│   ├── gfx.lua            # Graphics functions
│   ├── font.lua           # Font management
│   ├── system.lua         # System utilities
│   └── sound/             # Audio synthesis modules
│       ├── init.lua       # Sound API entry point
│       ├── channel.lua    # Audio channel management
│       ├── synth.lua      # Oscillator synthesis
│       ├── sampler.lua    # Sample playback
│       └── effects/       # Audio effects
├── apps/                   # Applications
│   ├── installed.json     # App registry
│   ├── kumo/              # App launcher
│   ├── mariawa/           # Physics-based music app
│   ├── hardtest/          # Hardware test utility
│   ├── yoru/              # Night sounds ambient app
│   └── ...                # Other apps
├── osga-sim/              # Simulator environment
│   ├── main.lua           # Simulator entry point
│   └── topbar.lua         # UI topbar component
└── osga-run/              # Production runtime
```

## API Reference

### Graphics (osga.gfx)

```lua
-- Drawing shapes
osga.gfx.clear(r, g, b)                    -- Clear screen with color
osga.gfx.rect(x, y, w, h, mode)           -- Draw rectangle ("fill" or "line")
osga.gfx.circle(x, y, radius, mode)       -- Draw circle
osga.gfx.line(x1, y1, x2, y2)            -- Draw line
osga.gfx.polygon(points, mode)           -- Draw polygon

-- Color and style
osga.gfx.color(r, g, b, a)               -- Set drawing color (0-1 range)
osga.gfx.lineWidth(width)                -- Set line width

-- Text
osga.gfx.text(text, x, y)                -- Draw text at position
osga.gfx.setFont(font)                    -- Set current font

-- Transformations
osga.gfx.push()                          -- Save transform state
osga.gfx.pop()                           -- Restore transform state
osga.gfx.translate(x, y)                 -- Move origin
osga.gfx.rotate(angle)                   -- Rotate (radians)
osga.gfx.scale(sx, sy)                   -- Scale
```

### Sound (osga.sound)

```lua
-- Create oscillators
local osc = osga.sound.synth.newOscillator(type, frequency)
-- Types: "sine", "square", "sawtooth", "triangle"

-- Create and manage channels
local channel = osga.sound.channel.new()
channel:addSource(osc)
channel:play()
channel:stop()

-- Add to active channels
osga.sound.addChannel(channel)
osga.sound.removeChannel(channel)

-- Sample playback
local sampler = osga.sound.sampler.new(audioData)
sampler:play()
```

### System (osga.system)

```lua
osga.system.width              -- Display width (320)
osga.system.height             -- Display height (240)
osga.system.getTime()          -- Get current time
osga.system.getDelta()         -- Get frame delta time
```

### Input (koto)

Applications receive input through the `koto` parameter in their draw function:

```lua
function app.draw(koto)
    -- Boolean switches
    if koto.swA then ... end        -- Button A pressed
    if koto.swB then ... end        -- Button B pressed
    if koto.swC then ... end        -- Button C pressed
    if koto.swR then ... end        -- Rotary button pressed
    
    -- Rotary encoder
    local angle = koto.rotaryValue  -- Current angle (0-360)
    if koto.rotaryInc then ... end  -- Rotated clockwise
    if koto.rotaryDec then ... end  -- Rotated counter-clockwise
    
    -- Gyroscope
    local gx = koto.gyroX           -- X axis (-2 to 2)
    local gy = koto.gyroY           -- Y axis (-2 to 2)
    local gz = koto.gyroZ           -- Z axis (-2 to 2)
    
    -- Navigation
    if koto.button.back then ... end -- Back button
end
```

## Creating an App

1. Create a new directory in `apps/` with your app name
2. Add `main.lua` with this structure:

```lua
local app = {}

-- Metadata (required)
app._meta = {
    name = "My App",
    slug = "myapp",
    author = "Your Name",
    version = "1.0.0"
}

-- Initialize (optional)
function app.init()
    -- Setup code here
end

-- Draw function (required)
function app.draw(koto)
    -- Your drawing and update code
    osga.gfx.clear(0, 0, 0)
    osga.gfx.color(1, 1, 1)
    osga.gfx.text("Hello OSGA!", 100, 100)
end

-- Cleanup (optional)
function app.cleanup()
    -- Release resources
end

return app
```

3. Add a 64x64 `icon.png` in your app directory
4. Register your app in `apps/installed.json`:

```json
{
    "existing": "apps...",
    "myapp": "My App"
}
```

## TODO

### Core Features
- [ ] Persistent storage API for app data
- [ ] Network/HTTP request capabilities
- [ ] More audio effects (reverb, delay, chorus)
- [ ] Sprite/image loading and drawing
- [ ] Particle system API
- [ ] Touch/mouse input for apps

### Apps
- [ ] Music sequencer/tracker
- [ ] Drawing/paint application  
- [ ] Game framework with collision detection
- [ ] Weather display app
- [ ] Clock/timer utilities
- [ ] Settings configuration app

### Development Tools
- [ ] App packaging system
- [ ] Live reload for development
- [ ] Performance profiler
- [ ] Visual app builder
- [ ] Documentation generator

### Hardware Support
- [ ] Serial communication with osga-shield devices
- [ ] Firmware update mechanism
- [ ] Battery status API
- [ ] LED control API
- [ ] Accelerometer calibration

### Improvements
- [ ] Optimize rendering pipeline
- [ ] Add more bitmap fonts
- [ ] Implement app sandboxing
- [ ] Create app store/repository system
- [ ] Add unit tests
- [ ] Internationalization support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the GNU Lesser General Public License v3.0 (LGPL v3).

This means:
- You can use OSGA in your projects (including commercial ones)
- Apps you create can have any license you choose
- If you modify the OSGA core/API, you must share those changes
- You must include the LGPL license and copyright notices

See the [LICENSE](LICENSE) file for the full license text.

## Acknowledgments

**OSGA** by Leo Kuroshita from Hugelton Instruments (2025)

**Credits:**
- **NADA font** by Leo Kuroshita
- **Sound synthesis** inspired by denver.lua by SuperZazu  
  https://github.com/superzazu/denver.lua (MIT License)
- **Additional libraries:**
  - sone.lua by camchenry (MIT License)
  - json.lua (MIT License)

**Special Thanks:**
- Built with [Love2D](https://love2d.org/)
- Inspired by fantasy consoles like PICO-8 and TIC-80
- Designed for the [osga-shield](https://github.com/kurogedelic/osga-shield) hardware platform