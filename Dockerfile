# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Versions
# ---------------------------------------------------------------------------

ARG WEST_VERSION=1.4.0
ARG ZEPHYR_SDK_VERSION=0.17.4

ENV \
    ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk \
    ZEPHYR_TOOLCHAIN_VARIANT=zephyr \
    ZEPHYR_BOARD=m2s010_mkr_kit/m2s010 \
    VIRTUAL_ENV=/opt/venv \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    CCACHE_DIR=/ccache \
    PATH=/opt/venv/bin:/opt/zephyr-sdk/arm-zephyr-eabi/bin:${PATH}

# ---------------------------------------------------------------------------
# OS dependencies
# ---------------------------------------------------------------------------

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        ccache \
        file \
        g++ \
        gcc \
        git \
        gperf \
        make \
        ninja-build \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        wget \
        xz-utils \
        device-tree-compiler \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Python environment
# ---------------------------------------------------------------------------

RUN python3 -m venv "${VIRTUAL_ENV}" \
    && "${VIRTUAL_ENV}/bin/pip" install \
        --no-cache-dir \
        "west==${WEST_VERSION}"

# ---------------------------------------------------------------------------
# Zephyr SDK - minimal bundle
#
# The minimal SDK contains host tools but no compiler toolchains.
# We install ONLY arm-zephyr-eabi afterwards.
# ---------------------------------------------------------------------------

RUN mkdir -p "${ZEPHYR_SDK_INSTALL_DIR}" \
    && wget -q \
       "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64_minimal.tar.xz" \
       -O /tmp/zephyr-sdk.tar.xz \
    && tar \
       -xJf /tmp/zephyr-sdk.tar.xz \
       --strip-components=1 \
       -C "${ZEPHYR_SDK_INSTALL_DIR}" \
    && rm -f /tmp/zephyr-sdk.tar.xz

# ---------------------------------------------------------------------------
# Install ONLY ARM Cortex-M toolchain
#
# The archive is intentionally downloaded separately from the minimal SDK.
# ---------------------------------------------------------------------------

RUN wget -q \
       "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz" \
       -O /tmp/arm-toolchain.tar.xz \
    && tar \
       -xJf /tmp/arm-toolchain.tar.xz \
       -C "${ZEPHYR_SDK_INSTALL_DIR}" \
    && rm -f /tmp/arm-toolchain.tar.xz

# ---------------------------------------------------------------------------
# Register SDK
# ---------------------------------------------------------------------------

RUN "${ZEPHYR_SDK_INSTALL_DIR}/setup.sh" -h

# ---------------------------------------------------------------------------
# ccache
# ---------------------------------------------------------------------------

RUN mkdir -p /ccache \
    && ccache --set-config=max_size=2G \
    && ccache --set-config=compression=true

# ---------------------------------------------------------------------------
# Workspace
# ---------------------------------------------------------------------------

WORKDIR /workspace

# Do not copy project sources into the image.
# The workspace is mounted at runtime.

CMD ["/bin/bash"]
