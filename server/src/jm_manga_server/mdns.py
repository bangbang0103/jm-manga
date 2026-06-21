import logging
import socket

import ifaddr
from zeroconf import IPVersion, ServiceInfo
from zeroconf.asyncio import AsyncZeroconf

from .version import VERSION

logger = logging.getLogger(__name__)
SERVICE_TYPE = "_http._tcp.local."
SERVICE_NAME_TEMPLATE = "JM Manga-Server {}"


def _get_local_ips() -> list[str]:
    """获取本机非回环 IPv4 地址，用于 mDNS 广播。"""
    ips: list[str] = []
    try:
        for adapter in ifaddr.get_adapters():
            for ip in adapter.ips:
                if not isinstance(ip.ip, str):
                    continue
                if ip.ip.startswith("127.") or ip.ip == "0.0.0.0":
                    continue
                if ":" in ip.ip:
                    # 简单跳过 IPv6
                    continue
                ips.append(ip.ip)
    except Exception:
        logger.exception("Failed to enumerate local interfaces")
    if not ips:
        ips.append("127.0.0.1")
    return ips


class MdnsAdvertiser:
    """在局域网中广播 MangaWave 后端服务。"""

    def __init__(self, port: int):
        self.port = port
        self.zeroconf: AsyncZeroconf | None = None
        self.service_info: ServiceInfo | None = None

    def _get_hostname(self) -> str:
        return socket.gethostname().split(".")[0]

    async def start(self) -> None:
        hostname = self._get_hostname()
        service_name = SERVICE_NAME_TEMPLATE.format(hostname)
        local_ips = _get_local_ips()

        desc = {"version": VERSION, "path": "/"}
        self.service_info = ServiceInfo(
            type_=SERVICE_TYPE,
            name=f"{service_name}.{SERVICE_TYPE}",
            addresses=[socket.inet_aton(ip) for ip in local_ips],
            port=self.port,
            properties=desc,
            server=f"{hostname}.local.",
        )

        try:
            self.zeroconf = AsyncZeroconf(ip_version=IPVersion.V4Only)
            await self.zeroconf.async_register_service(self.service_info)
            logger.info("mDNS service advertised at %s:%s", local_ips, self.port)
        except Exception as e:
            logger.warning("Failed to start mDNS advertiser: %s", e, exc_info=True)
            if self.zeroconf is not None:
                await self.zeroconf.async_close()
            self.zeroconf = None
            self.service_info = None

    async def stop(self) -> None:
        if self.zeroconf and self.service_info:
            try:
                await self.zeroconf.async_unregister_service(self.service_info)
                await self.zeroconf.async_close()
            except Exception as e:
                logger.warning("Failed to stop mDNS advertiser: %s", e)
            self.zeroconf = None
            self.service_info = None
