<div align="center">
  <h1>Linux-Mole</h1>
  <p><em>Deep clean and optimize your system.</em></p>
</div>

## Features

- **All-in-one toolkit**: Unified cleanup, optimization, installer scanning, and system status in a **single binary**
- **Deep cleaning**: Removes caches, logs, and browser leftovers to **reclaim gigabytes of space**
- **Disk insights**: Visualizes usage, finds large files, **rebuilds caches**, and refreshes system services
- **Live monitoring**: Shows real-time CPU, GPU, memory, disk, and network stats

## Quick Start

**Install (stable release):**

```bash
curl -fsSL https://raw.githubusercontent.com/SpreadSheets600/Mole/main/install.sh | MOLE_REPO="SpreadSheets600/Mole" bash
```

**Install latest main branch (nightly/edge):**

```bash
curl -fsSL https://raw.githubusercontent.com/SpreadSheets600/Mole/main/install.sh | MOLE_REPO="SpreadSheets600/Mole" bash -s -- latest
```

**Install a specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/SpreadSheets600/Mole/main/install.sh | MOLE_REPO="SpreadSheets600/Mole" bash -s -- 1.27.0
```

**Linux/WSL support:** `mo clean`, `mo optimize`, `mo installer`, `mo analyze`, `mo purge`, and `mo status` are optimized for Linux and WSL.

**Run:**

```bash
mo                           # Interactive menu
mo clean                     # Deep cleanup
mo optimize                  # Refresh caches & services
mo analyze                   # Visual disk explorer
mo status                    # Live system health dashboard
mo purge                     # Clean project build artifacts
mo installer                 # Find and remove installer files

mo completion                # Set up shell tab completion
mo update                    # Update Linux-Mole
mo update --nightly          # Update to latest unreleased main build, script install only
mo remove                    # Remove Linux-Mole from system
mo --help                    # Show help
mo --version                 # Show installed version

mo clean --dry-run           # Preview the cleanup plan
mo clean --whitelist         # Manage protected caches
mo clean --dry-run --debug   # Detailed preview with risk levels and file info

mo optimize --dry-run        # Preview optimization actions
mo optimize --debug          # Run with detailed operation logs
mo optimize --whitelist      # Manage protected optimization rules
mo purge --paths             # Configure project scan directories
mo analyze /mnt              # Analyze mounted external drives
```

## Command Snapshots

Snapshots captured from this repo on Linux/WSL:

```bash
$ ./mole --help
__  __       _
|  \/  | ___ | | ___
| |\/| |/ _ \| |/ _ \
| |  | | (_) | |  __/  https://github.com/SpreadSheets600/Mole
|_|  |_|\___/|_|\___|  Deep clean and optimize your Linux system.
...
  mo analyze /mnt              Analyze external drives only
```

```bash
$ ./mole --version
Linux-Mole version 1.27.0
OS: Debian GNU/Linux 13 (trixie)
Architecture: x86_64
Kernel: 6.6.87.2-microsoft-standard-WSL2
SIP: Unknown
Disk Free: 938G
Install: Manual
Shell: /usr/bin/zsh
```

```bash
$ ./mole clean --help
Usage: mo clean [OPTIONS]

Clean up disk space by removing caches, logs, and temporary files.

Options:
  --dry-run, -n     Preview cleanup without making changes
  --whitelist       Manage protected paths
  --debug           Show detailed operation logs
  -h, --help        Show this help message

Linux/WSL targets:
  ~/.cache, ~/.local/share/Trash/files, ~/.npm/_cacache, ~/.cargo/registry/cache, /tmp (user-owned only)
```

## Tips

- Video tutorial: Watch the [Linux-Mole tutorial video](https://www.youtube.com/watch?v=UEe9-w4CcQ0), thanks to PAPAYA 電腦教室.
- Safety first: Deletions are permanent. Review carefully and preview with `mo clean --dry-run`. See [Security Audit](SECURITY_AUDIT.md).
- Debug and logs: Use `--debug` for detailed logs. Combine with `--dry-run` for a full preview. File operations are logged to `~/.config/mole/operations.log`. Disable with `MO_NO_OPLOG=1`.
- Navigation: Linux-Mole supports arrow keys and Vim bindings `h/j/k/l`.

## Features in Detail

### Deep System Cleanup

```bash
$ mo clean

Scanning cache directories...

  ✓ User app cache                                           45.2GB
  ✓ Browser cache (Chrome, Safari, Firefox)                  10.5GB
  ✓ Developer tools (Xcode, Node.js, npm)                    23.3GB
  ✓ System logs and temp files                                3.8GB
  ✓ App-specific cache (Spotify, Dropbox, Slack)              8.4GB
  ✓ Trash                                                    12.3GB

====================================================================
Space freed: 95.5GB | Free space now: 223.5GB
====================================================================
```

Note: Linux/WSL cleanup targets include user caches, package caches, trash files, and temporary directories.

### System Optimization

```bash
$ mo optimize

System: 5/32 GB RAM | 333/460 GB Disk (72%) | Uptime 6d

  ✓ Rebuild system databases and clear caches
  ✓ Reset network services
  ✓ Refresh package/runtime caches
  ✓ Clean diagnostic and crash logs
  ✓ Remove swap files and restart dynamic pager
  ✓ Rebuild launch services and spotlight index

