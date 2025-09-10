# Security Policy

## Reporting a Vulnerability

If you discover a security issue:
- Email the maintainer privately (do not open a public issue).
- Include steps to reproduce, affected versions, and any PoC.
- Allow time for a fix before public disclosure.

## Scope and notes

- The script manipulates firewall rules. Misconfigurations can lead to exposure or lockouts.
- The script manages only IPv4 rules and removes all `PORT/PROTO` rules before re-adding the allowlist. Use a dedicated port.
- Consider limiting `sudo` permissions to the specific `ufw` commands used by the script.
