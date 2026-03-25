{
  # Copy this file to `settings.nix` and replace the example values with the
  # machine-specific and user-managed settings for that developer.
  # `defaults.nix` contains the shared system baseline.

  # macOS username from `whoami`.
  username = "your.username";
  # Host name from `scutil --get LocalHostName`.
  hostname = "Your-MacBook-Name";
  # `aarch64-darwin` for Apple Silicon, `x86_64-darwin` for Intel.
  system = "aarch64-darwin";

  # Optional shell file under `$HOME` that exports `HOMEBREW_GITHUB_API_TOKEN`.
  homebrewTokenFile = ".config/secrets/homebrew.env";
  # Path to this repo on disk, used by the `drs` rebuild alias.
  flakePath = "~/.config/nix-darwin";

  # Set to `null` to leave `AWS_PROFILE` unset.
  awsProfile = null;

  # Extra Home Manager packages installed for this user only.
  extraHomePackages = [
    # "rustup"
    # "smug"
    # "pnpm"
    # "gcc"
    # "lazygit"
    # "zoom-us"
    # "obsidian"
    # "libiconv"
    # "zlib"
    # "_1password-cli"
    # "vscode"
    # "rubocop"
  ];

  # Optional Neovim preferences.
  neovim = {
    enable = true;
    withNodeJs = true;
  };

  # Optional tmux preferences.
  tmux = {
    # enable = true;
    # prefix = "C-a";
    # nextWindowShortcut = "M-]";
    # previousWindowShortcut = "M-[";
    # restoreVimSessions = true;
    # continuumRestore = true;
    # plugins = [
    #   "sensible"
    #   "vim-tmux-navigator"
    #   "resurrect"
    #   "continuum"
    # ];
  };

  # Ghostty is opt-in. Also add `"ghostty"` to `homebrew.extraCasks` if enabled.
  ghostty = {
    # enable = false;
    # macosOptionAsAlt = "left";
  };

  # Override the shared Zsh baseline only when needed.
  zsh = {
    # enable = false;

    ohMyZsh = {
      # enable = false;
      # theme = "robbyrussell";
      # plugins = [ "git" ];
    };

    plugins = {
      # autosuggestions = false;
      # enhancd = false;
      # autocomplete = false;
    };
  };

  # User-managed Homebrew additions beyond the shared baseline.
  homebrew = {
    taps = [
      # "nikitabobko/tap"
      # "meetcleo/cleo"
      # "buildpacks-community/kpack-cli"
    ];
    brews = [
      # "meetcleo/cleo/cleo"
      # "kubernetes-cli"
      # "k9s"
      # "kubectx"
      # "helm"
      # "kpcli"
      # "stern"
    ];
    extraCasks = [
      # "nikitabobko/tap/aerospace"
      # "ghostty"
    ];
  };
}
