FROM ubuntu:latest

EXPOSE 25200

# Env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_TERM_COLOR=always
ENV RUSTFLAGS="-C target-feature=+crt-static"
ENV PATH="/root/.cargo/bin:${PATH}"

# Dependencies
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
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
    protobuf-compiler

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly

RUN rustup target add x86_64-unknown-linux-musl

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
RUN cargo build --release --target x86_64-unknown-linux-musl

# Install binaries
RUN install -Dm755 \
      target/x86_64-unknown-linux-musl/release/maxima-bootstrap \
      target/x86_64-unknown-linux-musl/release/maxima-cli \
      target/x86_64-unknown-linux-musl/release/maxima-tui \
      target/x86_64-unknown-linux-musl/release/maxima \
      /usr/local/bin/

# Create the required dirs
RUN mkdir -p \
    "/root/.local/share/applications" \
    "/opt/games/Battlefield 1" \
    "/opt/games/Battlefield V"

WORKDIR /opt/games

CMD ["maxima-cli"]
