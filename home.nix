{ pkgs, lib, settings, ... }:
let
  # Android Studio and SDK Manager install the SDK here on macOS by convention.
  androidSdkRoot = "$HOME/Library/Android/sdk";
  tmuxPluginNames = settings.tmux.plugins;
  hasTmuxPlugin = name: builtins.elem name tmuxPluginNames;
in
{
  # Shared Home Manager baseline for every developer machine using this repo.
  # These defaults are based on what `mobile-app` and `setup-mobile-app` show is
  # required for the common mobile workflow. Personal preferences stay in
  # `settings.nix`; required shared workflow tooling stays here.

  # Tracks the Home Manager state schema version for compatibility.
  # Change only when intentionally migrating to a newer state version.
  home.stateVersion = "25.11";

  # Manage XDG-style config files under `~/.config`.
  xdg.enable = true;

  # Install the package names declared in `settings.nix`.
  # Each string is looked up from the shared `pkgs` package set.
  home.packages =
    [
      # Shared baseline tools that should always be present.
      # `mobile-app` uses `direnv` + `use flake` as the main entrypoint.
      pkgs.direnv
    ]
    ++ builtins.map (name: pkgs.${name}) settings.systemDefaults.homePackages
    ++ builtins.map (name: pkgs.${name}) settings.extraHomePackages;

  # Environment variables exported in login shells and graphical sessions.
  home.sessionVariables = {
    # Standard Android SDK environment variables expected by React Native,
    # Expo, Android tooling, and many build scripts.
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;
  } // lib.optionalAttrs (settings.awsProfile != null) {
    # Only set this when a default AWS profile is configured.
    AWS_PROFILE = settings.awsProfile;
  };

  # Extra directories prepended to PATH for the user.
  home.sessionPath = [
    # `adb` and related Android platform tools.
    "${androidSdkRoot}/platform-tools"
    # Android emulator binaries.
    "${androidSdkRoot}/emulator"
    # Android command-line tools, if installed.
    "${androidSdkRoot}/cmdline-tools/latest/bin"
    # Older SDK tool locations kept for compatibility with some scripts.
    "${androidSdkRoot}/tools"
    "${androidSdkRoot}/tools/bin"
  ];

  programs.neovim = {
    # Install and manage Neovim.
    enable = settings.neovim.enable;
    # Provide Node.js support for Neovim plugins that require it.
    withNodeJs = settings.neovim.withNodeJs;
  };

  # Write a Ghostty config file under `~/.config/ghostty/config`.
  xdg.configFile = lib.mkIf settings.ghostty.enable {
    "ghostty/config".text = ''
      # Keep right Option for symbols like '#', left Option for tmux Meta binds.
      macos-option-as-alt = ${settings.ghostty.macosOptionAsAlt}
    '';
  };

  programs.tmux = lib.mkIf settings.tmux.enable {
    # Install and manage tmux config.
    enable = true;
    # Use Ctrl-a instead of the default Ctrl-b prefix.
    prefix = settings.tmux.prefix;
    # Default shell used inside tmux panes.
    shell = "${pkgs.zsh}/bin/zsh";

    # Install the tmux plugins listed in `settings.nix`.
    plugins = builtins.map (name: pkgs.tmuxPlugins.${name}) tmuxPluginNames;

    extraConfig = ''
      # Start shells in zsh for new panes and windows.
      set-option -g default-command "${pkgs.zsh}/bin/zsh"
      # Improve handling of modified function and arrow keys.
      set -g xterm-keys on

      # Quick keyboard shortcuts for moving between tmux windows.
      bind -n ${settings.tmux.nextWindowShortcut} next-window
      bind -n ${settings.tmux.previousWindowShortcut} previous-window

      # Ask the restore plugin to recover Vim and Neovim sessions.
      ${if settings.tmux.restoreVimSessions && hasTmuxPlugin "resurrect" then ''
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
      '' else ""}
      # Reopen the previous tmux session automatically.
      ${if hasTmuxPlugin "continuum" then ''
      set -g @continuum-restore '${if settings.tmux.continuumRestore then "on" else "off"}'
      '' else ""}
    '';
  };

  programs.direnv = {
    # Install and configure direnv.
    enable = true;
    # Hook direnv into the supported interactive shell baseline.
    enableZshIntegration = true;
    # Use nix-direnv for fast flake/devShell integration.
    nix-direnv.enable = true;
  };

  programs.zsh = lib.mkIf settings.zsh.enable {
    # Install and manage the supported interactive shell baseline.
    enable = true;

    initContent = lib.mkOrder 1200 ''
      # Load the optional Brew GitHub token into interactive shells.
      [[ -f "$HOME/${settings.homebrewTokenFile}" ]] && source "$HOME/${settings.homebrewTokenFile}"
      # Convenience alias for rebuilding this nix-darwin configuration.
      alias drs="sudo --preserve-env=HOMEBREW_GITHUB_API_TOKEN darwin-rebuild switch --flake ${settings.flakePath}#${settings.hostname}"

      # Repo-level flakes are the preferred path for mobile-app during adoption.
      # asdf remains available only as a compatibility fallback for repos that
      # still rely on .tool-versions.
      if command -v asdf >/dev/null 2>&1; then
        . "${pkgs.asdf-vm}/share/asdf-vm/asdf.sh"
      fi
    '';

    oh-my-zsh = lib.mkIf settings.zsh.ohMyZsh.enable {
      # Use Oh My Zsh to provide base shell defaults and prompts.
      enable = true;
      # Extra Oh My Zsh plugins to load.
      plugins = settings.zsh.ohMyZsh.plugins;
      # Prompt theme.
      theme = settings.zsh.ohMyZsh.theme;
    };

    plugins = builtins.filter (plugin: plugin != null) [
      (if settings.zsh.plugins.autosuggestions then {
        # Suggest commands from shell history as you type.
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "0e810e5afa27acbd074398eefbe28d13005dbc15";
          hash = "sha256-85aw9OM2pQPsWklXjuNOzp9El1MsNb+cIiZQVHUzBnk=";
        };
      } else null)
      (if settings.zsh.plugins.enhancd then {
        # Improved directory jumping and navigation.
        name = "enhancd";
        file = "init.sh";
        src = pkgs.fetchFromGitHub {
          owner = "babarot";
          repo = "enhancd";
          rev = "5afb4eb6ba36c15821de6e39c0a7bb9d6b0ba415";
          hash = "sha256-pKQbwiqE0KdmRDbHQcW18WfxyJSsKfymWt/TboY2iic=";
        };
      } else null)
      (if settings.zsh.plugins.autocomplete then {
        # Richer tab-completion UI for zsh.
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
          owner = "marlonrichert";
          repo = "zsh-autocomplete";
          rev = "77a4f9c1343d12d7cb3ae1e7efc7c37397ccb6b0";
          hash = "sha256-YH5T9a9KbYbvY6FRBITlhXRmkTmnwGyCQpibLe3Dhwc=";
        };
      } else null)
    ];
  };
}
