### How to manage boot/generations

```bash
# list of boot entries
sudo ls -la /boot/loader/entries/

# list of profiles
ll /nix/var/nix/profiles/

# it will remove every entries/profiles
sudo nix-collect-garbage -d

# have to generate boot
sudo nixos-rebuild --flake .#zs00lt boot

# have to switch
sudo nixos-rebuild --flake .#zs00lt switch
```
