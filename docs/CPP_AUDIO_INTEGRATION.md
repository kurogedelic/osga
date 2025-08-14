# C++ Audio Effects Integration Guide

## Overview
OSGA supports native C++ audio effects through Love2D's LuaJIT FFI (Foreign Function Interface). This allows high-performance DSP code while maintaining Lua's ease of use.

## Quick Start

### 1. Write Your C++ Effect

```cpp
// native/effects/reverb.cpp
extern "C" {
    void process_reverb(float* buffer, int samples, float room_size, float damping) {
        // Your DSP code here
        for(int i = 0; i < samples; i++) {
            buffer[i] *= 0.5f; // Example: simple gain
        }
    }
}
```

### 2. Compile to Shared Library

```bash
# macOS
g++ -dynamiclib -O3 reverb.cpp -o libreverb.dylib

# Linux  
g++ -shared -fPIC -O3 reverb.cpp -o libreverb.so

# Windows
cl /LD /O2 reverb.cpp /Fe:reverb.dll
```

### 3. Create Lua Binding

```lua
-- api/sound/effects/reverb.lua
local ffi = require("ffi")

ffi.cdef[[
    void process_reverb(float* buffer, int samples, float room_size, float damping);
]]

local lib = ffi.load("reverb")  -- Loads from lib/ directory

local reverb = {}

function reverb:process(soundData, roomSize, damping)
    local samples = soundData:getSampleCount()
    local ptr = ffi.cast("float*", soundData:getPointer())
    lib.process_reverb(ptr, samples, roomSize or 0.5, damping or 0.5)
end

return reverb
```

### 4. Use in OSGA App

```lua
-- apps/yourapp/main.lua
local reverb = require('api.sound.effects.reverb')

function processAudio(soundData)
    reverb:process(soundData, 0.8, 0.3)
end
```

## Project Structure

```
osga/
├── native/
│   ├── Makefile
│   └── effects/
│       ├── reverb.cpp
│       ├── distortion.cpp
│       └── compressor.cpp
├── lib/
│   ├── libreverb.dylib
│   ├── libdistortion.dylib
│   └── libcompressor.dylib
└── api/sound/effects/
    ├── reverb.lua
    ├── distortion.lua
    └── compressor.lua
```

## Build Script

```makefile
# native/Makefile
UNAME := $(shell uname)
CXX = g++
CXXFLAGS = -O3 -Wall

ifeq ($(UNAME), Darwin)
    EXT = dylib
    FLAGS = -dynamiclib
else ifeq ($(UNAME), Linux)
    EXT = so
    FLAGS = -shared -fPIC
else  # Windows
    CXX = cl
    FLAGS = /LD
    EXT = dll
endif

EFFECTS = reverb distortion compressor
TARGETS = $(EFFECTS:%=../lib/lib%.$(EXT))

all: $(TARGETS)

../lib/lib%.$(EXT): effects/%.cpp
	$(CXX) $(FLAGS) $(CXXFLAGS) $< -o $@

clean:
	rm -f ../lib/*
```

## Performance Tips

1. **Buffer Processing**: Process entire buffers, not sample-by-sample
2. **Memory**: Pre-allocate delay lines and buffers
3. **SIMD**: Use SSE/AVX intrinsics for parallel processing
4. **Threading**: Keep DSP in single thread to avoid sync overhead

## Example: Simple Distortion

```cpp
// native/effects/distortion.cpp
#include <cmath>

extern "C" {
    void process_distortion(float* buffer, int samples, float drive, float mix) {
        for(int i = 0; i < samples; i++) {
            float clean = buffer[i];
            float distorted = tanh(buffer[i] * drive);
            buffer[i] = clean * (1.0f - mix) + distorted * mix;
        }
    }
}
```

```lua
-- api/sound/effects/distortion.lua
local ffi = require("ffi")

ffi.cdef[[
    void process_distortion(float* buffer, int samples, float drive, float mix);
]]

local lib = ffi.load("distortion")

return {
    process = function(self, soundData, drive, mix)
        local samples = soundData:getSampleCount()
        local ptr = ffi.cast("float*", soundData:getPointer())
        lib.process_distortion(ptr, samples, drive or 2.0, mix or 0.7)
    end
}
```

## Debugging

- Use `LD_LIBRARY_PATH` (Linux) or `DYLD_LIBRARY_PATH` (macOS) to specify library location
- Check library dependencies with `ldd` (Linux) or `otool -L` (macOS)
- Use `nm` to verify exported symbols

## Platform Notes

- **macOS**: May need code signing for Apple Silicon
- **Windows**: Include Visual C++ redistributables
- **Linux**: Ensure compatible glibc version

## Resources

- [LuaJIT FFI Documentation](http://luajit.org/ext_ffi.html)
- [Love2D Sound Data API](https://love2d.org/wiki/SoundData)
- [DSP Algorithm Collection](https://github.com/topics/dsp-algorithms)