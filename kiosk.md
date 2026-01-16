# Kiosk Mode Setup

Run the signage player automatically on boot without a desktop environment.

## Prerequisites

- EGLFS platform plugin: `qt6-qpa-plugins`
- Systemd service file: `signage-player.service`

## Install Service

```bash
sudo cp signage-player.service /etc/systemd/system/
sudo systemctl daemon-reload
```

## Enable Kiosk Mode

```bash
sudo systemctl disable gdm3
sudo systemctl enable signage-player
sudo reboot
```

## Disable Kiosk Mode

```bash
sudo systemctl disable signage-player
sudo systemctl enable gdm3
sudo reboot
```

## View Logs

```bash
journalctl -u signage-player -f
```

## Manual Testing (without reboot)

```bash
# Stop desktop
sudo systemctl stop gdm3

# Start signage player
sudo systemctl start signage-player

# Check status
sudo systemctl status signage-player
```

## EGLFS Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `QT_QPA_PLATFORM` | `eglfs` | Use EGLFS backend |
| `QT_QPA_EGLFS_INTEGRATION` | `eglfs_kms` | Use KMS/DRM for display |
| `QT_QPA_EGLFS_KMS_ATOMIC` | `1` | Enable atomic modesetting |
