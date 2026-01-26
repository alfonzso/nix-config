{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Go toolchain
    go
    gopls # Go LSP server

    # Formatters
    gofumpt
    golines
    gotools # goimports

    # Code generation
    gomodifytags
    gotests
    impl
    iferr

    # Debugger
    delve # This is 'dlv'

    # Testing
    ginkgo
    richgo
  ];
}
