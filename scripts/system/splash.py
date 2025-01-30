# scripts/system/splash.py
import time
from src.kage import Kage


class Splash:
    def __init__(self, kage):
        self.kage = kage

    def show(self):
        try:
            # 画面を黒でクリア
            self.kage.clear(0)

            # 白丸を画面中央から拡大して表示
            self.kage.set_color(1)
            for radius in range(0, 101, 5):  # 0から100まで5ずつ拡大
                self.kage.clear(0)
                self.kage.fill_circle(160, 120, radius)
                self.kage.send_buffer()
                time.sleep(0.01)  # アニメーション速度調整

            # テキストを左端からスクロールして表示
            self.kage.set_font_size(3)
            self.kage.set_color(0)
            for x in range(-100, 101, 5):  # 左端から中央まで移動
                self.kage.clear(0)
                self.kage.fill_circle(160, 120, 100)
                self.kage.draw_text(160 + x, 100, "osga")
                self.kage.send_buffer()
                time.sleep(0.01)  # アニメーション速度調整

            # 0.5秒待機
            time.sleep(0.5)

            # テキストを消す
            self.kage.clear(0)
            self.kage.fill_circle(160, 120, 100)
            self.kage.send_buffer()

            # 白丸を画面いっぱいに拡大
            for radius in range(100, 241, 5):  # 100から240まで拡大
                self.kage.clear(0)
                self.kage.fill_circle(160, 120, radius)
                self.kage.send_buffer()
                time.sleep(0.01)  # アニメーション速度調整

        except Exception as e:
            print(f"Error in Splash: {e}")
