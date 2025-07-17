# nix-store --generate-binary-cache-key /etc/nix/keys/my-nas

# sudo mkdir -p /etc/nix/keys || true
nix-store --generate-binary-cache-key nas /etc/nix/keys/nas.pk /etc/nix/keys/nas.pub

ssh nxadmin@nasNix 'sudo -S mkdir -p /etc/nix/trusted-keys && sudo -S chown nxadmin: /etc/nix/trusted-keys'
scp /etc/nix/keys/nas.pub nxadmin@nasNix:/etc/nix/trusted-keys

# ssh nxadmin@nasNix 'sudo mkdir -p /etc/nix/trusted-keys && sudo mv /tmp/my-nas.pub /etc/nix/trusted-keys/'
