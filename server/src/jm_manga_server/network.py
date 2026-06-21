"""网络模式解析：根据 HOST 与 NETWORK_MODE 推断服务暴露范围。"""

import ipaddress
import logging
import socket
from typing import Literal

from jm_manga_server.config import Settings

logger = logging.getLogger(__name__)


def _is_loopback_or_link_local(addr: str) -> bool:
    """判断地址是否为回环或链路本地。"""
    try:
        ip = ipaddress.ip_address(addr)
        return ip.is_loopback or ip.is_link_local
    except ValueError:
        return addr.lower() in ("localhost",)


def _is_private_ip(addr: str) -> bool:
    """判断地址是否为 RFC1918 私网地址。"""
    try:
        ip = ipaddress.ip_address(addr)
        return ip.is_private
    except ValueError:
        return False


def _get_host_ips(host: str) -> set[str]:
    """将 host 解析为一组 IP 字符串。

    特殊值直接返回，避免 DNS 查询。
    """
    if host in ("0.0.0.0", ""):
        return {"0.0.0.0"}
    if host in ("localhost", "127.0.0.1"):
        return {"127.0.0.1"}
    try:
        info = socket.getaddrinfo(host, None)
        return {item[4][0] for item in info}
    except socket.gaierror:
        return {host}


def _host_is_public(host: str) -> bool:
    """判断 host 是否会被公网可路由地址暴露。

    规则：
    - 0.0.0.0 视为公网（会监听所有接口）。
    - 任何解析到的非回环/非链路本地/非私网地址视为公网。
    - 无法解析的 host 保守地视为公网（fail-closed）。
    """
    if host == "0.0.0.0":
        return True

    for ip_str in _get_host_ips(host):
        if ip_str == "0.0.0.0":
            return True
        try:
            ip = ipaddress.ip_address(ip_str)
            if not (ip.is_loopback or ip.is_link_local or ip.is_private):
                return True
        except ValueError:
            logger.debug("Could not parse host %r as IP; treating as public", host)
            return True
    return False


def resolve_network_mode(settings: Settings) -> Literal["lan", "public"]:
    """根据 settings 解析出实际的网络模式。

    - NETWORK_MODE=lan|public：直接采用。
    - NETWORK_MODE=auto（默认）：根据 HOST 推断。
    - 其他值：抛出 ValueError。
    """
    mode = (settings.network_mode or "auto").lower()
    if mode == "lan":
        return "lan"
    if mode == "public":
        return "public"
    if mode == "auto":
        return "lan" if not _host_is_public(settings.host) else "public"
    raise ValueError(f"Invalid NETWORK_MODE: {settings.network_mode!r}")


def validate_network_settings(settings: Settings) -> Literal["lan", "public"]:
    """启动时校验网络模式与相关安全配置。

    返回实际生效的网络模式。
    """
    mode = resolve_network_mode(settings)

    if mode == "public":
        if not settings.api_token:
            raise RuntimeError(
                "Public network mode requires a non-empty API_TOKEN. "
                "Set API_TOKEN or switch to NETWORK_MODE=lan."
            )
        if not settings.image_sign_secret:
            raise RuntimeError(
                "Public network mode requires a non-empty IMAGE_SIGN_SECRET. "
                "Set IMAGE_SIGN_SECRET or switch to NETWORK_MODE=lan."
            )
        # 公网模式下强制关闭 mDNS
        settings.mdns_enabled = False
    else:
        if not settings.api_token:
            logger.warning(
                "NETWORK_MODE=%s and API_TOKEN is empty; "
                "service is reachable by any device on the same network.",
                mode,
            )

    return mode
