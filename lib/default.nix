{
  self,
  lib,
}:
rec {
  callFlake = import ./call-flake.nix;
  mkWorkspaceEnv = import ./mk-workspace-env.nix {
    inherit lib callFlake;
  };
  mkWorkspace = import ./mk-workspace.nix {
    inherit self lib callFlake mkWorkspaceEnv;
  };
}
