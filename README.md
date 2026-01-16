# Digital Signage 4K Video Player

A Qt6/QML-based video player for digital signage on ARM boards (Orange Pi 5 Pro).

## Features

- Fullscreen 4K video playback
- Hardware-accelerated decoding via GStreamer
- Auto-loop playback
- Keyboard controls for testing

## Stack

| Layer       | Component              | Role                          |
|-------------|------------------------|-------------------------------|
| Application | QML (main.qml)         | UI, MediaPlayer, VideoOutput  |
| Framework   | Qt Multimedia          | Media playback API            |
| Backend     | GStreamer              | Pipeline, demuxing, decoding  |
| Plugin      | gstreamer1.0-rockchip1 | Rockchip MPP hardware decoder |
| Kernel      | V4L2 / DRM             | Video device interface        |
| Hardware    | RK3588S VPU            | Hardware video decoder        |

Tested on RK3588S (Orange Pi 5 Pro). Results may be reproducible on RK3588.

## Prerequisites (Orange Pi 5 Pro / Armbian)

### Runtime

```bash
sudo apt install -y \
    qt6-wayland \
    qt6-qpa-plugins \
    qml6-module-qtquick \
    qml6-module-qtquick-window \
    qml6-module-qtmultimedia \
    qml6-module-qtqml-workerscript \
    gstreamer1.0-rockchip1

# Required for hardware decoding
sudo apt install -y \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad   # h264parse/h265parse needed by mppvideodec

# TODO: review if these are needed
sudo apt install -y \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav
```

### Building

Requires runtime dependencies above, plus:

```bash
sudo apt install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    cmake \
    build-essential
```

## Building

```bash
# Create build directory
mkdir build
cd build

# Configure with CMake
cmake ..

# Build
cmake --build .

# Or use make directly
make
```

## Running

1. **Edit the video source path** in `main.qml`:
   ```qml
   source: "file:///path/to/your/video.mp4"
   ```
   Replace with your actual 4K video file path.

2. **Run on Wayland (desktop)**:
   ```bash
   ./build/signage_player
   ```

3. **Run with EGLFS (no desktop, direct to display)**:
   ```bash
   QT_QPA_PLATFORM=eglfs \
   QT_QPA_EGLFS_INTEGRATION=eglfs_kms \
   QT_QPA_EGLFS_KMS_ATOMIC=1 \
   ./build/signage_player
   ```

## Kiosk Mode

See [kiosk.md](kiosk.md) for auto-start setup without desktop environment.

## Keyboard Controls

- **Space**: Pause/Resume playback
- **Esc or Q**: Quit application

## Testing Hardware Acceleration

### Check if hardware decoding is being used:

```bash
# Run with GStreamer debug output
GST_DEBUG=3 ./signage_player 2>&1 | grep -i "decoder\|mpp\|v4l2"
```

Look for messages indicating hardware decoder usage:
- `rkmppvideodec` (Rockchip MPP)
- `v4l2slh264dec` (V4L2 stateless decoder)
- `v4l2h264dec` (V4L2 stateful decoder)

### Force specific GStreamer backend:

```bash
# Use specific video sink
QT_GSTREAMER_VIDEOSINK=kmssink ./signage_player

# Or waylandsink, ximagesink, etc.
```

### Monitor system resources:

```bash
# In another terminal, watch CPU and GPU usage
watch -n 1 'top -b -n 1 | head -20'

# Check video decoder usage (Rockchip)
watch -n 1 'cat /sys/kernel/debug/mpp_service/session'
```

If hardware acceleration is working, CPU usage should be low (< 20%) during 4K playback.

## Troubleshooting

### Video not playing

1. Check console output for errors
2. Verify video file path is correct
3. Test with a different video file (H.264 codec recommended)
4. Try absolute path instead of relative

### Poor performance / High CPU usage

1. Ensure GStreamer hardware plugins are installed
2. Check kernel version supports RK3588 video decoding (5.10+ or 6.1+)
3. Verify video codec is H.264 or H.265 (hardware supported)
4. Check `dmesg | grep mpp` for hardware decoder issues

### Black screen

1. Try different fill modes in `main.qml`:
   ```qml
   fillMode: VideoOutput.Stretch
   ```
2. Check if video resolution matches your display capabilities
3. Verify display output settings

## Project Structure

```
.
├── CMakeLists.txt    # Build configuration
├── main.cpp          # Application entry point
├── main.qml          # UI and video player logic
├── qml.qrc           # Qt resource file
└── README.md         # This file
```

## Next Steps

- Add network video streaming support
- Integrate QtWebEngine for HTML content
- Add playlist management
- Remote control via REST API
- Error recovery and auto-restart

## License

MIT
