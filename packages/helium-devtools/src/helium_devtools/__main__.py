from helium_devtools.config import Config
from helium_devtools.server import serve
import asyncio


def main() -> None:
    cfg = Config.from_env()
    asyncio.run(serve(cfg))


if __name__ == "__main__":
    main()
