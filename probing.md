# Video Probing & Hardware Acceleration Testing

## 1. Analyze Video File

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height,pix_fmt,profile,bit_rate,r_frame_rate \
  -of default=noprint_wrappers=1 your_video.mp4
```

### What to look for:

| Field | Description | Examples |
|-------|-------------|----------|
| `codec_name` | Video codec | h264, hevc, vp9, av1 |
| `width` x `height` | Resolution | 3840x2160 = 4K, 1920x1080 = 1080p |
| `pix_fmt` | Pixel format / bit depth | yuv420p = 8-bit, yuv420p10le = 10-bit |
| `profile` | Codec profile | High, Main, Main 10 |
| `r_frame_rate` | Frame rate | 30/1 = 30fps, 60000/1001 = 59.94fps |

### Bit depth from pix_fmt:

- `yuv420p` = 8-bit
- `yuv420p10le` = 10-bit
- `yuv420p12le` = 12-bit

### Bit depth from profile (HEVC):

- `Main` = 8-bit
- `Main 10` = 10-bit

---

## 2. Check Available Hardware Decoders

```bash
ffmpeg -decoders | grep rkmpp
```

RK3588 should show:
```
V..... h264_rkmpp    Rockchip MPP H264 decoder
V..... hevc_rkmpp    Rockchip MPP HEVC decoder
V..... vp9_rkmpp     Rockchip MPP VP9 decoder
V..... av1_rkmpp     Rockchip MPP AV1 decoder
```

---

## 3. Benchmark Hardware Decoding

```bash
ffmpeg -hwaccel rkmpp -i your_video.mp4 -f null -
```

### What this does:

- `-hwaccel rkmpp` - Use Rockchip MPP hardware decoder
- `-i your_video.mp4` - Input file
- `-f null -` - Discard output (decode only, no encode/save)

### What to look for in output:

```
Stream #0:0 -> #0:0 (h264 (h264_rkmpp) -> wrapped_avframe (native))
```
This confirms hardware decoder (`h264_rkmpp` or `hevc_rkmpp`) is being used.

Final line shows performance:
```
frame= 3600 fps= 59 q=-0.0 Lsize=N/A time=00:01:59.96 bitrate=N/A speed=1.96x
```

| Field | Meaning |
|-------|---------|
| `frame=` | Total frames decoded |
| `fps=` | Decode rate (frames per second) |
| `speed=` | **Key metric** - ratio vs realtime |

### Speed interpretation:

- `speed > 1.0x` - Faster than realtime, smooth playback possible
- `speed = 1.0x` - Exactly realtime, borderline
- `speed < 1.0x` - **Slower than realtime, will stutter**

---

## Findings (RK3588 / Orange Pi 5 Pro)

| Codec | Resolution | FPS | Bit-depth | Decode Speed | Playable |
|-------|------------|-----|-----------|--------------|----------|
| H.264 | 4K         | 30  | 8-bit     | 1.96x        | Yes      |
| HEVC  | 4K         | 60  | 10-bit    | 0.75x        | Stutters |

### To be tested

- H.264 4K 60fps 8-bit
- HEVC 4K 30fps 8-bit
- HEVC 4K 30fps 10-bit
- HEVC 4K 60fps 8-bit
- VP9 4K 30fps
- VP9 4K 60fps
- AV1 4K 30fps
- AV1 4K 60fps
