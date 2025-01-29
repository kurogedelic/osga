# osga : Organic Sound Generative Architecture

## Overview

organic sound generative architechture.

## Install

[osga-setup](https://github.com/hugelton/osga-setup)

## Requipments

### Mainframe

- Raspberry Pi Zero W Family

### Compotnents

- ILI9341 320x240
- MPU6050
- MAX98357 or PCM5102

## Hardware

[osga-hardware](https://github.com/hugelton/osga-hardware)

## Structure

- osga # main system
- | - osga-kage # display and graphics
- | - osga-nami # audio and synth
- | - osga-koto # sensor and physical interfaces
- | - osga-torii # web server
- | - osga-kumo # home app

## Sublications

### files

for example "Block" is sublication name.

Block/
├── main.lua # main process
├── icon.png # 32px icon
└── info.json # sublication infomation

#### icon.png

32x32px PNG

#### main.lua

```lua
block = {} // make instance table, must be same name on info.json

local squareSize = 0

// .init is must
function block.init()
    // running at once
end

// display draw
function block.draw()
    kage.clear(0)                             // clear background
    kage.drawBox(0,0,squareSize,squareSize)   // draw square
    kage.draw()                               // send buffer
end

// .update is must
function block.update()
    // running at framerate
    if squareSize < 100 then
        squareSize = squareSize + 1
    end
end
```

#### info.json

```json
{
	"instance": "block",
	"title": "Block",
	"author": "John Appleseed",
	"description": "Lorem ipsum",
	"version": "1.0.0",
	"tags": ["drone", "generative", "art"]
}
```
