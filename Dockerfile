FROM node:18-bullseye

RUN apt-get update && apt-get install -y \
    python3 python3-pip wget unzip ffmpeg build-essential libvips-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

RUN npm install --legacy-peer-deps

RUN pip3 install --no-cache-dir vosk

RUN mkdir -p models && \
    wget https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip && \
    unzip vosk-model-small-en-us-0.15.zip -d models/ && \
    rm vosk-model-small-en-us-0.15.zip

COPY . .

EXPOSE 5000

CMD ["node", "index.js"]

