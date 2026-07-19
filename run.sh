#!/usr/bin/env bash
# Dev container for hiss: mounts the music assets and this source tree, and
# wires up /dev/dsp so audio written to it plays on the Mac's speakers.
#
#   ./run.sh                    # drop into a shell in the container
#   ./run.sh cargo run -- --path /music
#
# How the audio path works: a local PulseAudio server runs on the Mac (with
# its CoreAudio sink) and listens on TCP for the container. Inside the
# container, LD_PRELOAD=libpulsedsp.so makes open("/dev/dsp"), the
# SNDCTL_DSP_* ioctls, and write() transparently proxy to that PulseAudio
# server instead of touching a real device file - so OSS-style code (like the
# akuma wavplay logic this is ported from) doesn't need to change at all.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MUSIC_DIR="$(cd "$SCRIPT_DIR/../../bootstrap/music" && pwd)"
IMAGE="hiss-dev"

PULSE_BIN="/opt/homebrew/opt/pulseaudio/bin/pulseaudio"
PACTL_BIN="/opt/homebrew/opt/pulseaudio/bin/pactl"

if [ ! -x "$PACTL_BIN" ]; then
    echo "error: pulseaudio not found at $PULSE_BIN (expected 'brew install pulseaudio')" >&2
    exit 1
fi

# Docker Desktop's internal VM subnet + loopback only - not the real LAN.
PULSE_ACL="127.0.0.1;192.168.65.0/24"

if ! "$PACTL_BIN" list modules short 2>/dev/null | grep -q module-native-protocol-tcp; then
    if ! "$PACTL_BIN" info >/dev/null 2>&1; then
        echo "==> starting local PulseAudio..."
        "$PULSE_BIN" --exit-idle-time=-1 --daemon
        sleep 1
    fi
    echo "==> loading PulseAudio TCP module (acl: $PULSE_ACL)..."
    "$PACTL_BIN" load-module module-native-protocol-tcp \
        listen=0.0.0.0 auth-anonymous=1 "auth-ip-acl=$PULSE_ACL" >/dev/null
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "==> building $IMAGE image..."
    docker build -t "$IMAGE" "$SCRIPT_DIR/docker"
fi

# target/ gets its own volume (not the virtiofs bind mount above) - cargo
# builds stall/hang over Docker Desktop's Mac<->VM file sharing otherwise.
docker run --rm -it \
    -v "$MUSIC_DIR:/music:ro" \
    -v "$SCRIPT_DIR:/src/hiss" \
    -v hiss-cargo-registry:/usr/local/cargo/registry \
    -v hiss-cargo-git:/usr/local/cargo/git \
    -v hiss-target:/src/hiss/target \
    -e PULSE_SERVER="tcp:host.docker.internal:4713" \
    -w /src/hiss \
    "$IMAGE" "$@"
