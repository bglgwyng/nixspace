{
  description = "Create workspaces to manage multiple packages with Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.url = "github:NixOS/nixpkgs/nixpkgs-unstable?dir=lib";
    systems.url = "github:nix-systems/default";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-lib, systems, rust-overlay, ... }:
    let
      lib = import nixpkgs-lib;
      defaultSystems = import systems;
      eachSystem = lib.genAttrs defaultSystems;
    in {
      lib = import ./lib {
        inherit self;
        inherit lib;
        inherit defaultSystems;
        revInfo =
          if lib?rev
          then " (nixpkgs-lib.rev: ${lib.rev})"
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
    } // {
      packages = eachSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        nixspace = pkgs.callPackage ./. { };
      in {
        inherit nixspace;
        default = nixspace;
      });
      devShells = eachSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        rustToolchain = pkgs.rust-bin.stable.latest.default;
      in {
        default = pkgs.mkShell {
          packages = [
            rustToolchain
            pkgs.cargo-watch
            pkgs.cargo-insta
          ];
        };
      });
    };
}
