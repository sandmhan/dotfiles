FROM python:3.12-alpine

WORKDIR /app

RUN pip install --no-cache-dir prometheus_client requests

COPY exporter.py .

EXPOSE 9101

ENTRYPOINT ["python3", "exporter.py"]
