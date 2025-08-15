# TouchOSC Layouts for OSGA

This directory contains TouchOSC layout files (.tosc) for controlling OSGA applications.

## Available Layouts

### osga-default.tosc
The default OSGA controller layout with:
- **Main Page**: Basic controls for all OSGA apps
  - 4 Push buttons (A, B, C, R)
  - XY pad for gyro simulation
  - Rotary knob control
  - Z-axis fader
  - 3 Toggle switches
  
- **Mariawa Page**: Specialized controls for Mariawa app
  - Gravity XY pad
  - Add Ball button
  - Clear button
  - Physics parameter faders (friction, bounce, size)
  
- **Settings Page**: Connection information and status

## How to Use

### 1. Import Layout to TouchOSC

#### On Mobile (iOS/Android):
1. Install TouchOSC from App Store/Google Play
2. Open TouchOSC
3. Tap the layout selector (document icon)
4. Tap '+' to add new layout
5. Choose "Import from File" or "Import from URL"
6. Select the .tosc file or use GitHub raw URL

#### On Desktop (TouchOSC Editor):
1. Open TouchOSC Editor
2. File → Open
3. Select the .tosc file
4. File → Sync to upload to your device

### 2. Configure Connection

1. Start OSGA simulator - it will display your IP address:
   ```bash
   ./run_mac.sh  # or run_linux.sh / run_windows.bat
   ```

2. In TouchOSC, go to Settings:
   - **Host**: Enter the IP address shown by OSGA (e.g., 192.168.1.100)
   - **Port**: 8000
   - **Protocol**: OSC (not MIDI)

3. Select the OSGA layout and start controlling!

### 3. Debug Mode

Press 'O' key in the OSGA simulator to toggle debug mode and see incoming OSC messages.

## Control Mappings

### Default Mappings (Main Page)

| TouchOSC Control | OSC Address | OSGA Input | Description |
|-----------------|-------------|------------|-------------|
| Push 1 (A) | /1/push1 | koto.swA | Button A |
| Push 2 (B) | /1/push2 | koto.swB | Button B |
| Push 3 (C) | /1/push3 | koto.swC | Button C |
| Push 4 (R) | /1/push4 | koto.swR | Button R |
| XY Pad | /1/xy1 | koto.gyroX/Y | Gyro simulation (-2 to 2) |
| Rotary | /1/rotary1 | koto.rotaryValue | Rotary encoder (0-360°) |
| Fader | /1/fader1 | koto.gyroZ | Z-axis control (-1 to 1) |
| Toggle 1 | /1/toggle1 | koto.swA | Toggle button A |
| Toggle 2 | /1/toggle2 | koto.swB | Toggle button B |
| Toggle 3 | /1/toggle3 | koto.swC | Toggle button C |

### Mariawa Specific Controls

| TouchOSC Control | OSC Address | Function |
|-----------------|-------------|----------|
| Gravity XY | /mariawa/gravity | Control gravity direction |
| Add Ball | /mariawa/add_ball | Add new ball to scene |
| Clear | /mariawa/clear | Clear all balls |
| Friction | /mariawa/friction | Adjust friction (0-2) |
| Bounce | /mariawa/bounce | Adjust bounciness (0-1) |
| Size | /mariawa/radius | Ball radius (5-50) |

## Creating Custom Layouts

To create your own TouchOSC layout for OSGA:

1. Use TouchOSC Editor (free from hexler.net)
2. Set canvas size to match your device
3. Add controls with OSC addresses matching the patterns above
4. Save as .tosc file in this directory
5. Update this README with your layout documentation

## Network Requirements

- OSGA device and TouchOSC device must be on same network
- Port 8000 must be open for UDP traffic
- Wi-Fi recommended for lowest latency
- Typical latency: 5-20ms on local network

## Troubleshooting

### No Connection
- Verify IP address is correct
- Check both devices are on same network
- Disable firewall temporarily to test
- Try using IP instead of hostname

### High Latency
- Move closer to Wi-Fi router
- Reduce network traffic
- Close other apps using network
- Use 5GHz Wi-Fi if available

### Controls Not Working
- Press 'O' in simulator to see debug output
- Verify OSC addresses match exactly
- Check value ranges in TouchOSC editor
- Ensure layout is using OSC, not MIDI

## Layout File Format

The .tosc files are XML-based and can be edited manually if needed. Basic structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<layout version="2">
    <tabpage name="PageName">
        <control_type name="name" x="0" y="0" w="100" h="50">
            <osc>/address/pattern</osc>
        </control_type>
    </tabpage>
</layout>
```

## License

These TouchOSC layouts are part of the OSGA project and follow the same LGPL v3 license.