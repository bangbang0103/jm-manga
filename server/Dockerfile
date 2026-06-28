FROM python:3.12-slim-bookworm

WORKDIR /app

# Install system dependencies that may be needed by curl_cffi / Pillow.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install a pinned uv version for reproducible builds.
ARG UV_VERSION=0.11.3
ADD https://astral.sh/uv/${UV_VERSION}/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy project metadata and the lockfile first for better layer caching.
COPY pyproject.toml uv.lock /app/
COPY src /app/src

# Install dependencies using the lockfile. Fail if the lockfile is out of sync.
RUN uv sync --locked --no-dev

# Create cache directory.
RUN mkdir -p /app/cache/images

EXPOSE 8080

ENV PYTHONUNBUFFERED=1
ENV JM_SERVER_IMAGE_CACHE_DIR=/app/cache/images

CMD ["uv", "run", "--no-dev", "uvicorn", "jm_server.main:app", "--host", "0.0.0.0", "--port", "8080"]
