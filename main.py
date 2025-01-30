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
