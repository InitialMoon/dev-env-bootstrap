# macOS/Linux Configuration Sync Design

## Goal

Keep `dev-env-bootstrap` safe to share while making it capable of recreating the current macOS terminal and AI-tool experience. The default shared layer must also work on Linux so a Linux machine can receive the same core terminal workflow and Claude Code/Codex experience without macOS-only paths or private values.

## Non-goals

- Do not commit secrets, tokens, SSH key material, machine-specific project paths, or local API endpoints.
- Do not overwrite existing dotfiles during installation.
- Do not make macOS tooling required for Linux users.
- Do not copy the current `~/.zshrc`, `~/.claude/settings.json`, or `~/.codex/config.toml` verbatim into the repository.

## Repository Layers

### Cross-platform core layer

`config/core/` remains the default layer for Linux and macOS. It should include terminal and AI-tool defaults that are safe and useful on both platforms:

- shell snippets for shared PATH/XDG defaults, aliases, and terminal helper functions;
- zsh/bash/fish entry snippets that source the shared shell layer and then optional local files;
- tmux configuration for the current workflow;
- Git defaults and safe aliases;
- Vim/Yazi basic interaction defaults;
- Claude Code shared preferences, status line/prompt templates, plugin preferences, and non-secret examples;
- Codex shared profiles, interaction defaults, environment-exclusion policy, and non-secret examples;
- global ignore patterns for local/private configuration files.

The core layer must avoid `/Users/initialmoon`, `/opt/homebrew`, local API endpoints, SSH key names, personal project paths, and any token-bearing configuration.

### macOS reproducibility layer

`config/macos/` and/or `scripts/macos/` should contain macOS-only additions that reproduce the current Mac experience without affecting Linux:

- Homebrew setup and optional package groups;
- Apple Silicon/Homebrew PATH setup;
- Homebrew bottle mirror support;
- Java setup via `/usr/libexec/java_home`;
- LLVM/OpenMP workaround paths and compiler flags;
- Ruby and user gem path setup;
- optional dotnet@6 path setup;
- optional conda/mamba initialization examples for the Homebrew/Miniforge layout;
- macOS-only Yazi opener behavior using `open`;
- iTerm2/tmux Option-key notes.

This layer should be opt-in through an interactive or explicit bootstrap command. It must be skipped or rejected with a clear message on non-Darwin platforms.

### Local/private layer

Private machine state should be represented only by templates and examples:

- `*.local.example` shell files for API key loading, SSH key additions, project-specific PATH entries, and automatic environment activation;
- Claude Code local settings examples for tokens, base URLs, and broad local permissions;
- Codex local settings examples for local model provider endpoints, trusted project paths, runtime/cache paths, and notification command paths;
- optional `ai_api_keys.example.json` showing expected shape without real keys.

Install scripts may create example files or print next steps, but they must not write real secrets or infer private values from the current machine.

## Configuration Decisions

### Shell and zsh

Do not import the current `~/.zshrc` as a single file. Split it into reusable pieces:

- shared core: XDG variables, `~/.local/bin` PATH, common aliases, Yazi directory-changing helper, shell local-file hook;
- zsh profile: Oh My Zsh/Powerlevel10k and plugin list as a template or opt-in module;
- macOS profile: Homebrew, Java, LLVM, Ruby, dotnet, and conda/mamba initialization examples;
- local profile: API key loading, SSH key additions, personal project PATHs, and automatic `mamba activate daily_use`.

The install path should continue using managed include blocks in `~/.zshrc`, `~/.bashrc`, and other shell entry files. Existing unmanaged files must be skipped or only amended with managed blocks.

### tmux

Use the repository tmux configuration as the base because it already removes obsolete UTF-8 settings and guards plugin/powerline loading. Preserve the current workflow:

- prefix `C-d`;
- Alt-based window and pane navigation;
- vi copy mode;
- tmux-resurrect and tmux-continuum plugin configuration;
- TPM integration only when TPM exists.

Powerline and optional plugins must be guarded with existence checks. `tmux-aiscope` should be optional rather than required in core unless its cross-platform behavior is verified.

### Git

Move shared Git behavior to the core Git include:

- `pull.rebase = true`;
- `push.default = upstream`;
- `fetch.prune = true`;
- `core.quotepath = false`;
- `core.autocrlf = false`;
- common aliases.

Use `rerere.enabled = true`, correcting the current local `rerere.enable` spelling. Replace the risky local alias `pf = push --force` with `pf = push --force-with-lease` if it is included in shared config. User identity, GitHub URL rewrites, and any work-specific Git settings stay local.

### Yazi and Vim

Keep cross-platform Yazi navigation keymaps in core. Put macOS-specific opener behavior behind the macOS layer or a platform-specific config snippet.

Keep Vim basics in core or optional editor config: indentation, line numbers, search behavior, leader key, and split navigation. Remove large tutorial comments when moving into shared config so the file stays focused.

### Claude Code

Core should manage only safe shared Claude Code configuration:

- shared `CLAUDE.md` preferences;
- status line/prompt templates;
- plugin preferences that are portable;
- non-secret hook templates if needed;
- `settings.local.example.json` for private values.

The real local `~/.claude/settings.json` contains values that must not be committed: auth token, base URL, local allowlists, and local status/hook commands if they include private paths. Those should either remain unmanaged or be split so only portable pieces enter the repo.

### Codex

Core should provide portable Codex defaults and profile templates. The local config should stay private for:

- local model provider base URL;
- trusted project paths;
- local runtime/cache marketplace paths;
- notification command path;
- any auth-related provider state.

If a shared profile is added, it should keep environment-exclusion rules for AI/API keys because those are portable and defensive.

## Bootstrap and Installer Behavior

Add or adjust bootstrap commands so the workflow is explicit:

- `./bootstrap.sh core`: install/check core tools and link cross-platform shared config;
- `./bootstrap.sh ai`: link or preview AI-tool shared templates/config snippets;
- `./bootstrap.sh macos`: show an interactive macOS-only menu for optional package groups and environment setup;
- `./bootstrap.sh interactive` or `./bootstrap.sh choose`: allow selecting optional groups, including choosing none.

The macOS menu should list toolchain groups such as Homebrew basics, Java, LLVM/OpenMP, Ruby, dotnet, conda/mamba, and optional editor/shell extras. The user can select groups manually or skip all package installation.

All mutating commands should support dry-run/status behavior. Existing unmanaged paths should not be overwritten. Symlink creation and managed block insertion should remain conservative and reversible.

## Secret and Private-Path Audit

Before considering the sync complete, run an audit over repository changes for:

- token/key strings;
- user-specific home directory paths;
- personal project or research paths;
- `.ssh/` and private SSH key names;
- local model-provider endpoints;
- real Claude/Codex auth or trust-path data.

The repository already has an audit script; extend it if needed so these checks are repeatable.

## Testing and Verification

Verification should cover:

- shell syntax for changed `*.sh` files;
- `./install.sh dry-run` on macOS;
- `./install.sh status` after non-mutating changes;
- `./bootstrap.sh doctor`;
- macOS command path rejecting or skipping on non-macOS where testable;
- audit script passing with no private values;
- Git diff review confirming local/private files are represented only by examples.

## Rollback and Safety

The existing `unlink` command should continue removing only repository-owned symlinks and managed blocks. New links and blocks must be added to the managed list so rollback remains precise. The installer must never delete or rewrite unmanaged user files.
