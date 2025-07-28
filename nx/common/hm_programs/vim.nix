{ config, pkgs, hostCfg, ... }:
# let
#   hostCfg = config.hostCfg ;
# in
{

  programs.vim = {
    enable = true;
    defaultEditor = true;

    # config = builtins.readFile ~/.vimrc;
    # extraConfig = builtins.readFile /home/nixos/.vimrc;

    plugins = with pkgs.vimPlugins; [
      vim-fzf-coauthorship
      vim-sensible
      vim-automkdir
      vim-nix # Syntax highlighting for Nix
      nerdtree # File explorer
      fugitive # Git integration
    ];

    extraConfig = ''
      " NERDTree configuration
      " nnoremap <leader>n :NERDTreeToggle<CR>
      set tabstop     =2
      set softtabstop =2
      set shiftwidth  =2
      set expandtab
      set backupdir=/home/${hostCfg.username}/.vim-tmp
      set directory=/home/${hostCfg.username}/.vim-tmp

      set exrc
      set secure

      " Reopen the last edited position in files
      au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    '';
  };
}
