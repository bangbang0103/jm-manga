import pytest

from jm_manga_server.config import Settings
from jm_manga_server.network import resolve_network_mode, validate_network_settings


class TestResolveNetworkMode:
    """测试网络模式解析。"""

    def test_explicit_lan(self):
        settings = Settings(network_mode="lan", host="0.0.0.0")
        assert resolve_network_mode(settings) == "lan"

    def test_explicit_public(self):
        settings = Settings(network_mode="public", host="127.0.0.1")
        assert resolve_network_mode(settings) == "public"

    def test_auto_with_loopback_is_lan(self):
        settings = Settings(network_mode="auto", host="127.0.0.1")
        assert resolve_network_mode(settings) == "lan"

    def test_auto_with_localhost_is_lan(self):
        settings = Settings(network_mode="auto", host="localhost")
        assert resolve_network_mode(settings) == "lan"

    def test_auto_with_private_ip_is_lan(self):
        settings = Settings(network_mode="auto", host="192.168.1.10")
        assert resolve_network_mode(settings) == "lan"

    @pytest.mark.parametrize("host", ["0.0.0.0", "8.8.8.8", "1.1.1.1"])
    def test_auto_with_public_binding_is_public(self, host):
        settings = Settings(network_mode="auto", host=host)
        assert resolve_network_mode(settings) == "public"

    def test_invalid_network_mode_raises(self):
        settings = Settings(network_mode="invalid")
        with pytest.raises(ValueError):
            resolve_network_mode(settings)


class TestValidateNetworkSettings:
    """测试启动时网络设置校验。"""

    def test_public_without_api_token_raises(self):
        settings = Settings(
            network_mode="public",
            api_token=None,
            image_sign_secret="img_secret",
        )
        with pytest.raises(RuntimeError, match="API_TOKEN"):
            validate_network_settings(settings)

    def test_public_without_image_sign_secret_raises(self):
        settings = Settings(
            network_mode="public",
            api_token="api_secret",
            image_sign_secret=None,
        )
        with pytest.raises(RuntimeError, match="IMAGE_SIGN_SECRET"):
            validate_network_settings(settings)

    def test_public_with_credentials_disables_mdns(self):
        settings = Settings(
            network_mode="public",
            api_token="api_secret",
            image_sign_secret="img_secret",
            mdns_enabled=True,
        )
        mode = validate_network_settings(settings)
        assert mode == "public"
        assert settings.mdns_enabled is False

    def test_lan_without_api_token_allows_and_keeps_mdns(self):
        settings = Settings(
            network_mode="lan",
            api_token=None,
            image_sign_secret=None,
            mdns_enabled=True,
        )
        mode = validate_network_settings(settings)
        assert mode == "lan"
        assert settings.mdns_enabled is True

    def test_auto_public_host_without_token_raises(self):
        settings = Settings(
            network_mode="auto",
            host="0.0.0.0",
            api_token=None,
            image_sign_secret=None,
        )
        with pytest.raises(RuntimeError, match="API_TOKEN"):
            validate_network_settings(settings)

    def test_auto_lan_host_without_token_allows(self):
        settings = Settings(
            network_mode="auto",
            host="127.0.0.1",
            api_token=None,
            image_sign_secret=None,
        )
        mode = validate_network_settings(settings)
        assert mode == "lan"
