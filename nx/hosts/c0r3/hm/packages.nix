{ pkgs, ... }: {
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    kustomize
    podman
    k9s

    # needed by nvim
    neovim
    tree-sitter
    python312
    poetry

    # LSP servers
    nil # Nix LSP
    lua-language-server
    just-lsp
    bash-language-server

    # Formatters
    # nixfmt-rfc-style      # or nixpkgs-fmt
    # nixfmt
    nixfmt
    shfmt
    prettier

    nodejs_24

    # Desktop applications
    google-chrome
    signal-desktop
    vlc

    ###########
    # Rust not needed if blink is used from prebuilt binary
    ###########
    # # Rust nightly with rust-src
    # (rust-bin.selectLatestNightlyWith (toolchain:
    #   toolchain.default.override {
    #     extensions = [ "rust-src" "rust-analyzer" ];
    #   }))

    ripgrep
    fzf
    fd
    ripgrep-all

    sops
    age

    dig
    htop
    iotop
    ncdu
    nmon
    pciutils # lspci
    ps # ps aux
    socat
    # unixtools.net-tools
    nettools
    usbutils # lsusb

    bat
    git
    mc
    direnv
    fastfetch
    rclone
    rename
    starship
    tldr
    tmux
    unzip

    yq
    jq

    sublime4
    vscode
  ];
}
