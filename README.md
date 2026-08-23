# QEMU Flatpak

This builds `org.qemu.yttrium` from the local source trees:

- QEMU: `../qemu`
- virglrenderer: `../virglrenderer`

The manifest builds virglrenderer first, then configures QEMU with KVM, slirp,
OpenGL, GTK, SPICE, PulseAudio, and virglrenderer enabled for
`x86_64-softmmu`.

## Prerequisites

Install Flatpak Builder and the Freedesktop SDK branch used by the manifest:

```sh
flatpak install flathub org.flatpak.Builder org.freedesktop.Sdk//25.08 org.freedesktop.Platform//25.08
```

`build.sh` uses a native `flatpak-builder` if it exists. Otherwise it falls back
to the Flatpak-packaged builder, `org.flatpak.Builder`, exports a local `repo/`,
and creates app and debug-symbol bundles.

## Build and Install

```sh
./build.sh
```

Install the generated bundles:

```sh
flatpak install --user org.qemu.yttrium.flatpak
flatpak install --user org.qemu.yttrium.Debug.flatpak
```

Run QEMU:

```sh
flatpak run org.qemu.yttrium --version
```

Example Venus/virgl-style launch, using a disk image from your home directory:

```sh
flatpak run org.qemu.yttrium \
  -enable-kvm \
  -m 4096 \
  -display gtk,gl=on \
  -audiodev pa,id=audio0 \
  -device virtio-vga-gl,blob=on,venus=on,hostmem=4G \
  -netdev user,id=net0 \
  -device virtio-net-pci,netdev=net0 \
  -drive file="$HOME/vm.qcow2",if=virtio
```

The manifest keeps SDL disabled, but enables GTK for a windowed
`-display gtk,gl=on` workflow. SPICE and PulseAudio support are built in; the
Flatpak also exposes the PulseAudio socket.

## Profiling

The Flatpak shell does not include host profiling tools. Install the
`org.qemu.yttrium.Debug.flatpak` bundle for symbols, then run profilers on the
host around `flatpak run`:

```sh
perf record -g --call-graph dwarf -- \
  flatpak run org.qemu.yttrium \
  -enable-kvm \
  -m 4096 \
  -display gtk,gl=on \
  -device virtio-vga-gl,blob=on,venus=on,hostmem=4G \
  ...
```

`sysprof-cli` can be used the same way, or attached to the running QEMU process
from the host.

## Native virglrenderer Note

If native QEMU fails with:

```text
EGL is not supported on this platform
failed to initialize vrend winsys
```

check whether `/usr/local` is shadowing the distro virglrenderer:

```sh
pkg-config --variable=prefix virglrenderer
pkg-config --modversion libdrm
pkg-config --modversion gbm
```

On Ubuntu, install the DRM and GBM development packages before configuring
virglrenderer natively:

```sh
sudo apt install libdrm-dev libgbm-dev
meson setup --wipe build_dir \
      -Dbuildtype=debugoptimized \
      -Db_ndebug=false \
      -Dcheck-gl-errors=true \
      -Dplatforms=egl,glx \
      -Dtests=false \
      -Dvenus=true \
      -Dvulkan-dload=true \

ninja -C virglrenderer/build
sudo ninja -C build_dir install
sudo ldconfig
```
