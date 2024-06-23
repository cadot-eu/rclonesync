# Rclone Sync and Log Script

## Description

This script is designed to synchronize a local directory with a remote directory using `rclone`, while logging the process and generating an HTML file to display the logs. The script also monitors the local directory for changes and triggers synchronization whenever a change is detected.

## Features

- Synchronizes a local directory with a remote directory using `rclone`.
- Generates an HTML file with the synchronization logs.
- Filters out unwanted log lines.
- Refreshes the HTML page every 3 seconds to show the latest logs.
- Monitors the local directory for changes and triggers synchronization automatically.

## Usage

```bash
./sync_script.sh [-w <WATCH_DIR>] [-r <REMOTE_DIR>]
