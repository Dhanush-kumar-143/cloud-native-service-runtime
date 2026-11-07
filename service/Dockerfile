
# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app
COPY app.py .

# Stage 2: Runtime
FROM python:3.12-slim

WORKDIR /app

# Create non-root user
RUN useradd -r -u 10001 app

COPY --from=builder /app/app.py .

USER 10001

EXPOSE 8080

CMD ["python", "app.py"]
