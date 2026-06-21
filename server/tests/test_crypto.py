from jm_manga_server.crypto import decrypt_password, encrypt_password


def test_encrypt_decrypt_roundtrip():
    """加密后再解密应得到原文。"""
    plaintext = "my_secret_password"
    key = "super_secret_master_key"
    ciphertext = encrypt_password(plaintext, key)
    assert ciphertext != plaintext
    assert ciphertext.startswith("enc:")
    decrypted = decrypt_password(ciphertext, key)
    assert decrypted == plaintext


def test_decrypt_plaintext_returns_unchanged():
    """非加密格式字符串应原样返回（向后兼容）。"""
    assert decrypt_password("plain_password", "any_key") == "plain_password"


def test_different_keys_produce_different_ciphertext():
    """同一密码用不同密钥加密应得到不同密文。"""
    plaintext = "password"
    ciphertext_a = encrypt_password(plaintext, "key_a")
    ciphertext_b = encrypt_password(plaintext, "key_b")
    assert ciphertext_a != ciphertext_b


def test_decrypt_with_wrong_key_fails():
    """用错误密钥解密应抛出异常。"""
    ciphertext = encrypt_password("password", "correct_key")
    try:
        decrypt_password(ciphertext, "wrong_key")
    except Exception:
        return
    raise AssertionError("Decrypt with wrong key should fail")
