"""Tests for jm_server.client cookie isolation and resource lifecycle."""

from unittest.mock import MagicMock, patch

import pytest

from jm_server.client import JmServerClient, _parse_cookie_header
from jm_server.config import ServerConfig


def async_return_value(value=None):
    """Return an awaitable that resolves to *value*."""
    async def _coro():
        return value
    return _coro()


def test_parse_cookie_header_splits_pairs():
    assert _parse_cookie_header("AVS=1; KEY=2") == {"AVS": "1", "KEY": "2"}


def test_parse_cookie_header_ignores_invalid_and_empty():
    assert _parse_cookie_header("AVS=1; badpair; ; KEY=2") == {
        "AVS": "1",
        "KEY": "2",
    }


def test_parse_cookie_header_none_returns_empty():
    assert _parse_cookie_header(None) == {}


@pytest.fixture
def client():
    return JmServerClient(ServerConfig())


@pytest.mark.asyncio
async def test_new_api_client_deepcopies_option_and_injects_cookies(client):
    option_mock = MagicMock()
    option_mock.client.postman.meta_data.src_dict = {}
    client._option = option_mock

    with patch("jm_server.client.copy.deepcopy") as deepcopy_mock:
        per_request_option = MagicMock()
        deepcopy_mock.return_value = per_request_option

        jm_client_mock = MagicMock()
        per_request_option.new_jm_async_client.return_value = jm_client_mock

        new_client = client._new_api_client("AVS=session-a")

        deepcopy_mock.assert_called_once_with(option_mock)
        per_request_option.update_cookies.assert_called_once_with(
            {"AVS": "session-a"}
        )
        assert new_client is jm_client_mock


@pytest.mark.asyncio
async def test_api_request_creates_isolated_client_per_call(client):
    option_mock = MagicMock()
    option_mock.client.postman.meta_data.src_dict = {}
    client._option = option_mock

    calls = []

    def make_mock_option(cookies):
        opt = MagicMock()
        jm = MagicMock()
        jm.req_api = MagicMock(return_value=async_return_value())
        jm.close = MagicMock(return_value=async_return_value())
        opt.new_jm_async_client.return_value = jm
        calls.append(cookies)
        return opt

    with patch("jm_server.client.copy.deepcopy") as deepcopy_mock:
        deepcopy_mock.side_effect = [
            make_mock_option("first"),
            make_mock_option("second"),
        ]

        await client.api_request(
            "GET", "/search", {"q": "a"}, None, "AVS=first"
        )
        await client.api_request(
            "GET", "/search", {"q": "b"}, None, "AVS=second"
        )

    assert len(calls) == 2
    # Each call created a fresh option/client.
    assert deepcopy_mock.call_count == 2
