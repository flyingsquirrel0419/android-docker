# Android in Docker

[![Build](https://github.com/dockur/android/actions/workflows/build.yml/badge.svg)](https://github.com/dockur/android/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/flyingsquirrel0419/android.svg?style=flat&label=pulls&logo=docker)](https://hub.docker.com/r/flyingsquirrel0419/android/)
[![Docker Image Size](https://img.shields.io/docker/image-size/flyingsquirrel0419/android/latest?color=066da5&label=size)](https://hub.docker.com/r/flyingsquirrel0419/android/tags)
[![License](https://img.shields.io/github/license/dockur/android?color=blue)](LICENSE)

Android inside a Docker container using QEMU/KVM, with a web-based viewer.

## Features

- **Multiple versions** — Android 9 (Pie), 11 (BlissOS), 13 (BlissOS 16)
- **KVM acceleration** — near-native performance on supported hardware
- **Web-based viewer** — access the Android screen from any browser via noVNC
- **ADB over TCP** — connect via `adb connect` on port 5555
- **One-command setup** — `docker compose up` and you're done
- **OpenGApps included** — BlissOS 11 and 13 come with Google Apps pre-installed

## Quick Start

```bash
docker run -it --rm -p 8006:8006 --device=/dev/kvm flyingsquirrel0419/android
```

Then open [http://localhost:8006](http://localhost:8006) in your browser.

## Usage

### Docker Compose

Create a `compose.yml`:

```yaml
services:
  android:
    image: flyingsquirrel0419/android
    container_name: android
    ports:
      - 8006:8006  # noVNC web viewer
      - 5555:5555  # ADB
    devices:
      - /dev/kvm
    volumes:
      - ./storage:/storage
    environment:
      VERSION: "11"
    restart: always
    stop_grace_period: 2m
```

```bash
docker compose up -d
```

### Docker CLI

```bash
docker run -d --name android \
  -p 8006:8006 -p 5555:5555 \
  --device=/dev/kvm \
  -v "${PWD:-.}/storage:/storage" \
  --stop-timeout 120 \
  flyingsquirrel0419/android
```

### Kubernetes

```bash
kubectl apply -f https://raw.githubusercontent.com/dockur/android/refs/heads/main/kubernetes.yml
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VERSION` | `11` | Android version: `9`, `11`, or `13` |
| `RAM_SIZE` | `4G` | Memory allocated to the VM |
| `CPU_CORES` | `2` | Number of CPU cores |
| `DISK_SIZE` | `16G` | Virtual disk size |
| `DISK_NAME` | `android` | Disk filename in `/storage` |

### Version Details

| Value | Version | Source | GApps |
|-------|---------|--------|-------|
| `9` | Android 9 Pie | [android-x86](https://www.android-x86.org/) | No |
| `11` | BlissOS 14 | [BlissOS](https://blissos.org/) | OpenGApps |
| `13` | BlissOS 16 | [BlissOS](https://blissos.org/) | OpenGApps |

You can also pass a direct URL to any compatible ISO:

```yaml
environment:
  VERSION: "https://example.com/custom-android.iso"
```

## FAQ

### How do I use it?

1. Start the container.
2. Open [http://localhost:8006](http://localhost:8006) in your browser.
3. Wait for Android to boot — first run downloads the ISO (~1GB).
4. Done.

### How do I connect via ADB?

```bash
adb connect localhost:5555
adb shell
```

ADB over TCP needs to be enabled in Android settings first: **Settings → Developer Options → USB Debugging**.

### How do I install APKs?

```bash
adb connect localhost:5555
adb install my-app.apk
```

Or place APK files in the `/storage/apk/` directory inside the container.

### How do I check if KVM is available?

```bash
ls -l /dev/kvm
```

If the file doesn't exist, enable virtualization (`Intel VT-x` or `AMD SVM`) in your BIOS. Without KVM, performance will be significantly slower.

Cloud providers typically don't support nested virtualization. Use `privileged: true` in your compose file if you get permission errors.

### How do I reset Android?

```bash
docker compose down
rm -rf ./storage/android.qcow2 ./storage/android.img
docker compose up -d
```

### How do I assign a dedicated IP?

Create a macvlan network:

```bash
docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    -o parent=eth0 vlan
```

```yaml
services:
  android:
    container_name: android
    networks:
      vlan:
        ipv4_address: 192.168.0.100

networks:
  vlan:
    external: true
```

All ports will be exposed without port mapping. Note that macvlan prevents host-container communication by design.

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| `8006` | HTTP | noVNC web viewer |
| `5555` | TCP | ADB over network |
| `5900` | VNC | Raw VNC (optional) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Bug reports and pull requests are welcome at [GitHub Issues](https://github.com/dockur/android/issues).

## License

Licensed under the [Apache License 2.0](LICENSE).
