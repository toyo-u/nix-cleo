{
  # Human-readable label shown by some Nix tooling.
  description = "Reusable nix-darwin + home-manager template for macOS engineers";

  inputs = {
    # The package set used everywhere else in this flake.
    # `nixpkgs-25.11-darwin` pins the macOS package collection to a specific release.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # nix-darwin lets Nix manage macOS system settings and machine-level packages.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    # Reuse the same nixpkgs revision so nix-darwin and the rest of the config stay aligned.
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager manages per-user dotfiles, shell config, and user packages.
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    # Reuse the same nixpkgs revision here as well.
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, ... }:
  let
    lib = nixpkgs.lib;
    # Merge repo-owned defaults with per-machine overrides so downstream modules
    # can consume a single stable `settings` attrset.
    settings = lib.recursiveUpdate (import ./defaults.nix) (import ./settings.nix);
  in
  {
    # Build one macOS configuration named after the host.
    # Example: `darwin-rebuild switch --flake .#my-hostname`
    darwinConfigurations.${settings.hostname} = nix-darwin.lib.darwinSystem {
      # `specialArgs` passes extra values into imported modules so they can use
      # the flake inputs and local settings without re-importing them manually.
      specialArgs = {
        inherit self inputs settings;
      };

      modules = [
        # Machine-level nix-darwin configuration.
        ./config.nix

        # Enable Home Manager as a nix-darwin module so user config and system
        # config can be deployed together with one `darwin-rebuild`.
        home-manager.darwinModules.home-manager
        {
          # Use the same package set as the system config instead of a separate
          # Home Manager package set.
          home-manager.useGlobalPkgs = true;
          # Install Home Manager packages into the user profile.
          home-manager.useUserPackages = true;
          # Pass the same shared arguments into `home.nix`.
          home-manager.extraSpecialArgs = {
            inherit self inputs settings;
          };
          # Attach the user-level Home Manager configuration for the configured user.
          home-manager.users.${settings.username} = import ./home.nix;
        }
      ];
    };
  };
}
