# Contributing to flyingsquirrel0419/android-docker

Thanks for your interest. This guide covers the basics of contributing to the project.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/flyingsquirrel0419/android-docker/issues/new) and include:

- Docker version and host OS
- Container logs (`docker compose logs`)
- Steps to reproduce
- Your `compose.yml` or `docker run` command (sanitize any secrets)

Before opening a new issue, search existing ones to avoid duplicates.

## Suggesting Features

Open an issue with the label `enhancement`. Describe the use case, not just the solution. If you've looked at how [dockur/windows](https://github.com/dockur/windows) handles something similar, mention it. This project follows those patterns closely.

## Submitting Pull Requests

1. Fork the repo
2. Create a branch from `master`: `fix/thing` or `feat/thing`
3. Make your changes
4. Run the checks locally (see below)
5. Open a PR against `master`

Keep PRs focused. One concern per PR makes review faster.

## Development Setup

Build and run locally:

```bash
docker build -t android-local .
docker compose up -d
```

The container exposes three ports:

- **8006** - web viewer
- **5555** - ADB
- **5900** - VNC

Connect to `http://localhost:8006` to see the web UI. Check logs with `docker compose logs -f`.

The base image is `qemux/qemu:7.29`, which provides QEMU and the runtime environment. The `src/` scripts are copied to `/run/` inside the container.

### Project Structure

```
Dockerfile          Image definition (based on qemux/qemu:7.29)
compose.yml         Default compose config
src/
  entry.sh          Container entrypoint
  define.sh         Variable definitions and helpers
  install.sh        Android image download and setup
  power.sh          Power management (start, stop, reset)
```

## Code Style

This project is shell scripts. Follow these rules:

- **POSIX-compatible bash** where possible. Use `#!/usr/bin/env bash` for scripts that need bash features.
- **Match dockur/windows patterns.** If windows does it a certain way, do it that way here too.
- **Quote variables.** Always. No bare `$VAR`.
- **Use `set -eu`** at the top of scripts that don't already have it.
- Keep scripts in `src/` clean and readable. Avoid deep nesting.

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add support for Android 15
fix: resolve disk resize on fresh install
docs: update FAQ for ADB connection
refactor: simplify boot detection logic
```

Scope is optional but nice when it fits:

```
feat(install): add retry logic for mirror downloads
fix(power): handle graceful shutdown timeout
```

## CI Requirements

All PRs must pass the checks in `.github/workflows/check.yml`:

1. **ShellCheck** runs on `src/` with these exclusions:
   `SC1008 SC1091 SC2001 SC2034 SC2064 SC2153 SC2317`
2. **Hadolint** lints the Dockerfile (warnings and above)
3. **YAML validation** on compose and Kubernetes configs

Run ShellCheck locally before pushing:

```bash
shellcheck -x --source-path=src -e SC1008 -e SC1091 -e SC2001 -e SC2034 -e SC2064 -e SC2153 -e SC2317 src/*.sh
```

That's it. Keep it simple, match existing patterns, and your PR will move fast.
