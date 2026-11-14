# rookieAHKcfg - Agent Guidelines

## Autonomous Multi-Device Sync (Notebook & Desktop)

This repository is actively developed and updated across both the notebook and desktop via GitHub.

- **Zero-Prompt Sync:** When asked to update, sync, or pull from GitHub:
  - Do NOT prompt the user with interactive questions (`ask_question`).
  - Automatically commit any pending local changes cleanly, fetch `origin/main`, merge upstream commits, validate AHK v2 syntax (`/validate`), and reload/push as requested.
  - Keep the cross-device sync completely frictionless and autonomous.
