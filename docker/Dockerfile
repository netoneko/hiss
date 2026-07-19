# Dev container for hiss: official rust image + OSS-over-PulseAudio so the app
# can open("/dev/dsp") like it will on real akuma and actually hear it on the
# Mac speakers. See ../run.sh.
FROM rust:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends pulseaudio-utils libchafa-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
