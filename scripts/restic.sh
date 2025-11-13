# restic backup /home/alfoldi --exclude-file home-manager/config-files/restic-exclude-files.txt
restic backup /home/$USER --exclude-file ~/workspace/home/nix/nix-config/scripts/restic-exclude-files.txt $@

