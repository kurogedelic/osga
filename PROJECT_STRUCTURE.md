# OSGA Project Structure

## Directory Layout

```
osga/
├── api/                        # Core API modules
│   ├── init.lua               # API initialization & path configuration
│   ├── system.lua             # System utilities (dimensions, time)
│   ├── gfx.lua                # Graphics API (shapes, colors, transforms)
│   ├── font.lua               # Font management
│   ├── fonts/                 # Font assets
│   │   └── nada.png           # Custom bitmap font
│   ├── libs/                  # Third-party libraries
│   │   ├── json.lua           # JSON parser
│   │   └── sone.lua           # Sound effects library
│   └── sound/                 # Audio synthesis system
│       ├── init.lua           # Sound API entry point
│       ├── channel.lua        # Audio channel mixing
│       ├── source.lua         # Audio source abstraction
│       ├── synth.lua          # Oscillators & synthesis
│       ├── sampler.lua        # Sample playback
│       ├── noise.lua          # Noise generators
│       ├── envelope.lua       # ADSR envelopes
│       ├── lfo.lua            # Low-frequency oscillators
│       ├── utils.lua          # Audio utilities
│       ├── effects.lua        # Effects routing
│       └── effects/           # Audio effects
│           └── filter.lua     # Filters (LP, HP, BP)
│
├── apps/                      # Applications
│   ├── installed.json        # App registry
│   ├── kumo/                  # [SYSTEM] App launcher
│   ├── hardtest/              # Hardware test utility
│   ├── mariawa/               # Physics-based music app
│   ├── ambient/               # Ambient sound meter
│   ├── yoru/                  # Night sounds generator
│   ├── shore/                 # Ocean shore simulation
│   ├── amebako/               # Amoeba visuals
│   ├── acidtest/              # Acid synthesis demo
│   ├── buddha/                # Buddha machine
│   └── densha/                # Train sounds
│
├── osga-sim/                  # Simulator environment
│   ├── main.lua               # Simulator entry point
│   ├── topbar.lua             # UI top bar (controls, info)
│   ├── conf.lua               # Love2D configuration
│   └── assets/                # Simulator assets
│       ├── default_icon.png  # Default app icon
│       └── loading_*.png     # Loading animations
│
├── osga-run/                  # Production runtime
│   ├── main.lua               # Runtime entry point
│   ├── conf.lua               # Love2D configuration
│   └── assets/                # Runtime assets
│       └── default_icon.png  # Default app icon
│
├── README.md                  # Project documentation
├── CLAUDE.md                  # Development notes & osga-studio plan
├── PROJECT_STRUCTURE.md      # This file
└── Ideas.md                   # App ideas & concepts
```

## File Naming Conventions

- **Lua modules**: `lowercase.lua`
- **Apps**: `lowercase/main.lua`
- **Assets**: `snake_case.png`, `snake_case.wav`
- **Documentation**: `UPPERCASE.md`

## App Structure

Each app follows this structure:
```
apps/appname/
├── main.lua      # App entry point (required)
├── icon.png      # 64x64 app icon (required)
└── assets/       # Optional assets (images, sounds)
```

## Key Files

### API Entry Points
- `api/init.lua` - Main API initialization
- `api/sound/init.lua` - Sound subsystem
- `api/gfx.lua` - Graphics subsystem

### App Management
- `apps/installed.json` - App registry
- `apps/kumo/main.lua` - System launcher

### Simulator
- `osga-sim/main.lua` - Development environment
- `osga-sim/topbar.lua` - Debug UI

## Module Dependencies

```
main.lua (sim/run)
  └── api/init.lua
      ├── api/system.lua
      ├── api/gfx.lua
      ├── api/font.lua
      └── api/sound/init.lua
          ├── api/sound/channel.lua
          ├── api/sound/synth.lua
          ├── api/sound/sampler.lua
          └── api/libs/sone.lua
```

## Input/Output Flow

```
Physical Input (Keyboard/Mouse)
    ↓
osga-sim/main.lua
    ↓
koto object (input state)
    ↓
app.draw(koto)
    ↓
OSGA API calls
    ↓
Love2D backend
    ↓
Display/Audio Output
```