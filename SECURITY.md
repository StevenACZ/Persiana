# Security and privacy

## Data and permissions

Persiana uses macOS Accessibility only to read the positions of menu bar items. It
does not read window contents or keystrokes, and it does not request Screen
Recording, Microphone, Full Disk Access or Automation permission. Settings are
stored locally in the app's preferences.

Persiana does not send analytics or require an account. Update checks and
downloads contact GitHub, the public release host, which can receive normal request
metadata such as your IP address. Automatic checks can be turned off in Settings.

To hide icons, Persiana uses a private macOS interface. If that interface is
missing or rejects the request, Persiana fails open and shows every icon.

## Distribution and updates

Public release artifacts use Developer ID signing and notarization. Sparkle 2
verifies EdDSA-signed updates, and installing one requires a user action. Local
development builds use Apple Development signing and do not consume the public
update feed. The repository contains no
certificates, Team IDs or other signing credentials; each builder uses their own
identity. Download releases only from the project's
[GitHub Releases](https://github.com/StevenACZ/Persiana/releases).

## Reporting a vulnerability

Use **Report a vulnerability** in the repository's
[Security tab](https://github.com/StevenACZ/Persiana/security) when private
reporting is available. Include the affected version, impact and a minimal
reproduction without real private data or credentials.

If private reporting is unavailable, open an issue requesting a private contact
channel. Do not publish exploit details, secrets or sensitive user data in that
issue. Security fixes target the latest release; older versions do not have a
separate maintenance policy.
