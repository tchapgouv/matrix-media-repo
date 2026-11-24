# Keep builder and runtime on the same Alpine branch for CGO compatibility.
ARG ALPINE_VERSION=3.24
ARG GO_VERSION=1.27.4

# ---- Stage 0 ----
# Builds media repo binaries against Alpine's maintained libheif package.
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk upgrade --no-cache && apk add --no-cache \
        git \
        dos2unix \
        build-base \
        pkgconf \
        'libheif-dev>=1.23.7'

WORKDIR /opt

COPY . /opt

# Run remaining build steps
RUN dos2unix ./build.sh ./docker/run.sh && chmod 744 ./build.sh ./docker/run.sh
RUN ./build.sh

# ---- Stage 1 ----
# Only runtime packages are installed; compilers and sources stay in the builder.
FROM alpine:${ALPINE_VERSION}

RUN apk upgrade --no-cache && apk add --no-cache \
        su-exec \
        ca-certificates \
        imagemagick \
        ffmpeg \
        'libheif>=1.23.7'

COPY --from=builder /opt/bin/plugin_antispam_ocr /plugins/
COPY --from=builder \
 /opt/bin/media_repo \
 /opt/bin/import_synapse \
 /opt/bin/import_dendrite \
 /opt/bin/export_synapse_for_import \
 /opt/bin/export_dendrite_for_import \
 /opt/bin/import_to_synapse \
 /opt/bin/gdpr_export \
 /opt/bin/gdpr_import \
 /opt/bin/s3_consistency_check \
 /opt/bin/combine_signing_keys \
 /opt/bin/generate_signing_key \
 /opt/bin/thumbnailer \
 /usr/local/bin/

COPY ./config.sample.yaml /etc/media-repo.yaml.sample
COPY --from=builder /opt/docker/run.sh /usr/local/bin/run.sh

# Verify CGO libraries resolve in the final image before it can be published.
RUN media_repo -version

WORKDIR /data
ENV REPO_CONFIG=/data/media-repo.yaml

CMD ["/usr/local/bin/run.sh"]
VOLUME ["/data", "/media"]
EXPOSE 8000
