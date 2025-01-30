from src.kage import Kage
from src.kage.lua_binding import create_kage_env


def main():
    # Kageインスタンスの作成
    kage = Kage()

    # Lua環境の作成
    lua = create_kage_env(kage)

    # テストスクリプトの実行
    with open('scripts/tests/kage_test.lua', 'r') as f:
        lua.execute(f.read())


if __name__ == "__main__":
    main()
