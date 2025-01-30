# create_project.sh
#!/bin/bash

# ディレクトリ構造の作成
mkdir -p src/{kage,nami,torii,kumo}
mkdir -p static
mkdir -p sublications/{current,archive,uploaded}
touch sublications/{current,archive,uploaded}/.gitkeep

# .gitignoreの作成
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
venv/

# Project specific
sublications/current/*
!sublications/current/.gitkeep
sublications/archive/*
!sublications/archive/.gitkeep
sublications/uploaded/*
!sublications/uploaded/.gitkeep

# OS
.DS_Store
*.log
EOF

# requirements.txtの作成
cat > requirements.txt << 'EOF'
pillow
miniaudio
fastapi
uvicorn
python-multipart
EOF

# Kageの実装
mkdir -p src/kage
cat > src/kage/__init__.py << 'EOF'
from .graphics import Kage
EOF

cat > src/kage/graphics.py << 'EOF'
from PIL import Image, ImageDraw

class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        try:
            self.fb = open('/dev/fb0', 'wb')
        except:
            print("Warning: Framebuffer not available, running in test mode")
        
        self.buffer = Image.new('RGB', (self.width, self.height), 'black')
        self.draw = ImageDraw.Draw(self.buffer)
        self.current_color = (255, 255, 255)

    def clear(self, color=0):
        fill_color = 'black' if color == 0 else 'white'
        self.buffer.paste(fill_color, (0, 0, self.width, self.height))
        self.draw_buffer()

    def setColor(self, r, g, b):
        self.current_color = (r, g, b)

    def drawBox(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1], 
                          fill=self.current_color)
        self.draw_buffer()

    def draw_buffer(self):
        if hasattr(self, 'fb'):
            data = self.buffer.tobytes()
            rgb565_data = self._convert_rgb888_to_rgb565(data)
            self.fb.seek(0)
            self.fb.write(rgb565_data)
            self.fb.flush()

    def _convert_rgb888_to_rgb565(self, data):
        rgb565_data = bytearray(len(data) // 3 * 2)
        for i in range(0, len(data), 3):
            r = data[i]
            g = data[i+1]
            b = data[i+2]
            rgb = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
            rgb565_data[i//3*2] = rgb >> 8
            rgb565_data[i//3*2+1] = rgb & 0xFF
        return rgb565_data

    def __del__(self):
        if hasattr(self, 'fb'):
            self.fb.close()
EOF

# テスト用main.py
cat > main.py << 'EOF'
from src.kage import Kage
import time

def main():
    try:
        print("Initializing Kage...")
        kage = Kage()
        print("Kage initialized")

        # 基本的な描画テスト
        print("Starting display test...")
        
        # 画面クリア（黒）
        kage.clear(0)
        time.sleep(1)
        
        # 赤い四角形
        kage.setColor(255, 0, 0)
        kage.drawBox(10, 10, 50, 50)
        time.sleep(1)
        
        # 緑の四角形
        kage.setColor(0, 255, 0)
        kage.drawBox(70, 10, 50, 50)
        time.sleep(1)
        
        # 青の四角形
        kage.setColor(0, 0, 255)
        kage.drawBox(130, 10, 50, 50)
        
        print("Test completed. Press Ctrl+C to exit.")
        while True:
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\nTest terminated by user")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
EOF

echo "Project files created successfully!"