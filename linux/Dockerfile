FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates gnupg \
    libasound2 libatk1.0-0 libc6 libdrm2 libgbm1 libgtk-3-0 libnss3 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxtst6 libxcb-dri3-0 libxcb-dri2-0 libxcb-present0 libxcb-sync1 libxshmfence1 libxss1 libgl1-mesa-glx libxkbcommon0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/discord-drover

# Install Discord .deb inside the image
RUN wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb" \
    && apt-get update && apt-get install -y --no-install-recommends /tmp/discord.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/discord.deb

# Copy launcher
COPY discord-drover.sh /opt/discord-drover/discord-drover
COPY config.example.env /etc/discord-drover/config.env

ENV DISCORD_DROVER_CONFIG=/etc/discord-drover/config.env

# Default to host display/audio; override with -e/volume flags at runtime.
CMD ["/opt/discord-drover/discord-drover"]
