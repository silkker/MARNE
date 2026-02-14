FROM ubuntu:24.04

EXPOSE 25200

# Env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTFLAGS="-C target-feature=+crt-static"
ENV CARGO_TERM_COLOR=always
#ENV WINEDLLOVERRIDES=dinput8=n,b
#ENV MAXIMA_DISABLE_WINE_VERIFICATION=1
#ENV MAXIMA_WINE_COMMAND="/home/maxima/ge-proton/files/bin/wine64"
#ENV MAXIMA_DISABLE_QRC=1

# Dependencies
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y \
    sudo \
    strace \
    htop \
    nano \
    tmux \
    git \
    curl \
    mesa-utils \
    cargo \
    musl-tools \
    locales \
    libx11-dev \
    libxcursor-dev \
    libxcb1-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    protobuf-compiler \
    xdg-utils \
    zenity \
    gnupg2 \
    winbind \
    xvfb \
    xdotool \
    cage \
    xwayland-run \
    ca-certificates \
    tar \
    xz-utils \
    unzip \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6-i386

# Locale
RUN sudo locale-gen en_US.UTF-8 \
 && sudo update-locale LANG=en_US.UTF-8

# Wine from the upstream repo
RUN mkdir -pm755 /etc/apt/keyrings && \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        -o /etc/apt/keyrings/winehq-archive.key && \
    curl -fsSL https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources \
        -o /etc/apt/sources.list.d/winehq-noble.sources && \
    apt-get update && \
    apt-get install -y --install-recommends winehq-devel

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
 && cargo build -p maxima-cli --release --target x86_64-unknown-linux-musl

# Install binaries
RUN install -Dm755 \
      target/x86_64-unknown-linux-musl/release/maxima-cli \
      /usr/local/bin/

# Create user
RUN useradd -m -s /bin/bash maxima

# Give maxima sudo without password
RUN echo "maxima ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/maxima \
 && chmod 0440 /etc/sudoers.d/maxima

USER maxima

# Kill exe alias
RUN echo "alias kill_exe='sudo pkill -9 -f "\\.exe"'" >> $HOME/.bashrc

# Create the required dirs
RUN mkdir -p \
    "$HOME/.cache" \
    "$HOME/.config/tmux" \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/maxima/wine/prefix" \
    "$HOME/Games"

WORKDIR /home/maxima

# Entrypoint
#COPY --chown=maxima:maxima entrypoint.sh /home/maxima/entrypoint.sh
#RUN chmod +x /home/maxima/entrypoint.sh && \
#    sed -i -e 's/\r$//' /home/maxima/entrypoint.sh

# auth.toml
COPY --chown=maxima:maxima auth.toml /home/maxima/.local/share/maxima/auth.toml

# tmux.conf
#COPY --chown=maxima:maxima tmux.conf /home/maxima/.config/tmux/tmux.conf

# Display server stuff
#ENV DISPLAY=:99
#ENV SDL_VIDEODRIVER=x11
#ENV GDK_BACKEND=x11
#ENV LIBGL_ALWAYS_SOFTWARE=1
#ENV LIBGL_DRI3_DISABLE=1

ENV PROTON_USE_WINED3D=1
ENV PROTON_ENABLE_WAYLAND=1
#ENV WAYLAND_DISPLAY=wayland-1
#ENV PROTON_ADD_CONFIG=wayland

#ENV XDG_RUNTIME_DIR=/tmp/xdg-runtime
#RUN mkdir -p "$XDG_RUNTIME_DIR" \
# && chmod 700 "$XDG_RUNTIME_DIR" \
# && sudo mkdir /tmp/.X11-unix \
# && sudo chown root:root /tmp/.X11-unix \
# && sudo chmod 1777 /tmp/.X11-unix

WORKDIR /home/maxima/Games

#ENTRYPOINT ["/home/maxima/entrypoint.sh"]
