FROM docker.io/python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY sync.py .
EXPOSE 5000
CMD ["python", "sync.py"]
