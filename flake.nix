{
  description = "Create workspaces to manage multiple packages with Nix.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      flake = {
        lib = import ./lib {
          self = inputs.self;
          lib = inputs.nixpkgs.lib;
          revInfo =
            if inputs.nixpkgs ? rev
            then " (nixpkgs.rev: ${inputs.nixpkgs.rev})"
            else "";
        };
        templates = let
          tmpls = {
            basic = {
              path = ./templates/basic;
              description = "Barebones template with minimal dependencies.";
            };
            flake-parts = {
              path = ./templates/flake-parts;
              description = "Template for workspace flakes using flake-parts.";
            };
          };
        in tmpls // { default = tmpls.basic; };
      };

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (import inputs.rust-overlay)
            ];
          };
          packages.default = pkgs.callPackage ./. { };
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.rust-bin.stable.latest.default
              pkgs.cargo-watch
              pkgs.cargo-insta
            ];
          };
        };
    };
}
