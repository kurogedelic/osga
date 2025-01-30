# main.py
import time
from src.kage import Kage
from scripts.system.splash import Splash  # splash.py から Splash クラスをインポート


def main():
    try:
        print("Initializing Kage...")
        kage = Kage()
        print("Kage initialized")

        # Splash クラスのインスタンスを作成して表示
        splash = Splash(kage)
        splash.show()

        print("Test completed. Press Ctrl+C to exit.")
        while True:
            time.sleep(0.1)

    except KeyboardInterrupt:
        print("\nTest terminated by user")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
