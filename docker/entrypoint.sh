#!/bin/bash
# Makes /dev/dsp work: LD_PRELOAD intercepts open()/ioctl(SNDCTL_DSP_*)/write()
# on that path and redirects the audio to PULSE_SERVER (the Mac host), which
# plays it through the CoreAudio sink. Confirmed working with a real
# open+ioctl+write C program, not just docs.
set -euo pipefail

export LD_PRELOAD="/usr/lib/$(uname -m)-linux-gnu/pulseaudio/libpulsedsp.so"
export PULSE_SERVER="${PULSE_SERVER:-tcp:host.docker.internal:4713}"

# The repo's .cargo/config.toml pins target=aarch64-apple-darwin for native
# macOS builds; override it here so cargo builds for the container's own arch
# instead (env var wins over the config-file setting).
export CARGO_BUILD_TARGET="$(rustc -vV | sed -n 's/^host: //p')"

exec "$@"
