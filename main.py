# main.py 全修正
from src.kage import Kage
import time


def main():
    try:
        print("Initializing Kage...")
        kage = Kage()
        print("Kage initialized")

        # カラーパレット定義 (RGB順)
        palette = [
            (0, 0, 0),        # 0: 黒
            (255, 255, 255),  # 1: 白
            (255, 0, 0),      # 2: 赤
            (0, 255, 0),      # 3: 緑
            (0, 0, 255),      # 4: 青
            (255, 255, 0),    # 5: 黄
            (0, 255, 255),    # 6: シアン
            (255, 0, 255)     # 7: マゼンタ
        ]

        print("Starting palette test...")
        kage.clear(0)
        time.sleep(1)

        # パレットを横並びで表示
        start_x = 10
        square_size = 40
        spacing = 10

        for idx, color in enumerate(palette):
            x = start_x + (square_size + spacing) * idx
            kage.set_color_rgb(*color)
            kage.fill_rect(x, 100, square_size, square_size)
            kage.send_buffer()
            time.sleep(0.3)

        print("Test completed. Press Ctrl+C to exit.")
        while True:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest terminated by user")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
