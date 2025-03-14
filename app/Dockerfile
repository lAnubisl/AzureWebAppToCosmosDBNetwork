FROM python:3.13.2-alpine3.21 AS base
ARG buildHash
WORKDIR /app

ENV BUILD_HASH=$buildHash

RUN apk add --no-cache curl
COPY requirements.txt .
RUN adduser --disabled-password appuser && \
    chown -R appuser:appuser /app
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

FROM base AS final
COPY src .
USER appuser
EXPOSE 80
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:80/health/$BUILD_HASH || exit 1
