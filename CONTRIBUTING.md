# Contributing

Thanks for your interest in improving **UFW DDNS Hostname Updater**!

## Ways to contribute
- Report bugs via GitHub Issues with clear steps to reproduce.
- Suggest enhancements and use cases.
- Improve documentation or examples.
- Submit pull requests for fixes and features.

## Pull requests
1. Fork and create a feature branch.
2. Keep changes focused and documented.
3. Update README or comments when behavior changes.
4. Ensure the script remains POSIX-friendly Bash and avoids external deps beyond `ufw` and `dig`.

## Coding guidelines
- Shell: Bash with strict, readable style.
- Avoid unnecessary subshells and external tools.
- Prefer idempotent operations.
- Be careful with `sudo` usage and user paths.

## Security
If you find a vulnerability, **do not open a public issue**. See [SECURITY.md](SECURITY.md).
