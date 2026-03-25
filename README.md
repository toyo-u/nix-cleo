# nix-cleo

Reusable `nix-darwin` + Home Manager flake for Cleo macOS developer machines.

This repo captures the shared machine baseline for local development, with a bias toward the `mobile-app` workflow. It is intended to replace ad hoc machine setup with a declarative configuration that can be reviewed, versioned, and reapplied.

## What This Manages

- `nix-darwin` system configuration
- Home Manager user configuration
- Shared shell defaults for `zsh`, `direnv`, `tmux`, and optional `neovim`
- Common macOS defaults
- Shared Homebrew taps, brews, and casks
- Android SDK environment variables and PATH entries used by mobile development

## Repository Structure

- `flake.nix`: flake entrypoint and wiring for `nix-darwin` + Home Manager
- `config.nix`: machine-level `nix-darwin` configuration
- `home.nix`: user-level Home Manager configuration
- `defaults.nix`: repo-owned shared defaults for all developers
- `settings.nix`: machine-specific values and user-managed preferences
- `settings.example.nix`: example template for a new machine

## How Configuration Is Split

The flake merges two layers:

- `defaults.nix`: the shared baseline that should be common across developer machines
- `settings.nix`: per-machine identity and user-managed additions

This merge happens in [`flake.nix`](/Users/toyo.u/Develop/nix-cleo/flake.nix), and the resulting `settings` attrset is passed into both [`config.nix`](/Users/toyo.u/Develop/nix-cleo/config.nix) and [`home.nix`](/Users/toyo.u/Develop/nix-cleo/home.nix).

The intended rule is:

- shared workflow requirements belong in `defaults.nix`, `config.nix`, or `home.nix`
- machine-specific values and personal preferences belong in `settings.nix`

## Getting Started

1. Install Nix and enable flakes.
2. Put this repo at `~/.config/nix-darwin`.
3. Copy `settings.example.nix` to `settings.nix`.
4. Edit `settings.nix`:
   - set `username` to the output of `whoami`
   - set `hostname` to the output of `scutil --get LocalHostName`
   - set `system` to `aarch64-darwin` or `x86_64-darwin`
   - update any optional Homebrew, shell, tmux, or package preferences
5. Apply the configuration:

```bash
sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)
```

If `settings.nix` sets a different host name than the current machine, use that explicitly:

```bash
sudo darwin-rebuild switch --flake .#your-hostname
```

## Common Workflow

After the initial switch, the configured `zsh` shell defines:

```bash
drs
```

That alias runs:

```bash
sudo --preserve-env=HOMEBREW_GITHUB_API_TOKEN darwin-rebuild switch --flake ~/.config/nix-darwin#<hostname>
```

Use `drs` after editing the config locally.

## Homebrew Token Support

If you need `HOMEBREW_GITHUB_API_TOKEN` for private taps or to avoid GitHub API rate limits, create the file referenced by `settings.homebrewTokenFile`.

By default that is:

```bash
~/.config/secrets/homebrew.env
```

Example contents:

```bash
export HOMEBREW_GITHUB_API_TOKEN=ghp_xxx
```

The token file is sourced:

- before Homebrew activation in `nix-darwin`
- in interactive `zsh` shells

## Relationship To Other Repos

- `mobile-app/flake.nix` is the repo-local development shell for application work
- `nix-cleo` is the machine-level baseline around that workflow
- `setup-mobile-app` is the older imperative bootstrap flow based on Homebrew and `asdf`

The current direction is Nix-first for shared setup, while keeping compatibility with workflows that still expect older tooling.

## Notes

- `android-studio` is installed via Homebrew cask, but the Android SDK still lives in `~/Library/Android/sdk`
- `asdf-vm` is kept as a compatibility fallback for repos that still rely on `.tool-versions`
- this repo is macOS-specific and intended for use with `nix-darwin`
