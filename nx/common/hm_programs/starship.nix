{ ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      add_newline = true;
      command_timeout = 1000;
      format = "$time$username$hostname$directory$git_branch$git_status$nix_shell$direnv$cmd_duration$status$line_break$character";

      time = {
        disabled = false;
        format = "[$time]($style) ";
        time_format = "%H:%M:%S";
        style = "dimmed white";
      };

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "bold yellow";
        style_root = "bold red";
      };

      hostname = {
        ssh_only = false;
        format = "[@$hostname]($style) ";
        style = "bold green";
      };

      directory = {
        truncation_length = 5;
        truncate_to_repo = false;
        read_only = " ro";
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        format = "on [$symbol$branch]($style) ";
        symbol = "git:";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
      };

      nix_shell = {
        format = "via [nix $state $name]($style) ";
      };

      direnv = {
        disabled = false;
        format = "[$symbol$loaded/$allowed]($style) ";
        symbol = "direnv:";
      };

      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
      };

      status = {
        disabled = false;
        format = "[$symbol$status]($style) ";
        symbol = "exit:";
      };
    };
  };
}
