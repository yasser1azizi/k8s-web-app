FROM python:3.12-slim

RUN apt-get update && apt-get install -y --only-upgrade \
    gzip \
    libpcre2-8-0 \
    libsqlite3-0 \
    perl-base \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 appuser

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]