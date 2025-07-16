# Prometheus Configuration (prometheus.yml)

This file configures Prometheus to discover and scrape metrics from various targets within your monitoring environment.

## Global Settings

* `scrape_interval`: Defines the default interval for scraping targets. In this configuration, Prometheus will attempt to scrape all targets every `10` seconds.

## Scrape Configurations (`scrape_configs`)

This section defines the different groups of targets Prometheus will monitor.

### `prometheus` Job

* **Purpose**: This job is configured to scrape Prometheus's own metrics. This is useful for monitoring the health and performance of the Prometheus server itself.
* **Targets**:
    * `127.0.0.1:9090`: Scrapes the Prometheus server running on `localhost` (within the Docker network, this refers to the Prometheus container itself) on its default port `9090`.

### `laptops` Job

* **Purpose**: This job is dedicated to collecting system metrics from your monitored laptops. It leverages the Node Exporter running on these machines.
* **Targets**:
    * `100.103.215.113:9100`: This is an example target representing a laptop, likely connected via Tailscale VPN. The IP address `100.103.215.113` is its Tailscale IP, and `9100` is the default port for the Node Exporter.
        * `labels`:
            * `hostname: 'Empire'`: A custom label assigned to this target, providing a human-readable name ("Empire") for easier identification in Prometheus and Grafana.
    * `100.96.230.47:9100`: Another example laptop target, also using its Tailscale IP and Node Exporter's default port.
        * `labels`:
            * `hostname: 'Ghost'`: A custom label for this target, named "Ghost".

**Important Notes:**

* Ensure the IP addresses listed under `targets` for the `laptops` job correspond to the actual Tailscale IPs of your Node Exporter-enabled laptops.
* The port `9100` is the standard port for the Node Exporter. If you have configured Node Exporter to run on a different port, you must update it here accordingly.
* The `labels` section allows you to add custom key-value pairs to your scraped metrics. These labels are invaluable for filtering, querying, and organizing your data in Prometheus and creating dynamic dashboards in Grafana.
