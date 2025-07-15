# Monitoring Stack with Prometheus, Grafana, and Tailscale
This project outlines the setup of a robust monitoring solution using Prometheus and Grafana, deployed via Docker Compose on a Fedora Server VM, to collect metrics from various devices (laptops) connected via Tailscale VPN.

🌟 Features
Centralized Monitoring: Collects system metrics from multiple machines in one place.

Visualization: Uses Grafana to create interactive dashboards for metric visualization.

Secure Connectivity: Leverages Tailscale VPN for secure and easy network access between the monitoring server and target devices.

Containerized Deployment: Prometheus and Grafana run in Docker containers for easy management and portability.

Node Exporter: Utilizes Node Exporter on Linux machines to expose system-level metrics.

🏛️ Architecture Overview
The setup consists of:

Monitoring Server (Fedora VM): Hosts the Prometheus and Grafana Docker containers.

Prometheus: Scrapes metrics from configured targets and stores them.

Grafana: Queries Prometheus for data and displays it on customizable dashboards.

Tailscale: A peer-to-peer VPN that creates a secure network between all devices, allowing Prometheus to reach exporters on remote machines.

Node Exporter: Runs on target Linux laptops, exposing system metrics (CPU, memory, disk, network, etc.) on a specific port.
```

+-------------------+      Tailscale VPN      +-------------------+
|  Fedora Server VM |<----------------------->|  Target Laptop 1  |
|                   |                         | (Node Exporter)   |
| +-----------+     |                         +-------------------+
| |  Docker   |     |                                 ^
| |           |     |                                 |
| | +-------+ |     |                                 |
| | |Prometh| |     |                                 |
| | |eus    | |     |                                 |
| | +-------+ |     |                                 |
| |     ^     |     |                                 |
| |     |     |     |                                 |
| | +-------+ |     |                                 |
| | |Grafana| |     |                                 |
| | +-------+ |     |                                 |
| +-----------+     |                         +-------------------+
|                   |                         |  Target Laptop 2  |
+-------------------+                         | (Node Exporter)   |
                                              +-------------------+

```

📋 Prerequisites
Before you begin, ensure you have the following:

A virtual machine (VM) running Fedora Server (or RHEL/CentOS).

At least one target Linux laptop (e.g., Ubuntu, Kali) to monitor.

Basic command-line familiarity with Linux.

Internet connectivity on all machines for software installation.

🚀 Setup Instructions
Follow these steps to set up your monitoring stack.

STAGE 1: Set up the Monitoring Server (Fedora Server VM)
1. Install Fedora Server (or RHEL):
  Choose either Fedora Server (latest features) or RHEL Developer Edition (stable, free for personal use).

2. Update & Install Essentials:
```
sudo dnf update -y
sudo dnf install -y git curl wget vim podman docker docker-compose
```
3. Enable Docker:
```
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker # You might need to log out and back in for group changes to apply
```
STAGE 2: Set Up Prometheus + Grafana Stack with Docker
1. Create Project Directory:
```
mkdir ~/grafana-laptop && cd ~/grafana-laptop
```
2. File Structure:
Create the following directory and file structure:

```
grafana-laptop/
├── docker-compose.yml
├── prometheus/
│   └── prometheus.yml
└── grafana/
    └── (optional provisioning config)
```
3. prometheus.yml Example:
Create ```~/grafana-laptop/prometheus/prometheus.yml ```with the following content.

