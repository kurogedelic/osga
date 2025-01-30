# run_kage_test.py
from src.kage import Kage
from src.kage.lua_binding import KageLuaEngine


def main():
    kage = Kage()
    engine = KageLuaEngine(kage)
    engine.load_script('scripts/tests/kage_test.lua')
    engine.run()


if __name__ == "__main__":
    main()
