#!/bin/bash
# nixos-rebuild --flake .#plgen8 --target-host root@plgen8Nix switch
nixos-rebuild --flake .#plgen8 --target-host root@192.168.1.104 switch $@
