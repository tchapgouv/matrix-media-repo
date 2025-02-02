# ---- Stage 0 ----
# Builds media repo binaries
FROM golang:1.20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git musl-dev dos2unix build-base libde265-dev libheif-dev

WORKDIR /opt
COPY . /opt
RUN dos2unix ./build.sh ./docker/run.sh && chmod 744 ./build.sh
RUN ./build.sh

# the label is applied last so we don't pollute the image list with a weird amount of labelled images
LABEL io.t2bot.mmr.cleanup="true"

# ---- Stage 1 ----
# Final runtime stage.
FROM alpine

RUN mkdir /plugins
RUN apk add --no-cache \
        su-exec \
        ca-certificates \
        dos2unix \
        imagemagick \
        ffmpeg

COPY --from=builder /opt/bin/plugin_antispam_ocr /plugins/
COPY --from=builder /opt/bin/media_repo /opt/bin/import_synapse /opt/bin/export_synapse_for_import /opt/bin/gdpr_export /opt/bin/gdpr_import /opt/bin/s3_consistency_check /usr/local/bin/

COPY ./config.sample.yaml /etc/media-repo.yaml.sample
COPY ./docker/run.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/run.sh && chmod 744 /usr/local/bin/run.sh

ENV REPO_CONFIG=/data/media-repo.yaml

CMD /usr/local/bin/run.sh
VOLUME ["/data", "/media"]
EXPOSE 8000
