"""创建 jmcomic 客户端。macOS 上 curl_cffi 可能遇到 TLS 库冲突，默认使用 openssl backend。"""

import os
import sys

if sys.platform == "darwin":
    os.environ.setdefault("CURL_SSL_BACKEND", "openssl")

import jmcomic

from jm_manga_server.config import Settings


def create_jm_client(settings: Settings):
    """创建 jmcomic 异步客户端。"""
    option = jmcomic.JmOption.default()

    if settings.client_impl == "api":
        client = jmcomic.AsyncJmApiClient(option)
    else:
        client = jmcomic.AsyncJmcomicClient(option)

    if settings.jm_domain_list:
        client.set_domain_list(settings.jm_domain_list.split(","))

    return client
