FROM python:3.9-slim

WORKDIR /app

RUN apt-get update --fix-missing && apt-get install -y --no-install-recommends \
    gcc \
    libc-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/main.py .

# Sensor/LCD hardware access is granted via explicit device mounts in
# docker-compose.yml (i2c-1, gpiomem) plus `group_add` there, matching this
# host's actual i2c/gpio group GIDs (they vary by OS image, so they aren't
# baked in here) - no privileged mode needed.
RUN useradd -m -u 1000 appuser
USER appuser

HEALTHCHECK --interval=60s --timeout=5s --start-period=30s --retries=3 \
    CMD pgrep -f "python -u main.py" || exit 1

CMD ["python", "-u", "main.py"]
