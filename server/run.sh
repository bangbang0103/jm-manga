#!/bin/bash
set -e

cd "$(dirname "$0")"

# Ensure dependencies are installed.
uv sync

# Start the server.
exec uv run uvicorn jm_server.main:app --host "${JM_SERVER_HOST:-0.0.0.0}" --port "${JM_SERVER_PORT:-8080}"
