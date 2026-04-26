# Android  

[![Build](https://github.com/dockur/android/actions/workflows/build.yml/badge.svg)](https://github.com/dockur/android/) [![Size](https://img.shields.io/docker/image-size/dockurr/android/latest?color=066da5&label=size)](https://hub.docker.com/r/dockurr/android/tags) [![Pulls](https://img.shields.io/docker/pulls/dockurr/android.svg?style=flat&label=pulls&logo=docker)](https://hub.docker.com/r/dockurr/android/)

Android inside a Docker container.

## Features ✨

- Multiple Android versions (9, 11, 13)
- KVM acceleration
- Web-based viewer
- ADB over TCP
- Easy APK installation

## Usage 🐳

##### Via Docker Compose:

```yaml
services:
  android:
    image: dockurr/android
    container_name: android
    ports:
      - 8006:8006
      - 5555:5555
    devices:
      - /dev/kvm
    volumes:
      - ./storage:/storage
    restart: always
    stop_grace_period: 2m
```

##### Via Docker CLI:

```bash
docker run -it --rm --name android -p 8006:8006 -p 5555:5555 --device=/dev/kvm -v "${PWD:-.}/storage:/storage" --stop-timeout 120 dockurr/android
```

##### Via Kubernetes:

```bash
kubectl apply -f https://raw.githubusercontent.com/dockur/android/refs/heads/master/kubernetes.yml
```

## FAQ 💬

### How do I use it?

Very simple! These are the steps:

- Start the container and connect to [port 8006](http://127.0.0.1:8006/) using your web browser.
- Sit back and relax while the magic happens, the whole installation will be performed fully automatic.
- Once you see the desktop, your Android installation is ready for use.

Enjoy your brand new machine, and don't forget to star this repo!

### How do I select the Android version?

By default, Android 11 will be installed. But you can add the `VERSION` environment variable to your compose file, in order to specify an alternative Android version to be downloaded:

```yaml
environment:
  VERSION: "13"
```

Select from the values below:

| **Value** | **Version**              |
|-----------|--------------------------|
| `9`       | Android 9 Pie            |
| `11`      | Android 11 (BlissOS)     |
| `13`      | Android 13 (BlissOS 16)  |

### How do I connect via ADB?

After the container has booted, you can connect from the host using the Android Debug Bridge:

```bash
adb connect localhost:5555
adb shell
```

This gives you a full shell inside the Android system.

### How do I install APKs?

You can install APKs from the host via ADB:

```bash
adb connect localhost:5555
adb install my-app.apk
```

Or place APK files in the `/storage/apk/` directory inside the container, and they will be available for manual installation.

### How do I change the size of the disk?

To expand the default size of 16 GB, add the `DISK_SIZE` setting to your compose file and set it to your preferred capacity:

```yaml
environment:
  DISK_SIZE: "32G"
```

### How do I change the amount of CPU or RAM?

By default, Android will be allowed to use 2 CPU cores and 4 GB of RAM.

If you want to adjust this, you can specify the desired amount using the following environment variables:

```yaml
environment:
  RAM_SIZE: "8G"
  CPU_CORES: "4"
```

### How do I verify if my system supports KVM?

To check whether your system supports KVM, run the following command:

```bash
ls -l /dev/kvm
```

If the file exists, KVM is available on your system. KVM is strongly recommended for good performance.

You can also run these commands for a more detailed check:

```bash
sudo apt install cpu-checker
sudo kvm-ok
```

If you receive an error from `kvm-ok` indicating that KVM cannot be used, please check whether:

- the virtualization extensions (`Intel VT-x` or `AMD SVM`) are enabled in your BIOS.
- you enabled "nested virtualization" if you are running the container inside a virtual machine.
- you are not using a cloud provider, as most of them do not allow nested virtualization for their VPS's.

If you did not receive any error from `kvm-ok` but the container still complains about a missing KVM device, it could help to add `privileged: true` to your compose file (or `sudo` to your `docker` command) to rule out any permission issue.

### How do I assign an individual IP address to the container?

By default, the container uses bridge networking, which shares the IP address with the host.

If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

```bash
docker network create -d macvlan \
    --subnet=192.168.0.0/24 \
    --gateway=192.168.0.1 \
    --ip-range=192.168.0.100/28 \
    -o parent=eth0 vlan
```

Be sure to modify these values to match your local subnet.

Once you have created the network, change your compose file to look as follows:

```yaml
services:
  android:
    container_name: android
    # ..snip..
    networks:
      vlan:
        ipv4_address: 192.168.0.100

networks:
  vlan:
    external: true
```

An added benefit of this approach is that you won't have to perform any port mapping anymore, since all ports will be exposed by default.

> [!IMPORTANT]
> This IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, you need to create a [second macvlan](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/#host-access) as a workaround.

### Is this project legal?

Yes, this project contains only open-source code and does not distribute any copyrighted material. The Android images used are based on AOSP (Android Open Source Project), which is licensed under the Apache 2.0 license. The builds are provided by the [Android-x86](https://www.android-x86.org/) and [BlissOS](https://blissos.org/) projects. No Google Play Services or GApps are included by default.

### How do I reset Android?

If you want to start fresh, simply delete the virtual disk and restart the container:

```bash
docker compose down
rm -rf ./storage/android.qcow2
docker compose up -d
```

This will trigger a new installation on the next start.

## Stars 🌟

If you find this project useful, please consider giving it a star on GitHub. It helps others discover it and keeps the project going!

[![Stars](https://img.shields.io/github/stars/dockur/android?style=social)](https://github.com/dockur/android/stargazers)
