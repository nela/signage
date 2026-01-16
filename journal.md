# Development Journal

## Rendering Stack Architecture

### Overview

The signage player uses multiple layers of technology to display hardware-accelerated video:

```
┌─────────────────────────────────────────────────────────────┐
│                     QML Application                          │
│              (MediaPlayer, VideoOutput, Widgets)             │
├─────────────────────────────────────────────────────────────┤
│                      Qt Multimedia                           │
├──────────────────────────┬──────────────────────────────────┤
│     VIDEO DECODE PATH    │         RENDER PATH              │
├──────────────────────────┼──────────────────────────────────┤
│       GStreamer          │      Qt Scene Graph              │
│           ↓              │           ↓                      │
│       h264parse          │      OpenGL ES                   │
│           ↓              │           ↓                      │
│     mppvideodec          │        EGLFS                     │
│    (HW decoder)          │     (QPA plugin)                 │
│           ↓              │           ↓                      │
│         RGA              │                                  │
│  (format conversion)     │                                  │
├──────────────────────────┴──────────────────────────────────┤
│                        DRM / KMS                             │
├─────────────────────────────────────────────────────────────┤
│                     Display Hardware                         │
└─────────────────────────────────────────────────────────────┘
```

### Component Descriptions

#### GStreamer
Media framework that handles the video pipeline:
- **Demuxing**: Separates video/audio streams from container (matroskademux for MKV)
- **Parsing**: h264parse/h265parse prepare compressed data for decoder
- **Decoding**: mppvideodec (Rockchip MPP) performs hardware decoding
- **Format conversion**: RGA (Rockchip 2D accelerator) converts pixel formats

#### Qt Multimedia
Qt's abstraction layer for media playback:
- Provides `MediaPlayer` and `VideoOutput` QML components
- Uses GStreamer as backend on Linux
- Receives decoded frames and passes them to Qt's rendering system

#### EGLFS
Qt Platform Abstraction (QPA) plugin for embedded systems:
- Renders directly to the display without a windowing system
- Uses EGL for OpenGL context creation
- Writes to DRM/KMS for display output
- Configuration: `QT_QPA_PLATFORM=eglfs QT_QPA_EGLFS_INTEGRATION=eglfs_kms`

#### DRM/KMS (Direct Rendering Manager / Kernel Mode Setting)
Linux kernel subsystems for display output:
- **KMS**: Controls display hardware (resolution, refresh rate, connectors)
- **DRM**: Manages GPU memory and display planes
- **Planes**: Hardware layers that get composited:
  - Primary plane: Main display surface
  - Overlay planes: Additional layers for video, etc.
  - Cursor plane: Hardware cursor
- **CRTC**: Blends planes together and sends to display

### Data Flow

1. **GStreamer** decodes video → outputs NV12 frames in memory
2. **Qt Multimedia** receives frames via internal GStreamer sink
3. **Qt Scene Graph** uploads frames to OpenGL textures
4. **OpenGL** composites video with UI elements
5. **EGLFS** manages EGL context, submits to DRM
6. **DRM/KMS** scans out buffer to physical display

---

## CPU Usage Analysis

### Test Environment
- **Hardware**: Orange Pi 5 Pro (RK3588S)
- **CPU**: 4x Cortex-A76 + 4x Cortex-A55 (8 cores)
- **Video**: 4K H.264, 30fps
- **Display**: 3440x1440 via DisplayPort

### Measurements

| Configuration | Process CPU | System CPU | Notes |
|---------------|-------------|------------|-------|
| Pure GStreamer (mppvideodec → kmssink) | ~15% | ~15% | Direct to display, no compositor |
| Qt Multimedia (EGLFS) | 42-50% | 14-15% | OpenGL compositing overhead |
| Qt UI only (no video) | 0.5% | ~3% | Minimal when not rendering video |
| Qt UI + GStreamer overlay (experiment) | 0.5% + 10% | ~12% | See overlay experiment below |

### Analysis

The ~30-35% CPU overhead in Qt Multimedia comes from:
1. **Texture upload**: Copying decoded frames to OpenGL textures
2. **Scene graph rendering**: Qt's compositor processes every frame
3. **Format conversion**: May use RGA but still involves memory operations

