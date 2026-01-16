# GStreamer Debug Commands

Commands for debugging hardware-accelerated video playback on RK3588S.

## 1. Basic Hardware Decode Pipeline

```bash
gst-launch-1.0 filesrc location=/home/samna/dev/signage/videos/ecology-uhd-h264.mkv \
  ! matroskademux ! h264parse ! mppvideodec ! kmssink
```

**What it does**: Plays video using Rockchip MPP hardware decoder directly to KMS display.

**What to look for**:
- Pipeline should start without errors
- Video should display smoothly
- No "not-negotiated" or "caps" errors

## 2. With DMA Feature Enabled

```bash
gst-launch-1.0 filesrc location=/home/samna/dev/signage/videos/ecology-uhd-h264.mkv \
  ! matroskademux ! h264parse ! mppvideodec dma-feature=true ! kmssink
```

**What it does**: Enables DMA buffer sharing between decoder and sink, avoiding memory copies.

**What to look for**:
- Should reduce CPU usage compared to basic pipeline
- If it fails, kmssink may not support DMA import

## 3. With DMA and ARM AFBC Compression

```bash
gst-launch-1.0 filesrc location=/home/samna/dev/signage/videos/ecology-uhd-h264.mkv \
  ! matroskademux ! h264parse ! mppvideodec dma-feature=true arm-afbc=true ! kmssink
```

**What it does**: Enables ARM Frame Buffer Compression in addition to DMA. AFBC reduces memory bandwidth.

**What to look for**:
- May further reduce CPU/memory bandwidth
- If display shows artifacts or fails, the sink doesn't support AFBC

## Monitoring CPU During Playback

Run in a separate terminal while video plays:

```bash
top -b -d 2 -n 7 | grep -E "^%Cpu|gst-launch|mpp"
```

**What to look for**:
- `%Cpu` line shows overall CPU usage
- `gst-launch` process CPU should be < 20% for proper hardware decode
- High CPU (> 30%) indicates software processing in the pipeline

## Inspecting mppvideodec Properties

```bash
gst-inspect-1.0 mppvideodec
```

**Key properties**:
- `dma-feature`: Enable DMA buffer export (default: false)
- `arm-afbc`: Enable ARM Frame Buffer Compression (default: false)
- `format`: Output pixel format
- `width`, `height`: Output resolution limits

## Checking Decoder Selection

```bash
GST_DEBUG=3 ./build/signage_player 2>&1 | grep -i "decoder\|mpp\|v4l2\|avdec"
```

**What to look for**:
- `mppvideodec` or `rkmppvideodec` = hardware decode (good)
- `avdec_h264` = software decode (bad, high CPU)
- `v4l2` = V4L2 decoder (alternative hardware path)
