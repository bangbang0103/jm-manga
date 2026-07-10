"""Probe JM /forum comment API for a single album.

Reference: jmcomic-qt/src/server/req.py::GetCommentReq2
"""

from __future__ import annotations

import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path
from time import sleep

from jmcomic import JmCryptoTool, JmOption

ALBUM_ID = "1215913"
SLEEP_SECONDS = 4.0

# Modes observed in jmcomic-qt comment_widget.py
MODES = ["manhua", "all", "chat"]
PAGES = [1, 2]


def _now() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def _shorten(value, limit: int = 60) -> str:
    if value is None:
        return "<null>"
    text = str(value).replace("\n", " ")
    if len(text) > limit:
        return text[:limit] + "…"
    return text


def _extract_fields(item: dict) -> dict:
    """Pull fields relevant to the Flutter/Dart model mapping."""
    exp = item.get("expinfo") or {}
    return {
        "CID": item.get("CID"),
        "UID": item.get("UID"),
        "username": item.get("username"),
        "level": exp.get("level"),
        "level_name": exp.get("level_name"),
        "content": _shorten(item.get("content")),
        "likes": item.get("likes"),
        "addtime": item.get("addtime"),
        "photo": item.get("photo"),
        "reply_count": len(item.get("replys", [])),
    }


async def probe() -> dict:
    option = JmOption.default()
    client = option.new_jm_async_client()
    try:
        results = []
        for mode in MODES:
            for page in PAGES:
                params = {"mode": mode, "aid": ALBUM_ID, "page": str(page)}
                try:
                    resp = await client.req_api(
                        "/forum",
                        get=True,
                        require_success=False,
                        params=params,
                    )
                    envelope = resp.json()
                    code = envelope.get("code", resp.http_code)
                    if code != 200:
                        results.append({
                            "mode": mode,
                            "page": page,
                            "http_code": resp.http_code,
                            "code": code,
                            "error": envelope.get("errorMsg") or envelope.get("message"),
                            "data": None,
                        })
                        continue

                    decoded = JmCryptoTool.decode_resp_data(
                        resp.encoded_data, resp.ts
                    )
                    data = json.loads(decoded)
                    comments = data.get("list", [])
                    results.append({
                        "mode": mode,
                        "page": page,
                        "http_code": resp.http_code,
                        "code": code,
                        "total": data.get("total"),
                        "count": len(comments),
                        "first_two_fields": [_extract_fields(c) for c in comments[:2]],
                        "all_keys": sorted(data.keys()),
                        "sample_raw_keys": sorted(comments[0].keys()) if comments else [],
                        "error": None,
                    })
                except Exception as exc:
                    results.append({
                        "mode": mode,
                        "page": page,
                        "http_code": None,
                        "code": None,
                        "error": f"{type(exc).__name__}: {exc}",
                        "data": None,
                    })
                if not (mode == MODES[-1] and page == PAGES[-1]):
                    sleep(SLEEP_SECONDS)
        return {"album_id": ALBUM_ID, "probed_at": _now(), "jmcomic_version": "2.7.0", "results": results}
    finally:
        await client.close()


if __name__ == "__main__":
    out_dir = Path(__file__).parent
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "comment_probe_raw.json"

    report = asyncio.run(probe())
    out_file.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Probe finished. Raw report written to {out_file}")
    print(json.dumps(report, ensure_ascii=False, indent=2))
