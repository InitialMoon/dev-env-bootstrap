# Global Claude Code preferences

- Keep shared configuration free of secrets, tokens, private paths, and machine-only values.
- Prefer small, reversible changes and safe install steps that do not overwrite existing files.
- Treat macOS and Linux as sharing the same core workflow, with platform-specific differences handled only when necessary.
- Keep broad tool allowlists and local permission changes in `~/.claude/settings.local.json` instead of this repository.
