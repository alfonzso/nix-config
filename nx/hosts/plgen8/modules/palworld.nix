{
  networking.firewall = {
    allowedUDPPorts = [
      8211 # Palworld game port
      27015 # Palworld query port
    ];
    allowedTCPPorts = [
      25575 # Palworld RCON/admin port
    ];
  };
}
