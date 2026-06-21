import argparse

import uvicorn

from jm_manga_server.config import Settings
from jm_manga_server.env_file import write_env_file
from jm_manga_server.main import app


def main(argv: list[str] | None = None):
    parser = argparse.ArgumentParser(prog="jm-manga-server")
    subparsers = parser.add_subparsers(dest="command")

    init_env = subparsers.add_parser("init-env", help="Generate a new .env file")
    init_env.add_argument(
        "--path",
        default=".env",
        help="Path to write. Defaults to .env in the current directory.",
    )
    init_env.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the file if it already exists.",
    )

    args = parser.parse_args(argv)
    if args.command == "init-env":
        path = write_env_file(args.path, force=args.force)
        print(f"Generated {path}")
        return

    settings = Settings()
    uvicorn.run(app, host=settings.host, port=settings.port)


if __name__ == "__main__":
    main()
