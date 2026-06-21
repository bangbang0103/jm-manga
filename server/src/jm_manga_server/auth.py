import secrets

from fastapi import Depends, HTTPException, Request
from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)

security_bearer = HTTPBearer(auto_error=False)


async def verify_api_token(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(security_bearer),
):
    """校验 API Token；未配置时跳过校验。"""
    settings = request.app.state.settings
    token = settings.api_token

    if not token:
        return True

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Missing or invalid authorization")

    if not secrets.compare_digest(credentials.credentials, token):
        raise HTTPException(status_code=403, detail="Invalid API token")

    return True


async def verify_auth(
    request: Request,
    _api: bool = Depends(verify_api_token),
):
    """组合校验入口：当前使用 API Token。"""
    return True
