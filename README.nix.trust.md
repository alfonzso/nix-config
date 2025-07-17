Generating nix cache keys

In order for remote systems to accept derivations built on other machines they have to be signed in the nix store of the build machine or through the nix cache server. Generating a key is quite simple, following the steps on Distributed build or Binary Cache over at the NixOS Wiki:

$ nix-store --generate-binary-cache-key builder-name cache-priv-key.pem cache-pub-key.pem

This is using the “legacy”3 nix-store command. There might be an entry into cache key generation using nix store or similar, but I have neither looked nor stumbled over it.

Most people who’ve used nix for any significant time should be familiar with seeing pre-built store paths pulled down from cache.nixos.org. It’s also possible to use other caches (substitutors) like cachix or serving up a nix store directly from the local machine using e.g. nix-serve (or any of its many compatible clones).

As a security mechanism nix doesn’t allow using pre-built store paths from random hosts. To ensure that a path has been built by a trusted remote nix allows signing store paths. By default, nix is configured to trust the key used by Hydra:

❯ grep trusted-public-keys /etc/nix/nix.conf
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=

It’s possible to have nix sign all store paths that are built locally using a given private key. This can be done by adding the private key to /etc/nix/nix.conf:

secret-key-files <path-to-key>.pem

It’s also possible to sign all existing store paths after the fact:

$ nix store sign --all --key-file cache-priv-key.pem

Instead of explicitly signing store paths on the local machine it’s possible (and perhaps preferable) to sign the store paths when they are served through servers like nix-serve. In which case you shouldn’t invoke the command above or add the secret-key-files to /etc/nix/nix.conf.
