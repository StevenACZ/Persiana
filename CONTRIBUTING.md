# Contributing to Persiana

Bug reports and focused pull requests are welcome. Use
[Issues](https://github.com/StevenACZ/Persiana/issues) for reproducible bugs and
feature proposals; read [SECURITY.md](SECURITY.md) before reporting a vulnerability.

Include your macOS version, Persiana version, Mac model, steps to reproduce, and
expected versus actual behavior. For hiding problems, describe where the affected
app's icon sits relative to Persiana's icon, and confirm that Persiana runs from
`/Applications`. Remove private information, such as account names or notification
content, from reports and screenshots.

## Changes

1. Read [development setup](docs/development.md) and the repository's `AGENTS.md`.
2. Keep changes focused and follow the existing Swift formatting and architecture.
3. Add regression coverage for behavioral changes in `PersianaCore`.
4. Run `make check`.
5. Describe the user-visible result, validation performed and remaining limitations
   in your pull request. Add a concise `CHANGELOG.md` entry under `Unreleased`.

Keep user-facing strings in English and Spanish. Persiana has no network code;
changes that add network access need a clear reason in the pull request. Do not
commit signing certificates, Team IDs, credentials, personal preferences, captures,
build outputs or rollback archives. Never reset system permissions or change
another application's preferences for a test.

Contributions are distributed under the project's [MIT license](LICENSE).
