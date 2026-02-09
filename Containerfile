FROM ubuntu:24.04

EXPOSE 25200

# Env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTFLAGS="-C target-feature=+crt-static"
ENV CARGO_TERM_COLOR=always

# Dependencies
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    cargo \
    musl-tools \
    libx11-dev \
    libxcursor-dev \
    libxcb1-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    protobuf-compiler \
    xdg-utils

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly

RUN export PATH="/root/.cargo/bin:$PATH" \
 && rustup target add x86_64-unknown-linux-musl

# umu
RUN set -eux; \
    ver="$( \
      curl -sIL https://github.com/Open-Wine-Components/umu-launcher/releases/latest \
      | grep -i '^location:' \
      | sed -E 's|.*tag/||' \
      | tr -d '\r' \
    )"; \
    curl -Lo /tmp/umu-launcher.deb \
      "https://github.com/Open-Wine-Components/umu-launcher/releases/download/${ver}/python3-umu-launcher_${ver}-1_amd64_ubuntu-noble.deb"; \
    apt-get install -y /tmp/umu-launcher.deb; \
    rm -f /tmp/umu-launcher.deb;

# Build maxima (gotta keep doing so till their first release)
WORKDIR /build
RUN git clone --recursive https://github.com/ArmchairDevelopers/maxima \
 && cd maxima \
 && git checkout cbde5f0002d6f16fb67dfa79ad96b705e1c591bf

WORKDIR /build/maxima
RUN export PATH="/root/.cargo/bin:$PATH" \
 && cargo build --release --target x86_64-unknown-linux-musl

# Install binaries
RUN install -Dm755 \
      target/x86_64-unknown-linux-musl/release/maxima-bootstrap \
      target/x86_64-unknown-linux-musl/release/maxima-cli \
      target/x86_64-unknown-linux-musl/release/maxima-tui \
      target/x86_64-unknown-linux-musl/release/maxima \
      /usr/local/bin/

# Create user
RUN useradd -m -s /bin/bash maxima

# Give maxima sudo without password
RUN echo "maxima ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/maxima \
 && chmod 0440 /etc/sudoers.d/maxima

USER maxima

# Create the required dirs
RUN mkdir -p \
    "$HOME/.local/share/applications" \
    "$HOME/maxima/games/Battlefield 1" \
    "$HOME/maxima/games/Battlefield V"

WORKDIR /home/maxima/games

CMD ["maxima-cli"]