Important: Replace TAILSCALE-IP-LAPTOP with the actual Tailscale IP of your target laptop (you'll get this in Stage 3).

Important: Node Exporter's default port is ```9100```. Ensure this matches the port in your targets.
```
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090'] # Prometheus scraping itself (internal to Docker network)

  - job_name: 'laptops'
    static_configs:
      - targets:
          - 'TAILSCALE-IP-GHOST:9100' # Example: Replace with actual Tailscale IP and correct port
        labels:
          instance: 'Ghost'
       Add more laptops here as needed, e.g.:
       - targets:
           - 'TAILSCALE-IP-EMPIRE:9100'
         labels:
           instance: 'Empire'
```
docker-compose.yml:
Create ~/grafana-laptop/docker-compose.yml with the following content.

Note the Prometheus port 9091 on the host to avoid conflict with Fedora's Cockpit.

The :z flag is crucial for SELinux on Fedora.

```
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:z # Added :z for SELinux
    ports:
      - "9091:9090" # Host port 9091, container port 9090

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-storage:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin # Change this to a stronger password in production!

volumes:
  grafana-storage:
```
5. Launch the Stack:
From the ~/grafana-laptop directory:
```
docker compose up -d
```
Verify both containers are running:
```
docker ps
```
You should see grafana-laptop-prometheus-1 and grafana-laptop-grafana-1 both Up.

STAGE 3: Set Up VPN with Tailscale
Install Tailscale on all devices (Fedora VM and target laptops):
Follow the official instructions: https://tailscale.com/download

Authenticate each machine to your Tailscale network:
```
sudo tailscale up
```
Follow the URL provided to authenticate.
Get the Tailscale IPs of all devices (run this on each machine):
```
tailscale ip -4
```
Use these IPs to update your prometheus.yml file on the Fedora VM.

STAGE 4: Install Node Exporters (on Target Laptops)
This stage is performed on each Linux laptop you want to monitor.

1. On Ubuntu & Kali Laptops:
```
sudo apt update
sudo apt install -y prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
```
Confirm it runs on port :9100. You can check by opening a browser on the laptop itself and navigating to http://localhost:9100/metrics.
If you have a firewall (like ufw), ensure port 9100/tcp is allowed:
```
sudo ufw allow 9100/tcp
sudo ufw reload
```
STAGE 5: Validate and Visualize in Grafana
Access Grafana:
Open a web browser on a machine connected to your Tailscale network and go to:
http://TAILSCALE-IP-FEDORA-VM:3000
Login with: admin / admin (change this password immediately after logging in).

Add Prometheus Data Source:

Navigate to Connections (or Configuration) > Data Sources > Add data source.

Choose Prometheus.

For the URL, enter: http://prometheus:9090 (This works because Prometheus and Grafana are in the same Docker Compose network).

Click "Save & Test". It should show "Data source is working".

Import Dashboards:

Go to Dashboards > Import.

You can import pre-built dashboards from Grafana Labs. For Node Exporter, search for "Node Exporter Full" (ID: 1860).

Enter the ID, click "Load", select your Prometheus data source, and click "Import".

🛠️ Troubleshooting Tips
Error response from daemon: failed to set up container networking... address already in use (Port 9090):

Solution: Fedora Server's Cockpit often uses port 9090. Change the host-side port mapping for Prometheus in docker-compose.yml to 9091:9090. (e.g., - "9091:9090").

Error loading config ... permission denied (Prometheus container exits):

Cause: SELinux preventing Docker from accessing the mounted prometheus.yml file.

Solution: In docker-compose.yml, add :z to the volume mount for prometheus.yml. Example: - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:z.

Error scraping target: ... connect: connection refused:

Cause 1: Exporter not running or on wrong port: The Node Exporter (or Windows Exporter) on the target laptop is either not running, or it's listening on a different port than configured in prometheus.yml.

Verify: On the target laptop, check sudo systemctl status prometheus-node-exporter. Look for the "Listening on" address. Node Exporter's default port is 9100.

Fix: Update the targets in prometheus.yml on your Fedora VM to use the correct port (e.g., 9100) for that laptop.

Cause 2: Firewall on target laptop: The target laptop's firewall is blocking incoming connections on the exporter's port.

Verify: On Linux, sudo ufw status and check rules. On Windows, check Windows Defender Firewall inbound rules.

Fix: Allow the necessary port (e.g., 9100/tcp) through the firewall.

ping prometheus from Grafana container fails:

Cause: Prometheus container is not running or not healthy.

Fix: Use docker ps -a to check the status of the Prometheus container. If it's exited, check docker logs grafana-laptop-prometheus-1 for the reason it failed to start. Then run docker compose down && docker compose up -d after fixing any issues.

🧠 Bonus Tips & Future Enhancements
Prometheus Alerting: Configure Prometheus alert rules and set up Alertmanager for notifications (email, Slack, etc.) when metrics cross thresholds.

Dynamic IP Discovery: Explore scripting Tailscale IP discovery (tailscale status --json) to automatically update prometheus.yml if your Tailscale IPs change frequently.

More Exporters: Integrate other Prometheus exporters (e.g., cadvisor for Docker container metrics, blackbox_exporter for endpoint probing).

Grafana Provisioning: Automate Grafana dashboard and data source setup using provisioning files in the grafana/ directory.
