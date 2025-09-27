FROM python:3.12-slim

WORKDIR /app

COPY . ./backend

RUN pip install --no-cache-dir -r ./backend/requirements.txt

EXPOSE 5000

CMD ["python", "-m", "backend.run"]

# build: $ docker build -t voting-app-backend:1.0 backend/Dockerfile ./backend/