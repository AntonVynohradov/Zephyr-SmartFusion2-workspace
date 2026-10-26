# Zephyr RTOS — Microchip SmartFusion2 M2S010

Development and build environment for **Zephyr RTOS firmware** targeting the **Microchip SmartFusion2 M2S010-MKR-KIT**.

The repository uses Docker and VS Code Dev Containers to provide a reproducible and isolated build environment. Microchip **Libero SoC is not installed inside the container** and remains part of the external FPGA/hardware development environment.

---

## Table of Contents

* [Project Goals](#project-goals)
* [Architecture](#architecture)
* [Requirements](#requirements)
* [Repository Structure](#repository-structure)
* [Tool Versions](#tool-versions)
* [Environment Setup](#environment-setup)
* [VS Code Dev Container](#vs-code-dev-container)
* [Building the Firmware](#building-the-firmware)
* [Pristine Build](#pristine-build)
* [Build Cache](#build-cache)
* [West and Zephyr](#west-and-zephyr)
* [Build Artifacts](#build-artifacts)
* [Libero SoC](#libero-soc)
* [Debugging](#debugging)
* [Updating Tool Versions](#updating-tool-versions)
* [CI/CD](#cicd)
* [Troubleshooting](#troubleshooting)
* [Licenses](#licenses)

---

## Project Goals

The goal of this repository is to provide a reproducible development environment for firmware targeting:

* **Microchip SmartFusion2 M2S010**
* **M2S010-MKR-KIT**
* **ARM Cortex-M3**
* **Zephyr RTOS**

The environment is designed primarily for:

* reproducible builds,
* local development,
* VS Code,
* CI/CD,
* a small Docker image,
* fast rebuilds using `ccache`,
* an isolated toolchain,
* separation of firmware and FPGA development tools.

---

## Architecture

The environment consists of two independent parts.

### Firmware

The Docker container contains:

```text
Debian
├── Python
├── west
├── CMake
├── Ninja
├── ccache
├── Zephyr SDK
└── ARM Cortex-M3 toolchain
```

The container is responsible exclusively for building Zephyr firmware.

### FPGA / Hardware

Microchip tools remain outside the container:

```text
Host
└── Microchip Libero SoC
    ├── SmartFusion2 MSS
    ├── FPGA fabric
    ├── clocks
    ├── pins
    └── hardware configuration
```

The Docker image **does not contain Libero SoC or Microchip license files**.

---

## Requirements

### Host

Required:

* Docker
* Docker BuildKit / Docker Buildx
* Git
* VS Code — optional
* VS Code Dev Containers extension — optional

Additional Microchip tools may be required for board programming, debugging, and FPGA/hardware development.

### Docker

Verify the installation:

```bash
docker --version
docker buildx version
```

BuildKit is recommended because it provides Docker build cache support.

### VS Code

If you are using VS Code, install the:

```text
Dev Containers
```

extension.

---

## Repository Structure

Repository structure (the root is a Zephyr application: a starter that blinks
`led0` and prints a heartbeat on the console; replace it with your firmware):

```text
.
├── .devcontainer/
│   └── devcontainer.json
│
├── .vscode/
│   ├── settings.json
│   └── tasks.json
│
├── src/
│   └── main.c
│
├── Dockerfile
├── .dockerignore
├── .gitignore
├── compose.yaml
├── west.yml
├── CMakeLists.txt
└── prj.conf
```

Generated directories such as `build/` and `.ccache/` should not be committed to the repository.

---

## Tool Versions

The environment uses explicitly defined tool versions.

Current configuration:

| Tool       | Version                 |
| ---------- | ----------------------- |
| Base image | `python:3.12-slim-bookworm` (pinned by digest) |
| Python     | 3.12 (Zephyr 4.5 requires 3.12 or later) |
| Zephyr     | v4.5.0-rc3 (`west.yml`; v4.5.0 once tagged) |
| west       | 1.5.0                   |
| Zephyr SDK | 1.0.1 (checksums verified) |
| Toolchain  | ARM `arm-zephyr-eabi` in `/opt/zephyr-sdk/gnu` |
| CMake      | 3.30.5 (pip)            |
| Ninja      | Debian-provided version |
| ccache     | Debian-provided version |
| Board      | `m2s010_mkr_kit/m2s010` |

The SDK and `west` versions are defined in the `Dockerfile`; the Zephyr revision in
`west.yml`. The `m2s010_mkr_kit` board is part of Zephyr from 4.5, so older Zephyr
revisions do not build for it.

Avoid using `latest` for critical toolchain components.

---

## Environment Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Initialize West

If the repository uses a local manifest:

```bash
west init -l .
```

Then:

```bash
west update
```

Verify the environment:

```bash
west --version
```

---

# VS Code Dev Container

The recommended way to work with the project is to use VS Code Dev Containers.

Open the repository in VS Code:

```text
File → Open Folder
```

Then run:

```text
F1
→ Dev Containers: Reopen in Container
```

VS Code will:

1. build the Docker image,
2. start the container,
3. mount the repository as `/workspace`,
4. mount the local `ccache`,
5. install the configured extensions,
6. make the ARM toolchain available.

After the container starts, the terminal should be located at:

```text
/workspace
```

You can verify this with:

```bash
pwd
```

---

## Verify the Toolchain

Inside the container:

```bash
west --version
```

Then:

```bash
arm-zephyr-eabi-gcc --version
```

Also verify:

```bash
cmake --version
```

and:

```bash
ninja --version
```

The SDK should be installed at:

```text
/opt/zephyr-sdk
```

---

# Building the Firmware

The default board target is:

```text
m2s010_mkr_kit/m2s010
```

Build the firmware with:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

Run this command from the application directory, which must contain a
`CMakeLists.txt` file. To build an application in another directory, pass it
with `-s <application-directory>`.

After a successful build, the output will be located in:

```text
build/
```

---

## Building from VS Code

The default build task opens the **Zephyr: Workspace Menu** picker:

```text
Ctrl + Shift + B
```

Choose one of these actions:

- **Initialize + update** — initializes West from the local manifest if needed,
  then downloads or updates the Zephyr repositories and modules.
- **Update dependencies** — runs `west update` in an initialized workspace.
- **Build firmware** — builds the application for the M2S010 board.

To open the same menu without the shortcut, use:

```text
F1
→ Tasks: Run Task
→ Zephyr: Workspace Menu
```

The individual tasks **Zephyr: Build** and **Zephyr: Pristine Build** are also
available from **Tasks: Run Task**.


---

# Pristine Build

A pristine build may be required after changing hardware configuration, Kconfig, or DeviceTree files.

Run:

```bash
west build \
    -p always \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

Alternatively:

```bash
rm -rf build
```

and then:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

The VS Code environment also provides:

```text
Zephyr: Pristine Build
```

---

# Build Cache

The project uses `ccache` to speed up subsequent builds.

The cache is stored on the host:

```text
.ccache/
```

and mounted inside the container as:

```text
/ccache
```

This means that removing and recreating the Docker container does not remove the compiler cache.

---

## Check Cache Statistics

Inside the container:

```bash
ccache --show-stats
```

You can also use VS Code:

```text
F1
→ Tasks: Run Task
→ Zephyr: Ccache Stats
```

---

## Clear the Cache

Run:

```bash
ccache --clear
```

or use:

```text
F1
→ Tasks: Run Task
→ Zephyr: Ccache Clear
```

The cache can also be removed completely:

```bash
rm -rf .ccache
```

This does not affect the source code.

---

# West and Zephyr

`west` is used to manage the Zephyr workspace and its dependencies.

In VS Code, initialize and download dependencies from **Zephyr: Workspace Menu**
by choosing **Initialize + update**. The task initializes from the local
manifest when necessary; if a workspace already exists, it only runs
`west update`.

For manual setup from the repository containing `west.yml`:

```bash
west init -l .
```

Then:

```bash
west update
```

The manifest is located at:

```text
west.yml
```

For reproducible builds, pin Zephyr to a specific release or revision instead of using:

```yaml
revision: main
```

Example:

```yaml
manifest:
  remotes:
    - name: zephyrproject-rtos
      url-base: https://github.com/zephyrproject-rtos

  projects:
    - name: zephyr
      remote: zephyrproject-rtos
      revision: <pinned-version>
      import: true
```

This ensures that subsequent builds use the same Zephyr source revision.

---

# Build Artifacts

The main build artifacts are located in:

```text
build/zephyr/
```

Typical files include:

```text
build/zephyr/zephyr.elf
build/zephyr/zephyr.hex
build/zephyr/zephyr.bin
```

### ELF

Primarily used for debugging.

```text
zephyr.elf
```

It contains debug information and symbols.

### HEX

Can be used by programming tools:

```text
zephyr.hex
```

### BIN

Raw firmware image:

```text
zephyr.bin
```

The exact programming method depends on the SmartFusion2 hardware configuration and programming environment.

---

# Libero SoC

**Libero SoC is not part of the Docker container.**

This is an intentional architectural decision.

The container is responsible for:

```text
Application
     ↓
Zephyr
     ↓
ARM Cortex-M3
     ↓
ELF / HEX / BIN
```

Libero is responsible for:

```text
SmartFusion2 hardware
        ↓
MSS
        ↓
Clock configuration
        ↓
FPGA fabric
        ↓
Pin configuration
        ↓
Hardware image
```

This separation avoids putting the following components into the Docker image:

* Libero SoC,
* Microchip license files,
* license server configuration,
* FPGA development tools.

---

## License Security

Microchip licenses should remain exclusively in the environment where they are required.

Do **not**:

* copy license files into the repository,
* add license files to the Dockerfile,
* include licenses in the Docker image,
* store licenses in a public container registry,
* publish licenses as CI artifacts.

---

# Debugging

Firmware can be debugged using:

* `zephyr.elf`,
* VS Code,
* Cortex-Debug,
* an appropriate hardware debugger/programmer.

The exact debugger configuration depends on the hardware interface and board setup.

Typical architecture:

```text
VS Code
   │
   ▼
Cortex-Debug
   │
   ▼
GDB
   │
   ▼
ARM Cortex-M3
   │
   ▼
SmartFusion2
```

Libero SoC is not required for debugging firmware already loaded into a configured hardware design.

---

# Docker Without VS Code

The Dev Container is not required.

Build the image directly:

```bash
docker build \
    -t zephyr-sf2:1.0.1 \
    .
```

Start the container:

```bash
docker run --rm -it \
    -v "$PWD:/workspace" \
    -v "$PWD/.ccache:/ccache" \
    -w /workspace \
    zephyr-sf2:1.0.1
```

Then build:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

---

# Docker Compose

If the repository contains `compose.yaml`, you can use:

```bash
docker compose run --rm zephyr
```

This avoids having to specify all Docker volume and environment parameters manually.

---

# Updating Tool Versions

SDK versions are defined in:

```text
Dockerfile
```

For example:

```dockerfile
ARG ZEPHYR_SDK_VERSION=1.0.1
```

The `west` version is defined as:

```dockerfile
ARG WEST_VERSION=1.5.0
```

After changing a tool version, rebuild the image:

```bash
docker build \
    --no-cache \
    -t zephyr-sf2:<new-version> \
    .
```

Toolchain updates should not be performed automatically without validating the firmware.

Each update should be verified with:

1. firmware build,
2. firmware tests,
3. hardware testing on the M2S010-MKR-KIT,
4. relevant integration tests,
5. updating the Docker image version.

---

# CI/CD

The same Dockerfile can be used locally and in CI.

Example pipeline:

```text
Git push
    │
    ▼
CI runner
    │
    ▼
Docker image
    │
    ▼
west update
    │
    ▼
west build
    │
    ▼
firmware.elf
firmware.hex
firmware.bin
    │
    ▼
CI artifacts
```

`ccache` can also be persisted using the CI system's cache mechanism.

The CI environment should not contain:

* Microchip license files,
* a Libero installation,
* license server credentials,

when the pipeline is only responsible for building Zephyr firmware.

---

# Troubleshooting

## `west: command not found`

Check:

```bash
which west
```

It should return:

```text
/opt/venv/bin/west
```

Then:

```bash
west --version
```

---

## `source directory "." does not contain a CMakeLists.txt`

West is available, but the selected application directory does not contain a
Zephyr application. Add the application files, including `CMakeLists.txt`, to
the directory being built, or select the application directory explicitly:

```bash
west build -s <application-directory> \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

---

## `arm-zephyr-eabi-gcc: command not found`

Check:

```bash
ls /opt/zephyr-sdk/gnu/arm-zephyr-eabi/bin/
```

and:

```bash
echo $PATH
```

The PATH should contain:

```text
/opt/zephyr-sdk/gnu/arm-zephyr-eabi/bin
```

---

## IntelliSense Problems

First perform a build:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

Then check:

```text
build/compile_commands.json
```

VS Code should use:

```text
C_Cpp.default.compileCommands
```

with:

```text
${workspaceFolder}/build/compile_commands.json
```

---

## Build Behaves Unexpectedly After Changing `prj.conf`

Perform a pristine build:

```bash
west build \
    -p always \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

---

## Problems After Changing DeviceTree

Remove the build directory:

```bash
rm -rf build
```

Then rebuild:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

---

## Ccache Does Not Speed Up the Build

Check:

```bash
ccache --show-stats
```

and:

```bash
echo $CCACHE_DIR
```

It should return:

```text
/ccache
```

Also verify that the directory exists:

```bash
ls -la /ccache
```

On the host:

```bash
ls -la .ccache
```

---

# Recommended Developer Workflow

After cloning the repository:

```bash
git clone <repository-url>
cd <repository>
```

Open the project in VS Code and run:

```text
Dev Containers: Reopen in Container
```

Inside the container:

```bash
west update
```

Build:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

After changing source code:

```bash
west build \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

`ccache` should speed up subsequent compilations.

After changing configuration:

```bash
west build \
    -p always \
    -b m2s010_mkr_kit/m2s010 \
    -d build
```

---

# Summary

The repository follows these principles:

```text
┌──────────────────────────────────────────────┐
│                 Development                  │
│                                              │
│  VS Code                                     │
│     │                                        │
│     ▼                                        │
│  Dev Container                               │
│     │                                        │
│     ├── Zephyr RTOS                          │
│     ├── west                                 │
│     ├── Zephyr SDK                           │
│     ├── ARM Cortex-M3 toolchain              │
│     ├── CMake                                │
│     ├── Ninja                                │
│     └── ccache                               │
│                                              │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
             M2S010-MKR-KIT firmware
                       │
                       ├── ELF
                       ├── HEX
                       └── BIN


┌──────────────────────────────────────────────┐
│              Hardware / FPGA                 │
│                                              │
│  Microchip Libero SoC                        │
│       │                                      │
│       ├── MSS                                │
│       ├── clocks                             │
│       ├── FPGA fabric                        │
│       └── hardware configuration             │
│                                              │
│  Microchip licenses remain outside Docker.   │
│                                              │
└──────────────────────────────────────────────┘
```

The development environment provides:

* **reproducible builds**,
* **an isolated ARM toolchain**,
* **a small Docker image**,
* **VS Code Dev Container support**,
* **persistent `ccache`**,
* **explicit tool versioning**,
* **Zephyr + west**,
* **M2S010-MKR-KIT support**,
* **Libero SoC outside Docker**,
* **no Microchip licenses inside the Docker image or repository**.

---

# Project License

The application source code and configuration contained in this repository are licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.

Zephyr RTOS, Zephyr SDK, and other third-party tools and components are distributed under their respective licenses. Review the applicable license terms for each component before distributing the Docker image or other project artifacts.

```
```
