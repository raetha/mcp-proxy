# Build stage with explicit platform specification
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS uv

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Final stage with explicit platform specification
#FROM python:3.12-alpine
FROM docker.io/nikolaik/python-nodejs:python3.12-nodejs22-alpine

COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Add uv to image
RUN python3 -m ensurepip && pip install --no-cache-dir uv

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:/usr/local/bin:$PATH" \
    UV_PYTHON_PREFERENCE="only-system"

ENTRYPOINT ["mcp-proxy"]
