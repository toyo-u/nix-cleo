{
  # Shared machine baseline for every developer using this config.
  # This file intentionally contains only the shared system baseline.
  systemDefaults = {
    homePackages = [
      "git"
      "asdf-vm"
      "unzip"
      "ripgrep"
      "gnumake"
    ];

    homebrew = {
      taps = [ ];
      brews = [ ];
      casks = [
        {
          name = "1password";
          greedy = true;
        }
        "android-studio"
        "codex"
        "reactotron"
      ];
    };
  };

  zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "docker" "direnv" ];
    };

    plugins = {
      autosuggestions = true;
      enhancd = true;
      autocomplete = true;
    };
  };

  tmux = {
    enable = false;
  };

  ghostty = {
    enable = false;
  };
}
