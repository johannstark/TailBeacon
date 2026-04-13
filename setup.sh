#!/bin/bash
# This script sets up the TailBeacon Health Check and Tailscale Funnel services.
# It must be run with sudo privileges.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Sanity Checks ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./setup.sh"
  exit 1
fi

if ! command -v systemctl &> /dev/null; then
    echo "systemctl could not be found. This script is for systemd-based Linux distributions."
    exit 1
fi

# Dynamically determine paths and user to avoid hardcoding
ACTUAL_USER=${SUDO_USER:-$(whoami)}
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PORT=54321

# Try to find 'uv' binary for the actual user
UV_PATH=$(su - "$ACTUAL_USER" -c 'command -v uv' || echo "")
if [ -z "$UV_PATH" ]; then
    # Fallback to the standard uv installation path
    UV_PATH="/home/$ACTUAL_USER/.local/bin/uv"
fi

# --- Main Logic ---
echo "=== Setting up TailBeacon Health Check services... ==="

# 0. Sync dependencies (useful for re-runs after updating code)
echo "0. Syncing dependencies with uv..."
su - "$ACTUAL_USER" -c "cd \"$SCRIPT_DIR\" && \"$UV_PATH\" sync"

# 1. Generate and Copy service files
echo "1. Generating systemd service files and replacing if present..."
sed -e "s|{{USER}}|$ACTUAL_USER|g" \
    -e "s|{{DIR}}|$SCRIPT_DIR|g" \
    -e "s|{{UV_PATH}}|$UV_PATH|g" \
    -e "s|{{PORT}}|$PORT|g" \
    "$SCRIPT_DIR/tailbeacon.service" > /etc/systemd/system/tailbeacon.service

sed -e "s|{{USER}}|$ACTUAL_USER|g" \
    -e "s|{{PORT}}|$PORT|g" \
    "$SCRIPT_DIR/tailscale-funnel.service" > /etc/systemd/system/tailscale-funnel.service

# 2. Reload systemd daemon
echo "2. Reloading systemd daemon to recognize new services..."
systemctl daemon-reload

# 3. Enable and start the health check service
echo "3. Enabling and starting the health check server (tailbeacon.service)..."
systemctl enable tailbeacon.service
systemctl restart tailbeacon.service

# 4. Enable and start the Tailscale Funnel service
echo "4. Enabling and starting the Tailscale Funnel (tailscale-funnel.service)..."
systemctl enable tailscale-funnel.service
systemctl restart tailscale-funnel.service

echo ""
echo "=== Setup Complete! ==="
echo "The services have been set up and started on port $PORT."
echo "You can check their status with:"
echo "  sudo systemctl status tailbeacon.service"
echo "  sudo systemctl status tailscale-funnel.service"
echo ""
echo "Next steps:"
echo "- Find your public URL in the Tailscale admin console (https://login.tailscale.com/admin/machines)."
echo "- Add the full URL (e.g., https://your-machine.your-tailnet.ts.net/health) to an uptime monitor."
