{
  config,
  pkgs,
  ...
}:
{
  sops = {
    defaultSopsFile =
      if (config.networking.hostName == "gaia") then
        ../secrets/gaia/secrets.yaml
      else if (config.networking.hostName == "nvr") then
        ../secrets/nvr/secrets.yaml
      else if (config.networking.hostName == "matrix") then
        ../secrets/matrix/secrets.yaml
      else if (config.networking.hostName == "git") then
        ../secrets/forgejo/secrets.yaml
      else if (config.networking.hostName == "lxc-git") then
        ../secrets/forgejo/secrets.yaml
      else if (config.networking.hostName == "homeassistant") then
        ../secrets/homeassistant/secrets.yaml
      else if (config.networking.hostName == "fitness") then
        ../secrets/fitness/secrets.yaml
      else if (config.networking.hostName == "lxc-homeassistant") then
        ../secrets/homeassistant/secrets.yaml
      else if (config.networking.hostName == "media") then
        ../secrets/media/secrets.yaml
      else if (config.networking.hostName == "gaming") then
        ../secrets/gaming/secrets.yaml
      else if (config.networking.hostName == "manga") then
        ../secrets/manga/secrets.yaml
      else
        ../secrets/shared/secrets.yaml;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };

    validateSopsFiles = false;
  };

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];
}
