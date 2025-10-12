FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY minecraft-webhook.py .

# Create non-root user
RUN useradd -m -u 1000 webhook && chown -R webhook:webhook /app
USER webhook

EXPOSE 8080

CMD ["python", "minecraft-webhook.py"]
