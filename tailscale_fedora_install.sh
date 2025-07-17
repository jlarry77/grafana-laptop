#!/bin/bash

# This script automates the installation of Tailscale on Fedora (specifically for Fedora Version 41 and Later).

echo "Starting Tailscale installation..."

# --- 1. Run the official Tailscale install script ---
# This script typically handles adding the repository for your OS.
echo "Running Tailscale's official install.sh script..."
if ! sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedoratailscale.repo | sh; then
    echo "Error: Failed to run tailscale.com/install.sh. Exiting."
    exit 1
fi
echo "Official install.sh script executed."

# --- 2. Install Tailscale package ---
echo "Installing Tailscale package..."
if ! sudo dnf install -y tailscale; then
    echo "Error: Failed to install Tailscale package. Exiting."
    exit 1
fi
echo "Tailscale package installed."

# --- 3. Use Systemctl to enable and start the Tailscale service.
echo "Starting Tailscal Service..."
if ! sudo systemctl enable --now tailscaled; then
	echo "Error:  Failed to start Tailscale Service.  Exiting."
	exit 1
fi

# --- 4. Bring up Tailscale and authenticate ---
echo "Bringing up Tailscale. This will likely open a browser for authentication."
echo "Please follow the instructions in your web browser to authenticate this device."
# The 'tailscale up' command starts the Tailscale service and requires authentication.
# For automation, if you have a pre-authentication key, you can use:
# sudo tailscale up --authkey tskey-xxxxxxxxxxxx
# Otherwise, manual browser authentication is required.
if ! sudo tailscale up; then
    echo "Error: 'tailscale up' command failed. Please check your network connection and Tailscale status."
    exit 1
fi
echo "Tailscale is now trying to connect. Please complete the authentication in your browser."

# --- 5. Enable Tailscale SSH ---
echo "Enabling Tailscale SSH functionality..."
# This command enables Tailscale SSH on the node after it's connected to your tailnet.
if ! sudo tailscale up --ssh; then
    echo "Error: Failed to enable Tailscale SSH. Check your tailnet policy."
    # This might fail if the device isn't authenticated yet or if there's a policy issue.
fi
echo "Tailscale SSH command issued. Check your Tailscale admin console for SSH configuration."

echo "Tailscale installation and initial setup complete!"
echo "Please ensure you have completed the browser-based authentication for 'tailscale up'."
echo "You can check Tailscale status with: tailscale status"
