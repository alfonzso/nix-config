{ ... }:
{

  programs.git = {
    enable = true;

    ignores = [ ".tmp" "tmp" ".envrc" ];

    settings = {

      user.name = "alfonzso";
      user.email = "alfonzso@gmail.com";

      core = {
        editor = "nvim";
        whitespace = "trailing-space,space-before-tab";
        quotepath = "off";
      };
      # pull.rebase = "true";
      stash = { showPatch = "1"; };
      color = {
        pager = "true";
        diff = "true";
        grep = "true";
        interactive = "true";
        status = "always";
        ui = "true";
      };
      "merge \"po\"" = {
        name = "Gettext merge driver";
        driver = "git-merge-po.sh %O %A %B";
      };
      apply = { whitespace = "fix"; };
      diff = {
        tool = "nvim -d";
        colorMoved = "default";
      };
      "color \"diff-highlight\"" = {
        oldNormal = "red bold";
        oldHighlight = "red bold 52";
        newNormal = "green bold";
        newHighlight = "green bold 22";
      };
      "color \"diff\"" = {
        meta = "yellow";
        frag = "magenta bold";
        commit = "yellow bold";
        old = "red bold";
        new = "green bold";
        whitespace = "red reverse";
      };
      merge = { tool = "nvim"; };
      "mergetool \"meld\"" = {
        cmd = ''meld "$LOCAL" "$MERGED" "$REMOTE" --output "$MERGED"'';
      };
      "mergetool \"nvim\"" = {
        cmd =
          "nvim -d \"$LOCAL\" \"$REMOTE\" \"$MERGED\" -c '$wincmd w' -c 'wincmd J'";
      };
      "mergetool \"vscode\"" = { cmd = ''code --wait "$MERGED"''; };
    };

  };

}
