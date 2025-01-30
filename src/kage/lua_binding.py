# src/kage/lua_binding.py
class KageLuaEngine:
    def setup_api(self):
        g = self.lua.globals()

        # トップレベルAPI
        g.print = print

        # Kage APIテーブル
        kage_api = {
            # 基本操作
            'clear': self.kage.clear,
            'sendBuffer': self.kage.send_buffer,
            'getSize': self.kage.get_size,

            # 描画色設定
            'setColor': self.kage.set_color,
            'setAlpha': self.kage.set_alpha,

            # 図形描画
            'drawPixel': self.kage.draw_pixel,
            'drawLine': self.kage.draw_line,
            'drawRect': self.kage.draw_rect,
            'fillRect': self.kage.fill_rect,
            'drawCircle': self.kage.draw_circle,
            'fillCircle': self.kage.fill_circle,
            'drawTriangle': self.kage.draw_triangle,
            'fillTriangle': self.kage.fill_triangle,
            'drawPolygon': self.kage.draw_polygon,

            # テキスト描画
            'setFontSize': self.kage.set_font_size,
            'setFontStyle': self.kage.set_font_style,
            'drawText': self.kage.draw_text,
            'textSize': self.kage.text_size,

            # 高度な描画
            'drawArc': self.kage.draw_arc,
            'drawEllipse': self.kage.draw_ellipse,

            # 描画属性
            'setLineWidth': self.kage.set_line_width,
        }
        g.kage = kage_api
