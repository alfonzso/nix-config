{ config, lib, pkgs, ... }: {
  imports = [ ./bash.nix ./git.nix ./tmux.nix ./vim.nix ];

}
