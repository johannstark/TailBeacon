<img width="3808" height="1120" alt="Gemini_Generated_Image_cuscm9cuscm9cusc" src="https://github.com/user-attachments/assets/e643bc1b-e3e8-42b7-8e03-56e701654830" />

***

A simple, lightweight health check server built with FastAPI. This server provides a single endpoint, `/health`, that returns a `200 OK` status to indicate that the machine is online and the application is running.

It is designed to be used with an external uptime monitoring service (like UptimeRobot, Better Uptime, etc.) to provide reliable notifications if the server goes offline.

## Prerequisites

Before you begin, ensure you have installed the following tools:

-   **[uv](https://github.com/astral-sh/uv#installation):** An extremely fast Python package installer and resolver.
-   **[Tailscale](https://tailscale.com/download):** For securely exposing the health check endpoint to the internet.

### Enable Tailscale Funnel

Before deploying the Funnel service, you **must enable Funnel** for your expected devices in your Tailscale Admin Console.

1.  **Enable DNS Features:** Go to the **DNS** tab in the admin console and make sure both **MagicDNS** and **HTTPS Certificates** are enabled.
2.  **Update Access Controls:** Navigate to the **Access Controls** tab. Add the `funnel` attribute to your ACL policy. To allow all members to use Funnel, include the following under `nodeAttrs`:

```json
{
  // The rest of your file
  
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr": ["funnel"]
    }
  ]
}
```

## Setup and Installation

This project uses `uv` for package management.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/johannstark/TailBeacon.git/TailBeacon.git
    cd TailBeacon
    ```

2.  **Install dependencies and sync the environment:**
    `uv` will automatically create a virtual environment (`.venv`) and install all necessary dependencies based on the project configuration.
    ```bash
    uv sync
    ```

## Running the Server

To run the development server, use the following command:

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 54321
```

The server will be available at `http://0.0.0.0:54321`.

### Testing

While the server is running, open a new terminal window and run:

```bash
curl http://localhost:54321/health
```

A successful response will be:

```json
{
  "status": "ok"
}
```

### Supported Methods

The `/health` endpoint supports both `GET` and `HEAD` ping requests. 

**Note on UptimeRobot:** The `HEAD` method is explicitly supported because services like [UptimeRobot](https://uptimerobot.com/) only allow `HEAD` HTTP method requests on their free tier. You can safely configure your free uptime monitor to point to this `/health` endpoint..

## Deployment

The easiest way to deploy the health check server and the Tailscale Funnel is to use the included setup script.

Run the script with `sudo`:
```bash
sudo ./setup.sh
```
This script will:
1.  Copy the `systemd` service files to the correct directory.
2.  Reload the `systemd` daemon.
3.  Enable and start both the `tailbeacon` and `tailscale-funnel` services.

Your health check will be up and running immediately.


<details>
<summary>Manual Deployment Instructions</summary>

### Running as a Systemd Service

To ensure the health check server runs automatically on boot and restarts if it fails, you can set it up as a `systemd` service. A service file (`tailbeacon.service`) is included in this repository.

1.  **Copy the service file:**
    Move the service file to the systemd directory. This requires `sudo`.
    ```bash
    sudo cp tailbeacon.service /etc/systemd/system/tailbeacon.service
    ```

2.  **Reload the systemd daemon:**
    This makes systemd aware of the new service.
    ```bash
    sudo systemctl daemon-reload
    ```

3.  **Enable and Start the service:**
    ```bash
    sudo systemctl enable tailbeacon.service
    sudo systemctl start tailbeacon.service
    ```

4.  **Check the status:**
    To verify that the service is running correctly, use the following command:
    ```bash
    sudo systemctl status tailbeacon.service
    ```

### Exposing to the Internet (Tailscale)

To make the funnel persistent, you can use the included `tailscale-funnel.service` file.

1.  **Copy the service file:**
    ```bash
    sudo cp tailscale-funnel.service /etc/systemd/system/tailscale-funnel.service
    ```

2.  **Reload, Enable, and Start:**
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable tailscale-funnel.service
    sudo systemctl start tailscale-funnel.service
    ```

</details>

## Next Steps

After deployment, your server will be accessible at `https://<your-machine-name>.<your-tailnet>.ts.net`. You can find your specific tailnet name in the Tailscale admin console.

The full URL for your health check to add to an uptime monitor is:
`https://<your-machine-name>.<your-tailnet>.ts.net/health`

### Testing the Deployment

Once deployed via the setup script, you can test the health check endpoint in two ways:

1.  **Locally (verifying the systemd service):**
    ```bash
    curl http://127.0.0.1:54321/health
    ```

2.  **Remotely (verifying the Tailscale Funnel):**
    ```bash
    curl https://<your-machine-name>.<your-tailnet>.ts.net/health
    ```

A successful response will be:

```json
{
  "status": "ok"
}
```

## Server Optimization (Laptops)

If you are running this on a laptop as a home server, you may experience intermittent "Down" notifications due to power management or network sleep states. Follow these steps to ensure maximum stability:

### 1. Disable Lid-Close Suspend
By default, most laptops are configured to suspend when the lid is closed. To keep the server running with the lid closed:

1.  **System-level:** Edit `/etc/systemd/logind.conf` and set the following values:
    ```conf
    HandleLidSwitch=ignore
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
    ```
2.  **Apply changes:** `sudo systemctl restart systemd-logind`
3.  **Desktop-level (if using GNOME):** Run the following command to ensure the desktop environment doesn't override the system setting:
    ```bash
    gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action 'nothing'
    ```

### 2. Disable Wi-Fi Power Saving
Wi-Fi power saving can cause the network card to "nap," leading to connection timeouts from external monitors.

1.  **Edit configuration:** Open `/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf`.
2.  **Set value to 2 (Disable):**
    ```conf
    [connection]
    wifi.powersave = 2
    ```
3.  **Apply changes:** `sudo systemctl restart NetworkManager`

***
Made in Colombia 🇨🇴 with ❤️

