import os
import stat

import pytest

from jm_manga_server.env_file import build_env_file, write_env_file


def test_build_env_file_contains_generated_deployment_defaults():
    content = build_env_file()

    assert "API_TOKEN=" in content
    assert "IMAGE_SIGN_SECRET=" in content
    assert "JM_PASSWORD_ENCRYPTION_KEY=" in content
    assert "NETWORK_MODE=public" in content
    assert "HOST=127.0.0.1" in content
    assert "DB_PATH=$HOME/.jm-manga/app.db" in content
    assert "CACHE_DIR=$HOME/.jm-manga/cache" in content
    assert "HTTP_USERNAME" not in content
    assert "HTTP_PASSWORD" not in content
    assert "JM_USERNAME" not in content
    assert "JM_PASSWORD=" not in content


def test_write_env_file_refuses_to_overwrite(tmp_path):
    env_path = tmp_path / ".env"
    env_path.write_text("API_TOKEN=existing\n", encoding="utf-8")

    with pytest.raises(FileExistsError):
        write_env_file(env_path)

    assert env_path.read_text(encoding="utf-8") == "API_TOKEN=existing\n"


def test_write_env_file_can_force_overwrite_and_sets_private_permissions(tmp_path):
    env_path = tmp_path / ".env"
    env_path.write_text("API_TOKEN=existing\n", encoding="utf-8")

    result = write_env_file(env_path, force=True)

    assert result == env_path
    assert "NETWORK_MODE=public" in env_path.read_text(encoding="utf-8")
    if os.name == "posix":
        assert stat.S_IMODE(env_path.stat().st_mode) == 0o600
