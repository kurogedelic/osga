from PIL import Image, ImageDraw


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        try:
            self.fb = open('/dev/fb1', 'wb')  # fb0ではなくfb1を使用
        except:
            print("Warning: Secondary framebuffer not available, running in test mode")

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
