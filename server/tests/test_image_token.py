import time

from jm_manga_server.routers.images import generate_image_token, verify_image_token


def test_generate_and_verify_token():
    """生成的图片 token 应在有效期内可校验。"""
    token = generate_image_token("photo_1", 3, 3600, "secret")
    assert verify_image_token(token, "photo_1", 3, "secret") is True


def test_token_fails_with_wrong_params():
    """photo_id 或 image_index 不匹配时应校验失败。"""
    token = generate_image_token("photo_1", 3, 3600, "secret")
    assert verify_image_token(token, "photo_2", 3, "secret") is False
    assert verify_image_token(token, "photo_1", 4, "secret") is False


def test_token_fails_when_expired():
    """过期 token 应校验失败。"""
    token = generate_image_token("photo_1", 3, -1, "secret")
    time.sleep(0.1)
    assert verify_image_token(token, "photo_1", 3, "secret") is False