====================================================================
System optimization completed
====================================================================

Use `mo optimize --whitelist` to exclude specific optimizations.
```

### Disk Space Analyzer

By default, Linux-Mole skips external drives under `/mnt` and `/media` for faster startup. To inspect them, run `mo analyze /mnt` or a specific mount path.

```bash
$ mo analyze

Analyze Disk  ~/Documents  |  Total: 156.8GB

 ▶  1. ███████████████████  48.2%  |  📁 Library                     75.4GB  >6mo
    2. ██████████░░░░░░░░░  22.1%  |  📁 Downloads                   34.6GB
    3. ████░░░░░░░░░░░░░░░  14.3%  |  📁 Movies                      22.4GB
    4. ███░░░░░░░░░░░░░░░░  10.8%  |  📁 Documents                   16.9GB
    5. ██░░░░░░░░░░░░░░░░░   5.2%  |  📄 backup_2023.zip              8.2GB

  ↑↓←→ Navigate  |  O Open  |  F Show  |  ⌫ Delete  |  L Large files  |  Q Quit
```

### Live System Status

Real-time dashboard with health score, hardware info, and performance metrics.

```bash
$ mo status

Linux-Mole Status  Health ● 92  Linux Host · 32GB · Kernel 6.x

⚙ CPU                                    ▦ Memory
Total   ████████████░░░░░░░  45.2%       Used    ███████████░░░░░░░  58.4%
Load    0.82 / 1.05 / 1.23 (8 cores)     Total   14.2 / 24.0 GB
Core 1  ███████████████░░░░  78.3%       Free    ████████░░░░░░░░░░  41.6%
Core 2  ████████████░░░░░░░  62.1%       Avail   9.8 GB

▤ Disk                                   ⚡ Power
Used    █████████████░░░░░░  67.2%       Level   ██████████████████  100%
Free    156.3 GB                         Status  Charged
Read    ▮▯▯▯▯  2.1 MB/s                  Health  Normal · 423 cycles
Write   ▮▮▮▯▯  18.3 MB/s                 Temp    58°C · 1200 RPM

⇅ Network                                ▶ Processes
Down    ▁▁█▂▁▁▁▁▁▁▁▁▇▆▅▂  0.54 MB/s      Code       ▮▮▮▮▯  42.1%
Up      ▄▄▄▃▃▃▄▆▆▇█▁▁▁▁▁  0.02 MB/s      Chrome     ▮▮▮▯▯  28.3%
Proxy   HTTP · 192.168.1.100             Terminal   ▮▯▯▯▯  12.5%
```

Health score is based on CPU, memory, disk, temperature, and I/O load, with color-coded ranges.

Shortcuts: In `mo status`, press `k` to toggle the cat and save the preference, and `q` to quit.

### Project Artifact Purge

Clean old build artifacts such as `node_modules`, `target`, `build`, and `dist` to free up disk space.

```bash
mo purge

Select Categories to Clean - 18.5GB (8 selected)

➤ ● my-react-app       3.2GB | node_modules
  ● old-project        2.8GB | node_modules
  ● rust-app           4.1GB | target
  ● next-blog          1.9GB | node_modules
  ○ current-work       856MB | node_modules  | Recent
  ● django-api         2.3GB | venv
  ● vue-dashboard      1.7GB | node_modules
  ● backend-service    2.5GB | node_modules
```

> We recommend installing `fd` for faster scans.
> Debian/Ubuntu: `sudo apt install fd-find` (`fd` may be named `fdfind`)

> **Use with caution:** This permanently deletes selected artifacts. Review carefully before confirming. Projects newer than 7 days are marked and unselected by default.

<details>
<summary><strong>Custom Scan Paths</strong></summary>

Run `mo purge --paths` to configure scan directories, or edit `~/.config/mole/purge_paths` directly:

```shell
~/Documents/MyProjects
~/Work/ClientA
~/Work/ClientB
```

When custom paths are configured, Linux-Mole scans only those directories. Otherwise, it uses defaults like `~/Projects`, `~/GitHub`, and `~/dev`.

</details>

### Installer Cleanup

Find and remove large installer files across Downloads, Desktop, cache, trash, and temp paths. Each file is labeled by source.

```bash
mo installer

Select Installers to Remove - 3.8GB (5 selected)

➤ ● ubuntu-24.04.iso           5.3GB | Downloads
  ● code_1.95.2_amd64.deb      110MB | Downloads
  ● docker-desktop.rpm         505MB | Downloads
  ● appimage-tool.AppImage      75MB | Desktop
  ● cache_bundle.tar.gz        940MB | Cache
  ○ legacy-installer.zip       410MB | Downloads
```

## Quick Launchers

Launch Linux-Mole commands from Raycast or Alfred:

```bash
curl -fsSL https://raw.githubusercontent.com/SpreadSheets600/Mole/main/scripts/setup-quick-launchers.sh | bash
```

Adds 5 commands: `Linux-Mole Clean`, `Linux-Mole Uninstall`, `Linux-Mole Optimize`, `Linux-Mole Analyze`, `Linux-Mole Status`.

## License

MIT License. Feel free to use Linux-Mole and contribute.
