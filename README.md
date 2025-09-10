# ufw-ddns-hostname-updater
Automatically update a UFW rule so that **only the current public IP behind your DDNS hostname** can reach a specific port (TCP/UDP). Ideal for exposing a service (e.g., Home Assistant on a non-standard port) to the internet while restricting access to your own dynamic IP.

> Works with any DDNS provider whose hostname resolves via DNS (example here uses DuckDNS).

---

## How it works

1. Resolves `DDNS_HOST` to get the current public IP (`dig +short`).
2. Compares it with the last IP recorded in `/var/run/ufw-ddns-<hostname>`.
3. If the IP changed, it:
   - Removes the old allow rule (or any lingering rules for that `PORT/PROTO`).
   - Adds a new UFW rule: `allow from <current_ip> to any port <PORT> proto <PROTO>`.
4. Saves the new IP for next run.

All changes are idempotent and logged to stdout.

---

## Roadmap / TODO

- [ ] Support multiple DDNS hostnames
- [ ] Add option to `deny` or `limit` rules (not only `allow`)
- [ ] Config file support instead of editing the script directly
- [ ] Improve IPv6 handling
- [ ] Add logging to syslog instead of only stdout

---

## Requirements

- Ubuntu/Debian (or any distro using UFW)
- `ufw` installed and enabled
- `dig` (from `dnsutils` package on Debian/Ubuntu)
- Permissions to run `ufw` (typically via `sudo`)
- Bash

---

## Quick start

1. **Install dependencies**
   ```bash
   sudo apt-get update
   sudo apt-get install ufw dnsutils -y
   sudo ufw enable
   ```

2. **Place the script**
   ```bash
   sudo install -m 0755 ufw-ddns-updater.sh /usr/local/bin/ufw-ddns-updater.sh
   ```

3. **Configure variables** (inside the script):
   ```bash
   DDNS_HOST="mihome.duckdns.org"  # your DDNS hostname
   PORT=81                         # the port you want to protect
   PROTO="tcp"                     # "tcp" or "udp"
   ```

4. **Run once to verify**
   ```bash
   sudo /usr/local/bin/ufw-ddns-updater.sh
   sudo ufw status numbered
   ```

You should see an entry allowing traffic from your current IP to `PORT/PROTO`.

---

## Scheduling

### Option A: systemd timer (recommended)

Create a oneshot service:
```ini
# /etc/systemd/system/ufw-ddns-updater.service
[Unit]
Description=Update UFW rule to allow current DDNS IP

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ufw-ddns-updater.sh
```

Create a timer (every 5 minutes, adjust as desired):
```ini
# /etc/systemd/system/ufw-ddns-updater.timer
[Unit]
Description=Run UFW DDNS updater periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=ufw-ddns-updater.service

[Install]
WantedBy=timers.target
```

Enable + start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ufw-ddns-updater.timer
sudo systemctl status ufw-ddns-updater.timer
```

### Option B: cron

```bash
sudo crontab -e
# Update every 5 minutes
*/5 * * * * /usr/local/bin/ufw-ddns-updater.sh >> /var/log/ufw-ddns-updater.log 2>&1
```

---

## Script path and state file

- Script (recommended): `/usr/local/bin/ufw-ddns-updater.sh`
- State file (auto-managed): `/var/run/ufw-ddns-<DDNS_HOST>`

> `/var/run` (or `/run`) is volatile; this is intentional, as rules will be re-applied by the scheduler on reboot.

---

## Safety & tips

- **Lockdown risk:** This script deletes **all** UFW rules for the specified `PORT/PROTO` before adding the new allow rule if it detects mismatches. Use a **dedicated port** for this pattern.
- **IPv6:** The script filters out `(v6)` entries when cleaning. It manages IPv4 rules only.
- **Least privilege:** Consider granting passwordless sudo **only** for the exact `ufw` commands used (via `/etc/sudoers.d/...`) rather than global passwordless sudo.
- **Firewall defaults:** Make sure your default UFW policy aligns with your intent:
  ```bash
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  ```

---

## Troubleshooting

- **`No se pudo resolver <host>` / can't resolve hostname**
  - Check `dig <host>` manually. Ensure DNS works and your DDNS provider updated.
- **Rule not changing**
  - Confirm the timer or cron is running.
  - Check `/var/run/ufw-ddns-<host>` content vs `dig +short <host>`.
- **Multiple rules hanging around**
  - The script runs a cleanup for `PORT/PROTO`, but if you manually edited rules, run:
    ```bash
    sudo ufw status numbered
    # then delete by number as needed
    ```

---

## Example

Protect TCP port 81 for `mihome.duckdns.org`:
```bash
DDNS_HOST="mihome.duckdns.org"
PORT=81
PROTO="tcp"
sudo /usr/local/bin/ufw-ddns-updater.sh
```

---

## Contributing

Issues and PRs welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
