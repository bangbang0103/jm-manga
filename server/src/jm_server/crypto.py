"""AES encryption helpers to re-seal JM API responses for the Flutter client."""

from __future__ import annotations

import base64
import hashlib
import json
from typing import Any

from Crypto.Cipher import AES

# Mirror of JmConstants.appDataSecret and the scramble-specific secret.
APP_DATA_SECRET = "185Hcomic3PAPP7R"
APP_TOKEN_SECRET_FOR_CONTENT = "18comicAPPContent"


def md5_hex(value: str) -> str:
    return hashlib.md5(value.encode("utf-8")).hexdigest()


def _pad_pkcs7(data: bytes, block_size: int = 16) -> bytes:
    padding_len = block_size - (len(data) % block_size)
    return data + bytes([padding_len] * padding_len)


def encrypt_response_data(data: str, timestamp: int, secret: str = APP_DATA_SECRET) -> str:
    """Encrypt a JSON string the same way JM API encrypts its 'data' field.

    The key is md5(f'{timestamp}{secret}') and the cipher is AES-256-ECB
    with PKCS#7 padding, finally base64-encoded.
    """
    key = md5_hex(f"{timestamp}{secret}").encode("utf-8")
    padded = _pad_pkcs7(data.encode("utf-8"))
    cipher = AES.new(key, AES.MODE_ECB)
    encrypted = cipher.encrypt(padded)
    return base64.b64encode(encrypted).decode("utf-8")


def extract_timestamp_from_tokenparam(tokenparam: str | None) -> int | None:
    """Parse '1234567890,1.7.0' -> 1234567890."""
    if not tokenparam:
        return None
    parts = tokenparam.split(",")
    if not parts:
        return None
    try:
        return int(parts[0])
    except ValueError:
        return None


def secret_for_path(path: str) -> str:
    """Return the JM secret used to encrypt the response body for a path."""
    if path == "/chapter_view_template":
        return APP_TOKEN_SECRET_FOR_CONTENT
    return APP_DATA_SECRET


def build_envelope(
    data: dict[str, Any] | list[Any],
    timestamp: int,
    path: str = "/",
) -> dict[str, Any]:
    """Wrap decrypted data into the official JM envelope using Flutter's timestamp."""
    encoded = encrypt_response_data(json.dumps(data, ensure_ascii=False), timestamp, secret_for_path(path))
    return {
        "code": 200,
        "data": encoded,
    }


def decode_jm_response(resp: Any, path: str = "/") -> Any:
    """Decode a JM API response, tolerating pre-decrypted or non-standard payloads.

    Some JM endpoints return data as an already-decoded list/dict instead of an
    encrypted string. This helper handles both cases.
    """
    envelope = resp.json()
    code = envelope.get("code", 200)
    if code != 200:
        message = envelope.get("errorMsg") or envelope.get("message") or "JM API error"
        raise RuntimeError(f"JM API error: code={code}, message={message}")

    encoded_data = envelope.get("data")
    if encoded_data is None:
        return {}

    if not isinstance(encoded_data, str):
        return encoded_data

    ts = getattr(resp, "ts", None)
    secret = APP_TOKEN_SECRET_FOR_CONTENT if path == "/chapter_view_template" else APP_DATA_SECRET
    decoded = decode_resp_data(encoded_data, ts, secret=secret)
    return json.loads(decoded)


def decode_resp_data(data: str, ts, secret: str = APP_DATA_SECRET) -> str:
    """Thin wrapper around jmcomic's response decryption."""
    from jmcomic import JmCryptoTool

    return JmCryptoTool.decode_resp_data(data, ts, secret=secret)
