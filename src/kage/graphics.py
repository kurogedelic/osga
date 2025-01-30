from PIL import Image, ImageDraw, ImageFont
import math
import colorsys


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.fb = open('/dev/fb1', 'wb')
        self.buffer = Image.new('P', (self.width, self.height), 0)
        self.draw = ImageDraw.Draw(self.buffer)

        # 描画属性
        self.current_color = 0
        self.current_rgb = None  # 追加
        self.alpha = 1.0
        self.line_width = 1
        self.font_size = 2
        self.font_style = "normal"

        # パレットの定義
        self.palette = {
            'BLACK': 0,
            'WHITE': 1,
            'ORANGE': 2,
            'BLUE': 3,
            'GREEN': 4,
            'RED': 5,
        }

        # パレットの色をRGBで定義
        self.palette_colors = [
            (0, 0, 0),        # BLACK
            (255, 255, 255),  # WHITE
            (255, 165, 0),    # ORANGE
            (0, 0, 255),      # BLUE
            (0, 255, 0),      # GREEN
            (255, 0, 0),      # RED
        ]

        # フォント関連の初期化
        self.font_sizes = {
            1: 8,    # 小
            2: 16,   # 標準
            3: 24    # 大
        }

        self.buffer.putpalette(
            [c for color in self.palette_colors for c in color])
        self.current_color_index = 0  # デフォルトはBLACK

        try:
            self.font = ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Regular.otf",
                                           self.font_sizes[self.font_size])
        except:
            self.font = ImageFont.load_default()

    def get_current_color(self):
        if self.current_rgb:  # 優先度: 直接指定 > パレット
            return self.current_rgb
        color = self.colors.get(self.current_color, (0, 0, 0))
        if self.alpha < 1.0:
            return (*color, int(255 * self.alpha))
        return color

    # 基本操作
    def clear(self, color=0):
        self.buffer.paste(self.colors[color], (0, 0, self.width, self.height))

    def send_buffer(self):
        if hasattr(self, 'fb'):
            data = self.buffer.tobytes()
            rgb565_data = self._convert_rgb888_to_rgb565(data)
            self.fb.seek(0)
            self.fb.write(rgb565_data)
            self.fb.flush()

    def get_size(self):
        return self.width, self.height

    # 描画色設定
    def setColor(self, color_name):
        if color_name in self.palette:
            self.current_color_index = self.palette[color_name]
        else:
            print(
                f"Color '{color_name}' not found in palette. Using default color (BLACK).")
            self.current_color_index = self.palette['BLACK']

    def set_alpha(self, a):
        self.alpha = max(0.0, min(1.0, a))

    # 図形描画
    def draw_pixel(self, x, y):
        self.draw.point((x, y), fill=self.current_color_index)

    def draw_line(self, x1, y1, x2, y2, stroke=None):
        width = stroke if stroke is not None else self.line_width
        self.draw.line((x1, y1, x2, y2),
                       fill=self.current_color_index,
                       width=width)

    def draw_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            outline=self.current_color_index,
                            width=self.line_width)

    def fill_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            fill=self.current_color_index)

    def draw_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          outline=self.current_color_index,
                          width=self.line_width)

    def fill_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          fill=self.current_color_index)

    # 三角形描画

    def draw_triangle(self, x1, y1, x2, y2, x3, y3):
        points = [(x1, y1), (x2, y2), (x3, y3), (x1, y1)]
        self.draw.line(points,
                       fill=self.current_color_index,
                       width=self.line_width)

    def fill_triangle(self, x1, y1, x2, y2, x3, y3):
        points = [(x1, y1), (x2, y2), (x3, y3)]
        self.draw.polygon(points, fill=self.current_color_index)

    # ポリゴン描画
    def draw_polygon(self, points):
        if len(points) > 1:
            # 最後の点を最初の点につなぐ
            points_list = [(p[0], p[1]) for p in points]
            points_list.append(points_list[0])
            self.draw.line(points_list,
                           fill=self.current_color_index,
                           width=self.line_width)

    # テキスト描画関連
    def set_font_size(self, size):
        if size in self.font_sizes:
            self.font_size = size
            try:
                self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                               self.font_sizes[self.font_size])
            except:
                self.font = ImageFont.load_default()

    def set_font_style(self, style):
        self.font_style = style  # 現在は使用していない

    def draw_text(self, x, y, text):
        self.draw.text((x, y), str(text),
                       font=self.font,
                       fill=self.current_color_index)

    def text_size(self, text):
        bbox = self.draw.textbbox((0, 0), str(text), font=self.font)
        return bbox[2] - bbox[0], bbox[3] - bbox[1]

    # 高度な描画機能
    def draw_arc(self, x, y, r, start, stop):
        # 角度を度からラジアンに変換
        start_deg = math.degrees(start)
        stop_deg = math.degrees(stop)
        bbox = [x - r, y - r, x + r, y + r]
        self.draw.arc(bbox, start_deg, stop_deg,
                      fill=self.current_color_index,
                      width=self.line_width)

    def draw_ellipse(self, x, y, rx, ry):
        bbox = [x - rx, y - ry, x + rx, y + ry]
        self.draw.ellipse(bbox,
                          outline=self.current_color_index,
                          width=self.line_width)

    # 描画属性
    def set_line_width(self, width):
        self.line_width = max(1, int(width))
