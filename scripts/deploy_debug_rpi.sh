#!/bin/bash
# Deploy debug version to Raspberry Pi 3A
# Usage: ./deploy_debug_rpi.sh [RPI_IP_ADDRESS]

RPI_IP=${1:-"raspberrypi.local"}
RPI_USER="pi"
OSGA_PATH="/home/pi/osga"

echo "========================================"
echo "OSGA Debug Deployment for RPi 3A"
echo "========================================"
echo "Target: $RPI_USER@$RPI_IP"
echo ""

# Check if we can connect
echo "Testing connection..."
if ! ssh -o ConnectTimeout=5 $RPI_USER@$RPI_IP "echo 'Connected'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to $RPI_IP"
    echo "Please check:"
    echo "  1. RPi is powered on and connected to network"
    echo "  2. SSH is enabled on the RPi"
    echo "  3. IP address is correct (try: ./deploy_debug_rpi.sh 192.168.x.x)"
    exit 1
fi

echo "✅ Connection successful"
echo ""

# Create backup
echo "Creating backup on RPi..."
ssh $RPI_USER@$RPI_IP "cp -r $OSGA_PATH $OSGA_PATH.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Copy debug files
echo "Deploying debug components..."

# Copy debug module
scp debug/runtime-debug.lua $RPI_USER@$RPI_IP:$OSGA_PATH/debug/

# Copy RPi 3A config
scp config/audio_rpi3a.lua $RPI_USER@$RPI_IP:$OSGA_PATH/config/

# Copy optimized sound module
scp api/sound/init_optimized.lua $RPI_USER@$RPI_IP:$OSGA_PATH/api/sound/

# Create debug launcher script
cat << 'EOF' > /tmp/osga_debug_launcher.sh
#!/bin/bash
# OSGA Debug Launcher for RPi 3A

cd /home/pi/osga

# Set environment for better performance
export LOVE_GRAPHICS_USE_GL2=1
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0

# Run with debug mode
love . --debug 2>&1 | tee /tmp/osga_runtime_$(date +%Y%m%d_%H%M%S).log &
LOVE_PID=$!

echo "OSGA running with PID: $LOVE_PID"
echo "Debug log: /tmp/osga_runtime_*.log"
echo ""
echo "Commands:"
echo "  tail -f /tmp/osga_runtime_*.log  # View live log"
echo "  kill $LOVE_PID                    # Stop OSGA"
echo "  htop                              # Monitor performance"
echo ""
echo "Press F12 in OSGA to toggle debug overlay"
EOF

scp /tmp/osga_debug_launcher.sh $RPI_USER@$RPI_IP:$OSGA_PATH/
ssh $RPI_USER@$RPI_IP "chmod +x $OSGA_PATH/osga_debug_launcher.sh"

# Create modified main.lua with debug hooks
echo "Adding debug hooks to runtime..."
ssh $RPI_USER@$RPI_IP << 'REMOTE_SCRIPT'
cd /home/pi/osga

# Backup original main.lua
cp main.lua main.lua.original

# Add debug module loading at the start
sed -i '1a\
-- Load debug module for RPi 3A troubleshooting\
local debug = require("debug.runtime-debug")\
debug.init()\
' main.lua

# Add debug.update() to love.update
sed -i '/function love.update/a\
    debug.update(love.timer.getDelta())\
' main.lua

# Add debug.draw() to love.draw  
sed -i '/function love.draw/a\
    debug.draw()\
' main.lua

# Add debug.keypressed() to love.keypressed
sed -i '/function love.keypressed/a\
    debug.keypressed(key)\
' main.lua

# Replace sound module with optimized version if RPi 3A detected
sed -i 's/require("api.sound")/require("api.sound.init_optimized")/g' api/init.lua

echo "Debug hooks installed"
REMOTE_SCRIPT

echo ""
echo "========================================"
echo "✅ Debug deployment complete!"
echo "========================================"
echo ""
echo "To start OSGA with debugging on RPi:"
echo "  ssh $RPI_USER@$RPI_IP"
echo "  cd $OSGA_PATH"
echo "  ./osga_debug_launcher.sh"
echo ""
echo "To view logs remotely:"
echo "  ssh $RPI_USER@$RPI_IP 'tail -f /tmp/osga_runtime_*.log'"
echo ""
echo "To check filter issue:"
echo "  1. Run OSGA with debug"
echo "  2. Launch an app that uses filters (Acidtest)"
echo "  3. Check log for 'Filter:' messages"
echo "  4. Press F12 to see performance overlay"
echo ""
echo "To restore original version:"
echo "  ssh $RPI_USER@$RPI_IP 'cp main.lua.original main.lua'"
echo ""

# Show current RPi status
echo "Current RPi Status:"
ssh $RPI_USER@$RPI_IP << 'STATUS'
echo -n "CPU Temp: "
vcgencmd measure_temp
echo -n "Memory: "
free -h | grep Mem
echo -n "Disk: "
df -h / | tail -1
echo -n "Audio devices: "
aplay -l | grep card | head -1
STATUS