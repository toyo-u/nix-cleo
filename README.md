# nix-cleo

Reusable `nix-darwin` + Home Manager flake for Cleo macOS developer machines.

This repo captures shared local development setup, with a bias toward the
`mobile-app` workflow. It replaces one-off machine setup with a declarative
configuration that can be reviewed, versioned, and reapplied.

## What This Manages

- `nix-darwin` system configuration
- Home Manager user configuration
- shared shell defaults for `zsh`, `direnv`, optional `tmux`, and optional `neovim`
- common macOS defaults
- shared Homebrew taps, formulae, and casks
- Android SDK environment variables and PATH entries for mobile development

## What This Does Not Manage

- Android SDK packages themselves. Android Studio still owns the SDK under
  `~/Library/Android/sdk`.
- Personal secrets. `settings.nix` and token files stay local.
- Existing unmanaged Homebrew packages. This repo currently sets Homebrew
  cleanup to `none`.

## Repository Structure

- [`flake.nix`](./flake.nix): flake entrypoint and wiring for `nix-darwin` + Home Manager
- [`config.nix`](./config.nix): machine-level `nix-darwin` configuration
- [`home.nix`](./home.nix): user-level Home Manager configuration
- [`defaults.nix`](./defaults.nix): repo-owned shared defaults for all developers
- `settings.nix`: machine-specific values and user-managed preferences
- [`settings.example.nix`](./settings.example.nix): example template for a new machine

## Configuration Model

The flake merges two layers:

- `defaults.nix`: shared baseline common across developer machines
- `settings.nix`: per-machine identity and user-managed additions

The merge happens in [`flake.nix`](./flake.nix). The resulting `settings`
attrset is passed into both [`config.nix`](./config.nix) and
[`home.nix`](./home.nix).

Use this rule:

- shared workflow requirements belong in `defaults.nix`, `config.nix`, or `home.nix`
- machine-specific values and personal preferences belong in `settings.nix`

`settings.nix` is ignored by git on purpose.

## Prerequisites

Install a Nix implementation with flakes enabled.

The upstream `nix-darwin` project supports both Nix and Lix. It recommends the
Lix installer for new users because the official Nix installer does not include
an automated macOS uninstaller. Use the implementation preferred by your team or
machine policy.

Useful upstream references:

- [`nix-darwin` GitHub repo](https://github.com/nix-darwin/nix-darwin)
- [`nix-darwin` option reference](https://nix-darwin.github.io/nix-darwin/manual/index.html)
- local docs after install: `darwin-help`
- local man page after install: `man 5 configuration.nix`

## First-Time Setup

Put this repo at the path used by `settings.flakePath`:

```bash
mkdir -p ~/.config
git clone <repo-url> ~/.config/nix-darwin
cd ~/.config/nix-darwin
```

Create your local settings:

```bash
cp settings.example.nix settings.nix
```

Edit `settings.nix`:

- set `username` to the output of `whoami`
- set `hostname` to the output of `scutil --get LocalHostName`
- set `system` to `aarch64-darwin` for Apple Silicon or `x86_64-darwin` for Intel
- add any personal packages, Homebrew formulae, casks, shell preferences, or AWS profile

Check the config evaluates:

```bash
nix flake check --no-build
```

Install/apply `nix-darwin`.

`nix-darwin` does not have a separate installer. The first successful
`darwin-rebuild switch` installs it. Before `darwin-rebuild` is on your PATH,
run it through `nix run`:

```bash
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#$(scutil --get LocalHostName)
```

If `settings.hostname` is not the same as `scutil --get LocalHostName`, use the
configured hostname explicitly:

```bash
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#your-hostname
```

After the first switch, open a new shell.

## Daily Use

After the initial switch, the configured `zsh` shell defines:

```bash
drs
```

That alias runs `darwin-rebuild switch` against `settings.flakePath` and
`settings.hostname`, preserving `HOMEBREW_GITHUB_API_TOKEN` for private taps.

Use it after editing this repo:

```bash
drs
```

Without the alias:

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#$(scutil --get LocalHostName)
```

## Updating Inputs

Update pinned flake inputs:

```bash
nix flake update
```

Then apply:

```bash
drs
```

Commit `flake.lock` when the update is intentional.

## Homebrew Token Support

If you need `HOMEBREW_GITHUB_API_TOKEN` for private taps or GitHub API limits,
create the file referenced by `settings.homebrewTokenFile`.

Default path:

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

Do not commit this file.

## Optional Features

### tmux

tmux is off by default. To enable it, uncomment the full `tmux` block in
`settings.nix` and set:

```nix
tmux.enable = true;
```

If you enable tmux, keep the rest of the tmux fields in that block. `home.nix`
uses them to generate bindings and plugin settings.

### Ghostty

Ghostty is off by default. To enable its Home Manager config, uncomment the
full `ghostty` block in `settings.nix` and set:

```nix
ghostty.enable = true;
```

To install the Ghostty app too, also add the cask:

```nix
homebrew.extraCasks = [
  "ghostty"
];
```

### Neovim

Neovim preferences live in `settings.nix`:

```nix
neovim = {
  enable = true;
  withNodeJs = true;
};
```

## Troubleshooting

### `darwin-rebuild: command not found`

Use the first-time command:

```bash
sudo nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch --flake .#$(scutil --get LocalHostName)
```

Then open a new shell.

### `does not provide attribute darwinConfigurations.<host>`

Your flake hostname does not match the host selector.

Check:

```bash
scutil --get LocalHostName
```

Then either update `settings.hostname` or pass the configured name explicitly:

```bash
sudo darwin-rebuild switch --flake ~/.config/nix-darwin#your-hostname
```

### `attribute '<name>' missing`

Your `settings.nix` probably has an incomplete optional block. Compare it with
[`settings.example.nix`](./settings.example.nix). For tmux and Ghostty, uncomment
the full block when enabling the feature.

### Android tooling cannot find the SDK

This repo exports:

- `ANDROID_HOME=$HOME/Library/Android/sdk`
- `ANDROID_SDK_ROOT=$HOME/Library/Android/sdk`

Open Android Studio and install the SDK, platform tools, emulator, and required
API levels there.

## Relationship To Other Repos

- `mobile-app/flake.nix` is the repo-local development shell for application work
- `nix-cleo` is the machine-level baseline around that workflow
- `setup-mobile-app` is the older imperative bootstrap flow based on Homebrew and `asdf`

The current direction is Nix-first for shared setup, while keeping compatibility
with workflows that still expect older tooling.
