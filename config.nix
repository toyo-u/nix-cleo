{ pkgs, self, settings, lib, ... }:
let
  # Convenience path for the configured user's home directory.
  userHome = "/Users/${settings.username}";
  # File that can export `HOMEBREW_GITHUB_API_TOKEN` before Brew runs.
  homebrewTokenFile = "${userHome}/${settings.homebrewTokenFile}";
in
{
  # Turn on the newer Nix CLI and flakes support.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Tell nixpkgs which platform this machine targets.
  nixpkgs.hostPlatform = settings.system;
  # Allow packages with non-free licenses, which is required for some macOS apps.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    # Overlays let you modify packages from nixpkgs without forking nixpkgs.
    (final: prev: {
      inetutils = prev.inetutils.overrideAttrs (old: {
        # Temporary workaround for Darwin/clang format-security build failure.
        NIX_CFLAGS_COMPILE =
          (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=format-security";
        # Upstream test suite is currently flaky/failing on Darwin in this revision.
        doCheck = false;
      });
    })
  ];

  # The main interactive user on this macOS machine.
  system.primaryUser = settings.username;

  # Ensure nix-darwin knows about the user account and the repo-supported
  # interactive shell baseline.
  users.users.${settings.username} = {
    home = userHome;
    shell = pkgs.zsh;
  };

  homebrew = {
    # Turn on nix-darwin's Homebrew integration.
    enable = true;
    onActivation = {
      # Update Homebrew metadata each time the config is applied.
      autoUpdate = true;
      # Upgrade already-installed Brew packages to the declared/latest versions.
      upgrade = true;
      # POC/adoption mode: manage declared Brew packages without removing
      # engineers' existing unmanaged Homebrew installs.
      cleanup = "none";
    };

    # Shared machine-level baseline for mobile-app:
    # - Android Studio is required to provision the Android SDK and emulator.
    # - `platform-tools` should come from the Android SDK, not Homebrew.
    #
    # Developers can add personal taps/brews/casks in `settings.nix`.
    taps = settings.systemDefaults.homebrew.taps ++ settings.homebrew.taps;
    brews = settings.systemDefaults.homebrew.brews ++ settings.homebrew.brews;
    casks = settings.systemDefaults.homebrew.casks ++ settings.homebrew.extraCasks;
  };

  # Run this script before nix-darwin activates Homebrew.
  # It lets Brew use a GitHub token for private taps or higher API limits.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    if [ -f ${lib.escapeShellArg homebrewTokenFile} ]; then
      # Load GitHub token for private tap downloads during brew bundle activation.
      # shellcheck disable=SC1091
      source ${lib.escapeShellArg homebrewTokenFile}
    fi
  '';

  # System-wide packages available to all users and shells.
  environment.systemPackages = with pkgs; [
    # Makes the `home-manager` CLI available on the machine.
    home-manager
  ];

  # Preserve the Brew GitHub token when a command is run through sudo.
  security.sudo.extraConfig = ''
    Defaults env_keep += "HOMEBREW_GITHUB_API_TOKEN"
  '';

  # Tracks the nix-darwin state schema version for compatibility.
  # Change only when intentionally migrating to a newer state version.
  system.stateVersion = 6;
  # Expose the current git revision in the built system when available.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # macOS defaults written via nix-darwin.
  system.defaults = {
    # Hide the Dock when it is not in use.
    dock.autohide = true;
    # Disable automatic reordering of Spaces based on recent use.
    dock.mru-spaces = false;
    # Always show file extensions in Finder.
    finder.AppleShowAllExtensions = true;
    # Use column view in Finder by default.
    finder.FXPreferredViewStyle = "clmv";
    # Save screenshots into this folder.
    screencapture.location = "~/Pictures/screenshots";
    # Wait 10 seconds before requiring a password after the screensaver starts.
    screensaver.askForPasswordDelay = 10;
  };
}
