FROM python:3.9-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY sidecar.py .
ENTRYPOINT ["python", "sidecar.py"]
