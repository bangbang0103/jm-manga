"""JM 密码加密工具。

使用 Fernet + PBKDF2HMAC 对称加密，密钥来自环境变量
`JM_PASSWORD_ENCRYPTION_KEY`。未配置密钥时保持明文（向后兼容）。
"""

import base64
import os

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

_ENCRYPTION_PREFIX = "enc:"
_SALT_LENGTH = 16


def _derive_key(password: str, salt: bytes) -> bytes:
    """用 PBKDF2 从主密码派生 Fernet 密钥。"""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100_000,
    )
    return base64.urlsafe_b64encode(kdf.derive(password.encode()))


def encrypt_password(plaintext: str, master_key: str) -> str:
    """加密 JM 密码，返回带 enc: 前缀的字符串。"""
    salt = os.urandom(_SALT_LENGTH)
    fernet = Fernet(_derive_key(master_key, salt))
    token = fernet.encrypt(plaintext.encode())
    combined = salt + token
    return _ENCRYPTION_PREFIX + base64.urlsafe_b64encode(combined).decode()


def decrypt_password(ciphertext: str, master_key: str) -> str:
    """解密 JM 密码。若输入不是加密格式则原样返回。"""
    if not ciphertext.startswith(_ENCRYPTION_PREFIX):
        return ciphertext

    raw = base64.urlsafe_b64decode(ciphertext[len(_ENCRYPTION_PREFIX) :].encode())
    salt = raw[:_SALT_LENGTH]
    token = raw[_SALT_LENGTH:]
    fernet = Fernet(_derive_key(master_key, salt))
    return fernet.decrypt(token).decode()
