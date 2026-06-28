import json

from jm_server.crypto import (
    APP_DATA_SECRET,
    build_envelope,
    encrypt_response_data,
    extract_timestamp_from_tokenparam,
    md5_hex,
    secret_for_path,
)


def test_md5_hex():
    assert md5_hex("") == "d41d8cd98f00b204e9800998ecf8427e"


def test_extract_timestamp_from_tokenparam():
    assert extract_timestamp_from_tokenparam("1234567890,1.7.0") == 1234567890
    assert extract_timestamp_from_tokenparam("abc,1.0") is None
    assert extract_timestamp_from_tokenparam(None) is None


def test_secret_for_path():
    from jm_server.crypto import APP_TOKEN_SECRET_FOR_CONTENT

    assert secret_for_path("/chapter_view_template") == APP_TOKEN_SECRET_FOR_CONTENT
    assert secret_for_path("/album") == APP_DATA_SECRET


def test_encrypt_and_build_envelope():
    data = {"id": "123", "title": "Test"}
    timestamp = 1234567890
    envelope = build_envelope(data, timestamp, path="/album")
    assert envelope["code"] == 200
    assert "data" in envelope
    assert isinstance(envelope["data"], str)