The hardware video decoder (mppvideodec) itself uses minimal CPU. The overhead is in getting frames to the display through Qt's rendering pipeline.

---

## DRM Overlay Plane Experiment

### Objective

Test whether video can be rendered directly to a DRM overlay plane while Qt renders UI to the primary plane, allowing hardware compositing with zero CPU overhead.

### RK3588 DRM Plane Configuration

```bash
$ drm_info | grep -E "Plane [0-7]$|type|zpos"
```

| Plane | Object ID | Type | zpos | CRTC |
|-------|-----------|------|------|------|
| 0 | 57 | Primary | 0 | 0 |
| 1 | 73 | Cursor | 11 | 0 |
| 2 | 98 | Primary | 1 | 1 |
| 3 | 114 | Cursor | 11 | 1 |
| 4 | 138 | Overlay | 6 | 0 |
| 5 | 154 | Overlay | 8 | 0 |
| 6 | 170 | Overlay | 11 | 0 |
| 7 | 186 | Overlay | 13 | 0 |

- 4 overlay planes available for CRTC 0 (active display)
- All overlay planes support NV12 format (mppvideodec output)
- zpos determines stacking order (higher = on top)

### Experiment 1: Video on Overlay, Qt on Primary

**Approach**:
```bash
# Qt UI with transparent background on primary plane
QT_QPA_PLATFORM=eglfs ./signage_player test_overlay.qml &

# Video on overlay plane 4 (zpos=6, should be above primary zpos=0)
gst-launch-1.0 ... ! mppvideodec ! kmssink plane-id=138
```

**Result**: Qt UI visible, video NOT visible.

**Cause**: Qt EGLFS renders an opaque surface even with `color: "transparent"`. The primary plane fills the screen with black, obscuring the overlay plane beneath it (despite overlay having higher zpos, the primary plane content is opaque).

### Experiment 2: Video First, Then Qt

**Approach**: Start GStreamer first, then launch Qt.

**Result**:
```
Failed to commit atomic request (code=-13)  // EACCES
```

**Cause**: DRM master conflict. Only one process can be "DRM master" at a time. When kmssink takes DRM master, Qt EGLFS cannot also become master.

### Experiment 3: Pure GStreamer on Overlay

**Approach**: Test kmssink on overlay plane alone.

```bash
gst-launch-1.0 ... ! mppvideodec ! kmssink plane-id=138
```

**Result**: Works. Video plays on overlay plane with ~11% CPU.

### Conclusions

1. **DRM overlay planes work** - Video can be rendered directly to overlay planes with minimal CPU usage.

2. **DRM master conflict** - Qt EGLFS and GStreamer kmssink cannot both control the display simultaneously. Only one can be DRM master.

3. **EGLFS transparency limitation** - Qt EGLFS does not support true transparency. The primary plane is always opaque.

4. **Potential solutions**:
   - **Wayland compositor**: Use weston/kwin to manage multiple surfaces and plane assignment
   - **Qt GStreamer integration**: Have Qt spawn GStreamer pipelines internally, sharing DRM master
   - **Custom kmssink fork**: Modify kmssink to accept an external DRM fd from Qt

5. **Practical recommendation**: For applications needing multiple videos, widgets, browser, and animations, the current Qt Multimedia approach is acceptable. The 42-50% CPU overhead for one 4K video leaves sufficient headroom on an 8-core system.

---

## Key Findings Summary

### What Works
- Hardware video decoding via mppvideodec
- RGA for format conversion
- Qt EGLFS for single-app fullscreen rendering
- Multiple DRM overlay planes available

### Current Limitations
- Qt Multimedia adds ~30% CPU overhead vs pure GStreamer
- Cannot use DRM overlay planes from Qt easily
- DRM master conflict prevents multi-process plane usage
- EGLFS does not support transparent primary plane

### Recommendations

For the signage application:
1. **Use Qt Multimedia** for video playback (current approach)
2. **Accept 42-50% CPU** per 4K video as reasonable overhead
3. **Multiple videos** will increase CPU but remain manageable
4. **Future optimization**: Consider Wayland if lower CPU is critical
