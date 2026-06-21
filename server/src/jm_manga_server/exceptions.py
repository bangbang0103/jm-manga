"""统一异常类与全局异常响应格式。

所有对外暴露的 HTTP 错误均通过本模块的异常子类抛出，
由 ``main.py`` 注册的全局处理器统一转换为 ``{code, message}`` JSON。
"""

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse


class ApiError(HTTPException):
    """应用统一的业务异常基类。"""

    default_message = "Internal server error"

    def __init__(self, detail: str | None = None):
        super().__init__(
            status_code=self.status_code,
            detail=detail or self.default_message,
        )


class BadRequestError(ApiError):
    """400 Bad Request"""

    status_code = status.HTTP_400_BAD_REQUEST
    default_message = "Bad request"


class UnauthorizedError(ApiError):
    """401 Unauthorized"""

    status_code = status.HTTP_401_UNAUTHORIZED
    default_message = "Unauthorized"


class ForbiddenError(ApiError):
    """403 Forbidden"""

    status_code = status.HTTP_403_FORBIDDEN
    default_message = "Forbidden"


class UnprocessableEntityError(ApiError):
    """422 Unprocessable Content"""

    status_code = status.HTTP_422_UNPROCESSABLE_CONTENT
    default_message = "Unprocessable content"


class InternalServerError(ApiError):
    """500 Internal Server Error"""

    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_message = "Internal server error"


class BadGatewayError(ApiError):
    """502 Bad Gateway：下游服务（如 JM）不可用。"""

    status_code = status.HTTP_502_BAD_GATEWAY
    default_message = "Upstream service unavailable"


class ServiceUnavailableError(ApiError):
    """503 Service Unavailable"""

    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_message = "Service unavailable"


def make_error_response(status_code: int, message: str) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={"code": "ERROR", "message": message},
    )


async def api_error_handler(request: Request, exc: ApiError) -> JSONResponse:
    """处理所有 ApiError 子类。"""
    return make_error_response(exc.status_code, exc.detail)


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """兜底 FastAPI 原生 HTTPException，统一响应格式。"""
    return make_error_response(exc.status_code, exc.detail)
