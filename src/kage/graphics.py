# src/kage/graphics.py
from PIL import Image, ImageDraw, ImageFont
import configparser
import time


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.config = self._load_config()

        # フレームバッファの設定
        try:
            self.fb = open('/dev/fb1', 'wb')
        except Exception as e:
            print(f"Warning: Could not open framebuffer: {e}")

        # バッファとカラー設定
        self.buffer = Image.new('RGB', (self.width, self.height), 'black')
        self.draw = ImageDraw.Draw(self.buffer)
        self.last_frame_time = time.time()
        self.frame_interval = 1.0 / self.config.getint('display', 'frame_rate')

        # フォント設定
        self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                       self.config.getint('display', 'font_size'))

    def _load_config(self):
        config = configparser.ConfigParser()
        config.read('src/kage/config.ini')
        return config

    def _wait_for_frame(self):
        current_time = time.time()
        wait_time = self.frame_interval - (current_time - self.last_frame_time)
        if wait_time > 0:
            time.sleep(wait_time)
        self.last_frame_time = time.time()

    def clear(self):
        self.buffer.paste('black', (0, 0, self.width, self.height))
        self.draw_buffer()

    def draw_buffer(self):
        if hasattr(self, 'fb'):
            data = self.buffer.tobytes()
            rgb565_data = self._convert_rgb888_to_rgb565(data)
            self.fb.seek(0)
            self.fb.write(rgb565_data)
            self.fb.flush()
        self._wait_for_frame()

    def draw_square(self, x, y, size, is_primary=False):
        color = self.config.get(
            'colors', 'primary_color' if is_primary else 'base_color')
        self.draw.rectangle([x, y, x + size - 1, y + size - 1], fill=color)

    def draw_text(self, text, x=None, y=None, center=False):
        color = self.config.get('colors', 'base_color')
        if center:
            bbox = self.draw.textbbox((0, 0), text, font=self.font)
            x = (self.width - (bbox[2] - bbox[0])) // 2
            y = (self.height - (bbox[3] - bbox[1])) // 2
        self.draw.text((x, y), text, font=self.font, fill=color)
