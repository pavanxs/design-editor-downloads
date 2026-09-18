# Design Editor beta downloads

Current test beta: **0.1.0-beta.3**. Windows x64, Intel Mac and Apple Silicon archives are attached to the corresponding release. These are early test releases, not a production-readiness or warning-free-installation claim.

## Install

The generated installers use the public beta channel and user-local storage. Node/npm is not a prerequisite. Review a script before running downloaded code.

macOS:

```sh
curl -fsSL --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/pavanxs/design-editor-downloads/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/pavanxs/design-editor-downloads/main/install.ps1 | iex
```

For a download-first review, save install.sh or install.ps1 from this repository and inspect it before executing it. Keep Windows and macOS security protections enabled. The beta is not publisher-code-signed; operating-system policy may warn or block it. No security-policy bypass is part of these instructions.

## Open a project

Open a new terminal after installation when needed, then run from your project folder:

```sh
design-editor .
```

Or pass an existing folder path. Opening a project does not automatically run its scripts. Live previews and agents need their own supported setup and approval.

## Updates

Installed apps check on launch and every 30 minutes while open. Use Updates → Check for updates, then Restart to update when work is finished. Downloads do not force a restart. The terminal also supports `design-editor update` and `design-editor --version`. Keep drafts and canvas work resolved before restarting; this beta does not promise durable autosave.

Release files are checked by size, SHA-256, version and target. Update-metadata signatures are deferred; hashes do not independently authenticate the publisher.

## Test status

Native candidate build/install/launch checks passed for all three targets. Real hosted old-to-new update acceptance is being run separately; publication itself is not that test result. The build repository contains candidate automation, not customer credentials. Application development source is not stored here.
