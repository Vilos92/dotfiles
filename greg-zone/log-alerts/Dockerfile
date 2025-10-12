FROM python:3.11-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache curl jq

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the alert monitor script
COPY alert-monitor.py .

# Create non-root user
RUN adduser -D -s /bin/sh alertmonitor
USER alertmonitor

# Run the alert monitor
CMD ["python", "alert-monitor.py"]
